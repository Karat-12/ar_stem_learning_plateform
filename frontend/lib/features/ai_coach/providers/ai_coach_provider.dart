import 'package:flutter/foundation.dart';

import '../../../core/network/api_exception.dart';
import '../models/ai_coach_report.dart';
import '../services/ai_coach_service.dart';

/// Manages AI Coach data loading and per-topic in-session caching.
///
/// Cache policy:
///   - The first call to [loadReport] for a given topicCode fetches from the
///     network and stores the result in [_cache].
///   - Subsequent calls with the same topicCode return the cached report
///     immediately without a network round-trip.
///   - [refresh] clears the cache entry for the current topic and re-fetches,
///     used when the student completes a new assessment and wants updated data.
///   - The cache lives only for the lifetime of this provider (i.e. the app
///     session).  It is not persisted to disk.
class AiCoachProvider extends ChangeNotifier {
  AiCoachProvider({required AiCoachService service}) : _service = service;

  final AiCoachService _service;

  // ── Per-topic cache ───────────────────────────────────────────────────────
  final Map<String, AiCoachReport> _cache = {};

  // ── Observable state ──────────────────────────────────────────────────────
  AiCoachReport? _currentReport;
  bool _isLoading = false;
  String? _errorMessage;
  String? _currentTopicCode;

  AiCoachReport? get currentReport => _currentReport;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  String? get currentTopicCode => _currentTopicCode;

  /// True when a report is available for the currently loaded topic.
  bool get hasReport => _currentReport != null;

  // ── Public API ────────────────────────────────────────────────────────────

  /// Loads the AI Coach report for [topicCode].
  ///
  /// Returns immediately from cache when a report for this topic already
  /// exists.  Pass [forceRefresh: true] (or call [refresh]) to bypass the
  /// cache and fetch fresh data from the backend.
  Future<void> loadReport(
    String topicCode, {
    bool forceRefresh = false,
  }) async {
    _currentTopicCode = topicCode;

    // Serve from cache unless a refresh is requested.
    if (!forceRefresh && _cache.containsKey(topicCode)) {
      _currentReport = _cache[topicCode];
      _errorMessage = null;
      notifyListeners();
      return;
    }

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final report = await _service.fetchReport(topicCode);
      _cache[topicCode] = report;
      _currentReport = report;
    } on ApiException catch (e) {
      _errorMessage = e.message;
      debugPrint('AiCoachProvider: load failed for $topicCode — ${e.message}');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Clears the cached report for [topicCode] and re-fetches from the backend.
  ///
  /// Call this after the student completes an assessment so the coach reflects
  /// the latest quiz results and misconception data.
  Future<void> refresh(String topicCode) async {
    _cache.remove(topicCode);
    await loadReport(topicCode, forceRefresh: true);
  }

  /// Clears all cached reports.  Intended for use on logout.
  void clearAll() {
    _cache.clear();
    _currentReport = null;
    _currentTopicCode = null;
    _errorMessage = null;
    notifyListeners();
  }
}
