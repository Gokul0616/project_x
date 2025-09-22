import 'package:flutter/material.dart';
import '../models/tweet_model.dart';

class UploadProvider with ChangeNotifier {
  bool _isUploading = false;
  double _uploadProgress = 0.0;
  String _uploadStatus = '';
  Tweet? _uploadedTweet;
  List<Map<String, dynamic>> _uploadingMediaFiles = [];
  
  bool get isUploading => _isUploading;
  double get uploadProgress => _uploadProgress;
  String get uploadStatus => _uploadStatus;
  Tweet? get uploadedTweet => _uploadedTweet;
  List<Map<String, dynamic>> get uploadingMediaFiles => _uploadingMediaFiles;

  void startUpload({
    required String content,
    List<Map<String, dynamic>>? mediaFiles,
  }) {
    _isUploading = true;
    _uploadProgress = 0.0;
    _uploadStatus = 'Preparing upload...';
    _uploadedTweet = null;
    _uploadingMediaFiles = mediaFiles ?? [];
    notifyListeners();
  }

  void updateProgress(double progress, String status) {
    _uploadProgress = progress;
    _uploadStatus = status;
    notifyListeners();
  }

  void completeUpload(Tweet tweet) {
    _isUploading = false;
    _uploadProgress = 1.0;
    _uploadStatus = 'Upload complete!';
    _uploadedTweet = tweet;
    notifyListeners();
    
    // Clear after 5 seconds as requested
    Future.delayed(const Duration(seconds: 5), () {
      if (!_isUploading) { // Only clear if not uploading something else
        clearUpload();
      }
    });
  }

  void failUpload(String error) {
    _isUploading = false;
    _uploadProgress = 0.0;
    _uploadStatus = 'Upload failed: $error';
    _uploadedTweet = null;
    notifyListeners();
    
    // Clear after a delay
    Future.delayed(const Duration(seconds: 3), () {
      clearUpload();
    });
  }

  void clearUpload() {
    _isUploading = false;
    _uploadProgress = 0.0;
    _uploadStatus = '';
    _uploadedTweet = null;
    _uploadingMediaFiles = [];
    notifyListeners();
  }
}