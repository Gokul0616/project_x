import 'package:flutter/material.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:uuid/uuid.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'dart:convert';
import 'package:logging/logging.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../config/api_config.dart';
import '../providers/auth_provider.dart';
import '../services/api_service.dart';

enum CallType { voice, video }

enum CallState { idle, calling, ringing, connected, ended }

class CallService extends ChangeNotifier {
  static final CallService _instance = CallService._internal();
  factory CallService() => _instance;
  CallService._internal();

  // WebRTC components
  RTCPeerConnection? _peerConnection;
  RTCDataChannel? _dataChannel;
  MediaStream? _localStream;
  MediaStream? _remoteStream;

  // Call state
  CallState _callState = CallState.idle;
  CallType _callType = CallType.voice;
  String? _currentCallId;
  String? _remoteUserId;
  bool _isInitiator = false;
  bool _isMuted = false;
  bool _isCameraOn = true;
  bool _isSpeakerOn = true;

  // Socket connection
  IO.Socket? _socket;
  
  // User ID cache
  String? _currentUserId;

  // Getters
  CallState get callState => _callState;
  CallType get callType => _callType;
  String? get currentCallId => _currentCallId;
  String? get remoteUserId => _remoteUserId;
  bool get isInitiator => _isInitiator;
  bool get isMuted => _isMuted;
  bool get isCameraOn => _isCameraOn;
  bool get isSpeakerOn => _isSpeakerOn;
  MediaStream? get localStream => _localStream;
  MediaStream? get remoteStream => _remoteStream;

  // Initialize WebRTC
  Future<void> initialize() async {
    try {
      // Initialize WebRTC
      await _initializePeerConnection();

      // Connect to signaling server
      await _connectToSignalingServer();

      Logger('CallService').info('CallService initialized successfully');
    } catch (e) {
      Logger('CallService').severe('Error initializing CallService', e);
      rethrow;
    }
  }

  Future<void> _initializePeerConnection() async {
    // Create peer connection
    final configuration = <String, dynamic>{
      'iceServers': [
        {'urls': 'stun:stun.l.google.com:19302'},
        {'urls': 'stun:stun1.l.google.com:19302'},
      ],
    };

    _peerConnection = await createPeerConnection(configuration);

    // Set up event handlers
    _peerConnection!.onIceCandidate = (candidate) {
      if (candidate != null) {
        _sendSignalingMessage('ice_candidate', {
          'candidate': candidate.toMap(),
        });
      }
    };

    _peerConnection!.onAddStream = (stream) {
      _remoteStream = stream;
      notifyListeners();
    };

    _peerConnection!.onRemoveStream = (stream) {
      _remoteStream = null;
      notifyListeners();
    };

    _peerConnection!.onDataChannel = (channel) {
      _dataChannel = channel;
      _setupDataChannel();
    };

    Logger('CallService').info('Peer connection initialized');
  }

  Future<void> _connectToSignalingServer() async {
    try {
      // Get authentication token
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');
      
      if (token == null) {
        Logger('CallService').severe('No authentication token found');
        return;
      }

      _socket = IO.io(ApiConfig.baseUrl.replaceAll('/api', ''), <String, dynamic>{
        'transports': ['websocket'],
        'autoConnect': true,
        'auth': {
          'token': token,
        },
      });

      _socket!.onConnect((_) {
        Logger('CallService').info('Connected to signaling server');
      });

      _socket!.onDisconnect((_) {
        Logger('CallService').info('Disconnected from signaling server');
      });

      _socket!.onConnectError((error) {
        Logger('CallService').severe('Socket connection error: $error');
      });

      // Listen for signaling messages
      _socket!.on('incoming_call', (data) => _handleIncomingCall(data));
      _socket!.on('call_accepted', (data) => _handleCallAccepted(data));
      _socket!.on('call_rejected', (data) => _handleCallRejected(data));
      _socket!.on('call_ended', (data) => _handleCallEnd(data));
      _socket!.on('webrtc_offer', (data) => _handleWebRTCOffer(data));
      _socket!.on('webrtc_answer', (data) => _handleWebRTCAnswer(data));
      _socket!.on('webrtc_ice_candidate', (data) => _handleWebRTCIceCandidate(data));
    } catch (e) {
      Logger('CallService').severe('Error connecting to signaling server', e);
    }
  }

  Future<void> _setupDataChannel() async {
    if (_dataChannel != null) {
      _dataChannel!.onMessage = (message) {
        Logger('CallService').info('Received data channel message: ${message.text}');
      };

      _dataChannel!.onDataChannelState = (state) {
        Logger('CallService').info('Data channel state: $state');
      };
    }
  }

