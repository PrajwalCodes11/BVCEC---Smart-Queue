import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/constants/supabase_constants.dart';
import '../../core/errors/app_exception.dart';
import '../../domain/queue_state_machine.dart';
import '../models/counter.dart';
import '../models/app_user.dart';

class CounterRepository {
  final SupabaseClient _client;
  CounterRepository(this._client);

  Future<List<Counter>> getCountersForCenter(String serviceCenterId) async {
    try {
      final data = await _client
          .from(SupabaseConstants.countersTable)
          .select('*, users(full_name)')
          .eq('service_center_id', serviceCenterId)
          .order('name');
      return (data as List).map((e) => _parseCounter(e)).toList();
    } catch (e) {
      throw NetworkException('Failed to load counters: $e');
    }
  }

  Stream<List<Counter>> watchCountersForCenter(String serviceCenterId) {
    return _client
        .from(SupabaseConstants.countersTable)
        .stream(primaryKey: ['id'])
        .eq('service_center_id', serviceCenterId)
        .order('name')
        .map((rows) => rows.map((r) => _parseCounter(r)).toList());
  }

  Future<Counter> createCounter({
    required String serviceCenterId,
    required String name,
  }) async {
    try {
      final data = await _client
          .from(SupabaseConstants.countersTable)
          .insert({
            'service_center_id': serviceCenterId,
            'name': name,
            'status': 'offline',
          })
          .select()
          .single();
      return _parseCounter(data);
    } catch (e) {
      throw NetworkException('Failed to create counter: $e');
    }
  }

  Future<void> assignStaff({
    required String counterId,
    required String staffId,
  }) async {
    try {
      await _client
          .from(SupabaseConstants.countersTable)
          .update({
            'assigned_staff_id': staffId,
            'status': 'available',
          })
          .eq('id', counterId);
    } catch (e) {
      throw NetworkException('Failed to assign staff: $e');
    }
  }

  Future<void> updateCounterStatus({
    required String counterId,
    required CounterStatus status,
  }) async {
    try {
      await _client
          .from(SupabaseConstants.countersTable)
          .update({'status': status.name})
          .eq('id', counterId);
    } catch (e) {
      throw NetworkException('Failed to update counter status: $e');
    }
  }

  Future<List<AppUser>> getAllStaff() async {
    try {
      final data = await _client
          .from(SupabaseConstants.usersTable)
          .select()
          .eq('role', 'staff')
          .order('full_name');
      return (data as List).map((e) => AppUser.fromJson(_normalize(e))).toList();
    } catch (e) {
      throw NetworkException('Failed to load staff: $e');
    }
  }

  Future<AppUser> createStaffAccount({
    required String registrationNumber,
    required String fullName,
    required String password,
  }) async {
    // PROTOTYPE ASSUMPTION: Admin creates staff via admin Supabase client.
    // In production, use service_role key server-side. For prototype, use
    // regular signUp and set role via DB trigger or RLS workaround.
    throw const PermissionException(
      'Staff creation requires server-side admin key. Use Supabase dashboard for prototype.',
      code: 'ADMIN_REQUIRED',
    );
  }

  Counter _parseCounter(Map<String, dynamic> data) {
    final normalized = _normalize(data);
    final staffName = (data['users'] as Map<String, dynamic>?)?['full_name'] as String?;
    return Counter(
      id: normalized['id'] as String,
      serviceCenterId: normalized['serviceCenterId'] as String,
      name: normalized['name'] as String,
      status: CounterStatus.fromString(normalized['status'] as String),
      assignedStaffId: normalized['assignedStaffId'] as String?,
      assignedStaffName: staffName,
    );
  }

  Map<String, dynamic> _normalize(Map<String, dynamic> data) {
    final result = <String, dynamic>{};
    data.forEach((key, value) {
      if (key != 'users') result[_toCamel(key)] = value;
    });
    return result;
  }

  String _toCamel(String snake) {
    final parts = snake.split('_');
    if (parts.length == 1) return snake;
    return parts[0] +
        parts.skip(1).map((p) => p[0].toUpperCase() + p.substring(1)).join();
  }
}
