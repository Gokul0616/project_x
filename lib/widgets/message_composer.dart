import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'dart:io';
import '../providers/message_provider.dart';

class MessageComposer extends StatefulWidget {
  final TextEditingController controller;
  final Function(String content, {List<String>? mediaFiles}) onSendMessage;
  final Function(bool isTyping) onTypingChanged;
  final String conversationId;

  const MessageComposer({
    super.key,
    required this.controller,
    required this.onSendMessage,
    required this.onTypingChanged,
    required this.conversationId,
  });

  @override
  State<MessageComposer> createState() => _MessageComposerState();
}

class _MessageComposerState extends State<MessageComposer> {
  final FocusNode _focusNode = FocusNode();
  final ImagePicker _imagePicker = ImagePicker();
  
  bool _isComposing = false;
  List<File> _selectedMedia = [];
  bool _isRecording = false;

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onTextChanged);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onTextChanged);
    _focusNode.dispose();
    super.dispose();
  }

  void _onTextChanged() {
    final isComposing = widget.controller.text.trim().isNotEmpty;
    if (_isComposing != isComposing) {
      setState(() {
        _isComposing = isComposing;
      });
      widget.onTypingChanged(isComposing);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<MessageProvider>(
      builder: (context, messageProvider, child) {
        final isSending = messageProvider.isSendingMessage(widget.conversationId);
        
        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Theme.of(context).scaffoldBackgroundColor,
            border: Border(
              top: BorderSide(
                color: Theme.of(context).dividerColor,
                width: 0.5,
              ),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Media preview
              if (_selectedMedia.isNotEmpty) ...[
                _buildMediaPreview(),
                const SizedBox(height: 12),
              ],

              // Input row
              Row(
                children: [
                  // Media attachment button
                  IconButton(
                    icon: const Icon(Icons.add),
                    onPressed: isSending ? null : _showAttachmentOptions,
                    tooltip: 'Add media',
                  ),

                  // Text input field
                  Expanded(
                    child: Container(
                      constraints: const BoxConstraints(maxHeight: 120),
                      decoration: BoxDecoration(
                        color: Theme.of(context).cardColor,
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(
                          color: Theme.of(context).dividerColor,
                        ),
                      ),
                      child: TextField(
                        controller: widget.controller,
                        focusNode: _focusNode,
                        enabled: !isSending,
                        maxLines: null,
                        textCapitalization: TextCapitalization.sentences,
                        decoration: const InputDecoration(
                          hintText: 'Type a message...',
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                          border: InputBorder.none,
                        ),
                        onSubmitted: _canSend() ? (_) => _sendMessage() : null,
                      ),
                    ),
                  ),

                  const SizedBox(width: 8),

                  // Send/Voice button
                  Container(
                    decoration: BoxDecoration(
                      color: Theme.of(context).primaryColor,
                      shape: BoxShape.circle,
                    ),
                    child: IconButton(
                      icon: Icon(
                        _canSend() 
                            ? Icons.send 
                            : (_isRecording ? Icons.stop : Icons.mic),
                        color: Colors.white,
                      ),
                      onPressed: isSending 
                          ? null 
                          : (_canSend() ? _sendMessage : _handleVoiceButton),
                    ),
                  ),
                ],
              ),

              // Connection status
              if (!messageProvider.isWebSocketConnected) ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(
                      Icons.wifi_off,
                      size: 16,
                      color: Colors.orange.shade600,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Offline - messages will be sent when reconnected',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.orange.shade600,
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _buildMediaPreview() {
    return Container(
      height: 80,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: _selectedMedia.length,
        itemBuilder: (context, index) {
          final file = _selectedMedia[index];
          return Container(
            margin: const EdgeInsets.only(right: 8),
            child: Stack(
              children: [
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    image: DecorationImage(
                      image: FileImage(file),
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
                Positioned(
                  top: 4,
                  right: 4,
                  child: GestureDetector(
                    onTap: () => _removeMedia(index),
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(
                        color: Colors.black54,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.close,
                        color: Colors.white,
                        size: 16,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  bool _canSend() {
    return (_isComposing || _selectedMedia.isNotEmpty) && !_isRecording;
  }

  void _sendMessage() {
    if (!_canSend()) return;

    final content = widget.controller.text.trim();
    final mediaFiles = _selectedMedia.map((file) => file.path).toList();

    if (content.isNotEmpty || mediaFiles.isNotEmpty) {
      widget.onSendMessage(
        content,
        mediaFiles: mediaFiles.isNotEmpty ? mediaFiles : null,
      );
      
      // Clear input
      widget.controller.clear();
      setState(() {
        _selectedMedia.clear();
        _isComposing = false;
      });
      
      widget.onTypingChanged(false);
    }
  }

  void _showAttachmentOptions() {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return Container(
          padding: const EdgeInsets.symmetric(vertical: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.camera_alt, color: Colors.blue),
                title: const Text('Camera'),
                onTap: () {
                  Navigator.pop(context);
                  _pickImage(ImageSource.camera);
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_library, color: Colors.green),
                title: const Text('Photo Library'),
                onTap: () {
                  Navigator.pop(context);
                  _pickImage(ImageSource.gallery);
                },
              ),
              ListTile(
                leading: const Icon(Icons.videocam, color: Colors.red),
                title: const Text('Video'),
                onTap: () {
                  Navigator.pop(context);
                  _pickVideo();
                },
              ),
              ListTile(
                leading: const Icon(Icons.insert_drive_file, color: Colors.orange),
                title: const Text('File'),
                onTap: () {
                  Navigator.pop(context);
                  _showComingSoon('File attachments');
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: source,
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 80,
      );
      
      if (image != null) {
        setState(() {
          _selectedMedia.add(File(image.path));
        });
      }
    } catch (e) {
      _showError('Failed to pick image: $e');
    }
  }

  Future<void> _pickVideo() async {
    try {
      final XFile? video = await _imagePicker.pickVideo(
        source: ImageSource.gallery,
        maxDuration: const Duration(minutes: 5),
      );
      
      if (video != null) {
        setState(() {
          _selectedMedia.add(File(video.path));
        });
      }
    } catch (e) {
      _showError('Failed to pick video: $e');
    }
  }

  void _removeMedia(int index) {
    setState(() {
      _selectedMedia.removeAt(index);
    });
  }

  void _handleVoiceButton() {
    if (_isRecording) {
      _stopRecording();
    } else {
      _startRecording();
    }
  }

  void _startRecording() {
    setState(() {
      _isRecording = true;
    });
    
    // TODO: Implement voice recording
    _showComingSoon('Voice messages');
    
    // Reset state for now
    setState(() {
      _isRecording = false;
    });
  }

  void _stopRecording() {
    setState(() {
      _isRecording = false;
    });
    
    // TODO: Process and send voice message
  }

  void _showError(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _showComingSoon(String feature) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('$feature coming soon!'),
          backgroundColor: Colors.blue,
        ),
      );
    }
  }
}