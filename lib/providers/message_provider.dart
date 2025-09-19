import 'package:flutter/material.dart';
import 'dart:async';
import '../models/message_model.dart';
import '../models/conversation_model.dart';
import '../services/api_service.dart';
import '../services/websocket_service.dart';

class MessageProvider with ChangeNotifier {
  // Conversations state
  List<Conversation> _conversations = [];
  bool _isLoadingConversations = false;
  bool _hasMoreConversations = true;
  int _conversationsPage = 1;
  String? _conversationsError;

  // Messages state for specific conversations
  Map<String, List<Message>> _conversationMessages = {};
  Map<String, bool> _loadingMessages = {};
  Map<String, bool> _hasMoreMessages = {};
  Map<String, int> _messagePage = {};
  Map<String, String?> _messageErrors = {};

  // Current active conversation
  String? _activeConversationId;
  
  // Sending state
  Map<String, bool> _sendingMessage = {};
  
  // Real-time updates
  Timer? _refreshTimer;
  final WebSocketService _webSocketService = WebSocketService();
  StreamSubscription? _messageSubscription;
  StreamSubscription? _conversationSubscription;
  StreamSubscription? _typingSubscription;
  StreamSubscription? _reactionSubscription;
  StreamSubscription? _readReceiptSubscription;

  // Typing indicators
  Map<String, Set<String>> _typingUsers = {}; // conversationId -> Set of userIds

  // Getters
  List<Conversation> get conversations => _conversations;
  bool get isLoadingConversations => _isLoadingConversations;
  bool get hasMoreConversations => _hasMoreConversations;
  String? get conversationsError => _conversationsError;
  String? get activeConversationId => _activeConversationId;

  List<Message> getMessagesForConversation(String conversationId) {
    return _conversationMessages[conversationId] ?? [];
  }

  bool isLoadingMessages(String conversationId) {
    return _loadingMessages[conversationId] ?? false;
  }

  bool hasMoreMessages(String conversationId) {
    return _hasMoreMessages[conversationId] ?? true;
  }

  String? getMessageError(String conversationId) {
    return _messageErrors[conversationId];
  }

  bool isSendingMessage(String conversationId) {
    return _sendingMessage[conversationId] ?? false;
  }

  // Get total unread messages count across all conversations
  int get totalUnreadCount {
    return _conversations.fold(0, (total, conv) => total + conv.unreadCount);
  }

  // Get typing users for a conversation
  Set<String> getTypingUsers(String conversationId) {
    return _typingUsers[conversationId] ?? {};
  }

  // Check if WebSocket is connected
  bool get isWebSocketConnected => _webSocketService.isConnected;

  MessageProvider() {
    // Auto-refresh conversations every 30 seconds
    _startAutoRefresh();
    // Initialize WebSocket connection
    _initializeWebSocket();
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    _cleanupWebSocket();
    super.dispose();
  }

  // Initialize WebSocket connection and listeners
  Future<void> _initializeWebSocket() async {
    await _webSocketService.connect();
    _setupWebSocketListeners();
  }

  void _setupWebSocketListeners() {
    // Listen for new messages
    _messageSubscription = _webSocketService.messageStream.listen((message) {
      _handleNewMessage(message);
    });

    // Listen for conversation updates
    _conversationSubscription = _webSocketService.conversationStream.listen((conversation) {
      _handleConversationUpdate(conversation);
    });

    // Listen for typing indicators
    _typingSubscription = _webSocketService.typingStream.listen((data) {
      _handleTypingIndicator(data);
    });

    // Listen for message reactions
    _reactionSubscription = _webSocketService.reactionStream.listen((data) {
      _handleMessageReaction(data);
    });

    // Listen for read receipts
    _readReceiptSubscription = _webSocketService.readReceiptStream.listen((data) {
      _handleReadReceipt(data);
    });
  }

  void _cleanupWebSocket() {
    _messageSubscription?.cancel();
    _conversationSubscription?.cancel();
    _typingSubscription?.cancel();
    _reactionSubscription?.cancel();
    _readReceiptSubscription?.cancel();
    _webSocketService.disconnect();
  }

