import '../../assessments/linked_list_assessment/models/linked_list_graph.dart';

/// A single construction-based learning task for the Linked List workspace.
///
/// Pure Dart — no Flutter imports.
///
/// Fields are kept separate so the UI can render each section independently:
///   [concept]       → "What is a linked list?" explanation card
///   [whyItMatters]  → "Why this matters" motivational line
///   [prompt]        → step-by-step build instructions
///   [hints]         → progressive hints shown on failed VERIFY
///   [explanation]   → post-success concept reinforcement
class LinkedListTask {
  const LinkedListTask({
    required this.id,
    required this.title,
    required this.concept,
    required this.whyItMatters,
    required this.prompt,
    required this.nodeValues,
    required this.expectedGraph,
    this.explanation = '',
    this.hints = const [],
  });

  /// Unique stable identifier for this task.
  final String id;

  /// Short title shown in the progress header.
  final String title;

  /// One-paragraph concept explanation shown at the top of the learning panel.
  ///
  /// Should explain the core idea being practised in this task in plain,
  /// student-friendly language. Shown before any construction takes place.
  final String concept;

  /// Single sentence shown in the "Why this matters" section.
  ///
  /// Motivates the concept by relating it to real traversal consequences.
  final String whyItMatters;

  /// Step-by-step build instructions shown below the concept.
  final String prompt;

  /// The values (labels) of the nodes the student receives in the palette.
  ///
  /// The order here defines stable node IDs: nodeValues[0] → id=1, etc.
  final List<String> nodeValues;

  /// The correct logical structure the student must construct.
  ///
  /// Validator compares structural relationships (IDs + pointers), never
  /// label strings or screen coordinates.
  final LinkedListGraph expectedGraph;

  /// Shown after a successful VERIFY — reinforces what was just learned.
  final String explanation;

  /// Progressive hints shown on each failed VERIFY attempt.
  /// Index 0 is lightest; later entries escalate toward the answer.
  final List<String> hints;

  // ── Helpers ────────────────────────────────────────────────────────────────

  /// Blank graph for this task: all nodes present, no pointers, no HEAD.
  LinkedListGraph buildEmptyGraph() {
    final nodes = <int, String>{};
    final pointers = <int, int?>{};
    for (var i = 0; i < nodeValues.length; i++) {
      final id = i + 1;
      nodes[id] = nodeValues[i];
      pointers[id] = null;
    }
    return LinkedListGraph(nodes: nodes, nextPointers: pointers, headId: null);
  }

  /// Maps each node value label to its stable integer ID for this task.
  Map<String, int> get valueToId => {
        for (var i = 0; i < nodeValues.length; i++) nodeValues[i]: i + 1,
      };
}

// ─────────────────────────────────────────────────────────────────────────────
// Learning task catalogue
// ─────────────────────────────────────────────────────────────────────────────

