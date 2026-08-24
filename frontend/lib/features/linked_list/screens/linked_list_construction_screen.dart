import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/network/api_client.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/glass_card.dart';
import '../../../shared/widgets/status_chip.dart';
import '../../assessments/linked_list_assessment/models/validation_result.dart';
import '../../assessments/linked_list_assessment/screens/linked_list_assessment_screen.dart';
import '../../assessments/linked_list_assessment/services/linked_list_assessment_service.dart';
import '../../misconceptions/models/record_misconception_request.dart';
import '../../misconceptions/services/misconception_service.dart';
import '../../progress/providers/progress_provider.dart';
import '../../sessions/providers/session_provider.dart';
import '../models/linked_list_node_model.dart';
import '../models/linked_list_task.dart';
import '../models/linked_list_workspace_state.dart';
import '../widgets/linked_list_playground.dart';
import '../widgets/node_palette.dart';

// ─────────────────────────────────────────────────────────────────────────────
// LinkedListConstructionScreen — public entry point
// ─────────────────────────────────────────────────────────────────────────────

/// Construction-based Linked List learning workspace.
///
/// The student drags nodes from [NodePalette] onto [LinkedListPlayground],
/// assigns HEAD via long-press, connects nodes by two-tap, then presses
/// VERIFY. Validation is delegated entirely to
/// [LinkedListAssessmentService.validateBuild] — no duplicate logic here.
///
/// Architecture:
///   Logical layer → [LinkedListWorkspaceState] + [LinkedListGraph]
///   Visual layer  → [List<LinkedListNodeModel>] (Offset positions only)
///   The two layers are kept completely separate.
class LinkedListConstructionScreen extends StatefulWidget {
  const LinkedListConstructionScreen({
    super.key,
    this.initialTaskId,
  });

  /// When set, the screen opens directly to the task with this ID and runs
  /// in "targeted practice" mode instead of the full 3-task curriculum.
  ///
  /// Targeted mode:
  ///   - Skips directly to the requested task (ignores task index 0).
  ///   - After the student completes the task, shows [_TargetedPracticeCompletePanel]
  ///     instead of the full [_AllTasksCompleteScreen].
  ///   - Does NOT automatically restart the full curriculum.
  ///
  /// Null = normal mode (start from Task 1, run full curriculum).
  final String? initialTaskId;

  @override
  State<LinkedListConstructionScreen> createState() =>
      _LinkedListConstructionScreenState();
}

