import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/providers/providers.dart';
import '../../../core/router/app_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/extensions/extensions.dart';
import '../../../data/models/queue_entry.dart';
import '../../../data/models/counter.dart';
import '../../../data/models/service.dart';
import '../../../data/models/service_center.dart';
import '../../../domain/queue_state_machine.dart';
import '../../../shared/widgets/common_widgets.dart';

// Providers for staff counter flow
final _staffCentersProvider = FutureProvider<List<ServiceCenter>>((ref) async {
  return ref.watch(serviceRepositoryProvider).getActiveServiceCenters();
});

final _selectedCenterProvider = StateProvider<String?>((ref) => null);

final _countersStreamProvider =
    StreamProvider.family<List<Counter>, String>((ref, centerId) {
  return ref.watch(counterRepositoryProvider).watchCountersForCenter(centerId);
});

final _waitingEntriesStreamProvider =
    StreamProvider.family<List<QueueEntry>, String>((ref, queueId) {
  return ref.watch(queueRepositoryProvider).watchWaitingEntries(queueId);
});

final _centerServicesProvider =
    FutureProvider.family<List<Service>, String>((ref, centerId) async {
  return ref.watch(serviceRepositoryProvider).getServicesForCenter(centerId);
});

final _selectedCounterProvider = StateProvider<Counter?>((ref) => null);
final _activeQueueIdProvider = StateProvider<String?>((ref) => null);
final _activeServiceNameProvider = StateProvider<String?>((ref) => null);

final _todayServedCountProvider =
    FutureProvider.family<int, String>((ref, staffId) async {
  return ref.watch(queueRepositoryProvider).getTodayServedCount(staffId);
});

class CounterScreen extends ConsumerWidget {
  const CounterScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    final selectedCenterId = ref.watch(_selectedCenterProvider);
    final selectedCounter = ref.watch(_selectedCounterProvider);
    final queueId = ref.watch(_activeQueueIdProvider);
    final serviceName = ref.watch(_activeServiceNameProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          selectedCounter != null
              ? '${selectedCounter.name} — Staff Portal'
              : 'Counter Dashboard',
        ),
        actions: [
          if (queueId != null)
            IconButton(
              icon: const Icon(Icons.swap_horiz_outlined),
              tooltip: 'Switch Service / Queue',
              onPressed: () {
                ref.read(_activeQueueIdProvider.notifier).state = null;
                ref.read(_activeServiceNameProvider.notifier).state = null;
              },
            ),
          IconButton(
            icon: const Icon(Icons.account_circle_outlined),
            tooltip: 'My Profile',
            onPressed: () => context.push(AppRoutes.profile),
          ),
          IconButton(
            icon: const Icon(Icons.logout_outlined),
            tooltip: 'Sign Out',
            onPressed: () => ref.read(authRepositoryProvider).signOut(),
          ),
        ],
      ),
      body: Column(
        children: [
          _StaffHeader(
            staffName: user.fullName,
            counter: selectedCounter,
            onCounterStatusChanged: selectedCounter == null
                ? null
                : (newStatus) async {
                    await ref
                        .read(counterRepositoryProvider)
                        .updateCounterStatus(
                          counterId: selectedCounter.id,
                          status: newStatus,
                        );
                    ref.read(_selectedCounterProvider.notifier).state =
                        selectedCounter.copyWith(status: newStatus);
                  },
          ),
          if (selectedCenterId == null)
            Expanded(child: _CenterSelector())
          else if (selectedCounter == null)
            Expanded(child: _CounterSelector(centerId: selectedCenterId))
          else if (queueId == null)
            Expanded(
              child: _QueueActivator(
                counter: selectedCounter,
                centerId: selectedCenterId,
              ),
            )
          else
            Expanded(
              child: _LiveQueue(
                queueId: queueId,
                counter: selectedCounter,
                serviceName: serviceName ?? 'Service Queue',
              ),
            ),
        ],
      ),
    );
  }
}

class _StaffHeader extends StatelessWidget {
  final String staffName;
  final Counter? counter;
  final ValueChanged<CounterStatus>? onCounterStatusChanged;

