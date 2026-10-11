import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers/providers.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/models/service.dart';
import '../../../shared/widgets/common_widgets.dart';

final _allServicesProvider =
    FutureProvider.family<List<Service>, String>((ref, centerId) async {
  return ref.watch(serviceRepositoryProvider).getAllServicesForCenter(centerId);
});

class AdminServicesScreen extends ConsumerWidget {
  final String centerId;
  const AdminServicesScreen({super.key, required this.centerId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final services = ref.watch(_allServicesProvider(centerId));

    return Scaffold(
      appBar: AppBar(title: const Text('Services')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddDialog(context, ref),
        backgroundColor: AppColors.staffColor,
        icon: const Icon(Icons.add),
        label: const Text('Add Service'),
      ),
      body: RefreshIndicator(
        color: AppColors.accent,
        onRefresh: () => ref.refresh(_allServicesProvider(centerId).future),
        child: services.when(
          loading: () => const AppLoadingWidget(),
          error: (e, _) => AppErrorWidget(message: e.toString()),
          data: (list) {
            if (list.isEmpty) {
              return const AppEmptyWidget(
                message: 'No services configured yet.',
                icon: Icons.miscellaneous_services_outlined,
              );
            }
            return ListView.builder(
              padding: const EdgeInsets.fromLTRB(8, 8, 8, 80),
              itemCount: list.length,
              itemBuilder: (_, i) => _ServiceAdminCard(
                service: list[i],
                onRefresh: () => ref.refresh(_allServicesProvider(centerId)),
              ),
            );
          },
        ),
      ),
    );
  }

  void _showAddDialog(BuildContext context, WidgetRef ref) {
    final nameCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    final durationCtrl = TextEditingController(text: '10');
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Add Service'),
        content: Form(
          key: formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: nameCtrl,
                  decoration: const InputDecoration(labelText: 'Service Name'),
                  validator: (v) =>
                      (v == null || v.trim().isEmpty) ? 'Required' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: descCtrl,
                  decoration: const InputDecoration(labelText: 'Description'),
                  validator: (v) =>
                      (v == null || v.trim().isEmpty) ? 'Required' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: durationCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Est. Duration (minutes)',
                    helperText: 'PROTOTYPE ASSUMPTION — update based on real data',
                  ),
                  keyboardType: TextInputType.number,
                  validator: (v) =>
                      (v == null || int.tryParse(v) == null || int.parse(v) <= 0)
                          ? 'Enter a valid duration'
                          : null,
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              if (!formKey.currentState!.validate()) return;
              try {
                final newService = await ref.read(serviceRepositoryProvider).createService(
                  serviceCenterId: centerId,
                  name: nameCtrl.text.trim(),
                  description: descCtrl.text.trim(),
                  estimatedDurationMinutes: int.parse(durationCtrl.text.trim()),
                );

                // Auto-initialize today's queue row so students and staff can immediately use it
                try {
                  await ref.read(queueRepositoryProvider).getOrCreateTodayQueue(
                    serviceCenterId: centerId,
                    serviceId: newService.id,
                  );
                } catch (_) {}

                ref.invalidate(_allServicesProvider(centerId));
                if (context.mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Service "${newService.name}" created and queue initialized!'),
                      backgroundColor: AppColors.available,
                    ),
                  );
                }
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

class _ServiceAdminCard extends ConsumerWidget {
  final Service service;
  final VoidCallback onRefresh;
  const _ServiceAdminCard({required this.service, required this.onRefresh});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return AppCard(
      accentColor: service.isActive ? AppColors.staffColor : AppColors.textMuted,
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: AppColors.staffColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: Text(
                '${service.estimatedDurationMinutes}m',
                style: const TextStyle(
                  color: AppColors.staffColor,
                  fontWeight: FontWeight.w800,
                  fontSize: 12,
                ),
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(service.name,
                    style: const TextStyle(fontWeight: FontWeight.w700)),
                const SizedBox(height: 2),
                Text(service.description,
                    style: const TextStyle(
                        color: AppColors.textSecondary, fontSize: 12),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis),
                const SizedBox(height: 4),
                StatusChip(
                  label: service.isActive ? 'Active' : 'Inactive',
                  color: service.isActive ? AppColors.available : AppColors.textMuted,
                ),
              ],
            ),
          ),
          IconButton(
            icon: Icon(
              service.isActive
                  ? Icons.toggle_on_outlined
                  : Icons.toggle_off_outlined,
              color: service.isActive ? AppColors.available : AppColors.textMuted,
            ),
            onPressed: () async {
              await ref.read(serviceRepositoryProvider).updateService(
                service.copyWith(isActive: !service.isActive),
              );
              onRefresh();
            },
          ),
        ],
      ),
    );
  }
}
