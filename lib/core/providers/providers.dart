import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../data/models/app_user.dart';
import '../../data/repositories/service_repository.dart';
import '../../data/repositories/queue_repository.dart';
import '../../data/repositories/counter_repository.dart';
import '../../features/auth/data/auth_repository.dart';
import '../theme/app_theme.dart';

// ─── Supabase Client ──────────────────────────────────────────────────────

final supabaseClientProvider = Provider<SupabaseClient>((ref) {
  return Supabase.instance.client;
});

// ─── Repositories ────────────────────────────────────────────────────────

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository(ref.watch(supabaseClientProvider));
});

final serviceRepositoryProvider = Provider<ServiceRepository>((ref) {
  return ServiceRepository(ref.watch(supabaseClientProvider));
});

final queueRepositoryProvider = Provider<QueueRepository>((ref) {
  return QueueRepository(ref.watch(supabaseClientProvider));
});

final counterRepositoryProvider = Provider<CounterRepository>((ref) {
  return CounterRepository(ref.watch(supabaseClientProvider));
});

// ─── Auth State ───────────────────────────────────────────────────────────

class AuthNotifier extends StateNotifier<AsyncValue<AppUser?>> {
  final AuthRepository _repo;
  StreamSubscription<AuthState>? _sub;

  AuthNotifier(this._repo) : super(const AsyncLoading()) {
    _init();
  }

  Future<void> _init() async {
    try {
      final user = await _repo.getCurrentUser();
      if (mounted) state = AsyncData(user);
    } catch (_) {
      if (mounted) state = const AsyncData(null);
    }

    _sub = _repo.authStateChanges.listen((data) async {
      if (data.session != null) {
        try {
          final user = await _repo.getCurrentUser();
          if (mounted) state = AsyncData(user);
        } catch (_) {
          // Keep current state
        }
      } else {
        if (mounted) state = const AsyncData(null);
      }
    });
  }

  /// Sets user immediately upon successful login/registration
  void setUser(AppUser user) {
    state = AsyncData(user);
  }

  /// Clears user immediately upon logout
  void clearUser() {
    state = const AsyncData(null);
  }

  /// Refreshes user profile from DB
  Future<void> refresh() async {
    try {
      final user = await _repo.getCurrentUser();
      if (mounted) state = AsyncData(user);
    } catch (_) {}
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }
}

final authNotifierProvider =
    StateNotifierProvider<AuthNotifier, AsyncValue<AppUser?>>((ref) {
  final repo = ref.watch(authRepositoryProvider);
  return AuthNotifier(repo);
});

/// Watches Supabase auth state and provides the current AppUser.
final authStateProvider = Provider<AsyncValue<AppUser?>>((ref) {
  return ref.watch(authNotifierProvider);
});

/// Convenience provider: returns current user or safe fallback during logout/transitions.
final currentUserProvider = Provider<AppUser>((ref) {
  final asyncUser = ref.watch(authStateProvider);
  return asyncUser.value ??
      AppUser(
        id: '',
        registrationNumber: '',
        fullName: 'User',
        role: UserRole.student,
        createdAt: DateTime.fromMillisecondsSinceEpoch(0),
      );
});

/// Dynamic theme mode provider (dark vs creamy white)
final appThemeModeProvider = StateProvider<AppThemeMode>((ref) {
  return AppThemeMode.dark;
});

