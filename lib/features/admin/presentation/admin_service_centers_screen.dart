import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/providers/providers.dart';
import '../../../core/router/app_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/models/service_center.dart';
import '../../../shared/widgets/common_widgets.dart';

final _allCentersProvider = FutureProvider<List<ServiceCenter>>((ref) async {
  return ref.watch(serviceRepositoryProvider).getAllServiceCenters();
});

class AdminServiceCentersScreen extends ConsumerWidget {
  const AdminServiceCentersScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final centers = ref.watch(_allCentersProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Service Centers')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddDialog(context, ref),
        backgroundColor: AppColors.accent,
        icon: const Icon(Icons.add),
        label: const Text('Add Center'),
      ),
      body: RefreshIndicator(
        color: AppColors.accent,
        onRefresh: () => ref.refresh(_allCentersProvider.future),
        child: centers.when(
          loading: () => const AppLoadingWidget(message: 'Loading...'),
          error: (e, _) => AppErrorWidget(
            message: e.toString(),
            onRetry: () => ref.refresh(_allCentersProvider),
          ),
          data: (list) {
            if (list.isEmpty) {
              return const AppEmptyWidget(
                message: 'No service centers yet. Add one!',
                icon: Icons.store_mall_directory_outlined,
              );
            }
            return ListView.builder(
              padding: const EdgeInsets.fromLTRB(8, 8, 8, 80),
              itemCount: list.length,
              itemBuilder: (_, i) => _CenterAdminCard(
                center: list[i],
                onRefresh: () => ref.refresh(_allCentersProvider),
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
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Add Service Center'),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: nameCtrl,
                decoration: const InputDecoration(labelText: 'Center Name'),
                validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: descCtrl,
                decoration: const InputDecoration(labelText: 'Description'),
                validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (!formKey.currentState!.validate()) return;
              try {
                await ref.read(serviceRepositoryProvider).createServiceCenter(
                  name: nameCtrl.text.trim(),
                  description: descCtrl.text.trim(),
                );
                ref.invalidate(_allCentersProvider);
                if (context.mounted) Navigator.pop(context);
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error: $e')),
                  );
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

class _CenterAdminCard extends ConsumerWidget {
  final ServiceCenter center;
  final VoidCallback onRefresh;
  const _CenterAdminCard({required this.center, required this.onRefresh});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return AppCard(
      accentColor: center.isActive ? AppColors.accent : AppColors.textMuted,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: (center.isActive ? AppColors.accent : AppColors.textMuted)
                      .withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.store_outlined,
                  color: center.isActive ? AppColors.accent : AppColors.textMuted,
                  size: 24,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(center.name,
                        style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
                    const SizedBox(height: 2),
                    Text(center.description,
                        style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis),
                  ],
                ),
              ),
              StatusChip(
                label: center.isActive ? 'Active' : 'Inactive',
                color: center.isActive ? AppColors.available : AppColors.textMuted,
              ),
            ],
          ),
          const SizedBox(height: 14),
          const Divider(height: 1),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => context.push(
                    AppRoutes.adminServices.replaceFirst(':centerId', center.id),
                  ),
                  icon: const Icon(Icons.assignment_outlined, size: 16),
                  label: const Text('Services', style: TextStyle(fontSize: 12)),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    side: const BorderSide(color: AppColors.cardBorder),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => context.push(
                    AppRoutes.adminCounters.replaceFirst(':centerId', center.id),
                  ),
                  icon: const Icon(Icons.point_of_sale_outlined, size: 16),
                  label: const Text('Counters', style: TextStyle(fontSize: 12)),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    side: const BorderSide(color: AppColors.cardBorder),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                tooltip: center.isActive ? 'Deactivate Center' : 'Activate Center',
                icon: Icon(
                  center.isActive ? Icons.toggle_on : Icons.toggle_off,
                  color: center.isActive ? AppColors.available : AppColors.textMuted,
                  size: 28,
                ),
                onPressed: () async {
                  await ref.read(serviceRepositoryProvider).updateServiceCenter(
                    center.copyWith(isActive: !center.isActive),
                  );
                  onRefresh();
                },
              ),
            ],
          ),
        ],
      ),
    );
  }
}
