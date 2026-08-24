import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/cyber_background.dart';
import '../../../shared/widgets/glass_card.dart';
import '../../linked_list/models/linked_list_misconception_map.dart';
import '../../linked_list/screens/linked_list_construction_screen.dart';
import '../models/ai_coach_report.dart';
import '../providers/ai_coach_provider.dart';
import '../utils/topic_labels.dart';
import '../widgets/coach_section_card.dart';
import '../widgets/mastery_score_ring.dart';

/// AI Coach screen — personalised learning report for one topic.
///
/// All backend codes (e.g. DSA_LINKED_LIST, DSA_HEAD_POINTER_MISSING) are
/// converted to natural English via [TopicLabels] before being displayed.
/// No raw codes are ever shown to the student.
class AiCoachScreen extends StatefulWidget {
  const AiCoachScreen({
    super.key,
    required this.topicCode,
    this.onNavigate,
    this.onRetryAssessment,
  });

  final String topicCode;
  final void Function(int shellIndex)? onNavigate;
  final VoidCallback? onRetryAssessment;

  @override
  State<AiCoachScreen> createState() => _AiCoachScreenState();
}

class _AiCoachScreenState extends State<AiCoachScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AiCoachProvider>().loadReport(widget.topicCode);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CyberBackground(
        child: SafeArea(
          child: Consumer<AiCoachProvider>(
            builder: (context, provider, _) {
              if (provider.isLoading) {
                return _LoadingBody(
                    topicLabel: TopicLabels.topic(widget.topicCode));
              }
              if (provider.errorMessage != null) {
                return _ErrorBody(
                  message: provider.errorMessage!,
                  onRetry: () => provider.refresh(widget.topicCode),
                );
              }
              final report = provider.currentReport;
              if (report == null) {
                return _EmptyBody(
                    topicLabel: TopicLabels.topic(widget.topicCode));
              }
              return _CoachBody(
                report: report,
                onNavigate: widget.onNavigate,
                onRetryAssessment: widget.onRetryAssessment,
                onRefresh: () => provider.refresh(widget.topicCode),
              );
            },
          ),
        ),
      ),
    );
  }
}

// ── Loading ───────────────────────────────────────────────────────────────────

class _LoadingBody extends StatelessWidget {
  const _LoadingBody({required this.topicLabel});
  final String topicLabel;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(
            width: 52,
            height: 52,
            child: CircularProgressIndicator(
                color: AppColors.cyan, strokeWidth: 3),
          ),
          const SizedBox(height: 24),
          Text(
            'Analysing your $topicLabel progress…',
            style: Theme.of(context)
                .textTheme
                .bodyLarge
                ?.copyWith(color: AppColors.textSecondary),
          ),
          const SizedBox(height: 6),
          Text(
            'Your personalised report is being prepared.',
            style: Theme.of(context)
                .textTheme
                .bodyMedium
                ?.copyWith(color: AppColors.textSecondary.withValues(alpha: 0.65)),
          ),
        ],
      ),
    );
  }
}

// ── Error ─────────────────────────────────────────────────────────────────────

class _ErrorBody extends StatelessWidget {
  const _ErrorBody({required this.message, required this.onRetry});
  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(36),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.wifi_off_rounded,
                size: 56, color: AppColors.orange),
            const SizedBox(height: 20),
            Text('Report unavailable',
                style: Theme.of(context)
                    .textTheme
                    .titleMedium
                    ?.copyWith(color: AppColors.textPrimary)),
            const SizedBox(height: 10),
            Text(
              'We could not load your AI Coach report right now.\n'
              'Check your connection and try again.',
              textAlign: TextAlign.center,
              style: const TextStyle(
                  color: AppColors.textSecondary, height: 1.5),
            ),
            const SizedBox(height: 28),
            FilledButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Try Again'),
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.cyan.withValues(alpha: 0.15),
                foregroundColor: AppColors.cyan,
                padding: const EdgeInsets.symmetric(
                    horizontal: 28, vertical: 14),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Empty ─────────────────────────────────────────────────────────────────────

