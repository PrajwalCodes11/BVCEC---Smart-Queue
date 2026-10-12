// ignore_for_file: avoid_print
import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:smartqueue/core/constants/supabase_constants.dart';
import 'package:smartqueue/data/models/app_user.dart';

void main() {
  test('Live Supabase Auth & Profile Query Diagnostic', () async {
    final client = SupabaseClient(
      SupabaseConstants.supabaseUrl,
      SupabaseConstants.supabaseAnonKey,
    );

    print('--> 1. Querying public.users as anonymous user...');
    try {
      final rows = await client.from('users').select();
      print('public.users row count: ${(rows as List).length}');
      for (final r in rows) {
        print('  User: $r');
      }
    } catch (e) {
      print('public.users anon query error: $e');
    }

    print('\n--> 2. Testing signInWithPassword for student (22a61a0501@bvcec.internal)...');
    try {
      final res = await client.auth.signInWithPassword(
        email: '22a61a0501@bvcec.internal',
        password: 'password123',
      );
      print('Auth Success! auth.users ID: ${res.user?.id}');

      final profileRow = await client
          .from('users')
          .select()
          .eq('id', res.user!.id)
          .maybeSingle();

      print('profileRow from public.users: $profileRow');

      if (profileRow != null) {
        final normalized = {
          'id': profileRow['id'],
          'registrationNumber': profileRow['registration_number'] ?? '',
          'fullName': profileRow['full_name'] ?? '',
          'role': profileRow['role'] ?? 'student',
          'createdAt': profileRow['created_at'] ?? DateTime.now().toIso8601String(),
        };
        final user = AppUser.fromJson(normalized);
        print('Parsed AppUser: $user');
        expect(user.registrationNumber, equals('22A61A0501'));
      } else {
        print('FAILURE: No profileRow found in public.users for auth.users id ${res.user!.id}!');
      }
    } catch (e) {
      print('Student signIn error: $e');
    }

    print('\n--> 3. Admin initializing today\'s queues for all services...');
    try {
      await client.auth.signInWithPassword(
        email: 'admin001@bvcec.internal',
        password: 'password123',
      );
      final allUsers = await client.from('users').select();
      print('=== ALL USERS IN DB ===');
      for (final u in allUsers) {
        print('  ID: ${u['id']} | Email: ${u['email']} | Reg: ${u['registration_number']} | Role: ${u['role']} | Name: ${u['full_name']}');
      }

      // Check if 22A61A0501 exists; if not, register it!
      final hasStudent = allUsers.any((u) => u['registration_number'] == '22A61A0501');
      if (!hasStudent) {
        print('Registering test student 22A61A0501...');
        try {
          final res = await client.rpc('register_new_user', params: {
            'p_email': '22a61a0501@bvcec.internal',
            'p_password': 'password123',
            'p_registration_number': '22A61A0501',
            'p_full_name': 'Prajwal Varma',
            'p_role': 'student',
            'p_department': 'Computer Science & Engineering (CSE)',
            'p_year_of_study': '3rd Year',
            'p_phone': '9876543210',
          });
          print('Registered student 22A61A0501: $res');
        } catch (e) {
          print('Failed to register student 22A61A0501: $e');
        }
      }

      // Check if STAFF001 exists; if not, register it!
      final hasStaff = allUsers.any((u) => u['registration_number'] == 'STAFF001');
      if (!hasStaff) {
        print('Registering test staff STAFF001...');
        try {
          final res = await client.rpc('register_new_user', params: {
            'p_email': 'staff001@bvcec.internal',
            'p_password': 'password123',
            'p_registration_number': 'STAFF001',
            'p_full_name': 'Exam Section Staff',
            'p_role': 'staff',
            'p_department': 'Examination Section',
            'p_year_of_study': null,
            'p_phone': '9123456780',
          });
          print('Registered staff STAFF001: $res');
        } catch (e) {
          print('Failed to register staff STAFF001: $e');
        }
      }
      final today = DateTime.now();
      final dateStr =
          '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';

      final services = await client.from('services').select();
      print('Found ${(services as List).length} services.');

      for (final service in services) {
        final serviceId = service['id'] as String;
        final centerId = service['service_center_id'] as String;
        final serviceName = service['name'] as String;

        final existing = await client
            .from('queues')
            .select()
            .eq('service_id', serviceId)
            .eq('date', dateStr)
            .maybeSingle();

        if (existing == null) {
          print('Creating queue for $serviceName...');
          await client.from('queues').insert({
            'service_center_id': centerId,
            'service_id': serviceId,
            'date': dateStr,
            'is_open': true,
          });
          print('Created queue for $serviceName.');
        } else {
          print('Queue already exists for $serviceName (${existing['id']})');
        }
      }

      print('\n--> 4. Testing Student Joining Queue on all services...');
      // Sign in as admin to clean up test entries
      print('Logging in as admin to clean up dummy entries...');
      await client.auth.signInWithPassword(
        email: 'admin001@bvcec.internal',
        password: 'password123',
      );
      
      try {
        final eventsDel = await client.from('queue_events').delete().neq('id', '00000000-0000-0000-0000-000000000000');
        print('Deleted queue_events: $eventsDel');
      } catch (e) {
        print('Could not delete queue_events: $e');
      }

      try {
        final updateRes = await client
            .from('queue_entries')
            .update({'status': 'cancelled'})
            .neq('status', 'cancelled')
            .select();
        print('Admin cancelled ${(updateRes as List).length} dummy entries!');
      } catch (e) {
        print('Could not update queue_entries: $e');
      }

      // Check count of active entries remaining for student
      final active = await client
          .from('queue_entries')
          .select('id, status')
          .inFilter('status', ['waiting', 'called', 'serving']);
      print('Remaining ACTIVE entries in DB: ${(active as List).length}');
    } catch (e, stack) {
      print('Queue operation FAILED with error: $e\n$stack');
    }
  });
}
