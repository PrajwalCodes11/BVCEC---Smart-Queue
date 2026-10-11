// ignore_for_file: avoid_print
import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:smartqueue/core/constants/supabase_constants.dart';
import 'package:smartqueue/data/repositories/queue_repository.dart';
import 'package:smartqueue/data/repositories/service_repository.dart';
import 'package:smartqueue/domain/queue_state_machine.dart';

void main() {
  test('Complete Staff & Admin & Student Service Discovery Workflow Test', () async {
    // 1. Student Client & Authentication
    final studentClient = SupabaseClient(
      SupabaseConstants.supabaseUrl,
      SupabaseConstants.supabaseAnonKey,
    );
    final studentAuth = await studentClient.auth.signInWithPassword(
      email: '22a61a0501@bvcec.internal',
      password: 'password123',
    );
    final studentId = studentAuth.user!.id;
    final studentServiceRepo = ServiceRepository(studentClient);
    final studentQueueRepo = QueueRepository(studentClient);

    // 2. Staff Client & Authentication
    final staffClient = SupabaseClient(
      SupabaseConstants.supabaseUrl,
      SupabaseConstants.supabaseAnonKey,
    );
    final staffAuth = await staffClient.auth.signInWithPassword(
      email: 'staff001@bvcec.internal',
      password: 'password123',
    );
    final staffId = staffAuth.user!.id;
    final staffQueueRepo = QueueRepository(staffClient);

    // 3. Verify student can discover all active campus services (including CSE ALLIED)
    final allActiveServices = await studentServiceRepo.getAllActiveServices();
    print('Discovered ${allActiveServices.length} active campus services:');
    for (final s in allActiveServices) {
      print(' - ${s.name} (centerId: ${s.serviceCenterId})');
    }

    final cseService = allActiveServices.firstWhere(
      (s) => s.name.toUpperCase().contains('CSE'),
      orElse: () => throw Exception('CSE ALLIED service not found!'),
    );
    expect(cseService.name, contains('CSE'));
    print('Verified: Student can discover "${cseService.name}"!');

    // Clean any preexisting active entries for student
    final initialActive = await studentQueueRepo.getActiveEntriesForUser(studentId);
    for (final e in initialActive) {
      await studentQueueRepo.cancelEntry(
        entryId: e.id,
        currentStatus: e.status.toDbString(),
        actorId: studentId,
      );
    }

    // 4. Obtain queue for CSE ALLIED
    final queue = await studentQueueRepo.getOrCreateTodayQueue(
      serviceCenterId: cseService.serviceCenterId,
      serviceId: cseService.id,
    );
    expect(queue.id, isNotEmpty);

    // 5. Student joins queue
    final entry1 = await studentQueueRepo.joinQueue(
      queueId: queue.id,
      userId: studentId,
      serviceId: cseService.id,
      estimatedWaitMinutes: 10,
    );
    expect(entry1.status, equals(QueueEntryStatus.waiting));
    print('Student joined queue for CSE ALLIED, Token #${entry1.tokenNumber}');

    // 6. Staff calls next student
    final allCounters = await staffClient.from('counters').select();
    final String counterId;
    if ((allCounters as List).isNotEmpty) {
      counterId = allCounters.first['id'] as String;
    } else {
      final newCounter = await staffClient.from('counters').insert({
        'service_center_id': cseService.serviceCenterId,
        'name': 'Counter 1',
        'status': 'available',
      }).select().single();
      counterId = newCounter['id'] as String;
    }

    await staffQueueRepo.callNext(
      entryId: entry1.id,
      counterId: counterId,
      staffId: staffId,
    );
    print('Staff called Token #${entry1.tokenNumber}');

    // Verify status is called
    final entry1Called = await studentQueueRepo.watchEntry(entry1.id).first;
    expect(entry1Called?.status, equals(QueueEntryStatus.called));

    // 7. Staff starts service
    final session = await staffQueueRepo.startService(
      entryId: entry1.id,
      counterId: counterId,
      staffId: staffId,
      serviceId: cseService.id,
    );
    expect(session.queueEntryId, equals(entry1.id));
    print('Staff started service for Token #${entry1.tokenNumber}');

    // Verify status is serving
    final entry1Serving = await studentQueueRepo.watchEntry(entry1.id).first;
    expect(entry1Serving?.status, equals(QueueEntryStatus.serving));

    // 8. Verify watchWaitingEntries now INCLUDES serving entries!
    final waitingStreamEntries = await staffQueueRepo.watchWaitingEntries(queue.id).first;
    final servingFound = waitingStreamEntries.any((e) => e.id == entry1.id && e.status == QueueEntryStatus.serving);
    expect(servingFound, isTrue, reason: 'Serving entry must be visible in watchWaitingEntries for staff!');
    print('Verified: Serving entry remains visible in watchWaitingEntries for staff dashboard!');

    // 9. Staff completes service
    await staffQueueRepo.completeService(
      entryId: entry1.id,
      sessionId: session.id,
      serviceId: cseService.id,
      staffId: staffId,
      startedAt: DateTime.now().subtract(const Duration(minutes: 5)),
    );
    print('Staff completed service for Token #${entry1.tokenNumber}');

    final entry1Completed = await studentQueueRepo.watchEntry(entry1.id).first;
    expect(entry1Completed?.status, equals(QueueEntryStatus.completed));

    // 10. Test "Complete & Call Next" rapid flow!
    final entry2 = await studentQueueRepo.joinQueue(
      queueId: queue.id,
      userId: studentId,
      serviceId: cseService.id,
      estimatedWaitMinutes: 10,
    );
    final entry3 = await studentQueueRepo.joinQueue(
      queueId: queue.id,
      userId: studentId,
      serviceId: cseService.id,
      estimatedWaitMinutes: 20,
    );

    // Call and start ticket 2
    await staffQueueRepo.callNext(entryId: entry2.id, counterId: counterId, staffId: staffId);
    await staffQueueRepo.startService(
      entryId: entry2.id,
      counterId: counterId,
      staffId: staffId,
      serviceId: cseService.id,
    );

    print('Testing completeAndCallNext (Ticket #${entry2.tokenNumber} -> Ticket #${entry3.tokenNumber})...');
    await staffQueueRepo.completeAndCallNext(
      currentEntryId: entry2.id,
      serviceId: cseService.id,
      staffId: staffId,
      nextEntryId: entry3.id,
      counterId: counterId,
    );

    final entry2Check = await studentQueueRepo.watchEntry(entry2.id).first;
    final entry3Check = await studentQueueRepo.watchEntry(entry3.id).first;

    expect(entry2Check?.status, equals(QueueEntryStatus.completed));
    expect(entry3Check?.status, equals(QueueEntryStatus.called));
    print('Verified: Ticket #${entry2.tokenNumber} completed AND Ticket #${entry3.tokenNumber} called in 1-tap!');

    // Complete ticket 3 to leave 100% clean state
    await staffQueueRepo.completeService(
      entryId: entry3.id,
      serviceId: cseService.id,
      staffId: staffId,
    );

    // 11. Final verification: 0 active entries remain for student
    final finalActive = await studentQueueRepo.getActiveEntriesForUser(studentId);
    expect(finalActive.length, equals(0));
    print('All tests passed! Database returned to 100% clean state.');
  });
}
