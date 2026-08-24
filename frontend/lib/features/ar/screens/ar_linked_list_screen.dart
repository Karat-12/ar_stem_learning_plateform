import 'dart:async';
import 'dart:math' as math;

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/network/api_client.dart';
import '../../../core/theme/app_colors.dart';
import '../../../features/assessments/linked_list_assessment/models/validation_result.dart';
import '../../../features/assessments/linked_list_assessment/services/linked_list_assessment_service.dart';
import '../../../features/linked_list/models/linked_list_task.dart';
import '../../../features/linked_list/models/linked_list_workspace_state.dart';
import '../../../features/misconceptions/models/record_misconception_request.dart';
import '../../../features/misconceptions/services/misconception_service.dart';
import '../../../features/progress/providers/progress_provider.dart';
import '../../../features/sessions/providers/session_provider.dart';

// ─────────────────────────────────────────────────────────────────────────────
// ArLinkedListScreen — public entry point
// ─────────────────────────────────────────────────────────────────────────────

/// Camera-based AR Linked List **learning** screen.
///
/// Phase 4: the student now constructs a real linked list, backed by the
/// shared [LinkedListWorkspaceState] + [LinkedListAssessmentService] engine
/// already used by the 2D construction workspace.
///
/// Architecture:
///   Logical layer → [LinkedListWorkspaceState] + [LinkedListGraph]
///   Visual layer  → [_arPositions] map of nodeId → screen [Offset]
///   Camera layer  → [CameraController] (rear camera, no ARCore)
///
/// The logical graph is the single source of truth.
/// Screen positions are only used for rendering nodes on the camera feed.
///
/// Optional [initialTaskId]: when set, opens directly to that task in
/// targeted-practice mode (same pattern as the 2D construction screen).
class ArLinkedListScreen extends StatefulWidget {
  const ArLinkedListScreen({super.key, this.initialTaskId});

  final String? initialTaskId;

  @override
  State<ArLinkedListScreen> createState() => _ArLinkedListScreenState();
}