class _LinkedListConstructionScreenState
    extends State<LinkedListConstructionScreen> {
  // ── Services ─────────────────────────────────────────────────────────────
  final _service = LinkedListAssessmentService();

  // ── Visual layer — Offsets live here only ─────────────────────────────────
  final List<LinkedListNodeModel> _visualNodes = [];

  // ── Logical layer ─────────────────────────────────────────────────────────
  LinkedListWorkspaceState _state = LinkedListWorkspaceState.initial();

  // ── Misconception deduplication ───────────────────────────────────────────
  String? _lastRecordedMisconceptionCode;

  // ── Transient invalid-action toast ───────────────────────────────────────
  String? _invalidActionMessage;

  // ── Targeted mode ─────────────────────────────────────────────────────────
  // True when the screen was opened with a specific [initialTaskId].
  // Derived once in initState; never changes for the lifetime of the widget.
  bool _isTargetedMode = false;

  @override
  void initState() {
    super.initState();

    // Determine starting task.
    LinkedListTask startTask = kLinkedListTasks[0];
    if (widget.initialTaskId != null) {
      final match = kLinkedListTasks
          .where((t) => t.id == widget.initialTaskId)
          .firstOrNull;
      if (match != null) {
        startTask = match;
        _isTargetedMode = true;
      }
    }

    _loadTask(startTask);
    _startSession();
  }

  // ── Session lifecycle ─────────────────────────────────────────────────────

  Future<void> _startSession() async {
    try {
      final sessionProvider = context.read<SessionProvider>();
      await sessionProvider.startSession(
        domainCode: 'DSA',
        topicCode: 'DSA_LINKED_LIST',
        activityCode: 'workspace',
      );
      if (!mounted) return;
      final active = context.read<SessionProvider>().activeSession;
      if (active != null) {
        setState(() => _state = _state.copyWith(sessionId: active.id));
      }
    } catch (e) {
      debugPrint('LL construction session start failed: $e');
    }
  }

  Future<void> _endSession() async {
    try {
      await context.read<SessionProvider>().endSession();
    } catch (e) {
      debugPrint('LL construction session end failed: $e');
    }
  }

  @override
  void dispose() {
    _endSession();
    super.dispose();
  }

  // ── Task loading ──────────────────────────────────────────────────────────

  void _loadTask(LinkedListTask task) {
    _visualNodes.clear();
    _lastRecordedMisconceptionCode = null;
    setState(() {
      _state = _state.loadTask(task);
      _invalidActionMessage = null;
    });
  }

  // ── Node drop from palette ────────────────────────────────────────────────

  void _onNodeDropped(PaletteNodeDragData data, Offset dropOffset) {
    if (!_state.paletteNodeIds.contains(data.nodeId)) return;

    // Clamp so the node starts fully inside the playground bounds.
    final clamped = Offset(
      dropOffset.dx.clamp(12.0, 560.0),
      dropOffset.dy.clamp(72.0, 340.0),
    );

    _visualNodes.add(LinkedListNodeModel(
      id: data.nodeId,
      label: data.label,
      position: clamped,
    ));

    setState(() {
      _state = _state.copyWith(
        paletteNodeIds:
            _state.paletteNodeIds.where((id) => id != data.nodeId).toList(),
        placedNodeIds: [..._state.placedNodeIds, data.nodeId],
      );
    });
  }

  // ── Reposition node on canvas ─────────────────────────────────────────────

  void _onMoveNode(int id, Offset position) {
    for (var i = 0; i < _visualNodes.length; i++) {
      if (_visualNodes[i].id == id) {
        setState(() {
          _visualNodes[i] = _visualNodes[i].copyWith(position: position);
        });
        break;
      }
    }
    // No logical graph mutation — position is purely visual.
  }

  // ── HEAD assignment ───────────────────────────────────────────────────────

  void _onNodeLongPress(int id) {
    if (!_state.placedNodeIds.contains(id)) return;
    _showSetHeadSheet(id);
  }

  void _showSetHeadSheet(int nodeId) {
    final label = _state.currentGraph.labelOf(nodeId);
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: const Color(0xFF121834),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => Padding(
        padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Node $label',
              style: Theme.of(context)
                  .textTheme
                  .titleLarge
                  ?.copyWith(color: AppColors.textPrimary),
            ),
            const SizedBox(height: 6),
            Text(
              'What would you like to do with this node?',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 14),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: () {
                  Navigator.pop(context);
                  _setHead(nodeId);
                },
                icon: const Icon(Icons.flag_rounded),
                label: const Text('Set as HEAD'),
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.lime.withValues(alpha: 0.20),
                  foregroundColor: AppColors.lime,
                  side: BorderSide(
                      color: AppColors.lime.withValues(alpha: 0.55)),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
              ),
            ),
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.close_rounded, size: 18),
                label: const Text('Cancel'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.textSecondary,
                  side: BorderSide(
                      color: AppColors.textSecondary.withValues(alpha: 0.3)),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _setHead(int nodeId) {
    setState(() {
      _state = _state.copyWith(
        currentGraph: _state.currentGraph.withHead(nodeId),
        clearSelectedNode: true,
      );
    });
  }

  // ── Two-tap connection ────────────────────────────────────────────────────

  void _onNodeTap(int id) {
    if (!_state.placedNodeIds.contains(id)) return;
    if (_state.isTaskComplete) return;

    final selected = _state.selectedNodeId;

    if (selected == null) {
      setState(() => _state = _state.copyWith(selectedNodeId: id));
      return;
    }

    if (selected == id) {
      setState(() => _state = _state.copyWith(clearSelectedNode: true));
      return;
    }

    // Prevent cycles.
    final simulated = _state.currentGraph.withPointer(
      fromId: selected,
      toId: id,
    );
    if (simulated.hasCycle()) {
      final fromLabel = _state.currentGraph.labelOf(selected);
      final toLabel = _state.currentGraph.labelOf(id);
      _showInvalidAction(
        'Connecting $fromLabel → $toLabel would create a cycle. '
        'Linked lists must not loop.',
      );
      setState(() => _state = _state.copyWith(clearSelectedNode: true));
      return;
    }

    setState(() {
      _state = _state.copyWith(
        currentGraph: simulated,
        clearSelectedNode: true,
      );
    });
  }

  void _showInvalidAction(String message) {
    setState(() => _invalidActionMessage = message);
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) setState(() => _invalidActionMessage = null);
    });
  }

  // ── VERIFY ────────────────────────────────────────────────────────────────

  void _onVerify() {
    final task = kLinkedListTasks[_state.currentTaskIndex];
    final raw = _service.validateBuild(
      _state.currentGraph,
      task.expectedGraph,
    );

    // Pick the progressive task hint on failure if available.
    final hintIndex =
        _state.hintsShownCount.clamp(0, task.hints.length - 1);
    final displayHint = (!raw.isValid && task.hints.isNotEmpty)
        ? task.hints[hintIndex]
        : raw.hint;

    // Rebuild ValidationResult with the overridden hint text so the
    // misconception fields are preserved exactly.
    final displayed = ValidationResult(
      isValid: raw.isValid,
      hint: displayHint,
      misconceptionCode: raw.misconceptionCode,
      misconceptionTitle: raw.misconceptionTitle,
      misconceptionDescription: raw.misconceptionDescription,
      misconceptionSeverity: raw.misconceptionSeverity,
    );

    final newHintCount = raw.isValid
        ? _state.hintsShownCount
        : math.min(_state.hintsShownCount + 1,
            math.max(0, task.hints.length - 1));

    setState(() {
      _state = _state.copyWith(
        lastValidation: displayed,
        hintsShownCount: newHintCount,
        isTaskComplete: raw.isValid,
        completedTaskCount: raw.isValid
            ? _state.completedTaskCount + 1
            : _state.completedTaskCount,
      );
    });

    if (raw.hasMisconception) {
      _recordMisconceptionIfNeeded(raw);
    }
  }

  // ── Misconception recording ───────────────────────────────────────────────

  void _recordMisconceptionIfNeeded(ValidationResult result) {
    if (result.misconceptionCode == _lastRecordedMisconceptionCode) return;
    if (_state.sessionId == null) return;
    _lastRecordedMisconceptionCode = result.misconceptionCode;
    unawaited(_doRecordMisconception(result));
  }

  Future<void> _doRecordMisconception(ValidationResult result) async {
    if (!mounted) return;
    try {
      final svc = MisconceptionService(apiClient: context.read<ApiClient>());
      await svc.recordMisconception(RecordMisconceptionRequest(
        sessionId: _state.sessionId!,
        topicCode: 'DSA_LINKED_LIST',
        misconceptionCode: result.misconceptionCode!,
        misconceptionTitle: result.misconceptionTitle!,
        description: result.misconceptionDescription!,
        severity: result.misconceptionSeverity,
      ));
      if (!mounted) return;
      unawaited(context.read<ProgressProvider>().loadProgress());
    } catch (e) {
      debugPrint('LL workspace misconception record failed: $e');
    }
  }

  // ── Next task ─────────────────────────────────────────────────────────────

  void _onNextTask() {
    if (_isTargetedMode) {
      // In targeted mode there is only one task.
      // Advance the index past the list length to trigger the targeted
      // completion screen instead of loading the next curriculum task.
      setState(() => _state = _state.copyWith(
            currentTaskIndex: kLinkedListTasks.length, // sentinel
          ));
      return;
    }

    final nextIndex = _state.currentTaskIndex + 1;
    if (nextIndex >= kLinkedListTasks.length) {
      // Sentinel: all curriculum tasks done.
      setState(() => _state = _state.copyWith(
            currentTaskIndex: kLinkedListTasks.length,
          ));
      return;
    }
    _loadTask(kLinkedListTasks[nextIndex]);
  }

  // ── Build ─────────────────────────────────────────────────────────────────
  //
  // IMPORTANT: this widget is rendered as a child of AdvancedStemWorkspacesScreen,
  // which already owns the Scaffold, SafeArea, CyberBackground, and the outer
  // SingleChildScrollView.  Do NOT add another Scaffold, SafeArea,
  // CyberBackground, or SingleChildScrollView here — doing so creates nested
  // scroll/unbounded-height contexts that crash the layout engine.
  //
  // The all-tasks-complete state returns a full-screen Scaffold only because
  // it intentionally replaces the entire AppShell content area.

  @override
  Widget build(BuildContext context) {
    // Sentinel — currentTaskIndex >= length means the student just finished.
    if (_state.currentTaskIndex >= kLinkedListTasks.length) {
      if (_isTargetedMode) {
        // Targeted completion: do NOT restart the full curriculum.
        return _TargetedPracticeCompletePanel(
          onContinueLearning: () {
            // Restart just the targeted task so the student can repeat it.
            final taskId = widget.initialTaskId;
            final task = taskId == null
                ? kLinkedListTasks[0]
                : kLinkedListTasks.firstWhere(
                    (t) => t.id == taskId,
                    orElse: () => kLinkedListTasks[0],
                  );
            _loadTask(task);
          },
        );
      }
      // Normal curriculum completion.
      return _AllTasksCompleteScreen(
        completedCount: _state.completedTaskCount,
        onRestart: () => _loadTask(kLinkedListTasks[0]),
      );
    }

    final task = kLinkedListTasks[_state.currentTaskIndex];
    final nodeLabels = <int, String>{
      for (final id in [
        ..._state.paletteNodeIds,
        ..._state.placedNodeIds,
      ])
        id: _state.currentGraph.labelOf(id),
    };

    // LayoutBuilder gives a finite maxWidth from the parent Column's width.
    // We use it only to choose wide vs narrow — no scrolling added here.
    return LayoutBuilder(builder: (context, constraints) {
      final isWide = constraints.maxWidth >= 900;
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          _ConstructionHeader(
            currentIndex: _state.currentTaskIndex,
            totalTasks: kLinkedListTasks.length,
            completedCount: _state.completedTaskCount,
            title: task.title,
            onBack: _endSession,
            isTargetedMode: _isTargetedMode,
          ),
          const SizedBox(height: 18),
          if (isWide)
            _WideLayout(
              task: task,
              state: _state,
              visualNodes: _visualNodes,
              nodeLabels: nodeLabels,
              invalidActionMessage: _invalidActionMessage,
              onNodeDropped: _onNodeDropped,
              onMoveNode: _onMoveNode,
              onNodeTap: _onNodeTap,
              onNodeLongPress: _onNodeLongPress,
              onVerify: _onVerify,
              onNextTask: _onNextTask,
            )
          else
            _NarrowLayout(
              task: task,
              state: _state,
              visualNodes: _visualNodes,
              nodeLabels: nodeLabels,
              invalidActionMessage: _invalidActionMessage,
              onNodeDropped: _onNodeDropped,
              onMoveNode: _onMoveNode,
              onNodeTap: _onNodeTap,
              onNodeLongPress: _onNodeLongPress,
              onVerify: _onVerify,
              onNextTask: _onNextTask,
            ),
        ],
      );
    });
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _ConstructionHeader
// ─────────────────────────────────────────────────────────────────────────────

