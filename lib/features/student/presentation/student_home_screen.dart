import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/errors/app_exception.dart';
import '../../../core/extensions/extensions.dart';
import '../../../core/providers/providers.dart';
import '../../../core/router/app_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/ewt_calculator.dart';
import '../../../data/models/app_user.dart';
import '../../../data/models/queue_entry.dart';
import '../../../data/models/service.dart';
import '../../../data/models/service_center.dart';
import '../../../domain/queue_state_machine.dart';
import '../../../shared/widgets/common_widgets.dart';
import '../../../shared/widgets/app_drawer.dart';
import '../../profile/presentation/profile_screen.dart';
import 'history_screen.dart';
import '../providers/student_providers.dart';

final _serviceCentersProvider = FutureProvider<List<ServiceCenter>>((ref) async {
  return ref.watch(serviceRepositoryProvider).getActiveServiceCenters();
});

final _allCampusServicesProvider = FutureProvider<List<Service>>((ref) async {
  return ref.watch(serviceRepositoryProvider).getAllActiveServices();
});

enum StudentNavSection {
  campusQueues(
    title: 'Live Campus Queues',
    shortTitle: 'Queues',
    subtitle: 'Browse campus service centers & take queue tokens',
    icon: Icons.storefront_outlined,
    activeIcon: Icons.storefront,
  ),
  activeTickets(
    title: 'My Active Tickets',
    shortTitle: 'Active Tickets',
    subtitle: 'Real-time turn positions, calling counters & wait times',
    icon: Icons.confirmation_number_outlined,
    activeIcon: Icons.confirmation_number,
  ),
  history(
    title: 'Queue History',
    shortTitle: 'History',
    subtitle: 'Completed, served and cancelled token history',
    icon: Icons.history_outlined,
    activeIcon: Icons.history,
  ),
  profile(
    title: 'My Profile',
    shortTitle: 'Profile',
    subtitle: 'Student registration details & account settings',
    icon: Icons.person_outline,
    activeIcon: Icons.person,
  );

  final String title;
  final String shortTitle;
  final String subtitle;
  final IconData icon;
  final IconData activeIcon;

  const StudentNavSection({
    required this.title,
    required this.shortTitle,
    required this.subtitle,
    required this.icon,
    required this.activeIcon,
  });
}

class StudentHomeScreen extends ConsumerStatefulWidget {
  final bool embedded;
  const StudentHomeScreen({super.key, this.embedded = false});

  @override
  ConsumerState<StudentHomeScreen> createState() => _StudentHomeScreenState();
}

