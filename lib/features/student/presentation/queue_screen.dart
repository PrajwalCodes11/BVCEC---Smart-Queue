import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/errors/app_exception.dart';
import '../../../core/extensions/extensions.dart';
import '../../../core/providers/providers.dart';
import '../../../core/services/notification_service.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/ewt_calculator.dart';
import '../../../data/models/queue_entry.dart';
import '../../../domain/queue_state_machine.dart';
import '../../../shared/widgets/common_widgets.dart';
import '../providers/student_providers.dart';

final _queueEntryStreamProvider =
    StreamProvider.family<QueueEntry?, String>((ref, entryId) {
  return ref.watch(queueRepositoryProvider).watchEntry(entryId);
});

final _positionProvider =
    FutureProvider.family<int, ({String queueId, int tokenNumber})>((ref, arg) async {
  return ref.watch(queueRepositoryProvider).getPositionInQueue(arg.queueId, arg.tokenNumber);
});

class QueueScreen extends ConsumerWidget {
  final String entryId;
  const QueueScreen({super.key, required this.entryId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.listen<AsyncValue<QueueEntry?>>(_queueEntryStreamProvider(entryId), (prev, next) {
      final oldEntry = prev?.value;
      final newEntry = next.value;
      if (newEntry != null && oldEntry != null) {
        if (oldEntry.status != QueueEntryStatus.called &&
            newEntry.status == QueueEntryStatus.called) {
          NotificationService.instance.notifyTokenCalled(
            tokenNumber: newEntry.tokenNumber,
            counterName: newEntry.counterName,
          );
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                backgroundColor: AppColors.called,
                behavior: SnackBarBehavior.floating,
                duration: const Duration(seconds: 10),
                content: Row(
                  children: [
                    const Icon(Icons.campaign, color: Colors.white, size: 28),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Token #${newEntry.tokenNumber} is called! ${newEntry.counterName != null ? "Proceed to ${newEntry.counterName}" : "Please approach the counter"}',
                        style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }
        }
      }
    });

    final entryAsync = ref.watch(_queueEntryStreamProvider(entryId));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Live Queue Ticket'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.canPop() ? context.pop() : context.go('/student'),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh',
            onPressed: () => ref.refresh(_queueEntryStreamProvider(entryId)),
          ),
        ],
      ),
      body: entryAsync.when(
        loading: () => const AppLoadingWidget(message: 'Connecting to live queue...'),
        error: (e, _) => AppErrorWidget(
          message: e.toString(),
          onRetry: () => ref.refresh(_queueEntryStreamProvider(entryId)),
        ),
        data: (entry) {
          if (entry == null) {
            return const AppEmptyWidget(
              message: 'Queue entry not found or expired.',
              icon: Icons.search_off,
            );
          }
          return _QueueDetails(entry: entry);
        },
      ),
    );
  }
}

class _QueueDetails extends ConsumerWidget {
  final QueueEntry entry;
  const _QueueDetails({required this.entry});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isActive = entry.status == QueueEntryStatus.waiting ||
        entry.status == QueueEntryStatus.called;

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      child: Column(
        children: [
          // Step progress indicator
          _QueueStepIndicator(status: entry.status),
          const SizedBox(height: 20),

          // Digital Ticket Card
          _DigitalTicketCard(entry: entry),
          const SizedBox(height: 20),

          // Status-specific banner cards
          if (entry.status == QueueEntryStatus.called)
            _CalledAlertCard(entry: entry),
          if (entry.status == QueueEntryStatus.serving)
            _ServingCard(entry: entry),
          if (entry.status == QueueEntryStatus.waiting)
            _WaitingInfoCard(entry: entry),
          if (entry.status == QueueEntryStatus.completed)
            _CompletedCard(entry: entry),
          if (entry.status == QueueEntryStatus.cancelled ||
              entry.status == QueueEntryStatus.noShow)
            _TerminalCard(entry: entry),

          const SizedBox(height: 16),

          // Helpful Instructions
          _HelpfulTipsCard(status: entry.status, counterName: entry.counterName),

          const SizedBox(height: 20),

          // Cancel Action
          if (isActive)
            _CancelButton(entry: entry),

          const SizedBox(height: 16),
          _EventTimeline(entry: entry),
        ],
      ),
    );
  }
}

