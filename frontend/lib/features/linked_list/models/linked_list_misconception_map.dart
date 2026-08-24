/// Mapping from backend misconception codes to targeted practice tasks.
///
/// Pure Dart — no Flutter imports.
///
/// This is the single source of truth for the learning loop:
///   backend misconception code
///     → [LinkedListPracticeRecommendation]
///       → initialTaskId passed to [LinkedListConstructionScreen]
///
/// How to extend:
///   1. Add a new [LinkedListPracticeRecommendation] constant below.
///   2. Add the code → recommendation entry in [_map].
///   3. Add the corresponding task to [kLinkedListTasks] if it does not
///      already exist.
///
/// The lookup intentionally returns null for unknown codes rather than
/// crashing — the caller must handle the null case gracefully.
class LinkedListPracticeRecommendation {
  const LinkedListPracticeRecommendation({
    required this.misconceptionCode,
    required this.taskId,
    required this.conceptTitle,
    required this.practiceReason,
    required this.ctaLabel,
  });

  /// The backend misconception code this recommendation addresses.
  final String misconceptionCode;

  /// The [LinkedListTask.id] to open in targeted mode.
  final String taskId;

  /// Short human-readable concept name shown in the UI chip.
  /// Never shows a raw backend code to the student.
  final String conceptTitle;

  /// One sentence explaining why this practice is recommended.
  final String practiceReason;

  /// Label for the "Practice This" button.
  final String ctaLabel;
}

// ── Built-in recommendations ──────────────────────────────────────────────────

const _headPointerRec = LinkedListPracticeRecommendation(
  misconceptionCode: 'DSA_HEAD_POINTER_MISSING',
  taskId: 'task-ll-2',          // "Understand HEAD and TAIL"
  conceptTitle: 'HEAD Pointer',
  practiceReason:
      'You need more practice identifying the first node and marking it as HEAD.',
  ctaLabel: 'Practice HEAD',
);

const _brokenListRec = LinkedListPracticeRecommendation(
  misconceptionCode: 'DSA_BROKEN_LINKED_LIST',
  taskId: 'task-ll-1',          // "Build an Ascending Linked List"
  conceptTitle: 'Node Connections',
  practiceReason:
      'Some nodes were left disconnected. Practise connecting every node into a '
      'complete chain.',
  ctaLabel: 'Practice Connections',
);

const _traversalRec = LinkedListPracticeRecommendation(
  misconceptionCode: 'DSA_INVALID_TRAVERSAL',
  taskId: 'task-ll-3',          // "Traverse a Linked List"
  conceptTitle: 'Traversal Order',
  practiceReason:
      'The traversal order was incorrect. Practise building a list whose '
      'pointer chain visits nodes in the right sequence.',
  ctaLabel: 'Practice Traversal',
);

/// Generic fallback used when a misconception code has no specific mapping.
///
/// Opens Task 1 so the student always gets a meaningful starting point.
const _genericRec = LinkedListPracticeRecommendation(
  misconceptionCode: '',         // sentinel — never stored in the map
  taskId: 'task-ll-1',
  conceptTitle: 'Linked List Fundamentals',
  practiceReason:
      'Revisiting the fundamentals will strengthen your understanding.',
  ctaLabel: 'Practice',
);

// ── Lookup table ──────────────────────────────────────────────────────────────

const Map<String, LinkedListPracticeRecommendation> _map = {
  'DSA_HEAD_POINTER_MISSING': _headPointerRec,
  'DSA_BROKEN_LINKED_LIST':   _brokenListRec,
  'DSA_INVALID_TRAVERSAL':    _traversalRec,
  // Aliases that the assessment service may produce
  'DSA_NULL_POINTER':         _traversalRec,
  'DSA_CYCLE_DETECTED':       _brokenListRec,
  'DSA_INSERT_POINTER_ERROR': _brokenListRec,
  'DSA_DELETE_POINTER_ERROR': _brokenListRec,
};

// ── Public API ────────────────────────────────────────────────────────────────

/// Returns the [LinkedListPracticeRecommendation] for [misconceptionCode],
/// or null when the code is not recognised and the caller should skip.
///
/// Case-insensitive. Leading/trailing whitespace is ignored.
LinkedListPracticeRecommendation? recommendationForCode(
    String misconceptionCode) {
  final key = misconceptionCode.trim().toUpperCase();
  return _map[key];
}

/// Returns the [LinkedListPracticeRecommendation] for [misconceptionCode],
/// falling back to [_genericRec] when no specific mapping exists.
///
/// Prefer [recommendationForCode] when you want to suppress output for
/// unknown codes entirely. Use this variant when you always need a CTA.
LinkedListPracticeRecommendation recommendationForCodeOrFallback(
    String misconceptionCode) {
  return recommendationForCode(misconceptionCode) ?? _genericRec;
}

/// Returns up to [limit] recommendations for a list of misconception codes,
/// deduplicating by [LinkedListPracticeRecommendation.taskId] so the student
/// is never shown two buttons that open the same task.
///
/// Priority order is preserved — the first code in [codes] is the most
/// important recommendation.
List<LinkedListPracticeRecommendation> topRecommendations(
  List<String> codes, {
  int limit = 3,
}) {
  final seen = <String>{};
  final result = <LinkedListPracticeRecommendation>[];
  for (final code in codes) {
    final rec = recommendationForCode(code);
    if (rec == null) continue;
    if (seen.contains(rec.taskId)) continue;
    seen.add(rec.taskId);
    result.add(rec);
    if (result.length >= limit) break;
  }
  return result;
}
