import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/extensions/extensions.dart';
import '../../../core/providers/providers.dart';
import '../../../core/router/app_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/models/app_user.dart';
import '../../../data/models/counter.dart';
import '../../../data/models/queue_entry.dart';
import '../../../data/models/service_center.dart';
import '../../../domain/queue_state_machine.dart';
import '../../../shared/widgets/app_drawer.dart';
import '../../profile/presentation/profile_screen.dart';
import 'admin_analytics_screen.dart';
import 'admin_service_centers_screen.dart';

final _campusLiveStatsProvider = FutureProvider<Map<String, int>>((ref) async {
  return ref.watch(queueRepositoryProvider).getCampusLiveStats();
});

final _overviewCentersProvider = FutureProvider<List<ServiceCenter>>((ref) async {
  return ref.watch(serviceRepositoryProvider).getActiveServiceCenters();
});

final _adminStaffListProvider = FutureProvider<List<AppUser>>((ref) async {
  return ref.watch(counterRepositoryProvider).getAllStaff();
});

final _adminCountersListProvider = FutureProvider<List<Counter>>((ref) async {
  return ref.watch(counterRepositoryProvider).getAllCounters();
});

final _adminCampusActiveEntriesProvider = FutureProvider<List<QueueEntry>>((ref) async {
  return ref.watch(queueRepositoryProvider).getCampusActiveEntries();
});

enum AdminNavSection {
  overview(
    title: 'Live Campus Monitor',
    shortTitle: 'Overview',
    subtitle: 'Real-time queue numbers & live operations overview',
    icon: Icons.dashboard_outlined,
    activeIcon: Icons.dashboard,
  ),
  serviceCenters(
    title: 'Service Centers & Counters',
    shortTitle: 'Centers',
    subtitle: 'Configure departments, active services & counters',
    icon: Icons.storefront_outlined,
    activeIcon: Icons.storefront,
  ),
  analytics(
    title: 'Analytics & Reports',
    shortTitle: 'Analytics',
    subtitle: 'Queue throughput, wait times & performance analytics',
    icon: Icons.insights_outlined,
    activeIcon: Icons.insights,
  ),
  staffDesk(
    title: 'Staff Desks Roster',
    shortTitle: 'Staff Desks',
    subtitle: 'Staff duty assignments & active counter stations',
    icon: Icons.badge_outlined,
    activeIcon: Icons.badge,
  ),
  studentPortal(
    title: 'Live Student Queues',
    shortTitle: 'Student Queues',
    subtitle: 'Campus-wide student line status, tokens & wait times',
    icon: Icons.groups_outlined,
    activeIcon: Icons.groups,
  ),
  profile(
    title: 'My Profile & Account',
    shortTitle: 'Profile',
    subtitle: 'Administrator account details & preferences',
    icon: Icons.person_outline,
    activeIcon: Icons.person,
  );

  final String title;
  final String shortTitle;
  final String subtitle;
  final IconData icon;
  final IconData activeIcon;

  const AdminNavSection({
    required this.title,
    required this.shortTitle,
    required this.subtitle,
    required this.icon,
    required this.activeIcon,
  });
}

