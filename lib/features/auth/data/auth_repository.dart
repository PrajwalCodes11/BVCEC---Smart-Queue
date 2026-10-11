import 'package:supabase_flutter/supabase_flutter.dart' hide AuthException;
import '../../../core/constants/supabase_constants.dart';
import '../../../core/errors/app_exception.dart';
import '../../../data/models/app_user.dart';

class AuthRepository {
  final SupabaseClient _client;

  AuthRepository(this._client);

  /// Returns the currently authenticated AppUser, or null if not logged in.
  Future<AppUser?> getCurrentUser() async {
    final authUser = _client.auth.currentUser;
    if (authUser == null) return null;
    return _fetchUserProfile(authUser.id);
  }

  /// Stream that emits auth state changes.
  Stream<AuthState> get authStateChanges => _client.auth.onAuthStateChange;

  /// Signs in with [registrationNumber] (reg no, staff ID, or direct email)
  /// and [password].
  Future<AppUser> signIn({
    required String registrationNumber,
    required String password,
  }) async {
    try {
      final input = registrationNumber.trim();
      String email = _toEmail(input);

      // Attempt to resolve registered email via RPC if input is a Student ID / Staff ID
      try {
        final resolved = await _client.rpc('get_email_for_identifier', params: {
          'p_identifier': input,
        });
        if (resolved != null && resolved.toString().isNotEmpty) {
          email = resolved.toString();
        }
      } catch (_) {
        // Fall back to _toEmail
      }

      final response = await _client.auth.signInWithPassword(
        email: email,
        password: password,
      );
      if (response.user == null) {
        throw const AuthException('Sign-in failed: no user returned.');
      }
      final profile = await _fetchUserProfile(response.user!.id);
      if (profile == null) {
        throw const AuthException('User profile not found.');
      }
      return profile;
    } on AuthException {
      rethrow;
    } catch (e) {
      final msg = e.toString();
      if (msg.contains('invalid_credentials') || msg.contains('Invalid login credentials')) {
        throw const AuthException(
          'Invalid login credentials. Please verify your Student/Staff ID or Email and password.',
        );
      }
      if (msg.contains('Database error querying schema') || msg.contains('unexpected_failure')) {
        throw const AuthException(
          'User identity setup required in database. Please run the updated supabase_register_rpc.sql in Supabase SQL Editor to complete user identity linking.',
        );
      }
      throw AuthException('Sign-in error: $e');
    }
  }

  /// Registers a new student account with comprehensive academic details.
  Future<AppUser> registerStudent({
    required String registrationNumber,
    required String fullName,
    required String password,
    required String department,
    required String yearOfStudy,
    required String email,
    String? phone,
  }) async {
    try {
      final normalizedEmail = email.trim().toLowerCase();
      final normalizedRegNo = registrationNumber.trim().toUpperCase();

      // Try RPC first for instant account creation if installed in Supabase
      try {
        final rpcRes = await _client.rpc('register_new_user', params: {
          'p_email': normalizedEmail,
          'p_password': password,
          'p_registration_number': normalizedRegNo,
          'p_full_name': fullName.trim(),
          'p_role': 'student',
          'p_department': department,
          'p_year_of_study': yearOfStudy,
          'p_phone': phone?.trim() ?? '',
        });
        if (rpcRes != null) {
          return await signIn(registrationNumber: normalizedEmail, password: password);
        }
      } on PostgrestException catch (pe) {
        if (pe.code != 'PGRST202' && pe.code != '42883') {
          throw AuthException(pe.message);
        }
      } catch (e) {
        if (e is AuthException) rethrow;
      }

      final response = await _client.auth.signUp(
        email: normalizedEmail,
        password: password,
        data: {
          'full_name': fullName.trim(),
          'registration_number': normalizedRegNo,
          'department': department,
          'year_of_study': yearOfStudy,
          'college_email': normalizedEmail,
          'phone': phone?.trim() ?? '',
          'role': 'student',
        },
      );
      if (response.user == null) {
        throw const AuthException('Registration failed: no user returned.');
      }

      // Upsert into public users table if session is active
      try {
        await _client.from(SupabaseConstants.usersTable).upsert({
          'id': response.user!.id,
          'registration_number': normalizedRegNo,
          'full_name': fullName.trim(),
          'role': 'student',
        });
      } catch (_) {
        // If RLS prevents upsert before email confirmation, auth metadata preserves user attributes
      }

      return AppUser(
        id: response.user!.id,
        registrationNumber: normalizedRegNo,
        fullName: fullName.trim(),
        role: UserRole.student,
        createdAt: DateTime.now(),
        department: department,
        yearOfStudy: yearOfStudy,
        email: normalizedEmail,
        phone: phone?.trim(),
      );
    } on AuthException {
      rethrow;
    } catch (e) {
      final msg = e.toString();
      if (msg.contains('over_email_send_rate_limit') || msg.contains('rate limit')) {
        throw const AuthException(
          'Email rate limit reached on Supabase. Please run the supabase_register_rpc.sql script in Supabase SQL Editor to enable unlimited instant registrations, or disable "Confirm email" in Supabase Auth settings.',
        );
      }
      throw AuthException('Registration error: $e');
    }
  }

