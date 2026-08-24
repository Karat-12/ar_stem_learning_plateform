import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_exception.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../features/sessions/services/session_service.dart';
import '../../../../shared/widgets/cyber_background.dart';
import '../../../../shared/widgets/glass_card.dart';
import '../../../ai_coach/providers/ai_coach_provider.dart';
import '../../../ai_coach/screens/ai_coach_screen.dart';
import '../../../linked_list/models/linked_list_misconception_map.dart';
import '../../../linked_list/models/linked_list_node_model.dart';
import '../../../linked_list/screens/linked_list_construction_screen.dart';
import '../../../linked_list/widgets/linked_list_playground.dart';
import '../../../misconceptions/models/record_misconception_request.dart';
import '../../../misconceptions/services/misconception_service.dart';
import '../../../progress/providers/progress_provider.dart';
import '../../shared/assessment_challenge_result.dart';
import '../models/challenge_definition.dart';
import '../models/linked_list_assessment_state.dart';
import '../models/validation_result.dart';
import '../services/linked_list_assessment_service.dart';
import '../widgets/assessment_progress_header.dart';
import '../widgets/challenge_instruction_card.dart';

class LinkedListAssessmentScreen extends StatefulWidget {
  const LinkedListAssessmentScreen({super.key, this.onOpenSection});

  /// Optional callback from the dashboard that switches AppShell sections.
  /// When null, Next Action buttons in the AI Coach screen are disabled.
  final ValueChanged<int>? onOpenSection;

  @override
  State<LinkedListAssessmentScreen> createState() =>
      _LinkedListAssessmentScreenState();
}