class AdminDashboardScreen extends ConsumerStatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  ConsumerState<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends ConsumerState<AdminDashboardScreen> {
  AdminNavSection _currentSection = AdminNavSection.overview;
  bool _isSidebarExpanded = true;

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProvider);
    final statsAsync = ref.watch(_campusLiveStatsProvider);
    final isDesktop = MediaQuery.of(context).size.width >= 850;

    if (isDesktop) {
      return Scaffold(
        backgroundColor: AppColors.background,
        body: Row(
          children: [
            // ── Desktop Collapsible/Expandable Sidebar ──
            _DesktopSidebar(
              user: user,
              currentSection: _currentSection,
              isExpanded: _isSidebarExpanded,
              onToggleExpand: () => setState(() => _isSidebarExpanded = !_isSidebarExpanded),
              onSelectSection: (section) => setState(() => _currentSection = section),
              onSignOut: () => _handleSignOut(context),
            ),

            // ── Main Content Area ──
            Expanded(
              child: Column(
                children: [
                  // Workspace Top Navigation Bar
                  _WorkspaceTopBar(
                    currentSection: _currentSection,
                    user: user,
                    onRefresh: _refreshAll,
                  ),

                  // Dynamic Section Workspace Body
                  Expanded(
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 200),
                      switchInCurve: Curves.easeOut,
                      switchOutCurve: Curves.easeIn,
                      child: KeyedSubtree(
                        key: ValueKey(_currentSection),
                        child: _buildSectionContent(statsAsync, user),
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

    // ── Mobile / Narrow Layout ──
    return Scaffold(
      drawer: AppDrawer(
        onSelectAdminSection: (index) {
          setState(() {
            _currentSection = AdminNavSection.values[index];
          });
        },
        selectedAdminSection: _currentSection.index,
      ),
      appBar: AppBar(
        title: Text(_currentSection.shortTitle),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh Workspace',
            onPressed: _refreshAll,
          ),
          IconButton(
            icon: const Icon(Icons.account_circle_outlined),
            tooltip: 'My Profile',
            onPressed: () => setState(() => _currentSection = AdminNavSection.profile),
          ),
          IconButton(
            icon: const Icon(Icons.logout_outlined),
            tooltip: 'Sign Out',
            onPressed: () => _handleSignOut(context),
          ),
        ],
      ),
      body: _buildSectionContent(statsAsync, user),
    );
  }

  void _refreshAll() {
    ref.invalidate(_campusLiveStatsProvider);
    ref.invalidate(_overviewCentersProvider);
    ref.invalidate(_adminStaffListProvider);
    ref.invalidate(_adminCountersListProvider);
    ref.invalidate(_adminCampusActiveEntriesProvider);
  }

  Widget _buildSectionContent(AsyncValue<Map<String, int>> statsAsync, AppUser user) {
    switch (_currentSection) {
      case AdminNavSection.overview:
        return _OverviewSection(
          statsAsync: statsAsync,
          user: user,
          onNavigateToSection: (section) => setState(() => _currentSection = section),
          onRefresh: () async => _refreshAll(),
        );
      case AdminNavSection.serviceCenters:
        return const AdminServiceCentersScreen(embedded: true);
      case AdminNavSection.analytics:
        return const AdminAnalyticsScreen(embedded: true);
      case AdminNavSection.staffDesk:
        return const _AdminStaffRosterSection();
      case AdminNavSection.studentPortal:
        return const _AdminStudentQueueMonitorSection();
      case AdminNavSection.profile:
        return const ProfileScreen(embedded: true);
    }
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
}

// ── Desktop Sidebar ──────────────────────────────────────────────────────────

class _DesktopSidebar extends StatelessWidget {
  final AppUser user;
  final AdminNavSection currentSection;
  final bool isExpanded;
  final VoidCallback onToggleExpand;
  final ValueChanged<AdminNavSection> onSelectSection;
  final VoidCallback onSignOut;

  const _DesktopSidebar({
    required this.user,
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
                            color: AppColors.accent.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: AppColors.accent.withValues(alpha: 0.3)),
                          ),
                          child: const Icon(Icons.account_balance, color: AppColors.accent, size: 20),
                        ),
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
                                'Admin Workspace',
                                style: TextStyle(
                                  color: AppColors.textSecondary,
                                  fontSize: 10,
                                ),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.menu_open, color: AppColors.textSecondary, size: 20),
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
                              color: AppColors.accent.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: AppColors.accent.withValues(alpha: 0.3)),
                            ),
                            child: const Icon(Icons.menu, color: AppColors.accent, size: 20),
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
                      backgroundColor: AppColors.adminColor.withValues(alpha: 0.3),
                      child: Text(
                        user.fullName.initials,
                        style: const TextStyle(
                          color: AppColors.adminColor,
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
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                            decoration: BoxDecoration(
                              color: AppColors.adminColor.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: const Text(
                              'ADMIN',
                              style: TextStyle(
                                color: AppColors.adminColor,
                                fontSize: 9,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
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
                children: AdminNavSection.values.map((section) {
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
                              color: isActive ? AppColors.accent.withValues(alpha: 0.15) : Colors.transparent,
                              borderRadius: BorderRadius.circular(10),
                              border: isActive ? Border.all(color: AppColors.accent.withValues(alpha: 0.4)) : null,
                            ),
                            child: Icon(
                              isActive ? section.activeIcon : section.icon,
                              color: isActive ? AppColors.accent : AppColors.textSecondary,
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
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                        decoration: BoxDecoration(
                          color: isActive ? AppColors.accent.withValues(alpha: 0.12) : Colors.transparent,
                          borderRadius: BorderRadius.circular(10),
                          border: isActive ? Border.all(color: AppColors.accent.withValues(alpha: 0.35)) : null,
                        ),
                        child: Row(
                          children: [
                            Icon(
                              isActive ? section.activeIcon : section.icon,
                              color: isActive ? AppColors.accent : AppColors.textSecondary,
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
                                      color: isActive ? AppColors.accent : AppColors.textPrimary,
                                      fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                                      fontSize: 13,
                                    ),
                                  ),
                                  Text(
                                    section.subtitle,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      color: isActive ? AppColors.accent.withValues(alpha: 0.7) : AppColors.textMuted,
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
                                  color: AppColors.accent,
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

            // Footer / Sign Out
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
                        side: BorderSide(color: AppColors.cancelled.withValues(alpha: 0.4)),
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      icon: const Icon(Icons.logout, size: 16),
                      label: const Text('Sign Out', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                      onPressed: onSignOut,
                    )
                  : Tooltip(
                      message: 'Sign Out',
                      child: IconButton(
                        icon: const Icon(Icons.logout, color: AppColors.cancelled, size: 20),
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

// ── Workspace Top Bar ────────────────────────────────────────────────────────

class _WorkspaceTopBar extends StatelessWidget {
  final AdminNavSection currentSection;
  final AppUser user;
  final VoidCallback onRefresh;

  const _WorkspaceTopBar({
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
          Icon(currentSection.activeIcon, color: AppColors.accent, size: 20),
          const SizedBox(width: 10),
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                currentSection.title,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  fontSize: 15,
                ),
              ),
              Text(
                currentSection.subtitle,
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 11,
                ),
              ),
            ],
          ),
          const Spacer(),

          // Live WebSocket Indicator
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.green.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.green.withValues(alpha: 0.3)),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.circle, color: Colors.greenAccent, size: 7),
                SizedBox(width: 5),
                Text(
                  'REAL-TIME',
                  style: TextStyle(
                    color: Colors.greenAccent,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),

          IconButton(
            icon: const Icon(Icons.refresh, color: AppColors.textSecondary),
            tooltip: 'Refresh Workspace Data',
            onPressed: onRefresh,
          ),
        ],
      ),
    );
  }
}

// ── Overview Section ─────────────────────────────────────────────────────────

class _OverviewSection extends StatelessWidget {
  final AsyncValue<Map<String, int>> statsAsync;
  final AppUser user;
  final ValueChanged<AdminNavSection> onNavigateToSection;
  final Future<void> Function() onRefresh;

  const _OverviewSection({
    required this.statsAsync,
    required this.user,
    required this.onNavigateToSection,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      color: AppColors.accent,
      onRefresh: onRefresh,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _AdminHeader(name: user.fullName),
            const SizedBox(height: 20),

            // Live Campus Queue Monitor Header
            Row(
              children: [
                const Icon(Icons.insights, color: AppColors.accent, size: 20),
                const SizedBox(width: 8),
                const Text(
                  'Campus Live Queue Monitor',
                  style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
                ),
                const Spacer(),
                Text(
                  'Real-time counters',
                  style: TextStyle(color: AppColors.textMuted, fontSize: 12),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Live Stats Grid
            statsAsync.when(
              loading: () => const LinearProgressIndicator(color: AppColors.accent),
              error: (e, _) => Text('Error loading stats: $e', style: const TextStyle(color: Colors.red)),
              data: (stats) {
                return Row(
                  children: [
                    _StatTile(
                      label: 'In Line',
                      value: '${stats['waiting'] ?? 0}',
                      subtext: 'Waiting',
                      color: AppColors.waiting,
                      icon: Icons.hourglass_top,
                    ),
                    const SizedBox(width: 10),
                    _StatTile(
                      label: 'At Window',
                      value: '${stats['serving'] ?? 0}',
                      subtext: 'Serving',
                      color: AppColors.serving,
                      icon: Icons.support_agent,
                    ),
                    const SizedBox(width: 10),
                    _StatTile(
                      label: 'Announced',
                      value: '${stats['called'] ?? 0}',
                      subtext: 'Called',
                      color: AppColors.called,
                      icon: Icons.campaign,
                    ),
                    const SizedBox(width: 10),
                    _StatTile(
                      label: 'Done Today',
                      value: '${stats['completedToday'] ?? 0}',
                      subtext: 'Completed',
                      color: AppColors.available,
                      icon: Icons.check_circle_outline,
                    ),
                  ],
                );
              },
            ),

            const SizedBox(height: 24),
            Row(
              children: const [
                Icon(Icons.storefront_outlined, color: AppColors.accent, size: 20),
                SizedBox(width: 8),
                Text(
                  'Campus Service Centers Live Status',
                  style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
                ),
                Spacer(),
                Text(
                  'Real-time overview',
                  style: TextStyle(color: AppColors.textMuted, fontSize: 12),
                ),
              ],
            ),
            const SizedBox(height: 12),
            const _CampusCentersLiveGrid(),

            const SizedBox(height: 24),

            // System Health Notice
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.surfaceElevated,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.cardBorder),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.accent.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.cloud_done, color: AppColors.accent, size: 24),
                  ),
                  const SizedBox(width: 14),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Supabase Cloud Realtime Infrastructure',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                        ),
                        SizedBox(height: 2),
                        Text(
                          'WebSocket channels connected. Queue state changes synchronize across all campus student devices and counter desks.',
                          style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Shared Stat & Header Widgets ─────────────────────────────────────────────

class _AdminHeader extends StatelessWidget {
  final String name;
  const _AdminHeader({required this.name});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.primaryDark,
            AppColors.surfaceElevated,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.cardBorder),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.25),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: AppColors.adminColor.withValues(alpha: 0.25),
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.adminColor.withValues(alpha: 0.5)),
            ),
            child: const Icon(Icons.admin_panel_settings, color: Colors.purpleAccent, size: 26),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Welcome back, $name',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 3),
                const Text(
                  'BVCEC Queue Operations & Real-Time Campus Control Hub',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12,
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

class _CampusCentersLiveGrid extends ConsumerWidget {
  const _CampusCentersLiveGrid();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final centersAsync = ref.watch(_overviewCentersProvider);

    return centersAsync.when(
      loading: () => const LinearProgressIndicator(color: AppColors.accent),
      error: (e, _) => Text(
        'Error loading service centers: $e',
        style: const TextStyle(color: Colors.red),
      ),
      data: (centers) {
        if (centers.isEmpty) {
          return Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.cardBorder),
            ),
            child: const Center(
              child: Text(
                'No active service centers configured yet.',
                style: TextStyle(color: AppColors.textSecondary),
              ),
            ),
          );
        }

        return LayoutBuilder(
          builder: (context, constraints) {
            final isWide = constraints.maxWidth >= 700;
            return Wrap(
              spacing: 12,
              runSpacing: 12,
              children: centers.map((center) {
                return SizedBox(
                  width: isWide ? (constraints.maxWidth - 12) / 2 : constraints.maxWidth,
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.cardBorder),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: AppColors.accent.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(Icons.storefront, color: AppColors.accent, size: 22),
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
                                      center.name,
                                      style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: Colors.green.withValues(alpha: 0.15),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: const Text(
                                      'ONLINE',
                                      style: TextStyle(
                                        color: Colors.greenAccent,
                                        fontSize: 9,
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 3),
                              Text(
                                center.description.isNotEmpty ? center.description : 'Campus Service Center',
                                style: const TextStyle(color: AppColors.textSecondary, fontSize: 11),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            );
          },
        );
      },
    );
  }
}

// ── Admin Staff Desks Roster Section ─────────────────────────────────────────

class _AdminStaffRosterSection extends ConsumerStatefulWidget {
  const _AdminStaffRosterSection();

  @override
  ConsumerState<_AdminStaffRosterSection> createState() => _AdminStaffRosterSectionState();
}

class _AdminStaffRosterSectionState extends ConsumerState<_AdminStaffRosterSection> {
  final TextEditingController _searchCtrl = TextEditingController();
  String _searchQuery = '';
  int _viewTab = 0; // 0 = Staff Directory & Desks, 1 = Desks & Counters
  String? _selectedCenterId;

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final staffAsync = ref.watch(_adminStaffListProvider);
    final countersAsync = ref.watch(_adminCountersListProvider);
    final centersAsync = ref.watch(_overviewCentersProvider);

    return RefreshIndicator(
      color: AppColors.accent,
      onRefresh: () async {
        ref.invalidate(_adminStaffListProvider);
        ref.invalidate(_adminCountersListProvider);
        ref.invalidate(_overviewCentersProvider);
      },
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Section Title Header
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.staffColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.badge_outlined, color: AppColors.staffColor, size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      Text(
                        'Staff Duty & Desk Allocations',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                      ),
                      Text(
                        'Monitor which staff members are stationed on which counter desks in real time',
                        style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),

            // Metrics Summary Grid
            staffAsync.when(
              loading: () => const LinearProgressIndicator(color: AppColors.staffColor),
              error: (e, _) => Text('Error loading staff: $e', style: const TextStyle(color: Colors.red)),
              data: (staffList) {
                final counters = countersAsync.value ?? <Counter>[];
                final onDeskCount = staffList.where((s) => counters.any((c) => c.assignedStaffId == s.id)).length;
                final servingOrOpen = counters.where((c) => c.assignedStaffId != null && (c.status == CounterStatus.available || c.status == CounterStatus.serving)).length;
                final unassignedStaff = staffList.length - onDeskCount;

                return Row(
                  children: [
                    _StatTile(
                      label: 'Total Staff',
                      value: '${staffList.length}',
                      subtext: 'Registered',
                      color: AppColors.staffColor,
                      icon: Icons.badge,
                    ),
                    const SizedBox(width: 10),
                    _StatTile(
                      label: 'On Desks',
                      value: '$onDeskCount',
                      subtext: 'Stationed',
                      color: AppColors.serving,
                      icon: Icons.support_agent,
                    ),
                    const SizedBox(width: 10),
                    _StatTile(
                      label: 'Serving / Ready',
                      value: '$servingOrOpen',
                      subtext: 'Available',
                      color: AppColors.available,
                      icon: Icons.check_circle_outline,
                    ),
                    const SizedBox(width: 10),
                    _StatTile(
                      label: 'Unassigned',
                      value: '$unassignedStaff',
                      subtext: 'Floating / Idle',
                      color: AppColors.textMuted,
                      icon: Icons.person_off_outlined,
                    ),
                  ],
                );
              },
            ),

            const SizedBox(height: 20),

            // Tab Selector
            Row(
              children: [
                _TabButton(
                  title: 'Staff Roster & Desks',
                  icon: Icons.people_outline,
                  isSelected: _viewTab == 0,
                  onTap: () => setState(() => _viewTab = 0),
                ),
                const SizedBox(width: 10),
                _TabButton(
                  title: 'Campus Desks & Stations',
                  icon: Icons.point_of_sale_outlined,
                  isSelected: _viewTab == 1,
                  onTap: () => setState(() => _viewTab = 1),
                ),
              ],
            ),
            const SizedBox(height: 14),

            // Search Bar
            TextField(
              controller: _searchCtrl,
              decoration: InputDecoration(
                hintText: _viewTab == 0
                    ? 'Search staff by name or employee ID (e.g. 221S001)...'
                    : 'Search counter desks (e.g. Counter 1, Helpdesk)...',
                hintStyle: const TextStyle(color: AppColors.textMuted, fontSize: 13),
                prefixIcon: const Icon(Icons.search, color: AppColors.staffColor, size: 20),
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
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
                  borderSide: const BorderSide(color: AppColors.staffColor, width: 1.5),
                ),
              ),
              onChanged: (val) => setState(() => _searchQuery = val.trim()),
            ),
            const SizedBox(height: 14),

            // Center Filter Chips
            centersAsync.when(
              loading: () => const SizedBox.shrink(),
              error: (e, st) => const SizedBox.shrink(),
              data: (centers) {
                if (centers.isEmpty) return const SizedBox.shrink();
                return SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _FilterChip(
                        label: 'All Departments',
                        isSelected: _selectedCenterId == null,
                        color: AppColors.staffColor,
                        onTap: () => setState(() => _selectedCenterId = null),
                      ),
                      ...centers.map((c) => Padding(
                        padding: const EdgeInsets.only(left: 8),
                        child: _FilterChip(
                          label: c.name,
                          isSelected: _selectedCenterId == c.id,
                          color: AppColors.staffColor,
                          onTap: () => setState(() => _selectedCenterId = c.id),
                        ),
                      )),
                    ],
                  ),
                );
              },
            ),

            const SizedBox(height: 18),

            // List Content
            if (_viewTab == 0)
              _buildStaffRosterList(staffAsync, countersAsync, centersAsync)
            else
              _buildCountersDeskList(countersAsync, staffAsync, centersAsync),
          ],
        ),
      ),
    );
  }

  Widget _buildStaffRosterList(
    AsyncValue<List<AppUser>> staffAsync,
    AsyncValue<List<Counter>> countersAsync,
    AsyncValue<List<ServiceCenter>> centersAsync,
  ) {
    return staffAsync.when(
      loading: () => const Padding(
        padding: EdgeInsets.symmetric(vertical: 40),
        child: Center(child: CircularProgressIndicator(color: AppColors.staffColor)),
      ),
      error: (e, _) => Text('Error: $e', style: const TextStyle(color: Colors.red)),
      data: (staffList) {
        final counters = countersAsync.value ?? <Counter>[];
        final centers = centersAsync.value ?? <ServiceCenter>[];

        final filtered = staffList.where((staff) {
          final assignedCounter = counters.where((c) => c.assignedStaffId == staff.id).firstOrNull;
          if (_selectedCenterId != null) {
            if (assignedCounter == null || assignedCounter.serviceCenterId != _selectedCenterId) {
              return false;
            }
          }
          if (_searchQuery.isNotEmpty) {
            final q = _searchQuery.toLowerCase();
            final name = staff.fullName.toLowerCase();
            final reg = staff.registrationNumber.toLowerCase();
            final email = (staff.email ?? '').toLowerCase();
            final counterName = (assignedCounter?.name ?? '').toLowerCase();
            if (!name.contains(q) && !reg.contains(q) && !email.contains(q) && !counterName.contains(q)) {
              return false;
            }
          }
          return true;
        }).toList();

        if (filtered.isEmpty) {
          return Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 20),
            decoration: BoxDecoration(
              color: AppColors.surfaceElevated,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.cardBorder),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.person_search_outlined, size: 48, color: AppColors.textMuted),
                const SizedBox(height: 12),
                Text(
                  _searchQuery.isNotEmpty
                      ? 'No staff members matching "$_searchQuery"'
                      : 'No staff members found for the selected department',
                  style: const TextStyle(color: AppColors.textSecondary, fontSize: 14, fontWeight: FontWeight.w600),
                ),
              ],
            ),
          );
        }

        return ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: filtered.length,
          separatorBuilder: (context, index) => const SizedBox(height: 10),
          itemBuilder: (ctx, i) {
            final staff = filtered[i];
            final counter = counters.where((c) => c.assignedStaffId == staff.id).firstOrNull;
            final center = counter != null
                ? centers.where((c) => c.id == counter.serviceCenterId).firstOrNull
                : null;

            return Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.surfaceElevated,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: counter != null
                      ? AppColors.staffColor.withValues(alpha: 0.35)
                      : AppColors.cardBorder,
                ),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 22,
                    backgroundColor: AppColors.staffColor.withValues(alpha: 0.2),
                    child: Text(
                      staff.fullName.initials,
                      style: const TextStyle(
                        color: AppColors.staffColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
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
                              staff.fullName,
                              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: Colors.white),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                              decoration: BoxDecoration(
                                color: AppColors.staffColor.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                staff.registrationNumber.toUpperCase(),
                                style: const TextStyle(
                                  color: AppColors.staffColor,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 3),
                        Text(
                          staff.email ?? '',
                          style: const TextStyle(color: AppColors.textMuted, fontSize: 11),
                        ),
                        const SizedBox(height: 8),
                        if (counter != null)
                          Row(
                            children: [
                              const Icon(Icons.point_of_sale, size: 14, color: AppColors.accent),
                              const SizedBox(width: 5),
                              Text(
                                'Working on ${counter.name}',
                                style: const TextStyle(
                                  color: AppColors.accent,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              if (center != null) ...[
                                const SizedBox(width: 6),
                                Flexible(
                                  child: Text(
                                    '•  ${center.name}',
                                    style: const TextStyle(color: AppColors.textSecondary, fontSize: 11),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ],
                          )
                        else
                          Row(
                            children: const [
                              Icon(Icons.person_off_outlined, size: 14, color: AppColors.textMuted),
                              SizedBox(width: 5),
                              Text(
                                'No Desk Assigned (Off Duty / Floating Staff)',
                                style: TextStyle(
                                  color: AppColors.textMuted,
                                  fontSize: 11,
                                  fontStyle: FontStyle.italic,
                                ),
                              ),
                            ],
                          ),
                      ],
                    ),
                  ),
                  _buildCounterStatusChip(counter?.status),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildCountersDeskList(
    AsyncValue<List<Counter>> countersAsync,
    AsyncValue<List<AppUser>> staffAsync,
    AsyncValue<List<ServiceCenter>> centersAsync,
  ) {
    return countersAsync.when(
      loading: () => const Padding(
        padding: EdgeInsets.symmetric(vertical: 40),
        child: Center(child: CircularProgressIndicator(color: AppColors.staffColor)),
      ),
      error: (e, _) => Text('Error: $e', style: const TextStyle(color: Colors.red)),
      data: (counters) {
        final staffList = staffAsync.value ?? <AppUser>[];
        final centers = centersAsync.value ?? <ServiceCenter>[];

        final filtered = counters.where((counter) {
          if (_selectedCenterId != null && counter.serviceCenterId != _selectedCenterId) {
            return false;
          }
          if (_searchQuery.isNotEmpty) {
            final q = _searchQuery.toLowerCase();
            final counterName = counter.name.toLowerCase();
            final staffName = (counter.assignedStaffName ?? '').toLowerCase();
            if (!counterName.contains(q) && !staffName.contains(q)) {
              return false;
            }
          }
          return true;
        }).toList();

        if (filtered.isEmpty) {
          return Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 20),
            decoration: BoxDecoration(
              color: AppColors.surfaceElevated,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.cardBorder),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.storefront_outlined, size: 48, color: AppColors.textMuted),
                const SizedBox(height: 12),
                Text(
                  _searchQuery.isNotEmpty
                      ? 'No counter desks matching "$_searchQuery"'
                      : 'No counters configured for the selected department',
                  style: const TextStyle(color: AppColors.textSecondary, fontSize: 14, fontWeight: FontWeight.w600),
                ),
              ],
            ),
          );
        }

        return ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: filtered.length,
          separatorBuilder: (context, index) => const SizedBox(height: 10),
          itemBuilder: (ctx, i) {
            final counter = filtered[i];
            final center = centers.where((c) => c.id == counter.serviceCenterId).firstOrNull;
            final assignedStaff = counter.assignedStaffId != null
                ? staffList.where((s) => s.id == counter.assignedStaffId).firstOrNull
                : null;

            return Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.surfaceElevated,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: counter.assignedStaffId != null
                      ? AppColors.staffColor.withValues(alpha: 0.3)
                      : AppColors.cardBorder,
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: AppColors.staffColor.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.point_of_sale, color: AppColors.staffColor, size: 22),
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
                              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: Colors.white),
                            ),
                            if (center != null) ...[
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                                decoration: BoxDecoration(
                                  color: AppColors.surface,
                                  borderRadius: BorderRadius.circular(4),
                                  border: Border.all(color: AppColors.cardBorder),
                                ),
                                child: Text(
                                  center.name,
                                  style: const TextStyle(color: AppColors.textSecondary, fontSize: 10),
                                ),
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: 6),
                        if (counter.assignedStaffId != null)
                          Row(
                            children: [
                              const Icon(Icons.person, size: 14, color: AppColors.staffColor),
                              const SizedBox(width: 5),
                              Text(
                                'Operated by: ${counter.assignedStaffName ?? assignedStaff?.fullName ?? 'Assigned Staff'}',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              if (assignedStaff != null) ...[
                                const SizedBox(width: 6),
                                Text(
                                  '(${assignedStaff.registrationNumber})',
                                  style: const TextStyle(color: AppColors.textMuted, fontSize: 11),
                                ),
                              ],
                            ],
                          )
                        else
                          Row(
                            children: const [
                              Icon(Icons.person_off_outlined, size: 14, color: AppColors.textMuted),
                              SizedBox(width: 5),
                              Text(
                                'Desk Vacant (No staff member stationed)',
                                style: TextStyle(
                                  color: AppColors.textMuted,
                                  fontSize: 11,
                                  fontStyle: FontStyle.italic,
                                ),
                              ),
                            ],
                          ),
                      ],
                    ),
                  ),
                  _buildCounterStatusChip(counter.status),
                ],
              ),
            );
          },
        );
      },
    );
  }
}

