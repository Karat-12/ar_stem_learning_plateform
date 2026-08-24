import '../../shared/assessment_challenge_result.dart';
import '../../shared/assessment_result_model.dart';
import '../models/challenge_definition.dart';
import '../models/linked_list_graph.dart';
import '../models/validation_result.dart';

/// Assessment engine for the Linked List topic.
///
/// Responsibilities:
///   1. Declare the three [ChallengeDefinition]s that describe what each
///      challenge starts with and what structural state counts as correct.
///   2. Expose three pure validator functions — one per challenge — that
///      accept the current [LinkedListGraph] (or traversal sequence) and
///      return a [ValidationResult].
///
/// Nothing here knows about screen coordinates, node labels, widget state,
/// or API calls.  Those concerns belong to the screen and the orchestration
/// layer.
class LinkedListAssessmentService {
  // ── Point budgets ────────────────────────────────────────────────────────

  static const int _challenge1Points = 35;
  static const int _challenge2Points = 35;
  static const int _challenge3Points = 30;

  // ── Challenge definitions ────────────────────────────────────────────────
  //
  // Node ids are stable integers; labels are display-only strings and are
  // never read by any validator.
  //
  // Challenge 1 — Build the chain
  //   Nodes 1-4 are scattered, unordered, no head, no pointers.
  //   Expected: head=1, chain 1→2→3→4 (ascending numeric order by label).
  //
  // Challenge 2 — Repair the break
  //   The list 1→2→3→4 has the pointer 2→3 missing (null), isolating node 3.
  //   Expected: the pointer 2→3 is restored so the full chain is connected.
  //
  // Challenge 3 — Trace the traversal
  //   A fully connected list 1→2→3→4 with head=1.
  //   Student must tap nodes in traversal order [1, 2, 3, 4].

  List<ChallengeDefinition> get challenges => [
        ChallengeDefinition(
          id: 'challenge-1',
          title: 'Build the chain',
          description:
              'Four nodes are scattered on the canvas with no connections.\n\n'
              'Tap a node to mark it as HEAD, then tap each node to draw a '
              'pointer to the next one.\n\n'
              'Build a complete linked list where every node is connected from '
              'HEAD through to the last node.',
          points: _challenge1Points,
          interactionMode: ChallengeInteractionMode.buildFromScratch,
          initialGraph: LinkedListGraph(
            nodes: {1: '10', 2: '25', 3: '40', 4: '60'},
            nextPointers: {1: null, 2: null, 3: null, 4: null},
            headId: null,
          ),
          expectedGraph: LinkedListGraph(
            nodes: {1: '10', 2: '25', 3: '40', 4: '60'},
            nextPointers: {1: 2, 2: 3, 3: 4, 4: null},
            headId: 1,
          ),
          hints: [
            'Start by selecting a HEAD node — it is the entry point of the list.',
            'After setting HEAD, tap that node then tap the next node to draw an arrow.',
            'Every node must be reachable from HEAD. Check for any floating nodes.',
          ],
        ),

        ChallengeDefinition(
          id: 'challenge-2',
          title: 'Repair the break',
          description:
              'The list has a broken link.\n\n'
              'Node 25 should point to node 40, but that connection is missing.\n\n'
              'Tap node 25 (the source), then tap node 40 (the target) to '
              'restore the missing arrow.\n\n'
              'The challenge is complete when the red break disappears and '
              'every node is connected from HEAD.',
          points: _challenge2Points,
          interactionMode: ChallengeInteractionMode.repairGraph,
          // Three nodes only.  Exactly one pointer is missing: 2→3.
          // Node 3 (40) has no outgoing pointer — it is the tail.
          // There are no pre-wired sub-chains.
          // Visual: HEAD→10→25→[BROKEN]   40→null (isolated)
          initialGraph: LinkedListGraph(
            nodes: {1: '10', 2: '25', 3: '40'},
            nextPointers: {1: 2, 2: null, 3: null},
            headId: 1,
          ),
          expectedGraph: LinkedListGraph(
            nodes: {1: '10', 2: '25', 3: '40'},
            nextPointers: {1: 2, 2: 3, 3: null},
            headId: 1,
          ),
          hints: [
            'Node 25 is missing its "next" pointer — it is the broken link.',
            'Tap node 25 first (source), then tap node 40 (target).',
            'The red broken arrow will heal when the correct pointer is drawn.',
          ],
        ),

        ChallengeDefinition(
          id: 'challenge-3',
          title: 'Trace the traversal',
          description:
              'The linked list is complete.\n\n'
              'Tap each node in the correct traversal order — starting from '
              'HEAD and following each arrow to the next node.\n\n'
              'Tapping a node out of order resets the trace.',
          points: _challenge3Points,
          interactionMode: ChallengeInteractionMode.traceTraversal,
          initialGraph: LinkedListGraph(
            nodes: {1: '10', 2: '25', 3: '40', 4: '60'},
            nextPointers: {1: 2, 2: 3, 3: 4, 4: null},
            headId: 1,
          ),
          expectedGraph: LinkedListGraph(
            nodes: {1: '10', 2: '25', 3: '40', 4: '60'},
            nextPointers: {1: 2, 2: 3, 3: 4, 4: null},
            headId: 1,
          ),
          hints: [
            'Traversal always starts at HEAD — find it first.',
            'Follow each arrow from one node to the next.',
            'You cannot skip nodes — every node must be visited in order.',
          ],
        ),
      ];

