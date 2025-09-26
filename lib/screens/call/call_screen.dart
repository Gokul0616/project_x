import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'dart:async';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import '../../services/call_service.dart';
import '../../utils/app_theme.dart';

class CallScreen extends StatefulWidget {
  final String remoteUserId;
  final String remoteUserName;
  final bool isIncoming;
  final CallType callType;
  final String? callId;

  const CallScreen({
    super.key,
    required this.remoteUserId,
    required this.remoteUserName,
    this.isIncoming = false,
    required this.callType,
    this.callId,
  });

  @override
  State<CallScreen> createState() => _CallScreenState();
}

class _CallScreenState extends State<CallScreen> {
  late CallService _callService;
  bool _showControls = true;
  Timer? _hideControlsTimer;

  // Video renderers
  RTCVideoRenderer _localRenderer = RTCVideoRenderer();
  RTCVideoRenderer _remoteRenderer = RTCVideoRenderer();

  @override
  void initState() {
    super.initState();
    _callService = Provider.of<CallService>(context, listen: false);

    // Initialize renderers
    _localRenderer.initialize();
    _remoteRenderer.initialize();

    // Set up orientation lock for video calls
    if (widget.callType == CallType.video) {
      SystemChrome.setPreferredOrientations([
        DeviceOrientation.landscapeLeft,
        DeviceOrientation.landscapeRight,
      ]);
    }

    // Auto-hide controls after 5 seconds
    _startHideControlsTimer();

    // Set up stream listeners
    _setupStreamListeners();
  }

  void _setupStreamListeners() {
    // Listen for stream changes and update renderers
    _callService.addListener(() {
      if (_callService.localStream != null) {
        _localRenderer.srcObject = _callService.localStream;
      }
      if (_callService.remoteStream != null) {
        _remoteRenderer.srcObject = _callService.remoteStream;
      }
    });
  }

  @override
  void dispose() {
    _hideControlsTimer?.cancel();

    // Restore orientation
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);

