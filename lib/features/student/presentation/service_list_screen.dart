import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/errors/app_exception.dart';
import '../../../core/providers/providers.dart';
import '../../../core/router/app_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/ewt_calculator.dart';
import '../../../data/models/queue_entry.dart';
import '../../../data/models/service.dart';
import '../../../shared/widgets/common_widgets.dart';
import '../providers/student_providers.dart';

final _servicesProvider =
    FutureProvider.family<List<Service>, String>((ref, centerId) async {
  return ref.watch(serviceRepositoryProvider).getServicesForCenter(centerId);
});

class ServiceListScreen extends ConsumerStatefulWidget {
  final String centerId;
  const ServiceListScreen({super.key, required this.centerId});

  @override
  ConsumerState<ServiceListScreen> createState() => _ServiceListScreenState();
}

class _ServiceListScreenState extends ConsumerState<ServiceListScreen> {
  String _searchQuery = '';
  final TextEditingController _searchCtrl = TextEditingController();

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final servicesAsync = ref.watch(_servicesProvider(widget.centerId));
    final activeEntriesAsync = ref.watch(studentActiveEntriesProvider);
    final activeEntries = activeEntriesAsync.value ?? <QueueEntry>[];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Available Services'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh',
            onPressed: () {
              ref.invalidate(_servicesProvider(widget.centerId));
              ref.invalidate(studentActiveEntriesProvider);
            },
          ),
        ],
      ),
      body: servicesAsync.when(
        loading: () => const AppLoadingWidget(message: 'Loading services...'),
        error: (e, _) => AppErrorWidget(
          message: e.toString(),
          onRetry: () {
            ref.invalidate(_servicesProvider(widget.centerId));
            ref.invalidate(studentActiveEntriesProvider);
          },
        ),
        data: (allServices) {
          if (allServices.isEmpty) {
            return const AppEmptyWidget(
              message: 'No services available at this center right now.',
              icon: Icons.miscellaneous_services_outlined,
            );
          }

          final filtered = allServices.where((s) {
            if (_searchQuery.trim().isEmpty) return true;
            final q = _searchQuery.toLowerCase();
            return s.name.toLowerCase().contains(q) ||
                s.description.toLowerCase().contains(q);
          }).toList();

          return Column(
            children: [
              // Search Header
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                child: TextField(
                  controller: _searchCtrl,
                  decoration: InputDecoration(
                    hintText: 'Search service name or keyword...',
                    hintStyle: const TextStyle(color: AppColors.textMuted, fontSize: 14),
                    prefixIcon: const Icon(Icons.search, color: AppColors.accent, size: 20),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear, size: 18),
                            onPressed: () {
                              setState(() {
                                _searchCtrl.clear();
                                _searchQuery = '';
                              });
                            },
                          )
                        : null,
                    filled: true,
                    fillColor: AppColors.surfaceElevated,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: const BorderSide(color: AppColors.cardBorder),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: const BorderSide(color: AppColors.cardBorder),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: const BorderSide(color: AppColors.accent, width: 1.5),
                    ),
                  ),
                  onChanged: (val) => setState(() => _searchQuery = val),
                ),
              ),

              // Service List
              Expanded(
                child: filtered.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.search_off, size: 48, color: AppColors.textMuted),
                            const SizedBox(height: 12),
                            Text(
                              'No services matching "$_searchQuery"',
                              style: const TextStyle(color: AppColors.textSecondary),
                            ),
                          ],
                        ),
                      )
                    : RefreshIndicator(
                        color: AppColors.accent,
                        onRefresh: () async {
                          ref.invalidate(_servicesProvider(widget.centerId));
                          ref.invalidate(studentActiveEntriesProvider);
                        },
                        child: ListView.builder(
                          padding: const EdgeInsets.fromLTRB(12, 6, 12, 24),
                          itemCount: filtered.length,
                          itemBuilder: (_, i) {
                            final service = filtered[i];
                            // Check if student holds active entry for this service
                            final activeEntry = activeEntries
                                .where((e) => e.serviceId == service.id)
                                .firstOrNull;

                            return _ServiceCard(
                              service: service,
                              activeEntry: activeEntry,
                            );
                          },
                        ),
                      ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _ServiceCard extends ConsumerWidget {
  final Service service;
  final QueueEntry? activeEntry;

  const _ServiceCard({
    required this.service,
    this.activeEntry,
  });

  IconData _getServiceIcon(String name) {
    final lower = name.toLowerCase();
    if (lower.contains('hall ticket')) return Icons.confirmation_number_outlined;
    if (lower.contains('book') || lower.contains('library')) return Icons.menu_book_outlined;
    if (lower.contains('fee') || lower.contains('payment')) return Icons.payments_outlined;
    if (lower.contains('transcript') || lower.contains('certificate')) return Icons.history_edu_outlined;
    if (lower.contains('evaluation') || lower.contains('exam')) return Icons.grading_outlined;
    return Icons.support_agent_outlined;
  }

  (Color, String) _getTrafficInfo(int minutes) {
    if (minutes <= 10) {
      return (AppColors.serving, '🟢 Quick line (~$minutes min)');
    } else if (minutes <= 25) {
      return (AppColors.waiting, '🟡 Moderate (~$minutes min)');
    } else {
      return (AppColors.cancelled, '🟠 Busy (~$minutes min)');
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hasActiveTicket = activeEntry != null;
    final icon = _getServiceIcon(service.name);
    final traffic = _getTrafficInfo(service.estimatedDurationMinutes);

    return AppCard(
      accentColor: hasActiveTicket ? AppColors.accent : AppColors.cardBorder,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Icon container
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: (hasActiveTicket ? AppColors.accent : AppColors.primaryLight)
                      .withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  icon,
                  color: hasActiveTicket ? AppColors.accent : AppColors.accentLight,
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      service.name,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      service.description,
                      style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // Chips row
          Wrap(
            spacing: 8,
            runSpacing: 6,
            children: [
              // Traffic indicator
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: traffic.$1.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: traffic.$1.withValues(alpha: 0.3)),
                ),
                child: Text(
                  traffic.$2,
                  style: TextStyle(
                    color: traffic.$1,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),

              if (hasActiveTicket)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.accent.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppColors.accent),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.airplane_ticket, size: 13, color: AppColors.accent),
                      const SizedBox(width: 4),
                      Text(
                        'Token #${activeEntry!.tokenNumber}',
                        style: const TextStyle(
                          color: AppColors.accent,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),

          const SizedBox(height: 14),

          // Action Button
          SizedBox(
            width: double.infinity,
            child: hasActiveTicket
                ? ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryLight,
                      foregroundColor: Colors.white,
                      elevation: 2,
                    ),
                    onPressed: () {
                      context.push(
                        AppRoutes.queue.replaceFirst(':entryId', activeEntry!.id),
                      );
                    },
                    icon: const Icon(Icons.confirmation_number_outlined, size: 18),
                    label: Text(
                      'View My Active Ticket (#${activeEntry!.tokenNumber})',
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                  )
                : ElevatedButton.icon(
                    onPressed: () => _confirmAndJoinQueue(context, ref),
                    icon: const Icon(Icons.add_circle_outline, size: 18),
                    label: const Text('Join Queue'),
                  ),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmAndJoinQueue(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Join ${service.name}?'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              service.description,
              style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.surfaceElevated,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.cardBorder),
              ),
              child: Row(
                children: [
                  const Icon(Icons.timer_outlined, color: AppColors.accent, size: 20),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Estimated duration: ~${service.estimatedDurationMinutes} min per person',
                      style: const TextStyle(color: AppColors.textPrimary, fontSize: 13),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(dialogCtx, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
            child: const Text('Join Now'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;
    if (!context.mounted) return;

    await _executeJoinQueue(context, ref);
  }

  Future<void> _executeJoinQueue(BuildContext context, WidgetRef ref) async {
    final queueRepo = ref.read(queueRepositoryProvider);
    final user = ref.read(currentUserProvider);

    // Show loading indicator
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(
        child: CircularProgressIndicator(color: AppColors.accent),
      ),
    );

    try {
      // 1. Get or create today's queue
      final queue = await queueRepo.getOrCreateTodayQueue(
        serviceCenterId: service.serviceCenterId,
        serviceId: service.id,
      );

      // 2. Calculate dynamic EWT based on queue position
      final ewtStats = await queueRepo.getEwtStats(service.id);
      final avgDuration = ewtStats?.averageDurationMinutes ??
          service.estimatedDurationMinutes.toDouble();

      final position = await queueRepo.getPositionInQueue(queue.id, 99999) + 1;
      final ewt = EwtCalculator.estimateWaitMinutes(
        positionInQueue: position,
        activeCounters: 1,
        avgServiceDurationMinutes: avgDuration,
      );

      // 3. Join queue
      final entry = await queueRepo.joinQueue(
        queueId: queue.id,
        userId: user.id,
        serviceId: service.id,
        estimatedWaitMinutes: ewt,
      );

      // Refresh student active entries provider so home screen updates
      ref.invalidate(studentActiveEntriesProvider);

      if (context.mounted) {
        context.pop(); // close loading dialog
        context.push(
          AppRoutes.queue.replaceFirst(':entryId', entry.id),
        );
      }
    } catch (e) {
      if (context.mounted) {
        context.pop(); // close loading dialog
        final message = e is AppException
            ? e.message
            : e.toString().replaceAll('Exception:', '').trim();

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error_outline, color: Colors.white, size: 20),
                const SizedBox(width: 10),
                Expanded(child: Text(message)),
              ],
            ),
            backgroundColor: AppColors.cancelled,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
      }
    }
  }
}