class _StudentHomeScreenState extends ConsumerState<StudentHomeScreen> {
  final TextEditingController _searchCtrl = TextEditingController();
  String _searchQuery = '';
  int _viewMode = 0; // 0 = All Campus Services, 1 = By Center / Department
  StudentNavSection _currentSection = StudentNavSection.campusQueues;
  bool _isSidebarExpanded = true;

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProvider);
    final centersAsync = ref.watch(_serviceCentersProvider);
    final allServicesAsync = ref.watch(_allCampusServicesProvider);
    final activeEntriesAsync = ref.watch(studentActiveEntriesStreamProvider);
    final activeEntries = activeEntriesAsync.value ?? <QueueEntry>[];

    final allServices = allServicesAsync.value ?? <Service>[];
    final allCenters = centersAsync.value ?? <ServiceCenter>[];

    // Filter services based on search query
    final filteredServices = allServices.where((s) {
      if (_searchQuery.trim().isEmpty) return true;
      final q = _searchQuery.toLowerCase();
      final centerName = allCenters
          .firstWhere(
            (c) => c.id == s.serviceCenterId,
            orElse: () => ServiceCenter(
              id: '',
              name: '',
              description: '',
              isActive: true,
              createdAt: DateTime(2026),
            ),
          )
          .name
          .toLowerCase();
      return s.name.toLowerCase().contains(q) ||
          s.description.toLowerCase().contains(q) ||
          centerName.contains(q);
    }).toList();

    // Embedded mode (e.g. inside Admin portal)
    if (widget.embedded) {
      return _buildSectionContent(
        user: user,
        activeEntries: activeEntries,
        allServices: allServices,
        allCenters: allCenters,
        filteredServices: filteredServices,
        allServicesAsync: allServicesAsync,
        centersAsync: centersAsync,
      );
    }

    final isDesktop = MediaQuery.of(context).size.width >= 850;

    if (isDesktop) {
      return Scaffold(
        backgroundColor: AppColors.background,
        body: Row(
          children: [
            // Desktop Collapsible/Expandable Sidebar
            _DesktopStudentSidebar(
              user: user,
              currentSection: _currentSection,
              isExpanded: _isSidebarExpanded,
              activeTicketCount: activeEntries.length,
              onToggleExpand: () => setState(() => _isSidebarExpanded = !_isSidebarExpanded),
              onSelectSection: (section) => setState(() => _currentSection = section),
              onSignOut: () => _confirmSignOut(context, ref),
            ),

            // Main Content Area
            Expanded(
              child: Column(
                children: [
                  // Workspace Top Navigation Bar (single refresh button, no duplicate buttons)
                  _StudentWorkspaceTopBar(
                    currentSection: _currentSection,
                    user: user,
                    onRefresh: () => _refreshAll(ref),
                  ),

                  // Dynamic Section Workspace Body
                  Expanded(
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 200),
                      switchInCurve: Curves.easeOut,
                      switchOutCurve: Curves.easeIn,
                      child: KeyedSubtree(
                        key: ValueKey(_currentSection),
                        child: _buildSectionContent(
                          user: user,
                          activeEntries: activeEntries,
                          allServices: allServices,
                          allCenters: allCenters,
                          filteredServices: filteredServices,
                          allServicesAsync: allServicesAsync,
                          centersAsync: centersAsync,
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
        selectedStudentSection: _currentSection.index,
        onSelectStudentSection: (idx) => setState(() {
          _currentSection = StudentNavSection.values[idx];
        }),
      ),
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: AppColors.accent,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 8),
                const Text(
                  'BVCEC SmartQueue',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, letterSpacing: -0.3),
                ),
              ],
            ),
            Text(
              _currentSection.title,
              style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
            ),
          ],
        ),
        actions: [
          // Single authoritative Refresh button (no duplicate profile/history/signout)
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh Queue Data',
            onPressed: () => _refreshAll(ref),
          ),
        ],
      ),
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 200),
        child: KeyedSubtree(
          key: ValueKey(_currentSection),
          child: _buildSectionContent(
            user: user,
            activeEntries: activeEntries,
            allServices: allServices,
            allCenters: allCenters,
            filteredServices: filteredServices,
            allServicesAsync: allServicesAsync,
            centersAsync: centersAsync,
          ),
        ),
      ),
    );
  }

  void _refreshAll(WidgetRef ref) {
    ref.invalidate(_serviceCentersProvider);
    ref.invalidate(_allCampusServicesProvider);
    ref.invalidate(studentActiveEntriesProvider);
  }

  Widget _buildSectionContent({
    required AppUser user,
    required List<QueueEntry> activeEntries,
    required List<Service> allServices,
    required List<ServiceCenter> allCenters,
    required List<Service> filteredServices,
    required AsyncValue<List<Service>> allServicesAsync,
    required AsyncValue<List<ServiceCenter>> centersAsync,
  }) {
    switch (_currentSection) {
      case StudentNavSection.campusQueues:
        return _buildCampusQueuesView(
          user: user,
          activeEntries: activeEntries,
          allServices: allServices,
          allCenters: allCenters,
          filteredServices: filteredServices,
          allServicesAsync: allServicesAsync,
          centersAsync: centersAsync,
        );
      case StudentNavSection.activeTickets:
        return _buildActiveTicketsView(activeEntries);
      case StudentNavSection.history:
        return const HistoryScreen(embedded: true);
      case StudentNavSection.profile:
        return const ProfileScreen(embedded: true);
    }
  }

  Widget _buildActiveTicketsView(List<QueueEntry> activeEntries) {
    if (activeEntries.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  color: AppColors.accent.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.confirmation_number_outlined,
                  size: 36,
                  color: AppColors.accent,
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'No Active Queue Tickets',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'You are not currently waiting in line for any campus services.\nSelect a service from the campus queues tab to join.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 13,
                  color: AppColors.textSecondary,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.accent,
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: () {
                  setState(() => _currentSection = StudentNavSection.campusQueues);
                },
                icon: const Icon(Icons.storefront, size: 18),
                label: const Text(
                  'Browse Campus Queues',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return RefreshIndicator(
      color: AppColors.accent,
      onRefresh: () async => _refreshAll(ref),
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Row(
            children: [
              const Icon(Icons.confirmation_number, color: AppColors.accent, size: 20),
              const SizedBox(width: 8),
              Text(
                'Active Tokens in Queue (${activeEntries.length})',
                style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 4),
          const Text(
            'Keep track of your turn. You will be notified when your token is called.',
            style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
          ),
          const SizedBox(height: 16),
          ...activeEntries.map((entry) => _ActiveTicketCard(entry: entry)),
        ],
      ),
    );
  }

  Widget _buildCampusQueuesView({
    required AppUser user,
    required List<QueueEntry> activeEntries,
    required List<Service> allServices,
    required List<ServiceCenter> allCenters,
    required List<Service> filteredServices,
    required AsyncValue<List<Service>> allServicesAsync,
    required AsyncValue<List<ServiceCenter>> centersAsync,
  }) {
    return RefreshIndicator(
      color: AppColors.accent,
      onRefresh: () async => _refreshAll(ref),
      child: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
            // Active tickets banner
            if (activeEntries.isNotEmpty)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.confirmation_number, color: AppColors.accent, size: 18),
                          const SizedBox(width: 8),
                          const Text(
                            'Your Active Queue Tickets',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                          ),
                          const Spacer(),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppColors.accent.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              '${activeEntries.length} Active',
                              style: const TextStyle(
                                color: AppColors.accent,
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      ...activeEntries.map((entry) => _ActiveTicketCard(entry: entry)),
                    ],
                  ),
                ),
              ),

            // Welcome & Metrics Banner
            SliverToBoxAdapter(
              child: _buildWelcomeBanner(user.registrationNumber, activeEntries.length),
            ),

            // Global Search Bar across all campus services
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 10, 16, 6),
                child: TextField(
                  controller: _searchCtrl,
                  decoration: InputDecoration(
                    hintText: 'Search campus services (e.g. CSE Allied, Books, Fees)...',
                    hintStyle: const TextStyle(color: AppColors.textMuted, fontSize: 13),
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
            ),

            // Mode Selector Toggle (All Campus Services vs By Center)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                child: Row(
                  children: [
                    _TabChip(
                      label: 'All Campus Services (${allServices.length})',
                      isSelected: _viewMode == 0 || _searchQuery.isNotEmpty,
                      icon: Icons.list_alt,
                      onTap: () => setState(() => _viewMode = 0),
                    ),
                    const SizedBox(width: 8),
                    _TabChip(
                      label: 'By Center (${allCenters.length})',
                      isSelected: _viewMode == 1 && _searchQuery.isEmpty,
                      icon: Icons.domain,
                      onTap: () {
                        setState(() {
                          _searchCtrl.clear();
                          _searchQuery = '';
                          _viewMode = 1;
                        });
                      },
                    ),
                  ],
                ),
              ),
            ),

            // Content Area: Either All Services or By Center
            if (_viewMode == 0 || _searchQuery.isNotEmpty) ...[
              // All Services View (Instant Discovery for services like CSE ALLIED)
              allServicesAsync.when(
                loading: () => const SliverFillRemaining(
                  child: AppLoadingWidget(message: 'Loading campus services...'),
                ),
                error: (e, _) => SliverFillRemaining(
                  child: AppErrorWidget(
                    message: e.toString(),
                    onRetry: () => ref.refresh(_allCampusServicesProvider),
                  ),
                ),
                data: (_) {
                  if (filteredServices.isEmpty) {
                    return SliverFillRemaining(
                      hasScrollBody: false,
                      child: Center(
                        child: Padding(
                          padding: const EdgeInsets.all(24),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.search_off, size: 48, color: AppColors.textMuted),
                              const SizedBox(height: 12),
                              Text(
                                _searchQuery.isNotEmpty
                                    ? 'No services matching "$_searchQuery"'
                                    : 'No services available today.',
                                style: const TextStyle(color: AppColors.textSecondary),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  }

                  return SliverPadding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (ctx, i) {
                          final service = filteredServices[i];
                          final center = allCenters.firstWhere(
                            (c) => c.id == service.serviceCenterId,
                            orElse: () => ServiceCenter(
                              id: '',
                              name: 'Campus Center',
                              description: '',
                              isActive: true,
                              createdAt: DateTime(2026),
                            ),
                          );
                          final activeEntry = activeEntries
                              .where((e) => e.serviceId == service.id)
                              .firstOrNull;

                          return _CampusServiceItem(
                            service: service,
                            centerName: center.name,
                            activeEntry: activeEntry,
                            onJoin: () => _confirmAndJoinQueue(ctx, ref, service),
                          );
                        },
                        childCount: filteredServices.length,
                      ),
                    ),
                  );
                },
              ),
            ] else ...[
              // By Center View with service preview tags
              centersAsync.when(
                loading: () => const SliverFillRemaining(
                  child: AppLoadingWidget(message: 'Loading campus service centers...'),
                ),
                error: (e, _) => SliverFillRemaining(
                  child: AppErrorWidget(
                    message: e.toString(),
                    onRetry: () => ref.refresh(_serviceCentersProvider),
                  ),
                ),
                data: (list) {
                  if (list.isEmpty) {
                    return const SliverFillRemaining(
                      child: AppEmptyWidget(
                        message: 'No service centers active today.',
                        icon: Icons.store_outlined,
                      ),
                    );
                  }
                  return SliverPadding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (_, i) {
                          final center = list[i];
                          final centerServices = allServices
                              .where((s) => s.serviceCenterId == center.id)
                              .toList();
                          return _ServiceCenterCard(
                            center: center,
                            services: centerServices,
                          );
                        },
                        childCount: list.length,
                      ),
                    ),
                  );
                },
              ),
            ],
          ],
        ),
      );
  }

  Widget _buildWelcomeBanner(String regNo, int activeCount) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 4, 16, 8),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.primaryDark, AppColors.primaryLight],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryDark.withValues(alpha: 0.4),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.qr_code_scanner, color: Colors.white, size: 26),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Digital Campus Queue',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Zero physical line standing. Real-time turn tracking.',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.8),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _BannerMetric(label: 'Registration', value: regNo.toUpperCase()),
                Container(width: 1, height: 20, color: Colors.white.withValues(alpha: 0.2)),
                _BannerMetric(label: 'Active Tickets', value: '$activeCount In Line'),
                Container(width: 1, height: 20, color: Colors.white.withValues(alpha: 0.2)),
                const _BannerMetric(label: 'Campus Status', value: '🟢 Open'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmAndJoinQueue(
    BuildContext context,
    WidgetRef ref,
    Service service,
  ) async {
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
                      'Estimated duration: ~${service.estimatedDurationMinutes} min per student',
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
      final queue = await queueRepo.getOrCreateTodayQueue(
        serviceCenterId: service.serviceCenterId,
        serviceId: service.id,
      );

      final ewtStats = await queueRepo.getEwtStats(service.id);
      final avgDuration = ewtStats?.averageDurationMinutes ??
          service.estimatedDurationMinutes.toDouble();

      final position = await queueRepo.getPositionInQueue(queue.id, 99999) + 1;
      final ewt = EwtCalculator.estimateWaitMinutes(
        positionInQueue: position,
        activeCounters: 1,
        avgServiceDurationMinutes: avgDuration,
      );

      final entry = await queueRepo.joinQueue(
        queueId: queue.id,
        userId: user.id,
        serviceId: service.id,
        estimatedWaitMinutes: ewt,
      );

      ref.invalidate(studentActiveEntriesProvider);
      ref.invalidate(_allCampusServicesProvider);

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
            content: Text(message),
            backgroundColor: AppColors.cancelled,
          ),
        );
      }
    }
  }

  Future<void> _confirmSignOut(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Sign Out'),
        content: const Text(
          'Are you sure you want to sign out of BVCEC SmartQueue?',
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

    if (confirmed == true) {
      await ref.read(authRepositoryProvider).signOut();
      if (context.mounted) {
        context.go(AppRoutes.login);
      }
    }
  }
}