    super.dispose();
  }

  void _startHideControlsTimer() {
    _hideControlsTimer?.cancel();
    _hideControlsTimer = Timer(const Duration(seconds: 5), () {
      if (mounted) {
        setState(() {
          _showControls = false;
        });
      }
    });
  }

  void _showControlsTemporarily() {
    setState(() {
      _showControls = true;
    });
    _startHideControlsTimer();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: GestureDetector(
        onTap: _showControlsTemporarily,
        child: Stack(
          children: [
            // Main video/audio view
            _buildMainView(),

            // Call info header
            if (_showControls) _buildCallInfo(),

            // Call controls
            if (_showControls) _buildCallControls(),

            // Incoming call overlay
            if (widget.isIncoming &&
                _callService.callState == CallState.ringing)
              _buildIncomingCallOverlay(),
          ],
        ),
      ),
    );
  }

  Widget _buildMainView() {
    return Consumer<CallService>(
      builder: (context, callService, child) {
        if (widget.callType == CallType.video) {
          return Stack(
            children: [
              // Remote video (main view)
              if (callService.remoteStream != null)
                RTCVideoView(
                  _remoteRenderer,
                  objectFit: RTCVideoViewObjectFit.RTCVideoViewObjectFitCover,
                )
              else
                Container(
                  color: Colors.grey.shade900,
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircleAvatar(
                          radius: 50,
                          backgroundColor: AppTheme.twitterBlue,
                          child: Text(
                            widget.remoteUserName[0].toUpperCase(),
                            style: const TextStyle(
                              fontSize: 36,
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          widget.remoteUserName,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _getCallStatusText(),
                          style: TextStyle(
                            color: Colors.grey.shade400,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

              // Local video (picture-in-picture)
              if (callService.localStream != null && callService.isCameraOn)
                Positioned(
                  top: 40,
                  right: 20,
                  width: 120,
                  height: 160,
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.white, width: 2),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: RTCVideoView(
                        _localRenderer,
                        mirror: true,
                        objectFit:
                            RTCVideoViewObjectFit.RTCVideoViewObjectFitCover,
                      ),
                    ),
                  ),
                ),
            ],
          );
        } else {
          // Voice call view
          return Container(
            color: Colors.grey.shade900,
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircleAvatar(
                    radius: 60,
                    backgroundColor: AppTheme.twitterBlue,
                    child: Text(
                      widget.remoteUserName[0].toUpperCase(),
                      style: const TextStyle(
                        fontSize: 48,
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    widget.remoteUserName,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    _getCallStatusText(),
                    style: TextStyle(color: Colors.grey.shade400, fontSize: 18),
                  ),
                  const SizedBox(height: 40),
                  // Audio visualization placeholder
                  Container(
                    width: 200,
                    height: 60,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade800,
                      borderRadius: BorderRadius.circular(30),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(
                        5,
                        (index) => AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          margin: const EdgeInsets.symmetric(horizontal: 2),
                          width: 4,
                          height: 20 + (index % 2 == 0 ? 20 : 10),
                          decoration: BoxDecoration(
                            color: callService.isMuted
                                ? Colors.red
                                : AppTheme.twitterBlue,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        }
      },
    );
  }

  Widget _buildCallInfo() {
    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: Container(
        padding: const EdgeInsets.only(top: 50, left: 20, right: 20),
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.black54, Colors.transparent],
          ),
        ),
        child: Column(
          children: [
            Text(
              widget.remoteUserName,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              _getCallStatusText(),
              style: TextStyle(color: Colors.grey.shade300, fontSize: 14),
            ),
            const SizedBox(height: 8),
            Text(
              _getCallDuration(),
              style: const TextStyle(color: Colors.white, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCallControls() {
    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: Container(
        padding: const EdgeInsets.only(bottom: 50, left: 20, right: 20),
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.bottomCenter,
            end: Alignment.topCenter,
            colors: [Colors.black54, Colors.transparent],
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            // Mute button
            _buildControlButton(
              icon: _callService.isMuted ? Icons.mic_off : Icons.mic,
              color: _callService.isMuted ? Colors.red : Colors.white,
              onPressed: _callService.toggleMute,
            ),

            // Video toggle (only for video calls)
            if (widget.callType == CallType.video)
              _buildControlButton(
                icon: _callService.isCameraOn
                    ? Icons.videocam
                    : Icons.videocam_off,
                color: _callService.isCameraOn ? Colors.white : Colors.red,
                onPressed: _callService.toggleCamera,
              ),

            // Speaker toggle
            _buildControlButton(
              icon: _callService.isSpeakerOn
                  ? Icons.volume_up
                  : Icons.volume_off,
              color: _callService.isSpeakerOn ? Colors.white : Colors.grey,
              onPressed: _callService.toggleSpeaker,
            ),

            // Switch camera (only for video calls)
            if (widget.callType == CallType.video)
              _buildControlButton(
                icon: Icons.switch_camera,
                color: Colors.white,
                onPressed: _callService.switchCamera,
              ),

            // End call button
            _buildControlButton(
              icon: Icons.call_end,
              color: Colors.red,
              size: 28,
              onPressed: () {
                _callService.endCall();
                Navigator.pop(context);
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildControlButton({
    required IconData icon,
    required Color color,
    required VoidCallback onPressed,
    double size = 24,
  }) {
    return Container(
      width: 60,
      height: 60,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        shape: BoxShape.circle,
      ),
      child: IconButton(
        icon: Icon(icon, color: color, size: size),
        onPressed: onPressed,
      ),
    );
  }

  Widget _buildIncomingCallOverlay() {
    return Container(
      color: Colors.black.withOpacity(0.8),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircleAvatar(
              radius: 50,
              backgroundColor: AppTheme.twitterBlue,
              child: Text(
                widget.remoteUserName[0].toUpperCase(),
                style: const TextStyle(
                  fontSize: 36,
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              widget.remoteUserName,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 28,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              '${widget.callType == CallType.video ? 'Video' : 'Voice'} Call',
              style: TextStyle(color: Colors.grey.shade300, fontSize: 18),
            ),
            const SizedBox(height: 60),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                // Decline button
                Container(
                  width: 70,
                  height: 70,
                  decoration: const BoxDecoration(
                    color: Colors.red,
                    shape: BoxShape.circle,
                  ),
                  child: IconButton(
                    icon: const Icon(
                      Icons.call_end,
                      color: Colors.white,
                      size: 32,
                    ),
                    onPressed: () {
                      _callService.endCall();
                      Navigator.pop(context);
                    },
                  ),
                ),

                // Accept button
                Container(
                  width: 70,
                  height: 70,
                  decoration: BoxDecoration(
                    color: Colors.green,
                    shape: BoxShape.circle,
                  ),
                  child: IconButton(
                    icon: Icon(
                      widget.callType == CallType.video
                          ? Icons.videocam
                          : Icons.call,
                      color: Colors.white,
                      size: 32,
                    ),
                    onPressed: () async {
                      final success = await _callService.acceptCall(
                        _callService.currentCallId!,
                        widget.callType,
                      );
                      if (success) {
                        setState(() {});
                      }
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _getCallStatusText() {
    switch (_callService.callState) {
      case CallState.calling:
        return 'Calling...';
      case CallState.ringing:
        return 'Ringing...';
      case CallState.connected:
        return 'Connected';
      case CallState.ended:
        return 'Call ended';
      default:
        return '';
    }
  }

  String _getCallDuration() {
    // This would be implemented with actual call duration tracking
    return '00:00';
  }
}
