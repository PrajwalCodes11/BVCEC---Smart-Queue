// ignore_for_file: avoid_print
import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:smartqueue/core/constants/supabase_constants.dart';
import 'package:smartqueue/data/repositories/queue_repository.dart';

void main() {
  test('Live Real Ticket Creation and Cancellation Verification', () async {
    final client = SupabaseClient(
      SupabaseConstants.supabaseUrl,
      SupabaseConstants.supabaseAnonKey,
    );

    // 1. Sign in as student
    final authRes = await client.auth.signInWithPassword(
      email: '22a61a0501@bvcec.internal',
      password: 'password123',
    );
    final studentId = authRes.user!.id;
    final queueRepo = QueueRepository(client);

    final initialActive = await queueRepo.getActiveEntriesForUser(studentId);
    for (final e in initialActive) {
      await queueRepo.cancelEntry(
        entryId: e.id,
        currentStatus: e.status.toDbString(),
        actorId: studentId,
      );
    }
    final cleanCheck = await queueRepo.getActiveEntriesForUser(studentId);
    expect(cleanCheck.length, equals(0));

    // 2. Query all service centers and all services
    final allCenters = await client.from('service_centers').select();
    print('=== ALL SERVICE CENTERS in DB (${(allCenters as List).length}) ===');
    for (final c in allCenters) {
      print(' Center: ${c['name']} (ID: ${c['id']}, is_active: ${c['is_active']})');
    }

    final allServices = await client.from('services').select('*, service_centers(name)');
    print('=== ALL SERVICES in DB (${(allServices as List).length}) ===');
    for (final s in allServices) {
      final centerName = s['service_centers'] != null ? s['service_centers']['name'] : 'Unknown Center';
      print(' Service: ${s['name']} -> Center: $centerName (is_active: ${s['is_active']}, ID: ${s['id']})');
    }

    final services = await client.from('services').select().eq('name', 'Hall Ticket Collection').single();
    final serviceId = services['id'] as String;
    final centerId = services['service_center_id'] as String;

    // 3. Obtain queue
    final queue = await queueRepo.getOrCreateTodayQueue(
      serviceCenterId: centerId,
      serviceId: serviceId,
    );

    // 4. Student joins queue
    final entry = await queueRepo.joinQueue(
      queueId: queue.id,
      userId: studentId,
      serviceId: serviceId,
      estimatedWaitMinutes: 5,
    );
    print('Created real ticket #${entry.tokenNumber} (ID: ${entry.id})');

    // Verify 1 active entry
    final activeNow = await queueRepo.getActiveEntriesForUser(studentId);
    expect(activeNow.length, equals(1));
    expect(activeNow.first.id, equals(entry.id));

    // 5. Test cancelling ticket
    print('Testing cancelEntry on ticket #${entry.tokenNumber}...');
    await queueRepo.cancelEntry(
      entryId: entry.id,
      currentStatus: entry.status.toDbString(),
      actorId: studentId,
    );
    print('Cancel completed successfully!');

    // 6. Verify 0 active entries remaining
    final activeAfterCancel = await queueRepo.getActiveEntriesForUser(studentId);
    expect(activeAfterCancel.length, equals(0));
    print('Verified: 0 active entries remain. Clean state restored!');
  });
}
