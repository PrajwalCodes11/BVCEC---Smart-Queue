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
import '../../../data/models/app_user.dart';
import '../../../domain/queue_state_machine.dart';
import '../../../shared/widgets/common_widgets.dart';
import '../../../shared/widgets/app_drawer.dart';
import '../../profile/presentation/profile_screen.dart';

// Providers for staff counter flow
// Providers for staff counter flow
final _staffAssignedCenterProvider = FutureProvider<ServiceCenter?>((ref) async {
  final user = ref.watch(currentUserProvider);
  final serviceRepo = ref.watch(serviceRepositoryProvider);
  final counterRepo = ref.watch(counterRepositoryProvider);

  final activeCenters = await serviceRepo.getActiveServiceCenters();
  if (activeCenters.isEmpty) return null;

  // 1. Check if admin assigned this staff member to any counter
  try {
    final allCounters = await counterRepo.getAllCounters();
    final assignedCounter =
        allCounters.where((c) => c.assignedStaffId == user.id).firstOrNull;
    if (assignedCounter != null) {
      final center = activeCenters
          .where((c) => c.id == assignedCounter.serviceCenterId)
          .firstOrNull;
      if (center != null) return center;
    }
  } catch (_) {}

  // 2. Match user's registered department with active service centers
  final userDept = user.department?.trim().toLowerCase();
  if (userDept != null && userDept.isNotEmpty) {
    final matched = activeCenters.where((c) {
      final cName = c.name.toLowerCase();
      return cName == userDept ||
          cName.contains(userDept) ||
          userDept.contains(cName);
    }).firstOrNull;
    if (matched != null) return matched;
  }

  // 3. Fallback to first active center
  return activeCenters.first;
});

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

final _departmentActiveEntriesProvider =
    FutureProvider.family<List<QueueEntry>, String>((ref, centerId) async {
  return ref.watch(queueRepositoryProvider).getCenterActiveEntries(centerId);
});

final _staffTodayCompletedEntriesProvider =
    FutureProvider.family<List<QueueEntry>, String>((ref, staffId) async {
  return ref.watch(queueRepositoryProvider).getStaffTodayCompletedEntries(staffId);
});

final _selectedCounterProvider = StateProvider<Counter?>((ref) => null);
final _activeQueueIdProvider = StateProvider<String?>((ref) => null);
final _activeServiceNameProvider = StateProvider<String?>((ref) => null);

final _todayServedCountProvider =
    FutureProvider.family<int, String>((ref, staffId) async {
  return ref.watch(queueRepositoryProvider).getTodayServedCount(staffId);
});

enum StaffNavSection {
  counterDesk(
    title: 'Counter Operations',
    shortTitle: 'Counter Desk',
    subtitle: 'Live ticket service desk & counter operations',
    icon: Icons.point_of_sale_outlined,
    activeIcon: Icons.point_of_sale,
  ),
  departmentQueue(
    title: 'Department Queue',
    shortTitle: 'Dept Queue',
    subtitle: 'Live student queues in your department',
    icon: Icons.groups_outlined,
    activeIcon: Icons.groups,
  ),
  shiftAnalytics(
    title: 'Shift & Performance',
    shortTitle: 'Shift Report',
    subtitle: 'Today\'s served tickets and shift metrics',
    icon: Icons.insights_outlined,
    activeIcon: Icons.insights,
  ),
  profile(
    title: 'Staff Profile',
    shortTitle: 'Profile',
    subtitle: 'Staff credentials and department info',
    icon: Icons.person_outline,
    activeIcon: Icons.person,
  );

  final String title;
  final String shortTitle;
  final String subtitle;
  final IconData icon;
  final IconData activeIcon;

  const StaffNavSection({
    required this.title,
    required this.shortTitle,
    required this.subtitle,
    required this.icon,
    required this.activeIcon,
  });
}

class CounterScreen extends ConsumerStatefulWidget {
  final bool embedded;
  const CounterScreen({super.key, this.embedded = false});

  @override
  ConsumerState<CounterScreen> createState() => _CounterScreenState();
}

class _CounterScreenState extends ConsumerState<CounterScreen> {
  StaffNavSection _currentSection = StaffNavSection.counterDesk;
  bool _isSidebarExpanded = true;

  void _stepBack() {
    if (_currentSection != StaffNavSection.counterDesk) {
      setState(() => _currentSection = StaffNavSection.counterDesk);
      return;
    }
    final queueId = ref.read(_activeQueueIdProvider);
    final selectedCounter = ref.read(_selectedCounterProvider);

    if (queueId != null) {
      ref.read(_activeQueueIdProvider.notifier).state = null;
      ref.read(_activeServiceNameProvider.notifier).state = null;
    } else if (selectedCounter != null) {
      ref.read(_selectedCounterProvider.notifier).state = null;
    }
  }

  void _resetToDeskSelection() {
    ref.read(_activeQueueIdProvider.notifier).state = null;
    ref.read(_activeServiceNameProvider.notifier).state = null;
    ref.read(_selectedCounterProvider.notifier).state = null;
    setState(() => _currentSection = StaffNavSection.counterDesk);
  }