class _ArLinkedListScreenState extends State<ArLinkedListScreen>
    with TickerProviderStateMixin, WidgetsBindingObserver {
  // ── Services ──────────────────────────────────────────────────────────────
  final _service = LinkedListAssessmentService();

  // ── Camera ────────────────────────────────────────────────────────────────
  CameraController? _cameraController;
  bool _cameraReady = false;
  String? _cameraError;

  // ── Float animation ───────────────────────────────────────────────────────
  late final AnimationController _floatController;
  late final Animation<double> _floatAnimation;

  // ── Drag-to-rotate Y axis (visual only) ───────────────────────────────────
  double _yRotation = 0.0;

  // ── Logical layer (shared with 2D workspace) ───────────────────────────────
  LinkedListWorkspaceState _state = LinkedListWorkspaceState.initial();

  // ── Visual layer: nodeId → screen Offset within the AR canvas ────────────
  // Offsets are pre-assigned in a horizontal row when a node is placed.
  // They are purely cosmetic — the logical graph is the source of truth.
  final Map<int, Offset> _arPositions = {};

  // ── AR interaction state ──────────────────────────────────────────────────

  /// The node ID currently selected from the palette, waiting to be placed.
  /// Null when no node is pending placement.
  int? _pendingPlacementNodeId;

  // ── Targeted mode ─────────────────────────────────────────────────────────
  bool _isTargetedMode = false;

  // ── Misconception deduplication ───────────────────────────────────────────
  String? _lastRecordedMisconceptionCode;

  // ── Transient toast ───────────────────────────────────────────────────────
  String? _toastMessage;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    _floatController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat(reverse: true);
    _floatAnimation = Tween<double>(begin: -6.0, end: 6.0).animate(
      CurvedAnimation(parent: _floatController, curve: Curves.easeInOut),
    );

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
    _initCamera();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _floatController.dispose();
    _cameraController?.dispose();
    _endSession();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final ctrl = _cameraController;
    if (ctrl == null || !ctrl.value.isInitialized) return;
    if (state == AppLifecycleState.inactive ||
        state == AppLifecycleState.paused) {
      ctrl.dispose();
      _cameraController = null;
      if (mounted) setState(() => _cameraReady = false);
    } else if (state == AppLifecycleState.resumed) {
      _initCamera();
    }
  }

  // ── Camera ────────────────────────────────────────────────────────────────

  Future<void> _initCamera() async {
    try {
      final cameras = await availableCameras();
      if (cameras.isEmpty) {
        if (mounted) setState(() => _cameraError = 'No cameras found.');
        return;
      }
      final rear = cameras.firstWhere(
        (c) => c.lensDirection == CameraLensDirection.back,
        orElse: () => cameras.first,
      );
      final ctrl = CameraController(
        rear, ResolutionPreset.high,
        enableAudio: false,
        imageFormatGroup: ImageFormatGroup.jpeg,
      );
      await ctrl.initialize();
      if (!mounted) { await ctrl.dispose(); return; }
      setState(() {
        _cameraController = ctrl;
        _cameraReady = true;
        _cameraError = null;
      });
    } catch (e) {
      if (mounted) {
        setState(() {
          _cameraError = 'Camera unavailable: ${e.toString()}';
          _cameraReady = false;
        });
      }
    }
  }

  // ── Session lifecycle ─────────────────────────────────────────────────────

  Future<void> _startSession() async {
    try {
      final sp = context.read<SessionProvider>();
      await sp.startSession(
        domainCode: 'DSA',
        topicCode: 'DSA_LINKED_LIST',
        activityCode: 'ar_workspace',
      );
      if (!mounted) return;
      final active = context.read<SessionProvider>().activeSession;
      if (active != null) {
        setState(() => _state = _state.copyWith(sessionId: active.id));
      }
    } catch (e) {
      debugPrint('AR session start failed: $e');
    }
  }

  Future<void> _endSession() async {
    try {
      await context.read<SessionProvider>().endSession();
    } catch (e) {
      debugPrint('AR session end failed: $e');
    }
  }

  // ── Task management ───────────────────────────────────────────────────────

  void _loadTask(LinkedListTask task) {
    _arPositions.clear();
    _pendingPlacementNodeId = null;
    _lastRecordedMisconceptionCode = null;
    setState(() {
      _state = _state.loadTask(task);
      _toastMessage = null;
    });
  }

  void _onNextTask() {
    if (_isTargetedMode) {
      setState(() => _state = _state.copyWith(
            currentTaskIndex: kLinkedListTasks.length,
          ));
      return;
    }
    final next = _state.currentTaskIndex + 1;
    if (next >= kLinkedListTasks.length) {
      setState(() => _state = _state.copyWith(
            currentTaskIndex: kLinkedListTasks.length,
          ));
      return;
    }
    _loadTask(kLinkedListTasks[next]);
  }

  // ── Node placement ────────────────────────────────────────────────────────

  /// Called when the student taps the camera view while a node is pending.
  ///
  /// Assigns a pre-calculated slot position so nodes are arranged in a
  /// readable horizontal row, regardless of where the student taps.
  /// The tap position itself is not used for layout — it is the gesture
  /// that confirms the student's intent to place the node.
  void _onArCanvasTapped(TapUpDetails details, Size canvasSize) {
    if (_pendingPlacementNodeId == null) {
      _showToast('Select a node from the tray first.');
      return;
    }
    if (!_state.paletteNodeIds.contains(_pendingPlacementNodeId!)) {
      _pendingPlacementNodeId = null;
      return;
    }

    final id = _pendingPlacementNodeId!;
    final task = kLinkedListTasks[_state.currentTaskIndex];
    final placedCount = _state.placedNodeIds.length;
    final total = task.nodeValues.length;

    // Pre-assigned horizontal slot: evenly spaced across the canvas centre.
    // This guarantees nodes are always visible and connected by arrows.
    const nodeW = 72.0;
    const spacing = 90.0;
    final rowWidth = total * nodeW + (total - 1) * (spacing - nodeW);
    final startX = (canvasSize.width - rowWidth) / 2;
    final slotX = startX + placedCount * spacing;
    final slotY = canvasSize.height * 0.42; // upper-centre of the view

    setState(() {
      _arPositions[id] = Offset(slotX, slotY);
      _state = _state.copyWith(
        paletteNodeIds:
            _state.paletteNodeIds.where((n) => n != id).toList(),
        placedNodeIds: [..._state.placedNodeIds, id],
      );
      _pendingPlacementNodeId = null;
    });
  }

  // ── Node tap (select / deselect / connect) ────────────────────────────────

  void _onPlacedNodeTapped(int id) {
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

    // Attempt to create a connection selected → id.
    final simulated = _state.currentGraph.withPointer(fromId: selected, toId: id);
    if (simulated.hasCycle()) {
      final fl = _state.currentGraph.labelOf(selected);
      final tl = _state.currentGraph.labelOf(id);
      _showToast('$fl → $tl would create a cycle. Linked lists must not loop.');
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

  // ── Long-press → context menu (HEAD / disconnect) ─────────────────────────

  void _onPlacedNodeLongPress(int id) {
    if (!_state.placedNodeIds.contains(id)) return;
    _showNodeActionSheet(id);
  }

  void _showNodeActionSheet(int nodeId) {
    final label = _state.currentGraph.labelOf(nodeId);
    final isHead = _state.currentGraph.headId == nodeId;
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
            Text('Node $label',
                style: Theme.of(context)
                    .textTheme
                    .titleLarge
                    ?.copyWith(color: AppColors.textPrimary)),
            const SizedBox(height: 6),
            Text('What would you like to do?',
                style: const TextStyle(
                    color: AppColors.textSecondary, fontSize: 14)),
            const SizedBox(height: 20),
            if (!isHead)
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
            if (isHead) ...[
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: AppColors.lime.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                      color: AppColors.lime.withValues(alpha: 0.35)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.flag_rounded,
                        color: AppColors.lime, size: 16),
                    const SizedBox(width: 8),
                    Text('This node is already HEAD',
                        style: TextStyle(
                            color: AppColors.lime.withValues(alpha: 0.85),
                            fontSize: 13)),
                  ],
                ),
              ),
            ],
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

  // ── VERIFY ────────────────────────────────────────────────────────────────

  void _onVerify() {
    final task = kLinkedListTasks[_state.currentTaskIndex];
    final raw = _service.validateBuild(_state.currentGraph, task.expectedGraph);

    final hintIndex =
        _state.hintsShownCount.clamp(0, task.hints.length - 1);
    final displayHint = (!raw.isValid && task.hints.isNotEmpty)
        ? task.hints[hintIndex]
        : raw.hint;

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
        : math.min(
            _state.hintsShownCount + 1,
            math.max(0, task.hints.length - 1),
          );

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

    if (raw.hasMisconception) _recordMisconceptionIfNeeded(raw);
  }

  // ── Misconception recording (same pipeline as 2D workspace) ───────────────

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
      debugPrint('AR misconception recording failed: $e');
    }
  }

  // ── Reset ─────────────────────────────────────────────────────────────────

  void _onReset() {
    final task = kLinkedListTasks[_state.currentTaskIndex];
    _loadTask(task);
  }

  // ── Toast ─────────────────────────────────────────────────────────────────

  void _showToast(String message) {
    setState(() => _toastMessage = message);
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) setState(() => _toastMessage = null);
    });
  }

  // ── Drag-rotate ───────────────────────────────────────────────────────────

  void _onDragUpdate(DragUpdateDetails d) {
    const maxRad = 15.0 * math.pi / 180.0;
    setState(() {
      _yRotation =
          (_yRotation + d.delta.dx * 0.008).clamp(-maxRad, maxRad);
    });
  }

  void _onDragEnd(DragEndDetails _) {
    final start = _yRotation;
    final ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    final anim = Tween<double>(begin: start, end: 0.0).animate(
      CurvedAnimation(parent: ctrl, curve: Curves.easeOut),
    );
    anim.addListener(() {
      if (mounted) setState(() => _yRotation = anim.value);
    });
    ctrl.forward().then((_) => ctrl.dispose());
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    // ── All-tasks-complete sentinel ──────────────────────────────────────────
    if (_state.currentTaskIndex >= kLinkedListTasks.length) {
      return _isTargetedMode
          ? _ArTargetedCompleteScreen(
              onPracticeAgain: () {
                final taskId = widget.initialTaskId;
                final task = taskId == null
                    ? kLinkedListTasks[0]
                    : kLinkedListTasks.firstWhere(
                        (t) => t.id == taskId,
                        orElse: () => kLinkedListTasks[0],
                      );
                _loadTask(task);
              },
            )
          : _ArAllCompleteScreen(
              completedCount: _state.completedTaskCount,
              onRestart: () => _loadTask(kLinkedListTasks[0]),
            );
    }

    final task = kLinkedListTasks[_state.currentTaskIndex];
    final tailId = _state.tailNodeId;

    // Derive the next-pointer map for the arrow painter.
    final nextPointers = <int, int?>{
      for (final id in _state.placedNodeIds)
        id: _state.currentGraph.nextOf(id),
    };

    return Scaffold(
      backgroundColor: Colors.black,
      body: LayoutBuilder(builder: (context, constraints) {
        final canvasSize =
            Size(constraints.maxWidth, constraints.maxHeight);

        return Stack(
          children: [
            // ── 1. Camera feed ──────────────────────────────────────────
            _CameraBackground(
              controller: _cameraController,
              isReady: _cameraReady,
              error: _cameraError,
              onRetry: _initCamera,
            ),

            // ── 2. AR canvas (tap to place) ─────────────────────────────
            if (_cameraReady || _cameraError != null)
              Positioned.fill(
                child: GestureDetector(
                  onHorizontalDragUpdate: _onDragUpdate,
                  onHorizontalDragEnd: _onDragEnd,
                  onTapUp: _pendingPlacementNodeId != null
                      ? (d) => _onArCanvasTapped(d, canvasSize)
                      : null,
                  behavior: HitTestBehavior.translucent,
                  child: _ArSceneLayer(
                    floatAnimation: _floatAnimation,
                    yRotation: _yRotation,
                    state: _state,
                    arPositions: _arPositions,
                    nextPointers: nextPointers,
                    tailId: tailId,
                    canvasSize: canvasSize,
                    onNodeTap: _onPlacedNodeTapped,
                    onNodeLongPress: _onPlacedNodeLongPress,
                  ),
                ),
              ),

            // ── 3. Placement hint overlay ───────────────────────────────
            if (_pendingPlacementNodeId != null)
              Positioned.fill(
                child: IgnorePointer(
                  child: Container(
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: AppColors.cyan.withValues(alpha: 0.50),
                        width: 2.5,
                      ),
                    ),
                    child: Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.touch_app_rounded,
                              color: AppColors.cyan, size: 40),
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 8),
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: 0.65),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                  color: AppColors.cyan
                                      .withValues(alpha: 0.45)),
                            ),
                            child: Text(
                              'Tap to place node '
                              '${_state.currentGraph.labelOf(_pendingPlacementNodeId!)}',
                              style: const TextStyle(
                                color: AppColors.cyan,
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),

            // ── 4. HUD header ───────────────────────────────────────────
            SafeArea(
              child: _ArLearningHeader(
                task: task,
                cameraReady: _cameraReady,
                currentIndex: _state.currentTaskIndex,
                totalTasks: kLinkedListTasks.length,
                isTargetedMode: _isTargetedMode,
              ),
            ),

            // ── 5. Task complete success panel ──────────────────────────
            if (_state.isTaskComplete)
              Positioned(
                left: 16,
                right: 16,
                bottom: 160,
                child: _ArSuccessPanel(
                  task: task,
                  state: _state,
                  isLast: _state.currentTaskIndex >=
                      kLinkedListTasks.length - 1,
                  onNextTask: _onNextTask,
                ),
              ),

            // ── 6. Feedback panel (verify result) ─────────────────────
            if (!_state.isTaskComplete && _state.hintsShownCount > 0)
              Positioned(
                left: 16,
                right: 16,
                bottom: 160,
                child: _ArFeedbackPanel(
                    validation: _state.lastValidation),
              ),

            // ── 7. Toast notification ──────────────────────────────────
            if (_toastMessage != null)
              Positioned(
                left: 16,
                right: 16,
                bottom: 160,
                child: _ToastBanner(message: _toastMessage!),
              ),

            // ── 8. Bottom controls ─────────────────────────────────────
            if (!_state.isTaskComplete)
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: SafeArea(
                  child: _ArBottomControls(
                    state: _state,
                    pendingNodeId: _pendingPlacementNodeId,
                    task: task,
                    onSelectPalette: (id) {
                      setState(() => _pendingPlacementNodeId =
                          _pendingPlacementNodeId == id ? null : id);
                    },
                    onVerify: _onVerify,
                    onReset: _onReset,
                  ),
                ),
              ),
          ],
        );
      }),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _ArSceneLayer — the live AR nodes drawn over the camera feed
