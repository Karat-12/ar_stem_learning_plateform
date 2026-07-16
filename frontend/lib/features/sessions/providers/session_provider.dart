import 'package:flutter/foundation.dart';

import '../../../core/network/api_exception.dart';
import '../models/session_response.dart';
import '../services/session_service.dart';

class SessionProvider extends ChangeNotifier {
  final SessionService _sessionService;

  SessionResponse? _activeSession;
  bool _isStarting = false;
  bool _isEnding = false;
  String? _errorMessage;

  SessionProvider({required SessionService sessionService})
    : _sessionService = sessionService;

  SessionResponse? get activeSession => _activeSession;
  bool get isStarting => _isStarting;
  bool get isEnding => _isEnding;
  String? get errorMessage => _errorMessage;

  Future<void> startSession({
    required String domainCode,
    required String topicCode,
    required String activityCode,
  }) async {
    _isStarting = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final result = await _sessionService.startSession(
        domainCode: domainCode,
        topicCode: topicCode,
        activityCode: activityCode,
      );
      _activeSession = result;
      debugPrint('Session started: ${result.id}');
    } on ApiException catch (e) {
      _errorMessage = e.message;
      debugPrint('Session start failed: ${e.message}');
      rethrow;
    } finally {
      _isStarting = false;
      notifyListeners();
    }
  }

  Future<void> endSession() async {
    if (_activeSession == null) {
      return;
    }

    _isEnding = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final result = await _sessionService.endSession(_activeSession!.id);
      _activeSession = result;
      debugPrint('Session ended: ${result.id}');
    } on ApiException catch (e) {
      _errorMessage = e.message;
      debugPrint('Session end failed: ${e.message}');
      rethrow;
    } finally {
      _isEnding = false;
      notifyListeners();
    }
  }
}