class _ConstructionHeader extends StatelessWidget {
  const _ConstructionHeader({
    required this.currentIndex,
    required this.totalTasks,
    required this.completedCount,
    required this.title,
    required this.onBack,
    this.isTargetedMode = false,
  });

  final int currentIndex;
  final int totalTasks;
  final int completedCount;
  final String title;
  final VoidCallback onBack;
  final bool isTargetedMode;

  @override
  Widget build(BuildContext context) {
    final progress = ((currentIndex + 1) / totalTasks).clamp(0.0, 1.0);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            IconButton.filledTonal(
              onPressed: onBack,
              icon: const Icon(Icons.arrow_back_rounded),
              color: AppColors.cyan,
            ),
            const SizedBox(width: 12),
            const StatusChip(label: 'Linked List — Learning Workspace'),
          ],
        ),
        const SizedBox(height: 14),
        // Mode badge
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: isTargetedMode
                ? AppColors.orange.withValues(alpha: 0.12)
                : AppColors.violet.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isTargetedMode
                  ? AppColors.orange.withValues(alpha: 0.35)
                  : AppColors.violet.withValues(alpha: 0.35),
            ),
          ),
          child: Text(
            isTargetedMode
                ? 'Targeted Practice'
                : 'Learning Task ${currentIndex + 1} of $totalTasks',
            style: TextStyle(
              color: isTargetedMode ? AppColors.orange : AppColors.violet,
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.6,
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(title, style: Theme.of(context).textTheme.headlineSmall),
        if (!isTargetedMode) ...[
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: LinearProgressIndicator(
                  value: progress,
                  minHeight: 6,
                  backgroundColor: AppColors.glass,
                  color: AppColors.lime,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              const SizedBox(width: 12),
              Text(
                '$completedCount / $totalTasks complete',
                style: const TextStyle(
                    color: AppColors.textSecondary, fontSize: 12),
              ),
            ],
          ),
        ],
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Shared callback typedef for layout widgets
// ─────────────────────────────────────────────────────────────────────────────

typedef _DropCallback = void Function(PaletteNodeDragData, Offset);

// ─────────────────────────────────────────────────────────────────────────────
// _WideLayout  (≥ 900 px) — playground left, side panel right
// ─────────────────────────────────────────────────────────────────────────────

class _WideLayout extends StatelessWidget {
  const _WideLayout({
    required this.task,
    required this.state,
    required this.visualNodes,
    required this.nodeLabels,
    required this.invalidActionMessage,
    required this.onNodeDropped,
    required this.onMoveNode,
    required this.onNodeTap,
    required this.onNodeLongPress,
    required this.onVerify,
    required this.onNextTask,
  });

  final LinkedListTask task;
  final LinkedListWorkspaceState state;
  final List<LinkedListNodeModel> visualNodes;
  final Map<int, String> nodeLabels;
  final String? invalidActionMessage;
  final _DropCallback onNodeDropped;
  final void Function(int, Offset) onMoveNode;
  final void Function(int) onNodeTap;
  final void Function(int) onNodeLongPress;
  final VoidCallback onVerify;
  final VoidCallback onNextTask;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Palette (left column)
        SizedBox(
          width: 180,
          child: Column(
            children: [
              NodePalette(
                paletteNodeIds: state.paletteNodeIds,
                nodeLabels: nodeLabels,
              ),
            ],
          ),
        ),
        const SizedBox(width: 16),

        // Playground (centre)
        Expanded(
          flex: 6,
          child: _PlaygroundCard(
            state: state,
            visualNodes: visualNodes,
            nodeLabels: nodeLabels,
            invalidActionMessage: invalidActionMessage,
            onNodeDropped: onNodeDropped,
            onMoveNode: onMoveNode,
            onNodeTap: onNodeTap,
            onNodeLongPress: onNodeLongPress,
          ),
        ),
        const SizedBox(width: 16),

        // Side panel (right)
        SizedBox(
          width: 280,
          child: _SidePanel(
            task: task,
            state: state,
            onVerify: onVerify,
            onNextTask: onNextTask,
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _NarrowLayout  (< 900 px) — stacked
// ─────────────────────────────────────────────────────────────────────────────

class _NarrowLayout extends StatelessWidget {
  const _NarrowLayout({
    required this.task,
    required this.state,
    required this.visualNodes,
    required this.nodeLabels,
    required this.invalidActionMessage,
    required this.onNodeDropped,
    required this.onMoveNode,
    required this.onNodeTap,
    required this.onNodeLongPress,
    required this.onVerify,
    required this.onNextTask,
  });

  final LinkedListTask task;
  final LinkedListWorkspaceState state;
  final List<LinkedListNodeModel> visualNodes;
  final Map<int, String> nodeLabels;
  final String? invalidActionMessage;
  final _DropCallback onNodeDropped;
  final void Function(int, Offset) onMoveNode;
  final void Function(int) onNodeTap;
  final void Function(int) onNodeLongPress;
  final VoidCallback onVerify;
  final VoidCallback onNextTask;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Palette (top, horizontal scroll)
        NodePalette(
          paletteNodeIds: state.paletteNodeIds,
          nodeLabels: nodeLabels,
        ),
        const SizedBox(height: 14),

        // Playground
        _PlaygroundCard(
          state: state,
          visualNodes: visualNodes,
          nodeLabels: nodeLabels,
          invalidActionMessage: invalidActionMessage,
          onNodeDropped: onNodeDropped,
          onMoveNode: onMoveNode,
          onNodeTap: onNodeTap,
          onNodeLongPress: onNodeLongPress,
        ),
        const SizedBox(height: 14),

        // Side panel
        _SidePanel(
          task: task,
          state: state,
          onVerify: onVerify,
          onNextTask: onNextTask,
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _PlaygroundCard — DragTarget wrapper around LinkedListPlayground
// ─────────────────────────────────────────────────────────────────────────────

class _PlaygroundCard extends StatelessWidget {
  const _PlaygroundCard({
    required this.state,
    required this.visualNodes,
    required this.nodeLabels,
    required this.invalidActionMessage,
    required this.onNodeDropped,
    required this.onMoveNode,
    required this.onNodeTap,
    required this.onNodeLongPress,
  });

  final LinkedListWorkspaceState state;
  final List<LinkedListNodeModel> visualNodes;
  final Map<int, String> nodeLabels;
  final String? invalidActionMessage;
  final _DropCallback onNodeDropped;
  final void Function(int, Offset) onMoveNode;
  final void Function(int) onNodeTap;
  final void Function(int) onNodeLongPress;

  @override
  Widget build(BuildContext context) {
    // Build the nextPointers map from the logical graph for the painter.
    final nextPointers = <int, int?>{
      for (final id in state.placedNodeIds)
        id: state.currentGraph.nextOf(id),
    };

    // Derive tail ID from logical graph for the TAIL indicator.
    final tailId = state.tailNodeId;

    return GlassCard(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Playground label
          Row(
            children: [
              const Icon(Icons.construction_rounded,
                  color: AppColors.cyan, size: 15),
              const SizedBox(width: 6),
              Text(
                'Construction Workspace',
                style: TextStyle(
                  color: AppColors.cyan.withValues(alpha: 0.85),
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const Spacer(),
              if (state.currentGraph.headId != null)
                _MiniChip(
                  label: 'HEAD set',
                  color: AppColors.lime,
                  icon: Icons.flag_rounded,
                ),
              if (tailId != null) ...[
                const SizedBox(width: 6),
                _MiniChip(
                  label: 'TAIL found',
                  color: AppColors.violet,
                  icon: Icons.last_page_rounded,
                ),
              ],
            ],
          ),
          const SizedBox(height: 10),

          // Instructions for empty canvas
          if (visualNodes.isEmpty)
            Container(
              height: 60,
              alignment: Alignment.center,
              child: Text(
                'Drag nodes from the palette into this area',
                style: TextStyle(
                    color: AppColors.textSecondary.withValues(alpha: 0.7),
                    fontSize: 13),
              ),
            ),

          // The playground as a DragTarget.
          // SizedBox gives a concrete finite height so LinkedListPlayground's
          // internal LayoutBuilder always receives a finite maxHeight constraint,
          // preventing the "render box never laid out" / mouse-tracker crash.
          SizedBox(
            height: 540,
            child: DragTarget<PaletteNodeDragData>(
              onAcceptWithDetails: (details) {
                // details.offset is global — convert to this widget's local
                // coordinate system so the drop position maps correctly onto
                // the playground canvas.
                final box = context.findRenderObject() as RenderBox?;
                final localOffset = box == null
                    ? details.offset
                    : box.globalToLocal(details.offset);
                onNodeDropped(details.data, localOffset);
              },
              builder: (context, candidateData, rejectedData) {
                final isHovering = candidateData.isNotEmpty;
                return AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: isHovering
                          ? AppColors.cyan.withValues(alpha: 0.65)
                          : Colors.transparent,
                      width: 2,
                    ),
                  ),
                  child: LinkedListPlayground(
                    nodes: visualNodes,
                    headNodeId: state.currentGraph.headId,
                    connectionBroken: false,
                    activeTraversalId: tailId,
                    selectedNodeId: state.selectedNodeId,
                    onMoveNode: onMoveNode,
                    onNodeTap: state.isTaskComplete ? null : onNodeTap,
                    onNodeLongPress:
                        state.isTaskComplete ? null : onNodeLongPress,
                    nextPointers: nextPointers,
                  ),
                );
              },
            ),
          ),

          // Invalid-action toast
          if (invalidActionMessage != null) ...[
            const SizedBox(height: 10),
            _ToastBanner(message: invalidActionMessage!),
          ],
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _SidePanel — learning panel + interaction guide + feedback + verify
// ─────────────────────────────────────────────────────────────────────────────

class _SidePanel extends StatelessWidget {
  const _SidePanel({
    required this.task,
    required this.state,
    required this.onVerify,
    required this.onNextTask,
  });

  final LinkedListTask task;
  final LinkedListWorkspaceState state;
  final VoidCallback onVerify;
  final VoidCallback onNextTask;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // ── Learning panel (concept + why) ────────────────────────────────
        _LearningPanel(task: task),
        const SizedBox(height: 12),

        // ── Step-by-step task prompt ──────────────────────────────────────
        GlassCard(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _SectionLabel(
                icon: Icons.assignment_outlined,
                label: 'Your Task',
                color: AppColors.cyan,
              ),
              const SizedBox(height: 8),
              Text(
                task.prompt,
                style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 13,
                    height: 1.55),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),

        // ── Interaction guide ─────────────────────────────────────────────
        GlassCard(
          padding: const EdgeInsets.all(14),
          child: _InteractionGuide(state: state),
        ),
        const SizedBox(height: 12),

        // ── Feedback / success panel ──────────────────────────────────────
        if (state.isTaskComplete)
          _SuccessPanel(task: task)
        else
          _FeedbackPanel(
            validation: state.lastValidation,
            hasAttempted: state.hintsShownCount > 0,
          ),
        const SizedBox(height: 14),

        // ── VERIFY / Next buttons ─────────────────────────────────────────
        if (!state.isTaskComplete)
          _VerifyButton(canVerify: state.canVerify, onVerify: onVerify)
        else
          _NextTaskButton(onNextTask: onNextTask),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _LearningPanel — concept explanation + why-it-matters
// ─────────────────────────────────────────────────────────────────────────────

class _LearningPanel extends StatelessWidget {
  const _LearningPanel({required this.task});

  final LinkedListTask task;

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Concept header
          _SectionLabel(
            icon: Icons.lightbulb_outline_rounded,
            label: 'Concept',
            color: AppColors.violet,
          ),
          const SizedBox(height: 8),
          Text(
            task.concept,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 13,
              height: 1.6,
            ),
          ),
          const SizedBox(height: 14),

          // Divider
          Divider(
            color: AppColors.violet.withValues(alpha: 0.18),
            height: 1,
          ),
          const SizedBox(height: 12),

          // Why it matters
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: AppColors.orange.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                      color: AppColors.orange.withValues(alpha: 0.35)),
                ),
                child: const Icon(Icons.warning_amber_rounded,
                    color: AppColors.orange, size: 14),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'WHY THIS MATTERS',
                      style: TextStyle(
                        color: AppColors.orange,
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.9,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      task.whyItMatters,
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 12,
                        height: 1.5,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _SectionLabel — small icon + label row used inside panels
// ─────────────────────────────────────────────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  const _SectionLabel({
    required this.icon,
    required this.label,
    required this.color,
  });

  final IconData icon;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: color, size: 14),
        const SizedBox(width: 6),
        Text(
          label.toUpperCase(),
          style: TextStyle(
            color: color,
            fontSize: 10,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.9,
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _InteractionGuide — step-by-step instructions reflecting current state
// ─────────────────────────────────────────────────────────────────────────────

class _InteractionGuide extends StatelessWidget {
  const _InteractionGuide({required this.state});

  final LinkedListWorkspaceState state;

  @override
  Widget build(BuildContext context) {
    final allPlaced = state.paletteNodeIds.isEmpty;
    final headSet = state.currentGraph.headId != null;
    final hasConnections = state.placedNodeIds.any(
      (id) => state.currentGraph.nextOf(id) != null,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'How to construct',
          style: TextStyle(
            color: AppColors.cyan,
            fontSize: 11,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.8,
          ),
        ),
        const SizedBox(height: 10),
        _GuideStep(
          icon: Icons.drag_indicator_rounded,
          color: AppColors.cyan,
          text: 'Drag all nodes from the palette',
          done: allPlaced,
        ),
        _GuideStep(
          icon: Icons.flag_rounded,
          color: AppColors.lime,
          text: 'Long-press a node → Set as HEAD',
          done: headSet,
          active: allPlaced && !headSet,
        ),
        _GuideStep(
          icon: Icons.arrow_forward_rounded,
          color: AppColors.violet,
          text: state.selectedNodeId == null
              ? 'Tap a node to select it as source'
              : 'Now tap the target node to connect →',
          done: false,
          active: allPlaced && headSet,
          highlighted: state.selectedNodeId != null,
        ),
        _GuideStep(
          icon: Icons.check_circle_outline_rounded,
          color: AppColors.lime,
          text: 'Connect all nodes, then press VERIFY',
          done: state.isTaskComplete,
          active: hasConnections,
        ),
      ],
    );
  }
}

class _GuideStep extends StatelessWidget {
  const _GuideStep({
    required this.icon,
    required this.color,
    required this.text,
    required this.done,
    this.active = false,
    this.highlighted = false,
  });

  final IconData icon;
  final Color color;
  final String text;
  final bool done;
  final bool active;
  final bool highlighted;

  @override
  Widget build(BuildContext context) {
    final effectiveColor = done
        ? AppColors.lime
        : highlighted
            ? AppColors.orange
            : active
                ? color
                : AppColors.textSecondary;

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            done ? Icons.check_circle_rounded : icon,
            size: 17,
            color: effectiveColor,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                color: effectiveColor,
                fontWeight:
                    (active || done || highlighted) ? FontWeight.w600 : FontWeight.w400,
                fontSize: 12,
                height: 1.45,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _FeedbackPanel — detailed correct / incorrect feedback
// ─────────────────────────────────────────────────────────────────────────────

class _FeedbackPanel extends StatelessWidget {
  const _FeedbackPanel({
    required this.validation,
    required this.hasAttempted,
  });

  final ValidationResult validation;
  final bool hasAttempted;

  @override
  Widget build(BuildContext context) {
    // Before first VERIFY — show a neutral starting prompt.
    if (!hasAttempted) {
      return Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.glass,
          borderRadius: BorderRadius.circular(14),
          border:
              Border.all(color: AppColors.cyan.withValues(alpha: 0.18)),
        ),
        child: Row(
          children: [
            const Icon(Icons.radar_rounded,
                color: AppColors.textSecondary, size: 18),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                validation.hint,
                style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                    height: 1.5),
              ),
            ),
          ],
        ),
      );
    }

    // After a VERIFY attempt — show coloured feedback.
    final isCorrect = validation.isValid;
    final color = isCorrect ? AppColors.lime : AppColors.pink;
    final icon = isCorrect
        ? Icons.check_circle_outline_rounded
        : Icons.highlight_off_rounded;
    final label = isCorrect ? 'Correct!' : 'Not quite yet.';

    return AnimatedContainer(
      duration: const Duration(milliseconds: 260),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.40)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Bold result line
          Row(
            children: [
              Icon(icon, color: color, size: 18),
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  color: color,
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          // Detailed explanation from ValidationResult.hint
          Text(
            validation.hint,
            style: TextStyle(
                color: isCorrect
                    ? AppColors.textPrimary
                    : AppColors.textSecondary,
                fontSize: 12,
                height: 1.55),
          ),
          // Show misconception title if present (non-distracting, small)
          if (!isCorrect && validation.misconceptionTitle != null) ...[
            const SizedBox(height: 10),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.orange.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                    color: AppColors.orange.withValues(alpha: 0.30)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.school_outlined,
                      color: AppColors.orange, size: 13),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      'Common mistake: ${validation.misconceptionTitle}',
                      style: const TextStyle(
                        color: AppColors.orange,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _SuccessPanel — shown when task is complete
// ─────────────────────────────────────────────────────────────────────────────

class _SuccessPanel extends StatelessWidget {
  const _SuccessPanel({required this.task});

  final LinkedListTask task;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.lime.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.lime.withValues(alpha: 0.40)),
        boxShadow: [
          BoxShadow(
              color: AppColors.lime.withValues(alpha: 0.08),
              blurRadius: 16),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ✓ Correct header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: AppColors.lime.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.check_rounded,
                    color: AppColors.lime, size: 16),
              ),
              const SizedBox(width: 10),
              const Text(
                'Correct!',
                style: TextStyle(
                  color: AppColors.lime,
                  fontWeight: FontWeight.w800,
                  fontSize: 15,
                ),
              ),
            ],
          ),

          if (task.explanation.isNotEmpty) ...[
            const SizedBox(height: 12),
            Divider(color: AppColors.lime.withValues(alpha: 0.18), height: 1),
            const SizedBox(height: 12),

            // "Concept learned" header
            Row(
              children: [
                const Icon(Icons.verified_outlined,
                    color: AppColors.cyan, size: 14),
                const SizedBox(width: 6),
                const Text(
                  'CONCEPT LEARNED',
                  style: TextStyle(
                    color: AppColors.cyan,
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.9,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              task.explanation,
              style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 12,
                  height: 1.65),
            ),
          ],
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _VerifyButton
// ─────────────────────────────────────────────────────────────────────────────

class _VerifyButton extends StatelessWidget {
  const _VerifyButton({required this.canVerify, required this.onVerify});

  final bool canVerify;
  final VoidCallback onVerify;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: FilledButton.icon(
        onPressed: canVerify ? onVerify : null,
        icon: const Icon(Icons.check_rounded),
        label: const Text('Verify'),
        style: FilledButton.styleFrom(
          backgroundColor:
              canVerify ? AppColors.lime : AppColors.glass,
          foregroundColor: canVerify
              ? AppColors.backgroundTop
              : AppColors.textSecondary,
          padding: const EdgeInsets.symmetric(vertical: 15),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _NextTaskButton
// ─────────────────────────────────────────────────────────────────────────────

class _NextTaskButton extends StatelessWidget {
  const _NextTaskButton({required this.onNextTask});

  final VoidCallback onNextTask;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: FilledButton.icon(
        onPressed: onNextTask,
        icon: const Icon(Icons.arrow_forward_rounded),
        label: const Text('Next Task'),
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.violet.withValues(alpha: 0.22),
          foregroundColor: AppColors.violet,
          side: BorderSide(color: AppColors.violet.withValues(alpha: 0.55)),
          padding: const EdgeInsets.symmetric(vertical: 15),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _ToastBanner — transient invalid-action notification
// ─────────────────────────────────────────────────────────────────────────────

class _ToastBanner extends StatelessWidget {
  const _ToastBanner({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.orange.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.orange.withValues(alpha: 0.45)),
      ),
      child: Row(
        children: [
          const Icon(Icons.warning_amber_rounded,
              color: AppColors.orange, size: 17),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                  color: AppColors.orange, fontSize: 12, height: 1.4),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _MiniChip — small status indicator in the playground header
// ─────────────────────────────────────────────────────────────────────────────

class _MiniChip extends StatelessWidget {
  const _MiniChip({
    required this.label,
    required this.color,
    required this.icon,
  });

  final String label;
  final Color color;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.40)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 12),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 10,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _TargetedPracticeCompletePanel — shown after completing a targeted task
// ─────────────────────────────────────────────────────────────────────────────

/// Compact completion state for targeted (misconception-driven) practice.
///
/// Does NOT restart the full curriculum.  The student can:
///   - Practice this concept again (re-opens the same task)
///   - Pop back to where they came from (AI Coach or assessment result)
class _TargetedPracticeCompletePanel extends StatelessWidget {
  const _TargetedPracticeCompletePanel({
    required this.onContinueLearning,
  });

  final VoidCallback onContinueLearning;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480),
          child: GlassCard(
            padding: const EdgeInsets.all(28),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Icon
                Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    color: AppColors.cyan.withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                    border: Border.all(
                        color: AppColors.cyan.withValues(alpha: 0.45),
                        width: 2),
                  ),
                  child: const Icon(Icons.verified_rounded,
                      color: AppColors.cyan, size: 38),
                ),
                const SizedBox(height: 20),

                const Text(
                  'Concept Practiced!',
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                const Text(
                  'Great work. Your practice has been recorded. '
                  'Continue improving by returning to the AI Coach '
                  'or by practicing again.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    height: 1.55,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 24),

                // Practice again
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: onContinueLearning,
                    icon: const Icon(Icons.replay_rounded, size: 18),
                    label: const Text('Practice Again'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.cyan,
                      side: BorderSide(
                          color: AppColors.cyan.withValues(alpha: 0.45)),
                      padding: const EdgeInsets.symmetric(vertical: 13),
                    ),
                  ),
                ),
                const SizedBox(height: 10),

                // Back to wherever the student came from
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: () => Navigator.of(context).maybePop(),
                    icon: const Icon(Icons.arrow_back_rounded, size: 18),
                    label: const Text('Back'),
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.violet.withValues(alpha: 0.18),
                      foregroundColor: AppColors.violet,
                      side: BorderSide(
                          color: AppColors.violet.withValues(alpha: 0.45)),
                      padding: const EdgeInsets.symmetric(vertical: 13),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _AllTasksCompleteScreen — shown after all learning tasks are finished
// ─────────────────────────────────────────────────────────────────────────────

class _AllTasksCompleteScreen extends StatelessWidget {
  const _AllTasksCompleteScreen({
    required this.completedCount,
    required this.onRestart,
  });

  final int completedCount;
  final VoidCallback onRestart;

  static const _accomplishments = [
    'Linked list node structure',
    'HEAD pointer and why it matters',
    'TAIL identification from the graph',
    'Creating connections between nodes',
    'Traversal order via pointer chain',
  ];

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 520),
          child: GlassCard(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Trophy icon
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: AppColors.lime.withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                    border: Border.all(
                        color: AppColors.lime.withValues(alpha: 0.45),
                        width: 2),
                  ),
                  child: const Icon(Icons.emoji_events_rounded,
                      color: AppColors.lime, size: 44),
                ),
                const SizedBox(height: 20),

                // Title
                const Text(
                  'Linked List Basics Complete!',
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  'You completed $completedCount / ${kLinkedListTasks.length} '
                  'learning tasks.',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                      color: AppColors.textSecondary,
                      height: 1.5,
                      fontSize: 13),
                ),
                const SizedBox(height: 22),

                // Accomplishments checklist
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.lime.withValues(alpha: 0.06),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                        color: AppColors.lime.withValues(alpha: 0.25)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'WHAT YOU LEARNED',
                        style: TextStyle(
                          color: AppColors.lime,
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.9,
                        ),
                      ),
                      const SizedBox(height: 12),
                      ..._accomplishments.map(
                        (item) => Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Icon(Icons.check_circle_rounded,
                                  color: AppColors.lime, size: 16),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  item,
                                  style: const TextStyle(
                                    color: AppColors.textPrimary,
                                    fontSize: 13,
                                    height: 1.4,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Primary: Start Assessment
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) => const LinkedListAssessmentScreen(),
                        ),
                      );
                    },
                    icon: const Icon(Icons.play_arrow_rounded),
                    label: const Text('Start Assessment'),
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.lime,
                      foregroundColor: AppColors.backgroundTop,
                      padding: const EdgeInsets.symmetric(vertical: 15),
                    ),
                  ),
                ),
                const SizedBox(height: 10),

                // Secondary: Practice Again
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: onRestart,
                    icon: const Icon(Icons.replay_rounded, size: 18),
                    label: const Text('Practice Again'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.cyan,
                      side: BorderSide(
                          color: AppColors.cyan.withValues(alpha: 0.45)),
                      padding: const EdgeInsets.symmetric(vertical: 13),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
