import 'linked_list_graph.dart';

/// The three distinct interaction modes a challenge can use.
///
/// The screen reads this enum to decide which gestures to enable on the
/// playground. Students never see this — they just see the appropriate
/// interactive affordances (tap-to-set-head, tap-to-connect, tap-to-traverse).
enum ChallengeInteractionMode {
  /// Student assigns HEAD and draws next-pointers between nodes.
  buildFromScratch,

  /// Student taps an isolated node, then its intended successor, to repair
  /// the broken pointer.  No node movement is required.
  repairGraph,

  /// Student taps each node in traversal order starting from HEAD.
  traceTraversal,
}

/// A self-contained description of one assessment challenge.
///
/// Everything the engine needs to run a challenge is captured here:
/// the starting state, the success state, and the interaction mode.
/// No screen coordinates, no widget references, no fixed labels.
class ChallengeDefinition {
  const ChallengeDefinition({
    required this.id,
    required this.title,
    required this.description,
    required this.points,
    required this.initialGraph,
    required this.expectedGraph,
    required this.interactionMode,
    this.hints = const [],
  });

  /// Unique identifier — used for switching behaviour in the screen.
  final String id;

  final String title;
  final String description;

  /// Maximum score awarded for completing this challenge correctly.
  final int points;

  /// The graph state handed to the student at challenge start.
  /// The screen copies this into [LinkedListAssessmentState.currentGraph]
  /// so the student always starts fresh.
  final LinkedListGraph initialGraph;

  /// The graph state that the validator compares against.
  /// The validator only reads structural properties (headId, traversalOrder)
  /// — never node labels.
  final LinkedListGraph expectedGraph;

  final ChallengeInteractionMode interactionMode;

  /// Progressive hints shown in the feedback panel during the attempt.
  /// Index 0 is shown first, escalating on repeated incorrect interactions.
  final List<String> hints;
}
