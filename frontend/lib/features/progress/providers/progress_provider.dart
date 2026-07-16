import 'package:flutter/foundation.dart';

import '../../../core/network/api_exception.dart';
import '../models/progress_response.dart';
import '../services/progress_service.dart';

class ProgressProvider extends ChangeNotifier {
  final ProgressService _progressService;

  List<ProgressResponse> _progressList = [];
  ProgressResponse? _selectedTopicProgress;
  bool _isLoading = false;
  bool _isLoadingTopic = false;
  String? _errorMessage;

  ProgressProvider({required ProgressService progressService})
    : _progressService = progressService;

  List<ProgressResponse> get progressList => _progressList;
  ProgressResponse? get selectedTopicProgress => _selectedTopicProgress;
  bool get isLoading => _isLoading;
  bool get isLoadingTopic => _isLoadingTopic;
  String? get errorMessage => _errorMessage;

  Future<void> loadProgress() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _progressList = await _progressService.getMyProgress();
    } on ApiException catch (e) {
      _errorMessage = e.message;
      debugPrint('Progress load failed: ${e.message}');
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadTopicProgress(String topicCode) async {
    _isLoadingTopic = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _selectedTopicProgress = await _progressService.getTopicProgress(
        topicCode,
      );
    } on ApiException catch (e) {
      _errorMessage = e.message;
      debugPrint('Topic progress load failed: ${e.message}');
      rethrow;
    } finally {
      _isLoadingTopic = false;
      notifyListeners();
    }
  }
}
