import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../shared/widgets/glass_card.dart';
import '../../shared/widgets/status_chip.dart';

class AdvancedStemWorkspacesScreen extends StatefulWidget {
  const AdvancedStemWorkspacesScreen({super.key});

  @override
  State<AdvancedStemWorkspacesScreen> createState() =>
      _AdvancedStemWorkspacesScreenState();
}

class _AdvancedStemWorkspacesScreenState
    extends State<AdvancedStemWorkspacesScreen> {
  int? _domainIndex;
  int? _topicIndex;

  static const _domains = [
    _LearningDomain(
      title: 'Data Structures',
      subtitle: 'Visualize memory logic, ordering rules, and traversal errors.',
      icon: Icons.account_tree_rounded,
      accent: AppColors.cyan,
      topics: [
        _LearningTopic(
          title: 'Linked List',
          subtitle: 'Explore head pointers, node links, and traversal paths.',
          icon: Icons.linear_scale_rounded,
        ),
        _LearningTopic(
          title: 'Stack',
          subtitle: 'Practice PUSH, POP, TOP, overflow, and underflow.',
          icon: Icons.layers_rounded,
        ),
        _LearningTopic(
          title: 'Binary Tree',
          subtitle: 'Place nodes and simulate inorder, preorder, postorder.',
          icon: Icons.account_tree_outlined,
        ),
      ],
    ),
    _LearningDomain(
      title: 'Digital Electronics',
      subtitle:
          'Digital Logic Construction Learning with gate design and truth tables.',
      icon: Icons.memory_rounded,
      accent: AppColors.violet,
      topics: [
        _LearningTopic(
          title: 'Basic Logic Gates',
          subtitle: 'Learn AND, OR, NOT by placing and testing core gates.',
          icon: Icons.compare_arrows_rounded,
        ),
        _LearningTopic(
          title: 'XOR Gate Builder',
          subtitle: 'Construct XOR from AND / OR / NOT combinations.',
          icon: Icons.change_circle_rounded,
        ),
        _LearningTopic(
          title: 'Complex Gate Construction',
          subtitle: 'Build NAND, NOR, and XNOR from basic logic elements.',
          icon: Icons.layers_rounded,
        ),
        _LearningTopic(
          title: 'Truth Table Simulator',
          subtitle: 'Verify input/output behavior and detect logic mistakes.',
          icon: Icons.table_chart_rounded,
        ),
      ],
    ),
    _LearningDomain(
      title: 'Organic Chemistry',
      subtitle:
          'Molecule Construction Learning with atom placement and bond validation.',
      icon: Icons.science_rounded,
      accent: AppColors.lime,
      topics: [
        _LearningTopic(
          title: 'Hydrocarbon Builder',
          subtitle: 'Build methane, ethane, ethene, and ethyne structures.',
          icon: Icons.local_fire_department_rounded,
        ),
        _LearningTopic(
          title: 'Sugar Structure Builder',
          subtitle: 'Assemble simplified glucose and sucrose arrangements.',
          icon: Icons.candlestick_chart_rounded,
        ),
        _LearningTopic(
          title: 'Alcohol & Functional Groups',
          subtitle: 'Add OH, N, and oxygen attachments to carbon scaffolds.',
          icon: Icons.water_drop_rounded,
        ),
        _LearningTopic(
          title: 'Bond Simulator',
          subtitle: 'Explore single, double, and triple bond behavior.',
          icon: Icons.auto_fix_high_rounded,
        ),
      ],
    ),
  ];

  void _openDomain(int index) {
    setState(() {
      _domainIndex = index;
      _topicIndex = null;
    });
  }

  void _openTopic(int index) {
    setState(() => _topicIndex = index);
  }

  void _goBack() {
    setState(() {
      if (_topicIndex != null) {
        _topicIndex = null;
      } else {
        _domainIndex = null;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final selectedDomain = _domainIndex == null
        ? null
        : _domains[_domainIndex!];
    final selectedTopic = selectedDomain == null || _topicIndex == null
        ? null
        : selectedDomain.topics[_topicIndex!];
    final title =
        selectedTopic?.title ??
        selectedDomain?.title ??
        'Choose Interactive Learning Domain';
    final subtitle =
        selectedTopic?.subtitle ??
        selectedDomain?.subtitle ??
        'Select a STEM domain first. Then choose a topic to open the interactive workspace.';

    return SafeArea(
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isWide = constraints.maxWidth >= 960;

          return SingleChildScrollView(
            padding: EdgeInsets.symmetric(
              horizontal: isWide ? 34 : 18,
              vertical: 24,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const StatusChip(label: 'Advanced Interactive STEM Labs'),
                const SizedBox(height: 14),
                if (_domainIndex != null) ...[
                  IconButton.filledTonal(
                    onPressed: _goBack,
                    icon: const Icon(Icons.arrow_back_rounded),
                    color: AppColors.cyan,
                  ),
                  const SizedBox(height: 14),
                ],
                Text(title, style: Theme.of(context).textTheme.headlineLarge),
                const SizedBox(height: 10),
                Text(subtitle, style: Theme.of(context).textTheme.bodyLarge),
                const SizedBox(height: 22),
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 360),
                  switchInCurve: Curves.easeOutCubic,
                  switchOutCurve: Curves.easeInCubic,
                  child: KeyedSubtree(
                    key: ValueKey('$_domainIndex:$_topicIndex'),
                    child: _buildCurrentStep(isWide),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildCurrentStep(bool isWide) {
    if (_domainIndex == null) {
      return _DomainSelectionGrid(
        domains: _domains,
        isWide: isWide,
        onSelect: _openDomain,
      );
    }

    final domain = _domains[_domainIndex!];
    if (_topicIndex == null) {
      return _TopicSelectionGrid(
        domain: domain,
        isWide: isWide,
        onSelect: _openTopic,
      );
    }

    return switch (_domainIndex!) {
      0 => DataStructuresWorkspace(topicIndex: _topicIndex!),
      1 => DigitalElectronicsWorkspace(topicIndex: _topicIndex!),
      _ => OrganicChemistryWorkspace(topicIndex: _topicIndex!),
    };
  }
}

class _DomainSelectionGrid extends StatelessWidget {
  const _DomainSelectionGrid({
    required this.domains,
    required this.isWide,
    required this.onSelect,
  });

  final List<_LearningDomain> domains;
  final bool isWide;
  final ValueChanged<int> onSelect;

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: isWide ? 3 : 1,
        crossAxisSpacing: 18,
        mainAxisSpacing: 18,
        childAspectRatio: isWide ? 1.08 : 2.65,
      ),
      itemCount: domains.length,
      itemBuilder: (context, index) {
        final domain = domains[index];
        return _LearningCard(
          title: domain.title,
          subtitle: domain.subtitle,
          icon: domain.icon,
          accent: domain.accent,
          footer:
              '${domain.topics.length} topic${domain.topics.length == 1 ? '' : 's'}',
          onTap: () => onSelect(index),
        );
      },
    );
  }
}

class _TopicSelectionGrid extends StatelessWidget {
  const _TopicSelectionGrid({
    required this.domain,
    required this.isWide,
    required this.onSelect,
  });

  final _LearningDomain domain;
  final bool isWide;
  final ValueChanged<int> onSelect;

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: isWide
            ? (domain.topics.length < 3 ? domain.topics.length : 3)
            : 1,
        crossAxisSpacing: 18,
        mainAxisSpacing: 18,
        childAspectRatio: isWide ? 1.2 : 2.55,
      ),
      itemCount: domain.topics.length,
      itemBuilder: (context, index) {
        final topic = domain.topics[index];
        return _LearningCard(
          title: topic.title,
          subtitle: topic.subtitle,
          icon: topic.icon,
          accent: domain.accent,
          footer: 'Open workspace',
          onTap: () => onSelect(index),
        );
      },
    );
  }
}

class DataStructuresWorkspace extends StatelessWidget {
  const DataStructuresWorkspace({super.key, required this.topicIndex});

  final int topicIndex;

  @override
  Widget build(BuildContext context) {
    return switch (topicIndex) {
      0 => const _LinkedListLearningLab(),
      1 => const StackLearningLab(),
      _ => const BinaryTreeLearningLab(),
    };
  }
}

class _LearningCard extends StatefulWidget {
  const _LearningCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.accent,
    required this.footer,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final Color accent;
  final String footer;
  final VoidCallback onTap;

  @override
  State<_LearningCard> createState() => _LearningCardState();
}

class _LearningCardState extends State<_LearningCard> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: TweenAnimationBuilder<double>(
        tween: Tween(end: _hovered ? 1 : 0),
        duration: const Duration(milliseconds: 240),
        curve: Curves.easeOutCubic,
        builder: (context, glow, child) {
          return Transform.translate(
            offset: Offset(0, -5 * glow),
            child: InkWell(
              borderRadius: BorderRadius.circular(24),
              onTap: widget.onTap,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 240),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: widget.accent.withValues(
                        alpha: 0.16 + glow * 0.22,
                      ),
                      blurRadius: 22 + glow * 24,
                    ),
                  ],
                ),
                child: GlassCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 56,
                        height: 56,
                        decoration: BoxDecoration(
                          color: widget.accent.withValues(alpha: 0.14),
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(
                            color: widget.accent.withValues(alpha: 0.48),
                          ),
                        ),
                        child: Icon(widget.icon, color: widget.accent),
                      ),
                      const Spacer(),
                      Text(
                        widget.title,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        widget.subtitle,
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                      const SizedBox(height: 14),
                      Row(
                        children: [
                          Text(
                            widget.footer,
                            style: TextStyle(
                              color: widget.accent,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Icon(
                            Icons.arrow_forward_rounded,
                            color: widget.accent,
                            size: 18,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class StackLearningLab extends StatefulWidget {
  const StackLearningLab({super.key});

  @override
  State<StackLearningLab> createState() => _StackLearningLabState();
}

class _StackLearningLabState extends State<StackLearningLab> {
  final List<String> _items = ['18', '27'];
  final int _capacity = 5;
  int _next = 42;
  int _activeIndex = -1;
  String _feedback = 'Drag a value or press PUSH to grow the stack.';
  Color _accent = AppColors.cyan;
  bool _topMismatch = false;

  void _push([String? value]) {
    if (_items.length >= _capacity) {
      _setFeedback('Stack overflow condition detected', AppColors.pink);
      return;
    }
    setState(() {
      _items.add(value ?? '${_next++}');
      _activeIndex = _items.length - 1;
      _topMismatch = false;
    });
    _setFeedback('PUSH complete. TOP pointer moved upward.', AppColors.lime);
  }

  Future<void> _pop() async {
    if (_items.isEmpty) {
      _setFeedback('Invalid POP operation', AppColors.pink);
      return;
    }
    setState(() => _activeIndex = _items.length - 1);
    await Future<void>.delayed(const Duration(milliseconds: 280));
    if (!mounted) {
      return;
    }
    setState(() {
      _items.removeLast();
      _activeIndex = _items.length - 1;
      _topMismatch = false;
    });
    _setFeedback(
      'POP complete. Removed last inserted element.',
      AppColors.lime,
    );
  }

  void _toggleTopMismatch() {
    setState(() => _topMismatch = !_topMismatch);
    _setFeedback(
      _topMismatch ? 'TOP pointer restored' : 'TOP pointer mismatch',
      _topMismatch ? AppColors.lime : AppColors.orange,
    );
  }

  void _setFeedback(String message, Color color) {
    setState(() {
      _feedback = message;
      _accent = color;
    });
  }

  @override
  Widget build(BuildContext context) {
    return _ResponsiveLabShell(
      workspace: _CyberPanel(
        title: 'Animated Stack Workspace',
        subtitle: 'Drop values into the stack. The capacity is five blocks.',
        child: _StackBoard(
          items: _items,
          capacity: _capacity,
          activeIndex: _activeIndex,
          topMismatch: _topMismatch,
          onAccept: _push,
        ),
      ),
      sidePanel: Column(
        children: [
          _CyberPanel(
            title: 'Operations',
            subtitle: 'Run LIFO operations and trigger misconception checks.',
            child: Column(
              children: [
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: [
                    _GlowButton(
                      label: 'PUSH',
                      icon: Icons.vertical_align_top_rounded,
                      color: AppColors.cyan,
                      onTap: () => _push(),
                    ),
                    _GlowButton(
                      label: 'POP',
                      icon: Icons.vertical_align_bottom_rounded,
                      color: AppColors.orange,
                      onTap: _pop,
                    ),
                    _GlowButton(
                      label: 'TOP',
                      icon: Icons.my_location_rounded,
                      color: AppColors.violet,
                      onTap: _toggleTopMismatch,
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    for (final value in ['64', '75', '91'])
                      Draggable<String>(
                        data: value,
                        feedback: _DragChip(label: value, large: true),
                        childWhenDragging: Opacity(
                          opacity: 0.35,
                          child: _DragChip(label: value),
                        ),
                        child: _DragChip(label: value),
                      ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          _FeedbackPanel(message: _feedback, accent: _accent),
          const SizedBox(height: 14),
          const _ExplanationPanel(
            title: 'Stack Concept',
            points: [
              'A stack follows Last In, First Out behavior.',
              'PUSH inserts at TOP. POP removes from TOP.',
              'Overflow happens when capacity is full; underflow happens when POP runs on an empty stack.',
            ],
          ),
        ],
      ),
    );
  }
}

class BinaryTreeLearningLab extends StatefulWidget {
  const BinaryTreeLearningLab({super.key});

  @override
  State<BinaryTreeLearningLab> createState() => _BinaryTreeLearningLabState();
}

class _BinaryTreeLearningLabState extends State<BinaryTreeLearningLab> {
  final List<_TreeNode> _nodes = [
    _TreeNode('A', const Offset(270, 48)),
    _TreeNode('B', const Offset(150, 170)),
    _TreeNode('C', const Offset(390, 170)),
    _TreeNode('D', const Offset(94, 292)),
  ];
  String _active = '';
  String _feedback = 'Place nodes and run a traversal simulation.';
  Color _accent = AppColors.cyan;
  bool _badHierarchy = false;
  bool _badTraversal = false;

  void _move(String label, Offset delta) {
    setState(() {
      final index = _nodes.indexWhere((node) => node.label == label);
      if (index < 0) return;
      _nodes[index] = _nodes[index].copyWith(_nodes[index].position + delta);
    });
  }

  void _addNode(String label) {
    if (_nodes.any((node) => node.label == label)) {
      _setFeedback('Node $label already exists on the tree', AppColors.orange);
      return;
    }
    setState(() {
      _nodes.add(_TreeNode(label, const Offset(250, 340)));
      _feedback = 'Placed node $label on the board. Drag to position it.';
      _accent = AppColors.lime;
    });
  }

  Future<void> _traverse(String mode) async {
    final order = switch (mode) {
      'Inorder' => ['D', 'B', 'A', 'C'],
      'Preorder' => ['A', 'B', 'D', 'C'],
      _ => ['D', 'B', 'C', 'A'],
    };
    final shown = _badTraversal ? order.reversed.toList() : order;
    for (final label in shown) {
      if (!mounted) {
        return;
      }
      setState(() {
        _active = label;
        _feedback = '$mode traversal visiting node $label';
        _accent = AppColors.cyan;
      });
      await Future<void>.delayed(const Duration(milliseconds: 520));
    }
    if (!mounted) {
      return;
    }
    setState(() => _active = '');
    _setFeedback(
      _badTraversal
          ? 'Traversal sequence mismatch'
          : '$mode traversal order validated',
      _badTraversal ? AppColors.orange : AppColors.lime,
    );
  }

  void _toggleHierarchy() {
    setState(() => _badHierarchy = !_badHierarchy);
    _setFeedback(
      _badHierarchy
          ? 'Binary tree hierarchy incorrect'
          : 'Parent-child hierarchy restored',
      _badHierarchy ? AppColors.pink : AppColors.lime,
    );
  }

  void _toggleTraversalMistake() {
    setState(() => _badTraversal = !_badTraversal);
    _setFeedback(
      _badTraversal
          ? 'Invalid traversal order armed'
          : 'Traversal sequence restored',
      _badTraversal ? AppColors.orange : AppColors.lime,
    );
  }

  void _setFeedback(String message, Color color) {
    setState(() {
      _feedback = message;
      _accent = color;
    });
  }

  @override
  Widget build(BuildContext context) {
    return _ResponsiveLabShell(
      workspace: _CyberPanel(
        title: 'Binary Tree Builder',
        subtitle: 'Drag nodes into hierarchy slots and simulate traversals.',
        child: _TreeBoard(
          nodes: _nodes,
          active: _active,
          badHierarchy: _badHierarchy,
          onMove: _move,
          onAccept: _addNode,
        ),
      ),
      sidePanel: Column(
        children: [
          _CyberPanel(
            title: 'Node Palette',
            subtitle: 'Drag new nodes into the tree workspace.',
            child: Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                for (final node in const ['E', 'F', 'G'])
                  Draggable<String>(
                    data: node,
                    feedback: _DragChip(label: node, large: true),
                    childWhenDragging: Opacity(
                      opacity: 0.35,
                      child: _DragChip(label: node),
                    ),
                    child: _DragChip(label: node),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          _CyberPanel(
            title: 'Traversal Console',
            subtitle: 'Animate classic DFS traversal orders.',
            child: Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                _GlowButton(
                  label: 'Inorder',
                  icon: Icons.route_rounded,
                  color: AppColors.cyan,
                  onTap: () => _traverse('Inorder'),
                ),
                _GlowButton(
                  label: 'Preorder',
                  icon: Icons.call_split_rounded,
                  color: AppColors.violet,
                  onTap: () => _traverse('Preorder'),
                ),
                _GlowButton(
                  label: 'Postorder',
                  icon: Icons.device_hub_rounded,
                  color: AppColors.orange,
                  onTap: () => _traverse('Postorder'),
                ),
                _GlowButton(
                  label: 'Break Link',
                  icon: Icons.link_off_rounded,
                  color: AppColors.pink,
                  onTap: _toggleHierarchy,
                ),
                _GlowButton(
                  label: 'Wrong Order',
                  icon: Icons.warning_amber_rounded,
                  color: AppColors.orange,
                  onTap: _toggleTraversalMistake,
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          _FeedbackPanel(message: _feedback, accent: _accent),
          const SizedBox(height: 14),
          const _ExplanationPanel(
            title: 'Binary Tree Concept',
            points: [
              'Each node has at most two children: left and right.',
              'Connections encode hierarchy, not just visual closeness.',
              'Traversal orders must match the selected algorithm.',
            ],
          ),
        ],
      ),
    );
  }
}

class DigitalElectronicsWorkspace extends StatelessWidget {
  const DigitalElectronicsWorkspace({super.key, required this.topicIndex});

  final int topicIndex;

  @override
  Widget build(BuildContext context) {
    return switch (topicIndex) {
      0 => const BasicLogicGatesLab(),
      1 => const XorGateBuilderLab(),
      2 => const ComplexGateConstructionLab(),
      _ => const TruthTableSimulatorLab(),
    };
  }
}

class TruthTableSimulatorLab extends StatefulWidget {
  const TruthTableSimulatorLab({super.key});

  @override
  State<TruthTableSimulatorLab> createState() => _TruthTableSimulatorLabState();
}

class _TruthTableSimulatorLabState extends State<TruthTableSimulatorLab> {
  final List<_GateNode> _gates = [
    _GateNode('AND', const Offset(150, 110)),
    _GateNode('XOR', const Offset(365, 205)),
  ];
  final List<_GateConnection> _connections = [];
  bool _inputA = true;
  bool _inputB = false;
  String _feedback = 'Drag gates onto the holographic board.';
  Color _accent = AppColors.cyan;
  int _nextX = 90;
  int? _selectedGateIndex;

  void _addGate(String type) {
    setState(() {
      _gates.add(_GateNode(type, Offset((_nextX % 450).toDouble(), 290)));
      _nextX += 105;
      _feedback = '$type gate added to circuit board';
      _accent = AppColors.lime;
    });
    _detectCircuit();
  }

  void _toggleGateSelection(int index) {
    setState(() {
      if (_selectedGateIndex == index) {
        _selectedGateIndex = null;
        _feedback = 'Gate selection cleared';
        _accent = AppColors.cyan;
        return;
      }
      _selectedGateIndex = index;
      _feedback = 'Selected ${_gates[index].type} gate for connection';
      _accent = AppColors.violet;
    });
  }

  void _connectGate(int targetIndex) {
    if (_selectedGateIndex == null || _selectedGateIndex == targetIndex) {
      return;
    }
    if (_connections.any(
      (connection) =>
          connection.from == _selectedGateIndex && connection.to == targetIndex,
    )) {
      _setFeedback('Connection already exists', AppColors.orange);
      return;
    }
    setState(() {
      _connections.add(_GateConnection(_selectedGateIndex!, targetIndex));
      _feedback =
          'Connected ${_gates[_selectedGateIndex!].type} → ${_gates[targetIndex].type}';
      _accent = AppColors.lime;
      _selectedGateIndex = null;
    });
    _detectCircuit();
  }

  void _moveGate(int index, Offset delta) {
    setState(() {
      _gates[index] = _gates[index].copyWith(_gates[index].position + delta);
    });
  }

  void _detectCircuit() {
    final hasXor = _gates.any((gate) => gate.type == 'XOR');
    final hasInvalid = _gates.length > 6;
    setState(() {
      if (hasInvalid) {
        _feedback = 'Invalid gate layout detected';
        _accent = AppColors.pink;
      } else if (!hasXor && _gates.length >= 3) {
        _feedback = 'Circuit needs XOR or more stable logic';
        _accent = AppColors.orange;
      } else {
        _feedback = 'Signal propagation is stable';
        _accent = AppColors.lime;
      }
    });
  }

  void _setFeedback(String message, Color color) {
    setState(() {
      _feedback = message;
      _accent = color;
    });
  }

  void _toggleInput(bool first) {
    setState(() {
      if (first) {
        _inputA = !_inputA;
      } else {
        _inputB = !_inputB;
      }
    });
    _detectCircuit();
  }

  bool _eval(String gate, bool a, bool b) {
    return switch (gate) {
      'AND' => a && b,
      'OR' => a || b,
      'NOT' => !a,
      'NAND' => !(a && b),
      'NOR' => !(a || b),
      'XOR' => a != b,
      _ => a == b,
    };
  }

  @override
  Widget build(BuildContext context) {
    final output = _gates.isEmpty
        ? false
        : _eval(_gates.last.type, _inputA, _inputB);

    return _ResponsiveLabShell(
      workspace: _CyberPanel(
        title: 'Logic Gate Circuit Builder',
        subtitle:
            'Drag gates, connect signals, and validate output with a truth table.',
        child: _LogicCircuitBoard(
          gates: _gates,
          inputA: _inputA,
          inputB: _inputB,
          output: output,
          selectedGateIndex: _selectedGateIndex,
          connections: _connections,
          onMoveGate: _moveGate,
          onAcceptGate: _addGate,
          onTapGate: (index) {
            if (_selectedGateIndex == null) {
              _toggleGateSelection(index);
            } else {
              _connectGate(index);
            }
          },
        ),
      ),
      sidePanel: Column(
        children: [
          _CyberPanel(
            title: 'Gate Palette',
            subtitle: 'Drag digital gates. No resistor/capacitor components.',
            child: Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                for (final gate in const [
                  'AND',
                  'OR',
                  'NOT',
                  'NAND',
                  'NOR',
                  'XOR',
                  'XNOR',
                ])
                  Draggable<String>(
                    data: gate,
                    feedback: _GateChip(label: gate, floating: true),
                    childWhenDragging: Opacity(
                      opacity: 0.35,
                      child: _GateChip(label: gate),
                    ),
                    child: _GateChip(label: gate),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          _CyberPanel(
            title: 'Input / Output Simulation',
            subtitle: 'Toggle A/B inputs and compare the selected gate output.',
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: _BinaryToggle(
                        label: 'A',
                        value: _inputA,
                        onTap: () => _toggleInput(true),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _BinaryToggle(
                        label: 'B',
                        value: _inputB,
                        onTap: () => _toggleInput(false),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _BinaryToggle(
                        label: 'OUT',
                        value: output,
                        onTap: () {
                          setState(() {
                            _feedback = 'Truth table output mismatch';
                            _accent = AppColors.orange;
                          });
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                _TruthTable(
                  gate: _gates.isEmpty ? 'XOR' : _gates.last.type,
                  evaluator: _eval,
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          _FeedbackPanel(message: _feedback, accent: _accent),
        ],
      ),
    );
  }
}

class BasicLogicGatesLab extends StatefulWidget {
  const BasicLogicGatesLab({super.key});

  @override
  State<BasicLogicGatesLab> createState() => _BasicLogicGatesLabState();
}

class _BasicLogicGatesLabState extends State<BasicLogicGatesLab> {
  final List<_GateNode> _gates = [];
  final List<_GateConnection> _connections = [];
  bool _inputA = false;
  bool _inputB = false;
  int? _selectedGateIndex;
  String _feedback =
      'Drag AND, OR, and NOT gates onto the board to learn logic basics.';
  Color _accent = AppColors.cyan;
  int _nextX = 90;

  void _addGate(String type) {
    setState(() {
      _gates.add(_GateNode(type, Offset((_nextX % 450).toDouble(), 260)));
      _nextX += 105;
      _feedback = '$type gate added to the learning board.';
      _accent = AppColors.lime;
    });
    _detectCircuit();
  }

  void _toggleGateSelection(int index) {
    setState(() {
      if (_selectedGateIndex == index) {
        _selectedGateIndex = null;
        _feedback = 'Gate selection cleared';
        _accent = AppColors.cyan;
        return;
      }
      _selectedGateIndex = index;
      _feedback = 'Selected ${_gates[index].type} for connection';
      _accent = AppColors.violet;
    });
  }

  void _connectGate(int targetIndex) {
    if (_selectedGateIndex == null || _selectedGateIndex == targetIndex) {
      return;
    }
    if (_connections.any(
      (connection) =>
          connection.from == _selectedGateIndex && connection.to == targetIndex,
    )) {
      _setFeedback('Connection already exists', AppColors.orange);
      return;
    }
    setState(() {
      _connections.add(_GateConnection(_selectedGateIndex!, targetIndex));
      _feedback =
          'Connected ${_gates[_selectedGateIndex!].type} → ${_gates[targetIndex].type}';
      _accent = AppColors.lime;
      _selectedGateIndex = null;
    });
    _detectCircuit();
  }

  void _moveGate(int index, Offset delta) {
    setState(() {
      _gates[index] = _gates[index].copyWith(_gates[index].position + delta);
    });
  }

  void _detectCircuit() {
    if (_gates.isEmpty) {
      _setFeedback(
        'Add basic gates and connect them to start constructing logic.',
        AppColors.cyan,
      );
      return;
    }
    if (_connections.isEmpty) {
      _setFeedback(
        'Connect the gates to complete a logical pathway.',
        AppColors.orange,
      );
      return;
    }
    _setFeedback('Basic gate network is forming correctly.', AppColors.lime);
  }

  void _setFeedback(String message, Color color) {
    setState(() {
      _feedback = message;
      _accent = color;
    });
  }

  bool _eval(String gate, bool a, bool b) {
    return switch (gate) {
      'AND' => a && b,
      'OR' => a || b,
      'NOT' => !a,
      _ => a == b,
    };
  }

  @override
  Widget build(BuildContext context) {
    final output = _gates.isEmpty
        ? false
        : _eval(_gates.last.type, _inputA, _inputB);

    return _ResponsiveLabShell(
      workspace: _CyberPanel(
        title: 'Basic Logic Gates',
        subtitle: 'Learn AND, OR, and NOT by placing and testing each gate.',
        child: _LogicCircuitBoard(
          gates: _gates,
          inputA: _inputA,
          inputB: _inputB,
          output: output,
          selectedGateIndex: _selectedGateIndex,
          connections: _connections,
          onMoveGate: _moveGate,
          onAcceptGate: _addGate,
          onTapGate: (index) {
            if (_selectedGateIndex == null) {
              _toggleGateSelection(index);
            } else {
              _connectGate(index);
            }
          },
        ),
      ),
      sidePanel: Column(
        children: [
          _CyberPanel(
            title: 'Core Gate Palette',
            subtitle:
                'Drag only the basic logic gates to build foundational circuits.',
            child: Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                for (final gate in const ['AND', 'OR', 'NOT'])
                  Draggable<String>(
                    data: gate,
                    feedback: _GateChip(label: gate, floating: true),
                    childWhenDragging: Opacity(
                      opacity: 0.35,
                      child: _GateChip(label: gate),
                    ),
                    child: _GateChip(label: gate),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          _CyberPanel(
            title: 'Signal Play',
            subtitle: 'Toggle inputs and verify the last gate output.',
            child: Row(
              children: [
                Expanded(
                  child: _BinaryToggle(
                    label: 'A',
                    value: _inputA,
                    onTap: () => setState(() => _inputA = !_inputA),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _BinaryToggle(
                    label: 'B',
                    value: _inputB,
                    onTap: () => setState(() => _inputB = !_inputB),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          _FeedbackPanel(message: _feedback, accent: _accent),
        ],
      ),
    );
  }
}

class XorGateBuilderLab extends StatefulWidget {
  const XorGateBuilderLab({super.key});

  @override
  State<XorGateBuilderLab> createState() => _XorGateBuilderLabState();
}

class _XorGateBuilderLabState extends State<XorGateBuilderLab> {
  final List<_GateNode> _gates = [];
  final List<_GateConnection> _connections = [];
  bool _inputA = false;
  bool _inputB = false;
  int? _selectedGateIndex;
  String _feedback =
      'Use AND, OR, and NOT gates to simulate XOR behavior in the board.';
  Color _accent = AppColors.violet;
  int _nextX = 90;

  void _addGate(String type) {
    setState(() {
      _gates.add(_GateNode(type, Offset((_nextX % 450).toDouble(), 260)));
      _nextX += 105;
      _feedback = '$type gate placed for XOR construction.';
      _accent = AppColors.lime;
    });
    _evaluateXorChallenge();
  }

  void _toggleGateSelection(int index) {
    setState(() {
      if (_selectedGateIndex == index) {
        _selectedGateIndex = null;
        _feedback = 'Gate selection cleared';
        _accent = AppColors.cyan;
        return;
      }
      _selectedGateIndex = index;
      _feedback = 'Selected ${_gates[index].type} for connection';
      _accent = AppColors.violet;
    });
  }

  void _connectGate(int targetIndex) {
    if (_selectedGateIndex == null || _selectedGateIndex == targetIndex) {
      return;
    }
    if (_connections.any(
      (connection) =>
          connection.from == _selectedGateIndex && connection.to == targetIndex,
    )) {
      _setFeedback('Connection already exists', AppColors.orange);
      return;
    }
    setState(() {
      _connections.add(_GateConnection(_selectedGateIndex!, targetIndex));
      _feedback =
          'Connected ${_gates[_selectedGateIndex!].type} → ${_gates[targetIndex].type}';
      _accent = AppColors.lime;
      _selectedGateIndex = null;
    });
    _evaluateXorChallenge();
  }

  void _moveGate(int index, Offset delta) {
    setState(() {
      _gates[index] = _gates[index].copyWith(_gates[index].position + delta);
    });
  }

  void _evaluateXorChallenge() {
    final hasAnd = _gates.any((gate) => gate.type == 'AND');
    final hasOr = _gates.any((gate) => gate.type == 'OR');
    final hasNot = _gates.any((gate) => gate.type == 'NOT');
    if (_gates.length >= 3 &&
        _connections.length >= 2 &&
        hasAnd &&
        hasOr &&
        hasNot) {
      _setFeedback(
        'Great! XOR construction is using AND, OR, and NOT properly.',
        AppColors.lime,
      );
      return;
    }
    _setFeedback(
      'Add AND/OR and optionally NOT gates to complete the XOR structure.',
      AppColors.orange,
    );
  }

  void _setFeedback(String message, Color color) {
    setState(() {
      _feedback = message;
      _accent = color;
    });
  }

  bool _eval(String gate, bool a, bool b) {
    return switch (gate) {
      'AND' => a && b,
      'OR' => a || b,
      'NOT' => !a,
      _ => a == b,
    };
  }

  @override
  Widget build(BuildContext context) {
    final output = _gates.isEmpty
        ? false
        : _eval(_gates.last.type, _inputA, _inputB);

    return _ResponsiveLabShell(
      workspace: _CyberPanel(
        title: 'XOR Gate Builder',
        subtitle:
            'Assemble XOR from basic gate primitives and compare behavior.',
        child: _LogicCircuitBoard(
          gates: _gates,
          inputA: _inputA,
          inputB: _inputB,
          output: output,
          selectedGateIndex: _selectedGateIndex,
          connections: _connections,
          onMoveGate: _moveGate,
          onAcceptGate: _addGate,
          onTapGate: (index) {
            if (_selectedGateIndex == null) {
              _toggleGateSelection(index);
            } else {
              _connectGate(index);
            }
          },
        ),
      ),
      sidePanel: Column(
        children: [
          _CyberPanel(
            title: 'XOR Builder Palette',
            subtitle: 'Use basic gates to build the exclusive OR pattern.',
            child: Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                for (final gate in const ['AND', 'OR', 'NOT'])
                  Draggable<String>(
                    data: gate,
                    feedback: _GateChip(label: gate, floating: true),
                    childWhenDragging: Opacity(
                      opacity: 0.35,
                      child: _GateChip(label: gate),
                    ),
                    child: _GateChip(label: gate),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          _CyberPanel(
            title: 'XOR Signal Check',
            subtitle:
                'Toggle inputs to see how the selected gate responds in the output.',
            child: Row(
              children: [
                Expanded(
                  child: _BinaryToggle(
                    label: 'A',
                    value: _inputA,
                    onTap: () => setState(() => _inputA = !_inputA),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _BinaryToggle(
                    label: 'B',
                    value: _inputB,
                    onTap: () => setState(() => _inputB = !_inputB),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          _FeedbackPanel(message: _feedback, accent: _accent),
        ],
      ),
    );
  }
}

class ComplexGateConstructionLab extends StatefulWidget {
  const ComplexGateConstructionLab({super.key});

  @override
  State<ComplexGateConstructionLab> createState() =>
      _ComplexGateConstructionLabState();
}

class _ComplexGateConstructionLabState
    extends State<ComplexGateConstructionLab> {
  final List<_GateNode> _gates = [];
  final List<_GateConnection> _connections = [];
  bool _inputA = false;
  bool _inputB = false;
  int? _selectedGateIndex;
  String _feedback =
      'Place NAND, NOR, and XNOR gates to explore complex digital logic.';
  Color _accent = AppColors.violet;
  int _nextX = 90;

  void _addGate(String type) {
    setState(() {
      _gates.add(_GateNode(type, Offset((_nextX % 450).toDouble(), 260)));
      _nextX += 105;
      _feedback = '$type gate added to the construction board.';
      _accent = AppColors.lime;
    });
    _evaluateComplexConstruction();
  }

  void _toggleGateSelection(int index) {
    setState(() {
      if (_selectedGateIndex == index) {
        _selectedGateIndex = null;
        _feedback = 'Gate selection cleared';
        _accent = AppColors.cyan;
        return;
      }
      _selectedGateIndex = index;
      _feedback = 'Selected ${_gates[index].type} for connection';
      _accent = AppColors.violet;
    });
  }

  void _connectGate(int targetIndex) {
    if (_selectedGateIndex == null || _selectedGateIndex == targetIndex) {
      return;
    }
    if (_connections.any(
      (connection) =>
          connection.from == _selectedGateIndex && connection.to == targetIndex,
    )) {
      _setFeedback('Connection already exists', AppColors.orange);
      return;
    }
    setState(() {
      _connections.add(_GateConnection(_selectedGateIndex!, targetIndex));
      _feedback =
          'Connected ${_gates[_selectedGateIndex!].type} → ${_gates[targetIndex].type}';
      _accent = AppColors.lime;
      _selectedGateIndex = null;
    });
    _evaluateComplexConstruction();
  }

  void _moveGate(int index, Offset delta) {
    setState(() {
      _gates[index] = _gates[index].copyWith(_gates[index].position + delta);
    });
  }

  void _evaluateComplexConstruction() {
    if (_gates.isEmpty) {
      _setFeedback(
        'Add complex gates and connect them to explore NAND/NOR/XNOR.',
        AppColors.cyan,
      );
      return;
    }
    if (_connections.isEmpty) {
      _setFeedback(
        'Connect complex gates to complete the circuit.',
        AppColors.orange,
      );
      return;
    }
    _setFeedback('Complex gate construction is stable.', AppColors.lime);
  }

  void _setFeedback(String message, Color color) {
    setState(() {
      _feedback = message;
      _accent = color;
    });
  }

  bool _eval(String gate, bool a, bool b) {
    return switch (gate) {
      'NAND' => !(a && b),
      'NOR' => !(a || b),
      'XNOR' => a == b,
      _ => a == b,
    };
  }

  @override
  Widget build(BuildContext context) {
    final output = _gates.isEmpty
        ? false
        : _eval(_gates.last.type, _inputA, _inputB);

    return _ResponsiveLabShell(
      workspace: _CyberPanel(
        title: 'Complex Gate Construction',
        subtitle:
            'Build NAND, NOR, and XNOR circuits and observe signal behavior.',
        child: _LogicCircuitBoard(
          gates: _gates,
          inputA: _inputA,
          inputB: _inputB,
          output: output,
          selectedGateIndex: _selectedGateIndex,
          connections: _connections,
          onMoveGate: _moveGate,
          onAcceptGate: _addGate,
          onTapGate: (index) {
            if (_selectedGateIndex == null) {
              _toggleGateSelection(index);
            } else {
              _connectGate(index);
            }
          },
        ),
      ),
      sidePanel: Column(
        children: [
          _CyberPanel(
            title: 'Complex Gate Palette',
            subtitle:
                'Drag the advanced gates and connect them for larger logic.',
            child: Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                for (final gate in const ['NAND', 'NOR', 'XNOR'])
                  Draggable<String>(
                    data: gate,
                    feedback: _GateChip(label: gate, floating: true),
                    childWhenDragging: Opacity(
                      opacity: 0.35,
                      child: _GateChip(label: gate),
                    ),
                    child: _GateChip(label: gate),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          _CyberPanel(
            title: 'Output Simulation',
            subtitle: 'Toggle inputs and verify the behavior of the last gate.',
            child: Row(
              children: [
                Expanded(
                  child: _BinaryToggle(
                    label: 'A',
                    value: _inputA,
                    onTap: () => setState(() => _inputA = !_inputA),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _BinaryToggle(
                    label: 'B',
                    value: _inputB,
                    onTap: () => setState(() => _inputB = !_inputB),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          _FeedbackPanel(message: _feedback, accent: _accent),
        ],
      ),
    );
  }
}

class SugarStructureBuilderLab extends StatefulWidget {
  const SugarStructureBuilderLab({super.key});

  @override
  State<SugarStructureBuilderLab> createState() =>
      _SugarStructureBuilderLabState();
}

class _SugarStructureBuilderLabState extends State<SugarStructureBuilderLab> {
  final List<_AtomNode> _atoms = [
    _AtomNode('C', const Offset(220, 180)),
    _AtomNode('O', const Offset(330, 170)),
    _AtomNode('H', const Offset(140, 240)),
    _AtomNode('H', const Offset(420, 240)),
  ];
  final List<_Bond> _bonds = [_Bond(0, 1, 1), _Bond(0, 2, 1), _Bond(0, 3, 1)];
  int _bondOrder = 1;
  int? _selectedAtomIndex;
  String _feedback =
      'Start building sugar structures. Add C, H, and O atoms with bonds.';
  Color _accent = AppColors.lime;

  void _addAtom(String symbol) {
    setState(() {
      _atoms.add(_AtomNode(symbol, Offset(90.0 + _atoms.length * 34, 300)));
      _feedback = '$symbol atom placed on sugar workspace.';
      _accent = AppColors.lime;
    });
    _detectValency();
  }

  void _moveAtom(int index, Offset delta) {
    setState(() {
      _atoms[index] = _atoms[index].copyWith(_atoms[index].position + delta);
    });
  }

  void _selectAtom(int index) {
    if (_selectedAtomIndex == null) {
      setState(() {
        _selectedAtomIndex = index;
        _feedback = 'Selected ${_atoms[index].symbol} for bonding';
        _accent = AppColors.violet;
      });
      return;
    }
    if (_selectedAtomIndex == index) {
      setState(() {
        _selectedAtomIndex = null;
        _feedback = 'Atom selection cleared';
        _accent = AppColors.cyan;
      });
      return;
    }
    _connectAtom(index);
  }

  void _connectAtom(int targetIndex) {
    if (_selectedAtomIndex == null || _selectedAtomIndex == targetIndex) {
      _setFeedback('Select a different atom to bond', AppColors.orange);
      return;
    }
    final first = _selectedAtomIndex!;
    final second = targetIndex;
    if (_bonds.any(
      (bond) =>
          (bond.a == first && bond.b == second) ||
          (bond.a == second && bond.b == first),
    )) {
      _setFeedback('Bond already exists', AppColors.orange);
      return;
    }
    setState(() {
      _bonds.add(_Bond(first, second, _bondOrder));
      _selectedAtomIndex = null;
      _feedback =
          'Created ${_bondOrder == 1
              ? 'single'
              : _bondOrder == 2
              ? 'double'
              : 'triple'} bond';
      _accent = AppColors.lime;
    });
    _detectValency();
  }

  int _atomMaxValency(String symbol) {
    return switch (symbol) {
      'C' => 4,
      'H' => 1,
      'O' => 2,
      'N' => 3,
      'Cl' => 1,
      _ => 1,
    };
  }

  void _setBondOrder(int order) {
    setState(() {
      _bondOrder = order;
      _feedback = switch (order) {
        1 => 'Single bond mode active',
        2 => 'Double bond mode active',
        _ => 'Triple bond mode active',
      };
      _accent = AppColors.cyan;
    });
  }

  void _loadExample(String name) {
    late List<_AtomNode> atoms;
    late List<_Bond> bonds;
    switch (name) {
      case 'Glucose':
        atoms = [
          _AtomNode('C', const Offset(180, 170)),
          _AtomNode('C', const Offset(260, 170)),
          _AtomNode('O', const Offset(340, 170)),
          _AtomNode('H', const Offset(160, 240)),
          _AtomNode('H', const Offset(300, 240)),
          _AtomNode('H', const Offset(380, 240)),
        ];
        bonds = [
          _Bond(0, 1, 1),
          _Bond(1, 2, 1),
          _Bond(0, 3, 1),
          _Bond(1, 4, 1),
          _Bond(2, 5, 1),
        ];
        break;
      default:
        atoms = [
          _AtomNode('C', const Offset(190, 170)),
          _AtomNode('C', const Offset(310, 170)),
          _AtomNode('O', const Offset(250, 250)),
          _AtomNode('H', const Offset(150, 240)),
          _AtomNode('H', const Offset(370, 240)),
          _AtomNode('H', const Offset(250, 100)),
        ];
        bonds = [
          _Bond(0, 1, 1),
          _Bond(0, 2, 1),
          _Bond(0, 3, 1),
          _Bond(1, 4, 1),
          _Bond(1, 5, 1),
        ];
        break;
    }
    setState(() {
      _atoms
        ..clear()
        ..addAll(atoms);
      _bonds
        ..clear()
        ..addAll(bonds);
      _selectedAtomIndex = null;
      _feedback = '$name structure loaded';
      _accent = AppColors.lime;
    });
  }

  void _detectValency() {
    final valency = <int, int>{};
    for (final bond in _bonds) {
      valency[bond.a] = (valency[bond.a] ?? 0) + bond.order;
      valency[bond.b] = (valency[bond.b] ?? 0) + bond.order;
    }

    var invalid = false;
    var hydrogenMismatch = false;
    for (var index = 0; index < _atoms.length; index++) {
      final atom = _atoms[index];
      final count = valency[index] ?? 0;
      final max = _atomMaxValency(atom.symbol);
      if (count > max) {
        invalid = true;
      }
      if (atom.symbol == 'H' && count != 1) {
        hydrogenMismatch = true;
      }
    }

    setState(() {
      if (invalid) {
        _feedback = 'Invalid valency detected';
        _accent = AppColors.pink;
      } else if (hydrogenMismatch) {
        _feedback = 'Hydrogen count mismatch';
        _accent = AppColors.orange;
      } else {
        _feedback = 'Sugar structure consistency looks stable';
        _accent = AppColors.lime;
      }
    });
  }

  void _setFeedback(String message, Color color) {
    setState(() {
      _feedback = message;
      _accent = color;
    });
  }

  @override
  Widget build(BuildContext context) {
    return _ResponsiveLabShell(
      workspace: _CyberPanel(
        title: 'Sugar Structure Builder',
        subtitle:
            'Build simplified glucose and sucrose arrangements with bonds.',
        child: _MoleculeBoard(
          atoms: _atoms,
          bondOrder: _bondOrder,
          bonds: _bonds,
          selectedAtomIndex: _selectedAtomIndex,
          onMoveAtom: _moveAtom,
          onAcceptAtom: _addAtom,
          onTapAtom: _selectAtom,
        ),
      ),
      sidePanel: Column(
        children: [
          _CyberPanel(
            title: 'Sugar Atom Palette',
            subtitle: 'Use C, H, O to form basic sugar skeletons.',
            child: Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                for (final atom in const ['C', 'H', 'O'])
                  Draggable<String>(
                    data: atom,
                    feedback: _AtomChip(symbol: atom, floating: true),
                    childWhenDragging: Opacity(
                      opacity: 0.35,
                      child: _AtomChip(symbol: atom),
                    ),
                    child: _AtomChip(symbol: atom),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          _CyberPanel(
            title: 'Bond Order Control',
            subtitle: 'Use bond order to model single and double sugar bonds.',
            child: Wrap(
              spacing: 10,
              children: [
                for (final order in [1, 2])
                  _MiniTab(
                    label: order == 1 ? 'Single' : 'Double',
                    selected: _bondOrder == order,
                    onTap: () => _setBondOrder(order),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          _CyberPanel(
            title: 'Example Sugar Shapes',
            subtitle: 'Load example templates to explore common ring patterns.',
            child: Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                for (final name in const ['Glucose', 'Sucrose'])
                  _GlowButton(
                    label: name,
                    icon: Icons.auto_fix_high_rounded,
                    color: AppColors.violet,
                    onTap: () => _loadExample(name),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          _FeedbackPanel(message: _feedback, accent: _accent),
        ],
      ),
    );
  }
}

class AlcoholFunctionalGroupsLab extends StatefulWidget {
  const AlcoholFunctionalGroupsLab({super.key});

  @override
  State<AlcoholFunctionalGroupsLab> createState() =>
      _AlcoholFunctionalGroupsLabState();
}

class _AlcoholFunctionalGroupsLabState
    extends State<AlcoholFunctionalGroupsLab> {
  final List<_AtomNode> _atoms = [
    _AtomNode('C', const Offset(220, 180)),
    _AtomNode('O', const Offset(330, 180)),
    _AtomNode('H', const Offset(140, 250)),
    _AtomNode('N', const Offset(420, 250)),
  ];
  final List<_Bond> _bonds = [_Bond(0, 1, 1), _Bond(0, 2, 1), _Bond(1, 3, 1)];
  int _bondOrder = 1;
  int? _selectedAtomIndex;
  String _feedback =
      'Build alcohols and functional groups by bonding OH and N attachments.';
  Color _accent = AppColors.cyan;

  void _addAtom(String symbol) {
    setState(() {
      _atoms.add(_AtomNode(symbol, Offset(90.0 + _atoms.length * 34, 300)));
      _feedback = '$symbol atom added for functional-group construction.';
      _accent = AppColors.lime;
    });
    _detectValency();
  }

  void _moveAtom(int index, Offset delta) {
    setState(() {
      _atoms[index] = _atoms[index].copyWith(_atoms[index].position + delta);
    });
  }

  void _selectAtom(int index) {
    if (_selectedAtomIndex == null) {
      setState(() {
        _selectedAtomIndex = index;
        _feedback = 'Selected ${_atoms[index].symbol} for bonding';
        _accent = AppColors.violet;
      });
      return;
    }
    if (_selectedAtomIndex == index) {
      setState(() {
        _selectedAtomIndex = null;
        _feedback = 'Atom selection cleared';
        _accent = AppColors.cyan;
      });
      return;
    }
    _connectAtom(index);
  }

  void _connectAtom(int targetIndex) {
    if (_selectedAtomIndex == null || _selectedAtomIndex == targetIndex) {
      _setFeedback('Select a different atom to bond', AppColors.orange);
      return;
    }
    final first = _selectedAtomIndex!;
    final second = targetIndex;
    if (_bonds.any(
      (bond) =>
          (bond.a == first && bond.b == second) ||
          (bond.a == second && bond.b == first),
    )) {
      _setFeedback('Bond already exists', AppColors.orange);
      return;
    }
    setState(() {
      _bonds.add(_Bond(first, second, _bondOrder));
      _selectedAtomIndex = null;
      _feedback =
          'Created ${_bondOrder == 1
              ? 'single'
              : _bondOrder == 2
              ? 'double'
              : 'triple'} bond';
      _accent = AppColors.lime;
    });
    _detectValency();
  }

  int _atomMaxValency(String symbol) {
    return switch (symbol) {
      'C' => 4,
      'H' => 1,
      'O' => 2,
      'N' => 3,
      'Cl' => 1,
      _ => 1,
    };
  }

  void _setBondOrder(int order) {
    setState(() {
      _bondOrder = order;
      _feedback = switch (order) {
        1 => 'Single bond mode active',
        2 => 'Double bond mode active',
        _ => 'Triple bond mode active',
      };
      _accent = AppColors.cyan;
    });
  }

  void _loadExample(String name) {
    late List<_AtomNode> atoms;
    late List<_Bond> bonds;
    switch (name) {
      case 'Ethanol':
        atoms = [
          _AtomNode('C', const Offset(200, 180)),
          _AtomNode('C', const Offset(300, 180)),
          _AtomNode('O', const Offset(380, 180)),
          _AtomNode('H', const Offset(150, 240)),
          _AtomNode('H', const Offset(240, 240)),
          _AtomNode('H', const Offset(340, 240)),
        ];
        bonds = [
          _Bond(0, 1, 1),
          _Bond(1, 2, 1),
          _Bond(0, 3, 1),
          _Bond(0, 4, 1),
          _Bond(1, 5, 1),
        ];
        break;
      default:
        atoms = [
          _AtomNode('C', const Offset(220, 180)),
          _AtomNode('N', const Offset(320, 180)),
          _AtomNode('H', const Offset(170, 240)),
          _AtomNode('H', const Offset(370, 240)),
          _AtomNode('H', const Offset(250, 260)),
        ];
        bonds = [
          _Bond(0, 1, 1),
          _Bond(0, 2, 1),
          _Bond(0, 3, 1),
          _Bond(1, 4, 1),
        ];
        break;
    }
    setState(() {
      _atoms
        ..clear()
        ..addAll(atoms);
      _bonds
        ..clear()
        ..addAll(bonds);
      _selectedAtomIndex = null;
      _feedback = '$name structure loaded';
      _accent = AppColors.lime;
    });
  }

  void _detectValency() {
    final valency = <int, int>{};
    for (final bond in _bonds) {
      valency[bond.a] = (valency[bond.a] ?? 0) + bond.order;
      valency[bond.b] = (valency[bond.b] ?? 0) + bond.order;
    }

    var invalid = false;
    var hydrogenMismatch = false;
    for (var index = 0; index < _atoms.length; index++) {
      final atom = _atoms[index];
      final count = valency[index] ?? 0;
      final max = _atomMaxValency(atom.symbol);
      if (count > max) {
        invalid = true;
      }
      if (atom.symbol == 'H' && count != 1) {
        hydrogenMismatch = true;
      }
    }

    setState(() {
      if (invalid) {
        _feedback = 'Invalid valency detected';
        _accent = AppColors.pink;
      } else if (hydrogenMismatch) {
        _feedback = 'Hydrogen count mismatch';
        _accent = AppColors.orange;
      } else {
        _feedback = 'Functional-group structure looks consistent';
        _accent = AppColors.lime;
      }
    });
  }

  void _setFeedback(String message, Color color) {
    setState(() {
      _feedback = message;
      _accent = color;
    });
  }

  @override
  Widget build(BuildContext context) {
    return _ResponsiveLabShell(
      workspace: _CyberPanel(
        title: 'Alcohol & Functional Groups',
        subtitle: 'Build OH and N attachments on carbon structures.',
        child: _MoleculeBoard(
          atoms: _atoms,
          bondOrder: _bondOrder,
          bonds: _bonds,
          selectedAtomIndex: _selectedAtomIndex,
          onMoveAtom: _moveAtom,
          onAcceptAtom: _addAtom,
          onTapAtom: _selectAtom,
        ),
      ),
      sidePanel: Column(
        children: [
          _CyberPanel(
            title: 'Functional Atom Palette',
            subtitle: 'Use C, H, O, N to create alcohols and amines.',
            child: Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                for (final atom in const ['C', 'H', 'O', 'N'])
                  Draggable<String>(
                    data: atom,
                    feedback: _AtomChip(symbol: atom, floating: true),
                    childWhenDragging: Opacity(
                      opacity: 0.35,
                      child: _AtomChip(symbol: atom),
                    ),
                    child: _AtomChip(symbol: atom),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          _CyberPanel(
            title: 'Bond Order Control',
            subtitle: 'Use bond order to model alcohol and amine bonds.',
            child: Wrap(
              spacing: 10,
              children: [
                for (final order in [1, 2, 3])
                  _MiniTab(
                    label: order == 1
                        ? 'Single'
                        : order == 2
                        ? 'Double'
                        : 'Triple',
                    selected: _bondOrder == order,
                    onTap: () => _setBondOrder(order),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          _CyberPanel(
            title: 'Example Functional Groups',
            subtitle: 'Load sample alcohol or amine structures quickly.',
            child: Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                _GlowButton(
                  label: 'Ethanol',
                  icon: Icons.auto_fix_high_rounded,
                  color: AppColors.violet,
                  onTap: () => _loadExample('Ethanol'),
                ),
                _GlowButton(
                  label: 'Amine',
                  icon: Icons.auto_fix_high_rounded,
                  color: AppColors.violet,
                  onTap: () => _loadExample('Amine'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          _FeedbackPanel(message: _feedback, accent: _accent),
        ],
      ),
    );
  }
}

class BondSimulatorLab extends StatefulWidget {
  const BondSimulatorLab({super.key});

  @override
  State<BondSimulatorLab> createState() => _BondSimulatorLabState();
}

class _BondSimulatorLabState extends State<BondSimulatorLab> {
  final List<_AtomNode> _atoms = [
    _AtomNode('C', const Offset(230, 180)),
    _AtomNode('C', const Offset(330, 180)),
    _AtomNode('H', const Offset(180, 250)),
    _AtomNode('H', const Offset(380, 250)),
  ];
  final List<_Bond> _bonds = [_Bond(0, 2, 1), _Bond(1, 3, 1)];
  int _bondOrder = 1;
  int? _selectedAtomIndex;
  String _feedback =
      'Explore single, double, and triple bonds by bonding atoms on the board.';
  Color _accent = AppColors.cyan;

  void _addAtom(String symbol) {
    setState(() {
      _atoms.add(_AtomNode(symbol, Offset(90.0 + _atoms.length * 34, 300)));
      _feedback = '$symbol atom added to the bond simulator.';
      _accent = AppColors.lime;
    });
    _detectValency();
  }

  void _moveAtom(int index, Offset delta) {
    setState(() {
      _atoms[index] = _atoms[index].copyWith(_atoms[index].position + delta);
    });
  }

  void _selectAtom(int index) {
    if (_selectedAtomIndex == null) {
      setState(() {
        _selectedAtomIndex = index;
        _feedback = 'Selected ${_atoms[index].symbol} for bonding';
        _accent = AppColors.violet;
      });
      return;
    }
    if (_selectedAtomIndex == index) {
      setState(() {
        _selectedAtomIndex = null;
        _feedback = 'Atom selection cleared';
        _accent = AppColors.cyan;
      });
      return;
    }
    _connectAtom(index);
  }

  void _connectAtom(int targetIndex) {
    if (_selectedAtomIndex == null || _selectedAtomIndex == targetIndex) {
      _setFeedback('Select a different atom to bond', AppColors.orange);
      return;
    }
    final first = _selectedAtomIndex!;
    final second = targetIndex;
    if (_bonds.any(
      (bond) =>
          (bond.a == first && bond.b == second) ||
          (bond.a == second && bond.b == first),
    )) {
      _setFeedback('Bond already exists', AppColors.orange);
      return;
    }
    setState(() {
      _bonds.add(_Bond(first, second, _bondOrder));
      _selectedAtomIndex = null;
      _feedback =
          'Created ${_bondOrder == 1
              ? 'single'
              : _bondOrder == 2
              ? 'double'
              : 'triple'} bond';
      _accent = AppColors.lime;
    });
    _detectValency();
  }

  int _atomMaxValency(String symbol) {
    return switch (symbol) {
      'C' => 4,
      'H' => 1,
      'O' => 2,
      'N' => 3,
      'Cl' => 1,
      _ => 1,
    };
  }

  void _setBondOrder(int order) {
    setState(() {
      _bondOrder = order;
      _feedback = switch (order) {
        1 => 'Single bond mode active',
        2 => 'Double bond mode active',
        _ => 'Triple bond mode active',
      };
      _accent = AppColors.cyan;
    });
  }

  void _detectValency() {
    final valency = <int, int>{};
    for (final bond in _bonds) {
      valency[bond.a] = (valency[bond.a] ?? 0) + bond.order;
      valency[bond.b] = (valency[bond.b] ?? 0) + bond.order;
    }

    var invalid = false;
    var hydrogenMismatch = false;
    for (var index = 0; index < _atoms.length; index++) {
      final atom = _atoms[index];
      final count = valency[index] ?? 0;
      final max = _atomMaxValency(atom.symbol);
      if (count > max) {
        invalid = true;
      }
      if (atom.symbol == 'H' && count != 1) {
        hydrogenMismatch = true;
      }
    }

    setState(() {
      if (invalid) {
        _feedback = 'Invalid valency detected';
        _accent = AppColors.pink;
      } else if (hydrogenMismatch) {
        _feedback = 'Hydrogen count mismatch';
        _accent = AppColors.orange;
      } else {
        _feedback = 'Bond structure looks balanced.';
        _accent = AppColors.lime;
      }
    });
  }

  void _setFeedback(String message, Color color) {
    setState(() {
      _feedback = message;
      _accent = color;
    });
  }

  @override
  Widget build(BuildContext context) {
    return _ResponsiveLabShell(
      workspace: _CyberPanel(
        title: 'Bond Simulator',
        subtitle:
            'Explore single, double, and triple bond structures interactively.',
        child: _MoleculeBoard(
          atoms: _atoms,
          bondOrder: _bondOrder,
          bonds: _bonds,
          selectedAtomIndex: _selectedAtomIndex,
          onMoveAtom: _moveAtom,
          onAcceptAtom: _addAtom,
          onTapAtom: _selectAtom,
        ),
      ),
      sidePanel: Column(
        children: [
          _CyberPanel(
            title: 'Atom Palette',
            subtitle: 'Drag atoms into the board and choose bond order.',
            child: Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                for (final atom in const ['C', 'H', 'O', 'N', 'Cl'])
                  Draggable<String>(
                    data: atom,
                    feedback: _AtomChip(symbol: atom, floating: true),
                    childWhenDragging: Opacity(
                      opacity: 0.35,
                      child: _AtomChip(symbol: atom),
                    ),
                    child: _AtomChip(symbol: atom),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          _CyberPanel(
            title: 'Bond Order',
            subtitle: 'Switch between single, double, and triple bonds.',
            child: Wrap(
              spacing: 10,
              children: [
                for (final order in [1, 2, 3])
                  _MiniTab(
                    label: order == 1
                        ? 'Single'
                        : order == 2
                        ? 'Double'
                        : 'Triple',
                    selected: _bondOrder == order,
                    onTap: () => _setBondOrder(order),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          _FeedbackPanel(message: _feedback, accent: _accent),
        ],
      ),
    );
  }
}

class OrganicChemistryWorkspace extends StatelessWidget {
  const OrganicChemistryWorkspace({super.key, required this.topicIndex});

  final int topicIndex;

  @override
  Widget build(BuildContext context) {
    return switch (topicIndex) {
      0 => const HydrocarbonBuilderLab(),
      1 => const SugarStructureBuilderLab(),
      2 => const AlcoholFunctionalGroupsLab(),
      _ => const BondSimulatorLab(),
    };
  }
}

class HydrocarbonBuilderLab extends StatefulWidget {
  const HydrocarbonBuilderLab({super.key});

  @override
  State<HydrocarbonBuilderLab> createState() => _HydrocarbonBuilderLabState();
}

class _HydrocarbonBuilderLabState extends State<HydrocarbonBuilderLab> {
  final List<_AtomNode> _atoms = [
    _AtomNode('C', const Offset(260, 200)),
    _AtomNode('H', const Offset(260, 80)),
    _AtomNode('H', const Offset(180, 220)),
    _AtomNode('H', const Offset(340, 220)),
    _AtomNode('H', const Offset(260, 320)),
  ];
  final List<_Bond> _bonds = [
    _Bond(0, 1, 1),
    _Bond(0, 2, 1),
    _Bond(0, 3, 1),
    _Bond(0, 4, 1),
  ];
  int _bondOrder = 1;
  int? _selectedAtomIndex;
  String _feedback =
      'Drag atoms into place and connect bonds to build stable molecules.';
  Color _accent = AppColors.cyan;

  void _addAtom(String symbol) {
    setState(() {
      _atoms.add(_AtomNode(symbol, Offset(90.0 + _atoms.length * 38, 315)));
      _feedback = '$symbol atom placed on molecule workspace';
      _accent = AppColors.lime;
    });
    _detectValency();
  }

  void _moveAtom(int index, Offset delta) {
    setState(() {
      _atoms[index] = _atoms[index].copyWith(_atoms[index].position + delta);
    });
  }

  void _selectAtom(int index) {
    if (_selectedAtomIndex == null) {
      setState(() {
        _selectedAtomIndex = index;
        _feedback = 'Selected ${_atoms[index].symbol} for bonding';
        _accent = AppColors.violet;
      });
      return;
    }
    if (_selectedAtomIndex == index) {
      setState(() {
        _selectedAtomIndex = null;
        _feedback = 'Atom selection cleared';
        _accent = AppColors.cyan;
      });
      return;
    }
    _connectAtom(index);
  }

  void _connectAtom(int targetIndex) {
    if (_selectedAtomIndex == null || _selectedAtomIndex == targetIndex) {
      _setFeedback('Select a different atom to bond', AppColors.orange);
      return;
    }
    final first = _selectedAtomIndex!;
    final second = targetIndex;
    if (_bonds.any(
      (bond) =>
          (bond.a == first && bond.b == second) ||
          (bond.a == second && bond.b == first),
    )) {
      _setFeedback('Bond already exists', AppColors.orange);
      return;
    }
    setState(() {
      _bonds.add(_Bond(first, second, _bondOrder));
      _selectedAtomIndex = null;
      _feedback =
          'Created ${_bondOrder == 1
              ? 'single'
              : _bondOrder == 2
              ? 'double'
              : 'triple'} bond';
      _accent = AppColors.lime;
    });
    _detectValency();
  }

  int _atomMaxValency(String symbol) {
    return switch (symbol) {
      'C' => 4,
      'H' => 1,
      'O' => 2,
      'N' => 3,
      'Cl' => 1,
      _ => 1,
    };
  }

  void _setBondOrder(int order) {
    setState(() {
      _bondOrder = order;
      _feedback = switch (order) {
        1 => 'Single bond mode active',
        2 => 'Double bond mode active',
        _ => 'Triple bond mode active',
      };
      _accent = AppColors.cyan;
    });
  }

  void _loadExample(String name) {
    late List<_AtomNode> atoms;
    late List<_Bond> bonds;
    switch (name) {
      case 'Methane':
        atoms = [
          _AtomNode('C', const Offset(260, 200)),
          _AtomNode('H', const Offset(260, 82)),
          _AtomNode('H', const Offset(140, 200)),
          _AtomNode('H', const Offset(380, 200)),
          _AtomNode('H', const Offset(260, 320)),
        ];
        bonds = [
          _Bond(0, 1, 1),
          _Bond(0, 2, 1),
          _Bond(0, 3, 1),
          _Bond(0, 4, 1),
        ];
        break;
      case 'Ethene':
        atoms = [
          _AtomNode('C', const Offset(210, 205)),
          _AtomNode('C', const Offset(330, 205)),
          _AtomNode('H', const Offset(148, 105)),
          _AtomNode('H', const Offset(148, 305)),
          _AtomNode('H', const Offset(392, 105)),
          _AtomNode('H', const Offset(392, 305)),
        ];
        bonds = [
          _Bond(0, 1, 2),
          _Bond(0, 2, 1),
          _Bond(0, 3, 1),
          _Bond(1, 4, 1),
          _Bond(1, 5, 1),
        ];
        break;
      case 'Ethyne':
        atoms = [
          _AtomNode('C', const Offset(210, 205)),
          _AtomNode('C', const Offset(330, 205)),
          _AtomNode('H', const Offset(132, 94)),
          _AtomNode('H', const Offset(132, 316)),
          _AtomNode('H', const Offset(388, 94)),
          _AtomNode('H', const Offset(388, 316)),
        ];
        bonds = [
          _Bond(0, 1, 3),
          _Bond(0, 2, 1),
          _Bond(0, 3, 1),
          _Bond(1, 4, 1),
          _Bond(1, 5, 1),
        ];
        break;
      default:
        atoms = [
          _AtomNode('C', const Offset(180, 205)),
          _AtomNode('C', const Offset(302, 205)),
          _AtomNode('O', const Offset(424, 205)),
          _AtomNode('H', const Offset(500, 138)),
          _AtomNode('H', const Offset(118, 126)),
          _AtomNode('H', const Offset(118, 284)),
        ];
        bonds = [
          _Bond(0, 1, 1),
          _Bond(1, 2, 1),
          _Bond(1, 4, 1),
          _Bond(1, 5, 1),
          _Bond(2, 3, 1),
        ];
        break;
    }
    setState(() {
      _atoms
        ..clear()
        ..addAll(atoms);
      _bonds
        ..clear()
        ..addAll(bonds);
      _selectedAtomIndex = null;
      _feedback = '$name structure loaded';
      _accent = AppColors.lime;
    });
  }

  void _detectValency() {
    final valency = <int, int>{};
    for (final bond in _bonds) {
      valency[bond.a] = (valency[bond.a] ?? 0) + bond.order;
      valency[bond.b] = (valency[bond.b] ?? 0) + bond.order;
    }

    var invalid = false;
    var hydrogenMismatch = false;
    for (var index = 0; index < _atoms.length; index++) {
      final atom = _atoms[index];
      final count = valency[index] ?? 0;
      final max = _atomMaxValency(atom.symbol);
      if (count > max) {
        invalid = true;
      }
      if (atom.symbol == 'H' && count != 1) {
        hydrogenMismatch = true;
      }
    }

    setState(() {
      if (invalid) {
        _feedback = 'Invalid valency detected';
        _accent = AppColors.pink;
      } else if (hydrogenMismatch) {
        _feedback = 'Hydrogen count mismatch';
        _accent = AppColors.orange;
      } else {
        _feedback = 'Organic structure consistency looks stable';
        _accent = AppColors.lime;
      }
    });
  }

  void _setFeedback(String message, Color color) {
    setState(() {
      _feedback = message;
      _accent = color;
    });
  }

  @override
  Widget build(BuildContext context) {
    return _ResponsiveLabShell(
      workspace: _CyberPanel(
        title: 'Molecular Bond Builder',
        subtitle:
            'Arrange atoms, choose bond order, and balance organic valency.',
        child: _MoleculeBoard(
          atoms: _atoms,
          bondOrder: _bondOrder,
          bonds: _bonds,
          selectedAtomIndex: _selectedAtomIndex,
          onMoveAtom: _moveAtom,
          onAcceptAtom: _addAtom,
          onTapAtom: _selectAtom,
        ),
      ),
      sidePanel: Column(
        children: [
          _CyberPanel(
            title: 'Atom Palette',
            subtitle: 'Drag atoms into the workspace and adjust bond order.',
            child: Column(
              children: [
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: [
                    for (final atom in const ['C', 'H', 'O', 'N', 'Cl'])
                      Draggable<String>(
                        data: atom,
                        feedback: _AtomChip(symbol: atom, floating: true),
                        childWhenDragging: Opacity(
                          opacity: 0.35,
                          child: _AtomChip(symbol: atom),
                        ),
                        child: _AtomChip(symbol: atom),
                      ),
                  ],
                ),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 10,
                  children: [
                    for (final order in [1, 2, 3])
                      _MiniTab(
                        label:
                            '${order == 1
                                ? 'Single'
                                : order == 2
                                ? 'Double'
                                : 'Triple'} Bond',
                        selected: _bondOrder == order,
                        onTap: () => _setBondOrder(order),
                      ),
                  ],
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        _selectedAtomIndex == null
                            ? 'Selected atom: none'
                            : 'Selected atom: ${_atoms[_selectedAtomIndex!].symbol}',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ),
                    _GlowButton(
                      label: 'BOND',
                      icon: Icons.link_rounded,
                      color: AppColors.lime,
                      onTap: () {
                        if (_selectedAtomIndex == null) {
                          _setFeedback(
                            'Select an atom first before bonding',
                            AppColors.orange,
                          );
                        }
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          _CyberPanel(
            title: 'Example Structures',
            subtitle: 'Load quick demos to explore stable organic molecules.',
            child: Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                for (final name in const [
                  'Methane',
                  'Ethene',
                  'Ethyne',
                  'Alcohol',
                ])
                  _GlowButton(
                    label: name,
                    icon: Icons.auto_fix_high_rounded,
                    color: AppColors.violet,
                    onTap: () => _loadExample(name),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          _FeedbackPanel(message: _feedback, accent: _accent),
          const SizedBox(height: 14),
          const _ExplanationPanel(
            title: 'Organic Structure Rules',
            points: [
              'Carbon normally forms four bonds in stable organic structures.',
              'Hydrogen forms one bond; oxygen commonly forms two.',
              'Double and triple bonds increase bond order and reduce available valency.',
            ],
          ),
        ],
      ),
    );
  }
}

class _StackBoard extends StatelessWidget {
  const _StackBoard({
    required this.items,
    required this.capacity,
    required this.activeIndex,
    required this.topMismatch,
    required this.onAccept,
  });

  final List<String> items;
  final int capacity;
  final int activeIndex;
  final bool topMismatch;
  final ValueChanged<String> onAccept;

  @override
  Widget build(BuildContext context) {
    return DragTarget<String>(
      onAcceptWithDetails: (details) => onAccept(details.data),
      builder: (context, candidate, rejected) {
        return SizedBox(
          height: 430,
          child: Stack(
            children: [
              const Positioned.fill(child: _NeonGrid()),
              Center(
                child: Container(
                  width: 230,
                  height: 355,
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: AppColors.cyan.withValues(alpha: 0.5),
                      width: 2,
                    ),
                    borderRadius: BorderRadius.circular(18),
                    gradient: LinearGradient(
                      colors: [
                        AppColors.cyan.withValues(alpha: 0.04),
                        AppColors.violet.withValues(alpha: 0.12),
                      ],
                    ),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      for (var i = capacity - 1; i >= 0; i--)
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 320),
                          curve: Curves.easeOutBack,
                          margin: const EdgeInsets.symmetric(
                            horizontal: 18,
                            vertical: 5,
                          ),
                          height: 54,
                          decoration: BoxDecoration(
                            color: i < items.length
                                ? AppColors.cyan.withValues(alpha: 0.18)
                                : Colors.white.withValues(alpha: 0.035),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: i == activeIndex
                                  ? AppColors.lime
                                  : AppColors.cyan.withValues(alpha: 0.24),
                            ),
                            boxShadow: i < items.length
                                ? [
                                    BoxShadow(
                                      color: AppColors.cyan.withValues(
                                        alpha: 0.22,
                                      ),
                                      blurRadius: 18,
                                    ),
                                  ]
                                : null,
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            i < items.length ? items[i] : 'empty',
                            style: TextStyle(
                              color: i < items.length
                                  ? AppColors.textPrimary
                                  : AppColors.textSecondary,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              AnimatedPositioned(
                duration: const Duration(milliseconds: 300),
                right: 36,
                top: topMismatch
                    ? 92
                    : 330 - math.max(0, items.length - 1) * 64,
                child: _PointerLabel(
                  label: 'TOP',
                  color: topMismatch ? AppColors.orange : AppColors.lime,
                ),
              ),
              Positioned(
                left: 24,
                bottom: 22,
                child: Text(
                  candidate.isEmpty
                      ? 'Drop draggable values here'
                      : 'Release to PUSH',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _TreeBoard extends StatelessWidget {
  const _TreeBoard({
    required this.nodes,
    required this.active,
    required this.badHierarchy,
    required this.onMove,
    required this.onAccept,
  });

  final List<_TreeNode> nodes;
  final String active;
  final bool badHierarchy;
  final void Function(String label, Offset delta) onMove;
  final ValueChanged<String> onAccept;

  @override
  Widget build(BuildContext context) {
    return DragTarget<String>(
      onAcceptWithDetails: (details) => onAccept(details.data),
      builder: (context, candidate, rejected) {
        return SizedBox(
          height: 430,
          child: Stack(
            children: [
              const Positioned.fill(child: _NeonGrid()),
              Positioned.fill(
                child: CustomPaint(
                  painter: _TreePainter(nodes, active, badHierarchy),
                ),
              ),
              for (final node in nodes)
                Positioned(
                  left: node.position.dx,
                  top: node.position.dy,
                  child: GestureDetector(
                    onPanUpdate: (details) => onMove(node.label, details.delta),
                    child: _TreeNodeBubble(
                      label: node.label,
                      active: node.label == active,
                      warning: badHierarchy && node.label == 'C',
                    ),
                  ),
                ),
              Positioned(
                left: 24,
                bottom: 18,
                child: Text(
                  candidate.isEmpty
                      ? 'Drop node chips onto the tree board'
                      : 'Release to place node',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _LogicCircuitBoard extends StatefulWidget {
  const _LogicCircuitBoard({
    required this.gates,
    required this.inputA,
    required this.inputB,
    required this.output,
    required this.selectedGateIndex,
    required this.connections,
    required this.onMoveGate,
    required this.onAcceptGate,
    required this.onTapGate,
  });

  final List<_GateNode> gates;
  final bool inputA;
  final bool inputB;
  final bool output;
  final int? selectedGateIndex;
  final List<_GateConnection> connections;
  final void Function(int index, Offset delta) onMoveGate;
  final ValueChanged<String> onAcceptGate;
  final ValueChanged<int> onTapGate;

  @override
  State<_LogicCircuitBoard> createState() => _LogicCircuitBoardState();
}

class _LogicCircuitBoardState extends State<_LogicCircuitBoard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return DragTarget<String>(
      onAcceptWithDetails: (details) => widget.onAcceptGate(details.data),
      builder: (context, candidate, rejected) {
        return SizedBox(
          height: 430,
          child: AnimatedBuilder(
            animation: _controller,
            builder: (context, child) {
              return Stack(
                children: [
                  const Positioned.fill(child: _NeonGrid()),
                  Positioned.fill(
                    child: CustomPaint(
                      painter: _CircuitPainter(
                        gates: widget.gates,
                        progress: _controller.value,
                        inputA: widget.inputA,
                        inputB: widget.inputB,
                        output: widget.output,
                        connections: widget.connections,
                      ),
                    ),
                  ),
                  Positioned(
                    left: 18,
                    top: 78,
                    child: _SignalPad(label: 'A', active: widget.inputA),
                  ),
                  Positioned(
                    left: 18,
                    top: 238,
                    child: _SignalPad(label: 'B', active: widget.inputB),
                  ),
                  Positioned(
                    right: 22,
                    top: 176,
                    child: _SignalPad(label: 'OUT', active: widget.output),
                  ),
                  for (var i = 0; i < widget.gates.length; i++)
                    Positioned(
                      left: widget.gates[i].position.dx,
                      top: widget.gates[i].position.dy,
                      child: GestureDetector(
                        onPanUpdate: (details) =>
                            widget.onMoveGate(i, details.delta),
                        onTap: () => widget.onTapGate(i),
                        child: _GateNodeWidget(
                          label: widget.gates[i].type,
                          selected: widget.selectedGateIndex == i,
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
        );
      },
    );
  }
}

class _MoleculeBoard extends StatefulWidget {
  const _MoleculeBoard({
    required this.atoms,
    required this.bondOrder,
    required this.bonds,
    required this.selectedAtomIndex,
    required this.onMoveAtom,
    required this.onAcceptAtom,
    required this.onTapAtom,
  });

  final List<_AtomNode> atoms;
  final int bondOrder;
  final List<_Bond> bonds;
  final int? selectedAtomIndex;
  final void Function(int index, Offset delta) onMoveAtom;
  final ValueChanged<String> onAcceptAtom;
  final ValueChanged<int> onTapAtom;

  @override
  State<_MoleculeBoard> createState() => _MoleculeBoardState();
}

class _MoleculeBoardState extends State<_MoleculeBoard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return DragTarget<String>(
      onAcceptWithDetails: (details) => widget.onAcceptAtom(details.data),
      builder: (context, candidate, rejected) {
        return SizedBox(
          height: 430,
          child: AnimatedBuilder(
            animation: _controller,
            builder: (context, child) {
              return Stack(
                children: [
                  const Positioned.fill(child: _NeonGrid()),
                  Positioned.fill(
                    child: CustomPaint(
                      painter: _MoleculePainter(
                        atoms: widget.atoms,
                        bonds: widget.bonds,
                        progress: _controller.value,
                      ),
                    ),
                  ),
                  for (var i = 0; i < widget.atoms.length; i++)
                    Positioned(
                      left: widget.atoms[i].position.dx,
                      top: widget.atoms[i].position.dy,
                      child: GestureDetector(
                        onPanUpdate: (details) =>
                            widget.onMoveAtom(i, details.delta),
                        onTap: () => widget.onTapAtom(i),
                        child: _AtomBubble(
                          symbol: widget.atoms[i].symbol,
                          selected: widget.selectedAtomIndex == i,
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
        );
      },
    );
  }
}

class _TruthTable extends StatelessWidget {
  const _TruthTable({required this.gate, required this.evaluator});

  final String gate;
  final bool Function(String gate, bool a, bool b) evaluator;

  @override
  Widget build(BuildContext context) {
    final rows = [
      [false, false],
      [false, true],
      [true, false],
      [true, true],
    ];

    return Column(
      children: [
        _TruthRow(a: 'A', b: 'B', out: gate, header: true),
        for (final row in rows)
          _TruthRow(
            a: row[0] ? '1' : '0',
            b: row[1] ? '1' : '0',
            out: evaluator(gate, row[0], row[1]) ? '1' : '0',
          ),
      ],
    );
  }
}

class _ResponsiveLabShell extends StatelessWidget {
  const _ResponsiveLabShell({required this.workspace, required this.sidePanel});

  final Widget workspace;
  final Widget sidePanel;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth >= 980;
        if (!isWide) {
          return Column(
            children: [workspace, const SizedBox(height: 16), sidePanel],
          );
        }
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(flex: 7, child: workspace),
            const SizedBox(width: 18),
            Expanded(flex: 4, child: sidePanel),
          ],
        );
      },
    );
  }
}

class _LinkedListLearningLab extends StatefulWidget {
  const _LinkedListLearningLab();

  @override
  State<_LinkedListLearningLab> createState() => _LinkedListLearningLabState();
}

class _LinkedListLearningLabState extends State<_LinkedListLearningLab> {
  final List<_LinkedListNode> _nodes = [
    _LinkedListNode('A', const Offset(130, 220)),
    _LinkedListNode('B', const Offset(280, 220)),
    _LinkedListNode('C', const Offset(430, 220)),
  ];
  String _feedback = 'Drag node chips onto the list board to build the chain.';
  Color _accent = AppColors.cyan;
  bool _brokenLink = false;

  void _addNode(String label) {
    if (_nodes.any((node) => node.label == label)) {
      _setFeedback('Node $label already exists in the list', AppColors.orange);
      return;
    }
    setState(() {
      _nodes.add(
        _LinkedListNode(label, Offset(130.0 + _nodes.length * 150, 220)),
      );
      _brokenLink = false;
    });
    _setFeedback('Node $label added. Connect it to the tail.', AppColors.lime);
  }

  void _removeHead() {
    if (_nodes.isEmpty) {
      _setFeedback('Invalid remove operation: list is empty', AppColors.pink);
      return;
    }
    setState(() {
      final removed = _nodes.removeAt(0);
      _brokenLink = false;
      _feedback =
          'Removed head node ${removed.label}. New head is ${_nodes.isEmpty ? 'NULL' : _nodes.first.label}.';
      _accent = AppColors.lime;
    });
  }

  void _toggleBrokenLink() {
    setState(() {
      _brokenLink = !_brokenLink;
      _feedback = _brokenLink
          ? 'Link hierarchy incorrect'
          : 'Head pointer and next links restored';
      _accent = _brokenLink ? AppColors.orange : AppColors.lime;
    });
  }

  void _moveNode(String label, Offset delta) {
    setState(() {
      final index = _nodes.indexWhere((node) => node.label == label);
      if (index < 0) return;
      _nodes[index] = _nodes[index].copyWith(_nodes[index].position + delta);
    });
  }

  bool get _invalidSequence {
    for (var i = 1; i < _nodes.length; i++) {
      if (_nodes[i].position.dx <= _nodes[i - 1].position.dx) {
        return true;
      }
    }
    return false;
  }

  void _setFeedback(String message, Color color) {
    setState(() {
      _feedback = message;
      _accent = color;
    });
  }

  @override
  Widget build(BuildContext context) {
    return _ResponsiveLabShell(
      workspace: _CyberPanel(
        title: 'Linked List Builder',
        subtitle: 'Drag nodes into the list and simulate head traversal.',
        child: _LinkedListBoard(
          nodes: _nodes,
          brokenLink: _brokenLink,
          invalidSequence: _invalidSequence,
          onMove: _moveNode,
          onAccept: _addNode,
        ),
      ),
      sidePanel: Column(
        children: [
          _CyberPanel(
            title: 'Operations',
            subtitle: 'Append, remove, and challenge the pointer hierarchy.',
            child: Column(
              children: [
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: [
                    _GlowButton(
                      label: 'ADD NODE',
                      icon: Icons.add_rounded,
                      color: AppColors.cyan,
                      onTap: () => _addNode('N${_nodes.length + 1}'),
                    ),
                    _GlowButton(
                      label: 'REMOVE HEAD',
                      icon: Icons.remove_circle_outline,
                      color: AppColors.orange,
                      onTap: _removeHead,
                    ),
                    _GlowButton(
                      label: 'BREAK LINK',
                      icon: Icons.link_off_rounded,
                      color: AppColors.pink,
                      onTap: _toggleBrokenLink,
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    for (final value in ['D', 'E', 'F'])
                      Draggable<String>(
                        data: value,
                        feedback: _DragChip(label: value, large: true),
                        childWhenDragging: Opacity(
                          opacity: 0.35,
                          child: _DragChip(label: value),
                        ),
                        child: _DragChip(label: value),
                      ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          _FeedbackPanel(message: _feedback, accent: _accent),
          const SizedBox(height: 14),
          const _ExplanationPanel(
            title: 'Linked List Concept',
            points: [
              'The head pointer always points to the first node in the list.',
              'Each node stores data and a link to the next node.',
              'Incorrect ordering or links causes traversal faults.',
            ],
          ),
        ],
      ),
    );
  }
}

class _LinkedListBoard extends StatelessWidget {
  const _LinkedListBoard({
    required this.nodes,
    required this.onMove,
    required this.onAccept,
    required this.brokenLink,
    required this.invalidSequence,
  });

  final List<_LinkedListNode> nodes;
  final void Function(String label, Offset delta) onMove;
  final ValueChanged<String> onAccept;
  final bool brokenLink;
  final bool invalidSequence;

  @override
  Widget build(BuildContext context) {
    return DragTarget<String>(
      onAcceptWithDetails: (details) => onAccept(details.data),
      builder: (context, candidate, rejected) {
        return SizedBox(
          height: 430,
          child: Stack(
            children: [
              const Positioned.fill(child: _NeonGrid()),
              Positioned.fill(
                child: CustomPaint(
                  painter: _LinkedListPainter(
                    nodes,
                    brokenLink,
                    invalidSequence,
                  ),
                ),
              ),
              for (final node in nodes)
                Positioned(
                  left: node.position.dx,
                  top: node.position.dy,
                  child: GestureDetector(
                    onPanUpdate: (details) => onMove(node.label, details.delta),
                    child: _LinkedListNodeBubble(
                      label: node.label,
                      active: false,
                    ),
                  ),
                ),
              Positioned(
                left: 24,
                top: 22,
                child: _PointerLabel(
                  label: 'HEAD',
                  color: brokenLink ? AppColors.orange : AppColors.lime,
                ),
              ),
              Positioned(
                left: 24,
                bottom: 22,
                child: Text(
                  candidate.isEmpty
                      ? 'Drop node chips into the workspace'
                      : 'Release to add node',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _CyberPanel extends StatelessWidget {
  const _CyberPanel({
    required this.title,
    required this.subtitle,
    required this.child,
  });

  final String title;
  final String subtitle;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 6),
          Text(subtitle, style: Theme.of(context).textTheme.bodyMedium),
          const SizedBox(height: 14),
          ClipRRect(
            borderRadius: BorderRadius.circular(22),
            child: Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: const Color(0xC4080B1D),
                border: Border.all(
                  color: AppColors.cyan.withValues(alpha: 0.18),
                ),
                borderRadius: BorderRadius.circular(22),
              ),
              child: child,
            ),
          ),
        ],
      ),
    );
  }
}

class _FeedbackPanel extends StatelessWidget {
  const _FeedbackPanel({required this.message, required this.accent});

  final String message;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Icon(Icons.psychology_alt_rounded, color: accent),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                color: accent,
                fontWeight: FontWeight.w800,
                height: 1.35,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ExplanationPanel extends StatelessWidget {
  const _ExplanationPanel({required this.title, required this.points});

  final String title;
  final List<String> points;

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 10),
          for (final point in points)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '01',
                    style: TextStyle(
                      color: AppColors.cyan,
                      fontSize: 10,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      point,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _MiniTab extends StatelessWidget {
  const _MiniTab({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ActionChip(
      onPressed: onTap,
      label: Text(label),
      backgroundColor: selected
          ? AppColors.violet.withValues(alpha: 0.22)
          : Colors.white.withValues(alpha: 0.06),
      side: BorderSide(
        color: selected
            ? AppColors.violet.withValues(alpha: 0.62)
            : Colors.white.withValues(alpha: 0.12),
      ),
      labelStyle: TextStyle(
        color: selected ? AppColors.textPrimary : AppColors.textSecondary,
        fontWeight: FontWeight.w800,
      ),
    );
  }
}

class _GlowButton extends StatelessWidget {
  const _GlowButton({
    required this.label,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return FilledButton.icon(
      onPressed: onTap,
      icon: Icon(icon, size: 18),
      label: Text(label),
      style: FilledButton.styleFrom(
        backgroundColor: color.withValues(alpha: 0.16),
        foregroundColor: color,
        side: BorderSide(color: color.withValues(alpha: 0.46)),
      ),
    );
  }
}

class _BinaryToggle extends StatelessWidget {
  const _BinaryToggle({
    required this.label,
    required this.value,
    required this.onTap,
  });

  final String label;
  final bool value;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: (value ? AppColors.lime : AppColors.pink).withValues(
            alpha: 0.12,
          ),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: (value ? AppColors.lime : AppColors.pink).withValues(
              alpha: 0.42,
            ),
          ),
        ),
        child: Column(
          children: [
            Text(label, style: Theme.of(context).textTheme.bodyMedium),
            Text(
              value ? '1' : '0',
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 22,
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TruthRow extends StatelessWidget {
  const _TruthRow({
    required this.a,
    required this.b,
    required this.out,
    this.header = false,
  });

  final String a;
  final String b;
  final String out;
  final bool header;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: header
            ? AppColors.cyan.withValues(alpha: 0.1)
            : Colors.white.withValues(alpha: 0.045),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Expanded(child: Text(a, textAlign: TextAlign.center)),
          Expanded(child: Text(b, textAlign: TextAlign.center)),
          Expanded(child: Text(out, textAlign: TextAlign.center)),
        ],
      ),
    );
  }
}

class _DragChip extends StatelessWidget {
  const _DragChip({required this.label, this.large = false});

  final String label;
  final bool large;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: Container(
        width: large ? 70 : 58,
        height: large ? 54 : 46,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: AppColors.cyan.withValues(alpha: 0.18),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.cyan.withValues(alpha: 0.55)),
          boxShadow: [
            BoxShadow(
              color: AppColors.cyan.withValues(alpha: 0.25),
              blurRadius: 18,
            ),
          ],
        ),
        child: Text(
          label,
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w900,
          ),
        ),
      ),
    );
  }
}

class _GateChip extends StatelessWidget {
  const _GateChip({required this.label, this.floating = false});

  final String label;
  final bool floating;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: floating ? 18 : 14,
          vertical: floating ? 13 : 10,
        ),
        decoration: BoxDecoration(
          color: AppColors.violet.withValues(alpha: 0.16),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.violet.withValues(alpha: 0.48)),
        ),
        child: Text(
          label,
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w900,
          ),
        ),
      ),
    );
  }
}

class _AtomChip extends StatelessWidget {
  const _AtomChip({required this.symbol, this.floating = false});

  final String symbol;
  final bool floating;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: Container(
        width: floating ? 58 : 48,
        height: floating ? 58 : 48,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: _atomColor(symbol).withValues(alpha: 0.2),
          border: Border.all(color: _atomColor(symbol).withValues(alpha: 0.65)),
          boxShadow: [
            BoxShadow(
              color: _atomColor(symbol).withValues(alpha: 0.24),
              blurRadius: 18,
            ),
          ],
        ),
        child: Text(
          symbol,
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w900,
          ),
        ),
      ),
    );
  }
}

class _TreeNodeBubble extends StatelessWidget {
  const _TreeNodeBubble({
    required this.label,
    required this.active,
    required this.warning,
  });

  final String label;
  final bool active;
  final bool warning;

  @override
  Widget build(BuildContext context) {
    final color = warning
        ? AppColors.pink
        : active
        ? AppColors.lime
        : AppColors.cyan;
    return Container(
      width: 76,
      height: 76,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color.withValues(alpha: 0.16),
        border: Border.all(color: color.withValues(alpha: 0.7), width: 2),
        boxShadow: [
          BoxShadow(color: color.withValues(alpha: 0.3), blurRadius: 24),
        ],
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: AppColors.textPrimary,
          fontSize: 24,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class _GateNodeWidget extends StatelessWidget {
  const _GateNodeWidget({required this.label, this.selected = false});

  final String label;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    final color = selected ? AppColors.lime : AppColors.violet;
    return Container(
      width: 112,
      height: 72,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.22),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: color.withValues(alpha: 0.65),
          width: selected ? 3 : 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.28),
            blurRadius: selected ? 28 : 18,
          ),
        ],
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: AppColors.textPrimary,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class _AtomBubble extends StatelessWidget {
  const _AtomBubble({required this.symbol, this.selected = false});

  final String symbol;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    final color = _atomColor(symbol);
    return Container(
      width: 72,
      height: 72,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [
            color.withValues(alpha: selected ? 0.75 : 0.55),
            color.withValues(alpha: 0.16),
          ],
        ),
        border: Border.all(
          color: selected
              ? AppColors.lime.withValues(alpha: 0.95)
              : color.withValues(alpha: 0.75),
          width: selected ? 3 : 2,
        ),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.32),
            blurRadius: selected ? 30 : 24,
          ),
        ],
      ),
      child: Text(
        symbol,
        style: const TextStyle(
          color: AppColors.textPrimary,
          fontSize: 20,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class _PointerLabel extends StatelessWidget {
  const _PointerLabel({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(Icons.arrow_back_rounded, color: color),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.14),
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: color.withValues(alpha: 0.5)),
          ),
          child: Text(
            label,
            style: TextStyle(color: color, fontWeight: FontWeight.w900),
          ),
        ),
      ],
    );
  }
}

class _SignalPad extends StatelessWidget {
  const _SignalPad({required this.label, required this.active});

  final String label;
  final bool active;

  @override
  Widget build(BuildContext context) {
    final color = active ? AppColors.lime : AppColors.pink;
    return Container(
      width: 58,
      height: 58,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color.withValues(alpha: 0.14),
        border: Border.all(color: color.withValues(alpha: 0.65)),
      ),
      child: Text(
        label,
        style: TextStyle(color: color, fontWeight: FontWeight.w900),
      ),
    );
  }
}

class _NeonGrid extends StatelessWidget {
  const _NeonGrid();

  @override
  Widget build(BuildContext context) {
    return CustomPaint(painter: _GridPainter());
  }
}

class _GridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.cyan.withValues(alpha: 0.055)
      ..strokeWidth = 1;
    for (double x = 0; x < size.width; x += 32) {
      canvas.drawLine(Offset(x, 0), Offset(x - 54, size.height), paint);
    }
    for (double y = 0; y < size.height; y += 32) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _TreePainter extends CustomPainter {
  const _TreePainter(this.nodes, this.active, this.badHierarchy);

  final List<_TreeNode> nodes;
  final String active;
  final bool badHierarchy;

  @override
  void paint(Canvas canvas, Size size) {
    void connect(String from, String to) {
      final a =
          nodes.firstWhere((node) => node.label == from).position +
          const Offset(38, 38);
      final b =
          nodes.firstWhere((node) => node.label == to).position +
          const Offset(38, 38);
      final warning = badHierarchy && to == 'C';
      final paint = Paint()
        ..color = (warning ? AppColors.pink : AppColors.cyan).withValues(
          alpha: 0.58,
        )
        ..strokeWidth = warning ? 4 : 2.5
        ..strokeCap = StrokeCap.round;
      canvas.drawLine(a, b, paint);
      canvas.drawCircle(
        Offset.lerp(a, b, 0.55)!,
        4,
        Paint()..color = AppColors.lime,
      );
    }

    connect('A', 'B');
    connect('A', 'C');
    connect('B', 'D');
  }

  @override
  bool shouldRepaint(covariant _TreePainter oldDelegate) => true;
}

class _CircuitPainter extends CustomPainter {
  const _CircuitPainter({
    required this.gates,
    required this.progress,
    required this.inputA,
    required this.inputB,
    required this.output,
    required this.connections,
  });

  final List<_GateNode> gates;
  final double progress;
  final bool inputA;
  final bool inputB;
  final bool output;
  final List<_GateConnection> connections;

  @override
  void paint(Canvas canvas, Size size) {
    if (gates.isEmpty) {
      return;
    }
    final points = [
      Offset(76, 107),
      Offset(76, 267),
      ...gates.map((gate) => gate.position + const Offset(56, 36)),
      Offset(size.width - 52, 205),
    ];
    for (var i = 0; i < points.length - 1; i++) {
      final active = i == 0
          ? inputA
          : i == 1
          ? inputB
          : output;
      _drawNeonLine(canvas, points[i], points[i + 1], progress, active);
    }
    for (final connection in connections) {
      if (connection.from < 0 || connection.from >= gates.length) continue;
      if (connection.to < 0 || connection.to >= gates.length) continue;
      final a = gates[connection.from].position + const Offset(56, 36);
      final b = gates[connection.to].position + const Offset(56, 36);
      _drawConnectionLine(canvas, a, b, progress);
    }
  }

  void _drawConnectionLine(Canvas canvas, Offset a, Offset b, double t) {
    final paint = Paint()
      ..color = AppColors.violet.withValues(alpha: 0.55)
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round;
    final path = Path()
      ..moveTo(a.dx, a.dy)
      ..quadraticBezierTo((a.dx + b.dx) / 2, a.dy - 40, b.dx, b.dy);
    canvas.drawPath(path, paint);
    canvas.drawCircle(
      Offset.lerp(a, b, t)!,
      4.5,
      Paint()..color = AppColors.lime.withValues(alpha: 0.9),
    );
  }

  void _drawNeonLine(Canvas canvas, Offset a, Offset b, double t, bool active) {
    final color = active ? AppColors.lime : AppColors.cyan;
    final paint = Paint()
      ..color = color.withValues(alpha: 0.48)
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;
    final path = Path()
      ..moveTo(a.dx, a.dy)
      ..cubicTo(a.dx + 70, a.dy, b.dx - 70, b.dy, b.dx, b.dy);
    canvas.drawPath(path, paint);
    canvas.drawCircle(Offset.lerp(a, b, t)!, 4.5, Paint()..color = color);
  }

  @override
  bool shouldRepaint(covariant _CircuitPainter oldDelegate) => true;
}

class _MoleculePainter extends CustomPainter {
  const _MoleculePainter({
    required this.atoms,
    required this.bonds,
    required this.progress,
  });

  final List<_AtomNode> atoms;
  final List<_Bond> bonds;
  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    if (atoms.isEmpty || bonds.isEmpty) {
      return;
    }
    for (final bond in bonds) {
      if (bond.a < 0 || bond.a >= atoms.length) continue;
      if (bond.b < 0 || bond.b >= atoms.length) continue;
      final a = atoms[bond.a].position + const Offset(33, 33);
      final b = atoms[bond.b].position + const Offset(33, 33);
      final normal = Offset(-(b.dy - a.dy), b.dx - a.dx);
      final length = math.max(1.0, normal.distance);
      final unit = Offset(normal.dx / length, normal.dy / length);
      for (var order = 0; order < bond.order; order++) {
        final offset = unit * ((order - (bond.order - 1) / 2) * 10);
        _drawBond(canvas, a + offset, b + offset, progress);
      }
    }
  }

  void _drawBond(Canvas canvas, Offset a, Offset b, double t) {
    final paint = Paint()
      ..color = AppColors.cyan.withValues(alpha: 0.58)
      ..strokeWidth = 3.5
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(a, b, paint);
    canvas.drawCircle(
      Offset.lerp(a, b, t)!,
      4.5,
      Paint()..color = AppColors.lime,
    );
  }

  @override
  bool shouldRepaint(covariant _MoleculePainter oldDelegate) =>
      oldDelegate.atoms != atoms ||
      oldDelegate.bonds != bonds ||
      oldDelegate.progress != progress;
}

class _LinkedListNode {
  const _LinkedListNode(this.label, this.position);

  final String label;
  final Offset position;

  _LinkedListNode copyWith(Offset position) => _LinkedListNode(label, position);
}

class _LinkedListNodeBubble extends StatelessWidget {
  const _LinkedListNodeBubble({required this.label, required this.active});

  final String label;
  final bool active;

  @override
  Widget build(BuildContext context) {
    final color = active ? AppColors.lime : AppColors.cyan;
    return Container(
      width: 96,
      height: 66,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: color.withValues(alpha: 0.7), width: 2),
        boxShadow: [
          BoxShadow(color: color.withValues(alpha: 0.2), blurRadius: 18),
        ],
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: AppColors.textPrimary,
          fontWeight: FontWeight.w900,
          fontSize: 22,
        ),
      ),
    );
  }
}

class _LinkedListPainter extends CustomPainter {
  const _LinkedListPainter(this.nodes, this.brokenLink, this.invalidSequence);

  final List<_LinkedListNode> nodes;
  final bool brokenLink;
  final bool invalidSequence;

  @override
  void paint(Canvas canvas, Size size) {
    if (nodes.isEmpty) {
      return;
    }

    final linkColor = brokenLink || invalidSequence
        ? AppColors.orange
        : AppColors.lime;
    final paint = Paint()
      ..color = linkColor.withValues(alpha: 0.72)
      ..strokeWidth = 3.5
      ..strokeCap = StrokeCap.round;

    final first = nodes.first.position + const Offset(48, 33);
    final headAnchor = Offset(24 + 90, 52);
    canvas.drawLine(headAnchor, first, paint);
    canvas.drawCircle(first, 6, Paint()..color = linkColor);

    for (var i = 0; i < nodes.length - 1; i++) {
      final a = nodes[i].position + const Offset(96, 33);
      final b = nodes[i + 1].position + const Offset(0, 33);
      final path = Path()
        ..moveTo(a.dx, a.dy)
        ..lineTo(a.dx + 30, a.dy)
        ..lineTo(a.dx + 30, b.dy)
        ..lineTo(b.dx, b.dy);
      canvas.drawPath(path, paint);
      canvas.drawCircle(
        Offset.lerp(a, b, 0.45)!,
        5,
        Paint()..color = AppColors.lime.withValues(alpha: 0.9),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _LinkedListPainter oldDelegate) =>
      oldDelegate.nodes != nodes ||
      oldDelegate.brokenLink != brokenLink ||
      oldDelegate.invalidSequence != invalidSequence;
}

class _LearningDomain {
  const _LearningDomain({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.accent,
    required this.topics,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final Color accent;
  final List<_LearningTopic> topics;
}

class _LearningTopic {
  const _LearningTopic({
    required this.title,
    required this.subtitle,
    required this.icon,
  });

  final String title;
  final String subtitle;
  final IconData icon;
}

class _TreeNode {
  const _TreeNode(this.label, this.position);

  final String label;
  final Offset position;

  _TreeNode copyWith(Offset position) => _TreeNode(label, position);
}

class _GateNode {
  const _GateNode(this.type, this.position);

  final String type;
  final Offset position;

  _GateNode copyWith(Offset position) => _GateNode(type, position);
}

class _GateConnection {
  const _GateConnection(this.from, this.to);

  final int from;
  final int to;
}

class _Bond {
  const _Bond(this.a, this.b, this.order);

  final int a;
  final int b;
  final int order;
}

class _AtomNode {
  const _AtomNode(this.symbol, this.position);

  final String symbol;
  final Offset position;

  _AtomNode copyWith(Offset position) => _AtomNode(symbol, position);
}

Color _atomColor(String symbol) {
  return switch (symbol) {
    'C' => AppColors.cyan,
    'H' => AppColors.lime,
    'O' => AppColors.pink,
    'N' => AppColors.violet,
    _ => AppColors.orange,
  };
}
