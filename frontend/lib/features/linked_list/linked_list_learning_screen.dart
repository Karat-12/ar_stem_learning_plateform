import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../shared/widgets/cyber_background.dart';
import '../../shared/widgets/glass_card.dart';
import '../../shared/widgets/status_chip.dart';
import 'models/linked_list_node_model.dart';
import 'widgets/floating_particles.dart';
import 'widgets/holographic_explanation_panel.dart';
import 'widgets/linked_list_playground.dart';
import 'widgets/misconception_feedback_panel.dart';
import 'widgets/operation_control_panel.dart';

class LinkedListLearningScreen extends StatefulWidget {
  const LinkedListLearningScreen({super.key});

  @override
  State<LinkedListLearningScreen> createState() =>
      _LinkedListLearningScreenState();
}

class _LinkedListLearningScreenState extends State<LinkedListLearningScreen> {
  List<LinkedListNodeModel> _nodes = const [
    LinkedListNodeModel(id: 1, label: 'A', position: Offset(70, 160)),
    LinkedListNodeModel(id: 2, label: 'B', position: Offset(250, 160)),
    LinkedListNodeModel(id: 3, label: 'C', position: Offset(430, 160)),
  ];

  int? _headNodeId = 1;
  int _nextId = 4;
  bool _connectionBroken = false;
  bool _reverseTraversal = false;
  int? _activeTraversalId;
  String _feedback = 'Ready: arrange nodes or run an operation.';
  Color _feedbackColor = AppColors.cyan;

  void _moveNode(int id, Offset position) {
    setState(() {
      _nodes = _nodes
          .map(
            (node) => node.id == id ? node.copyWith(position: position) : node,
          )
          .toList();
    });
  }

  void _insertNode() {
    final label = String.fromCharCode(64 + _nextId);
    setState(() {
      _nodes = [
        ..._nodes,
        LinkedListNodeModel(
          id: _nextId,
          label: label,
          position: Offset(100.0 + (_nodes.length * 105) % 460, 300),
        ),
      ];
      _feedback =
          'Inserted node $label. A linked list grows by changing links.';
      _feedbackColor = AppColors.lime;
      _nextId++;
    });
    _detectMisconceptions();
  }

  void _deleteTailNode() {
    if (_nodes.isEmpty) {
      return;
    }

    setState(() {
      final removed = _nodes.last;
      _nodes = _nodes.sublist(0, _nodes.length - 1);
      if (_headNodeId == removed.id) {
        _headNodeId = _nodes.isEmpty ? null : _nodes.first.id;
      }
      _feedback =
          'Deleted node ${removed.label}. The previous node now points forward.';
      _feedbackColor = AppColors.orange;
    });
    _detectMisconceptions();
  }

  void _toggleBrokenConnection() {
    setState(() {
      _connectionBroken = !_connectionBroken;
    });
    _detectMisconceptions();
  }

  void _toggleHead() {
    setState(() {
      _headNodeId = _headNodeId == null && _nodes.isNotEmpty
          ? _nodes.first.id
          : null;
    });
    _detectMisconceptions();
  }

  void _toggleTraversalOrder() {
    setState(() {
      _reverseTraversal = !_reverseTraversal;
    });
    _detectMisconceptions();
  }

  Future<void> _runTraversal() async {
    final ordered = [..._nodes]
      ..sort((a, b) => a.position.dx.compareTo(b.position.dx));
    final traversal = _reverseTraversal ? ordered.reversed.toList() : ordered;

    for (final node in traversal) {
      if (!mounted) {
        return;
      }
      setState(() {
        _activeTraversalId = node.id;
        _feedback = 'Traversal visiting node ${node.label}...';
        _feedbackColor = AppColors.cyan;
      });
      await Future<void>.delayed(const Duration(milliseconds: 560));
    }

    if (!mounted) {
      return;
    }

    setState(() => _activeTraversalId = null);
    _detectMisconceptions();
  }

