const jwt = require('jsonwebtoken');
const User = require('../models/User');
const Message = require('../models/Message');
const Conversation = require('../models/Conversation');

// Connected users store
const connectedUsers = new Map(); // userId -> socketId
const userSockets = new Map();    // socketId -> userId

module.exports = (io) => {
  // Authentication middleware for Socket.IO
  io.use(async (socket, next) => {
    try {
      const token = socket.handshake.auth.token;
      if (!token) {
        return next(new Error('Authentication error: No token provided'));
      }

      const decoded = jwt.verify(token, process.env.JWT_SECRET);
      const user = await User.findById(decoded.userId);
      
      if (!user) {
        return next(new Error('Authentication error: User not found'));
      }

      socket.userId = user._id;
      socket.user = user;
      next();
    } catch (err) {
      next(new Error('Authentication error: Invalid token'));
    }
  });

  io.on('connection', (socket) => {
    const userId = socket.userId;
    console.log(`User ${socket.user.username} connected with socket ${socket.id}`);

    // Store user connection
    connectedUsers.set(userId, socket.id);
    userSockets.set(socket.id, userId);

    // Join user-specific room for notifications
    socket.join(`user_${userId}`);

    // Handle user joining conversation rooms
    socket.on('join_conversation', async (conversationId) => {
      try {
        // Verify user is part of this conversation
        const conversation = await Conversation.findOne({
          _id: conversationId,
          participants: userId
        });

        if (conversation) {
          socket.join(`conversation_${conversationId}`);
          console.log(`User ${socket.user.username} joined conversation ${conversationId}`);
        }
      } catch (error) {
        console.error('Error joining conversation:', error);
      }
    });

    // Handle leaving conversation rooms
    socket.on('leave_conversation', (conversationId) => {
      socket.leave(`conversation_${conversationId}`);
      console.log(`User ${socket.user.username} left conversation ${conversationId}`);
    });

    // Handle new message
    socket.on('send_message', async (data) => {
      try {
        const { conversationId, content, replyToId, mediaFiles } = data;

        // Verify user is part of this conversation
        const conversation = await Conversation.findOne({
          _id: conversationId,
          participants: userId
        });

        if (!conversation) {
          socket.emit('message_error', { error: 'Conversation not found or access denied' });
          return;
        }

        // Get recipient for direct messages
        const recipient = conversation.participants.find(p => p !== userId);

        // Create new message
        const message = new Message({
          conversationId,
          sender: userId,
          recipient,
          content: content.trim(),
          messageType: mediaFiles && mediaFiles.length > 0 ? 'media' : 'text',
          mediaFiles: mediaFiles || [],
          replyTo: replyToId || null
        });

        await message.save();
        await message.populate('sender', 'username displayName profileImage isVerified');
        
        if (replyToId) {
          await message.populate('replyTo', 'content sender createdAt');
        }

        // Update conversation
        conversation.lastMessage = message._id;
        conversation.lastActivity = new Date();

        // Update unread counts for all participants except sender
        conversation.participants.forEach(participantId => {
          if (participantId !== userId) {
            conversation.incrementUnreadForUser(participantId);
          }
        });

        await conversation.save();

        // Broadcast message to conversation room
        io.to(`conversation_${conversationId}`).emit('new_message', {
          message: message.toJSON(),
          conversationId
        });

        // Send notification to offline users
        conversation.participants.forEach(participantId => {
          if (participantId !== userId && !connectedUsers.has(participantId)) {
            // Could trigger push notification here
            console.log(`Should send push notification to user ${participantId}`);
          }
        });

        // Update conversation for all participants
        const populatedConversation = await Conversation.findById(conversationId)
          .populate('participants', 'username displayName profileImage isVerified')
          .populate('lastMessage', 'content messageType createdAt sender');

        conversation.participants.forEach(participantId => {
          io.to(`user_${participantId}`).emit('conversation_updated', {
            conversation: populatedConversation.toJSON()
          });
        });

      } catch (error) {
        console.error('Error sending message:', error);
        socket.emit('message_error', { error: 'Failed to send message' });
      }
    });

    // Handle message reactions
    socket.on('react_to_message', async (data) => {
      try {
        const { messageId, conversationId, emoji } = data;

        const message = await Message.findById(messageId);
        if (!message || message.conversationId !== conversationId) {
          socket.emit('reaction_error', { error: 'Message not found' });
          return;
        }

        // Check if user already reacted with this emoji
        const existingReaction = message.reactions.find(r => 
          r.user === userId && r.emoji === emoji
        );

        if (existingReaction) {
          // Remove reaction
          message.reactions = message.reactions.filter(r => 
            !(r.user === userId && r.emoji === emoji)
          );
        } else {
          // Add reaction
          message.reactions.push({
            user: userId,
            emoji,
            createdAt: new Date()
          });
        }

        await message.save();

        // Broadcast reaction update to conversation
        io.to(`conversation_${conversationId}`).emit('message_reaction_updated', {
          messageId,
          reactions: message.reactions,
          conversationId
        });

      } catch (error) {
        console.error('Error handling reaction:', error);
        socket.emit('reaction_error', { error: 'Failed to update reaction' });
      }
    });

    // Handle typing indicators
    socket.on('typing_start', (data) => {
      const { conversationId } = data;
      socket.to(`conversation_${conversationId}`).emit('user_typing', {
        userId,
        username: socket.user.username,
        conversationId
      });
    });

    socket.on('typing_stop', (data) => {
      const { conversationId } = data;
      socket.to(`conversation_${conversationId}`).emit('user_stopped_typing', {
        userId,
        conversationId
      });
    });

    // Handle message read receipts
    socket.on('mark_messages_read', async (data) => {
      try {
        const { conversationId, messageIds } = data;

        // Update messages as read
        await Message.updateMany(
          {
            _id: { $in: messageIds },
            recipient: userId
          },
          {
            $set: { isRead: true },
            $addToSet: { readBy: { user: userId, readAt: new Date() } }
          }
        );

        // Reset unread count for this user
        const conversation = await Conversation.findById(conversationId);
        if (conversation) {
          conversation.resetUnreadForUser(userId);
          await conversation.save();
        }

        // Notify sender about read receipts
        io.to(`conversation_${conversationId}`).emit('messages_read', {
          messageIds,
          userId,
          conversationId
        });

      } catch (error) {
        console.error('Error marking messages as read:', error);
      }
    });

    // Handle disconnect
    socket.on('disconnect', () => {
      console.log(`User ${socket.user.username} disconnected`);
      
      // Remove from connected users
      connectedUsers.delete(userId);
      userSockets.delete(socket.id);
      
      // Leave all rooms
      socket.rooms.forEach(room => {
        if (room.startsWith('conversation_')) {
          socket.leave(room);
        }
      });
    });
  });

  // Export function to send notifications to specific users
  io.sendNotificationToUser = (userId, notification) => {
    io.to(`user_${userId}`).emit('notification', notification);
  };

  // Export function to check if user is online
  io.isUserOnline = (userId) => {
    return connectedUsers.has(userId);
  };
};