class _QueueStepIndicator extends StatelessWidget {
  final QueueEntryStatus status;
  const _QueueStepIndicator({required this.status});

  int get _currentStepIndex {
    switch (status) {
      case QueueEntryStatus.waiting:
        return 0;
      case QueueEntryStatus.called:
        return 1;
      case QueueEntryStatus.serving:
        return 2;
      case QueueEntryStatus.completed:
        return 3;
      default:
        return 0;
    }
  }

  @override
  Widget build(BuildContext context) {
    final steps = ['In Queue', 'Called', 'Serving', 'Done'];
    final currentIndex = _currentStepIndex;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: AppColors.surfaceElevated,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Row(
        children: List.generate(steps.length * 2 - 1, (index) {
          if (index.isOdd) {
            final stepBefore = index ~/ 2;
            final isDone = stepBefore < currentIndex;
            return Expanded(
              child: Container(
                height: 2,
                color: isDone ? AppColors.accent : AppColors.cardBorder,
              ),
            );
          }

          final stepIndex = index ~/ 2;
          final isDone = stepIndex < currentIndex;
          final isCurrent = stepIndex == currentIndex;

          final color = isDone
              ? AppColors.accent
              : isCurrent
                  ? (status == QueueEntryStatus.called ? AppColors.called : AppColors.accent)
                  : AppColors.textMuted;

          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 26,
                height: 26,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isCurrent
                      ? color.withValues(alpha: 0.2)
                      : isDone
                          ? color
                          : AppColors.surface,
                  border: Border.all(color: color, width: 2),
                ),
                child: Center(
                  child: isDone
                      ? const Icon(Icons.check, size: 14, color: Colors.white)
                      : Text(
                          '${stepIndex + 1}',
                          style: TextStyle(
                            color: isCurrent ? color : AppColors.textMuted,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                steps[stepIndex],
                style: TextStyle(
                  fontSize: 10,
                  color: isCurrent ? Colors.white : AppColors.textMuted,
                  fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            ],
          );
        }),
      ),
    );
  }
}

class _DigitalTicketCard extends StatelessWidget {
  final QueueEntry entry;
  const _DigitalTicketCard({required this.entry});