  const _StaffHeader({
    required this.staffName,
    this.counter,
    this.onCounterStatusChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.staffColor, Color(0xFF1B5E20)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.staffColor.withValues(alpha: 0.3),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                staffName.initials,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                  fontSize: 16,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  staffName,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                  ),
                ),
                Text(
                  counter != null
                      ? 'Assigned to ${counter!.name}'
                      : 'Staff Member On Duty',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.8),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          if (counter != null && onCounterStatusChanged != null)
            _CounterStatusMenu(
              status: counter!.status,
              onChanged: onCounterStatusChanged!,
            )
          else ...[
            const Icon(Icons.circle, color: Colors.greenAccent, size: 10),
            const SizedBox(width: 6),
            const Text('On Duty',
                style: TextStyle(color: Colors.white70, fontSize: 12)),
          ],
        ],
      ),
    );
  }
}

class _CounterStatusMenu extends StatelessWidget {
  final CounterStatus status;
  final ValueChanged<CounterStatus> onChanged;

  const _CounterStatusMenu({required this.status, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final (color, label) = switch (status) {
      CounterStatus.available => (Colors.greenAccent, 'Available'),
      CounterStatus.serving => (Colors.blueAccent, 'Serving'),
      CounterStatus.paused => (Colors.orangeAccent, 'On Break'),
      CounterStatus.offline => (Colors.redAccent, 'Offline'),
    };

    return PopupMenuButton<CounterStatus>(
      onSelected: onChanged,
      color: AppColors.surfaceElevated,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.25),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color.withValues(alpha: 0.5)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.circle, color: color, size: 9),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(width: 2),
            const Icon(Icons.arrow_drop_down, color: Colors.white70, size: 16),
          ],
        ),
      ),
      itemBuilder: (_) => [
        const PopupMenuItem(
          value: CounterStatus.available,
          child: Row(
            children: [
              Icon(Icons.circle, color: Colors.green, size: 10),
              SizedBox(width: 8),
              Text('Available / Serving'),
            ],
          ),
        ),
        const PopupMenuItem(
          value: CounterStatus.paused,
          child: Row(
            children: [
              Icon(Icons.circle, color: Colors.orange, size: 10),
              SizedBox(width: 8),
              Text('On Short Break'),
            ],
          ),
        ),
        const PopupMenuItem(
          value: CounterStatus.offline,
          child: Row(
            children: [
              Icon(Icons.circle, color: Colors.red, size: 10),
              SizedBox(width: 8),
              Text('Counter Closed'),
            ],
          ),
        ),
      ],
    );
  }
}