  // ── Validators ───────────────────────────────────────────────────────────
  //
  // Each validator is a pure function:
  //   - No side effects.
  //   - No knowledge of screen state, Offset, or labels.
  //   - Returns a ValidationResult the screen can act on immediately.

  /// Challenge 1 — Build from scratch.
  ///
  /// Passes when:
  ///   1. A HEAD node is assigned.
  ///   2. The traversal order of [current] matches [expected] exactly
  ///      (same sequence of node IDs).
  ///   3. No isolated nodes exist.
  ValidationResult validateBuild(
    LinkedListGraph current,
    LinkedListGraph expected,
  ) {
    // No HEAD assigned yet.
    if (current.headId == null) {
      return const ValidationResult(
        isValid: false,
        hint: 'No HEAD selected yet. Tap a node and choose "Set as HEAD".',
        misconceptionCode: 'DSA_HEAD_POINTER_MISSING',
        misconceptionTitle: 'Head Node Missing',
        misconceptionDescription:
            'The student has not assigned a HEAD pointer to the linked list.',
        misconceptionSeverity: 'HIGH',
      );
    }

    // Wrong HEAD node chosen.
    if (current.headId != expected.headId) {
      return const ValidationResult(
        isValid: false,
        hint: 'That is not the right HEAD node. '
            'HEAD should be the first node in the chain.',
        misconceptionCode: 'DSA_HEAD_POINTER_MISSING',
        misconceptionTitle: 'Head Node Missing',
        misconceptionDescription:
            'The student assigned HEAD to the wrong node.',
        misconceptionSeverity: 'HIGH',
      );
    }

    // Isolated nodes — some nodes not yet connected.
    final isolated = current.isolatedNodeIds();
    if (isolated.isNotEmpty) {
      return ValidationResult(
        isValid: false,
        hint: 'Node${isolated.length > 1 ? 's' : ''} '
            '${isolated.map(current.labelOf).join(', ')} '
            '${isolated.length > 1 ? 'are' : 'is'} not connected. '
            'Draw an arrow from the previous node to reach it.',
        misconceptionCode: 'DSA_BROKEN_LINKED_LIST',
        misconceptionTitle: 'Broken Linked List',
        misconceptionDescription:
            'The student left one or more nodes disconnected from the chain.',
        misconceptionSeverity: 'MEDIUM',
      );
    }

    // Traversal order does not match expected.
    final currentOrder = current.traversalOrder();
    final expectedOrder = expected.traversalOrder();
    if (!_listEquals(currentOrder, expectedOrder)) {
      return const ValidationResult(
        isValid: false,
        hint: 'The chain is connected but the order is wrong. '
            'Check that each node points to the correct successor.',
        misconceptionCode: 'DSA_INVALID_TRAVERSAL',
        misconceptionTitle: 'Invalid Traversal Order',
        misconceptionDescription:
            'The student connected all nodes but in the wrong sequence.',
        misconceptionSeverity: 'MEDIUM',
      );
    }

    return const ValidationResult(
      isValid: true,
      hint: 'The chain is complete and correctly ordered. '
          'Tap "Check & Continue" to proceed.',
    );
  }

