import '../../assessments/linked_list_assessment/models/linked_list_graph.dart';
import '../../assessments/linked_list_assessment/models/validation_result.dart';
import 'linked_list_task.dart';

/// Live state for the Linked List construction learning workspace.
///
/// Pure Dart — no Flutter imports, no Offset, no Color, no Widget.
///
/// The screen owns [LinkedListNodeModel] positions (visual layer).
/// This class owns everything structural (logical layer):
///   - which task is active
///   - the logical graph the student is building
///   - which nodes are still in the palette vs placed on the canvas
///   - the two-tap connection gesture state
///   - the last validation result
///   - session / submission bookkeeping
///
/// All mutations return a new instance via [copyWith] — same pattern as
/// [LinkedListAssessmentState] so the two are interchangeable in reasoning.
class LinkedListWorkspaceState {
  const LinkedListWorkspaceState({
    required this.currentTaskIndex,
    required this.currentGraph,
    required this.paletteNodeIds,
    required this.placedNodeIds,
    required this.selectedNodeId,
    required this.lastValidation,
    required this.hintsShownCount,
    required this.isTaskComplete,
    required this.isSubmitting,
    required this.sessionId,
    required this.errorMessage,
    required this.completedTaskCount,
  });

  // ── Task progression ───────────────────────────────────────────────────────

  /// Index into [kLinkedListTasks].
  final int currentTaskIndex;

  /// Number of tasks the student has successfully completed this session.
  final int completedTaskCount;

  // ── Logical graph ─────────────────────────────────────────────────────────

  /// The live structural state the student is constructing.
  ///
  /// Initialised from [LinkedListTask.buildEmptyGraph()] at task start.
  /// Mutated only through [LinkedListGraph.withHead] and
  /// [LinkedListGraph.withPointer] — returning new immutable instances.
  ///
  /// Validation reads this; visual rendering reads [LinkedListNodeModel]
  /// positions which live in the screen layer. The two are kept separate.
  final LinkedListGraph currentGraph;

  // ── Palette / canvas membership ───────────────────────────────────────────

  /// Node IDs that are still in the palette (not yet dragged to the canvas).
  ///
  /// When the student drags a node onto the canvas, its ID moves from
  /// [paletteNodeIds] to [placedNodeIds].  Removing a node from the canvas
  /// is not supported in Phase 1 — once placed, a node stays on the canvas.
  final List<int> paletteNodeIds;

  /// Node IDs that have been placed on the canvas.
  final List<int> placedNodeIds;

  // ── Two-tap connection gesture ────────────────────────────────────────────

  /// The node the student tapped first in a connect gesture (the source).
  ///
  /// Null when no source is selected.
  /// Cleared after a connection is made, or when the same node is tapped again.
  final int? selectedNodeId;

  // ── Validation ────────────────────────────────────────────────────────────

  /// Result of the most recent VERIFY press (or initial placeholder).
  final ValidationResult lastValidation;

  /// How many progressive hints have been shown for the current task.
  /// Incremented on each failed VERIFY so hints escalate over time.
  final int hintsShownCount;

  // ── Task completion ───────────────────────────────────────────────────────

  /// True once [lastValidation.isValid] was true and the student pressed
  /// VERIFY. The screen uses this to show the success + explanation panel.
  final bool isTaskComplete;

  // ── Session / submission ──────────────────────────────────────────────────

  final bool isSubmitting;

  /// Backend session ID returned by [SessionService.startSession].
  final String? sessionId;

  /// Non-null only when a network or session error has occurred.
  final String? errorMessage;

  // ── Convenience getters ───────────────────────────────────────────────────

  /// True when the VERIFY button should be enabled.
  ///
  /// Minimum conditions:
  ///   1. All palette nodes have been placed on the canvas.
  ///   2. A HEAD node has been assigned.
  ///
  /// We do not require all connections to exist yet — [validateBuild] will
  /// surface clear hints if the graph is incomplete.
  bool get canVerify =>
      paletteNodeIds.isEmpty && currentGraph.headId != null && !isTaskComplete;