  void _startAutoRefresh() {
    _refreshTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      if (_conversations.isNotEmpty) {
        loadConversations(refresh: true);
      }
    });
  }

  // WebSocket event handlers
  void _handleNewMessage(Message message) {
    final conversationId = message.conversationId;
    
    print('MessageProvider: Received new message via WebSocket');
    print('  messageId: ${message.id}');
    print('  conversationId: $conversationId');
    print('  senderId: ${message.senderId}');
    print('  content: "${message.content}"');
    
    // Add message to conversation messages
    final messages = _conversationMessages[conversationId] ?? [];
    _conversationMessages[conversationId] = [message, ...messages];
    
    // Update conversation in list
    final convIndex = _conversations.indexWhere((c) => c.id == conversationId);
    if (convIndex != -1) {
      _conversations[convIndex] = _conversations[convIndex].copyWith(
        lastMessage: message,
        lastActivity: DateTime.now(),
      );
      
      // Move conversation to top of list
      final conversation = _conversations.removeAt(convIndex);
      _conversations.insert(0, conversation);
    }
    
    notifyListeners();
  }
  
  void _handleConversationUpdate(Conversation conversation) {
    final convIndex = _conversations.indexWhere((c) => c.id == conversation.id);
    if (convIndex != -1) {
      _conversations[convIndex] = conversation;
    } else {
      _conversations.insert(0, conversation);
    }
    notifyListeners();
  }
  
  void _handleTypingIndicator(Map<String, dynamic> data) {
    final conversationId = data['conversationId'] as String;
    final userId = data['userId'] as String;
    final type = data['type'] as String;
    
    if (type == 'start') {
      _typingUsers[conversationId] ??= <String>{};
      _typingUsers[conversationId]!.add(userId);
    } else {
      _typingUsers[conversationId]?.remove(userId);
      if (_typingUsers[conversationId]?.isEmpty ?? false) {
        _typingUsers.remove(conversationId);
      }
    }
    
    notifyListeners();
  }
  
  void _handleMessageReaction(Map<String, dynamic> data) {
    final conversationId = data['conversationId'] as String;
    final messageId = data['messageId'] as String;
    final reactions = data['reactions'] as List;
    
    // Update message in local state
    final messages = _conversationMessages[conversationId];
    if (messages != null) {
      final msgIndex = messages.indexWhere((msg) => msg.id == messageId);
      if (msgIndex != -1) {
        // Convert reaction data to MessageReaction objects
        final messageReactions = reactions.map((r) => MessageReaction(
          userId: r['user'] ?? '',
          emoji: r['emoji'] ?? '',
          createdAt: DateTime.tryParse(r['createdAt'] ?? '') ?? DateTime.now(),
        )).toList();
        
        _conversationMessages[conversationId]![msgIndex] = 
            _conversationMessages[conversationId]![msgIndex].copyWith(
              reactions: messageReactions,
            );
        notifyListeners();
      }
    }
  }
  
  void _handleReadReceipt(Map<String, dynamic> data) {
    final conversationId = data['conversationId'] as String;
    final messageIds = List<String>.from(data['messageIds']);
    
    // Update messages as read
    final messages = _conversationMessages[conversationId];
    if (messages != null) {
      _conversationMessages[conversationId] = messages.map((message) {
        if (messageIds.contains(message.id)) {
          return message.copyWith(isRead: true);
        }
        return message;
      }).toList();
      notifyListeners();
    }
  }

  // Load conversations list
  Future<void> loadConversations({bool refresh = false}) async {
    if (refresh) {
      _conversationsPage = 1;
      _hasMoreConversations = true;
      _conversations.clear();
    }

    if (!_hasMoreConversations || _isLoadingConversations) return;

    _isLoadingConversations = true;
    _conversationsError = null;
    notifyListeners();

    try {
      final response = await ApiService.getConversations(
        page: _conversationsPage,
        limit: 20,
      );

      if (response['success']) {
        final newConversations = (response['conversations'] as List)
            .map((json) => Conversation.fromJson(json))
            .toList();

        if (newConversations.isEmpty) {
          _hasMoreConversations = false;
        } else {
          if (refresh) {
            _conversations = newConversations;
          } else {
            _conversations.addAll(newConversations);
          }
          _conversationsPage++;
        }
      } else {
        _conversationsError = response['message'] ?? 'Failed to load conversations';
      }
    } catch (e) {
      _conversationsError = 'Network error: $e';
    } finally {
      _isLoadingConversations = false;
      notifyListeners();
    }
  }

  // Create or get existing conversation with user
  Future<Conversation?> createConversationWithUser(String userId) async {
    try {
      final response = await ApiService.createConversation(userId);
      
      if (response['success']) {
        final conversation = Conversation.fromJson(response['conversation']);
        
        // Add to conversations list if not already present
        final existingIndex = _conversations.indexWhere((c) => c.id == conversation.id);
        if (existingIndex != -1) {
          _conversations[existingIndex] = conversation;
        } else {
          _conversations.insert(0, conversation);
        }
        
        notifyListeners();
        return conversation;
      } else {
        throw Exception(response['message'] ?? 'Failed to create conversation');
      }
    } catch (e) {
      print('Error creating conversation: $e');
      return null;
    }
  }

  // Load messages for specific conversation
  Future<void> loadMessages(String conversationId, {bool refresh = false}) async {
    if (refresh) {
      _messagePage[conversationId] = 1;
      _hasMoreMessages[conversationId] = true;
      _conversationMessages[conversationId] = [];
    }

    if (_hasMoreMessages[conversationId] == false || 
        _loadingMessages[conversationId] == true) return;

    _loadingMessages[conversationId] = true;
    _messageErrors[conversationId] = null;
    _activeConversationId = conversationId;
    
    // Join WebSocket room for this conversation
    _webSocketService.joinConversation(conversationId);
    notifyListeners();

    try {
      final response = await ApiService.getConversationMessages(
        conversationId,
        page: _messagePage[conversationId] ?? 1,
        limit: 50,
      );

      if (response['success']) {
        final newMessages = (response['messages'] as List)
            .map((json) => Message.fromJson(json))
            .toList();

        if (newMessages.isEmpty) {
          _hasMoreMessages[conversationId] = false;
        } else {
          if (refresh) {
            _conversationMessages[conversationId] = newMessages;
          } else {
            final existingMessages = _conversationMessages[conversationId] ?? [];
            _conversationMessages[conversationId] = [...existingMessages, ...newMessages];
          }
          _messagePage[conversationId] = (_messagePage[conversationId] ?? 1) + 1;
        }

        // Mark conversation as read
        await markConversationAsRead(conversationId);
      } else {
        _messageErrors[conversationId] = response['message'] ?? 'Failed to load messages';
      }
    } catch (e) {
      _messageErrors[conversationId] = 'Network error: $e';
    } finally {
      _loadingMessages[conversationId] = false;
      notifyListeners();
    }
  }

  // Send a new message
  Future<bool> sendMessage(
    String conversationId,
    String content, {
    List<String>? mediaFilePaths,
    String? replyToId,
  }) async {
    _sendingMessage[conversationId] = true;
    notifyListeners();

    try {
      print('MessageProvider: Sending message via HTTP API');
      print('  conversationId: $conversationId');
      print('  content: "$content"');
      
      // Always use HTTP API for now to ensure message consistency
      final response = await ApiService.sendMessage(
        conversationId,
        content,
        mediaFilePaths: mediaFilePaths,
        replyToId: replyToId,
      );

      print('MessageProvider: Response received: ${response['success']}');
      
      if (response['success']) {
        final newMessage = Message.fromJson(response['message']);
        
        print('MessageProvider: New message created');
        print('  messageId: ${newMessage.id}');
        print('  senderId: ${newMessage.senderId}');
        print('  content: "${newMessage.content}"');
        
        // Add message to conversation
        final messages = _conversationMessages[conversationId] ?? [];
        _conversationMessages[conversationId] = [newMessage, ...messages];

        // Update conversation's last message
        final convIndex = _conversations.indexWhere((c) => c.id == conversationId);
        if (convIndex != -1) {
          _conversations[convIndex] = _conversations[convIndex].copyWith(
            lastMessage: newMessage,
            lastActivity: DateTime.now(),
          );
        }

        notifyListeners();
        return true;
      } else {
        throw Exception(response['message'] ?? 'Failed to send message');
      }
    } catch (e) {
      print('Error sending message: $e');
      return false;
    } finally {
      _sendingMessage[conversationId] = false;
      notifyListeners();
    }
  }

  // Mark conversation as read
  Future<void> markConversationAsRead(String conversationId) async {
    try {
      await ApiService.markConversationAsRead(conversationId);

      // Update local state
      final convIndex = _conversations.indexWhere((c) => c.id == conversationId);
      if (convIndex != -1) {
        _conversations[convIndex] = _conversations[convIndex].copyWith(unreadCount: 0);
        notifyListeners();
      }

      // Mark messages as read
      final messages = _conversationMessages[conversationId];
      if (messages != null) {
        _conversationMessages[conversationId] = messages
            .map((msg) => msg.copyWith(isRead: true))
            .toList();
      }
    } catch (e) {
      print('Error marking conversation as read: $e');
    }
  }

  // Delete a message
  Future<bool> deleteMessage(String messageId, String conversationId) async {
    try {
      final response = await ApiService.deleteMessage(messageId);
      
      if (response['success']) {
        // Remove message from local state
        final messages = _conversationMessages[conversationId];
        if (messages != null) {
          _conversationMessages[conversationId] = messages
              .where((msg) => msg.id != messageId)
              .toList();
          notifyListeners();
        }
        return true;
      } else {
        throw Exception(response['message'] ?? 'Failed to delete message');
      }
    } catch (e) {
      print('Error deleting message: $e');
      return false;
    }
  }

  // React to a message
  Future<bool> reactToMessage(String messageId, String conversationId, String emoji) async {
    try {
      final response = await ApiService.reactToMessage(messageId, emoji);
      
      if (response['success']) {
        final updatedMessage = Message.fromJson(response['message']);
        
        // Update message in local state
        final messages = _conversationMessages[conversationId];
        if (messages != null) {
          final msgIndex = messages.indexWhere((msg) => msg.id == messageId);
          if (msgIndex != -1) {
            _conversationMessages[conversationId]![msgIndex] = updatedMessage;
            notifyListeners();
          }
        }
        return true;
      } else {
        throw Exception(response['message'] ?? 'Failed to react to message');
      }
    } catch (e) {
      print('Error reacting to message: $e');
      return false;
    }
  }

  // Search conversations
  List<Conversation> searchConversations(String query) {
    if (query.isEmpty) return _conversations;
    
    final lowercaseQuery = query.toLowerCase();
    return _conversations.where((conversation) {
      // Search by participant names
      final participantMatch = conversation.participants.any((participant) =>
          participant.displayName.toLowerCase().contains(lowercaseQuery) ||
          participant.username.toLowerCase().contains(lowercaseQuery));
      
      // Search by group name
      final groupNameMatch = conversation.groupName?.toLowerCase().contains(lowercaseQuery) ?? false;
      
      // Search by last message content
      final messageMatch = conversation.lastMessage?.content.toLowerCase().contains(lowercaseQuery) ?? false;
      
      return participantMatch || groupNameMatch || messageMatch;
    }).toList();
  }

  // Get conversation by participant ID (for direct messages)
  Conversation? getConversationByParticipant(String participantId) {
    try {
      return _conversations.firstWhere(
        (conv) => !conv.isGroup && conv.participantIds.contains(participantId),
      );
    } catch (e) {
      return null;
    }
  }

  // WebSocket convenience methods
  void startTyping(String conversationId) {
    if (_webSocketService.isConnected) {
      _webSocketService.startTyping(conversationId);
    }
  }
  
  void stopTyping(String conversationId) {
    if (_webSocketService.isConnected) {
      _webSocketService.stopTyping(conversationId);
    }
  }
  
  void reactToMessageWebSocket(String messageId, String conversationId, String emoji) {
    if (_webSocketService.isConnected) {
      _webSocketService.reactToMessage(
        messageId: messageId,
        conversationId: conversationId,
        emoji: emoji,
      );
    }
  }
  
  void leaveConversationRoom(String conversationId) {
    _webSocketService.leaveConversation(conversationId);
  }
  
  void markMessagesReadWebSocket(String conversationId, List<String> messageIds) {
    if (_webSocketService.isConnected && messageIds.isNotEmpty) {
      _webSocketService.markMessagesRead(
        conversationId: conversationId,
        messageIds: messageIds,
      );
    }
  }

  // Clear all data (for logout)
  void clearData() {
    _conversations.clear();
    _conversationMessages.clear();
    _loadingMessages.clear();
    _hasMoreMessages.clear();
    _messagePage.clear();
    _messageErrors.clear();
    _sendingMessage.clear();
    _typingUsers.clear();
    _activeConversationId = null;
    _conversationsPage = 1;
    _hasMoreConversations = true;
    _isLoadingConversations = false;
    _conversationsError = null;
    _webSocketService.disconnect();
    notifyListeners();
  }
}