class _CenterSelector extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final centers = ref.watch(_staffCentersProvider);
    return centers.when(
      loading: () => const AppLoadingWidget(message: 'Loading centers...'),
      error: (e, _) => AppErrorWidget(message: e.toString()),
      data: (list) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(20, 8, 20, 12),
            child: Text('Step 1: Select Service Center',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: list.length,
              itemBuilder: (_, i) => ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.staffColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.store_outlined, color: AppColors.staffColor),
                ),
                title: Text(list[i].name, style: const TextStyle(fontWeight: FontWeight.w600)),
                subtitle: Text(list[i].description, maxLines: 1, overflow: TextOverflow.ellipsis),
                trailing: const Icon(Icons.chevron_right),
                onTap: () =>
                    ref.read(_selectedCenterProvider.notifier).state = list[i].id,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CounterSelector extends ConsumerWidget {
  final String centerId;
  const _CounterSelector({required this.centerId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final counters = ref.watch(_countersStreamProvider(centerId));
    return counters.when(
      loading: () => const AppLoadingWidget(message: 'Loading counters...'),
      error: (e, _) => AppErrorWidget(message: e.toString()),
      data: (list) {
        if (list.isEmpty) {
          return const AppEmptyWidget(
            message: 'No counters configured at this center. Ask Admin to add one.',
            icon: Icons.point_of_sale_outlined,
          );
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
              child: Row(
                children: [
                  const Text('Step 2: Select Your Counter',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                  const Spacer(),
                  TextButton.icon(
                    onPressed: () =>
                        ref.read(_selectedCenterProvider.notifier).state = null,
                    icon: const Icon(Icons.arrow_back, size: 14),
                    label: const Text('Change Center', style: TextStyle(fontSize: 12)),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView.builder(
                itemCount: list.length,
                itemBuilder: (_, i) {
                  final c = list[i];
                  return ListTile(
                    leading: Icon(
                      Icons.point_of_sale,
                      color: c.status == CounterStatus.available
                          ? AppColors.available
                          : c.status == CounterStatus.serving
                              ? AppColors.serving
                              : AppColors.paused,
                    ),
                    title: Text(c.name, style: const TextStyle(fontWeight: FontWeight.w600)),
                    subtitle: StatusChip(
                      label: c.status.name.toUpperCase(),
                      color: c.status == CounterStatus.available
                          ? AppColors.available
                          : c.status == CounterStatus.serving
                              ? AppColors.serving
                              : AppColors.paused,
                    ),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () =>
                        ref.read(_selectedCounterProvider.notifier).state = c,
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }
}

class _QueueActivator extends ConsumerWidget {
  final Counter counter;
  final String centerId;
  const _QueueActivator({required this.counter, required this.centerId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final servicesAsync = ref.watch(_centerServicesProvider(centerId));

    return servicesAsync.when(
      loading: () => const AppLoadingWidget(message: 'Loading services...'),
      error: (e, _) => AppErrorWidget(message: e.toString()),
      data: (services) {
        if (services.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.miscellaneous_services_outlined, size: 56, color: AppColors.textMuted),
                  const SizedBox(height: 12),
                  const Text(
                    'No services configured for this center.',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => ref.read(_selectedCounterProvider.notifier).state = null,
                    child: const Text('Back to Counters'),
                  ),
                ],
              ),
            ),
          );
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 4),
              child: Row(
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Step 3: Select Service Queue to Serve',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                      ),
                      Text(
                        'Operating at ${counter.name}',
                        style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
                      ),
                    ],
                  ),
                  const Spacer(),
                  TextButton.icon(
                    onPressed: () =>
                        ref.read(_selectedCounterProvider.notifier).state = null,
                    icon: const Icon(Icons.arrow_back, size: 14),
                    label: const Text('Counter', style: TextStyle(fontSize: 12)),
                  ),
                ],
              ),
            ),
            const Divider(),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.all(12),
                itemCount: services.length,
                itemBuilder: (_, i) {
                  final service = services[i];
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: AppCard(
                      accentColor: AppColors.staffColor,
                      child: Row(
                        children: [
                          Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              color: AppColors.staffColor.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(Icons.assignment_outlined, color: AppColors.staffColor),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  service.name,
                                  style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  service.description,
                                  style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '~${service.estimatedDurationMinutes} mins/student',
                                  style: const TextStyle(color: AppColors.textMuted, fontSize: 11),
                                ),
                              ],
                            ),
                          ),
                          ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.staffColor,
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                            ),
                            icon: const Icon(Icons.play_circle_fill, size: 16),
                            label: const Text('Open Queue'),
                            onPressed: () async {
                              final queue = await ref
                                  .read(queueRepositoryProvider)
                                  .getOrCreateTodayQueue(
                                    serviceCenterId: counter.serviceCenterId,
                                    serviceId: service.id,
                                  );
                              ref.read(_activeServiceNameProvider.notifier).state = service.name;
                              ref.read(_activeQueueIdProvider.notifier).state = queue.id;
                            },
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }
}

class _LiveQueue extends ConsumerStatefulWidget {
  final String queueId;
  final Counter counter;
  final String serviceName;

  const _LiveQueue({
    required this.queueId,
    required this.counter,
    required this.serviceName,
  });

  @override
  ConsumerState<_LiveQueue> createState() => _LiveQueueState();
}

class _LiveQueueState extends ConsumerState<_LiveQueue> {
  bool _isActionLoading = false;

  @override
  Widget build(BuildContext context) {
    final entriesAsync = ref.watch(_waitingEntriesStreamProvider(widget.queueId));
    final user = ref.watch(currentUserProvider);
    final todayServedAsync = ref.watch(_todayServedCountProvider(user.id));
    final todayServedCount = todayServedAsync.value ?? 0;

    return entriesAsync.when(
      loading: () => const AppLoadingWidget(message: 'Connecting to live queue...'),
      error: (e, _) => AppErrorWidget(message: e.toString()),
      data: (entries) {
        final waiting = entries.where((e) => e.status == QueueEntryStatus.waiting).toList();
        final called = entries.where((e) => e.status == QueueEntryStatus.called).toList();
        final serving = entries.where((e) => e.status == QueueEntryStatus.serving).toList();

        final hasActiveSession = serving.isNotEmpty || called.isNotEmpty;

        return Column(
          children: [
            // Service context header & stats
            _QueueStatsHeader(
              serviceName: widget.serviceName,
              counter: widget.counter,
              waitingCount: waiting.length,
              calledCount: called.length,
              servingCount: serving.length,
              todayServedCount: todayServedCount,
              onChangeQueue: () {
                ref.read(_activeQueueIdProvider.notifier).state = null;
                ref.read(_activeServiceNameProvider.notifier).state = null;
              },
            ),

            // 1. CURRENTLY SERVING (Highest Priority: Service in progress)
            if (serving.isNotEmpty)
              _CurrentlyServingSection(
                entry: serving.first,
                counter: widget.counter,
                staffId: user.id,
                isLoading: _isActionLoading,
                nextWaitingEntry: waiting.firstOrNull,
                onCompleteService: () => _completeService(serving.first, user.id),
                onCompleteAndCallNext: waiting.isNotEmpty
                    ? () => _completeAndCallNext(
                          currentEntry: serving.first,
                          nextEntry: waiting.first,
                          staffId: user.id,
                        )
                    : null,
              ),

            // 2. CURRENTLY CALLED (Student called to counter, awaiting start)
            if (called.isNotEmpty)
              _CurrentlyCalledSection(
                entry: called.first,
                counter: widget.counter,
                staffId: user.id,
                isLoading: _isActionLoading,
                onStartService: () => _startService(called.first, user.id),
                onReannounce: () => _reannounce(called.first, user.id),
                onNoShow: () => _noShow(called.first, user.id),
              ),

            // 3. CALL NEXT WAITING STUDENT BUTTON (When staff is free)
            if (waiting.isNotEmpty && !hasActiveSession)
              _CallNextButton(
                nextEntry: waiting.first,
                staffId: user.id,
                counter: widget.counter,
                isLoading: _isActionLoading,
                onCallNext: () => _callNext(waiting.first, user.id),
              ),

            // 4. WAITING QUEUE LIST
            Expanded(
              child: waiting.isEmpty && !hasActiveSession
                  ? const AppEmptyWidget(
                      message: 'Queue is clear! No students waiting right now.',
                      icon: Icons.check_circle_outline,
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.fromLTRB(12, 6, 12, 24),
                      itemCount: waiting.length,
                      itemBuilder: (_, i) => _QueueEntryTile(
                        entry: waiting[i],
                        position: i + 1,
                        canCallNow: !hasActiveSession,
                        onCallNow: () => _callNext(waiting[i], user.id),
                      ),
                    ),
            ),
          ],
        );
      },
    );
  }

  // Action: Call Next Student
  Future<void> _callNext(QueueEntry entry, String staffId) async {
    setState(() => _isActionLoading = true);
    try {
      await ref.read(queueRepositoryProvider).callNext(
        entryId: entry.id,
        counterId: widget.counter.id,
        staffId: staffId,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Calling Token #${entry.tokenNumber} to ${widget.counter.name}'),
            backgroundColor: AppColors.called,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: AppColors.cancelled),
        );
      }
    } finally {
      if (mounted) setState(() => _isActionLoading = false);
    }
  }

  // Action: Start Service
  Future<void> _startService(QueueEntry entry, String staffId) async {
    setState(() => _isActionLoading = true);
    try {
      await ref.read(queueRepositoryProvider).startService(
        entryId: entry.id,
        counterId: widget.counter.id,
        staffId: staffId,
        serviceId: entry.serviceId,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Service started for Token #${entry.tokenNumber}'),
            backgroundColor: AppColors.serving,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: AppColors.cancelled),
        );
      }
    } finally {
      if (mounted) setState(() => _isActionLoading = false);
    }
  }

  // Action: Reannounce / Recall
  Future<void> _reannounce(QueueEntry entry, String staffId) async {
    setState(() => _isActionLoading = true);
    try {
      await ref.read(queueRepositoryProvider).reannounceEntry(
        entryId: entry.id,
        staffId: staffId,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Re-announced Token #${entry.tokenNumber}!'),
            backgroundColor: AppColors.called,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: AppColors.cancelled),
        );
      }
    } finally {
      if (mounted) setState(() => _isActionLoading = false);
    }
  }

  // Action: Complete Service
  Future<void> _completeService(QueueEntry entry, String staffId) async {
    setState(() => _isActionLoading = true);
    try {
      await ref.read(queueRepositoryProvider).completeService(
        entryId: entry.id,
        serviceId: entry.serviceId,
        staffId: staffId,
        startedAt: entry.serviceStartedAt,
      );
      ref.invalidate(_todayServedCountProvider(staffId));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Token #${entry.tokenNumber} completed successfully!'),
            backgroundColor: AppColors.available,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: AppColors.cancelled),
        );
      }
    } finally {
      if (mounted) setState(() => _isActionLoading = false);
    }
  }

  // Action: Complete and Call Next Person (1-Tap Rapid Flow)
  Future<void> _completeAndCallNext({
    required QueueEntry currentEntry,
    required QueueEntry nextEntry,
    required String staffId,
  }) async {
    setState(() => _isActionLoading = true);
    try {
      await ref.read(queueRepositoryProvider).completeAndCallNext(
        currentEntryId: currentEntry.id,
        serviceId: currentEntry.serviceId,
        staffId: staffId,
        startedAt: currentEntry.serviceStartedAt,
        nextEntryId: nextEntry.id,
        counterId: widget.counter.id,
      );
      ref.invalidate(_todayServedCountProvider(staffId));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Done Token #${currentEntry.tokenNumber}! Now Calling Token #${nextEntry.tokenNumber}',
            ),
            backgroundColor: AppColors.primary,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: AppColors.cancelled),
        );
      }
    } finally {
      if (mounted) setState(() => _isActionLoading = false);
    }
  }

  // Action: Mark No-Show
  Future<void> _noShow(QueueEntry entry, String staffId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: Text('Mark Token #${entry.tokenNumber} as No-Show?'),
        content: const Text(
          'The student has not responded to calls. This ticket will be marked as no-show and removed from active queue.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.noShow),
            child: const Text('Confirm No-Show'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() => _isActionLoading = true);
    try {
      await ref.read(queueRepositoryProvider).markNoShow(
        entryId: entry.id,
        staffId: staffId,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Token #${entry.tokenNumber} marked as No-Show.'),
            backgroundColor: AppColors.noShow,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: AppColors.cancelled),
        );
      }
    } finally {
      if (mounted) setState(() => _isActionLoading = false);
    }
  }
}