  void _detectMisconceptions() {
    setState(() {
      if (_headNodeId == null) {
        _feedback = 'Head node missing';
        _feedbackColor = AppColors.pink;
        return;
      }

      if (_connectionBroken) {
        _feedback = 'Node linkage mismatch detected';
        _feedbackColor = AppColors.pink;
        return;
      }

      if (_reverseTraversal) {
        _feedback = 'Traversal path incorrect';
        _feedbackColor = AppColors.orange;
        return;
      }

      _feedback = 'Great! Head and node links form a valid left-to-right path.';
      _feedbackColor = AppColors.lime;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CyberBackground(
        child: Stack(
          children: [
            const Positioned.fill(child: FloatingParticles()),
            SafeArea(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final isWide = constraints.maxWidth >= 1040;

                  return SingleChildScrollView(
                    padding: EdgeInsets.symmetric(
                      horizontal: isWide ? 34 : 18,
                      vertical: 24,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _LinkedListHeader(onBack: () => Navigator.pop(context)),
                        const SizedBox(height: 22),
                        if (isWide)
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                flex: 7,
                                child: _WorkspaceColumn(
                                  nodes: _nodes,
                                  headNodeId: _headNodeId,
                                  connectionBroken: _connectionBroken,
                                  activeTraversalId: _activeTraversalId,
                                  onMoveNode: _moveNode,
                                ),
                              ),
                              const SizedBox(width: 22),
                              Expanded(
                                flex: 4,
                                child: _LearningSidePanel(
                                  feedback: _feedback,
                                  feedbackColor: _feedbackColor,
                                  connectionBroken: _connectionBroken,
                                  headMissing: _headNodeId == null,
                                  reverseTraversal: _reverseTraversal,
                                  onInsert: _insertNode,
                                  onDelete: _deleteTailNode,
                                  onTraverse: _runTraversal,
                                  onToggleBrokenConnection:
                                      _toggleBrokenConnection,
                                  onToggleHead: _toggleHead,
                                  onToggleTraversalOrder: _toggleTraversalOrder,
                                ),
                              ),
                            ],
                          )
                        else ...[
                          _WorkspaceColumn(
                            nodes: _nodes,
                            headNodeId: _headNodeId,
                            connectionBroken: _connectionBroken,
                            activeTraversalId: _activeTraversalId,
                            onMoveNode: _moveNode,
                          ),
                          const SizedBox(height: 18),
                          _LearningSidePanel(
                            feedback: _feedback,
                            feedbackColor: _feedbackColor,
                            connectionBroken: _connectionBroken,
                            headMissing: _headNodeId == null,
                            reverseTraversal: _reverseTraversal,
                            onInsert: _insertNode,
                            onDelete: _deleteTailNode,
                            onTraverse: _runTraversal,
                            onToggleBrokenConnection: _toggleBrokenConnection,
                            onToggleHead: _toggleHead,
                            onToggleTraversalOrder: _toggleTraversalOrder,
                          ),
                        ],
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LinkedListHeader extends StatelessWidget {
  const _LinkedListHeader({required this.onBack});

  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 18,
      runSpacing: 16,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        IconButton.filledTonal(
          onPressed: onBack,
          icon: const Icon(Icons.arrow_back_rounded),
          color: AppColors.cyan,
        ),
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 850),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const StatusChip(label: 'Data Structures Module'),
              const SizedBox(height: 12),
              Text(
                'Linked List Learning Workspace',
                style: Theme.of(context).textTheme.headlineLarge,
              ),
              const SizedBox(height: 10),
              Text(
                'Build, rearrange, traverse, and intentionally test common linked-list mistakes in a holographic playground.',
                style: Theme.of(context).textTheme.bodyLarge,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _WorkspaceColumn extends StatelessWidget {
  const _WorkspaceColumn({
    required this.nodes,
    required this.headNodeId,
    required this.connectionBroken,
    required this.activeTraversalId,
    required this.onMoveNode,
  });

  final List<LinkedListNodeModel> nodes;
  final int? headNodeId;
  final bool connectionBroken;
  final int? activeTraversalId;
  final void Function(int id, Offset position) onMoveNode;

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Interactive Node Playground',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          Text(
            'Drag nodes around. Arrows connect the visual order from left to right.',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 16),
          LinkedListPlayground(
            nodes: nodes,
            headNodeId: headNodeId,
            connectionBroken: connectionBroken,
            activeTraversalId: activeTraversalId,
            onMoveNode: onMoveNode,
          ),
        ],
      ),
    );
  }
}

class _LearningSidePanel extends StatelessWidget {
  const _LearningSidePanel({
    required this.feedback,
    required this.feedbackColor,
    required this.connectionBroken,
    required this.headMissing,
    required this.reverseTraversal,
    required this.onInsert,
    required this.onDelete,
    required this.onTraverse,
    required this.onToggleBrokenConnection,
    required this.onToggleHead,
    required this.onToggleTraversalOrder,
  });

  final String feedback;
  final Color feedbackColor;
  final bool connectionBroken;
  final bool headMissing;
  final bool reverseTraversal;
  final VoidCallback onInsert;
  final VoidCallback onDelete;
  final VoidCallback onTraverse;
  final VoidCallback onToggleBrokenConnection;
  final VoidCallback onToggleHead;
  final VoidCallback onToggleTraversalOrder;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        OperationControlPanel(
          connectionBroken: connectionBroken,
          headMissing: headMissing,
          reverseTraversal: reverseTraversal,
          onInsert: onInsert,
          onDelete: onDelete,
          onTraverse: onTraverse,
          onToggleBrokenConnection: onToggleBrokenConnection,
          onToggleHead: onToggleHead,
          onToggleTraversalOrder: onToggleTraversalOrder,
        ),
        const SizedBox(height: 16),
        MisconceptionFeedbackPanel(message: feedback, accent: feedbackColor),
        const SizedBox(height: 16),
        const HolographicExplanationPanel(),
      ],
    );
  }
}
