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

/// Watches Supabase auth state and provides the current AppUser.
final authStateProvider = StreamProvider<AppUser?>((ref) async* {
  final repo = ref.watch(authRepositoryProvider);
  // Emit current user immediately
  yield await repo.getCurrentUser();
  // Then stream subsequent auth changes
  await for (final state in repo.authStateChanges) {
    if (state.session != null) {
      yield await repo.getCurrentUser();
    } else {
      yield null;
    }
  }
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

