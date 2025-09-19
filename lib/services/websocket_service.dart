import 'dart:async';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'package:shared_preferences/shared_preferences.dart';
import '../config/api_config.dart';
import '../models/message_model.dart';
import '../models/conversation_model.dart';

class WebSocketService {
  static final WebSocketService _instance = WebSocketService._internal();
  factory WebSocketService() => _instance;
  WebSocketService._internal();

  IO.Socket? _socket;
  bool _isConnected = false;
  String? _currentUserId;

  // Stream controllers for events
  final StreamController<Message> _messageController = StreamController<Message>.broadcast();
  final StreamController<Conversation> _conversationController = StreamController<Conversation>.broadcast();
  final StreamController<Map<String, dynamic>> _typingController = StreamController<Map<String, dynamic>>.broadcast();
  final StreamController<Map<String, dynamic>> _reactionController = StreamController<Map<String, dynamic>>.broadcast();
  final StreamController<Map<String, dynamic>> _readReceiptController = StreamController<Map<String, dynamic>>.broadcast();
  final StreamController<String> _connectionController = StreamController<String>.broadcast();

  // Getters for streams
  Stream<Message> get messageStream => _messageController.stream;
  Stream<Conversation> get conversationStream => _conversationController.stream;
  Stream<Map<String, dynamic>> get typingStream => _typingController.stream;
  Stream<Map<String, dynamic>> get reactionStream => _reactionController.stream;
  Stream<Map<String, dynamic>> get readReceiptStream => _readReceiptController.stream;
  Stream<String> get connectionStream => _connectionController.stream;

  bool get isConnected => _isConnected;
  String? get currentUserId => _currentUserId;

  Future<void> connect() async {
    if (_isConnected) return;

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');

      if (token == null) {
        print('No authentication token found');
        return;
      }

      // Extract base URL without /api prefix for socket connection
      String socketUrl = ApiConfig.baseUrl.replaceAll('/api', '');

      _socket = IO.io(socketUrl, <String, dynamic>{
        'transports': ['websocket'],
        'autoConnect': false,
        'auth': {
          'token': token,
        },
      });

      _setupEventListeners();
      _socket!.connect();

    } catch (e) {
      print('WebSocket connection error: $e');
      _connectionController.add('error');
    }
  }

  void _setupEventListeners() {
    _socket!.on('connect', (_) {
      print('Connected to WebSocket server');
      _isConnected = true;
      _connectionController.add('connected');
    });

    _socket!.on('disconnect', (_) {
      print('Disconnected from WebSocket server');
      _isConnected = false;
      _connectionController.add('disconnected');
    });

    _socket!.on('connect_error', (data) {
      print('WebSocket connection error: $data');
      _isConnected = false;
      _connectionController.add('error');
    });

    // Message events
    _socket!.on('new_message', (data) {
      try {
        final message = Message.fromJson(data['message']);
        _messageController.add(message);
      } catch (e) {
        print('Error parsing new message: $e');
      }
    });

    // Conversation updates
    _socket!.on('conversation_updated', (data) {
      try {
        final conversation = Conversation.fromJson(data['conversation']);
        _conversationController.add(conversation);
      } catch (e) {
        print('Error parsing conversation update: $e');
      }
    });

    // Typing indicators
    _socket!.on('user_typing', (data) {
      _typingController.add({
        'type': 'start',
        'userId': data['userId'],
        'username': data['username'],
        'conversationId': data['conversationId'],
      });
    });

    _socket!.on('user_stopped_typing', (data) {
      _typingController.add({
        'type': 'stop',
        'userId': data['userId'],
        'conversationId': data['conversationId'],
      });
    });

    // Message reactions
    _socket!.on('message_reaction_updated', (data) {
      _reactionController.add({
        'messageId': data['messageId'],
        'reactions': data['reactions'],
        'conversationId': data['conversationId'],
      });
    });

    // Read receipts
    _socket!.on('messages_read', (data) {
      _readReceiptController.add({
        'messageIds': data['messageIds'],
        'userId': data['userId'],
        'conversationId': data['conversationId'],
      });
    });

    // Error events
    _socket!.on('message_error', (data) {
      print('Message error: ${data['error']}');
    });

    _socket!.on('reaction_error', (data) {
      print('Reaction error: ${data['error']}');
    });
  }

  // Join a conversation room
  void joinConversation(String conversationId) {
    if (_isConnected && _socket != null) {
      _socket!.emit('join_conversation', conversationId);
    }
  }

  // Leave a conversation room
  void leaveConversation(String conversationId) {
    if (_isConnected && _socket != null) {
      _socket!.emit('leave_conversation', conversationId);
    }
  }

  // Send a message
  void sendMessage({
    required String conversationId,
    required String content,
    String? replyToId,
    List<Map<String, dynamic>>? mediaFiles,
  }) {
    if (_isConnected && _socket != null) {
      _socket!.emit('send_message', {
        'conversationId': conversationId,
        'content': content,
        'replyToId': replyToId,
        'mediaFiles': mediaFiles,
      });
    }
  }

  // React to a message
  void reactToMessage({
    required String messageId,
    required String conversationId,
    required String emoji,
  }) {
    if (_isConnected && _socket != null) {
      _socket!.emit('react_to_message', {
        'messageId': messageId,
        'conversationId': conversationId,
        'emoji': emoji,
      });
    }
  }

  // Send typing indicator
  void startTyping(String conversationId) {
    if (_isConnected && _socket != null) {
      _socket!.emit('typing_start', {
        'conversationId': conversationId,
      });
    }
  }

  void stopTyping(String conversationId) {
    if (_isConnected && _socket != null) {
      _socket!.emit('typing_stop', {
        'conversationId': conversationId,
      });
    }
  }

  // Mark messages as read
  void markMessagesRead({
    required String conversationId,
    required List<String> messageIds,
  }) {
    if (_isConnected && _socket != null) {
      _socket!.emit('mark_messages_read', {
        'conversationId': conversationId,
        'messageIds': messageIds,
      });
    }
  }

  // Disconnect
  void disconnect() {
    if (_socket != null) {
      _socket!.disconnect();
      _socket!.dispose();
      _socket = null;
    }
    _isConnected = false;
    _currentUserId = null;
  }

  // Dispose all resources
  void dispose() {
    disconnect();
    _messageController.close();
    _conversationController.close();
    _typingController.close();
    _reactionController.close();
    _readReceiptController.close();
    _connectionController.close();
  }

  // Reconnect if disconnected
  Future<void> reconnect() async {
    if (!_isConnected) {
      disconnect();
      await Future.delayed(const Duration(seconds: 2));
      await connect();
    }
  }

  // Check connection status and reconnect if needed
  void ensureConnection() {
    if (!_isConnected) {
      Timer(const Duration(seconds: 1), () {
        reconnect();
      });
    }
  }
}