// ─────────────────────────────────────────────────────────────────────────────

class _ArSceneLayer extends StatelessWidget {
  const _ArSceneLayer({
    required this.floatAnimation,
    required this.yRotation,
    required this.state,
    required this.arPositions,
    required this.nextPointers,
    required this.tailId,
    required this.canvasSize,
    required this.onNodeTap,
    required this.onNodeLongPress,
  });

  final Animation<double> floatAnimation;
  final double yRotation;
  final LinkedListWorkspaceState state;
  final Map<int, Offset> arPositions;
  final Map<int, int?> nextPointers;
  final int? tailId;
  final Size canvasSize;
  final void Function(int) onNodeTap;
  final void Function(int) onNodeLongPress;

  @override
  Widget build(BuildContext context) {
    if (arPositions.isEmpty) {
      // Nothing placed yet — show a subtle hint.
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 40),
          child: Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.55),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                  color: AppColors.cyan.withValues(alpha: 0.30)),
            ),
            child: const Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.touch_app_outlined,
                    color: AppColors.cyan, size: 28),
                SizedBox(height: 8),
                Text(
                  'Select a node below,\nthen tap here to place it.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 13,
                      height: 1.5),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return AnimatedBuilder(
      animation: floatAnimation,
      builder: (context, _) {
        final floatY = floatAnimation.value;
        return Transform(
          alignment: Alignment.center,
          transform: Matrix4.identity()
            ..setEntry(3, 2, 0.0008)
            ..rotateX(0.10)
            ..rotateY(yRotation),
          child: Stack(
            children: [
              // Arrow layer (CustomPaint behind nodes)
              Positioned.fill(
                child: CustomPaint(
                  painter: _ArArrowPainter(
                    arPositions: arPositions,
                    nextPointers: nextPointers,
                    headId: state.currentGraph.headId,
                  ),
                ),
              ),
              // Floor effect
              Positioned(
                left: 0,
                right: 0,
                bottom: canvasSize.height * 0.35,
                child: _FloorEffect(floatY: floatY),
              ),
              // Placed nodes
              for (final id in state.placedNodeIds)
                if (arPositions.containsKey(id))
                  _ArPlacedNode(
                    nodeId: id,
                    label: state.currentGraph.labelOf(id),
                    position: arPositions[id]! +
                        Offset(0, floatY + math.sin(id * 0.9) * 3.0),
                    isHead: state.currentGraph.headId == id,
                    isTail: tailId == id,
                    isSelected: state.selectedNodeId == id,
                    onTap: onNodeTap,
                    onLongPress: onNodeLongPress,
                  ),
            ],
          ),
        );
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _ArPlacedNode — a single interactive 3D-style AR node
// ─────────────────────────────────────────────────────────────────────────────

class _ArPlacedNode extends StatelessWidget {
  const _ArPlacedNode({
    required this.nodeId,
    required this.label,
    required this.position,
    required this.isHead,
    required this.isTail,
    required this.isSelected,
    required this.onTap,
    required this.onLongPress,
  });

  final int nodeId;
  final String label;
  final Offset position;
  final bool isHead;
  final bool isTail;
  final bool isSelected;
  final void Function(int) onTap;
  final void Function(int) onLongPress;

  static const double _sz = 64.0;
  static const double _depth = 7.0;

  Color get _color {
    if (isHead) return AppColors.violet;
    if (isTail) return AppColors.lime;
    return AppColors.cyan;
  }

  @override
  Widget build(BuildContext context) {
    final c = _color;
    final tilt = isSelected
        ? (Matrix4.identity()
          ..setEntry(3, 2, 0.001)
          ..rotateX(-0.18)
          ..rotateY(0.12))
        : Matrix4.identity();

    return Positioned(
      left: position.dx - _sz / 2,
      top: position.dy - _sz / 2,
      child: GestureDetector(
        onTap: () => onTap(nodeId),
        onLongPress: () => onLongPress(nodeId),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Badge above node
            if (isHead || isTail) ...[
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: c.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: c.withValues(alpha: 0.55)),
                  boxShadow: [
                    BoxShadow(
                        color: c.withValues(alpha: 0.35), blurRadius: 8)
                  ],
                ),
                child: Text(
                  isHead ? 'HEAD' : 'TAIL',
                  style: TextStyle(
                    color: c,
                    fontSize: 9,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.0,
                  ),
                ),
              ),
              const SizedBox(height: 3),
              Icon(Icons.arrow_downward_rounded,
                  color: c.withValues(alpha: 0.8), size: 14),
              const SizedBox(height: 2),
            ],
            // 3D node body
            Transform(
              alignment: Alignment.center,
              transform: tilt,
              child: SizedBox(
                width: _sz + _depth,
                height: _sz + _depth + 6,
                child: Stack(
                  alignment: Alignment.topLeft,
                  children: [
                    // Shadow
                    Positioned(
                      bottom: 0,
                      left: _depth * 0.5,
                      child: Container(
                        width: _sz * 0.85,
                        height: 8,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(_sz),
                          boxShadow: [
                            BoxShadow(
                              color: c.withValues(
                                  alpha: isSelected ? 0.45 : 0.22),
                              blurRadius: isSelected ? 18 : 10,
                              spreadRadius: isSelected ? 3 : 1,
                            ),
                          ],
                        ),
                      ),
                    ),
                    // Depth layer
                    Positioned(
                      left: _depth * 0.5,
                      top: _depth * 0.8,
                      child: Container(
                        width: _sz,
                        height: _sz,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: c.withValues(alpha: 0.25),
                          border: Border.all(
                            color: c.withValues(alpha: 0.35),
                            width: 1.5,
                          ),
                        ),
                      ),
                    ),
                    // Front face
                    Positioned(
                      left: 0,
                      top: 0,
                      child: Container(
                        width: _sz,
                        height: _sz,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: RadialGradient(
                            center: const Alignment(-0.3, -0.4),
                            radius: 0.85,
                            colors: [
                              Color.lerp(c, Colors.white, 0.30)!,
                              c,
                              c.withValues(alpha: 0.80),
                              Color.lerp(c, Colors.black, 0.40)!,
                            ],
                            stops: const [0.0, 0.35, 0.70, 1.0],
                          ),
                          border: Border.all(
                            color: isSelected
                                ? Colors.white.withValues(alpha: 0.6)
                                : c.withValues(alpha: 0.9),
                            width: isSelected ? 2.0 : 1.5,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: c.withValues(
                                  alpha: isSelected ? 0.70 : 0.38),
                              blurRadius: isSelected ? 24 : 12,
                              spreadRadius: isSelected ? 3 : 0,
                            ),
                          ],
                        ),
                        child: Stack(
                          children: [
                            Center(
                              child: Text(
                                label,
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 15,
                                  fontWeight: FontWeight.w900,
                                  shadows: [
                                    Shadow(
                                      color: c.withValues(alpha: 0.8),
                                      blurRadius: 8,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            Positioned(
                              top: _sz * 0.10,
                              left: _sz * 0.14,
                              child: Container(
                                width: _sz * 0.38,
                                height: _sz * 0.18,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(_sz),
                                  gradient: LinearGradient(colors: [
                                    Colors.white.withValues(alpha: 0.55),
                                    Colors.white.withValues(alpha: 0.0),
                                  ]),
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
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _ArArrowPainter — draws connection arrows between placed nodes
// ─────────────────────────────────────────────────────────────────────────────

class _ArArrowPainter extends CustomPainter {
  const _ArArrowPainter({
    required this.arPositions,
    required this.nextPointers,
    required this.headId,
  });

  final Map<int, Offset> arPositions;
  final Map<int, int?> nextPointers;
  final int? headId;

  @override
  void paint(Canvas canvas, Size size) {
    if (arPositions.length < 2) return;

    for (final entry in nextPointers.entries) {
      final fromId = entry.key;
      final toId = entry.value;
      if (toId == null) continue;
      final from = arPositions[fromId];
      final to = arPositions[toId];
      if (from == null || to == null) continue;

      final isHead = fromId == headId;
      final color = isHead ? AppColors.lime : AppColors.cyan;

      // Start at the right edge of the from-node, end at the left of the to-node.
      const nodeR = 32.0;
      final start = from + Offset(nodeR, 0);
      final end = to - Offset(nodeR, 0);

      final glowPaint = Paint()
        ..color = color.withValues(alpha: 0.25)
        ..strokeWidth = 7
        ..strokeCap = StrokeCap.round
        ..style = PaintingStyle.stroke
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5);
      canvas.drawLine(start, end, glowPaint);

      final linePaint = Paint()
        ..color = color.withValues(alpha: 0.85)
        ..strokeWidth = 2.5
        ..strokeCap = StrokeCap.round
        ..style = PaintingStyle.stroke;
      canvas.drawLine(start, end, linePaint);

      // Arrowhead
      final angle = math.atan2(end.dy - start.dy, end.dx - start.dx);
      final p1 = end -
          Offset(math.cos(angle - 0.42) * 12, math.sin(angle - 0.42) * 12);
      final p2 = end -
          Offset(math.cos(angle + 0.42) * 12, math.sin(angle + 0.42) * 12);
      final arrowPaint = Paint()
        ..color = color
        ..strokeWidth = 2.5
        ..strokeCap = StrokeCap.round
        ..style = PaintingStyle.stroke;
      canvas.drawLine(end, p1, arrowPaint);
      canvas.drawLine(end, p2, arrowPaint);
    }
  }

  @override
  bool shouldRepaint(_ArArrowPainter old) =>
      old.arPositions != arPositions ||
      old.nextPointers != nextPointers ||
      old.headId != headId;
}

// ─────────────────────────────────────────────────────────────────────────────
// _ArLearningHeader — top HUD: task label + camera indicator
// ─────────────────────────────────────────────────────────────────────────────

class _ArLearningHeader extends StatelessWidget {
  const _ArLearningHeader({
    required this.task,
    required this.cameraReady,
    required this.currentIndex,
    required this.totalTasks,
    required this.isTargetedMode,
  });

  final LinkedListTask task;
  final bool cameraReady;
  final int currentIndex;
  final int totalTasks;
  final bool isTargetedMode;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              GestureDetector(
                onTap: () {
                  if (Navigator.of(context).canPop()) {
                    Navigator.of(context).pop();
                  }
                },
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.55),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                        color: AppColors.cyan.withValues(alpha: 0.45)),
                  ),
                  child: const Icon(Icons.arrow_back_rounded,
                      color: AppColors.textPrimary, size: 20),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'AR LINKED LIST',
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.4,
                      ),
                    ),
                    Text(
                      isTargetedMode
                          ? 'Targeted Practice'
                          : 'Task ${currentIndex + 1} of $totalTasks',
                      style: TextStyle(
                        color: isTargetedMode
                            ? AppColors.orange
                            : AppColors.textSecondary,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
              // Camera indicator
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.60),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: (cameraReady ? AppColors.lime : AppColors.pink)
                        .withValues(alpha: 0.5),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 7,
                      height: 7,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: cameraReady ? AppColors.lime : AppColors.pink,
                        boxShadow: [
                          BoxShadow(
                            color:
                                (cameraReady ? AppColors.lime : AppColors.pink)
                                    .withValues(alpha: 0.7),
                            blurRadius: 6,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 5),
                    Text(
                      cameraReady ? 'LIVE' : 'OFF',
                      style: TextStyle(
                        color: cameraReady ? AppColors.lime : AppColors.pink,
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.8,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          // Compact concept strip
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.55),
              borderRadius: BorderRadius.circular(12),
              border:
                  Border.all(color: AppColors.violet.withValues(alpha: 0.30)),
            ),
            child: Text(
              task.title,
              style: const TextStyle(
                color: AppColors.violet,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _ArBottomControls — node palette tray + VERIFY + Reset
// ─────────────────────────────────────────────────────────────────────────────

class _ArBottomControls extends StatelessWidget {
  const _ArBottomControls({
    required this.state,
    required this.pendingNodeId,
    required this.task,
    required this.onSelectPalette,
    required this.onVerify,
    required this.onReset,
  });

  final LinkedListWorkspaceState state;
  final int? pendingNodeId;
  final LinkedListTask task;
  final void Function(int) onSelectPalette;
  final VoidCallback onVerify;
  final VoidCallback onReset;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.80),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.cyan.withValues(alpha: 0.25)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // ── Connection status row ──────────────────────────────────────
          _ArStatusRow(state: state),
          const SizedBox(height: 10),

          // ── Palette: unplaced nodes ────────────────────────────────────
          if (state.paletteNodeIds.isNotEmpty) ...[
            Row(
              children: [
                const Icon(Icons.add_circle_outline_rounded,
                    color: AppColors.cyan, size: 13),
                const SizedBox(width: 6),
                Text(
                  'Tap a node, then tap the camera view to place it',
                  style: TextStyle(
                    color: AppColors.textSecondary.withValues(alpha: 0.8),
                    fontSize: 11,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: state.paletteNodeIds.map((id) {
                final label = state.currentGraph.labelOf(id);
                final isPending = pendingNodeId == id;
                return GestureDetector(
                  onTap: () => onSelectPalette(id),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 10),
                    decoration: BoxDecoration(
                      color: isPending
                          ? AppColors.cyan.withValues(alpha: 0.22)
                          : AppColors.glass,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isPending
                            ? AppColors.cyan
                            : AppColors.cyan.withValues(alpha: 0.30),
                        width: isPending ? 2.0 : 1.0,
                      ),
                      boxShadow: isPending
                          ? [
                              BoxShadow(
                                  color: AppColors.cyan
                                      .withValues(alpha: 0.35),
                                  blurRadius: 12)
                            ]
                          : [],
                    ),
                    child: Text(
                      label,
                      style: TextStyle(
                        color: isPending
                            ? AppColors.cyan
                            : AppColors.textPrimary,
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 10),
          ],

          // ── Interaction guide ──────────────────────────────────────────
          _ArInteractionGuide(state: state),
          const SizedBox(height: 10),

          // ── Action buttons ─────────────────────────────────────────────
          Row(
            children: [
              // Reset
              _ArActionBtn(
                label: 'Reset',
                icon: Icons.refresh_rounded,
                color: AppColors.textSecondary,
                isActive: false,
                onTap: onReset,
              ),
              const SizedBox(width: 8),
              // VERIFY (expanded, prominent)
              Expanded(
                child: FilledButton.icon(
                  onPressed: state.canVerify ? onVerify : null,
                  icon: const Icon(Icons.check_rounded),
                  label: const Text('Verify Structure'),
                  style: FilledButton.styleFrom(
                    backgroundColor:
                        state.canVerify ? AppColors.lime : AppColors.glass,
                    foregroundColor: state.canVerify
                        ? AppColors.backgroundTop
                        : AppColors.textSecondary,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
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
// _ArStatusRow — mini HEAD/TAIL/connections status bar
// ─────────────────────────────────────────────────────────────────────────────

class _ArStatusRow extends StatelessWidget {
  const _ArStatusRow({required this.state});
  final LinkedListWorkspaceState state;

  @override
  Widget build(BuildContext context) {
    final headSet = state.currentGraph.headId != null;
    final allPlaced = state.paletteNodeIds.isEmpty;
    final tailId = state.tailNodeId;

    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: [
        _StatusPip(label: 'Placed', done: allPlaced),
        _StatusPip(label: 'HEAD', done: headSet),
        _StatusPip(label: 'TAIL', done: tailId != null),
        if (state.selectedNodeId != null)
          _StatusPip(
            label:
                'Connecting from ${state.currentGraph.labelOf(state.selectedNodeId!)}…',
            done: false,
            accent: AppColors.orange,
          ),
      ],
    );
  }
}

class _StatusPip extends StatelessWidget {
  const _StatusPip({
    required this.label,
    required this.done,
    this.accent,
  });
  final String label;
  final bool done;
  final Color? accent;

  @override
  Widget build(BuildContext context) {
    final c = accent ?? (done ? AppColors.lime : AppColors.textSecondary);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: c.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: c.withValues(alpha: 0.35)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            done ? Icons.check_circle_rounded : Icons.radio_button_unchecked_rounded,
            color: c,
            size: 11,
          ),
          const SizedBox(width: 4),
          Text(label,
              style: TextStyle(
                  color: c, fontSize: 10, fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _ArInteractionGuide — dynamic step hints
// ─────────────────────────────────────────────────────────────────────────────

class _ArInteractionGuide extends StatelessWidget {
  const _ArInteractionGuide({required this.state});
  final LinkedListWorkspaceState state;

  @override
  Widget build(BuildContext context) {
    final allPlaced = state.paletteNodeIds.isEmpty;
    final headSet = state.currentGraph.headId != null;
    final hasConnections = state.placedNodeIds.any(
      (id) => state.currentGraph.nextOf(id) != null,
    );
    final connecting = state.selectedNodeId != null;

    String step;
    if (!allPlaced) {
      step = 'Tap a node chip above, then tap the camera view to place it.';
    } else if (!headSet) {
      step = 'Long-press a node to mark it as HEAD.';
    } else if (connecting) {
      final fromLabel =
          state.currentGraph.labelOf(state.selectedNodeId!);
      step = 'Tap another node to connect $fromLabel → it.';
    } else if (!hasConnections) {
      step = 'Tap node A, then node B to create A → B connection.';
    } else {
      step = 'Finish connecting all nodes, then press Verify Structure.';
    }

    return Row(
      children: [
        const Icon(Icons.info_outline_rounded,
            color: AppColors.textSecondary, size: 14),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            step,
            style: const TextStyle(
                color: AppColors.textSecondary, fontSize: 11, height: 1.4),
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _ArActionBtn — small bottom action button
// ─────────────────────────────────────────────────────────────────────────────

class _ArActionBtn extends StatelessWidget {
  const _ArActionBtn({
    required this.label,
    required this.icon,
    required this.color,
    required this.isActive,
    required this.onTap,
  });
  final String label;
  final IconData icon;
  final Color color;
  final bool isActive;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: isActive
              ? color.withValues(alpha: 0.18)
              : Colors.white.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isActive
                ? color.withValues(alpha: 0.8)
                : color.withValues(alpha: 0.25),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 16),
            const SizedBox(width: 6),
            Text(label,
                style: TextStyle(
                    color: color,
                    fontSize: 11,
                    fontWeight: FontWeight.w700)),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _ArFeedbackPanel — shown after a failed VERIFY
// ─────────────────────────────────────────────────────────────────────────────

class _ArFeedbackPanel extends StatelessWidget {
  const _ArFeedbackPanel({required this.validation});
  final ValidationResult validation;

  @override
  Widget build(BuildContext context) {
    final color = validation.isValid ? AppColors.lime : AppColors.pink;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.82),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.55)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Icon(
                validation.isValid
                    ? Icons.check_circle_outline_rounded
                    : Icons.highlight_off_rounded,
                color: color,
                size: 18,
              ),
              const SizedBox(width: 8),
              Text(
                validation.isValid ? 'Correct!' : 'Not quite yet.',
                style: TextStyle(
                    color: color,
                    fontSize: 13,
                    fontWeight: FontWeight.w800),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            validation.hint,
            style: const TextStyle(
                color: AppColors.textPrimary, fontSize: 12, height: 1.5),
          ),
          if (!validation.isValid && validation.misconceptionTitle != null) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
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
// _ArSuccessPanel — shown when current task is correct
// ─────────────────────────────────────────────────────────────────────────────

class _ArSuccessPanel extends StatelessWidget {
  const _ArSuccessPanel({
    required this.task,
    required this.state,
    required this.isLast,
    required this.onNextTask,
  });

  final LinkedListTask task;
  final LinkedListWorkspaceState state;
  final bool isLast;
  final VoidCallback onNextTask;

  @override
  Widget build(BuildContext context) {
    // Build the traversal string from the logical graph.
    final order = state.currentGraph.traversalOrder();
    final chain = order
        .map((id) => state.currentGraph.labelOf(id))
        .join(' → ');

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.88),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.lime.withValues(alpha: 0.55)),
        boxShadow: [
          BoxShadow(
              color: AppColors.lime.withValues(alpha: 0.15), blurRadius: 20),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: AppColors.lime.withValues(alpha: 0.18),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.check_rounded,
                    color: AppColors.lime, size: 16),
              ),
              const SizedBox(width: 10),
              const Text('Correct!',
                  style: TextStyle(
                      color: AppColors.lime,
                      fontSize: 15,
                      fontWeight: FontWeight.w800)),
            ],
          ),
          const SizedBox(height: 10),
          // Traversal chain
          if (chain.isNotEmpty) ...[
            Text(
              chain,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 14,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 4),
          ],
          // HEAD / TAIL
          Text(
            'HEAD = ${state.currentGraph.labelOf(state.currentGraph.headId ?? -1)}'
            '  •  TAIL = ${state.currentGraph.labelOf(state.tailNodeId ?? -1)}',
            style: const TextStyle(
                color: AppColors.textSecondary, fontSize: 11),
          ),
          if (task.explanation.isNotEmpty) ...[
            const SizedBox(height: 10),
            Divider(
                color: AppColors.lime.withValues(alpha: 0.18), height: 1),
            const SizedBox(height: 10),
            Text(
              task.explanation,
              style: const TextStyle(
                  color: AppColors.textPrimary, fontSize: 12, height: 1.6),
            ),
          ],
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: onNextTask,
              icon: Icon(
                isLast
                    ? Icons.emoji_events_rounded
                    : Icons.arrow_forward_rounded,
              ),
              label: Text(isLast ? 'Complete Learning' : 'Next Task'),
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.lime,
                foregroundColor: AppColors.backgroundTop,
                padding: const EdgeInsets.symmetric(vertical: 13),
              ),
            ),
          ),
        ],
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
        color: AppColors.orange.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.orange.withValues(alpha: 0.45)),
      ),
      child: Row(
        children: [
          const Icon(Icons.warning_amber_rounded,
              color: AppColors.orange, size: 17),
          const SizedBox(width: 8),
          Expanded(
            child: Text(message,
                style: const TextStyle(
                    color: AppColors.orange, fontSize: 12, height: 1.4)),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _ArTargetedCompleteScreen — targeted practice done
// ─────────────────────────────────────────────────────────────────────────────

class _ArTargetedCompleteScreen extends StatelessWidget {
  const _ArTargetedCompleteScreen({required this.onPracticeAgain});
  final VoidCallback onPracticeAgain;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 400),
            child: Container(
              padding: const EdgeInsets.all(28),
              decoration: BoxDecoration(
                color: const Color(0xC4080B1D),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                    color: AppColors.cyan.withValues(alpha: 0.35)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      color: AppColors.cyan.withValues(alpha: 0.12),
                      shape: BoxShape.circle,
                      border: Border.all(
                          color: AppColors.cyan.withValues(alpha: 0.45),
                          width: 2),
                    ),
                    child: const Icon(Icons.verified_rounded,
                        color: AppColors.cyan, size: 34),
                  ),
                  const SizedBox(height: 18),
                  const Text('Concept Practiced!',
                      style: TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                      ),
                      textAlign: TextAlign.center),
                  const SizedBox(height: 8),
                  const Text(
                    'Your AR practice has been recorded. '
                    'You can practice again or return to the AI Coach.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        color: AppColors.textSecondary,
                        height: 1.55,
                        fontSize: 13),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: onPracticeAgain,
                      icon: const Icon(Icons.replay_rounded, size: 17),
                      label: const Text('Practice Again'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.cyan,
                        side: BorderSide(
                            color: AppColors.cyan.withValues(alpha: 0.45)),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: () =>
                          Navigator.of(context).maybePop(),
                      icon: const Icon(Icons.arrow_back_rounded, size: 17),
                      label: const Text('Back'),
                      style: FilledButton.styleFrom(
                        backgroundColor:
                            AppColors.violet.withValues(alpha: 0.18),
                        foregroundColor: AppColors.violet,
                        side: BorderSide(
                            color:
                                AppColors.violet.withValues(alpha: 0.45)),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _ArAllCompleteScreen — normal curriculum completion
// ─────────────────────────────────────────────────────────────────────────────

class _ArAllCompleteScreen extends StatelessWidget {
  const _ArAllCompleteScreen({
    required this.completedCount,
    required this.onRestart,
  });
  final int completedCount;
  final VoidCallback onRestart;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 400),
            child: Container(
              padding: const EdgeInsets.all(28),
              decoration: BoxDecoration(
                color: const Color(0xC4080B1D),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                    color: AppColors.lime.withValues(alpha: 0.40)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      color: AppColors.lime.withValues(alpha: 0.12),
                      shape: BoxShape.circle,
                      border: Border.all(
                          color: AppColors.lime.withValues(alpha: 0.45),
                          width: 2),
                    ),
                    child: const Icon(Icons.emoji_events_rounded,
                        color: AppColors.lime, size: 40),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'AR Learning Complete!',
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
                    'AR learning tasks.',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                        color: AppColors.textSecondary,
                        height: 1.5,
                        fontSize: 13),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: onRestart,
                      icon: const Icon(Icons.replay_rounded, size: 17),
                      label: const Text('Practice Again'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.cyan,
                        side: BorderSide(
                            color: AppColors.cyan.withValues(alpha: 0.45)),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: () =>
                          Navigator.of(context).maybePop(),
                      icon: const Icon(Icons.arrow_back_rounded, size: 17),
                      label: const Text('Back'),
                      style: FilledButton.styleFrom(
                        backgroundColor:
                            AppColors.lime.withValues(alpha: 0.18),
                        foregroundColor: AppColors.lime,
                        side: BorderSide(
                            color: AppColors.lime.withValues(alpha: 0.45)),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _CameraBackground  (unchanged from Phase 3)
// ─────────────────────────────────────────────────────────────────────────────

class _CameraBackground extends StatelessWidget {
  const _CameraBackground({
    required this.controller,
    required this.isReady,
    required this.error,
    required this.onRetry,
  });
  final CameraController? controller;
  final bool isReady;
  final String? error;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    if (error != null) {
      return _CameraErrorView(message: error!, onRetry: onRetry);
    }
    if (!isReady || controller == null) {
      return const _CameraLoadingView();
    }
    return SizedBox.expand(
      child: FittedBox(
        fit: BoxFit.cover,
        child: SizedBox(
          width: controller!.value.previewSize?.height ?? 1,
          height: controller!.value.previewSize?.width ?? 1,
          child: CameraPreview(controller!),
        ),
      ),
    );
  }
}

class _CameraLoadingView extends StatelessWidget {
  const _CameraLoadingView();
  @override
  Widget build(BuildContext context) => Container(
        color: const Color(0xFF050713),
        child: const Center(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            CircularProgressIndicator(color: AppColors.cyan),
            SizedBox(height: 16),
            Text('Initialising camera…',
                style: TextStyle(color: AppColors.textSecondary, fontSize: 14)),
          ]),
        ),
      );
}

class _CameraErrorView extends StatelessWidget {
  const _CameraErrorView({required this.message, required this.onRetry});
  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFF050713),
      padding: const EdgeInsets.all(32),
      child: Center(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          const Icon(Icons.videocam_off_rounded,
              color: AppColors.pink, size: 56),
          const SizedBox(height: 16),
          const Text('Camera unavailable',
              style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text(message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                  color: AppColors.textSecondary, fontSize: 13)),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.cyan,
                foregroundColor: const Color(0xFF050713)),
            onPressed: onRetry,
            icon: const Icon(Icons.refresh_rounded),
            label: const Text('Retry'),
          ),
        ]),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _FloorEffect  — elliptical shadow + faint perspective grid (unchanged)
// ─────────────────────────────────────────────────────────────────────────────

class _FloorEffect extends StatelessWidget {
  const _FloorEffect({required this.floatY});
  final double floatY;

  @override
  Widget build(BuildContext context) {
    final shadowAlpha = 0.18 + (floatY.abs() / 7.0) * 0.06;
    return SizedBox(
      width: 340,
      height: 36,
      child: CustomPaint(painter: _FloorPainter(shadowAlpha: shadowAlpha)),
    );
  }
}

class _FloorPainter extends CustomPainter {
  const _FloorPainter({required this.shadowAlpha});
  final double shadowAlpha;

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height * 0.35;

    canvas.drawOval(
      Rect.fromCenter(
          center: Offset(cx, cy + 4),
          width: size.width * 0.82, height: 14),
      Paint()
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 14)
        ..color = Colors.black.withValues(alpha: shadowAlpha),
    );
    canvas.drawOval(
      Rect.fromCenter(
          center: Offset(cx, cy),
          width: size.width * 0.78, height: 8),
      Paint()
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8)
        ..color = AppColors.cyan.withValues(alpha: shadowAlpha * 0.6),
    );

    final gridPaint = Paint()
      ..color = AppColors.cyan.withValues(alpha: 0.07)
      ..strokeWidth = 0.8
      ..style = PaintingStyle.stroke;
    for (int i = 1; i <= 3; i++) {
      final t = i / 4.0;
      final y = cy + 5 + i * 6.0;
      final leftX = cx - (size.width * 0.5) * (1 - t * 0.4);
      final rightX = cx + (size.width * 0.5) * (1 - t * 0.4);
      canvas.drawLine(Offset(leftX, y), Offset(rightX, y), gridPaint);
    }
  }

  @override
  bool shouldRepaint(_FloorPainter old) => old.shadowAlpha != shadowAlpha;
}