  /// True when the student has placed at least one node on the canvas.
  bool get hasPlacedNodes => placedNodeIds.isNotEmpty;

  /// Derived TAIL: the last node in the traversal from HEAD.
  ///
  /// Returns null when HEAD is unset or the graph is empty.
  /// The TAIL is the final reachable node whose next pointer is null.
  int? get tailNodeId {
    final order = currentGraph.traversalOrder();
    if (order.isEmpty) return null;
    final last = order.last;
    // Only report a TAIL if the last node explicitly has a null pointer
    // (rather than a broken cycle or mid-chain node).
    if (currentGraph.nextOf(last) == null) return last;
    return null;
  }

  /// True when the last VERIFY produced a passing result.
  bool get isCurrentValid => lastValidation.isValid;

  // ── Factory ───────────────────────────────────────────────────────────────

  /// Blank initial state before any task has been loaded.
  factory LinkedListWorkspaceState.initial() {
    return LinkedListWorkspaceState(
      currentTaskIndex: 0,
      currentGraph: LinkedListGraph(
        nodes: {},
        nextPointers: {},
        headId: null,
      ),
      paletteNodeIds: const [],
      placedNodeIds: const [],
      selectedNodeId: null,
      lastValidation: const ValidationResult(
        isValid: false,
        hint: 'Drag nodes from the palette to start building.',
      ),
      hintsShownCount: 0,
      isTaskComplete: false,
      isSubmitting: false,
      sessionId: null,
      errorMessage: null,
      completedTaskCount: 0,
    );
  }

  /// Returns a fresh state loaded for [task], preserving session bookkeeping.
  ///
  /// All node IDs start in [paletteNodeIds]. [currentGraph] is the empty
  /// graph from [task.buildEmptyGraph()].  Visual positions are not held
  /// here — the screen clears its own [_visualNodes] list when this is called.
  LinkedListWorkspaceState loadTask(LinkedListTask task) {
    final allIds = List<int>.generate(
      task.nodeValues.length,
      (i) => i + 1,
      growable: false,
    );
    return LinkedListWorkspaceState(
      currentTaskIndex: kLinkedListTasks.indexOf(task),
      currentGraph: task.buildEmptyGraph(),
      paletteNodeIds: allIds,
      placedNodeIds: const [],
      selectedNodeId: null,
      lastValidation: ValidationResult(
        isValid: false,
        hint: task.hints.isNotEmpty ? task.hints[0] : task.prompt,
      ),
      hintsShownCount: 0,
      isTaskComplete: false,
      isSubmitting: false,
      sessionId: sessionId,
      errorMessage: null,
      completedTaskCount: completedTaskCount,
    );
  }

  // ── copyWith ──────────────────────────────────────────────────────────────

  LinkedListWorkspaceState copyWith({
    int? currentTaskIndex,
    LinkedListGraph? currentGraph,
    List<int>? paletteNodeIds,
    List<int>? placedNodeIds,
    int? selectedNodeId,
    bool clearSelectedNode = false,
    ValidationResult? lastValidation,
    int? hintsShownCount,
    bool? isTaskComplete,
    bool? isSubmitting,
    String? sessionId,
    String? errorMessage,
    bool clearError = false,
    int? completedTaskCount,
  }) {
    return LinkedListWorkspaceState(
      currentTaskIndex: currentTaskIndex ?? this.currentTaskIndex,
      currentGraph: currentGraph ?? this.currentGraph,
      paletteNodeIds: paletteNodeIds ?? this.paletteNodeIds,
      placedNodeIds: placedNodeIds ?? this.placedNodeIds,
      selectedNodeId:
          clearSelectedNode ? null : (selectedNodeId ?? this.selectedNodeId),
      lastValidation: lastValidation ?? this.lastValidation,
      hintsShownCount: hintsShownCount ?? this.hintsShownCount,
      isTaskComplete: isTaskComplete ?? this.isTaskComplete,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      sessionId: sessionId ?? this.sessionId,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      completedTaskCount: completedTaskCount ?? this.completedTaskCount,
    );
  }
}