class _EmptyBody extends StatelessWidget {
  const _EmptyBody({required this.topicLabel});
  final String topicLabel;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(36),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.smart_toy_outlined,
                size: 64, color: AppColors.textSecondary),
            const SizedBox(height: 20),
            Text(
              'No $topicLabel report yet',
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(color: AppColors.textPrimary),
            ),
            const SizedBox(height: 10),
            Text(
              'Complete the $topicLabel assessment to generate\n'
              'your first personalised AI Coach report.',
              textAlign: TextAlign.center,
              style: const TextStyle(
                  color: AppColors.textSecondary, height: 1.55),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Main content body ─────────────────────────────────────────────────────────

class _CoachBody extends StatelessWidget {
  const _CoachBody({
    required this.report,
    required this.onRefresh,
    this.onNavigate,
    this.onRetryAssessment,
  });

  final AiCoachReport report;
  final VoidCallback onRefresh;
  final void Function(int shellIndex)? onNavigate;
  final VoidCallback? onRetryAssessment;

  @override
  Widget build(BuildContext context) {
    final hasInsights = report.insights.strengths.isNotEmpty ||
        report.insights.weaknesses.isNotEmpty;
    final hasWeakAreas = report.misconceptionCodes.isNotEmpty;

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 18),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 820),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _CoachHeader(
                  topicCode: report.topicCode, onRefresh: onRefresh),
              const SizedBox(height: 28),
              _MasterySection(report: report),
              const SizedBox(height: 22),
              _TutorMessageSection(report: report),
              const SizedBox(height: 22),
              if (hasInsights) ...[
                _InsightsSection(report: report),
                const SizedBox(height: 22),
              ],
              if (report.topicRecommendation != null) ...[
                _RecommendationSection(report: report),
                const SizedBox(height: 22),
              ],
              if (report.hasRevisionActions) ...[
                _RevisionSection(report: report),
                const SizedBox(height: 22),
              ],
              if (hasWeakAreas) ...[
                _WeakAreasSection(report: report),
                const SizedBox(height: 22),
              ],
              if (report.studyPlan.todayTasks.isNotEmpty) ...[
                _StudyPlanSection(report: report),
                const SizedBox(height: 22),
              ],
              _NextActionSection(
                report: report,
                onNavigate: onNavigate,
                onRetryAssessment: onRetryAssessment,
              ),
              const SizedBox(height: 36),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Header ────────────────────────────────────────────────────────────────────

class _CoachHeader extends StatelessWidget {
  const _CoachHeader({required this.topicCode, required this.onRefresh});
  final String topicCode;
  final VoidCallback onRefresh;

  @override
  Widget build(BuildContext context) {
    final canPop = Navigator.of(context).canPop();
    final topicLabel = TopicLabels.topic(topicCode);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        if (canPop) ...[
          IconButton(
            onPressed: () => Navigator.of(context).pop(),
            icon: const Icon(Icons.arrow_back_rounded),
            color: AppColors.textSecondary,
            tooltip: 'Back',
            padding: EdgeInsets.zero,
            visualDensity: VisualDensity.compact,
          ),
          const SizedBox(width: 6),
        ],
        Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: AppColors.violet.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
                color: AppColors.violet.withValues(alpha: 0.35)),
          ),
          child: const Icon(Icons.smart_toy_rounded,
              color: AppColors.violet, size: 24),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'AI Learning Coach',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      color: AppColors.violet,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.3,
                    ),
              ),
              const SizedBox(height: 2),
              Text(
                topicLabel,
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
        IconButton(
          onPressed: onRefresh,
          tooltip: 'Refresh report',
          icon: const Icon(Icons.refresh_rounded,
              color: AppColors.textSecondary, size: 22),
          padding: EdgeInsets.zero,
          visualDensity: VisualDensity.compact,
        ),
      ],
    );
  }
}

// ── Mastery ───────────────────────────────────────────────────────────────────

class _MasterySection extends StatelessWidget {
  const _MasterySection({required this.report});
  final AiCoachReport report;

  Color get _accentColor {
    final level = report.masteryLevel.toUpperCase();
    if (level == 'MASTERED' || level == 'ADVANCED') return AppColors.lime;
    if (level == 'PROFICIENT' || level == 'INTERMEDIATE') return AppColors.cyan;
    if (level == 'DEVELOPING') return AppColors.orange;
    return AppColors.pink; // BEGINNER
  }