  Future<void> _handleSignOut(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Sign Out'),
        content: const Text(
          'Are you sure you want to sign out?',
          style: TextStyle(color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Stay'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.cancelled),
            child: const Text('Sign Out'),
          ),
        ],
      ),
    );
    if (confirmed == true && context.mounted) {
      await ref.read(authRepositoryProvider).signOut();
      if (context.mounted) {
        context.go(AppRoutes.login);
      }
    }
  }

  Future<void> _onSelectCounter(
      Counter counter, String centerId, AppUser user) async {
    try {
      await ref.read(counterRepositoryProvider).assignStaff(
            counterId: counter.id,
            staffId: user.id,
          );
      ref.read(_selectedCounterProvider.notifier).state = counter.copyWith(
        assignedStaffId: user.id,
        assignedStaffName: user.fullName,
        status: CounterStatus.available,
      );
      ref.invalidate(_countersStreamProvider(centerId));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                'Switched to ${counter.name} (${counter.status.name.toUpperCase()})'),
            backgroundColor: AppColors.available,
            duration: const Duration(seconds: 2),
          ),
        );
        setState(() => _currentSection = StaffNavSection.counterDesk);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to switch desk: $e'),
            backgroundColor: AppColors.cancelled,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProvider);
    final assignedCenterAsync = ref.watch(_staffAssignedCenterProvider);
    final selectedCounter = ref.watch(_selectedCounterProvider);
    final queueId = ref.watch(_activeQueueIdProvider);
    final serviceName = ref.watch(_activeServiceNameProvider);

    final assignedCenter = assignedCenterAsync.value;

    // Listen to counters to auto-assign active counter if held by user
    if (assignedCenter != null) {
      ref.listen<AsyncValue<List<Counter>>>(
          _countersStreamProvider(assignedCenter.id), (previous, next) {
        if (ref.read(_selectedCounterProvider) == null && next.hasValue) {
          final myCounter = next.value
              ?.where((c) => c.assignedStaffId == user.id)
              .firstOrNull;
          if (myCounter != null) {
            ref.read(_selectedCounterProvider.notifier).state = myCounter;
          }
        }
      });
    }

    final canStepBack = _currentSection != StaffNavSection.counterDesk ||
        selectedCounter != null ||
        queueId != null;

    if (widget.embedded) {
      return _buildSectionView(
        user: user,
        assignedCenterAsync: assignedCenterAsync,
        selectedCounter: selectedCounter,
        queueId: queueId,
        serviceName: serviceName,
        isDesktop: false,
      );
    }

    final isDesktop = MediaQuery.of(context).size.width >= 850;

    if (isDesktop) {
      return Scaffold(
        backgroundColor: AppColors.background,
        body: Row(
          children: [
            // Desktop Collapsible/Expandable Sidebar
            _DesktopStaffSidebar(
              user: user,
              assignedCenter: assignedCenter,
              currentSection: _currentSection,
              isExpanded: _isSidebarExpanded,
              onToggleExpand: () =>
                  setState(() => _isSidebarExpanded = !_isSidebarExpanded),
              onSelectSection: (section) =>
                  setState(() => _currentSection = section),
              onSignOut: () => _handleSignOut(context),
            ),

            // Main Content Area
            Expanded(
              child: Column(
                children: [
                  // Workspace Top Navigation Bar
                  _StaffWorkspaceTopBar(
                    currentSection: _currentSection,
                    user: user,
                    assignedCenter: assignedCenter,
                    counter: selectedCounter,
                    canStepBack: canStepBack,
                    onStepBack: _stepBack,
                    onSwitchDesk: () {
                      ref.read(_selectedCounterProvider.notifier).state = null;
                      ref.read(_activeQueueIdProvider.notifier).state = null;
                      ref.read(_activeServiceNameProvider.notifier).state = null;
                      setState(() => _currentSection = StaffNavSection.counterDesk);
                    },
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
                    onRefresh: () {
                      ref.invalidate(_staffAssignedCenterProvider);
                      if (assignedCenter != null) {
                        ref.invalidate(
                            _countersStreamProvider(assignedCenter.id));
                        ref.invalidate(
                            _centerServicesProvider(assignedCenter.id));
                        ref.invalidate(_departmentActiveEntriesProvider(
                            assignedCenter.id));
                      }
                      ref.invalidate(
                          _staffTodayCompletedEntriesProvider(user.id));
                      ref.invalidate(_todayServedCountProvider(user.id));
                      if (queueId != null) {
                        ref.invalidate(_waitingEntriesStreamProvider(queueId));
                      }
                    },
                  ),

                  // Dynamic Section Workspace Body
                  Expanded(
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 200),
                      switchInCurve: Curves.easeOut,
                      switchOutCurve: Curves.easeIn,
                      child: KeyedSubtree(
                        key: ValueKey(_currentSection),
                        child: _buildSectionView(
                          user: user,
                          assignedCenterAsync: assignedCenterAsync,
                          selectedCounter: selectedCounter,
                          queueId: queueId,
                          serviceName: serviceName,
                          isDesktop: true,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    // Mobile / Narrow layout
    return Scaffold(
      drawer: AppDrawer(
        selectedStaffSection: _currentSection.index,
        onSelectStaffSection: (idx) {
          if (idx >= 0 && idx < StaffNavSection.values.length) {
            setState(() => _currentSection = StaffNavSection.values[idx]);
          }
        },
        onResetStaffFlow: _resetToDeskSelection,
      ),
      appBar: AppBar(
        title: Text(
          selectedCounter != null
              ? '${selectedCounter.name} — ${assignedCenter?.name ?? 'Staff'}'
              : _currentSection.title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        leading: canStepBack
            ? IconButton(
                icon: const Icon(Icons.arrow_back),
                tooltip: 'Back to previous step',
                onPressed: _stepBack,
              )
            : null,
        actions: [
          if (selectedCounter != null &&
              _currentSection == StaffNavSection.counterDesk)
            IconButton(
              icon: const Icon(Icons.swap_horiz),
              tooltip: 'Switch Desk',
              onPressed: () {
                ref.read(_selectedCounterProvider.notifier).state = null;
                ref.read(_activeQueueIdProvider.notifier).state = null;
                ref.read(_activeServiceNameProvider.notifier).state = null;
              },
            ),
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh Counter Data',
            onPressed: () {
              ref.invalidate(_staffAssignedCenterProvider);
              if (assignedCenter != null) {
                ref.invalidate(_countersStreamProvider(assignedCenter.id));
                ref.invalidate(_centerServicesProvider(assignedCenter.id));
                ref.invalidate(
                    _departmentActiveEntriesProvider(assignedCenter.id));
              }
              ref.invalidate(_staffTodayCompletedEntriesProvider(user.id));
              ref.invalidate(_todayServedCountProvider(user.id));
              if (queueId != null) {
                ref.invalidate(_waitingEntriesStreamProvider(queueId));
              }
            },
          ),
        ],
      ),
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 200),
        child: KeyedSubtree(
          key: ValueKey(_currentSection),
          child: _buildSectionView(
            user: user,
            assignedCenterAsync: assignedCenterAsync,
            selectedCounter: selectedCounter,
            queueId: queueId,
            serviceName: serviceName,
            isDesktop: false,
          ),
        ),
      ),
    );
  }

  Widget _buildSectionView({
    required AppUser user,
    required AsyncValue<ServiceCenter?> assignedCenterAsync,
    required Counter? selectedCounter,
    required String? queueId,
    required String? serviceName,
    required bool isDesktop,
  }) {
    return assignedCenterAsync.when(
      loading: () =>
          const AppLoadingWidget(message: 'Loading department assignment...'),
      error: (e, _) =>
          AppErrorWidget(message: 'Failed to resolve department: $e'),
      data: (assignedCenter) {
        if (assignedCenter == null) {
          return const Center(
            child: AppEmptyWidget(
              message:
                  'No active department assignment found. Please contact campus admin.',
              icon: Icons.domain_disabled,
            ),
          );
        }

        switch (_currentSection) {

          case StaffNavSection.departmentQueue:
            return _DepartmentQueueMonitor(
              centerId: assignedCenter.id,
              centerName: assignedCenter.name,
            );

          case StaffNavSection.shiftAnalytics:
            return _StaffShiftAnalyticsView(
              user: user,
              counter: selectedCounter,
              assignedCenter: assignedCenter,
            );

          case StaffNavSection.profile:
            return const ProfileScreen(embedded: true);

          case StaffNavSection.counterDesk:
            return _buildDeskBody(
              user: user,
              assignedCenter: assignedCenter,
              selectedCounter: selectedCounter,
              queueId: queueId,
              serviceName: serviceName,
              isDesktop: isDesktop,
            );
        }
      },
    );
  }

  Widget _buildDeskBody({
    required AppUser user,
    required ServiceCenter assignedCenter,
    required Counter? selectedCounter,
    required String? queueId,
    required String? serviceName,
    required bool isDesktop,
  }) {
    return Column(
      children: [
        if (!isDesktop)
          _StaffHeader(
            staffName: user.fullName,
            counter: selectedCounter,
            departmentName: assignedCenter.name,
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
        if (selectedCounter == null)
          Expanded(
            child: _DepartmentCounterSelector(
              assignedCenter: assignedCenter,
              currentCounter: null,
              user: user,
              onCounterSelected: (counter) =>
                  _onSelectCounter(counter, assignedCenter.id, user),
            ),
          )
        else if (queueId == null)
          Expanded(
            child: _QueueActivator(
              counter: selectedCounter,
              centerId: assignedCenter.id,
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
    );
  }
}

class _StaffHeader extends StatelessWidget {
  final String staffName;
  final Counter? counter;
  final String departmentName;
  final ValueChanged<CounterStatus>? onCounterStatusChanged;

  const _StaffHeader({
    required this.staffName,
    this.counter,
    required this.departmentName,
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
                      ? 'Stationed at ${counter!.name} • $departmentName'
                      : 'On Duty • $departmentName',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.8),
                    fontSize: 12,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
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

class _DepartmentCounterSelector extends ConsumerWidget {
  final ServiceCenter assignedCenter;
  final Counter? currentCounter;
  final AppUser user;
  final ValueChanged<Counter> onCounterSelected;

  const _DepartmentCounterSelector({
    required this.assignedCenter,
    required this.currentCounter,
    required this.user,
    required this.onCounterSelected,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final countersAsync = ref.watch(_countersStreamProvider(assignedCenter.id));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Assigned Section Header Banner
        Container(
          margin: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.surfaceElevated,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.cardBorder),
          ),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: AppColors.staffColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.staffColor.withValues(alpha: 0.3)),
                ),
                child: const Icon(Icons.domain, color: AppColors.staffColor, size: 24),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            assignedCenter.name,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.green.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: Colors.greenAccent.withValues(alpha: 0.4)),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.lock, size: 10, color: Colors.greenAccent),
                              SizedBox(width: 4),
                              Text(
                                'ASSIGNED SECTION',
                                style: TextStyle(
                                  color: Colors.greenAccent,
                                  fontSize: 9,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 3),
                    const Text(
                      'You are authorized to switch between counters within your assigned department only.',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        // Section Title & Counter Count
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 10),
          child: Row(
            children: [
              const Text(
                'Available Counters & Desks',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Colors.white),
              ),
              const Spacer(),
              if (currentCounter != null)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.staffColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.staffColor.withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.check_circle, size: 12, color: AppColors.staffColor),
                      const SizedBox(width: 5),
                      Text(
                        'Current: ${currentCounter!.name}',
                        style: const TextStyle(
                          color: AppColors.staffColor,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),

        // Counters List
        Expanded(
          child: countersAsync.when(
            loading: () => const AppLoadingWidget(message: 'Loading department counters...'),
            error: (e, _) => AppErrorWidget(message: e.toString()),
            data: (counters) {
              if (counters.isEmpty) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.storefront_outlined, size: 48, color: AppColors.textMuted),
                        const SizedBox(height: 12),
                        Text(
                          'No counters configured in ${assignedCenter.name}.',
                          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(height: 6),
                        const Text(
                          'Contact campus admin to configure desks for this department.',
                          style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                        ),
                      ],
                    ),
                  ),
                );
              }

              return ListView.separated(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                itemCount: counters.length,
                separatorBuilder: (context, index) => const SizedBox(height: 10),
                itemBuilder: (ctx, i) {
                  final counter = counters[i];
                  final isCurrent = currentCounter?.id == counter.id || counter.assignedStaffId == user.id;
                  final isOccupiedByOther = counter.assignedStaffId != null && counter.assignedStaffId != user.id;

                  final (statusColor, statusText) = switch (counter.status) {
                    CounterStatus.available => (Colors.greenAccent, 'AVAILABLE'),
                    CounterStatus.serving => (Colors.blueAccent, 'SERVING'),
                    CounterStatus.paused => (Colors.orangeAccent, 'ON BREAK'),
                    CounterStatus.offline => (Colors.redAccent, 'OFFLINE'),
                  };

                  return Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: isCurrent
                          ? AppColors.staffColor.withValues(alpha: 0.1)
                          : AppColors.surfaceElevated,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: isCurrent
                            ? AppColors.staffColor
                            : AppColors.cardBorder,
                        width: isCurrent ? 1.5 : 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: isCurrent
                                ? AppColors.staffColor.withValues(alpha: 0.2)
                                : AppColors.surface,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            Icons.point_of_sale,
                            color: isCurrent ? AppColors.staffColor : AppColors.textSecondary,
                            size: 22,
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Text(
                                    counter.name,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w700,
                                      fontSize: 15,
                                      color: Colors.white,
                                    ),
                                  ),
                                  if (isCurrent) ...[
                                    const SizedBox(width: 8),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                                      decoration: BoxDecoration(
                                        color: AppColors.staffColor.withValues(alpha: 0.2),
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: const Text(
                                        'YOUR DESK',
                                        style: TextStyle(
                                          color: AppColors.staffColor,
                                          fontSize: 9,
                                          fontWeight: FontWeight.w800,
                                        ),
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                              const SizedBox(height: 4),
                              if (isOccupiedByOther)
                                Row(
                                  children: [
                                    const Icon(Icons.person, size: 13, color: AppColors.textMuted),
                                    const SizedBox(width: 4),
                                    Text(
                                      'Stationed: ${counter.assignedStaffName ?? 'Colleague'}',
                                      style: const TextStyle(
                                        color: AppColors.textMuted,
                                        fontSize: 11,
                                      ),
                                    ),
                                  ],
                                )
                              else if (isCurrent)
                                const Row(
                                  children: [
                                    Icon(Icons.check, size: 13, color: AppColors.staffColor),
                                    SizedBox(width: 4),
                                    Text(
                                      'Stationed & Ready for duty',
                                      style: TextStyle(
                                        color: AppColors.staffColor,
                                        fontSize: 11,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                )
                              else
                                const Row(
                                  children: [
                                    Icon(Icons.event_seat_outlined, size: 13, color: AppColors.textSecondary),
                                    SizedBox(width: 4),
                                    Text(
                                      'Vacant Desk — Available to occupy',
                                      style: TextStyle(
                                        color: AppColors.textSecondary,
                                        fontSize: 11,
                                      ),
                                    ),
                                  ],
                                ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: statusColor.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: statusColor.withValues(alpha: 0.4)),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.circle, size: 6, color: statusColor),
                                  const SizedBox(width: 4),
                                  Text(
                                    statusText,
                                    style: TextStyle(
                                      color: statusColor,
                                      fontSize: 10,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 8),
                            if (isCurrent)
                              ElevatedButton.icon(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.staffColor,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                  minimumSize: Size.zero,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                ),
                                icon: const Icon(Icons.play_arrow, size: 14),
                                label: const Text('Operate Desk', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                                onPressed: () => onCounterSelected(counter),
                              )
                            else
                              OutlinedButton.icon(
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: isOccupiedByOther ? AppColors.textSecondary : AppColors.staffColor,
                                  side: BorderSide(
                                    color: isOccupiedByOther
                                        ? AppColors.cardBorder
                                        : AppColors.staffColor.withValues(alpha: 0.6),
                                  ),
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                  minimumSize: Size.zero,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                ),
                                icon: const Icon(Icons.swap_horiz, size: 14),
                                label: Text(
                                  isOccupiedByOther ? 'Reassign to Me' : 'Switch to Desk',
                                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                                ),
                                onPressed: () => onCounterSelected(counter),
                              ),
                          ],
                        ),
                      ],
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
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
              _MiniStat(label: 'Served', count: todayServedCount, color: AppColors.available),
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
              const Expanded(
                child: Text(
                  'STUDENT CALLED — Awaiting Arrival',
                  style: TextStyle(
                    color: AppColors.called,
                    fontWeight: FontWeight.w800,
                    fontSize: 12,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
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

// ── Desktop Staff Sidebar ────────────────────────────────────────────────────

class _DesktopStaffSidebar extends StatelessWidget {
  final AppUser user;
  final ServiceCenter? assignedCenter;
  final StaffNavSection currentSection;
  final bool isExpanded;
  final VoidCallback onToggleExpand;
  final ValueChanged<StaffNavSection> onSelectSection;
  final VoidCallback onSignOut;

  const _DesktopStaffSidebar({
    required this.user,
    this.assignedCenter,
    required this.currentSection,
    required this.isExpanded,
    required this.onToggleExpand,
    required this.onSelectSection,
    required this.onSignOut,
  });

  @override
  Widget build(BuildContext context) {
    final width = isExpanded ? 250.0 : 72.0;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeInOut,
      width: width,
      clipBehavior: Clip.hardEdge,
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(
          right: BorderSide(color: AppColors.cardBorder, width: 1),
        ),
      ),
      child: SafeArea(
        child: Column(
          children: [
            // Header / Brand & Toggle
            Container(
              height: 64,
              padding: EdgeInsets.symmetric(horizontal: isExpanded ? 14 : 12),
              decoration: const BoxDecoration(
                border: Border(
                  bottom: BorderSide(color: AppColors.cardBorder, width: 1),
                ),
              ),
              child: isExpanded
                  ? Row(
                      children: [
                        Container(
                          width: 38,
                          height: 38,
                          decoration: BoxDecoration(
                            color: AppColors.staffColor.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: AppColors.staffColor.withValues(alpha: 0.3),
                            ),
                          ),
                          child: const Icon(
                            Icons.point_of_sale,
                            color: AppColors.staffColor,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'SmartQueue',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 0.2,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              Text(
                                assignedCenter?.name ?? 'Staff Operations',
                                style: const TextStyle(
                                  color: AppColors.textSecondary,
                                  fontSize: 10,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.menu_open,
                              color: AppColors.textSecondary, size: 20),
                          tooltip: 'Collapse sidebar',
                          onPressed: onToggleExpand,
                        ),
                      ],
                    )
                  : Center(
                      child: Tooltip(
                        message: 'Expand sidebar',
                        child: InkWell(
                          borderRadius: BorderRadius.circular(10),
                          onTap: onToggleExpand,
                          child: Container(
                            width: 42,
                            height: 42,
                            decoration: BoxDecoration(
                              color: AppColors.staffColor.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: AppColors.staffColor.withValues(alpha: 0.3),
                              ),
                            ),
                            child: const Icon(
                              Icons.menu,
                              color: AppColors.staffColor,
                              size: 20,
                            ),
                          ),
                        ),
                      ),
                    ),
            ),

            // User Info Pill
            if (isExpanded)
              Container(
                margin: const EdgeInsets.fromLTRB(12, 12, 12, 6),
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.surfaceElevated,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.cardBorder),
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 16,
                      backgroundColor:
                          AppColors.staffColor.withValues(alpha: 0.25),
                      child: Text(
                        user.fullName.initials,
                        style: const TextStyle(
                          color: AppColors.staffColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            user.fullName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: AppColors.textPrimary,
                              fontWeight: FontWeight.w700,
                              fontSize: 12,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 5, vertical: 1),
                                decoration: BoxDecoration(
                                  color: AppColors.staffColor
                                      .withValues(alpha: 0.2),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: const Text(
                                  'STAFF',
                                  style: TextStyle(
                                    color: AppColors.staffColor,
                                    fontSize: 9,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  assignedCenter?.name ??
                                      user.department ??
                                      'On Duty',
                                  style: const TextStyle(
                                    color: AppColors.textSecondary,
                                    fontSize: 10,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

            const SizedBox(height: 6),

            // Navigation Items List
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                children: StaffNavSection.values.map((section) {
                  final isActive = currentSection == section;

                  if (!isExpanded) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Tooltip(
                        message: section.title,
                        preferBelow: false,
                        child: InkWell(
                          borderRadius: BorderRadius.circular(10),
                          onTap: () => onSelectSection(section),
                          child: Container(
                            height: 48,
                            decoration: BoxDecoration(
                              color: isActive
                                  ? AppColors.staffColor.withValues(alpha: 0.15)
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(10),
                              border: isActive
                                  ? Border.all(
                                      color: AppColors.staffColor
                                          .withValues(alpha: 0.4),
                                    )
                                  : null,
                            ),
                            child: Icon(
                              isActive ? section.activeIcon : section.icon,
                              color: isActive
                                  ? AppColors.staffColor
                                  : AppColors.textSecondary,
                              size: 22,
                            ),
                          ),
                        ),
                      ),
                    );
                  }

                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 3),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(10),
                      onTap: () => onSelectSection(section),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 8),
                        decoration: BoxDecoration(
                          color: isActive
                              ? AppColors.staffColor.withValues(alpha: 0.12)
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(10),
                          border: isActive
                              ? Border.all(
                                  color: AppColors.staffColor
                                      .withValues(alpha: 0.35),
                                )
                              : null,
                        ),
                        child: Row(
                          children: [
                            Icon(
                              isActive ? section.activeIcon : section.icon,
                              color: isActive
                                  ? AppColors.staffColor
                                  : AppColors.textSecondary,
                              size: 20,
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    section.shortTitle,
                                    style: TextStyle(
                                      color: isActive
                                          ? AppColors.staffColor
                                          : AppColors.textPrimary,
                                      fontWeight: isActive
                                          ? FontWeight.w700
                                          : FontWeight.w500,
                                      fontSize: 13,
                                    ),
                                  ),
                                  Text(
                                    section.subtitle,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      color: isActive
                                          ? AppColors.staffColor
                                              .withValues(alpha: 0.7)
                                          : AppColors.textMuted,
                                      fontSize: 10,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            if (isActive)
                              Container(
                                width: 5,
                                height: 5,
                                decoration: const BoxDecoration(
                                  color: AppColors.staffColor,
                                  shape: BoxShape.circle,
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),

            // Sidebar Footer: Sign Out
            Container(
              padding: const EdgeInsets.all(10),
              decoration: const BoxDecoration(
                border: Border(
                  top: BorderSide(color: AppColors.cardBorder, width: 1),
                ),
              ),
              child: isExpanded
                  ? SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.cancelled,
                          side: BorderSide(
                            color: AppColors.cancelled.withValues(alpha: 0.5),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        icon: const Icon(Icons.logout, size: 16),
                        label: const Text(
                          'Sign Out',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        onPressed: onSignOut,
                      ),
                    )
                  : Tooltip(
                      message: 'Sign Out',
                      child: IconButton(
                        icon: const Icon(Icons.logout,
                            color: AppColors.cancelled, size: 20),
                        onPressed: onSignOut,
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Desktop Staff Workspace Top Bar ──────────────────────────────────────────

class _StaffWorkspaceTopBar extends StatelessWidget {
  final StaffNavSection currentSection;
  final AppUser user;
  final ServiceCenter? assignedCenter;
  final Counter? counter;
  final bool canStepBack;
  final VoidCallback onStepBack;
  final VoidCallback onSwitchDesk;
  final ValueChanged<CounterStatus>? onCounterStatusChanged;
  final VoidCallback onRefresh;

  const _StaffWorkspaceTopBar({
    required this.currentSection,
    required this.user,
    this.assignedCenter,
    required this.counter,
    required this.canStepBack,
    required this.onStepBack,
    required this.onSwitchDesk,
    required this.onCounterStatusChanged,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 64,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(
          bottom: BorderSide(color: AppColors.cardBorder, width: 1),
        ),
      ),
      child: Row(
        children: [
          if (canStepBack) ...[
            IconButton(
              icon: const Icon(Icons.arrow_back,
                  color: AppColors.textSecondary, size: 20),
              tooltip: 'Previous Step',
              onPressed: onStepBack,
            ),
            const SizedBox(width: 8),
          ],

          // Section Title & Breadcrumb
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        color: AppColors.staffColor,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        counter != null
                            ? 'SmartQueue  /  ${assignedCenter?.name ?? 'Department'}  /  ${counter!.name}'
                            : 'SmartQueue  /  ${assignedCenter?.name ?? 'Department'}  /  ${currentSection.title}',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                          letterSpacing: -0.2,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  counter != null
                      ? 'Active service desk for ${counter!.name} • ${assignedCenter?.name ?? ''}'
                      : currentSection.subtitle,
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppColors.textSecondary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),

          // Switch Desk Fast Action Button
          if (counter != null) ...[
            OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.staffColor,
                side: BorderSide(
                    color: AppColors.staffColor.withValues(alpha: 0.5)),
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                minimumSize: Size.zero,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8)),
              ),
              icon: const Icon(Icons.swap_horiz, size: 14),
              label: const Text('Switch Desk',
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
              onPressed: onSwitchDesk,
            ),
            const SizedBox(width: 10),
          ],

          // Counter Status Menu (when assigned to a counter)
          if (counter != null && onCounterStatusChanged != null) ...[
            _CounterStatusMenu(
              status: counter!.status,
              onChanged: onCounterStatusChanged!,
            ),
            const SizedBox(width: 10),
          ],

          // Duty pill
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: AppColors.surfaceElevated,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.cardBorder),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 7,
                  height: 7,
                  decoration: const BoxDecoration(
                    color: Colors.greenAccent,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 6),
                const Text(
                  'Staff On Duty',
                  style: TextStyle(
                    fontSize: 11,
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(width: 10),

          // Single authoritative Refresh Button
          IconButton(
            icon: const Icon(Icons.refresh,
                color: AppColors.textSecondary, size: 20),
            tooltip: 'Refresh Counter Data',
            onPressed: onRefresh,
          ),
        ],
      ),
    );
  }
}

// ── Department Queue Monitor ─────────────────────────────────────────────────

class _DepartmentQueueMonitor extends ConsumerStatefulWidget {
  final String centerId;
  final String centerName;

  const _DepartmentQueueMonitor({
    required this.centerId,
    required this.centerName,
  });

  @override
  ConsumerState<_DepartmentQueueMonitor> createState() =>
      _DepartmentQueueMonitorState();
}

class _DepartmentQueueMonitorState
    extends ConsumerState<_DepartmentQueueMonitor> {
  final TextEditingController _searchCtrl = TextEditingController();
  String _searchQuery = '';
  QueueEntryStatus? _statusFilter;

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final activeEntriesAsync =
        ref.watch(_departmentActiveEntriesProvider(widget.centerId));

    return RefreshIndicator(
      color: AppColors.staffColor,
      onRefresh: () async {
        ref.invalidate(_departmentActiveEntriesProvider(widget.centerId));
      },
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Section Header
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.staffColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.groups_outlined,
                      color: AppColors.staffColor, size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${widget.centerName} — Queue Line',
                        style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.white),
                      ),
                      const Text(
                        'Live student line and ticket progress across this department',
                        style: TextStyle(
                            fontSize: 12, color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),

            // Metrics Summary
            activeEntriesAsync.when(
              loading: () =>
                  const LinearProgressIndicator(color: AppColors.staffColor),
              error: (e, _) => Text('Error loading queues: $e',
                  style: const TextStyle(color: Colors.red)),
              data: (entries) {
                final waitingCount = entries
                    .where((e) => e.status == QueueEntryStatus.waiting)
                    .length;
                final calledCount = entries
                    .where((e) => e.status == QueueEntryStatus.called)
                    .length;
                final servingCount = entries
                    .where((e) => e.status == QueueEntryStatus.serving)
                    .length;

                return LayoutBuilder(
                  builder: (context, constraints) {
                    final isNarrow = constraints.maxWidth < 600;
                    if (isNarrow) {
                      return Column(
                        children: [
                          Row(
                            children: [
                              _StatTile(
                                label: 'In Line',
                                value: '${entries.length}',
                                subtext: 'Department',
                                color: AppColors.staffColor,
                                icon: Icons.groups,
                              ),
                              const SizedBox(width: 10),
                              _StatTile(
                                label: 'Waiting',
                                value: '$waitingCount',
                                subtext: 'Turn Line',
                                color: AppColors.waiting,
                                icon: Icons.hourglass_top,
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          Row(
                            children: [
                              _StatTile(
                                label: 'Called',
                                value: '$calledCount',
                                subtext: 'At Desks',
                                color: AppColors.called,
                                icon: Icons.campaign,
                              ),
                              const SizedBox(width: 10),
                              _StatTile(
                                label: 'Serving',
                                value: '$servingCount',
                                subtext: 'In Session',
                                color: AppColors.serving,
                                icon: Icons.support_agent,
                              ),
                            ],
                          ),
                        ],
                      );
                    }
                    return Row(
                      children: [
                        _StatTile(
                          label: 'In Line',
                          value: '${entries.length}',
                          subtext: 'Department',
                          color: AppColors.staffColor,
                          icon: Icons.groups,
                        ),
                        const SizedBox(width: 10),
                        _StatTile(
                          label: 'Waiting',
                          value: '$waitingCount',
                          subtext: 'Turn Line',
                          color: AppColors.waiting,
                          icon: Icons.hourglass_top,
                        ),
                        const SizedBox(width: 10),
                        _StatTile(
                          label: 'Called',
                          value: '$calledCount',
                          subtext: 'At Desks',
                          color: AppColors.called,
                          icon: Icons.campaign,
                        ),
                        const SizedBox(width: 10),
                        _StatTile(
                          label: 'Serving',
                          value: '$servingCount',
                          subtext: 'In Session',
                          color: AppColors.serving,
                          icon: Icons.support_agent,
                        ),
                      ],
                    );
                  },
                );
              },
            ),

            const SizedBox(height: 20),

            // Search Bar
            TextField(
              controller: _searchCtrl,
              decoration: InputDecoration(
                hintText:
                    'Search by student name, registration number, or token #...',
                hintStyle:
                    const TextStyle(color: AppColors.textMuted, fontSize: 13),
                prefixIcon: const Icon(Icons.search,
                    color: AppColors.staffColor, size: 20),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, size: 18),
                        onPressed: () => setState(() {
                          _searchCtrl.clear();
                          _searchQuery = '';
                        }),
                      )
                    : null,
                filled: true,
                fillColor: AppColors.surfaceElevated,
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppColors.cardBorder),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppColors.cardBorder),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(
                      color: AppColors.staffColor, width: 1.5),
                ),
              ),
              onChanged: (val) => setState(() => _searchQuery = val.trim()),
            ),
            const SizedBox(height: 14),

            // Status Filter Chips
            activeEntriesAsync.when(
              loading: () => const SizedBox.shrink(),
              error: (e, st) => const SizedBox.shrink(),
              data: (entries) {
                final waitingCount = entries
                    .where((e) => e.status == QueueEntryStatus.waiting)
                    .length;
                final calledCount = entries
                    .where((e) => e.status == QueueEntryStatus.called)
                    .length;
                final servingCount = entries
                    .where((e) => e.status == QueueEntryStatus.serving)
                    .length;

                return SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _FilterChip(
                        label: 'All Active (${entries.length})',
                        isSelected: _statusFilter == null,
                        color: AppColors.staffColor,
                        onTap: () => setState(() => _statusFilter = null),
                      ),
                      const SizedBox(width: 8),
                      _FilterChip(
                        label: 'Waiting ($waitingCount)',
                        isSelected: _statusFilter == QueueEntryStatus.waiting,
                        color: AppColors.waiting,
                        onTap: () => setState(
                            () => _statusFilter = QueueEntryStatus.waiting),
                      ),
                      const SizedBox(width: 8),
                      _FilterChip(
                        label: 'Called ($calledCount)',
                        isSelected: _statusFilter == QueueEntryStatus.called,
                        color: AppColors.called,
                        onTap: () => setState(
                            () => _statusFilter = QueueEntryStatus.called),
                      ),
                      const SizedBox(width: 8),
                      _FilterChip(
                        label: 'Serving ($servingCount)',
                        isSelected: _statusFilter == QueueEntryStatus.serving,
                        color: AppColors.serving,
                        onTap: () => setState(
                            () => _statusFilter = QueueEntryStatus.serving),
                      ),
                    ],
                  ),
                );
              },
            ),

            const SizedBox(height: 18),

            // Queue Entries List
            activeEntriesAsync.when(
              loading: () => const Padding(
                padding: EdgeInsets.symmetric(vertical: 40),
                child: Center(
                    child: CircularProgressIndicator(
                        color: AppColors.staffColor)),
              ),
              error: (e, _) => Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.cancelled.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text('Error loading department queues: $e',
                    style: const TextStyle(color: Colors.red)),
              ),
              data: (entries) {
                final filtered = entries.where((e) {
                  if (_statusFilter != null && e.status != _statusFilter) {
                    return false;
                  }
                  if (_searchQuery.isNotEmpty) {
                    final q = _searchQuery.toLowerCase();
                    final tokenStr = '#${e.tokenNumber}'.toLowerCase();
                    final rawToken = '${e.tokenNumber}';
                    final studentName = (e.userName ?? '').toLowerCase();
                    final serviceName = (e.serviceName ?? '').toLowerCase();
                    final deskName = (e.counterName ?? '').toLowerCase();
                    if (!tokenStr.contains(q) &&
                        !rawToken.contains(q) &&
                        !studentName.contains(q) &&
                        !serviceName.contains(q) &&
                        !deskName.contains(q)) {
                      return false;
                    }
                  }
                  return true;
                }).toList();

                if (filtered.isEmpty) {
                  return Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                        vertical: 48, horizontal: 20),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceElevated,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: AppColors.cardBorder),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.people_outline,
                            size: 48, color: AppColors.textMuted),
                        const SizedBox(height: 12),
                        Text(
                          _searchQuery.isNotEmpty
                              ? 'No queue tickets match "$_searchQuery"'
                              : 'No students currently waiting in this department',
                          style: const TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'Queue entries update automatically as students join queues',
                          style: TextStyle(
                              color: AppColors.textMuted, fontSize: 11),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: filtered.length,
                  separatorBuilder: (context, index) =>
                      const SizedBox(height: 10),
                  itemBuilder: (ctx, i) {
                    final entry = filtered[i];
                    return _DepartmentStudentQueueCard(entry: entry);
                  },
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _DepartmentStudentQueueCard extends StatelessWidget {
  final QueueEntry entry;
  const _DepartmentStudentQueueCard({required this.entry});

  @override
  Widget build(BuildContext context) {
    final (badgeColor, statusLabel, icon) = switch (entry.status) {
      QueueEntryStatus.waiting => (
          AppColors.waiting,
          'WAITING IN LINE',
          Icons.hourglass_top
        ),
      QueueEntryStatus.called => (
          AppColors.called,
          'CALLED TO DESK',
          Icons.campaign
        ),
      QueueEntryStatus.serving => (
          AppColors.serving,
          'CURRENTLY SERVING',
          Icons.support_agent
        ),
      _ => (AppColors.textMuted, 'OTHER', Icons.circle),
    };

    final waitMinutes = DateTime.now().difference(entry.joinedAt).inMinutes;
    final waitText =
        waitMinutes < 1 ? 'Just joined' : 'Waiting for ${waitMinutes}m';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceElevated,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: entry.status == QueueEntryStatus.called
              ? AppColors.called.withValues(alpha: 0.6)
              : AppColors.cardBorder,
          width: entry.status == QueueEntryStatus.called ? 1.5 : 1,
        ),
      ),
      child: Row(
        children: [
          // Token Badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: badgeColor.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: badgeColor.withValues(alpha: 0.5)),
            ),
            child: Text(
              '#${entry.tokenNumber}',
              style: TextStyle(
                color: badgeColor,
                fontSize: 18,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          const SizedBox(width: 14),

          // Student & Queue Details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        entry.userName ?? 'Student',
                        style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 14,
                            color: Colors.white),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (entry.priority > 0) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 5, vertical: 1),
                        decoration: BoxDecoration(
                          color: Colors.amber.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Text(
                          'PRIORITY',
                          style: TextStyle(
                              color: Colors.amber,
                              fontSize: 9,
                              fontWeight: FontWeight.w800),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 3),
                Text(
                  entry.serviceName ?? 'Department Service',
                  style: const TextStyle(
                      color: AppColors.textSecondary, fontSize: 12),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Icon(
                      entry.counterName != null
                          ? Icons.point_of_sale
                          : Icons.desk_outlined,
                      size: 13,
                      color: entry.counterName != null
                          ? AppColors.staffColor
                          : AppColors.textMuted,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      entry.counterName != null
                          ? 'Desk: ${entry.counterName}'
                          : 'Desk: Not yet assigned',
                      style: TextStyle(
                        color: entry.counterName != null
                            ? AppColors.staffColor
                            : AppColors.textMuted,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Icon(Icons.access_time,
                        size: 12, color: AppColors.textMuted),
                    const SizedBox(width: 4),
                    Text(
                      waitText,
                      style: const TextStyle(
                          color: AppColors.textMuted, fontSize: 11),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Status Badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: badgeColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: badgeColor.withValues(alpha: 0.4)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, color: badgeColor, size: 13),
                const SizedBox(width: 5),
                Text(
                  statusLabel,
                  style: TextStyle(
                    color: badgeColor,
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.3,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Staff Shift Analytics View ───────────────────────────────────────────────

class _StaffShiftAnalyticsView extends ConsumerWidget {
  final AppUser user;
  final Counter? counter;
  final ServiceCenter assignedCenter;

  const _StaffShiftAnalyticsView({
    required this.user,
    required this.counter,
    required this.assignedCenter,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final servedCountAsync = ref.watch(_todayServedCountProvider(user.id));
    final completedEntriesAsync =
        ref.watch(_staffTodayCompletedEntriesProvider(user.id));

    return RefreshIndicator(
      color: AppColors.staffColor,
      onRefresh: () async {
        ref.invalidate(_todayServedCountProvider(user.id));
        ref.invalidate(_staffTodayCompletedEntriesProvider(user.id));
      },
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.staffColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.insights,
                      color: AppColors.staffColor, size: 24),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Shift Summary & Performance',
                        style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.white),
                      ),
                      Text(
                        'Duty activity metrics for ${user.fullName} (${assignedCenter.name})',
                        style: const TextStyle(
                            fontSize: 12, color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Metrics Cards
            Row(
              children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceElevated,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: AppColors.cardBorder),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.check_circle_outline,
                                color: Colors.greenAccent, size: 20),
                            const Spacer(),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color:
                                    Colors.greenAccent.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: const Text('TODAY',
                                  style: TextStyle(
                                      color: Colors.greenAccent,
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold)),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        servedCountAsync.when(
                          loading: () => const Text('...',
                              style: TextStyle(
                                  fontSize: 26, fontWeight: FontWeight.bold)),
                          error: (e, st) => const Text('0',
                              style: TextStyle(
                                  fontSize: 26, fontWeight: FontWeight.bold)),
                          data: (count) => Text('$count',
                              style: const TextStyle(
                                  fontSize: 28,
                                  fontWeight: FontWeight.w900,
                                  color: Colors.white)),
                        ),
                        const SizedBox(height: 2),
                        const Text('Tickets Served',
                            style: TextStyle(
                                color: AppColors.textSecondary, fontSize: 12)),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceElevated,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: AppColors.cardBorder),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.point_of_sale,
                                color: AppColors.staffColor, size: 20),
                            const Spacer(),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: AppColors.staffColor
                                    .withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                counter != null
                                    ? counter!.status.name.toUpperCase()
                                    : 'NO DESK',
                                style: const TextStyle(
                                    color: AppColors.staffColor,
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Text(
                          counter != null ? counter!.name : 'Unassigned',
                          style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                              color: Colors.white),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        const Text('Current Active Desk',
                            style: TextStyle(
                                color: AppColors.textSecondary, fontSize: 12)),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Completed tickets log section
            Row(
              children: [
                const Icon(Icons.history,
                    color: AppColors.textSecondary, size: 18),
                const SizedBox(width: 8),
                const Text(
                  'Today\'s Completed Tickets Log',
                  style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: Colors.white),
                ),
                const Spacer(),
                completedEntriesAsync.when(
                  loading: () => const SizedBox.shrink(),
                  error: (e, st) => const SizedBox.shrink(),
                  data: (entries) => Text(
                    '${entries.length} completed',
                    style: const TextStyle(
                        color: AppColors.textMuted, fontSize: 12),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            completedEntriesAsync.when(
              loading: () => const Center(
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 40),
                  child:
                      CircularProgressIndicator(color: AppColors.staffColor),
                ),
              ),
              error: (e, _) => Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.cancelled.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text('Error loading completed tickets: $e',
                    style: const TextStyle(color: Colors.red)),
              ),
              data: (entries) {
                if (entries.isEmpty) {
                  return Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                        vertical: 40, horizontal: 20),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceElevated,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: AppColors.cardBorder),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: const [
                        Icon(Icons.assignment_turned_in_outlined,
                            size: 44, color: AppColors.textMuted),
                        SizedBox(height: 10),
                        Text(
                          'No tickets completed yet during this shift',
                          style: TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 13,
                              fontWeight: FontWeight.w600),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'Tickets completed at your counter today will appear here in chronological order.',
                          style: TextStyle(
                              color: AppColors.textMuted, fontSize: 11),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  );
                }

                return ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: entries.length,
                  separatorBuilder: (context, index) =>
                      const SizedBox(height: 8),
                  itemBuilder: (ctx, i) {
                    final entry = entries[i];
                    final completedTimeStr = entry.completedAt != null
                        ? '${entry.completedAt!.hour.toString().padLeft(2, '0')}:${entry.completedAt!.minute.toString().padLeft(2, '0')}'
                        : 'Done';

                    return Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 12),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceElevated,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.cardBorder),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 6),
                            decoration: BoxDecoration(
                              color: Colors.green.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                  color: Colors.greenAccent
                                      .withValues(alpha: 0.4)),
                            ),
                            child: Text(
                              '#${entry.tokenNumber}',
                              style: const TextStyle(
                                  color: Colors.greenAccent,
                                  fontWeight: FontWeight.w900,
                                  fontSize: 13),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  entry.userName ?? 'Student',
                                  style: const TextStyle(
                                      fontWeight: FontWeight.w700,
                                      fontSize: 13,
                                      color: Colors.white),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  entry.serviceName ?? 'Completed Service',
                                  style: const TextStyle(
                                      color: AppColors.textSecondary,
                                      fontSize: 11),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          Row(
                            children: [
                              const Icon(Icons.check_circle,
                                  size: 13, color: Colors.greenAccent),
                              const SizedBox(width: 4),
                              Text(
                                completedTimeStr,
                                style: const TextStyle(
                                    color: AppColors.textMuted, fontSize: 11),
                              ),
                            ],
                          ),
                        ],
                      ),
                    );
                  },
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

// ── Shared Stat & Chip Components ────────────────────────────────────────────

class _StatTile extends StatelessWidget {
  final String label;
  final String value;
  final String subtext;
  final Color color;
  final IconData icon;

  const _StatTile({
    required this.label,
    required this.value,
    required this.subtext,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 10),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(height: 6),
            Text(
              value,
              style: TextStyle(
                color: color,
                fontSize: 22,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              subtext,
              style: const TextStyle(color: AppColors.textMuted, fontSize: 11),
            ),
          ],
        ),
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final Color? color;
  final VoidCallback onTap;

  const _FilterChip({
    required this.label,
    required this.isSelected,
    this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final activeColor = color ?? AppColors.staffColor;
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected
              ? activeColor.withValues(alpha: 0.15)
              : AppColors.surfaceElevated,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? activeColor : AppColors.cardBorder,
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected
                ? (color != null ? activeColor : Colors.white)
                : AppColors.textSecondary,
            fontSize: 11,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
          ),
        ),
      ),
    );
  }
}