class _QueueStatsHeader extends StatelessWidget {
  final String serviceName;
  final Counter counter;
  final int waitingCount;
  final int calledCount;
  final int servingCount;
  final int todayServedCount;
  final VoidCallback onChangeQueue;

  const _QueueStatsHeader({
    required this.serviceName,
    required this.counter,
    required this.waitingCount,
    required this.calledCount,
    required this.servingCount,
    required this.todayServedCount,
    required this.onChangeQueue,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 4, 16, 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surfaceElevated,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: AppColors.staffColor.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.assignment, size: 16, color: AppColors.staffColor),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      serviceName,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      'Counter: ${counter.name}',
                      style: const TextStyle(color: AppColors.textSecondary, fontSize: 11),
                    ),
                  ],
                ),
              ),
              TextButton.icon(
                onPressed: onChangeQueue,
                icon: const Icon(Icons.switch_access_shortcut, size: 14),
                label: const Text('Switch', style: TextStyle(fontSize: 12)),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              _MiniStat(label: 'Waiting', count: waitingCount, color: AppColors.waiting),
              const SizedBox(width: 8),
              _MiniStat(label: 'Called', count: calledCount, color: AppColors.called),
              const SizedBox(width: 8),
              _MiniStat(label: 'Serving', count: servingCount, color: AppColors.serving),
              const SizedBox(width: 8),
              _MiniStat(label: 'Served Today', count: todayServedCount, color: AppColors.available),
            ],
          ),
        ],
      ),
    );
  }
}

