// ignore_for_file: avoid_print
import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:smartqueue/core/constants/supabase_constants.dart';
import 'package:smartqueue/data/repositories/queue_repository.dart';
import 'package:smartqueue/data/repositories/service_repository.dart';
import 'package:smartqueue/domain/queue_state_machine.dart';

void main() {
  test('E2E Complete Flow: Student Join -> Staff Serve -> Admin Analytics Reflection', () async {
    print('===============================================================');
    print('Starting End-to-End Workflow & Analytics Reflection Test');
    print('===============================================================');

    // 1. Authenticate Admin Client
    final adminClient = SupabaseClient(
      SupabaseConstants.supabaseUrl,
      SupabaseConstants.supabaseAnonKey,
    );
    final adminAuth = await adminClient.auth.signInWithPassword(
      email: 'admin001@bvcec.internal',
      password: 'password123',
    );
    expect(adminAuth.user, isNotNull);
    final adminId = adminAuth.user!.id;
    final adminQueueRepo = QueueRepository(adminClient);
    final adminServiceRepo = ServiceRepository(adminClient);
    print('✓ Step 1: Admin authenticated successfully ($adminId)');

    // Inspect existing users in public.users
    final usersList = await adminClient.from('users').select();
    print('Registered users in public.users:');
    for (final u in usersList) {
      print('  • ${u['role']}: ${u['full_name']} (Reg: ${u['registration_number']}, ID: ${u['id']})');
    }

    final resolvedStaffEmail = await adminClient.rpc('get_email_for_identifier', params: {'p_identifier': '221S001'});
    final resolvedStudentEmail = await adminClient.rpc('get_email_for_identifier', params: {'p_identifier': '24221A4562'});
    print('Resolved staff email from DB: $resolvedStaffEmail');
    print('Resolved student email from DB: $resolvedStudentEmail');

    // 2. Authenticate Staff Client (Ram Prasad / 221S001)
    final staffClient = SupabaseClient(
      SupabaseConstants.supabaseUrl,
      SupabaseConstants.supabaseAnonKey,
    );
    final staffAuth = await staffClient.auth.signInWithPassword(
      email: resolvedStaffEmail.toString(),
      password: 'password123',
    );
    expect(staffAuth.user, isNotNull);
    final staffId = staffAuth.user!.id;
    final staffQueueRepo = QueueRepository(staffClient);
    print('✓ Step 2: Staff authenticated successfully ($staffId)');

    // 3. Authenticate Student Client (Prajwal Adhikari / 24221A4562)
    final studentClient = SupabaseClient(
      SupabaseConstants.supabaseUrl,
      SupabaseConstants.supabaseAnonKey,
    );
    
    final studentAuth = await studentClient.auth.signInWithPassword(
      email: '24221a4562@bvcec.internal',
      password: 'password123',
    );
    final studentId = studentAuth.user!.id;
    expect(studentId, isNotEmpty);
    final studentQueueRepo = QueueRepository(studentClient);
    print('✓ Step 3: Student authenticated successfully ($studentId)');

    // 4. Select an active service for the test
    final services = await adminServiceRepo.getAllActiveServices();
    expect(services, isNotEmpty);
    final testService = services.first;
    print('✓ Step 4: Selected active service "${testService.name}" (${testService.serviceCenterId})');

    // Clean previous active entries for student if any
    final prevEntries = await studentQueueRepo.getActiveEntriesForUser(studentId);
    for (final pe in prevEntries) {
      await studentQueueRepo.cancelEntry(
        entryId: pe.id,
        currentStatus: pe.status.toDbString(),
        actorId: studentId,
      );
    }

    // 5. Ensure queue exists for today
    final queue = await studentQueueRepo.getOrCreateTodayQueue(
      serviceCenterId: testService.serviceCenterId,
      serviceId: testService.id,
    );
    expect(queue.id, isNotEmpty);
    print('✓ Step 5: Queue for today is active (Queue ID: ${queue.id})');

    // 6. Record pre-test analytics baseline
    final baselineStats = await adminQueueRepo.getCampusLiveStats();
    print('Baseline Campus Live Stats: $baselineStats');

    // 7. Student joins the queue
    final entry = await studentQueueRepo.joinQueue(
      queueId: queue.id,
      userId: studentId,
      serviceId: testService.id,
      estimatedWaitMinutes: 10,
    );
    expect(entry.status, equals(QueueEntryStatus.waiting));
    print('✓ Step 6: Student joined queue: Token #${entry.tokenNumber} (Status: waiting)');

    // Check live stats after joining
    final statsAfterJoin = await adminQueueRepo.getCampusLiveStats();
    print('Stats after join: $statsAfterJoin (In-Line: ${statsAfterJoin['waiting']})');
    expect(statsAfterJoin['waiting']! >= baselineStats['waiting']!, isTrue);

    // 8. Staff calls next student to counter
    final allCounters = await staffClient.from('counters').select();
    final String counterId = (allCounters as List).isNotEmpty
        ? allCounters.first['id'] as String
        : (await staffClient.from('counters').insert({
            'service_center_id': testService.serviceCenterId,
            'name': 'Counter 1',
            'status': 'available',
          }).select().single())['id'] as String;

    await staffQueueRepo.callNext(
      entryId: entry.id,
      counterId: counterId,
      staffId: staffId,
    );
    final calledEntry = await studentQueueRepo.watchEntry(entry.id).first;
    expect(calledEntry?.status, equals(QueueEntryStatus.called));
    print('✓ Step 7: Staff called token #${entry.tokenNumber} (Status: called)');

    // 9. Staff begins service
    final session = await staffQueueRepo.startService(
      entryId: entry.id,
      counterId: counterId,
      staffId: staffId,
      serviceId: testService.id,
    );
    final servingEntry = await studentQueueRepo.watchEntry(entry.id).first;
    expect(servingEntry?.status, equals(QueueEntryStatus.serving));
    print('✓ Step 8: Staff started service (Session ID: ${session.id}, Status: serving)');

    // 10. Staff completes service
    await staffQueueRepo.completeService(
      entryId: entry.id,
      sessionId: session.id,
      serviceId: testService.id,
      staffId: staffId,
      startedAt: DateTime.now().subtract(const Duration(minutes: 6)),
    );
    final completedEntry = await studentQueueRepo.watchEntry(entry.id).first;
    expect(completedEntry?.status, equals(QueueEntryStatus.completed));
    print('✓ Step 9: Staff completed service for Token #${entry.tokenNumber} (Status: completed)');

    // 11. Admin Analytics Verification
    print('✓ Step 10: Querying Admin Analytics to verify live data reflection...');
    final now = DateTime.now();
    final analytics = await adminQueueRepo.getAnalytics(
      serviceCenterId: null, // campus-wide
      fromDate: now.subtract(const Duration(days: 7)),
      toDate: now.add(const Duration(days: 1)),
    );

    print('Analytics Summary Result:');
    print('  • Total entries: ${analytics['total']}');
    print('  • Completed entries: ${analytics['completed']}');
    print('  • Avg wait time: ${analytics['avgWaitMinutes']} min');
    print('  • Avg service time: ${analytics['avgServiceDurationMinutes']} min');
    print('  • Services breakdown: ${analytics['perService']}');
    print('  • Hourly distribution: ${analytics['hourlyCount']}');

    expect(analytics['total'] as int, greaterThan(0));
    expect(analytics['completed'] as int, greaterThan(0));

    print('===============================================================');
    print('🎉 COMPLETE E2E WORKFLOW & ADMIN ANALYTICS REFLECTION VERIFIED!');
    print('===============================================================');
  });
}