  @override
  Widget build(BuildContext context) {
    return CoachSectionCard(
      icon: Icons.military_tech_rounded,
      title: 'Mastery Level',
      accent: _accentColor,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          MasteryScoreRing(
            score: report.masteryScore,
            masteryLevel: TopicLabels.masteryLevel(report.masteryLevel),
            size: 118,
          ),
          const SizedBox(width: 28),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _StatRow(
                  label: 'Quiz score',
                  value: '${report.analytics.averageQuizScore}%',
                  color: AppColors.cyan,
                ),
                const SizedBox(height: 9),
                _StatRow(
                  label: 'Sessions done',
                  value: '${report.analytics.completedSessions}',
                  color: AppColors.violet,
                ),
                const SizedBox(height: 9),
                _StatRow(
                  label: 'Active misconceptions',
                  value: '${report.analytics.misconceptionCount}',
                  color: report.analytics.misconceptionCount > 0
                      ? AppColors.orange
                      : AppColors.lime,
                ),
                if (report.practiceRecommended) ...[
                  const SizedBox(height: 14),
                  _PracticeBadge(),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PracticeBadge extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: AppColors.orange.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.orange.withValues(alpha: 0.4)),
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.auto_awesome_rounded, color: AppColors.orange, size: 13),
          SizedBox(width: 5),
          Text(
            'More practice will help',
            style: TextStyle(
              color: AppColors.orange,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _StatRow extends StatelessWidget {
  const _StatRow(
      {required this.label, required this.value, required this.color});
  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(label,
              style: const TextStyle(
                  color: AppColors.textSecondary, fontSize: 13)),
        ),
        Text(value,
            style: TextStyle(
                color: color, fontWeight: FontWeight.w700, fontSize: 14)),
      ],
    );
  }
}

// ── Tutor Message (personalised, mastery-tier) ────────────────────────────────
//
// This section replaces the generic "Overall Performance" label with a
// friendly tutor voice that varies by mastery tier (Task 3 & 5).

class _TutorMessageSection extends StatelessWidget {
  const _TutorMessageSection({required this.report});
  final AiCoachReport report;

  /// Generates a tutor-voice message from available data.
  /// Priority: backend-generated summary → tier-based fallback.
  String _message(String topicLabel) {
    final summary = report.overallSummary.trim();
    // If the backend already produced a rich summary, use it directly but
    // clean any raw topic codes that may have slipped through.
    if (summary.isNotEmpty &&
        !summary.contains('Complete an assessment')) {
      return TopicLabels.clean(summary);
    }

    // Personalised tier-based fallback messages.
    final score = report.analytics.averageQuizScore;
    final level = report.masteryLevel.toUpperCase();
    final activeMisconceptions = report.analytics.misconceptionCount;

    if (level == 'MASTERED' || level == 'ADVANCED') {
      if (activeMisconceptions == 0) {
        return 'Great work! You understand $topicLabel very well. '
            'No active misconceptions remain — you are ready to move on to '
            'the next topic.';
      }
      return 'Excellent performance on $topicLabel! '
          'You scored $score% on your quiz. '
          'A few concepts still need attention — see the revision section below.';
    }

    if (level == 'PROFICIENT' || level == 'INTERMEDIATE') {
      return 'Good progress on $topicLabel. '
          'You scored $score% overall. '
          'Practising insertion and deletion operations will push you to full mastery.';
    }

    if (level == 'DEVELOPING') {
      return 'You are developing your understanding of $topicLabel. '
          'Most of your mistakes happened while connecting nodes. '
          'Try rebuilding one linked list from scratch before attempting '
          'the assessment again.';
    }

    // BEGINNER
    return "Don't worry — everyone starts somewhere. "
        'Your main challenge with $topicLabel right now is '
        '${activeMisconceptions > 0 ? 'connecting nodes correctly' : 'the overall structure'}. '
        'Visit the learning workspace and follow the step-by-step guide '
        'before retrying the assessment.';
  }

  @override
  Widget build(BuildContext context) {
    final topicLabel = TopicLabels.topic(report.topicCode);
    return CoachSectionCard(
      icon: Icons.psychology_rounded,
      title: 'Your AI Tutor',
      accent: AppColors.violet,
      child: Text(
        _message(topicLabel),
        style: const TextStyle(
          color: AppColors.textPrimary,
          height: 1.6,
          fontSize: 14,
        ),
      ),
    );
  }
}

