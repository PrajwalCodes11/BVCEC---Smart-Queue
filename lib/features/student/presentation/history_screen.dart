import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/extensions/extensions.dart';
import '../../../core/providers/providers.dart';
import '../../../core/router/app_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/models/queue_entry.dart';
import '../../../domain/queue_state_machine.dart';
import '../../../shared/widgets/common_widgets.dart';

final _historyProvider = FutureProvider<List<QueueEntry>>((ref) async {
  final user = ref.watch(currentUserProvider);
  return ref.watch(queueRepositoryProvider).getStudentHistory(user.id);
});

class HistoryScreen extends ConsumerStatefulWidget {
  const HistoryScreen({super.key});

  @override
  ConsumerState<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends ConsumerState<HistoryScreen> {
  String _filter = 'All';

  @override
  Widget build(BuildContext context) {
    final history = ref.watch(_historyProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Queue History'),
        leading: const BackButton(),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh',
            onPressed: () => ref.refresh(_historyProvider),
          ),
        ],
      ),
      body: Column(
        children: [
          // Filter Chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: Row(
              children: ['All', 'Active', 'Completed', 'Cancelled'].map((tag) {
                final isSelected = _filter == tag;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: FilterChip(
                    label: Text(tag),
                    selected: isSelected,
                    onSelected: (_) => setState(() => _filter = tag),
                    selectedColor: AppColors.primaryLight.withValues(alpha: 0.3),
                    checkmarkColor: AppColors.accent,
                    backgroundColor: AppColors.surfaceElevated,
                    labelStyle: TextStyle(
                      color: isSelected ? AppColors.accent : AppColors.textSecondary,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      fontSize: 13,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                      side: BorderSide(
                        color: isSelected ? AppColors.accent : AppColors.cardBorder,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),

          // History list
          Expanded(
            child: history.when(
              loading: () => const AppLoadingWidget(message: 'Loading queue history...'),
              error: (e, _) => AppErrorWidget(
                message: e.toString(),
                onRetry: () => ref.refresh(_historyProvider),
              ),
              data: (list) {
                final filtered = list.where((e) {
                  if (_filter == 'All') return true;
                  if (_filter == 'Active') {
                    return e.status == QueueEntryStatus.waiting ||
                        e.status == QueueEntryStatus.called ||
                        e.status == QueueEntryStatus.serving;
                  }
                  if (_filter == 'Completed') {
                    return e.status == QueueEntryStatus.completed;
                  }
                  if (_filter == 'Cancelled') {
                    return e.status == QueueEntryStatus.cancelled ||
                        e.status == QueueEntryStatus.noShow;
                  }
                  return true;
                }).toList();

                if (filtered.isEmpty) {
                  return AppEmptyWidget(
                    message: _filter == 'All'
                        ? 'You haven\'t joined any queues yet.'
                        : 'No $_filter queue entries found.',
                    icon: Icons.history_toggle_off,
                  );
                }

                return RefreshIndicator(
                  color: AppColors.accent,
                  onRefresh: () async => ref.refresh(_historyProvider),
                  child: ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 20),
                    itemCount: filtered.length,
                    itemBuilder: (_, i) => _HistoryCard(entry: filtered[i]),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _HistoryCard extends StatelessWidget {
  final QueueEntry entry;
  const _HistoryCard({required this.entry});

  Color get _color {
    switch (entry.status) {
      case QueueEntryStatus.completed:
        return AppColors.completed;
      case QueueEntryStatus.cancelled:
        return AppColors.cancelled;
      case QueueEntryStatus.noShow:
        return AppColors.noShow;
      case QueueEntryStatus.waiting:
        return AppColors.waiting;
      case QueueEntryStatus.called:
        return AppColors.called;
      case QueueEntryStatus.serving:
        return AppColors.serving;
      default:
        return AppColors.textMuted;
    }
  }

  bool get _isActive =>
      entry.status == QueueEntryStatus.waiting ||
      entry.status == QueueEntryStatus.called ||
      entry.status == QueueEntryStatus.serving;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () {
          // Navigate to live ticket for active entries, or view summary
          if (_isActive) {
            context.push(AppRoutes.queue.replaceFirst(':entryId', entry.id));
          } else {
            _showSummarySheet(context);
          }
        },
        child: AppCard(
          accentColor: _color,
          child: Row(
            children: [
              // Token Badge
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: _color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: _color.withValues(alpha: 0.3)),
                ),
                child: Center(
                  child: Text(
                    '#${entry.tokenNumber}',
                    style: TextStyle(
                      color: _color,
                      fontWeight: FontWeight.w900,
                      fontSize: 16,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      entry.serviceName ?? 'Campus Service',
                      style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      entry.joinedAt.toDisplayDateTime(),
                      style: const TextStyle(color: AppColors.textMuted, fontSize: 12),
                    ),
                    if (entry.counterName != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        'Counter: ${entry.counterName}',
                        style: const TextStyle(color: AppColors.textSecondary, fontSize: 11),
                      ),
                    ],
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  StatusChip(
                    label: entry.status.name.replaceAll('noShow', 'No-Show'),
                    color: _color,
                  ),
                  if (_isActive) ...[
                    const SizedBox(height: 4),
                    const Text(
                      'Tap to View >',
                      style: TextStyle(color: AppColors.accent, fontSize: 10, fontWeight: FontWeight.bold),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showSummarySheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  'Token #${entry.tokenNumber}',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    color: _color,
                  ),
                ),
                const Spacer(),
                StatusChip(label: entry.status.name, color: _color),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              entry.serviceName ?? 'Campus Service',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
            ),
            const Divider(height: 24, color: AppColors.cardBorder),
            _sheetRow('Joined At', entry.joinedAt.toDisplayDateTime()),
            if (entry.calledAt != null)
              _sheetRow('Called At', entry.calledAt!.toDisplayTime()),
            if (entry.completedAt != null)
              _sheetRow('Completed At', entry.completedAt!.toDisplayTime()),
            if (entry.counterName != null)
              _sheetRow('Counter', entry.counterName!),
            _sheetRow('Ticket ID', entry.id),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Close'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _sheetRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: AppColors.textMuted, fontSize: 13)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
        ],
      ),
    );
  }
}