  Color get _statusColor {
    switch (entry.status) {
      case QueueEntryStatus.waiting:
        return AppColors.waiting;
      case QueueEntryStatus.called:
        return AppColors.called;
      case QueueEntryStatus.serving:
        return AppColors.serving;
      case QueueEntryStatus.completed:
        return AppColors.completed;
      default:
        return AppColors.cancelled;
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = _statusColor;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.5), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.2),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          // Top Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(18)),
            ),
            child: Row(
              children: [
                const Icon(Icons.school, size: 18, color: Colors.white70),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text(
                    'SMARTQUEUE PASS',
                    style: TextStyle(
                      fontSize: 11,
                      letterSpacing: 1.5,
                      fontWeight: FontWeight.w800,
                      color: Colors.white70,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 8),
                StatusChip(
                  label: entry.status.name.replaceAll('noShow', 'No Show').toUpperCase(),
                  color: color,
                ),
              ],
            ),
          ),

          // Main Token Content
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 20, 24, 16),
            child: Column(
              children: [
                Text(
                  entry.serviceName ?? 'Campus Service',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.3,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 6),
                const Text(
                  'YOUR QUEUE TOKEN',
                  style: TextStyle(
                    fontSize: 11,
                    color: AppColors.textMuted,
                    letterSpacing: 3,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  '#${entry.tokenNumber}',
                  style: TextStyle(
                    fontSize: 64,
                    fontWeight: FontWeight.w900,
                    color: color,
                    letterSpacing: -2,
                    height: 1.1,
                  ),
                ),
                const SizedBox(height: 4),
                if (entry.counterName != null)
                  Container(
                    margin: const EdgeInsets.only(top: 6),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppColors.called.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: AppColors.called),
                    ),
                    child: Text(
                      'Counter: ${entry.counterName}',
                      style: const TextStyle(
                        color: AppColors.called,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ),
              ],
            ),
          ),

          // Dashed Divider with Notches
          Row(
            children: [
              Container(
                width: 14,
                height: 28,
                decoration: const BoxDecoration(
                  color: AppColors.background,
                  borderRadius: BorderRadius.horizontal(right: Radius.circular(14)),
                ),
              ),
              Expanded(
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final count = (constraints.constrainWidth() / 10).floor();
                    return Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: List.generate(
                        count,
                        (_) => const SizedBox(
                          width: 5,
                          height: 1.5,
                          child: DecoratedBox(
                            decoration: BoxDecoration(color: AppColors.cardBorder),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
              Container(
                width: 14,
                height: 28,
                decoration: const BoxDecoration(
                  color: AppColors.background,
                  borderRadius: BorderRadius.horizontal(left: Radius.circular(14)),
                ),
              ),
            ],
          ),

          // Bottom Barcode & Meta Info
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 14, 20, 18),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Joined at', style: TextStyle(color: AppColors.textMuted, fontSize: 11)),
                    Text(
                      entry.joinedAt.toDisplayTime(),
                      style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                    ),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    const Text('Ticket ID', style: TextStyle(color: AppColors.textMuted, fontSize: 11)),
                    Text(
                      entry.id.substring(0, 8).toUpperCase(),
                      style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _WaitingInfoCard extends ConsumerWidget {
  final QueueEntry entry;
  const _WaitingInfoCard({required this.entry});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final positionAsync = ref.watch(
      _positionProvider((queueId: entry.queueId, tokenNumber: entry.tokenNumber)),
    );
    final ewt = entry.estimatedWaitMinutes;

    return Row(
      children: [
        Expanded(
          child: _InfoTile(
            icon: Icons.people_outline,
            label: 'People Ahead',
            value: positionAsync.when(
              data: (pos) => pos <= 1 ? 'Next Up!' : '${pos - 1} ahead',
              loading: () => '...',
              error: (err, stack) => '1 ahead',
            ),
            color: AppColors.waiting,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _InfoTile(
            icon: Icons.timer_outlined,
            label: 'Estimated Wait',
            value: ewt != null ? EwtCalculator.formatWait(ewt) : 'Calculating...',
            color: AppColors.accent,
          ),
        ),
      ],
    );
  }
}

class _CalledAlertCard extends StatelessWidget {
  final QueueEntry entry;
  const _CalledAlertCard({required this.entry});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.called.withValues(alpha: 0.25),
            AppColors.called.withValues(alpha: 0.08),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.called, width: 2),
      ),
      child: Column(
        children: [
          const Icon(Icons.campaign, color: AppColors.called, size: 48),
          const SizedBox(height: 10),
          const Text(
            '🔔 YOUR TOKEN HAS BEEN CALLED!',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w900,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            entry.counterName != null
                ? 'Please proceed immediately to ${entry.counterName}.'
                : 'Please report to the counter service desk immediately.',
            style: const TextStyle(color: Colors.white70, fontSize: 14),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _ServingCard extends StatelessWidget {
  final QueueEntry entry;
  const _ServingCard({required this.entry});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.serving.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.serving, width: 1.5),
      ),
      child: Column(
        children: const [
          Icon(Icons.check_circle_outline, color: AppColors.serving, size: 44),
          SizedBox(height: 8),
          Text(
            'You are being served',
            style: TextStyle(
              color: AppColors.serving,
              fontSize: 18,
              fontWeight: FontWeight.w800,
            ),
          ),
          SizedBox(height: 4),
          Text(
            'Your counter service is currently in progress.',
            style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
          ),
        ],
      ),
    );
  }
}

class _CompletedCard extends StatelessWidget {
  final QueueEntry entry;
  const _CompletedCard({required this.entry});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.completed.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.completed, width: 1.5),
      ),
      child: Column(
        children: [
          const Icon(Icons.task_alt, color: AppColors.completed, size: 44),
          const SizedBox(height: 8),
          const Text(
            'Service Completed ✓',
            style: TextStyle(
              color: AppColors.completed,
              fontSize: 18,
              fontWeight: FontWeight.w800,
            ),
          ),
          if (entry.completedAt != null) ...[
            const SizedBox(height: 4),
            Text(
              'Completed at ${entry.completedAt!.toDisplayTime()}',
              style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
            ),
          ],
        ],
      ),
    );
  }
}

class _TerminalCard extends StatelessWidget {
  final QueueEntry entry;
  const _TerminalCard({required this.entry});