class _MiniStat extends StatelessWidget {
  final String label;
  final int count;
  final Color color;

  const _MiniStat({required this.label, required this.count, required this.color});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withValues(alpha: 0.25)),
        ),
        child: Column(
          children: [
            Text(
              '$count',
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.w800,
                fontSize: 16,
              ),
            ),
            Text(
              label,
              style: const TextStyle(color: AppColors.textMuted, fontSize: 10),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// CURRENTLY SERVING SECTION (With Live Elapsed Timer & Complete / Next controls)
// ─────────────────────────────────────────────────────────────────────────────

class _CurrentlyServingSection extends StatefulWidget {
  final QueueEntry entry;
  final Counter counter;
  final String staffId;
  final bool isLoading;
  final QueueEntry? nextWaitingEntry;
  final VoidCallback onCompleteService;
  final VoidCallback? onCompleteAndCallNext;

  const _CurrentlyServingSection({
    required this.entry,
    required this.counter,
    required this.staffId,
    required this.isLoading,
    this.nextWaitingEntry,
    required this.onCompleteService,
    this.onCompleteAndCallNext,
  });

  @override
  State<_CurrentlyServingSection> createState() => _CurrentlyServingSectionState();
}

class _CurrentlyServingSectionState extends State<_CurrentlyServingSection> {
  Timer? _timer;
  late DateTime _startedAt;

  @override
  void initState() {
    super.initState();
    _startedAt = widget.entry.serviceStartedAt ?? DateTime.now();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void didUpdateWidget(covariant _CurrentlyServingSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.entry.id != oldWidget.entry.id) {
      _startedAt = widget.entry.serviceStartedAt ?? DateTime.now();
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  String _formatElapsed() {
    final diff = DateTime.now().difference(_startedAt);
    final minutes = diff.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = diff.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.serving.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.serving, width: 2),
        boxShadow: [
          BoxShadow(
            color: AppColors.serving.withValues(alpha: 0.2),
            blurRadius: 12,
            spreadRadius: 1,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Row
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.serving,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.person, color: Colors.white, size: 14),
                    SizedBox(width: 4),
                    Text(
                      'CURRENTLY SERVING',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w900,
                        fontSize: 11,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              // Stopwatch timer
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppColors.serving.withValues(alpha: 0.5)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.timer_outlined, size: 14, color: AppColors.serving),
                    const SizedBox(width: 4),
                    Text(
                      _formatElapsed(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontFamily: 'monospace',
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 14),

          // Token and Student Info Row
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  color: AppColors.serving.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.serving),
                ),
                child: Text(
                  '#${widget.entry.tokenNumber.toString().padLeft(3, '0')}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 26,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Token #${widget.entry.tokenNumber}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      widget.entry.userName ?? 'Student at Counter',
                      style: const TextStyle(color: Colors.white70, fontSize: 13),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Counter: ${widget.counter.name}',
                      style: const TextStyle(color: AppColors.textMuted, fontSize: 11),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Primary Actions
          Row(
            children: [
              // Complete Service Button
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: widget.isLoading ? null : widget.onCompleteService,
                  icon: const Icon(Icons.check_circle_outline, size: 18),
                  label: const Text('Complete Service'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.available,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    elevation: 2,
                  ),
                ),
              ),

              // Complete & Call Next Button (1-Tap!)
              if (widget.nextWaitingEntry != null && widget.onCompleteAndCallNext != null) ...[
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: widget.isLoading ? null : widget.onCompleteAndCallNext,
                    icon: const Icon(Icons.skip_next, size: 18),
                    label: Text(
                      'Done & Next (#${widget.nextWaitingEntry!.tokenNumber})',
                      overflow: TextOverflow.ellipsis,
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      elevation: 3,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// CURRENTLY CALLED SECTION
// ─────────────────────────────────────────────────────────────────────────────

class _CurrentlyCalledSection extends StatelessWidget {
  final QueueEntry entry;
  final Counter counter;
  final String staffId;
  final bool isLoading;
  final VoidCallback onStartService;
  final VoidCallback onReannounce;
  final VoidCallback onNoShow;

  const _CurrentlyCalledSection({
    required this.entry,
    required this.counter,
    required this.staffId,
    required this.isLoading,
    required this.onStartService,
    required this.onReannounce,
    required this.onNoShow,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.called.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.called, width: 2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.campaign, color: AppColors.called, size: 20),
              const SizedBox(width: 8),
              const Text(
                'STUDENT CALLED — Awaiting Arrival',
                style: TextStyle(
                  color: AppColors.called,
                  fontWeight: FontWeight.w800,
                  fontSize: 12,
                ),
              ),
              const Spacer(),
              Text(
                'Token #${entry.tokenNumber.toString().padLeft(3, '0')}',
                style: const TextStyle(
                  color: AppColors.called,
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              // Start Service Button
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: isLoading ? null : onStartService,
                  icon: const Icon(Icons.play_arrow, size: 18),
                  label: const Text('Start Service'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.serving,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              // Reannounce / Recall Button
              IconButton.filledTonal(
                tooltip: 'Ring / Announce Again',
                onPressed: isLoading ? null : onReannounce,
                icon: const Icon(Icons.volume_up, size: 20),
              ),
              const SizedBox(width: 8),
              // No-Show Button
              OutlinedButton(
                onPressed: isLoading ? null : onNoShow,
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.noShow,
                  side: const BorderSide(color: AppColors.noShow),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                ),
                child: const Text('No-Show'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// CALL NEXT BUTTON
// ─────────────────────────────────────────────────────────────────────────────

class _CallNextButton extends StatelessWidget {
  final QueueEntry nextEntry;
  final String staffId;
  final Counter counter;
  final bool isLoading;
  final VoidCallback onCallNext;

  const _CallNextButton({
    required this.nextEntry,
    required this.staffId,
    required this.counter,
    required this.isLoading,
    required this.onCallNext,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      child: SizedBox(
        width: double.infinity,
        height: 54,
        child: ElevatedButton.icon(
          onPressed: isLoading ? null : onCallNext,
          icon: const Icon(Icons.campaign, size: 22),
          label: Text(
            'Call Next — Token #${nextEntry.tokenNumber.toString().padLeft(3, '0')}',
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            elevation: 3,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// WAITING QUEUE ENTRY TILE
// ─────────────────────────────────────────────────────────────────────────────

class _QueueEntryTile extends StatelessWidget {
  final QueueEntry entry;
  final int position;
  final bool canCallNow;
  final VoidCallback onCallNow;

  const _QueueEntryTile({
    required this.entry,
    required this.position,
    required this.canCallNow,
    required this.onCallNow,
  });

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: AppColors.waiting.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                '$position',
                style: const TextStyle(
                  color: AppColors.waiting,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Token #${entry.tokenNumber.toString().padLeft(3, '0')}',
                  style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
                ),
                Text(
                  'Joined ${entry.joinedAt.timeAgo}',
                  style: const TextStyle(color: AppColors.textMuted, fontSize: 12),
                ),
              ],
            ),
          ),
          if (canCallNow && position == 1)
            ElevatedButton.icon(
              onPressed: onCallNow,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                minimumSize: Size.zero,
              ),
              icon: const Icon(Icons.campaign, size: 14),
              label: const Text('Call', style: TextStyle(fontSize: 12)),
            )
          else
            const StatusChip(label: 'WAITING', color: AppColors.waiting),
        ],
      ),
    );
  }
}