// ── Strengths & Weak Areas ────────────────────────────────────────────────────

class _InsightsSection extends StatelessWidget {
  const _InsightsSection({required this.report});
  final AiCoachReport report;

  @override
  Widget build(BuildContext context) {
    final hasStrengths = report.insights.strengths.isNotEmpty;
    final hasWeaknesses = report.insights.weaknesses.isNotEmpty;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (hasStrengths)
          Expanded(
            child: CoachSectionCard(
              icon: Icons.trending_up_rounded,
              title: 'Strengths',
              accent: AppColors.lime,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: report.insights.strengths
                    .map((s) => CoachBulletItem(
                        text: TopicLabels.topic(s), accent: AppColors.lime))
                    .toList(),
              ),
            ),
          ),
        if (hasStrengths && hasWeaknesses) const SizedBox(width: 14),
        if (hasWeaknesses)
          Expanded(
            child: CoachSectionCard(
              icon: Icons.trending_down_rounded,
              title: 'Needs Work',
              accent: AppColors.orange,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: report.insights.weaknesses
                    .map((w) => CoachBulletItem(
                        text: TopicLabels.topic(w), accent: AppColors.orange))
                    .toList(),
              ),
            ),
          ),
      ],
    );
  }
}

// ── AI Recommendation ─────────────────────────────────────────────────────────

class _RecommendationSection extends StatelessWidget {
  const _RecommendationSection({required this.report});
  final AiCoachReport report;

  @override
  Widget build(BuildContext context) {
    final rec = report.topicRecommendation!;
    final typeLabel = TopicLabels.recommendationType(rec.recommendationType);
    final isPositive = rec.recommendationType == 'NEXT_TOPIC';
    final accent = isPositive ? AppColors.lime : AppColors.cyan;

    return CoachSectionCard(
      icon: Icons.lightbulb_outline_rounded,
      title: 'Recommendation',
      accent: accent,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: accent.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: accent.withValues(alpha: 0.35)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  isPositive
                      ? Icons.arrow_upward_rounded
                      : Icons.auto_fix_high_rounded,
                  color: accent,
                  size: 13,
                ),
                const SizedBox(width: 5),
                Text(
                  typeLabel,
                  style: TextStyle(
                    color: accent,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Text(
            TopicLabels.clean(rec.reason),
            style: const TextStyle(
                color: AppColors.textPrimary, height: 1.55, fontSize: 14),
          ),
        ],
      ),
    );
  }
}

// ── Revision Actions ──────────────────────────────────────────────────────────

class _RevisionSection extends StatelessWidget {
  const _RevisionSection({required this.report});
  final AiCoachReport report;

  @override
  Widget build(BuildContext context) {
    final rev = report.revision;
    final cleanedReason = TopicLabels.clean(rev.reason);
    final isPositive = rev.revisionActions.isEmpty;

    return CoachSectionCard(
      icon: Icons.auto_fix_high_rounded,
      title: 'Revision Plan',
      accent: isPositive ? AppColors.lime : AppColors.pink,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (cleanedReason.isNotEmpty &&
              cleanedReason != 'No revision needed — keep up the great work!') ...[
            Text(cleanedReason,
                style: const TextStyle(
                    color: AppColors.textSecondary, height: 1.55)),
            const SizedBox(height: 12),
          ],
          if (isPositive)
            const _PositiveNotice(
              icon: Icons.check_circle_outline_rounded,
              message:
                  'No revision needed — you are performing well on this topic!',
              color: AppColors.lime,
            )
          else
            ...rev.revisionActions.map((a) =>
                CoachBulletItem(
                    text: TopicLabels.clean(a), accent: AppColors.pink)),
          if (rev.estimatedRevisionTimeMinutes > 0) ...[
            const SizedBox(height: 10),
            _TimeEstimate(minutes: rev.estimatedRevisionTimeMinutes),
          ],
        ],
      ),
    );
  }
}

class _PositiveNotice extends StatelessWidget {
  const _PositiveNotice(
      {required this.icon, required this.message, required this.color});
  final IconData icon;
  final String message;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: color, size: 18),
        const SizedBox(width: 10),
        Expanded(
          child: Text(message,
              style: TextStyle(
                  color: color, fontWeight: FontWeight.w600, height: 1.4)),
        ),
      ],
    );
  }
}