  @override
  Widget build(BuildContext context) {
    final isNoShow = entry.status == QueueEntryStatus.noShow;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.cancelled.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.cancelled.withValues(alpha: 0.4)),
      ),
      child: Column(
        children: [
          Icon(
            isNoShow ? Icons.person_off_outlined : Icons.cancel_outlined,
            color: AppColors.cancelled,
            size: 44,
          ),
          const SizedBox(height: 8),
          Text(
            isNoShow ? 'Marked as No-Show' : 'Queue Entry Cancelled',
            style: const TextStyle(
              color: AppColors.cancelled,
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _HelpfulTipsCard extends StatelessWidget {
  final QueueEntryStatus status;
  final String? counterName;

  const _HelpfulTipsCard({required this.status, this.counterName});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surfaceElevated,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.lightbulb_outline, color: AppColors.accent, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              status == QueueEntryStatus.called
                  ? 'Keep this screen open and show your token number to the counter staff at ${counterName ?? "the counter"}.'
                  : 'You do not need to wait right at the door. Relax in campus study areas; your phone will alert you when your turn arrives.',
              style: const TextStyle(color: AppColors.textSecondary, fontSize: 12.5, height: 1.4),
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _InfoTile({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(height: 6),
          Text(label, style: const TextStyle(color: AppColors.textMuted, fontSize: 11)),
          const SizedBox(height: 2),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 17,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _CancelButton extends ConsumerWidget {
  final QueueEntry entry;
  const _CancelButton({required this.entry});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return OutlinedButton.icon(
      onPressed: () => _confirmCancel(context, ref),
      icon: const Icon(Icons.cancel_outlined, color: AppColors.cancelled, size: 18),
      label: const Text('Cancel My Ticket'),
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.cancelled,
        side: const BorderSide(color: AppColors.cancelled),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      ),
    );
  }

  Future<void> _confirmCancel(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Cancel Queue Ticket?'),
        content: const Text(
          'You will forfeit your place in line and your token number. This action cannot be undone.',
          style: TextStyle(color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Keep Ticket')),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.cancelled),
            child: const Text('Yes, Cancel'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;
    if (!context.mounted) return;

    // Show cancellation loading dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(
        child: CircularProgressIndicator(color: AppColors.cancelled),
      ),
    );

    try {
      final user = ref.read(currentUserProvider);
      await ref.read(queueRepositoryProvider).cancelEntry(
        entryId: entry.id,
        currentStatus: entry.status.toDbString(),
        actorId: user.id,
      );

      // Invalidate active entries so home screen immediately reflects the change
      ref.invalidate(studentActiveEntriesProvider);

      if (context.mounted) {
        context.pop(); // dismiss loading dialog
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Queue ticket cancelled successfully.'),
            behavior: SnackBarBehavior.floating,
          ),
        );
        if (context.canPop()) {
          context.pop();
        } else {
          context.go('/student');
        }
      }
    } catch (e) {
      if (context.mounted) {
        context.pop(); // dismiss loading dialog
        final message = e is AppException
            ? e.message
            : e.toString().replaceAll('Exception:', '').trim();

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(message),
            backgroundColor: AppColors.cancelled,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }
}

class _EventTimeline extends StatelessWidget {
  final QueueEntry entry;
  const _EventTimeline({required this.entry});

  @override
  Widget build(BuildContext context) {
    final events = <(String, DateTime?, IconData, Color)>[
      ('Joined Queue', entry.joinedAt, Icons.login, AppColors.waiting),
      if (entry.calledAt != null)
        ('Called to Counter', entry.calledAt, Icons.campaign, AppColors.called),
      if (entry.serviceStartedAt != null)
        ('Service In Progress', entry.serviceStartedAt, Icons.play_arrow, AppColors.serving),
      if (entry.completedAt != null)
        ('Service Completed', entry.completedAt, Icons.check_circle, AppColors.completed),
    ];

    if (events.length <= 1) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Ticket Activity',
          style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
        ),
        const SizedBox(height: 10),
        ...events.map(
          (e) => Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(
              children: [
                Icon(e.$3, color: e.$4, size: 16),
                const SizedBox(width: 10),
                Text(e.$1, style: TextStyle(color: e.$4, fontWeight: FontWeight.w600, fontSize: 13)),
                const Spacer(),
                if (e.$2 != null)
                  Text(
                    e.$2!.toDisplayTime(),
                    style: const TextStyle(color: AppColors.textMuted, fontSize: 12),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
