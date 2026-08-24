/// Result returned by every challenge validator.
///
/// The validator is a pure function — it never writes to any service.
/// The screen is responsible for acting on [misconceptionCode] when present
/// (recording it via MisconceptionService) and for enabling/disabling the
/// "Check & Continue" button based on [isValid].
class ValidationResult {
  const ValidationResult({
    required this.isValid,
    required this.hint,
    this.misconceptionCode,
    this.misconceptionTitle,
    this.misconceptionDescription,
    this.misconceptionSeverity = 'MEDIUM',
  }) : assert(
         misconceptionCode == null ||
             (misconceptionTitle != null && misconceptionDescription != null),
         'When misconceptionCode is supplied, title and description are required.',
       );

  /// Whether the student has satisfied the challenge's success condition.
  final bool isValid;

  /// Live guidance shown in the feedback panel.
  /// Always non-null: even a passing state shows a confirmation message.
  final String hint;

  /// Optional misconception code to be recorded via MisconceptionService.
  ///
  /// Null when the current state has no detectable misconception.
  /// Mirrors the codes used in LinkedListLearningScreen so that
  /// the AI Learning Coach can correlate workspace and assessment signals.
  final String? misconceptionCode;

  /// Human-readable title for the misconception (required when [misconceptionCode] is set).
  final String? misconceptionTitle;

  /// Explanation of the misconception (required when [misconceptionCode] is set).
  final String? misconceptionDescription;

  /// Severity level forwarded to MisconceptionService: HIGH | MEDIUM | LOW.
  final String misconceptionSeverity;

  /// Convenience: true when this result carries a misconception to record.
  bool get hasMisconception => misconceptionCode != null;

  /// A passing result with no misconception.
  static const ValidationResult valid = ValidationResult(
    isValid: true,
    hint: 'All good — tap "Check & Continue" to move on.',
  );
}
