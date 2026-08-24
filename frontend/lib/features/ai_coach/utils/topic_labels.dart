/// Reusable mapping layer that converts backend topic codes and misconception
/// codes into natural human-readable English.
///
/// Usage:
///   TopicLabels.topic('DSA_LINKED_LIST')          → 'Linked List'
///   TopicLabels.misconception('DSA_HEAD_POINTER_MISSING') → 'You made a
///       mistake choosing the Head node.'
///
/// All conversions are static and pure — no state, no dependencies.
/// Add new entries to [_topics] or [_misconceptions] as the catalogue grows.
abstract final class TopicLabels {
  // ── Topic code → display name ─────────────────────────────────────────────

  static const Map<String, String> _topics = {
    'DSA_LINKED_LIST': 'Linked List',
    'DSA_STACK': 'Stack',
    'DSA_BINARY_TREE': 'Binary Tree',
    'ELECTRONICS_AND_GATE': 'AND Gate',
    'ELECTRONICS_OR_GATE': 'OR Gate',
    'ELECTRONICS_NOT_GATE': 'NOT Gate',
    'ELECTRONICS_XOR_GATE': 'XOR Gate',
    'ELECTRONICS_NAND_GATE': 'NAND Gate',
    'ELECTRONICS_NOR_GATE': 'NOR Gate',
    'ELECTRONICS_XNOR_GATE': 'XNOR Gate',
    'CHEMISTRY_METHANE': 'Methane',
    'CHEMISTRY_ETHANE': 'Ethane',
    'CHEMISTRY_PROPANE': 'Propane',
    'CHEMISTRY_METHANOL': 'Methanol',
    'CHEMISTRY_ETHANOL': 'Ethanol',
    'CHEMISTRY_GLUCOSE': 'Glucose',
    'CHEMISTRY_FRUCTOSE': 'Fructose',
    'CHEMISTRY_SUCROSE': 'Sucrose',
  };

  /// Returns a human-readable topic name.
  /// Falls back to title-casing the raw code when no mapping exists.
  static String topic(String code) {
    final trimmed = code.trim().toUpperCase();
    if (_topics.containsKey(trimmed)) return _topics[trimmed]!;
    // Generic fallback: "DSA_MY_TOPIC" → "My Topic"
    final parts = trimmed.split('_');
    final skip = parts.length > 1 ? 1 : 0;
    return parts
        .skip(skip)
        .map((w) => w.isEmpty
            ? ''
            : '${w[0].toUpperCase()}${w.substring(1).toLowerCase()}')
        .join(' ');
  }

  // ── Misconception code → student-facing description ───────────────────────
  //
  // These messages are written in the second person so they feel like tutor
  // feedback, not system logs.

  static const Map<String, String> _misconceptions = {
    // ── Linked List ──────────────────────────────────────────────────────────
    'DSA_HEAD_POINTER_MISSING':
        'You made a mistake while choosing the Head node. '
        'Remember — the Head is where traversal always begins.',
    'DSA_BROKEN_LINKED_LIST':
        'Some nodes were left disconnected. '
        'Every node in a linked list must be reachable from the Head.',
    'DSA_INVALID_TRAVERSAL':
        'The traversal order was incorrect. '
        'Always follow each arrow from the Head node, one step at a time.',
    'DSA_INSERT_POINTER_ERROR':
        'Practise connecting nodes during insertion. '
        'When inserting, you need to update two pointers — the new node\'s '
        'next and the previous node\'s next.',
    'DSA_DELETE_POINTER_ERROR':
        'There was an error while removing a node. '
        'When deleting, redirect the previous node\'s pointer to skip the '
        'removed node.',
    'DSA_NULL_POINTER':
        'The pointer was left pointing to nothing (null) too early. '
        'Only the last node in the list should have a null next pointer.',
    'DSA_CYCLE_DETECTED':
        'A cycle was introduced — the list loops back on itself. '
        'The last node must point to null, not back to an earlier node.',

    // ── Stack ────────────────────────────────────────────────────────────────
    'STACK_UNDERFLOW':
        'You tried to remove an item from an empty stack. '
        'Always check if the stack is empty before popping.',
    'STACK_OVERFLOW':
        'The stack exceeded its capacity. '
        'Check the stack size before pushing a new item.',

    // ── Electronics ──────────────────────────────────────────────────────────
    'ELECTRONICS_OUTPUT_ERROR':
        'The gate output was incorrect. '
        'Review the truth table for this gate and try again.',
    'ELECTRONICS_INPUT_ERROR':
        'One or more inputs were set incorrectly. '
        'Double-check which inputs are active before reading the output.',
  };