class _TabChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final IconData icon;
  final VoidCallback onTap;

  const _TabChip({
    required this.label,
    required this.isSelected,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.accent : AppColors.surfaceElevated,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? AppColors.accent : AppColors.cardBorder,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 15,
              color: isSelected ? Colors.black : AppColors.textSecondary,
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? Colors.black : AppColors.textPrimary,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BannerMetric extends StatelessWidget {
  final String label;
  final String value;
  const _BannerMetric({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          label,
          style: TextStyle(color: Colors.white.withValues(alpha: 0.65), fontSize: 10),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w700),
        ),
      ],
    );
  }
}

class _ActiveTicketCard extends StatelessWidget {
  final QueueEntry entry;
  const _ActiveTicketCard({required this.entry});

  @override
  Widget build(BuildContext context) {
    final isCalled = entry.status == QueueEntryStatus.called;
    final isServing = entry.status == QueueEntryStatus.serving;

    final badgeColor = isCalled
        ? AppColors.called
        : isServing
            ? AppColors.serving
            : AppColors.waiting;

    final statusText = isCalled
        ? '🔔 YOU ARE BEING CALLED!'
        : isServing
            ? 'Serving at Counter'
            : 'Waiting in line';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceElevated,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isCalled ? AppColors.called : AppColors.cardBorder,
          width: isCalled ? 2 : 1,
        ),
        boxShadow: isCalled
            ? [
                BoxShadow(
                  color: AppColors.called.withValues(alpha: 0.35),
                  blurRadius: 12,
                  spreadRadius: 1,
                ),
              ]
            : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: badgeColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: badgeColor),
                ),
                child: Text(
                  '#${entry.tokenNumber}',
                  style: TextStyle(
                    color: badgeColor,
                    fontSize: 20,
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
                      entry.serviceName ?? 'Campus Service',
                      style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: badgeColor,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          statusText,
                          style: TextStyle(
                            color: badgeColor,
                            fontWeight: FontWeight.w600,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: isCalled ? AppColors.called : AppColors.primary,
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                ),
                onPressed: () {
                  context.push(AppRoutes.queue.replaceFirst(':entryId', entry.id));
                },
                icon: const Icon(Icons.arrow_forward, size: 16),
                label: const Text('View Ticket', style: TextStyle(fontSize: 13)),
              ),
            ],
          ),
          if (isCalled && entry.counterName != null) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.called.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const Icon(Icons.campaign, color: AppColors.called, size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Please report to ${entry.counterName} immediately.',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ] else if (entry.estimatedWaitMinutes != null) ...[
            const SizedBox(height: 10),
            Text(
              'Estimated wait time: ${EwtCalculator.formatWait(entry.estimatedWaitMinutes!)}',
              style: const TextStyle(color: AppColors.textMuted, fontSize: 12),
            ),
          ],
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// CAMPUS SERVICE ITEM (Direct discovery card for CSE ALLIED, etc.)
// ─────────────────────────────────────────────────────────────────────────────