  // Call management methods
  Future<String?> startCall(String remoteUserId, CallType callType) async {
    try {
      _remoteUserId = remoteUserId;
      _callType = callType;
      _isInitiator = true;
      _callState = CallState.calling;

      notifyListeners();

      // Get local media stream
      await _getLocalMediaStream();

      // Create data channel for call metadata
      _dataChannel = await _peerConnection!.createDataChannel(
        'call',
        RTCDataChannelInit()..ordered = true,
      );
      _setupDataChannel();

      // Start call via backend API
      final response =
          await ApiService.makeRequest('POST', '/api/calls/start', {
            'recipientId': remoteUserId,
            'callType': callType == CallType.video ? 'video' : 'voice',
          });

      if (response.statusCode == 201) {
        final data = jsonDecode(response.body);
        _currentCallId = data['callId'];
        Logger('CallService').info('Call started successfully: $_currentCallId');
        return _currentCallId;
      } else {
        final error = jsonDecode(response.body);
        Logger('CallService').severe('Error starting call: ${error['message']}');
        _callState = CallState.idle;
        notifyListeners();
        return null;
      }
    } catch (e) {
      Logger('CallService').severe('Error starting call', e);
      _callState = CallState.idle;
      notifyListeners();
      return null;
    }
  }

  Future<bool> acceptCall(String callId, CallType callType) async {
    try {
      _currentCallId = callId;
      _callType = callType;
      _isInitiator = false;
      _callState = CallState.connected;

      // Get local media stream
      await _getLocalMediaStream();

      notifyListeners();
      Logger('CallService').info('Call accepted successfully');
      return true;
    } catch (e) {
      Logger('CallService').severe('Error accepting call', e);
      return false;
    }
  }

  Future<void> endCall() async {
    try {
      _sendSignalingMessage('call_end', {'callId': _currentCallId});

      await _cleanup();
      Logger('CallService').info('Call ended successfully');
    } catch (e) {
      Logger('CallService').severe('Error ending call', e);
    }
  }

  Future<void> _getLocalMediaStream() async {
    final Map<String, dynamic> mediaConstraints = {
      'audio': true,
      'video': _callType == CallType.video,
    };

    try {
      _localStream = await navigator.mediaDevices.getUserMedia(
        mediaConstraints,
      );

      // Add local stream to peer connection
      for (var track in _localStream!.getTracks()) {
        await _peerConnection!.addTrack(track, _localStream!);
      }

      notifyListeners();
      Logger('CallService').info('Local media stream obtained');
    } catch (e) {
      Logger('CallService').severe('Error getting local media stream', e);
      rethrow;
    }
  }

  // Signaling message handlers
  void _handleIncomingCall(dynamic data) {
    if (_callState != CallState.idle) {
      // Busy, reject the call
      _sendCallRejectResponse(data['callId'], 'busy');
      return;
    }

    _currentCallId = data['callId'];
    _remoteUserId = data['callerId'];
    _callType = data['callType'] == 'video' ? CallType.video : CallType.voice;
    _isInitiator = false;
    _callState = CallState.ringing;

    notifyListeners();
    Logger('CallService').info('Incoming call received from ${data['callerName']}');
  }

  void _handleCallAccepted(dynamic data) {
    if (data['callId'] == _currentCallId) {
      _callState = CallState.connected;
      notifyListeners();
      Logger('CallService').info('Call accepted by recipient');
    }
  }

  void _handleCallRejected(dynamic data) {
    if (data['callId'] == _currentCallId) {
      _callState = CallState.ended;
      notifyListeners();
      Logger('CallService').info('Call rejected by recipient');
      _cleanup();
    }
  }

  void _handleWebRTCOffer(dynamic data) async {
    try {
      if (data['callId'] == _currentCallId) {
        final offer = RTCSessionDescription(
          data['offer']['sdp'],
          data['offer']['type'],
        );

        await _peerConnection!.setRemoteDescription(offer);
        
        // Create answer
        final answer = await _peerConnection!.createAnswer();
        await _peerConnection!.setLocalDescription(answer);

        // Send answer back
        _sendWebRTCAnswer(answer);
        
        Logger('CallService').info('WebRTC offer processed and answer sent');
      }
    } catch (e) {
      Logger('CallService').severe('Error handling WebRTC offer', e);
    }
  }

