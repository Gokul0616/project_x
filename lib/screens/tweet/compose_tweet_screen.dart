import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../../providers/tweet_provider.dart';
import '../../utils/app_theme.dart';
import '../../widgets/mention_suggestions.dart';
import '../../widgets/rich_tweet_text.dart';

class ComposeTweetScreen extends StatefulWidget {
  const ComposeTweetScreen({super.key});

  @override
  State<ComposeTweetScreen> createState() => _ComposeTweetScreenState();
}

class _ComposeTweetScreenState extends State<ComposeTweetScreen> {
  final _tweetController = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  bool _isLoading = false;
  File? _selectedImage;
  final ImagePicker _picker = ImagePicker();

  // Mention functionality
  bool _showMentionSuggestions = false;
  String _mentionQuery = '';
  int _mentionStartIndex = -1;
  OverlayEntry? _overlayEntry;

  @override
  void initState() {
    super.initState();
    _tweetController.addListener(() {
      setState(() {}); // Update UI when text changes
      _handleTextChange();
    });
  }

  @override
  void dispose() {
    _tweetController.dispose();
    _focusNode.dispose();
    _hideOverlay();
    super.dispose();
  }

  void _handleTextChange() {
    final text = _tweetController.text;
    final cursorPosition = _tweetController.selection.baseOffset;

    // Check if user is typing a mention
    if (cursorPosition > 0) {
      // Find the last @ symbol before cursor
      int atIndex = -1;
      for (int i = cursorPosition - 1; i >= 0; i--) {
        if (text[i] == '@') {
          atIndex = i;
          break;
        } else if (text[i] == ' ' || text[i] == '\n') {
          break;
        }
      }

      if (atIndex != -1) {
        // Extract the mention query (text after @)
        final query = text.substring(atIndex + 1, cursorPosition);
        // Only show suggestions if query doesn't contain spaces or newlines
        if (!query.contains(' ') && !query.contains('\n')) {
          setState(() {
            _mentionQuery = query;
            _mentionStartIndex = atIndex;
            _showMentionSuggestions = true;
          });
          _showOverlay();
          return;
        }
      }
    }

    // Hide suggestions if not typing a mention
    if (_showMentionSuggestions) {
      setState(() {
        _showMentionSuggestions = false;
        _mentionQuery = '';
        _mentionStartIndex = -1;
      });
      _hideOverlay();
    }
  }

  void _showOverlay() {
    _hideOverlay(); // Remove existing overlay first

    _overlayEntry = OverlayEntry(
      builder: (context) => Positioned(
        left: 16,
        right: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 200,
        child: Material(
          color: Colors.transparent,
          child: MentionSuggestions(
            query: _mentionQuery,
            onUserSelected: _onUserSelected,
            onClose: _hideSuggestions,
          ),
        ),
      ),
    );

    Overlay.of(context).insert(_overlayEntry!);
  }

  void _hideOverlay() {
    _overlayEntry?.remove();
    _overlayEntry = null;
  }

  void _hideSuggestions() {
    setState(() {
      _showMentionSuggestions = false;
      _mentionQuery = '';
      _mentionStartIndex = -1;
    });
    _hideOverlay();
  }

  void _onUserSelected(String username, String displayName) {
    final text = _tweetController.text;
    final beforeMention = text.substring(0, _mentionStartIndex);
    final afterMention = text.substring(_tweetController.selection.baseOffset);

    final newText = '$beforeMention@$username $afterMention';
    _tweetController.text = newText;

    // Set cursor position after the mention
    final newCursorPosition = beforeMention.length + username.length + 2;
    _tweetController.selection = TextSelection.collapsed(
      offset: newCursorPosition,
    );

    _hideSuggestions();
    _focusNode.requestFocus();
  }

  Future<void> _pickImage() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1080,
        maxHeight: 1080,
        imageQuality: 85,
      );

      if (image != null) {
        setState(() {
          _selectedImage = File(image.path);
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error picking image: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _removeImage() {
    setState(() {
      _selectedImage = null;
    });
  }

  Future<void> _postTweet() async {
    if (_tweetController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please write something to tweet'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    final tweetProvider = Provider.of<TweetProvider>(context, listen: false);
    final result = await tweetProvider.createTweet(
      _tweetController.text.trim(),
    );

    setState(() {
      _isLoading = false;
    });

    if (result['success']) {
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Tweet posted successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['message']),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Compose Tweet'),
        actions: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: ElevatedButton(
              onPressed: _isLoading ? null : _postTweet,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.twitterBlue,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 20),
              ),
              child: _isLoading
                  ? const SizedBox(
                      height: 16,
                      width: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : const Text('Tweet'),
            ),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Tweet Input
            Expanded(
              child: Column(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _tweetController,
                      focusNode: _focusNode,
                      maxLines: null,
                      expands: true,
                      decoration: const InputDecoration(
                        hintText: "What's happening?",
                        border: InputBorder.none,
                        hintStyle: TextStyle(
                          fontSize: 20,
                          color: AppTheme.darkGray,
                        ),
                      ),
                      style: const TextStyle(fontSize: 20),
                      textAlignVertical: TextAlignVertical.top,
                    ),
                  ),

                  if (_selectedImage != null) ...[
                    const SizedBox(height: 16),
                    Stack(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.file(
                            _selectedImage!,
                            width: double.infinity,
                            height: 200,
                            fit: BoxFit.cover,
                          ),
                        ),
                        Positioned(
                          top: 8,
                          right: 8,
                          child: GestureDetector(
                            onTap: _removeImage,
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
                  ],
                ],
              ),
            ),

            // Media and Actions Row
            Row(
              children: [
                IconButton(
                  onPressed: _pickImage,
                  icon: const Icon(
                    Icons.image_outlined,
                    color: AppTheme.twitterBlue,
                  ),
                ),
                IconButton(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Video upload coming soon!'),
                      ),
                    );
                  },
                  icon: const Icon(
                    Icons.videocam_outlined,
                    color: AppTheme.twitterBlue,
                  ),
                ),
                IconButton(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('GIF search coming soon!')),
                    );
                  },
                  icon: const Icon(
                    Icons.gif_box_outlined,
                    color: AppTheme.twitterBlue,
                  ),
                ),
                const Spacer(),
              ],
            ),

            // Character Counter
            Padding(
              padding: const EdgeInsets.only(top: 8.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Spacer(),
                  Text(
                    '${_tweetController.text.length}/280',
                    style: TextStyle(
                      color: _tweetController.text.length > 280
                          ? Colors.red
                          : AppTheme.darkGray,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}
