const express = require('express');
const auth = require('../middleware/auth');
const Message = require('../models/Message');
const Conversation = require('../models/Conversation');
const User = require('../models/User');
const Notification = require('../models/Notification');
const multer = require('multer');
const path = require('path');
const { v4: uuidv4 } = require('uuid');

const router = express.Router();

// Configure multer for file uploads
const storage = multer.diskStorage({
  destination: function (req, file, cb) {
    cb(null, 'uploads/messages/');
  },
  filename: function (req, file, cb) {
    const uniqueSuffix = Date.now() + '-' + Math.round(Math.random() * 1E9);
    cb(null, file.fieldname + '-' + uniqueSuffix + path.extname(file.originalname));
  }
});

const upload = multer({ 
  storage: storage,
  limits: {
    fileSize: 100 * 1024 * 1024, // 100MB limit
  },
  fileFilter: (req, file, cb) => {
    // Allow images, videos, and GIFs
    const allowedMimes = [
      'image/jpeg', 'image/png', 'image/gif', 'image/webp',
      'video/mp4', 'video/webm', 'video/quicktime', 'video/x-msvideo'
    ];
    
    if (allowedMimes.includes(file.mimetype)) {
      cb(null, true);
    } else {
      cb(new Error('Invalid file type. Only images and videos are allowed.'), false);
    }
  }
});

// Get user's conversations list
router.get('/conversations', auth, async (req, res) => {
  try {
    const page = parseInt(req.query.page) || 1;
    const limit = parseInt(req.query.limit) || 20;
    const skip = (page - 1) * limit;

    const conversations = await Conversation.find({
      participants: req.user._id,
      isActive: true
    })
    .populate('participants', 'username displayName profileImage isVerified')
    .populate('lastMessage', 'content messageType createdAt sender isRead')
    .populate('lastMessage.sender', 'username displayName')
    .sort({ lastActivity: -1 })
    .limit(limit)
    .skip(skip);

    // Add unread count for current user to each conversation
    const conversationsWithUnread = conversations.map(conv => {
      const convObj = conv.toObject();
      convObj.unreadCount = conv.getUnreadCountForUser(req.user._id);
      
      // For direct conversations, get the other participant
      if (!conv.isGroup) {
        convObj.otherParticipant = conv.participants.find(p => p._id !== req.user._id);
      }
      
      return convObj;
    });

    res.json(conversationsWithUnread);
  } catch (error) {
    console.error('Error fetching conversations:', error);
    res.status(500).json({ message: 'Error fetching conversations' });
  }
});

// Get or create conversation with specific user
router.post('/conversations', auth, async (req, res) => {
  try {
    const { participantId } = req.body;

    if (!participantId) {
      return res.status(400).json({ message: 'Participant ID is required' });
    }

    if (participantId === req.user._id) {
      return res.status(400).json({ message: 'Cannot create conversation with yourself' });
    }

    // Check if participant exists
    const participant = await User.findById(participantId);
    if (!participant) {
      return res.status(404).json({ message: 'User not found' });
    }

    // Check if conversation already exists
    let conversation = await Conversation.findOne({
      participants: { $all: [req.user._id, participantId] },
      isGroup: false,
      isActive: true
    })
    .populate('participants', 'username displayName profileImage isVerified');

    // If no conversation exists, create one
    if (!conversation) {
      conversation = new Conversation({
        participants: [req.user._id, participantId],
        isGroup: false,
        createdBy: req.user._id,
        participantSettings: [
          { user: req.user._id, joinedAt: new Date() },
          { user: participantId, joinedAt: new Date() }
        ]
      });

      await conversation.save();
      await conversation.populate('participants', 'username displayName profileImage isVerified');
    }

    const convObj = conversation.toObject();
    convObj.unreadCount = conversation.getUnreadCountForUser(req.user._id);
    convObj.otherParticipant = conversation.participants.find(p => p._id !== req.user._id);

    res.status(201).json(convObj);
  } catch (error) {
    console.error('Error creating conversation:', error);
    res.status(500).json({ message: 'Error creating conversation' });
  }
});

// Get messages in a conversation
router.get('/conversations/:conversationId/messages', auth, async (req, res) => {
  try {
    const { conversationId } = req.params;
    const page = parseInt(req.query.page) || 1;
    const limit = parseInt(req.query.limit) || 50;
    const skip = (page - 1) * limit;

    // Check if user is part of the conversation
    const conversation = await Conversation.findOne({
      _id: conversationId,
      participants: req.user._id,
      isActive: true
    });

    if (!conversation) {
      return res.status(404).json({ message: 'Conversation not found or access denied' });
    }

    const messages = await Message.find({
      conversationId,
      isDeleted: false
    })
    .populate('sender', 'username displayName profileImage isVerified')
    .populate('recipient', 'username displayName profileImage isVerified')
    .populate('replyTo', 'content sender createdAt')
    .sort({ createdAt: -1 })
    .limit(limit)
    .skip(skip);

    // Mark messages as read for current user
    const unreadMessages = messages.filter(msg => 
      msg.recipient.toString() === req.user._id && !msg.isRead
    );

    if (unreadMessages.length > 0) {
      await Message.updateMany(
        {
          _id: { $in: unreadMessages.map(msg => msg._id) },
          recipient: req.user._id
        },
        {
          $set: { isRead: true },
          $addToSet: { readBy: { user: req.user._id, readAt: new Date() } }
        }
      );

      // Reset unread count for this user in the conversation
      conversation.resetUnreadForUser(req.user._id);
      await conversation.save();
    }

    res.json(messages.reverse()); // Return in chronological order
  } catch (error) {
    console.error('Error fetching messages:', error);
    res.status(500).json({ message: 'Error fetching messages' });
  }
});