  /// Registers a new staff account with staff ID, department/section, and role.
  Future<AppUser> registerStaff({
    required String staffId,
    required String fullName,
    required String department,
    required String email,
    String? phone,
    required String password,
  }) async {
    try {
      final normalizedEmail = email.trim().toLowerCase();
      final normalizedStaffId = staffId.trim().toUpperCase();

      // Try RPC first for instant account creation if installed in Supabase
      try {
        final rpcRes = await _client.rpc('register_new_user', params: {
          'p_email': normalizedEmail,
          'p_password': password,
          'p_registration_number': normalizedStaffId,
          'p_full_name': fullName.trim(),
          'p_role': 'staff',
          'p_department': department,
          'p_year_of_study': null,
          'p_phone': phone?.trim() ?? '',
        });
        if (rpcRes != null) {
          return await signIn(registrationNumber: normalizedEmail, password: password);
        }
      } on PostgrestException catch (pe) {
        if (pe.code != 'PGRST202' && pe.code != '42883') {
          throw AuthException(pe.message);
        }
      } catch (e) {
        if (e is AuthException) rethrow;
      }

      final response = await _client.auth.signUp(
        email: normalizedEmail,
        password: password,
        data: {
          'full_name': fullName.trim(),
          'registration_number': normalizedStaffId,
          'department': department,
          'college_email': normalizedEmail,
          'phone': phone?.trim() ?? '',
          'role': 'staff',
        },
      );
      if (response.user == null) {
        throw const AuthException('Staff registration failed: no user returned.');
      }

      // Upsert into public users table with role 'staff'
      try {
        await _client.from(SupabaseConstants.usersTable).upsert({
          'id': response.user!.id,
          'registration_number': normalizedStaffId,
          'full_name': fullName.trim(),
          'role': 'staff',
        });
      } catch (_) {
        // If RLS prevents upsert before email confirmation, auth metadata preserves user attributes
      }

      return AppUser(
        id: response.user!.id,
        registrationNumber: normalizedStaffId,
        fullName: fullName.trim(),
        role: UserRole.staff,
        createdAt: DateTime.now(),
        department: department,
        email: normalizedEmail,
        phone: phone?.trim(),
      );
    } on AuthException {
      rethrow;
    } catch (e) {
      final msg = e.toString();
      if (msg.contains('over_email_send_rate_limit') || msg.contains('rate limit')) {
        throw const AuthException(
          'Email rate limit reached on Supabase. Please run the supabase_register_rpc.sql script in Supabase SQL Editor to enable unlimited instant registrations, or disable "Confirm email" in Supabase Auth settings.',
        );
      }
      throw AuthException('Staff registration error: $e');
    }
  }

