import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers/providers.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/models/counter.dart';
import '../../../data/models/app_user.dart';
import '../../../domain/queue_state_machine.dart';
import '../../../shared/widgets/common_widgets.dart';

final _countersProvider =
    FutureProvider.family<List<Counter>, String>((ref, centerId) async {
  return ref.watch(counterRepositoryProvider).getCountersForCenter(centerId);
});

final _staffListProvider = FutureProvider<List<AppUser>>((ref) async {
  return ref.watch(counterRepositoryProvider).getAllStaff();
});

class AdminCountersScreen extends ConsumerWidget {
  final String centerId;
  const AdminCountersScreen({super.key, required this.centerId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final counters = ref.watch(_countersProvider(centerId));

    return Scaffold(
      appBar: AppBar(title: const Text('Counters'), leading: const BackButton()),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddDialog(context, ref),
        backgroundColor: AppColors.adminColor,
        icon: const Icon(Icons.add),
        label: const Text('Add Counter'),
      ),
      body: counters.when(
        loading: () => const AppLoadingWidget(),
        error: (e, _) => AppErrorWidget(message: e.toString()),
        data: (list) {
          if (list.isEmpty) {
            return const AppEmptyWidget(
              message: 'No counters configured for this center.',
              icon: Icons.point_of_sale_outlined,
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.fromLTRB(8, 8, 8, 80),
            itemCount: list.length,
            itemBuilder: (_, i) => _CounterAdminCard(
              counter: list[i],
              onRefresh: () => ref.refresh(_countersProvider(centerId)),
            ),
          );
        },
      ),
    );
  }

  void _showAddDialog(BuildContext context, WidgetRef ref) {
    final nameCtrl = TextEditingController();
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Add Counter'),
        content: Form(
          key: formKey,
          child: TextFormField(
            controller: nameCtrl,
            decoration: const InputDecoration(
              labelText: 'Counter Name',
              hintText: 'e.g. Counter 1, Window A',
            ),
            validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              if (!formKey.currentState!.validate()) return;
              try {
                await ref.read(counterRepositoryProvider).createCounter(
                  serviceCenterId: centerId,
                  name: nameCtrl.text.trim(),
                );
                ref.invalidate(_countersProvider(centerId));
                if (context.mounted) Navigator.pop(context);
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context)
                      .showSnackBar(SnackBar(content: Text('Error: $e')));
                }
              }
            },
            child: const Text('Create'),
          ),
        ],
      ),
    );
  }
}

class _CounterAdminCard extends ConsumerWidget {
  final Counter counter;
  final VoidCallback onRefresh;
  const _CounterAdminCard({required this.counter, required this.onRefresh});

  Color get _statusColor {
    switch (counter.status) {
      case CounterStatus.available: return AppColors.available;
      case CounterStatus.serving: return AppColors.serving;
      case CounterStatus.paused: return AppColors.paused;
      case CounterStatus.offline: return AppColors.offline;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return AppCard(
      accentColor: _statusColor,
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: _statusColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(Icons.point_of_sale, color: _statusColor),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(counter.name,
                        style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
                    if (counter.assignedStaffName != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        'Staff: ${counter.assignedStaffName}',
                        style: const TextStyle(
                            color: AppColors.textSecondary, fontSize: 12),
                      ),
                    ],
                  ],
                ),
              ),
              StatusChip(label: counter.status.name, color: _statusColor),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _assignStaff(context, ref),
                  icon: const Icon(Icons.person_add_outlined, size: 16),
                  label: const Text('Assign Staff'),
                ),
              ),
              const SizedBox(width: 8),
              PopupMenuButton<CounterStatus>(
                color: AppColors.surfaceElevated,
                onSelected: (status) async {
                  await ref.read(counterRepositoryProvider).updateCounterStatus(
                    counterId: counter.id,
                    status: status,
                  );
                  onRefresh();
                },
                itemBuilder: (_) => CounterStatus.values
                    .map((s) => PopupMenuItem(
                          value: s,
                          child: Text(s.name),
                        ))
                    .toList(),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    border: Border.all(color: AppColors.cardBorder),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('Status', style: TextStyle(fontSize: 13)),
                      Icon(Icons.arrow_drop_down),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                tooltip: 'Delete Counter',
                icon: const Icon(
                  Icons.delete_outline,
                  color: AppColors.cancelled,
                  size: 22,
                ),
                onPressed: () => _confirmDeleteCounter(context, ref),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _confirmDeleteCounter(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Delete Counter'),
        content: Text(
          'Are you sure you want to permanently delete Counter "${counter.name}"?',
          style: const TextStyle(color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.cancelled,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await ref.read(counterRepositoryProvider).deleteCounter(counter.id);
      onRefresh();
    }
  }

  Future<void> _assignStaff(BuildContext context, WidgetRef ref) async {
    final staff = await ref.read(_staffListProvider.future);
    if (staff.isEmpty) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No staff accounts found.')),
        );
      }
      return;
    }

    if (!context.mounted) return;
    final selected = await showDialog<AppUser>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Assign Staff Member'),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: staff.length,
            itemBuilder: (_, i) => ListTile(
              leading: const Icon(Icons.person_outline),
              title: Text(staff[i].fullName),
              subtitle: Text(staff[i].registrationNumber),
              onTap: () => Navigator.pop(context, staff[i]),
            ),
          ),
        ),
      ),
    );

    if (selected != null) {
      await ref.read(counterRepositoryProvider).assignStaff(
        counterId: counter.id,
        staffId: selected.id,
      );
      onRefresh();
    }
  }
}