class _CampusServiceItem extends StatelessWidget {
  final Service service;
  final String centerName;
  final QueueEntry? activeEntry;
  final VoidCallback onJoin;

  const _CampusServiceItem({
    required this.service,
    required this.centerName,
    required this.activeEntry,
    required this.onJoin,
  });

  @override
  Widget build(BuildContext context) {
    final hasActiveTicket = activeEntry != null;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: AppCard(
        accentColor: hasActiveTicket ? AppColors.accent : AppColors.cardBorder,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: AppColors.accent.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.assignment_outlined, color: AppColors.accent, size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        service.name,
                        style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        service.description,
                        style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
                      ),
                      const SizedBox(height: 6),
                      Wrap(
                        spacing: 6,
                        runSpacing: 4,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppColors.surfaceElevated,
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(color: AppColors.cardBorder),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.store, size: 11, color: AppColors.textSecondary),
                                const SizedBox(width: 4),
                                Text(
                                  centerName,
                                  style: const TextStyle(color: AppColors.textSecondary, fontSize: 11),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppColors.serving.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              '~${service.estimatedDurationMinutes} mins',
                              style: const TextStyle(
                                color: AppColors.serving,
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: hasActiveTicket
                  ? ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryLight,
                      ),
                      onPressed: () {
                        context.push(
                          AppRoutes.queue.replaceFirst(':entryId', activeEntry!.id),
                        );
                      },
                      icon: const Icon(Icons.confirmation_number_outlined, size: 16),
                      label: Text('View Active Ticket (#${activeEntry!.tokenNumber})'),
                    )
                  : ElevatedButton.icon(
                      onPressed: onJoin,
                      icon: const Icon(Icons.add_circle_outline, size: 16),
                      label: const Text('Join Queue'),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// SERVICE CENTER CARD (Enhanced with service count and preview tags)
// ─────────────────────────────────────────────────────────────────────────────

class _ServiceCenterCard extends StatelessWidget {
  final ServiceCenter center;
  final List<Service> services;

  const _ServiceCenterCard({
    required this.center,
    required this.services,
  });

  static const _icons = [
    Icons.school_outlined,
    Icons.admin_panel_settings_outlined,
    Icons.account_balance_outlined,
    Icons.local_library_outlined,
    Icons.domain_outlined,
  ];

  @override
  Widget build(BuildContext context) {
    final colorCycle = [
      AppColors.accent,
      AppColors.studentColor,
      AppColors.staffColor,
      AppColors.adminColor,
      AppColors.waiting,
    ];
    final index = center.name.hashCode.abs() % colorCycle.length;
    final color = colorCycle[index];
    final icon = _icons[index % _icons.length];

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: GestureDetector(
        onTap: () => context.push(
          AppRoutes.serviceList.replaceFirst(':centerId', center.id),
        ),
        child: AppCard(
          accentColor: color,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: color.withValues(alpha: 0.3)),
                    ),
                    child: Icon(icon, color: color, size: 24),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          center.name,
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          center.description,
                          style: const TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 12,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${services.length} ${services.length == 1 ? 'service' : 'services'}',
                      style: TextStyle(
                        color: color,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              if (services.isNotEmpty) ...[
                const SizedBox(height: 10),
                const Divider(height: 1),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 6,
                  runSpacing: 4,
                  children: services.map((s) {
                    return Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceElevated,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: AppColors.cardBorder),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.label_outline, size: 11, color: color),
                          const SizedBox(width: 4),
                          Text(
                            s.name,
                            style: const TextStyle(fontSize: 11, color: AppColors.textPrimary),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

// ── Desktop Student Sidebar ──────────────────────────────────────────────────

class _DesktopStudentSidebar extends StatelessWidget {
  final AppUser user;
  final StudentNavSection currentSection;
  final bool isExpanded;
  final int activeTicketCount;
  final VoidCallback onToggleExpand;
  final ValueChanged<StudentNavSection> onSelectSection;
  final VoidCallback onSignOut;

  const _DesktopStudentSidebar({
    required this.user,
    required this.currentSection,
    required this.isExpanded,
    required this.activeTicketCount,
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
              padding: const EdgeInsets.symmetric(horizontal: 14),
              decoration: const BoxDecoration(
                border: Border(
                  bottom: BorderSide(color: AppColors.cardBorder, width: 1),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: AppColors.accent.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: AppColors.accent.withValues(alpha: 0.3)),
                    ),
                    child: const Icon(Icons.school, color: AppColors.accent, size: 20),
                  ),
                  if (isExpanded) ...[
                    const SizedBox(width: 10),
                    const Expanded(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'BVCEC SmartQueue',
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
                            'Student Portal',
                            style: TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 10,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  IconButton(
                    icon: Icon(
                      isExpanded ? Icons.menu_open : Icons.menu,
                      color: AppColors.textSecondary,
                      size: 20,
                    ),
                    tooltip: isExpanded ? 'Collapse sidebar' : 'Expand sidebar',
                    onPressed: onToggleExpand,
                  ),
                ],
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
                      backgroundColor: AppColors.accent.withValues(alpha: 0.25),
                      child: Text(
                        user.fullName.initials,
                        style: const TextStyle(
                          color: AppColors.accent,
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
                                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                                decoration: BoxDecoration(
                                  color: AppColors.accent.withValues(alpha: 0.2),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: const Text(
                                  'STUDENT',
                                  style: TextStyle(
                                    color: AppColors.accent,
                                    fontSize: 9,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  user.registrationNumber.toUpperCase(),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    color: AppColors.textSecondary,
                                    fontSize: 10,
                                  ),
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
                children: StudentNavSection.values.map((section) {
                  final isActive = currentSection == section;
                  final hasActiveBadge = section == StudentNavSection.activeTickets && activeTicketCount > 0;

                  if (!isExpanded) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Tooltip(
                        message: hasActiveBadge ? '${section.title} ($activeTicketCount)' : section.title,
                        child: Stack(
                          clipBehavior: Clip.none,
                          alignment: Alignment.center,
                          children: [
                            InkWell(
                              borderRadius: BorderRadius.circular(10),
                              onTap: () => onSelectSection(section),
                              child: Container(
                                width: 44,
                                height: 44,
                                decoration: BoxDecoration(
                                  color: isActive
                                      ? AppColors.accent.withValues(alpha: 0.15)
                                      : Colors.transparent,
                                  borderRadius: BorderRadius.circular(10),
                                  border: isActive
                                      ? Border.all(
                                          color: AppColors.accent.withValues(alpha: 0.4),
                                          width: 1,
                                        )
                                      : null,
                                ),
                                child: Icon(
                                  isActive ? section.activeIcon : section.icon,
                                  color: isActive ? AppColors.accent : AppColors.textSecondary,
                                  size: 20,
                                ),
                              ),
                            ),
                            if (hasActiveBadge)
                              Positioned(
                                top: 2,
                                right: 8,
                                child: Container(
                                  width: 8,
                                  height: 8,
                                  decoration: const BoxDecoration(
                                    color: AppColors.accent,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    );
                  }

                  return Container(
                    margin: const EdgeInsets.symmetric(vertical: 3),
                    decoration: BoxDecoration(
                      color: isActive
                          ? AppColors.accent.withValues(alpha: 0.12)
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(10),
                      border: isActive
                          ? Border.all(
                              color: AppColors.accent.withValues(alpha: 0.35),
                              width: 1,
                            )
                          : null,
                    ),
                    child: ListTile(
                      dense: true,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      leading: Icon(
                        isActive ? section.activeIcon : section.icon,
                        color: isActive ? AppColors.accent : AppColors.textSecondary,
                        size: 20,
                      ),
                      title: Row(
                        children: [
                          Expanded(
                            child: Text(
                              section.title,
                              style: TextStyle(
                                color: isActive ? Colors.white : AppColors.textPrimary,
                                fontWeight: isActive ? FontWeight.bold : FontWeight.w500,
                                fontSize: 13,
                              ),
                            ),
                          ),
                          if (hasActiveBadge)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: AppColors.accent,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(
                                '$activeTicketCount',
                                style: const TextStyle(
                                  color: Colors.black,
                                  fontWeight: FontWeight.w900,
                                  fontSize: 10,
                                ),
                              ),
                            ),
                        ],
                      ),
                      subtitle: Text(
                        section.subtitle,
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 10,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      onTap: () => onSelectSection(section),
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
                  ? OutlinedButton.icon(
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
                      onPressed: onSignOut,
                      icon: const Icon(Icons.logout, size: 16),
                      label: const Text('Sign Out', style: TextStyle(fontWeight: FontWeight.bold)),
                    )
                  : IconButton(
                      tooltip: 'Sign Out',
                      icon: const Icon(Icons.logout, color: AppColors.cancelled, size: 20),
                      onPressed: onSignOut,
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Desktop Student Workspace Top Bar ────────────────────────────────────────

class _StudentWorkspaceTopBar extends StatelessWidget {
  final StudentNavSection currentSection;
  final AppUser user;
  final VoidCallback onRefresh;

  const _StudentWorkspaceTopBar({
    required this.currentSection,
    required this.user,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 64,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(
          bottom: BorderSide(color: AppColors.cardBorder, width: 1),
        ),
      ),
      child: Row(
        children: [
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
                        color: AppColors.accent,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'BVCEC SmartQueue  /  ${currentSection.title}',
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                        letterSpacing: -0.2,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  currentSection.subtitle,
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

          // Real-time status pill
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
                    color: AppColors.serving,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 6),
                const Text(
                  'BVCEC Connected',
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

          // Single authoritative Refresh Button (no duplicate buttons!)
          IconButton(
            icon: const Icon(Icons.refresh, color: AppColors.textSecondary, size: 20),
            tooltip: 'Refresh Queue Data',
            onPressed: onRefresh,
          ),
        ],
      ),
    );
  }
}

