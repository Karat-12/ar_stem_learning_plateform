/// Internal logical model for a singly-linked list.
///
/// This class is an implementation detail of the assessment engine.
/// It is never exposed to the learner — students interact with the visual
/// playground and the engine translates those interactions into graph mutations.
///
/// No Flutter imports. Pure Dart only.
class LinkedListGraph {
  LinkedListGraph({
    required Map<int, String> nodes,
    required Map<int, int?> nextPointers,
    required int? headId,
  })  : _nodes = Map.unmodifiable(nodes),
        _nextPointers = Map.unmodifiable(nextPointers),
        _headId = headId;

  /// id → display label.  Labels are stored for the canvas to render but are
  /// never read by any validator.
  final Map<int, String> _nodes;

  /// Explicit pointer graph: nodeId → nextNodeId (null means end-of-list).
  final Map<int, int?> _nextPointers;

  final int? _headId;

  // ── Public read-only accessors ──────────────────────────────────────────

  int? get headId => _headId;

  /// All node ids in insertion order.
  List<int> get nodeIds => List.unmodifiable(_nodes.keys.toList());

  /// Display label for [id].  Returns empty string for unknown ids.
  String labelOf(int id) => _nodes[id] ?? '';

  /// The next-pointer of [id] (null means end-of-list or not yet assigned).
  int? nextOf(int id) => _nextPointers[id];

  // ── Structural queries ──────────────────────────────────────────────────

  /// Traversal order starting from [headId], following [nextPointers].
  ///
  /// Returns an empty list when [headId] is null.
  /// Stops at null and protects against cycles (visits each id at most once).
  List<int> traversalOrder() {
    if (_headId == null) return const [];

    final visited = <int>[];
    final seen = <int>{};
    int? current = _headId;

    while (current != null && !seen.contains(current)) {
      seen.add(current);
      visited.add(current);
      current = _nextPointers[current];
    }

    return List.unmodifiable(visited);
  }

  /// True when every node in the graph is reachable from [headId] and
  /// no node is isolated (i.e. not present in the traversal chain).
  bool isFullyConnected() {
    if (_headId == null) return false;
    final reachable = traversalOrder();
    return reachable.length == _nodes.length;
  }

  /// Node ids that are not reachable from [headId].
  List<int> isolatedNodeIds() {
    final reachable = traversalOrder().toSet();
    return _nodes.keys.where((id) => !reachable.contains(id)).toList();
  }

  /// True when the pointer graph contains a cycle.
  bool hasCycle() {
    if (_headId == null) return false;
    final seen = <int>{};
    int? current = _headId;
    while (current != null) {
      if (seen.contains(current)) return true;
      seen.add(current);
      current = _nextPointers[current];
    }
    return false;
  }

  // ── Mutation (returns a new immutable instance) ─────────────────────────

  /// Returns a new graph with [headId] changed to [newHeadId].
  LinkedListGraph withHead(int? newHeadId) {
    return LinkedListGraph(
      nodes: Map.of(_nodes),
      nextPointers: Map.of(_nextPointers),
      headId: newHeadId,
    );
  }

  /// Returns a new graph where [fromId] points to [toId].
  /// Pass [toId] as null to clear an existing pointer (break the link).
  LinkedListGraph withPointer({required int fromId, required int? toId}) {
    final updated = Map<int, int?>.of(_nextPointers);
    updated[fromId] = toId;
    return LinkedListGraph(
      nodes: Map.of(_nodes),
      nextPointers: updated,
      headId: _headId,
    );
  }

  // ── Equality ────────────────────────────────────────────────────────────

  /// Structural equality: two graphs are equal when they have the same
  /// headId, the same pointer map, and the same node set.
  /// Labels are intentionally excluded — two graphs with different display
  /// labels but identical structure are considered equal.
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! LinkedListGraph) return false;
    if (_headId != other._headId) return false;
    if (_nodes.length != other._nodes.length) return false;
    for (final id in _nodes.keys) {
      if (!other._nodes.containsKey(id)) return false;
    }
    for (final id in _nextPointers.keys) {
      if (_nextPointers[id] != other._nextPointers[id]) return false;
    }
    return true;
  }

  @override
  int get hashCode => Object.hash(_headId, _nodes.keys.toSet(), _nextPointers);

  @override
  String toString() {
    final chain = traversalOrder().map((id) => '${labelOf(id)}($id)').join(' → ');
    return 'LinkedListGraph(head=$_headId, chain=[$chain], isolated=${isolatedNodeIds()})';
  }
}
