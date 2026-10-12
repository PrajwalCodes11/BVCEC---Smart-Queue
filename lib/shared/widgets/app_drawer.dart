import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/extensions/extensions.dart';
import '../../../core/providers/providers.dart';
import '../../../core/router/app_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/models/app_user.dart';

class AppDrawer extends ConsumerWidget {
  final VoidCallback? onResetStaffFlow;
  final ValueChanged<int>? onSelectAdminSection;
  final int? selectedAdminSection;
  final ValueChanged<int>? onSelectStudentSection;
  final int? selectedStudentSection;
  final ValueChanged<int>? onSelectStaffSection;
  final int? selectedStaffSection;

  const AppDrawer({
    super.key,
    this.onResetStaffFlow,
    this.onSelectAdminSection,
    this.selectedAdminSection,
    this.onSelectStudentSection,
    this.selectedStudentSection,
    this.onSelectStaffSection,
    this.selectedStaffSection,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    final currentPath = GoRouterState.of(context).matchedLocation;

    final roleColor = switch (user.role) {
      UserRole.student => AppColors.accent,
      UserRole.staff => AppColors.staffColor,
      UserRole.admin => AppColors.adminColor,
    };

    final roleLabel = switch (user.role) {
      UserRole.student => 'STUDENT',
      UserRole.staff => 'STAFF',
      UserRole.admin => 'ADMINISTRATOR',
    };

    return Drawer(
      backgroundColor: AppColors.surface,
      child: SafeArea(
        child: Column(
          children: [
            // ── Drawer Header ──
            Container(
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppColors.primaryDark,
                    AppColors.surfaceElevated,
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                border: const Border(
                  bottom: BorderSide(color: AppColors.cardBorder, width: 1),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppColors.accent.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: AppColors.accent.withValues(alpha: 0.3),
                          ),
                        ),
                        child: const Icon(
                          Icons.account_balance,
                          color: AppColors.accent,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: const [
                            Text(
                              'BVCEC SmartQueue',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                                letterSpacing: 0.5,
                              ),
                            ),
                            Text(
                              'Smart Campus Flow',
                              style: TextStyle(
                                fontSize: 11,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // User Info Pill Card
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.surface.withValues(alpha: 0.8),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.cardBorder),
                    ),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 20,
                          backgroundColor: roleColor.withValues(alpha: 0.25),
                          child: Text(
                            user.fullName.initials,
                            style: TextStyle(
                              color: roleColor,
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                user.fullName,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 13,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 6,
                                      vertical: 2,
                                    ),
                                    decoration: BoxDecoration(
                                      color: roleColor.withValues(alpha: 0.2),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(
                                      roleLabel,
                                      style: TextStyle(
                                        color: roleColor,
                                        fontWeight: FontWeight.w800,
                                        fontSize: 9,
                                        letterSpacing: 0.5,
                                      ),
                                    ),
                                  ),
                                  if (user.registrationNumber.isNotEmpty) ...[
                                    const SizedBox(width: 6),
                                    Flexible(
                                      child: Text(
                                        user.registrationNumber,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(
                                          color: AppColors.textMuted,
                                          fontSize: 11,
                                        ),
                                      ),
                                    ),
                                  ],
                                ],
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

            // ── Navigation Menu Items ──
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
                children: [
                  // Student Section
                  if (user.role == UserRole.student) ...[
                    _buildSectionHeader('STUDENT SERVICES'),
                    _DrawerTile(
                      icon: Icons.storefront_outlined,
                      activeIcon: Icons.storefront,
                      title: 'Live Campus Queues',
                      subtitle: 'Join queues & check counters',
                      isActive: onSelectStudentSection != null
                          ? selectedStudentSection == 0
                          : currentPath == AppRoutes.studentHome,
                      onTap: () {
                        Navigator.pop(context);
                        if (onSelectStudentSection != null) {
                          onSelectStudentSection!(0);
                        } else if (currentPath != AppRoutes.studentHome) {
                          context.go(AppRoutes.studentHome);
                        }
                      },
                    ),
                    _DrawerTile(
                      icon: Icons.confirmation_number_outlined,
                      activeIcon: Icons.confirmation_number,
                      title: 'My Active Tickets',
                      subtitle: 'Live turn positions & wait times',
                      isActive: onSelectStudentSection != null
                          ? selectedStudentSection == 1
                          : false,
                      onTap: () {
                        Navigator.pop(context);
                        if (onSelectStudentSection != null) {
                          onSelectStudentSection!(1);
                        } else {
                          context.go(AppRoutes.studentHome);
                        }
                      },
                    ),
                    _DrawerTile(
                      icon: Icons.history_outlined,
                      activeIcon: Icons.history,
                      title: 'Queue History',
                      subtitle: 'View your completed tickets',
                      isActive: onSelectStudentSection != null
                          ? selectedStudentSection == 2
                          : currentPath == AppRoutes.history,
                      onTap: () {
                        Navigator.pop(context);
                        if (onSelectStudentSection != null) {
                          onSelectStudentSection!(2);
                        } else if (currentPath != AppRoutes.history) {
                          context.push(AppRoutes.history);
                        }
                      },
                    ),
                  ],

                  // Staff Section
                  if (user.role == UserRole.staff) ...[
                    _buildSectionHeader('STAFF DESK'),
                    _DrawerTile(
                      icon: Icons.point_of_sale_outlined,
                      activeIcon: Icons.point_of_sale,
                      title: 'Counter Desk',
                      subtitle: 'Serve students & call tickets',
                      isActive: onSelectStaffSection != null
                          ? selectedStaffSection == 0
                          : currentPath == AppRoutes.staffCounter,
                      onTap: () {
                        Navigator.pop(context);
                        if (onSelectStaffSection != null) {
                          onSelectStaffSection!(0);
                        } else if (currentPath != AppRoutes.staffCounter) {
                          context.go(AppRoutes.staffCounter);
                        }
                      },
                    ),
                    _DrawerTile(
                      icon: Icons.swap_horiz_outlined,
                      activeIcon: Icons.swap_horiz,
                      title: 'Switch Service Center',
                      subtitle: 'Change your assigned center',
                      isActive: onSelectStaffSection != null
                          ? selectedStaffSection == 1
                          : false,
                      onTap: () {
                        Navigator.pop(context);
                        if (onSelectStaffSection != null) {
                          onSelectStaffSection!(1);
                        } else if (onResetStaffFlow != null) {
                          onResetStaffFlow!();
                        }
                      },
                    ),
                  ],

                  // Admin Section
                  if (user.role == UserRole.admin) ...[
                    _buildSectionHeader('ADMINISTRATION'),
                    _DrawerTile(
                      icon: Icons.analytics_outlined,
                      activeIcon: Icons.analytics,
                      title: 'Live Overview',
                      subtitle: 'Live monitor & campus stats',
                      isActive: onSelectAdminSection != null
                          ? selectedAdminSection == 0
                          : currentPath == AppRoutes.adminDashboard,
                      onTap: () {
                        Navigator.pop(context);
                        if (onSelectAdminSection != null) {
                          onSelectAdminSection!(0);
                        } else if (currentPath != AppRoutes.adminDashboard) {
                          context.go(AppRoutes.adminDashboard);
                        }
                      },
                    ),
                    _DrawerTile(
                      icon: Icons.storefront_outlined,
                      activeIcon: Icons.storefront,
                      title: 'Service Centers',
                      subtitle: 'Manage centers, services & counters',
                      isActive: onSelectAdminSection != null
                          ? selectedAdminSection == 1
                          : currentPath == AppRoutes.adminServiceCenters,
                      onTap: () {
                        Navigator.pop(context);
                        if (onSelectAdminSection != null) {
                          onSelectAdminSection!(1);
                        } else if (currentPath != AppRoutes.adminServiceCenters) {
                          context.push(AppRoutes.adminServiceCenters);
                        }
                      },
                    ),
                    _DrawerTile(
                      icon: Icons.insights_outlined,
                      activeIcon: Icons.insights,
                      title: 'Analytics & Reports',
                      subtitle: 'Throughput, wait times & trends',
                      isActive: onSelectAdminSection != null
                          ? selectedAdminSection == 2
                          : currentPath == AppRoutes.adminAnalytics,
                      onTap: () {
                        Navigator.pop(context);
                        if (onSelectAdminSection != null) {
                          onSelectAdminSection!(2);
                        } else if (currentPath != AppRoutes.adminAnalytics) {
                          context.push(AppRoutes.adminAnalytics);
                        }
                      },
                    ),
                    const SizedBox(height: 8),
                    _buildSectionHeader('PORTAL VIEWS'),
                    _DrawerTile(
                      icon: Icons.point_of_sale_outlined,
                      activeIcon: Icons.point_of_sale,
                      title: 'Staff Counter View',
                      subtitle: 'Inspect staff operation desk',
                      isActive: onSelectAdminSection != null
                          ? selectedAdminSection == 3
                          : currentPath == AppRoutes.staffCounter,
                      onTap: () {
                        Navigator.pop(context);
                        if (onSelectAdminSection != null) {
                          onSelectAdminSection!(3);
                        } else if (currentPath != AppRoutes.staffCounter) {
                          context.go(AppRoutes.staffCounter);
                        }
                      },
                    ),
                    _DrawerTile(
                      icon: Icons.school_outlined,
                      activeIcon: Icons.school,
                      title: 'Student Queue View',
                      subtitle: 'Inspect student ticketing interface',
                      isActive: onSelectAdminSection != null
                          ? selectedAdminSection == 4
                          : currentPath == AppRoutes.studentHome,
                      onTap: () {
                        Navigator.pop(context);
                        if (onSelectAdminSection != null) {
                          onSelectAdminSection!(4);
                        } else if (currentPath != AppRoutes.studentHome) {
                          context.go(AppRoutes.studentHome);
                        }
                      },
                    ),
                  ],

                  const SizedBox(height: 8),
                  _buildSectionHeader('ACCOUNT & SETTINGS'),
                  _DrawerTile(
                    icon: Icons.person_outline,
                    activeIcon: Icons.person,
                    title: 'My Profile',
                    subtitle: 'Account details & contact info',
                    isActive: (onSelectAdminSection != null && user.role == UserRole.admin && selectedAdminSection == 5) ||
                        (onSelectStudentSection != null && user.role == UserRole.student && selectedStudentSection == 3) ||
                        (onSelectStaffSection != null && user.role == UserRole.staff && selectedStaffSection == 2) ||
                        currentPath == AppRoutes.profile,
                    onTap: () {
                      Navigator.pop(context);
                      if (onSelectAdminSection != null && user.role == UserRole.admin) {
                        onSelectAdminSection!(5);
                      } else if (onSelectStudentSection != null && user.role == UserRole.student) {
                        onSelectStudentSection!(3);
                      } else if (onSelectStaffSection != null && user.role == UserRole.staff) {
                        onSelectStaffSection!(2);
                      } else if (currentPath != AppRoutes.profile) {
                        context.push(AppRoutes.profile);
                      }
                    },
                  ),
                ],
              ),
            ),

            // ── Drawer Footer ──
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              decoration: const BoxDecoration(
                color: AppColors.surfaceElevated,
                border: Border(
                  top: BorderSide(color: AppColors.cardBorder, width: 1),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
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
                      onPressed: () async {
                        final confirmed = await showDialog<bool>(
                          context: context,
                          builder: (ctx) => AlertDialog(
                            backgroundColor: AppColors.surface,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
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
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.cancelled,
                                ),
                                child: const Text('Sign Out'),
                              ),
                            ],
                          ),
                        );
                        if (confirmed == true && context.mounted) {
                          Navigator.pop(context);
                          await ref.read(authRepositoryProvider).signOut();
                          if (context.mounted) {
                            context.go(AppRoutes.login);
                          }
                        }
                      },
                      icon: const Icon(Icons.logout, size: 16),
                      label: const Text('Sign Out',
                          style: TextStyle(fontWeight: FontWeight.bold)),
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

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 6),
      child: Text(
        title,
        style: const TextStyle(
          color: AppColors.textMuted,
          fontSize: 10,
          fontWeight: FontWeight.w800,
          letterSpacing: 1.2,
        ),
      ),
    );
  }
}

class _DrawerTile extends StatelessWidget {
  final IconData icon;
  final IconData activeIcon;
  final String title;
  final String subtitle;
  final bool isActive;
  final VoidCallback onTap;

  const _DrawerTile({
    required this.icon,
    required this.activeIcon,
    required this.title,
    required this.subtitle,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Material(
        color: Colors.transparent,
        child: ListTile(
          dense: true,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          selected: isActive,
          selectedTileColor: AppColors.accent.withValues(alpha: 0.12),
          leading: Icon(
            isActive ? activeIcon : icon,
            color: isActive ? AppColors.accent : AppColors.textSecondary,
            size: 20,
          ),
          title: Text(
            title,
            style: TextStyle(
              color: isActive ? AppColors.accent : AppColors.textPrimary,
              fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
              fontSize: 13,
            ),
          ),
          subtitle: Text(
            subtitle,
            style: TextStyle(
              color: isActive
                  ? AppColors.accent.withValues(alpha: 0.8)
                  : AppColors.textMuted,
              fontSize: 11,
            ),
          ),
          trailing: isActive
              ? Container(
                  width: 6,
                  height: 6,
                  decoration: const BoxDecoration(
                    color: AppColors.accent,
                    shape: BoxShape.circle,
                  ),
                )
              : null,
          onTap: onTap,
        ),
      ),
    );
  }
}