class _TimeEstimate extends StatelessWidget {
  const _TimeEstimate({required this.minutes});
  final int minutes;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Icon(Icons.timer_outlined,
            size: 14, color: AppColors.textSecondary),
        const SizedBox(width: 5),
        Text(
          'Estimated revision time: $minutes min',
          style: const TextStyle(
              color: AppColors.textSecondary, fontSize: 12),
        ),
      ],
    );
  }
}

// ── Misconceptions ────────────────────────────────────────────────────────────

class _WeakAreasSection extends StatelessWidget {
  const _WeakAreasSection({required this.report});
  final AiCoachReport report;

  @override
  Widget build(BuildContext context) {
    final codes = report.misconceptionCodes;
    return CoachSectionCard(
      icon: Icons.bug_report_rounded,
      title: 'Concepts to Review',
      accent: AppColors.orange,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            codes.length == 1
                ? 'There is 1 concept you should revisit. '
                    'Working through it will improve your mastery score.'
                : 'There are ${codes.length} concepts you should revisit. '
                    'Working through each will improve your mastery score.',
            style: const TextStyle(
                color: AppColors.textSecondary, height: 1.55),
          ),
          const SizedBox(height: 14),
          // Short chip row for quick overview
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: codes
                .map((c) => _MisconceptionChip(code: c))
                .toList(),
          ),
          const SizedBox(height: 16),
          // Detailed explanation cards
          ...codes.map((c) => _MisconceptionDetailCard(code: c)),
        ],
      ),
    );
  }
}