  /// Returns a student-facing explanation for a misconception code.
  /// Falls back to a generic encouraging message when no mapping exists.
  static String misconception(String code) {
    final trimmed = code.trim().toUpperCase();
    if (_misconceptions.containsKey(trimmed)) return _misconceptions[trimmed]!;
    // Generic fallback: title-case the code and add a coaching prompt.
    final label = trimmed
        .split('_')
        .map((w) =>
            w.isEmpty ? '' : '${w[0].toUpperCase()}${w.substring(1).toLowerCase()}')
        .join(' ');
    return 'Review your understanding of $label and try again.';
  }

  /// Converts a short misconception code to a display title (no period).
  /// Used in chip labels where space is limited.
  static String misconceptionShort(String code) {
    final trimmed = code.trim().toUpperCase();
    const shortLabels = <String, String>{
      'DSA_HEAD_POINTER_MISSING': 'Head Node Error',
      'DSA_BROKEN_LINKED_LIST': 'Disconnected Nodes',
      'DSA_INVALID_TRAVERSAL': 'Traversal Order',
      'DSA_INSERT_POINTER_ERROR': 'Insertion Pointer',
      'DSA_DELETE_POINTER_ERROR': 'Deletion Pointer',
      'DSA_NULL_POINTER': 'Null Pointer',
      'DSA_CYCLE_DETECTED': 'Cycle Detected',
      'STACK_UNDERFLOW': 'Stack Underflow',
      'STACK_OVERFLOW': 'Stack Overflow',
      'ELECTRONICS_OUTPUT_ERROR': 'Wrong Output',
      'ELECTRONICS_INPUT_ERROR': 'Wrong Input',
    };
    if (shortLabels.containsKey(trimmed)) return shortLabels[trimmed]!;
    return trimmed
        .split('_')
        .skip(trimmed.startsWith('DSA_') ||
                trimmed.startsWith('ELECTRONICS_') ||
                trimmed.startsWith('CHEMISTRY_')
            ? 1
            : 0)
        .map((w) =>
            w.isEmpty ? '' : '${w[0].toUpperCase()}${w.substring(1).toLowerCase()}')
        .join(' ');
  }

  // ── Recommendation type → action label ───────────────────────────────────

  static const Map<String, String> _recommendationTypes = {
    'NEXT_TOPIC': 'Ready for next topic',
    'QUIZ_PRACTICE': 'Quiz practice needed',
    'REVISION': 'Revision recommended',
    'PRACTICE': 'More practice needed',
  };

  static String recommendationType(String code) =>
      _recommendationTypes[code.trim().toUpperCase()] ??
      code.replaceAll('_', ' ');

  // ── Mastery level → display label ─────────────────────────────────────────

  static const Map<String, String> _masteryLevels = {
    'MASTERED': 'Mastered',
    'PROFICIENT': 'Proficient',
    'DEVELOPING': 'Developing',
    'BEGINNER': 'Beginner',
    // Legacy values from old formula — map gracefully.
    'ADVANCED': 'Mastered',
    'INTERMEDIATE': 'Proficient',
  };

  static String masteryLevel(String code) =>
      _masteryLevels[code.trim().toUpperCase()] ?? code;

  // ── Text-cleaning helpers for backend strings ─────────────────────────────

  /// Replaces any raw topic-code tokens inside a backend-generated string
  /// with their human-readable equivalents.
  ///
  /// Example:
  ///   clean('Practise DSA_LINKED_LIST insertion')
  ///   → 'Practise Linked List insertion'
  static String clean(String text) {
    var result = text;
    for (final entry in _topics.entries) {
      result = result.replaceAll(entry.key, entry.value);
    }
    return result;
  }
}