  /// Challenge 2 — Repair the break.
  ///
  /// Passes when:
  ///   1. No isolated nodes remain.
  ///   2. The traversal order of [current] matches [expected].
  ///   3. HEAD is unchanged.
  ValidationResult validateRepair(
    LinkedListGraph current,
    LinkedListGraph expected,
  ) {
    // HEAD was changed — should not happen in repair mode but guard anyway.
    if (current.headId != expected.headId) {
      return const ValidationResult(
        isValid: false,
        hint: 'HEAD should not change during a repair. '
            'Only restore the missing connection.',
        misconceptionCode: 'DSA_HEAD_POINTER_MISSING',
        misconceptionTitle: 'Head Node Missing',
        misconceptionDescription:
            'The student altered the HEAD pointer while attempting a repair.',
        misconceptionSeverity: 'HIGH',
      );
    }

    // Still have isolated nodes — repair not complete.
    final isolated = current.isolatedNodeIds();
    if (isolated.isNotEmpty) {
      return ValidationResult(
        isValid: false,
        hint: 'Node${isolated.length > 1 ? 's' : ''} '
            '${isolated.map(current.labelOf).join(', ')} '
            '${isolated.length > 1 ? 'are' : 'is'} still disconnected. '
            'Tap the node before the gap and connect it to the next node.',
        misconceptionCode: 'DSA_BROKEN_LINKED_LIST',
        misconceptionTitle: 'Broken Linked List',
        misconceptionDescription:
            'The student has not yet restored the broken link.',
        misconceptionSeverity: 'MEDIUM',
      );
    }

    // Fully connected but wrong order.
    final currentOrder = current.traversalOrder();
    final expectedOrder = expected.traversalOrder();
    if (!_listEquals(currentOrder, expectedOrder)) {
      return const ValidationResult(
        isValid: false,
        hint: 'All nodes are connected, but the order is wrong. '
            'The repair connected the wrong pair of nodes.',
        misconceptionCode: 'DSA_INVALID_TRAVERSAL',
        misconceptionTitle: 'Invalid Traversal Order',
        misconceptionDescription:
            'The student connected the wrong nodes during the repair.',
        misconceptionSeverity: 'MEDIUM',
      );
    }

    return const ValidationResult(
      isValid: true,
      hint: 'The broken link is repaired and the chain is complete. '
          'Tap "Check & Continue" to proceed.',
    );
  }