// ── Admin Student Queue Monitor Section ──────────────────────────────────────

class _AdminStudentQueueMonitorSection extends ConsumerStatefulWidget {
  const _AdminStudentQueueMonitorSection();

  @override
  ConsumerState<_AdminStudentQueueMonitorSection> createState() => _AdminStudentQueueMonitorSectionState();
}

class _AdminStudentQueueMonitorSectionState extends ConsumerState<_AdminStudentQueueMonitorSection> {
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
    final activeEntriesAsync = ref.watch(_adminCampusActiveEntriesProvider);

    return RefreshIndicator(
      color: AppColors.accent,
      onRefresh: () async {
        ref.invalidate(_adminCampusActiveEntriesProvider);
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
                    color: AppColors.accent.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.groups_outlined, color: AppColors.accent, size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      Text(
                        'Live Campus Student Queue Monitor',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                      ),
                      Text(
                        'Real-time view of all students queued, waiting, called, and being served across BVCEC',
                        style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),

            // Live Metrics Summary
            activeEntriesAsync.when(
              loading: () => const LinearProgressIndicator(color: AppColors.accent),
              error: (e, _) => Text('Error loading queues: $e', style: const TextStyle(color: Colors.red)),
              data: (entries) {
                final waitingCount = entries.where((e) => e.status == QueueEntryStatus.waiting).length;
                final calledCount = entries.where((e) => e.status == QueueEntryStatus.called).length;
                final servingCount = entries.where((e) => e.status == QueueEntryStatus.serving).length;

                return Row(
                  children: [
                    _StatTile(
                      label: 'In Line',
                      value: '${entries.length}',
                      subtext: 'Campus Total',
                      color: AppColors.accent,
                      icon: Icons.groups,
                    ),
                    const SizedBox(width: 10),
                    _StatTile(
                      label: 'Waiting',
                      value: '$waitingCount',
                      subtext: 'In Turn Line',
                      color: AppColors.waiting,
                      icon: Icons.hourglass_top,
                    ),
                    const SizedBox(width: 10),
                    _StatTile(
                      label: 'Called',
                      value: '$calledCount',
                      subtext: 'To Desk',
                      color: AppColors.called,
                      icon: Icons.campaign,
                    ),
                    const SizedBox(width: 10),
                    _StatTile(
                      label: 'Serving',
                      value: '$servingCount',
                      subtext: 'At Counter',
                      color: AppColors.serving,
                      icon: Icons.support_agent,
                    ),
                  ],
                );
              },
            ),

            const SizedBox(height: 20),

            // Search Bar
            TextField(
              controller: _searchCtrl,
              decoration: InputDecoration(
                hintText: 'Search by student name, registration number, or token #...',
                hintStyle: const TextStyle(color: AppColors.textMuted, fontSize: 13),
                prefixIcon: const Icon(Icons.search, color: AppColors.accent, size: 20),
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
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
                  borderSide: const BorderSide(color: AppColors.accent, width: 1.5),
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
                final waitingCount = entries.where((e) => e.status == QueueEntryStatus.waiting).length;
                final calledCount = entries.where((e) => e.status == QueueEntryStatus.called).length;
                final servingCount = entries.where((e) => e.status == QueueEntryStatus.serving).length;

                return SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _FilterChip(
                        label: 'All Active (${entries.length})',
                        isSelected: _statusFilter == null,
                        color: AppColors.accent,
                        onTap: () => setState(() => _statusFilter = null),
                      ),
                      const SizedBox(width: 8),
                      _FilterChip(
                        label: 'Waiting ($waitingCount)',
                        isSelected: _statusFilter == QueueEntryStatus.waiting,
                        color: AppColors.waiting,
                        onTap: () => setState(() => _statusFilter = QueueEntryStatus.waiting),
                      ),
                      const SizedBox(width: 8),
                      _FilterChip(
                        label: 'Called ($calledCount)',
                        isSelected: _statusFilter == QueueEntryStatus.called,
                        color: AppColors.called,
                        onTap: () => setState(() => _statusFilter = QueueEntryStatus.called),
                      ),
                      const SizedBox(width: 8),
                      _FilterChip(
                        label: 'Serving ($servingCount)',
                        isSelected: _statusFilter == QueueEntryStatus.serving,
                        color: AppColors.serving,
                        onTap: () => setState(() => _statusFilter = QueueEntryStatus.serving),
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
                child: Center(child: CircularProgressIndicator(color: AppColors.accent)),
              ),
              error: (e, _) => Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.cancelled.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text('Error loading campus queues: $e', style: const TextStyle(color: Colors.red)),
              ),
              data: (entries) {
                final filtered = entries.where((e) {
                  if (_statusFilter != null && e.status != _statusFilter) return false;
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
                    padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 20),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceElevated,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: AppColors.cardBorder),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.people_outline, size: 48, color: AppColors.textMuted),
                        const SizedBox(height: 12),
                        Text(
                          _searchQuery.isNotEmpty
                              ? 'No queue tickets match "$_searchQuery"'
                              : 'No students currently waiting in queue',
                          style: const TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'Queue entries update automatically as students join campus queues',
                          style: TextStyle(color: AppColors.textMuted, fontSize: 11),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: filtered.length,
                  separatorBuilder: (context, index) => const SizedBox(height: 10),
                  itemBuilder: (ctx, i) {
                    final entry = filtered[i];
                    return _AdminStudentQueueCard(entry: entry);
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

class _AdminStudentQueueCard extends StatelessWidget {
  final QueueEntry entry;
  const _AdminStudentQueueCard({required this.entry});

  @override
  Widget build(BuildContext context) {
    final (badgeColor, statusLabel, icon) = switch (entry.status) {
      QueueEntryStatus.waiting => (AppColors.waiting, 'WAITING IN LINE', Icons.hourglass_top),
      QueueEntryStatus.called => (AppColors.called, 'CALLED TO DESK', Icons.campaign),
      QueueEntryStatus.serving => (AppColors.serving, 'CURRENTLY SERVING', Icons.support_agent),
      _ => (AppColors.textMuted, 'OTHER', Icons.circle),
    };

    final waitMinutes = DateTime.now().difference(entry.joinedAt).inMinutes;
    final waitText = waitMinutes < 1 ? 'Just joined' : 'Waiting for ${waitMinutes}m';

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
                        style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: Colors.white),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (entry.priority > 0) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                        decoration: BoxDecoration(
                          color: Colors.amber.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Text(
                          'PRIORITY',
                          style: TextStyle(color: Colors.amber, fontSize: 9, fontWeight: FontWeight.w800),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 3),
                Text(
                  entry.serviceName ?? 'Campus Service',
                  style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Icon(
                      entry.counterName != null ? Icons.point_of_sale : Icons.desk_outlined,
                      size: 13,
                      color: entry.counterName != null ? AppColors.staffColor : AppColors.textMuted,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      entry.counterName != null ? 'Desk: ${entry.counterName}' : 'Desk: Not yet assigned',
                      style: TextStyle(
                        color: entry.counterName != null ? AppColors.staffColor : AppColors.textMuted,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Icon(Icons.access_time, size: 12, color: AppColors.textMuted),
                    const SizedBox(width: 4),
                    Text(
                      waitText,
                      style: const TextStyle(color: AppColors.textMuted, fontSize: 11),
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

// ── Shared Helper Components for Admin Monitors ──────────────────────────────

class _TabButton extends StatelessWidget {
  final String title;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  const _TabButton({
    required this.title,
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(10),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.staffColor.withValues(alpha: 0.15) : AppColors.surfaceElevated,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected ? AppColors.staffColor : AppColors.cardBorder,
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: isSelected ? AppColors.staffColor : AppColors.textSecondary),
            const SizedBox(width: 6),
            Text(
              title,
              style: TextStyle(
                color: isSelected ? Colors.white : AppColors.textSecondary,
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
    final activeColor = color ?? AppColors.accent;
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? activeColor.withValues(alpha: 0.15) : AppColors.surfaceElevated,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? activeColor : AppColors.cardBorder,
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? (color != null ? activeColor : Colors.white) : AppColors.textSecondary,
            fontSize: 11,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
          ),
        ),
      ),
    );
  }
}

Widget _buildCounterStatusChip(CounterStatus? status) {
  if (status == null) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: const Text(
        'OFF DUTY',
        style: TextStyle(color: AppColors.textMuted, fontSize: 10, fontWeight: FontWeight.bold),
      ),
    );
  }

  final (color, label) = switch (status) {
    CounterStatus.available => (Colors.greenAccent, 'AVAILABLE'),
    CounterStatus.serving => (Colors.blueAccent, 'SERVING'),
    CounterStatus.paused => (Colors.orangeAccent, 'ON BREAK'),
    CounterStatus.offline => (Colors.redAccent, 'DESK OFFLINE'),
  };

  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
    decoration: BoxDecoration(
      color: color.withValues(alpha: 0.12),
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: color.withValues(alpha: 0.4)),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.circle, size: 7, color: color),
        const SizedBox(width: 5),
        Text(
          label,
          style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold),
        ),
      ],
    ),
  );
}

