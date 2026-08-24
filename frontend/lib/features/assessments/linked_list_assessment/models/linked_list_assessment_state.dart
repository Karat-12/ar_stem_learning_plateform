import '../../shared/assessment_challenge_result.dart';
import 'linked_list_graph.dart';
import 'validation_result.dart';

/// Full live state of the Linked List assessment session.
///
/// The screen owns one instance of this and replaces it via [copyWith] on
/// every interaction.  [_revalidate] on the screen derives
/// [isCurrentChallengeValid] and [currentHint] automatically — they are
/// never set manually.
class LinkedListAssessmentState {
  const LinkedListAssessmentState({
    required this.currentChallengeIndex,
    required this.currentGraph,
    required this.tappedSequence,
    required this.selectedNodeId,
    required this.lastValidation,
    required this.results,
    required this.isSubmitting,
    required this.sessionId,
    required this.errorMessage,
  });

  // ── Challenge progression ────────────────────────────────────────────────

  /// Index into [LinkedListAssessmentService.challenges].
  final int currentChallengeIndex;

  // ── Logical graph state ──────────────────────────────────────────────────

  /// The live structural state the student is building or repairing.
  ///
  /// Initialised from [ChallengeDefinition.initialGraph] at the start of
  /// each challenge and mutated through [LinkedListGraph.withHead] /
  /// [LinkedListGraph.withPointer].
  ///
  /// The screen never exposes this object to the student — it is only used
  /// internally for validation and for deriving which arrows to render.
  final LinkedListGraph currentGraph;

  // ── Challenge 3 traversal state ──────────────────────────────────────────

  /// Ordered list of node IDs tapped by the student during traceTraversal.
  /// Cleared on a wrong tap or when advancing to the next challenge.
  final List<int> tappedSequence;

  // ── Connection gesture state (Challenge 1 & 2) ───────────────────────────

  /// The node ID the student tapped first in a two-tap connect gesture.
  /// Null when no node is selected.
  ///
  /// Interaction flow:
  ///   tap node A → selectedNodeId = A
  ///   tap node B → fire onConnectNodes(A, B), clear selectedNodeId
  final int? selectedNodeId;

  // ── Live validation ──────────────────────────────────────────────────────

  /// The result of the most recent call to the active challenge's validator.
  /// Derived automatically by [_revalidate] — never set directly.
  final ValidationResult lastValidation;

  // ── Session & submission ─────────────────────────────────────────────────

  /// Collected results — one entry appended per completed challenge.
  final List<AssessmentChallengeResult> results;

  final bool isSubmitting;

  /// Backend session ID returned by SessionService.startSession().
  final String? sessionId;

  /// Non-null only when a network or session error has occurred.
  final String? errorMessage;

  // ── Convenience getters ──────────────────────────────────────────────────

  /// True when the active challenge's validator says the student is done.
  bool get isCurrentChallengeValid => lastValidation.isValid;

  /// Live hint text to display in the feedback panel.
  String get currentHint => lastValidation.hint;

  /// True when the broken-link visual should be shown.
  /// Derived from the graph so the playground always reflects structural truth.
  bool get connectionBroken => !currentGraph.isFullyConnected();

  // ── Factory ──────────────────────────────────────────────────────────────

  /// Initial state before any challenge has started.
  /// [currentGraph] is a placeholder — the screen replaces it with
  /// [ChallengeDefinition.initialGraph] immediately in [initState].
  factory LinkedListAssessmentState.initial() {
    return LinkedListAssessmentState(
      currentChallengeIndex: 0,
      currentGraph: LinkedListGraph(
        nodes: {},
        nextPointers: {},
        headId: null,
      ),
      tappedSequence: const [],
      selectedNodeId: null,
      lastValidation: const ValidationResult(
        isValid: false,
        hint: 'Starting assessment…',
      ),
      results: const [],
      isSubmitting: false,
      sessionId: null,
      errorMessage: null,
    );
  }

  // ── copyWith ─────────────────────────────────────────────────────────────

  LinkedListAssessmentState copyWith({
    int? currentChallengeIndex,
    LinkedListGraph? currentGraph,
    List<int>? tappedSequence,
    int? selectedNodeId,
    bool clearSelectedNode = false,
    ValidationResult? lastValidation,
    List<AssessmentChallengeResult>? results,
    bool? isSubmitting,
    String? sessionId,
    String? errorMessage,
    bool clearError = false,
  }) {
    return LinkedListAssessmentState(
      currentChallengeIndex:
          currentChallengeIndex ?? this.currentChallengeIndex,
      currentGraph: currentGraph ?? this.currentGraph,
      tappedSequence: tappedSequence ?? this.tappedSequence,
      // clearSelectedNode=true forces selectedNodeId to null even when
      // the caller also passes selectedNodeId: null (same effect, explicit intent).
      selectedNodeId:
          clearSelectedNode ? null : (selectedNodeId ?? this.selectedNodeId),
      lastValidation: lastValidation ?? this.lastValidation,
      results: results ?? this.results,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      sessionId: sessionId ?? this.sessionId,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }
}