  /// Updates profile details (Full name, department, year, phone, email)
  Future<AppUser> updateProfile({
    required String userId,
    required String fullName,
    String? department,
    String? yearOfStudy,
    String? phone,
    String? email,
  }) async {
    try {
      // 1. Attempt to update public.users full_name
      try {
        await _client.from(SupabaseConstants.usersTable).update({
          'full_name': fullName.trim(),
        }).eq('id', userId);
      } catch (_) {
        // Ignored if RLS restricts direct update; metadata holds user attributes
      }

      // 2. Update auth.users metadata
      final updateData = <String, dynamic>{
        'full_name': fullName.trim(),
      };
      if (department != null) updateData['department'] = department;
      if (yearOfStudy != null) updateData['year_of_study'] = yearOfStudy;
      if (phone != null) updateData['phone'] = phone.trim();
      if (email != null) updateData['college_email'] = email.trim().toLowerCase();

      await _client.auth.updateUser(UserAttributes(data: updateData));

      final refreshed = await _fetchUserProfile(userId);
      if (refreshed == null) {
        throw const AuthException('Could not retrieve updated profile.');
      }
      return refreshed;
    } catch (e) {
      throw AuthException('Failed to update profile: $e');
    }
  }

  Future<void> signOut() async {
    await _client.auth.signOut();
  }

  /// Fetches a user profile by user ID.
  Future<AppUser?> getUserById(String userId) async {
    return _fetchUserProfile(userId);
  }

  Future<AppUser?> _fetchUserProfile(String userId) async {
    try {
      final data = await _client
          .from(SupabaseConstants.usersTable)
          .select()
          .eq('id', userId)
          .maybeSingle();
      if (data == null) {
        return null;
      }

      final authUser = _client.auth.currentUser;
      Map<String, dynamic>? meta;
      if (authUser != null && authUser.id == userId) {
        meta = authUser.userMetadata;
      }

      return _normalizeUser(data, meta, authUser?.email);
    } catch (e, st) {
      // ignore: avoid_print
      print('DEBUG: _fetchUserProfile error: $e\n$st');
      throw AuthException('Profile database query failed: $e');
    }
  }

  /// Converts input identifier to email format for Supabase auth.
  static String _toEmail(String identifier) {
    final trimmed = identifier.toLowerCase().trim();
    if (trimmed.contains('@')) return trimmed;
    return '$trimmed@bvcec.internal';
  }

  static AppUser _normalizeUser(
    Map<String, dynamic> data,
    Map<String, dynamic>? meta,
    String? authEmail,
  ) {
    final roleStr = data['role'] ?? meta?['role'] ?? 'student';
    final role = switch (roleStr) {
      'admin' => UserRole.admin,
      'staff' => UserRole.staff,
      _ => UserRole.student,
    };

    final regNo = data['registration_number'] ??
        data['registrationNumber'] ??
        meta?['registration_number'] ??
        meta?['staff_id'] ??
        '';

    final name = meta?['full_name'] ??
        data['full_name'] ??
        data['fullName'] ??
        '';

    final createdAt = data['created_at'] != null
        ? DateTime.parse(data['created_at'] as String)
        : DateTime.now();

    final department = (meta?['department'] as String?)?.isNotEmpty == true
        ? meta!['department'] as String
        : null;

    final yearOfStudy = (meta?['year_of_study'] as String?)?.isNotEmpty == true
        ? meta!['year_of_study'] as String
        : null;

    final collegeEmail = (meta?['college_email'] as String?)?.isNotEmpty == true
        ? meta!['college_email'] as String
        : authEmail;

    final phone = (meta?['phone'] as String?)?.isNotEmpty == true
        ? meta!['phone'] as String
        : null;

    return AppUser(
      id: data['id'] as String,
      registrationNumber: regNo as String,
      fullName: name as String,
      role: role,
      createdAt: createdAt,
      department: department,
      yearOfStudy: yearOfStudy,
      email: collegeEmail,
      phone: phone,
    );
  }
}
