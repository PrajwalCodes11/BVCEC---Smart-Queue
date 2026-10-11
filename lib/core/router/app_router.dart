import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/providers/providers.dart';
import '../../data/models/app_user.dart';
import '../../features/auth/presentation/login_screen.dart';
import '../../features/student/presentation/student_home_screen.dart';
import '../../features/student/presentation/service_list_screen.dart';
import '../../features/student/presentation/queue_screen.dart';
import '../../features/student/presentation/history_screen.dart';
import '../../features/staff/presentation/counter_screen.dart';
import '../../features/admin/presentation/admin_dashboard_screen.dart';
import '../../features/admin/presentation/admin_service_centers_screen.dart';
import '../../features/admin/presentation/admin_services_screen.dart';
import '../../features/admin/presentation/admin_counters_screen.dart';
import '../../features/admin/presentation/admin_analytics_screen.dart';
import '../../features/profile/presentation/profile_screen.dart';

class AppRoutes {
  static const login = '/login';
  static const studentHome = '/student';
  static const serviceList = '/student/services/:centerId';
  static const queue = '/student/queue/:entryId';
  static const history = '/student/history';
  static const staffCounter = '/staff/counter';
  static const adminDashboard = '/admin';
  static const adminServiceCenters = '/admin/service-centers';
  static const adminServices = '/admin/services/:centerId';
  static const adminCounters = '/admin/counters/:centerId';
  static const adminAnalytics = '/admin/analytics';
  static const profile = '/profile';

  static String roleHome(UserRole role) {
    switch (role) {
      case UserRole.student:
        return studentHome;
      case UserRole.staff:
        return staffCounter;
      case UserRole.admin:
        return adminDashboard;
    }
  }
}

class _RouterNotifier extends ChangeNotifier {
  _RouterNotifier(Ref ref) {
    ref.listen(authStateProvider, (_, _) => notifyListeners());
  }
}

final _routerNotifierProvider = Provider<_RouterNotifier>((ref) {
  return _RouterNotifier(ref);
});

final routerProvider = Provider<GoRouter>((ref) {
  final notifier = ref.watch(_routerNotifierProvider);

  return GoRouter(
    refreshListenable: notifier,
    initialLocation: AppRoutes.login,
    redirect: (context, state) {
      final authAsync = ref.read(authStateProvider);
      final isLoggedIn = authAsync.maybeWhen(
        data: (user) => user != null,
        orElse: () => false,
      );
      final user = authAsync.maybeWhen(
        data: (u) => u,
        orElse: () => null,
      );

      final onLogin = state.matchedLocation == AppRoutes.login;

      // Not logged in → always redirect to login
      if (!isLoggedIn) {
        return onLogin ? null : AppRoutes.login;
      }

      // Logged in on login page → redirect to role home
      if (onLogin && user != null) {
        return AppRoutes.roleHome(user.role);
      }

      // Role-based path guard
      if (user != null) {
        final path = state.matchedLocation;
        if (path.startsWith('/student') && user.role != UserRole.student) {
          return AppRoutes.roleHome(user.role);
        }
        if (path.startsWith('/staff') && user.role != UserRole.staff) {
          return AppRoutes.roleHome(user.role);
        }
        if (path.startsWith('/admin') && user.role != UserRole.admin) {
          return AppRoutes.roleHome(user.role);
        }
      }
      return null;
    },
    routes: [
      GoRoute(
        path: AppRoutes.login,
        builder: (context, state) => const LoginScreen(),
      ),

      // ── Student routes ───────────────────────────────────────────────────
      GoRoute(
        path: AppRoutes.studentHome,
        builder: (context, state) => const StudentHomeScreen(),
      ),
      GoRoute(
        path: AppRoutes.serviceList,
        builder: (_, state) => ServiceListScreen(
          centerId: state.pathParameters['centerId']!,
        ),
      ),
      GoRoute(
        path: AppRoutes.queue,
        builder: (_, state) => QueueScreen(
          entryId: state.pathParameters['entryId']!,
        ),
      ),
      GoRoute(
        path: AppRoutes.history,
        builder: (context, state) => const HistoryScreen(),
      ),

      // ── Staff routes ─────────────────────────────────────────────────────
      GoRoute(
        path: AppRoutes.staffCounter,
        builder: (context, state) => const CounterScreen(),
      ),

      // ── Admin routes ─────────────────────────────────────────────────────
      GoRoute(
        path: AppRoutes.adminDashboard,
        builder: (context, state) => const AdminDashboardScreen(),
      ),
      GoRoute(
        path: AppRoutes.adminServiceCenters,
        builder: (context, state) => const AdminServiceCentersScreen(),
      ),
      GoRoute(
        path: AppRoutes.adminServices,
        builder: (_, state) => AdminServicesScreen(
          centerId: state.pathParameters['centerId']!,
        ),
      ),
      GoRoute(
        path: AppRoutes.adminCounters,
        builder: (_, state) => AdminCountersScreen(
          centerId: state.pathParameters['centerId']!,
        ),
      ),
      GoRoute(
        path: AppRoutes.adminAnalytics,
        builder: (context, state) => const AdminAnalyticsScreen(),
      ),
      GoRoute(
        path: AppRoutes.profile,
        builder: (context, state) => const ProfileScreen(),
      ),
    ],
  );
});
