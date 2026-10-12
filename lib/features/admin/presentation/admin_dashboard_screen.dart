import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/extensions/extensions.dart';
import '../../../core/providers/providers.dart';
import '../../../core/router/app_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/models/app_user.dart';
import '../../../data/models/service_center.dart';
import '../../../shared/widgets/app_drawer.dart';
import '../../profile/presentation/profile_screen.dart';
import '../../staff/presentation/counter_screen.dart';
import '../../student/presentation/student_home_screen.dart';
import 'admin_analytics_screen.dart';
import 'admin_service_centers_screen.dart';

final _campusLiveStatsProvider = FutureProvider<Map<String, int>>((ref) async {
  return ref.watch(queueRepositoryProvider).getCampusLiveStats();
});

final _overviewCentersProvider = FutureProvider<List<ServiceCenter>>((ref) async {
  return ref.watch(serviceRepositoryProvider).getActiveServiceCenters();
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
    title: 'Staff Operation Desk',
    shortTitle: 'Staff Desk',
    subtitle: 'Live counter calling & ticket serving simulator',
    icon: Icons.point_of_sale_outlined,
    activeIcon: Icons.point_of_sale,
  ),
  studentPortal(
    title: 'Student Ticket View',
    shortTitle: 'Student View',
    subtitle: 'Live student ticketing & service queue view',
    icon: Icons.school_outlined,
    activeIcon: Icons.school,
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
                    onRefresh: () => ref.refresh(_campusLiveStatsProvider),
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
            tooltip: 'Refresh Stats',
            onPressed: () => ref.refresh(_campusLiveStatsProvider),
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

  Widget _buildSectionContent(AsyncValue<Map<String, int>> statsAsync, AppUser user) {
    switch (_currentSection) {
      case AdminNavSection.overview:
        return _OverviewSection(
          statsAsync: statsAsync,
          user: user,
          onNavigateToSection: (section) => setState(() => _currentSection = section),
          onRefresh: () => ref.refresh(_campusLiveStatsProvider.future),
        );
      case AdminNavSection.serviceCenters:
        return const AdminServiceCentersScreen(embedded: true);
      case AdminNavSection.analytics:
        return const AdminAnalyticsScreen(embedded: true);
      case AdminNavSection.staffDesk:
        return const CounterScreen(embedded: true);
      case AdminNavSection.studentPortal:
        return const StudentHomeScreen(embedded: true);
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
                    child: const Icon(Icons.account_balance, color: AppColors.accent, size: 20),
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
                            'Admin Workspace',
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