  void _handleWebRTCAnswer(dynamic data) async {
    try {
      if (data['callId'] == _currentCallId) {
        final answer = RTCSessionDescription(
          data['answer']['sdp'],
          data['answer']['type'],
        );

        await _peerConnection!.setRemoteDescription(answer);
        _callState = CallState.connected;
        notifyListeners();
        Logger('CallService').info('WebRTC answer received and processed');
      }
    } catch (e) {
      Logger('CallService').severe('Error handling WebRTC answer', e);
    }
  }

  void _handleWebRTCIceCandidate(dynamic data) async {
    try {
      if (data['callId'] == _currentCallId) {
        final candidate = RTCIceCandidate(
          data['candidate']['candidate'],
          data['candidate']['sdpMid'],
          data['candidate']['sdpMLineIndex'],
        );

        await _peerConnection!.addCandidate(candidate);
        Logger('CallService').info('ICE candidate added successfully');
      }
    } catch (e) {
      Logger('CallService').severe('Error adding ICE candidate', e);
    }
  }

  void _handleCallEnd(dynamic data) {
    if (data['callId'] == _currentCallId) {
      _cleanup();
      Logger('CallService').info('Call ended by remote user');
    }
  }

  void _sendCallRejectResponse(String callId, String reason) {
    try {
      ApiService.makeRequest('POST', '/calls/reject', {
        'callId': callId,
      });
    } catch (e) {
      Logger('CallService').severe('Error sending call reject response', e);
    }
  }

  void _sendWebRTCOffer(RTCSessionDescription offer) {
    try {
      ApiService.makeRequest('POST', '/calls/offer', {
        'callId': _currentCallId,
        'offer': {
          'sdp': offer.sdp,
          'type': offer.type,
        },
      });
    } catch (e) {
      Logger('CallService').severe('Error sending WebRTC offer', e);
    }
  }

  void _sendWebRTCAnswer(RTCSessionDescription answer) {
    try {
      ApiService.makeRequest('POST', '/calls/answer', {
        'callId': _currentCallId,
        'answer': {
          'sdp': answer.sdp,
          'type': answer.type,
        },
      });
    } catch (e) {
      Logger('CallService').severe('Error sending WebRTC answer', e);
    }
  }

  void _sendICECandidate(RTCIceCandidate candidate) {
    try {
      ApiService.makeRequest('POST', '/calls/ice-candidate', {
        'callId': _currentCallId,
        'candidate': {
          'candidate': candidate.candidate,
          'sdpMid': candidate.sdpMid,
          'sdpMLineIndex': candidate.sdpMLineIndex,
        },
      });
    } catch (e) {
      Logger('CallService').severe('Error sending ICE candidate', e);
    }
  }

  String? _getCurrentUserId() {
    // Try to get user ID from cached value first
    if (_currentUserId != null) {
      return _currentUserId;
    }
    
    // If not cached, we'll need to get it from auth provider or shared preferences
    // For now, this will be set during initialization
    Logger('CallService').warning('Current user ID not available');
    return null;
  }

  // Helper method to set current user ID
  void setCurrentUserId(String userId) {
    _currentUserId = userId;
  }

  // Call controls
  Future<void> toggleMute() async {
    if (_localStream != null) {
      for (var track in _localStream!.getAudioTracks()) {
        track.enabled = !track.enabled;
      }
      _isMuted = !_isMuted;
      notifyListeners();
    }
  }

  Future<void> toggleCamera() async {
    if (_localStream != null && _callType == CallType.video) {
      for (var track in _localStream!.getVideoTracks()) {
        track.enabled = !track.enabled;
      }
      _isCameraOn = !_isCameraOn;
      notifyListeners();
    }
  }

  Future<void> toggleSpeaker() async {
    // This would control audio output device
    _isSpeakerOn = !_isSpeakerOn;
    notifyListeners();
  }

  Future<void> switchCamera() async {
    if (_localStream != null) {
      // Switch between front and back camera
      await Helper.switchCamera(_localStream!.getVideoTracks()[0]);
    }
  }

  Future<void> _cleanup() async {
    try {
      // Close data channel
      _dataChannel?.close();

      // Close peer connection
      _peerConnection?.close();

      // Stop local stream
      _localStream?.getTracks().forEach((track) => track.stop());

      // Reset state
      _callState = CallState.idle;
      _currentCallId = null;
      _remoteUserId = null;
      _isInitiator = false;
      _localStream = null;
      _remoteStream = null;
      _dataChannel = null;
      _peerConnection = null;

      notifyListeners();
    } catch (e) {
      Logger('CallService').severe('Error during cleanup', e);
    }
  }

  void dispose() {
    _cleanup();
    _socket?.disconnect();
    super.dispose();
  }
}
