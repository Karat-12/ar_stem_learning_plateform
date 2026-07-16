import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/progress_provider.dart';

class ProgressScreen extends StatefulWidget {
  const ProgressScreen({super.key});

  @override
  State<ProgressScreen> createState() => _ProgressScreenState();
}

class _ProgressScreenState extends State<ProgressScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ProgressProvider>().loadProgress();
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ProgressProvider>();

    return Scaffold(
      appBar: AppBar(title: const Text('Progress')),
      body: RefreshIndicator(
        onRefresh: () => provider.loadProgress(),
        child: Builder(
          builder: (_) {
            if (provider.isLoading) {
              return const Center(child: CircularProgressIndicator());
            }

            if (provider.errorMessage != null) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(provider.errorMessage!),
                ),
              );
            }

            if (provider.progressList.isEmpty) {
              return const Center(child: Text('No progress found yet.'));
            }

            return ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: provider.progressList.length,
              separatorBuilder: (_, _) => const SizedBox(height: 12),
              itemBuilder: (_, index) {
                final item = provider.progressList[index];
                return Card(
                  child: ListTile(
                    title: Text(
                      item.topicCode.isNotEmpty
                          ? item.topicCode
                          : 'Overall Progress',
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Completed sessions: ${item.completedSessions}'),
                        Text('Misconceptions: ${item.misconceptionCount}'),
                        Text('Mastery score: ${item.masteryScore}%'),
                        if (item.weakAreas.isNotEmpty)
                          Text('Weak areas: ${item.weakAreas.join(', ')}'),
                      ],
                    ),
                    trailing: CircleAvatar(
                      radius: 24,
                      backgroundColor: Theme.of(
                        context,
                      ).colorScheme.primaryContainer,
                      child: Text('${item.completionPercent}%'),
                    ),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}
