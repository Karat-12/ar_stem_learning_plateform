import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../shared/widgets/glass_card.dart';
import '../../shared/widgets/neon_action_card.dart';
import '../../shared/widgets/pulse_orb.dart';
import '../../shared/widgets/status_chip.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key, required this.onOpenSection});

  final ValueChanged<int> onOpenSection;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isWide = constraints.maxWidth >= 900;
          final contentWidth = isWide ? 1160.0 : constraints.maxWidth;

          return SingleChildScrollView(
            padding: EdgeInsets.symmetric(
              horizontal: isWide ? 40 : 20,
              vertical: 28,
            ),
            child: Center(
              child: ConstrainedBox(
                constraints: BoxConstraints(maxWidth: contentWidth),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _DashboardHero(isWide: isWide),
                    const SizedBox(height: 26),
                    _ActionGrid(isWide: isWide, onOpenSection: onOpenSection),
                    const SizedBox(height: 26),
                    _InsightStrip(isWide: isWide),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _DashboardHero extends StatelessWidget {
  const _DashboardHero({required this.isWide});

  final bool isWide;

  @override
  Widget build(BuildContext context) {
    final heroText = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const StatusChip(label: 'HoloSTEM Explorer'),
        const SizedBox(height: 18),
        Text(
          'HoloSTEM Explorer',
          style: Theme.of(context).textTheme.headlineLarge,
        ),
        const SizedBox(height: 16),
        Text(
          'A neon learning cockpit for interactive STEM labs, guided concept repair, and immersive AR-ready experiences.',
          style: Theme.of(context).textTheme.bodyLarge,
        ),
      ],
    );

    final scanner = GlassCard(
      padding: const EdgeInsets.all(24),
      child: SizedBox(
        height: isWide ? 260 : 220,
        child: Stack(
          alignment: Alignment.center,
          children: [
            const PulseOrb(color: AppColors.cyan, size: 190),
            const PulseOrb(color: AppColors.pink, size: 116, delay: 300),
            Icon(
              Icons.psychology_alt_outlined,
              size: isWide ? 92 : 76,
              color: AppColors.textPrimary,
            ),
            Positioned(
              bottom: 8,
              child: Text(
                'Misconception Signal Scanner',
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
          ],
        ),
      ),
    );

    if (!isWide) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [heroText, const SizedBox(height: 24), scanner],
      );
    }

    return Row(
      children: [
        Expanded(flex: 6, child: heroText),
        const SizedBox(width: 28),
        Expanded(flex: 4, child: scanner),
      ],
    );
  }
}

class _ActionGrid extends StatelessWidget {
  const _ActionGrid({required this.isWide, required this.onOpenSection});

  final bool isWide;
  final ValueChanged<int> onOpenSection;

  @override
  Widget build(BuildContext context) {
    final cards = [
      NeonActionCard(
        title: 'Start Learning',
        subtitle: 'Open advanced interactive STEM labs',
        icon: Icons.play_arrow_rounded,
        accent: AppColors.cyan,
        onTap: () => onOpenSection(1),
      ),
      NeonActionCard(
        title: 'Learning Path',
        subtitle: 'Explore labs by domain and topic in guided flow',
        icon: Icons.map_outlined,
        accent: AppColors.violet,
        onTap: () => onOpenSection(1),
      ),
      NeonActionCard(
        title: 'AR Simulation',
        subtitle: 'Reserved UI entry for AR mode',
        icon: Icons.view_in_ar_outlined,
        accent: AppColors.pink,
        onTap: () => onOpenSection(2),
      ),
      NeonActionCard(
        title: 'Progress Tracker',
        subtitle: 'Preview learning analytics area',
        icon: Icons.trending_up_rounded,
        accent: AppColors.lime,
        onTap: () => onOpenSection(3),
      ),
    ];

    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: isWide ? 4 : 1,
      crossAxisSpacing: 18,
      mainAxisSpacing: 18,
      childAspectRatio: isWide ? 1.08 : 2.55,
      children: cards,
    );
  }
}

class _InsightStrip extends StatelessWidget {
  const _InsightStrip({required this.isWide});

  final bool isWide;

  @override
  Widget build(BuildContext context) {
    final items = [
      _MetricData('Adaptivity', 'Ready', AppColors.cyan),
      _MetricData('Concept Graph', 'UI only', AppColors.violet),
      _MetricData('AR Engine', 'Pending', AppColors.pink),
    ];

    return GlassCard(
      child: Wrap(
        spacing: 18,
        runSpacing: 18,
        children: items
            .map(
              (item) => SizedBox(
                width: isWide ? 320 : double.infinity,
                child: _MetricTile(data: item),
              ),
            )
            .toList(),
      ),
    );
  }
}

class _MetricTile extends StatelessWidget {
  const _MetricTile({required this.data});

  final _MetricData data;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 48,
          decoration: BoxDecoration(
            color: data.color,
            borderRadius: BorderRadius.circular(99),
            boxShadow: [
              BoxShadow(
                color: data.color.withValues(alpha: 0.55),
                blurRadius: 18,
              ),
            ],
          ),
        ),
        const SizedBox(width: 14),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(data.label, style: Theme.of(context).textTheme.bodyMedium),
            const SizedBox(height: 4),
            Text(data.value, style: Theme.of(context).textTheme.headlineSmall),
          ],
        ),
      ],
    );
  }
}

class _MetricData {
  const _MetricData(this.label, this.value, this.color);

  final String label;
  final String value;
  final Color color;
}