// Send a new message
router.post('/conversations/:conversationId/messages', auth, upload.array('media', 10), async (req, res) => {
  try {
    const { conversationId } = req.params;
    const { content, replyToId } = req.body;

    // Check if user is part of the conversation
    const conversation = await Conversation.findOne({
      _id: conversationId,
      participants: req.user._id,
      isActive: true
    });

    if (!conversation) {
      return res.status(404).json({ message: 'Conversation not found or access denied' });
    }

    // Get recipient (the other participant in direct conversation)
    const recipientId = conversation.getOtherParticipant(req.user._id);
    if (!recipientId) {
      return res.status(400).json({ message: 'Could not determine recipient' });
    }

    // Validate message content
    if (!content && (!req.files || req.files.length === 0)) {
      return res.status(400).json({ message: 'Message content or media is required' });
    }

    // Process uploaded media files
    let mediaFiles = [];
    if (req.files && req.files.length > 0) {
      mediaFiles = req.files.map(file => ({
        url: `/uploads/messages/${file.filename}`,
        type: file.mimetype.startsWith('image/') ? 'image' : 'video',
        filename: file.filename,
        size: file.size
      }));
    }

    // Create message
    const message = new Message({
      conversationId,
      sender: req.user._id,
      recipient: recipientId,
      content: content || '',
      messageType: mediaFiles.length > 0 ? 'media' : 'text',
      mediaFiles,
      replyTo: replyToId || null
    });

    await message.save();

    // Update conversation
    conversation.lastMessage = message._id;
    conversation.lastActivity = new Date();
    conversation.incrementUnreadForUser(recipientId);
    await conversation.save();

    // Populate message data for response
    await message.populate('sender', 'username displayName profileImage isVerified');
    await message.populate('recipient', 'username displayName profileImage isVerified');
    if (replyToId) {
      await message.populate('replyTo', 'content sender createdAt');
    }

    // Create notification for recipient
    try {
      const notification = new Notification({
        recipient: recipientId,
        sender: req.user._id,
        type: 'message',
        message: `${req.user.displayName} sent you a message`,
        relatedTweet: null,
        metadata: {
          conversationId,
          messageId: message._id,
          messageContent: content ? content.substring(0, 100) : 'Sent a media message'
        }
      });
      await notification.save();
    } catch (notifError) {
      console.error('Error creating message notification:', notifError);
      // Don't fail the message sending if notification fails
    }

    res.status(201).json(message);
  } catch (error) {
    console.error('Error sending message:', error);
    res.status(500).json({ message: 'Error sending message' });
  }
});

// Mark conversation as read
router.patch('/conversations/:conversationId/read', auth, async (req, res) => {
  try {
    const { conversationId } = req.params;

    // Check if user is part of the conversation
    const conversation = await Conversation.findOne({
      _id: conversationId,
      participants: req.user._id,
      isActive: true
    });

    if (!conversation) {
      return res.status(404).json({ message: 'Conversation not found or access denied' });
    }

    // Mark all unread messages as read
    await Message.updateMany(
      {
        conversationId,
        recipient: req.user._id,
        isRead: false
      },
      {
        $set: { isRead: true },
        $addToSet: { readBy: { user: req.user._id, readAt: new Date() } }
      }
    );

    // Reset unread count for this user
    conversation.resetUnreadForUser(req.user._id);
    await conversation.save();

    res.json({ message: 'Conversation marked as read' });
  } catch (error) {
    console.error('Error marking conversation as read:', error);
    res.status(500).json({ message: 'Error marking conversation as read' });
  }
});

// Delete a message
router.delete('/messages/:messageId', auth, async (req, res) => {
  try {
    const { messageId } = req.params;

    const message = await Message.findOne({
      _id: messageId,
      sender: req.user._id,
      isDeleted: false
    });

    if (!message) {
      return res.status(404).json({ message: 'Message not found or access denied' });
    }

    // Soft delete the message
    message.isDeleted = true;
    message.deletedBy.push(req.user._id);
    await message.save();

    res.json({ message: 'Message deleted successfully' });
  } catch (error) {
    console.error('Error deleting message:', error);
    res.status(500).json({ message: 'Error deleting message' });
  }
});

// React to a message
router.post('/messages/:messageId/reactions', auth, async (req, res) => {
  try {
    const { messageId } = req.params;
    const { emoji } = req.body;

    if (!emoji) {
      return res.status(400).json({ message: 'Emoji is required' });
    }

    const message = await Message.findById(messageId);
    if (!message) {
      return res.status(404).json({ message: 'Message not found' });
    }

    // Check if user already reacted with this emoji
    const existingReaction = message.reactions.find(
      reaction => reaction.user.toString() === req.user._id && reaction.emoji === emoji
    );

    if (existingReaction) {
      // Remove reaction
      message.reactions = message.reactions.filter(
        reaction => !(reaction.user.toString() === req.user._id && reaction.emoji === emoji)
      );
    } else {
      // Add reaction
      message.reactions.push({
        user: req.user._id,
        emoji,
        createdAt: new Date()
      });
    }

    await message.save();
    await message.populate('reactions.user', 'username displayName');

    res.json(message);
  } catch (error) {
    console.error('Error reacting to message:', error);
    res.status(500).json({ message: 'Error reacting to message' });
  }
});

module.exports = router;