  /// Challenge 3 — Trace the traversal.
  ///
  /// [tappedSequence] is the list of node IDs the student has tapped so far
  /// (accumulated incrementally by the screen).
  ///
  /// Passes when [tappedSequence] equals [expected.traversalOrder()] exactly.
  ///
  /// The screen calls this after each tap to get live feedback; it also calls
  /// [validateNextTap] before appending to the sequence to catch wrong taps
  /// early.
  ValidationResult validateTraversal(
    List<int> tappedSequence,
    LinkedListGraph expected,
  ) {
    final expectedOrder = expected.traversalOrder();

    if (tappedSequence.isEmpty) {
      return const ValidationResult(
        isValid: false,
        hint: 'Tap the HEAD node to begin the traversal.',
      );
    }

    // First tap must be HEAD.
    if (tappedSequence.first != expected.headId) {
      return const ValidationResult(
        isValid: false,
        hint: 'Traversal must start at HEAD. Tap the HEAD node first.',
        misconceptionCode: 'DSA_INVALID_TRAVERSAL',
        misconceptionTitle: 'Invalid Traversal',
        misconceptionDescription:
            'The student began traversal from a non-HEAD node.',
        misconceptionSeverity: 'MEDIUM',
      );
    }

    // Partial traversal in progress — no error yet.
    if (tappedSequence.length < expectedOrder.length) {
      final nextExpected = expectedOrder[tappedSequence.length];
      return ValidationResult(
        isValid: false,
        hint: 'Good — ${tappedSequence.length} of ${expectedOrder.length} '
            'nodes visited. '
            'Follow the arrow to the next node '
            '(${expected.labelOf(nextExpected)}).',
      );
    }

    // Full sequence tapped — verify order.
    if (_listEquals(tappedSequence, expectedOrder)) {
      return const ValidationResult(
        isValid: true,
        hint: 'Traversal complete — all nodes visited in the correct order. '
            'Tap "Check & Continue" to finish.',
      );
    }

    // Should not normally be reached (wrong taps reset the sequence in the
    // screen), but handles the edge case defensively.
    return const ValidationResult(
      isValid: false,
      hint: 'The traversal order is incorrect. '
          'Tap the nodes starting from HEAD and following each arrow.',
      misconceptionCode: 'DSA_INVALID_TRAVERSAL',
      misconceptionTitle: 'Invalid Traversal',
      misconceptionDescription:
          'The student tapped nodes in the wrong traversal order.',
      misconceptionSeverity: 'MEDIUM',
    );
  }

  /// Checks whether [tappedNodeId] is the correct next node in the traversal.
  ///
  /// Called by the screen *before* appending to [tappedSequence], so a wrong
  /// tap can trigger a reset with corrective feedback without permanently
  /// corrupting the sequence.
  ValidationResult validateNextTap(
    int tappedNodeId,
    List<int> tappedSequence,
    LinkedListGraph expected,
  ) {
    final expectedOrder = expected.traversalOrder();
    final nextIndex = tappedSequence.length;

    if (nextIndex >= expectedOrder.length) {
      // Already complete — extra tap.
      return const ValidationResult(
        isValid: false,
        hint: 'You have already visited all nodes.',
      );
    }

    final expectedNext = expectedOrder[nextIndex];
    if (tappedNodeId == expectedNext) {
      // Correct tap — let the screen append and then call validateTraversal.
      return ValidationResult(
        isValid: true,
        hint: nextIndex == 0
            ? 'HEAD found. Follow the arrow to the next node.'
            : 'Correct — follow the next arrow.',
      );
    }

    // Wrong tap — the screen should reset tappedSequence.
    return ValidationResult(
      isValid: false,
      hint: tappedSequence.isEmpty
          ? 'Traversal must start at HEAD — that is not the HEAD node.'
          : 'Wrong node. Traversal was reset — start again from HEAD.',
      misconceptionCode: 'DSA_INVALID_TRAVERSAL',
      misconceptionTitle: 'Invalid Traversal',
      misconceptionDescription:
          'The student tapped a node out of traversal order.',
      misconceptionSeverity: 'MEDIUM',
    );
  }

  // ── Result builder ───────────────────────────────────────────────────────

  /// Wraps accumulated [results] into the summary model used by the result
  /// screen and the quiz submission payload.
  AssessmentResultModel buildResult(List<AssessmentChallengeResult> results) {
    final totalScore = results.fold<int>(0, (sum, r) => sum + r.score);
    final passed = results.where((r) => r.passed).length;
    return AssessmentResultModel(
      challengeResults: results,
      totalScore: totalScore,
      passedChallenges: passed,
    );
  }

  /// Converts a completed [validation] into the storable [AssessmentChallengeResult].
  AssessmentChallengeResult toResult(
    ValidationResult validation,
    int points,
  ) {
    return AssessmentChallengeResult(
      passed: validation.isValid,
      score: validation.isValid ? points : 0,
      feedback: validation.hint,
    );
  }

  // ── Private helpers ──────────────────────────────────────────────────────

  static bool _listEquals(List<int> a, List<int> b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }
}