class _LinkedListAssessmentScreenState
    extends State<LinkedListAssessmentScreen> {
  late final LinkedListAssessmentService _service;
  late final SessionService _sessionService;

  // ── Visual node positions (rendering only) ────────────────────────────────
  // These are decoupled from the logical graph.  The playground uses them
  // to position nodes on screen; validation never reads them.
  late List<LinkedListNodeModel> _visualNodes;

  // ── Assessment state ──────────────────────────────────────────────────────
  LinkedListAssessmentState _state = LinkedListAssessmentState.initial();

  // ── Misconception deduplication ───────────────────────────────────────────
  // Tracks the last code that was successfully sent so we do not spam the
  // backend with the same code on every keystroke/revalidation.
  String? _lastRecordedMisconceptionCode;

  // ── Result screen flag ────────────────────────────────────────────────────
  bool _showResult = false;

  @override
  void initState() {
    super.initState();
    _service = LinkedListAssessmentService();
    _sessionService = context.read<SessionService>();
    _loadChallenge(0);
    _startAssessmentSession();
  }

  // ── Challenge initialisation ──────────────────────────────────────────────

  /// Resets visual nodes and graph state for the challenge at [index].
  /// [preserveResults] is the accumulated results list to carry forward —
  /// passing it here ensures a single setState covers both the challenge reset
  /// and the results update atomically.
  void _loadChallenge(int index, {List<AssessmentChallengeResult>? preserveResults}) {
    final def = _service.challenges[index];
    final nodeIds = def.initialGraph.nodeIds;

    // Arrange visual nodes in a horizontal row at fixed positions.
    // Position is purely cosmetic — validation never reads it.
    final spacing = 160.0;
    final startX = 40.0;
    _visualNodes = nodeIds.asMap().entries.map((e) {
      return LinkedListNodeModel(
        id: e.value,
        label: def.initialGraph.labelOf(e.value),
        position: Offset(startX + e.key * spacing, 160),
      );
    }).toList();

    _lastRecordedMisconceptionCode = null;

    setState(() {
      _state = _state.copyWith(
        currentChallengeIndex: index,
        currentGraph: def.initialGraph,
        tappedSequence: [],
        clearSelectedNode: true,
        lastValidation: ValidationResult(
          isValid: false,
          hint: def.hints.isNotEmpty ? def.hints[0] : def.description,
        ),
        results: preserveResults ?? _state.results,
        clearError: true,
      );
    });
  }

  // ── Session management ────────────────────────────────────────────────────

  Future<void> _startAssessmentSession() async {
    try {
      final response = await _sessionService.startSession(
        domainCode: 'DSA',
        topicCode: 'DSA_LINKED_LIST',
        activityCode: 'ASSESSMENT_LINKED_LIST',
      );
      if (!mounted) return;
      setState(() => _state = _state.copyWith(sessionId: response.id));
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _state = _state.copyWith(errorMessage: e.message));
    }
  }

  /// Completely resets the assessment to its initial state and starts again
  /// from Challenge 1, without popping the route.
  ///
  /// Called when the student taps "Retry Assessment" on the result screen.
  /// Reuses [_loadChallenge] and [_startAssessmentSession] so initialization
  /// logic is never duplicated.
  void _restartAssessment() {
    // Reset the whole assessment state to its initial value first so that
    // _loadChallenge starts with a clean slate (empty results list, no sessionId).
    _state = LinkedListAssessmentState.initial();
    _lastRecordedMisconceptionCode = null;
    _showResult = false;
    // _loadChallenge already calls setState, so no extra setState needed here.
    _loadChallenge(0);
    // Start a fresh backend session for the new attempt.
    _startAssessmentSession();
  }

  // ── Node drag (visual only) ───────────────────────────────────────────────

  void _onMoveNode(int id, Offset position) {
    setState(() {
      _visualNodes = _visualNodes.map((n) {
        return n.id == id ? n.copyWith(position: position) : n;
      }).toList();
    });
    // No revalidation needed — position is never part of validation.
  }

  // ── Head assignment (Challenge 1) ─────────────────────────────────────────

  void _onNodeLongPress(int id) {
    final mode = _service.challenges[_state.currentChallengeIndex].interactionMode;
    if (mode != ChallengeInteractionMode.buildFromScratch) return;
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
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Node $label',
                style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: () {
                Navigator.pop(context);
                _setHead(nodeId);
              },
              icon: const Icon(Icons.flag_rounded),
              label: const Text('Set as HEAD'),
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.lime.withValues(alpha: 0.2),
                foregroundColor: AppColors.lime,
                side: BorderSide(color: AppColors.lime.withValues(alpha: 0.5)),
              ),
            ),
            const SizedBox(height: 8),
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
    _revalidate();
  }

  // ── Two-tap connect gesture (Challenge 1 & 2) ─────────────────────────────

  void _onNodeTap(int id) {
    final challenge = _service.challenges[_state.currentChallengeIndex];

    if (challenge.interactionMode == ChallengeInteractionMode.traceTraversal) {
      _onTraversalTap(id);
      return;
    }

    if (challenge.interactionMode == ChallengeInteractionMode.buildFromScratch ||
        challenge.interactionMode == ChallengeInteractionMode.repairGraph) {
      _onConnectTap(id);
    }
  }

  void _onConnectTap(int id) {
    final selected = _state.selectedNodeId;

    if (selected == null) {
      // First tap: select this node as the connection source.
      setState(() => _state = _state.copyWith(selectedNodeId: id));
      return;
    }

    if (selected == id) {
      // Tapped the same node twice: deselect.
      setState(() => _state = _state.copyWith(clearSelectedNode: true));
      return;
    }

    // Second tap on a different node: draw the pointer selected → id.
    final updatedGraph = _state.currentGraph.withPointer(
      fromId: selected,
      toId: id,
    );
    setState(() {
      _state = _state.copyWith(
        currentGraph: updatedGraph,
        clearSelectedNode: true,
      );
    });
    _revalidate();
  }

  // ── Traversal tapping (Challenge 3) ──────────────────────────────────────

  void _onTraversalTap(int id) {
    final challenge = _service.challenges[_state.currentChallengeIndex];
    final tapResult = _service.validateNextTap(
      id,
      _state.tappedSequence,
      challenge.expectedGraph,
    );

    if (tapResult.isValid) {
      final newSequence = [..._state.tappedSequence, id];
      setState(() {
        _state = _state.copyWith(tappedSequence: newSequence);
      });
      _revalidate();
    } else {
      // Wrong tap — reset sequence and show feedback.
      setState(() {
        _state = _state.copyWith(
          tappedSequence: [],
          lastValidation: tapResult,
        );
      });
      _recordMisconceptionIfNeeded(tapResult);
    }
  }

  // ── Continuous validation ─────────────────────────────────────────────────

  /// Runs the correct validator for the current challenge and updates
  /// [_state.lastValidation].  Always called after any structural mutation.
  void _revalidate() {
    final challenge = _service.challenges[_state.currentChallengeIndex];
    ValidationResult result;

    switch (challenge.interactionMode) {
      case ChallengeInteractionMode.buildFromScratch:
        result = _service.validateBuild(
          _state.currentGraph,
          challenge.expectedGraph,
        );
      case ChallengeInteractionMode.repairGraph:
        result = _service.validateRepair(
          _state.currentGraph,
          challenge.expectedGraph,
        );
      case ChallengeInteractionMode.traceTraversal:
        result = _service.validateTraversal(
          _state.tappedSequence,
          challenge.expectedGraph,
        );
    }

    setState(() {
      _state = _state.copyWith(lastValidation: result);
    });

    _recordMisconceptionIfNeeded(result);
  }

  // ── Misconception recording ───────────────────────────────────────────────

  void _recordMisconceptionIfNeeded(ValidationResult result) {
    if (!result.hasMisconception) return;
    if (result.misconceptionCode == _lastRecordedMisconceptionCode) return;
    if (_state.sessionId == null) return;

    _lastRecordedMisconceptionCode = result.misconceptionCode;
    unawaited(_recordMisconception(result));
  }

  Future<void> _recordMisconception(ValidationResult result) async {
    if (!mounted) return;
    try {
      final service = MisconceptionService(apiClient: context.read<ApiClient>());
      await service.recordMisconception(
        RecordMisconceptionRequest(
          sessionId: _state.sessionId!,
          topicCode: 'DSA_LINKED_LIST',
          misconceptionCode: result.misconceptionCode!,
          misconceptionTitle: result.misconceptionTitle!,
          description: result.misconceptionDescription!,
          severity: result.misconceptionSeverity,
        ),
      );
      if (!mounted) return;
      unawaited(context.read<ProgressProvider>().loadProgress());
    } catch (e) {
      debugPrint('Assessment misconception recording failed: $e');
    }
  }

  // ── Challenge progression ─────────────────────────────────────────────────

  Future<void> _advanceChallenge() async {
    final challenge = _service.challenges[_state.currentChallengeIndex];
    final result = _service.toResult(_state.lastValidation, challenge.points);
    final updatedResults = [..._state.results, result];
    final nextIndex = _state.currentChallengeIndex + 1;

    if (nextIndex >= _service.challenges.length) {
      await _submitAssessment(updatedResults);
      return;
    }

    // Single atomic setState: resets the next challenge AND preserves results.
    _loadChallenge(nextIndex, preserveResults: updatedResults);  }

  Future<void> _submitAssessment(
    List<AssessmentChallengeResult> results,
  ) async {
    if (_state.sessionId == null) {
      setState(() => _state = _state.copyWith(
        errorMessage: 'Assessment session was not started.',
      ));
      return;
    }

    setState(() => _state = _state.copyWith(isSubmitting: true));

    try {
      final apiClient = context.read<ApiClient>();
      final passed = results.where((r) => r.passed).length;
      await apiClient.post<Map<String, dynamic>>(
        path: '/api/v1/quizzes/submit',
        data: {
          'sessionId': _state.sessionId,
          'topicCode': 'DSA_LINKED_LIST',
          'totalQuestions': results.length,
          'correctAnswers': passed,
        },
        fromJson: (json) => json as Map<String, dynamic>,
      );
      await _sessionService.endSession(_state.sessionId!);
      if (!mounted) return;
      // Invalidate the cached AI Coach report so the next view reflects the
      // just-completed assessment.  Fire-and-forget: we do not await the
      // network call here to keep the result screen appearing immediately.
      unawaited(
        context.read<AiCoachProvider>().refresh('DSA_LINKED_LIST'),
      );
      setState(() {
        _state = _state.copyWith(isSubmitting: false, results: results);
        _showResult = true;
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _state = _state.copyWith(
        isSubmitting: false,
        errorMessage: e.message,
      ));
    }
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    if (_showResult) {
      return _AssessmentResultScreen(
        results: _state.results,
        service: _service,
        onOpenSection: widget.onOpenSection,
        onRetry: _restartAssessment,
        onViewCoach: () {
          Navigator.of(context).push(
            MaterialPageRoute<void>(
              builder: (_) => AiCoachScreen(
                topicCode: 'DSA_LINKED_LIST',
                onRetryAssessment: () => Navigator.of(context).pop(),
                onNavigate: widget.onOpenSection != null
                    ? (index) {
                        // Pop all assessment routes back to the dashboard,
                        // then switch the AppShell to the requested section.
                        Navigator.of(context).popUntil((route) => route.isFirst);
                        widget.onOpenSection!(index);
                      }
                    : null,
              ),
            ),
          );
        },
      );
    }

    final challenge = _service.challenges[_state.currentChallengeIndex];
    final isLast =
        _state.currentChallengeIndex == _service.challenges.length - 1;

    return Scaffold(
      body: CyberBackground(
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1120),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    AssessmentProgressHeader(
                      currentIndex: _state.currentChallengeIndex,
                      totalSteps: _service.challenges.length,
                      title: challenge.title,
                    ),
                    const SizedBox(height: 20),
                    ChallengeInstructionCard(
                      title: challenge.title,
                      description: challenge.description,
                      points: challenge.points,
                    ),
                    const SizedBox(height: 20),
                    LayoutBuilder(builder: (context, constraints) {
                      final isWide = constraints.maxWidth >= 980;
                      final playground = GlassCard(
                        padding: const EdgeInsets.all(16),
                        child: LinkedListPlayground(
                          nodes: _visualNodes,
                          headNodeId: _state.currentGraph.headId,
                          // connectionBroken is the workspace fallback.
                          // nextPointers overrides it in assessment mode.
                          connectionBroken: _state.connectionBroken,
                          activeTraversalId: _state.tappedSequence.isNotEmpty
                              ? _state.tappedSequence.last
                              : null,
                          selectedNodeId: _state.selectedNodeId,
                          onMoveNode: _onMoveNode,
                          onNodeTap: _onNodeTap,
                          onNodeLongPress:
                              challenge.interactionMode ==
                                      ChallengeInteractionMode.buildFromScratch
                                  ? _onNodeLongPress
                                  : null,
                          // Supply the pointer map so the painter draws
                          // arrows from logical structure, not screen position.
                          nextPointers: {
                            for (final id in _state.currentGraph.nodeIds)
                              id: _state.currentGraph.nextOf(id),
                          },
                        ),
                      );
                      final panel = _AssessmentSidePanel(
                        challenge: challenge,
                        state: _state,
                        isLastChallenge: isLast,
                        onContinue: _advanceChallenge,
                      );
                      if (isWide) {
                        return Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(flex: 7, child: playground),
                            const SizedBox(width: 18),
                            Expanded(flex: 3, child: panel),
                          ],
                        );
                      }
                      return Column(children: [
                        playground,
                        const SizedBox(height: 16),
                        panel,
                      ]);
                    }),
                    if (_state.errorMessage != null) ...[
                      const SizedBox(height: 16),
                      GlassCard(
                        padding: const EdgeInsets.all(16),
                        child: Text(
                          _state.errorMessage!,
                          style: const TextStyle(color: AppColors.pink),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ── Side panel ────────────────────────────────────────────────────────────────

class _AssessmentSidePanel extends StatelessWidget {
  const _AssessmentSidePanel({
    required this.challenge,
    required this.state,
    required this.isLastChallenge,
    required this.onContinue,
  });

  final ChallengeDefinition challenge;
  final LinkedListAssessmentState state;
  final bool isLastChallenge;
  final VoidCallback onContinue;

  @override
  Widget build(BuildContext context) {
    final feedbackColor =
        state.isCurrentChallengeValid ? AppColors.lime : AppColors.orange;

    return GlassCard(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _InteractionGuide(mode: challenge.interactionMode, state: state),
          const SizedBox(height: 16),
          // Live feedback panel
          AnimatedContainer(
            duration: const Duration(milliseconds: 260),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: feedbackColor.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(16),
              border:
                  Border.all(color: feedbackColor.withValues(alpha: 0.35)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  state.isCurrentChallengeValid
                      ? Icons.check_circle_outline_rounded
                      : Icons.radar_rounded,
                  color: feedbackColor,
                  size: 22,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 220),
                    child: Text(
                      state.currentHint,
                      key: ValueKey(state.currentHint),
                      style: TextStyle(
                        color: feedbackColor,
                        fontWeight: FontWeight.w600,
                        height: 1.4,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: state.isCurrentChallengeValid && !state.isSubmitting
                  ? onContinue
                  : null,
              icon: state.isSubmitting
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: AppColors.backgroundTop,
                      ),
                    )
                  : Icon(
                      isLastChallenge
                          ? Icons.verified_rounded
                          : Icons.arrow_forward_rounded,
                    ),
              label: Text(
                isLastChallenge ? 'Submit Assessment' : 'Check & Continue',
              ),
              style: FilledButton.styleFrom(
                backgroundColor: state.isCurrentChallengeValid
                    ? AppColors.lime
                    : AppColors.glass,
                foregroundColor: state.isCurrentChallengeValid
                    ? AppColors.backgroundTop
                    : AppColors.textSecondary,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Interaction guide (mode-specific instructions) ────────────────────────────

class _InteractionGuide extends StatelessWidget {
  const _InteractionGuide({required this.mode, required this.state});

  final ChallengeInteractionMode mode;
  final LinkedListAssessmentState state;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('How to interact',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  color: AppColors.cyan,
                  fontWeight: FontWeight.w700,
                )),
        const SizedBox(height: 10),
        ..._steps(context),
      ],
    );
  }

  List<Widget> _steps(BuildContext context) {
    switch (mode) {
      case ChallengeInteractionMode.buildFromScratch:
        return [
          _Step(
            icon: Icons.flag_rounded,
            color: AppColors.lime,
            text: 'Long-press a node → tap "Set as HEAD"',
            done: state.currentGraph.headId != null,
          ),
          _Step(
            icon: Icons.arrow_forward_rounded,
            color: AppColors.cyan,
            text: state.selectedNodeId == null
                ? 'Tap a node to select it as source'
                : 'Now tap the node it should point to',
            done: false,
            active: state.selectedNodeId != null,
          ),
          _Step(
            icon: Icons.check_circle_outline_rounded,
            color: AppColors.violet,
            text: 'Connect all nodes into one chain',
            done: state.isCurrentChallengeValid,
          ),
        ];
      case ChallengeInteractionMode.repairGraph:
        return [
          _Step(
            icon: Icons.touch_app_rounded,
            color: AppColors.orange,
            text: state.selectedNodeId == null
                ? 'Tap the node before the broken link'
                : 'Now tap the node it should connect to',
            done: false,
            active: state.selectedNodeId != null,
          ),
          _Step(
            icon: Icons.check_circle_outline_rounded,
            color: AppColors.lime,
            text: 'The broken arrow heals when the link is restored',
            done: state.isCurrentChallengeValid,
          ),
        ];
      case ChallengeInteractionMode.traceTraversal:
        final done = state.tappedSequence.length;
        final total = state.currentGraph.nodeIds.length;
        return [
          _Step(
            icon: Icons.flag_rounded,
            color: AppColors.lime,
            text: 'Start by tapping the HEAD node',
            done: state.tappedSequence.isNotEmpty,
          ),
          _Step(
            icon: Icons.arrow_forward_rounded,
            color: AppColors.cyan,
            text: 'Follow each arrow — tap node $done of $total',
            done: false,
            active: done > 0 && !state.isCurrentChallengeValid,
          ),
          _Step(
            icon: Icons.verified_rounded,
            color: AppColors.violet,
            text: 'Wrong tap resets the sequence',
            done: state.isCurrentChallengeValid,
          ),
        ];
    }
  }
}

class _Step extends StatelessWidget {
  const _Step({
    required this.icon,
    required this.color,
    required this.text,
    required this.done,
    this.active = false,
  });

  final IconData icon;
  final Color color;
  final String text;
  final bool done;
  final bool active;

  @override
  Widget build(BuildContext context) {
    final effectiveColor = done
        ? AppColors.lime
        : active
            ? color
            : AppColors.textSecondary;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(done ? Icons.check_circle_rounded : icon,
              size: 18, color: effectiveColor),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                color: effectiveColor,
                fontWeight: active || done ? FontWeight.w600 : FontWeight.w400,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Result screen ─────────────────────────────────────────────────────────────

class _AssessmentResultScreen extends StatelessWidget {
  const _AssessmentResultScreen({
    required this.results,
    required this.service,
    required this.onViewCoach,
    required this.onRetry,
    this.onOpenSection,
  });

  final List<AssessmentChallengeResult> results;
  final LinkedListAssessmentService service;
  final VoidCallback onViewCoach;
  final VoidCallback onRetry;
  final ValueChanged<int>? onOpenSection;

  // Challenge titles matching the service definition order.
  static const _titles = [
    'Build the chain',
    'Repair the break',
    'Trace the traversal',
  ];

  @override
  Widget build(BuildContext context) {
    final summary = service.buildResult(results);
    final passed = summary.passedChallenges;
    final total = results.length;
    final score = summary.totalScore;
    final excellent = score >= 80;
    final accent = excellent ? AppColors.lime : AppColors.orange;

    // Derive strengths and improvements from challenge outcomes.
    final strengths = <String>[];
    final improvements = <String>[];
    for (var i = 0; i < results.length; i++) {
      final title = i < _titles.length ? _titles[i] : 'Challenge ${i + 1}';
      if (results[i].passed) {
        strengths.add(title);
      } else {
        improvements.add(title);
      }
    }

    return Scaffold(
      body: CyberBackground(
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(
                  horizontal: 24, vertical: 20),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 680),
                child: Column(
                  children: [
                    // ── Icon + heading ──────────────────────────────────────
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        color: accent.withValues(alpha: 0.12),
                        shape: BoxShape.circle,
                        border: Border.all(
                            color: accent.withValues(alpha: 0.4),
                            width: 2),
                      ),
                      child: Icon(
                        excellent
                            ? Icons.verified_rounded
                            : Icons.school_rounded,
                        size: 44,
                        color: accent,
                      ),
                    ),
                    const SizedBox(height: 18),
                    Text(
                      excellent
                          ? 'Assessment Complete!'
                          : 'Assessment Complete',
                      style: Theme.of(context)
                          .textTheme
                          .headlineMedium
                          ?.copyWith(
                              color: AppColors.textPrimary,
                              fontWeight: FontWeight.w800),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      excellent
                          ? 'Great work — you demonstrated solid understanding '
                              'of Linked List structure and traversal.'
                          : 'Good effort. Review the concepts below and '
                              'practise more before your next attempt.',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                          color: AppColors.textSecondary, height: 1.5),
                    ),
                    const SizedBox(height: 28),

                    // ── Score summary card ──────────────────────────────────
                    GlassCard(
                      padding: const EdgeInsets.all(22),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              _ScoreStat(
                                label: 'Score',
                                value: '$score',
                                unit: '/ 100',
                                color: accent,
                              ),
                              Container(
                                  width: 1,
                                  height: 48,
                                  color: Colors.white
                                      .withValues(alpha: 0.08)),
                              _ScoreStat(
                                label: 'Challenges',
                                value: '$passed',
                                unit: '/ $total passed',
                                color: AppColors.cyan,
                              ),
                            ],
                          ),
                          const SizedBox(height: 18),
                          // Per-challenge breakdown
                          ...results.asMap().entries.map((e) {
                            final i = e.key;
                            final r = e.value;
                            final title = i < _titles.length
                                ? _titles[i]
                                : 'Challenge ${i + 1}';
                            return Padding(
                              padding:
                                  const EdgeInsets.only(bottom: 8),
                              child: Row(
                                children: [
                                  Icon(
                                    r.passed
                                        ? Icons.check_circle_rounded
                                        : Icons.cancel_rounded,
                                    size: 18,
                                    color: r.passed
                                        ? AppColors.lime
                                        : AppColors.pink,
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Text(
                                      title,
                                      style: const TextStyle(
                                          color: AppColors.textPrimary),
                                    ),
                                  ),
                                  Text(
                                    r.passed
                                        ? '+${r.score} pts'
                                        : '0 pts',
                                    style: TextStyle(
                                      color: r.passed
                                          ? AppColors.lime
                                          : AppColors.textSecondary,
                                      fontWeight: FontWeight.w700,
                                      fontSize: 13,
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }),
                        ],
                      ),
                    ),

                    // ── Strengths ───────────────────────────────────────────
                    if (strengths.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      _ResultSection(
                        icon: Icons.thumb_up_alt_rounded,
                        title: 'What you did well',
                        accent: AppColors.lime,
                        items: strengths,
                      ),
                    ],

                    // ── Concepts to improve ─────────────────────────────────
                    if (improvements.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      _ResultSection(
                        icon: Icons.auto_fix_high_rounded,
                        title: 'Concepts to improve',
                        accent: AppColors.orange,
                        items: improvements,
                      ),
                    ],

                    // ── Recommended next step ───────────────────────────────
                    const SizedBox(height: 16),
                    _NextStepBanner(score: score),

                    // ── Recommended Practice (when misconceptions exist) ────
                    Builder(builder: (context) {
                      // Map each failed challenge to its primary misconception
                      // code using the well-known per-challenge mapping, then
                      // deduplicate via topRecommendations.
                      const challengeMisconceptions = [
                        'DSA_HEAD_POINTER_MISSING', // challenge 0: build chain
                        'DSA_BROKEN_LINKED_LIST',   // challenge 1: repair
                        'DSA_INVALID_TRAVERSAL',    // challenge 2: traversal
                      ];
                      final failedCodes = <String>[
                        for (var i = 0; i < results.length; i++)
                          if (!results[i].passed &&
                              i < challengeMisconceptions.length)
                            challengeMisconceptions[i],
                      ];
                      final recs = topRecommendations(failedCodes, limit: 2);
                      if (recs.isEmpty) return const SizedBox.shrink();
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 16),
                          _RecommendedPracticeSection(recommendations: recs),
                        ],
                      );
                    }),

                    // ── Action buttons ──────────────────────────────────────
                    const SizedBox(height: 24),
                    Column(
                      children: [
                        SizedBox(
                          width: double.infinity,
                          child: FilledButton.icon(
                            onPressed: onViewCoach,
                            icon: const Icon(Icons.smart_toy_rounded),
                            label: const Text('Open AI Coach'),
                            style: FilledButton.styleFrom(
                              backgroundColor:
                                  AppColors.violet.withValues(alpha: 0.22),
                              foregroundColor: AppColors.violet,
                              side: BorderSide(
                                  color: AppColors.violet
                                      .withValues(alpha: 0.45)),
                              padding:
                                  const EdgeInsets.symmetric(vertical: 15),
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: () =>
                                    Navigator.of(context).pop(),
                                icon: const Icon(
                                    Icons.arrow_back_rounded,
                                    size: 18),
                                label: const Text('Back'),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor:
                                      AppColors.textSecondary,
                                  side: BorderSide(
                                      color: AppColors.textSecondary
                                          .withValues(alpha: 0.3)),
                                  padding: const EdgeInsets.symmetric(
                                      vertical: 14),
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: onRetry,
                                icon: const Icon(
                                    Icons.replay_rounded,
                                    size: 18),
                                label: const Text('Retry Assessment'),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: AppColors.cyan,
                                  side: BorderSide(
                                      color: AppColors.cyan
                                          .withValues(alpha: 0.4)),
                                  padding: const EdgeInsets.symmetric(
                                      vertical: 14),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),

                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ScoreStat extends StatelessWidget {
  const _ScoreStat({
    required this.label,
    required this.value,
    required this.unit,
    required this.color,
  });
  final String label;
  final String value;
  final String unit;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(label,
            style: const TextStyle(
                color: AppColors.textSecondary, fontSize: 12)),
        const SizedBox(height: 4),
        RichText(
          text: TextSpan(
            children: [
              TextSpan(
                text: value,
                style: TextStyle(
                  color: color,
                  fontSize: 32,
                  fontWeight: FontWeight.w900,
                  height: 1,
                ),
              ),
              TextSpan(
                text: ' $unit',
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 13,
                  fontWeight: FontWeight.w400,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ResultSection extends StatelessWidget {
  const _ResultSection({
    required this.icon,
    required this.title,
    required this.accent,
    required this.items,
  });
  final IconData icon;
  final String title;
  final Color accent;
  final List<String> items;

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: accent, size: 17),
              const SizedBox(width: 8),
              Text(title,
                  style: TextStyle(
                    color: accent,
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                    letterSpacing: 0.3,
                  )),
            ],
          ),
          const SizedBox(height: 10),
          ...items.map((item) => Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(top: 5),
                      child: Container(
                        width: 5,
                        height: 5,
                        decoration: BoxDecoration(
                          color: accent,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(item,
                          style: const TextStyle(
                              color: AppColors.textPrimary, height: 1.4)),
                    ),
                  ],
                ),
              )),
        ],
      ),
    );
  }
}

class _NextStepBanner extends StatelessWidget {
  const _NextStepBanner({required this.score});
  final int score;

  @override
  Widget build(BuildContext context) {
    final String message;
    final IconData icon;
    final Color accent;

    if (score >= 80) {
      message = 'Open your AI Coach report to see your full analysis '
          'and what to explore next.';
      icon = Icons.smart_toy_rounded;
      accent = AppColors.violet;
    } else if (score >= 50) {
      message = 'Your AI Coach will explain exactly what to practise '
          'before retrying the assessment.';
      icon = Icons.auto_fix_high_rounded;
      accent = AppColors.cyan;
    } else {
      message = 'Your AI Coach will guide you through the concepts '
          'you need to revisit before trying again.';
      icon = Icons.school_rounded;
      accent = AppColors.orange;
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: accent.withValues(alpha: 0.25)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: accent, size: 22),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Recommended Next Step',
                  style: TextStyle(
                    color: accent,
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  message,
                  style: const TextStyle(
                      color: AppColors.textSecondary,
                      height: 1.5,
                      fontSize: 13),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Recommended Practice section ─────────────────────────────────────────────

class _RecommendedPracticeSection extends StatelessWidget {
  const _RecommendedPracticeSection({required this.recommendations});

  final List<LinkedListPracticeRecommendation> recommendations;

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: AppColors.orange.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                      color: AppColors.orange.withValues(alpha: 0.35)),
                ),
                child: const Icon(Icons.fitness_center_rounded,
                    color: AppColors.orange, size: 14),
              ),
              const SizedBox(width: 10),
              const Text(
                'RECOMMENDED PRACTICE',
                style: TextStyle(
                  color: AppColors.orange,
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.9,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          const Text(
            'Based on your results, these concepts need more practice.',
            style: TextStyle(
                color: AppColors.textSecondary, fontSize: 12, height: 1.45),
          ),
          const SizedBox(height: 14),
          // One card per recommendation
          ...recommendations.map(
            (rec) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _PracticeRecommendationCard(recommendation: rec),
            ),
          ),
        ],
      ),
    );
  }
}

class _PracticeRecommendationCard extends StatelessWidget {
  const _PracticeRecommendationCard({required this.recommendation});

  final LinkedListPracticeRecommendation recommendation;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.cyan.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.cyan.withValues(alpha: 0.22)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  recommendation.conceptTitle,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  recommendation.practiceReason,
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                    height: 1.45,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          // "Practice This" button
          TextButton.icon(
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => LinkedListConstructionScreen(
                  initialTaskId: recommendation.taskId,
                ),
              ),
            ),
            icon: const Icon(Icons.play_arrow_rounded, size: 16),
            label: Text(recommendation.ctaLabel),
            style: TextButton.styleFrom(
              foregroundColor: AppColors.lime,
              backgroundColor: AppColors.lime.withValues(alpha: 0.10),
              side: BorderSide(color: AppColors.lime.withValues(alpha: 0.35)),
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              textStyle: const TextStyle(
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