class _MisconceptionChip extends StatelessWidget {
  const _MisconceptionChip({required this.code});
  final String code;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: AppColors.orange.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.orange.withValues(alpha: 0.35)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.warning_amber_rounded,
              size: 12, color: AppColors.orange),
          const SizedBox(width: 5),
          Text(
            TopicLabels.misconceptionShort(code),
            style: const TextStyle(
              color: AppColors.orange,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _MisconceptionDetailCard extends StatelessWidget {
  const _MisconceptionDetailCard({required this.code});
  final String code;

  @override
  Widget build(BuildContext context) {
    final explanation = TopicLabels.misconception(code);
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.orange.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
              color: AppColors.orange.withValues(alpha: 0.2)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Padding(
              padding: EdgeInsets.only(top: 2),
              child: Icon(Icons.lightbulb_outline_rounded,
                  size: 16, color: AppColors.orange),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                explanation,
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  height: 1.5,
                  fontSize: 13,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Study Plan ────────────────────────────────────────────────────────────────

class _StudyPlanSection extends StatelessWidget {
  const _StudyPlanSection({required this.report});
  final AiCoachReport report;

  Color get _priorityColor {
    switch (report.studyPlan.priorityLevel.toUpperCase()) {
      case 'HIGH':
        return AppColors.pink;
      case 'MEDIUM':
        return AppColors.orange;
      default:
        return AppColors.lime;
    }
  }

  String get _priorityLabel {
    switch (report.studyPlan.priorityLevel.toUpperCase()) {
      case 'HIGH':
        return 'High priority';
      case 'MEDIUM':
        return 'Medium priority';
      default:
        return 'On track';
    }
  }

  @override
  Widget build(BuildContext context) {
    final plan = report.studyPlan;
    final accent = _priorityColor;
    return CoachSectionCard(
      icon: Icons.calendar_today_rounded,
      title: "Today's Study Plan",
      accent: accent,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(6),
                  border:
                      Border.all(color: accent.withValues(alpha: 0.35)),
                ),
                child: Text(
                  _priorityLabel,
                  style: TextStyle(
                    color: accent,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.4,
                  ),
                ),
              ),
              if (plan.estimatedTimeMinutes > 0) ...[
                const SizedBox(width: 10),
                const Icon(Icons.access_time_rounded,
                    size: 13, color: AppColors.textSecondary),
                const SizedBox(width: 4),
                Text(
                  '${plan.estimatedTimeMinutes} min',
                  style: const TextStyle(
                      color: AppColors.textSecondary, fontSize: 12),
                ),
              ],
            ],
          ),
          if (plan.reason.isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(
              TopicLabels.clean(plan.reason),
              style: const TextStyle(
                  color: AppColors.textSecondary, height: 1.5),
            ),
          ],
          const SizedBox(height: 12),
          ...plan.todayTasks.asMap().entries.map((e) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 9),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 22,
                    height: 22,
                    decoration: BoxDecoration(
                      color: accent.withValues(alpha: 0.12),
                      shape: BoxShape.circle,
                      border: Border.all(
                          color: accent.withValues(alpha: 0.35)),
                    ),
                    child: Center(
                      child: Text(
                        '${e.key + 1}',
                        style: TextStyle(
                          color: accent,
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      TopicLabels.clean(e.value),
                      style: const TextStyle(
                          color: AppColors.textPrimary, height: 1.45),
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}

// ── Next Action ───────────────────────────────────────────────────────────────

class _NextActionSection extends StatelessWidget {
  const _NextActionSection({
    required this.report,
    this.onNavigate,
    this.onRetryAssessment,
  });
  final AiCoachReport report;
  final void Function(int shellIndex)? onNavigate;
  final VoidCallback? onRetryAssessment;

  String get _guidanceText {
    final level = report.masteryLevel.toUpperCase();
    if (level == 'MASTERED' || level == 'ADVANCED') {
      return 'Outstanding! Your mastery is strong. '
          'You can advance to the next topic or reinforce your skills in AR Practice.';
    }
    if (level == 'PROFICIENT' || level == 'INTERMEDIATE') {
      return 'You are making solid progress. '
          'Review the revision plan above, then retry the assessment to reach Mastered.';
    }
    if (level == 'DEVELOPING') {
      return 'Keep going — you are improving. '
          'Work through the revision steps above before your next attempt.';
    }
    return 'Start with the Learning workspace to build your foundation, '
        'then attempt the assessment when you feel ready.';
  }

  @override
  Widget build(BuildContext context) {
    // Derive a targeted practice recommendation from the first misconception
    // code recorded for this topic.  Only shown for DSA_LINKED_LIST because
    // that is the only topic with a Flutter-side practice workspace so far.
    final practiceRec = report.topicCode == 'DSA_LINKED_LIST' &&
            report.misconceptionCodes.isNotEmpty
        ? topRecommendations(report.misconceptionCodes, limit: 1).firstOrNull
        : null;

    return CoachSectionCard(
      icon: Icons.rocket_launch_rounded,
      title: 'Your Next Step',
      accent: AppColors.violet,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _guidanceText,
            style: const TextStyle(
                color: AppColors.textSecondary, height: 1.55),
          ),
          const SizedBox(height: 18),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              _ActionButton(
                icon: Icons.school_rounded,
                label: 'Continue Learning',
                accent: AppColors.lime,
                onTap: onNavigate != null ? () => onNavigate!(1) : null,
              ),
              _ActionButton(
                icon: Icons.refresh_rounded,
                label: 'Retry Assessment',
                accent: AppColors.cyan,
                onTap: onRetryAssessment,
              ),
              _ActionButton(
                icon: Icons.insights_rounded,
                label: 'Open Analytics',
                accent: AppColors.orange,
                onTap: onNavigate != null ? () => onNavigate!(3) : null,
              ),
              _ActionButton(
                icon: Icons.view_in_ar_rounded,
                label: 'AR Practice',
                accent: AppColors.pink,
                onTap: onNavigate != null ? () => onNavigate!(2) : null,
              ),
              // "Practice Weak Area" — only rendered when:
              //   • The topic has a Flutter practice workspace (DSA_LINKED_LIST)
              //   • At least one misconception has a matching targeted task
              if (practiceRec != null)
                _ActionButton(
                  icon: Icons.fitness_center_rounded,
                  label: 'Practice ${practiceRec.conceptTitle}',
                  accent: AppColors.orange,
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => LinkedListConstructionScreen(
                        initialTaskId: practiceRec.taskId,
                      ),
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

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.icon,
    required this.label,
    required this.accent,
    this.onTap,
  });
  final IconData icon;
  final String label;
  final Color accent;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final active = onTap != null;
    return GlassCard(
      padding: EdgeInsets.zero,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: active
                  ? accent.withValues(alpha: 0.45)
                  : AppColors.textSecondary.withValues(alpha: 0.12),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon,
                  size: 17,
                  color: active ? accent : AppColors.textSecondary),
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  color: active ? accent : AppColors.textSecondary,
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