final List<LinkedListTask> kLinkedListTasks = [
  // ── Task 1 ─────────────────────────────────────────────────────────────────
  LinkedListTask(
    id: 'task-ll-1',
    title: 'Build an Ascending Linked List',
    concept:
        'A linked list is a sequence of nodes. Each node stores a value and '
        'a pointer to the next node in the chain. The list has no fixed '
        'size — nodes are connected by pointers, not by physical memory '
        'positions. The first node is called HEAD, and traversal always '
        'starts there.',
    whyItMatters:
        'If HEAD is wrong, traversal visits the wrong node first — '
        'every operation that follows will produce incorrect results.',
    prompt: 'Build a 3-node linked list in ascending order.\n\n'
        '1. Drag nodes 10, 20, and 30 from the palette into the workspace.\n'
        '2. Long-press node 10 and tap "Set as HEAD".\n'
        '3. Tap node 10, then tap node 20 to connect them.\n'
        '4. Tap node 20, then tap node 30 to connect them.\n'
        '5. Press VERIFY when the chain is ready.',
    nodeValues: ['10', '20', '30'],
    // IDs:  10→1   20→2   30→3
    expectedGraph: LinkedListGraph(
      nodes: {1: '10', 2: '20', 3: '30'},
      nextPointers: {1: 2, 2: 3, 3: null},
      headId: 1,
    ),
    explanation:
        'Each node stores data and a "next" pointer. Node 10 points to 20, '
        'node 20 points to 30, and node 30 points to null — marking the end '
        'of the list. HEAD (node 10) is the entry point. The chain is '
        '10 → 20 → 30 → null.',
    hints: [
      'Start by dragging all three nodes onto the workspace.',
      'Long-press node 10 and choose "Set as HEAD" to mark where '
          'traversal begins.',
      'Tap node 10, then tap node 20 to draw the first connection arrow.',
      'Tap node 20, then tap node 30 to complete the chain.',
    ],
  ),

  // ── Task 2 ─────────────────────────────────────────────────────────────────
  LinkedListTask(
    id: 'task-ll-2',
    title: 'Understand HEAD and TAIL',
    concept:
        'Every linked list has a HEAD and a TAIL. HEAD is the first node — '
        'it is where all traversals begin. TAIL is the last node — its '
        '"next" pointer is null, which signals the end of the list. '
        'There is no shortcut to the TAIL; you must follow each pointer '
        'from HEAD until you reach null.',
    whyItMatters:
        'Knowing HEAD and TAIL is essential for insertion, deletion, '
        'and traversal. Getting HEAD wrong makes the whole list unreachable.',
    prompt: 'Build the same 3-node list and identify its HEAD and TAIL.\n\n'
        '1. Drag nodes 10, 20, and 30 into the workspace.\n'
        '2. Set node 10 as HEAD (long-press → "Set as HEAD").\n'
        '3. Connect 10 → 20 and 20 → 30.\n'
        '4. Notice the TAIL indicator — it appears on node 30 '
        'automatically once it has no outgoing connection.\n'
        '5. Press VERIFY.',
    nodeValues: ['10', '20', '30'],
    expectedGraph: LinkedListGraph(
      nodes: {1: '10', 2: '20', 3: '30'},
      nextPointers: {1: 2, 2: 3, 3: null},
      headId: 1,
    ),
    explanation:
        'HEAD → 10 → 20 → 30 → null. Node 10 is HEAD because it is first '
        'in the chain. Node 30 is TAIL because its next pointer is null. '
        'Traversal visits every node exactly once by following "next" '
        'pointers from HEAD until null is reached.',
    hints: [
      'This is the same structure as Task 1 — build 10 → 20 → 30.',
      'Set node 10 as HEAD. The TAIL badge will appear on node 30 '
          'automatically once all three nodes are connected.',
      'Connect 10 → 20 → 30. TAIL is derived — you do not set it manually.',
    ],
  ),

  // ── Task 3 ─────────────────────────────────────────────────────────────────
  LinkedListTask(
    id: 'task-ll-3',
    title: 'Traverse a Linked List',
    concept:
        'Traversal means visiting every node in order, starting from HEAD '
        'and following each "next" pointer until null is reached. The order '
        'of traversal is determined entirely by the pointer chain — not by '
        'where nodes appear on screen. Two lists with the same values but '
        'different pointer arrangements produce different traversal orders.',
    whyItMatters:
        'Traversal is the foundation of search, insertion at a position, '
        'deletion, and printing a list. Understanding traversal order is '
        'the first step to understanding all linked list algorithms.',
    prompt:
        'Construct the list so that traversal visits nodes in ascending order.'
        '\n\n'
        'Expected traversal: 10 → 20 → 30 → null\n\n'
        '1. Drag nodes 10, 20, and 30 into the workspace.\n'
        '2. Set node 10 as HEAD.\n'
        '3. Connect 10 → 20, then 20 → 30.\n'
        '4. The TAIL badge should appear on node 30.\n'
        '5. Press VERIFY. The validator checks the logical traversal order — '
        'node positions on screen do not matter.',
    nodeValues: ['10', '20', '30'],
    expectedGraph: LinkedListGraph(
      nodes: {1: '10', 2: '20', 3: '30'},
      nextPointers: {1: 2, 2: 3, 3: null},
      headId: 1,
    ),
    explanation:
        'Traversal follows the pointer chain: start at HEAD (10), '
        'read the value, move to next (20), read, move to next (30), '
        'read, next is null — stop. '
        'The traversal sequence is 10 → 20 → 30. '
        'Pointer order is what matters, not visual position.',
    hints: [
      'Build the chain: drag all three nodes onto the workspace.',
      'Set node 10 as HEAD so traversal starts at the smallest value.',
      'Connect nodes in ascending order: 10 → 20 → 30.',
      'The validator checks traversal order by following pointers — '
          'make sure every connection points to the next larger value.',
    ],
  ),
];
