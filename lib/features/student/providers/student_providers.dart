import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers/providers.dart';
import '../../../data/models/queue_entry.dart';

/// Provides active queue entries (waiting, called, serving) for the logged in student
final studentActiveEntriesProvider = FutureProvider<List<QueueEntry>>((ref) async {
  final user = ref.watch(currentUserProvider);
  if (user.id.isEmpty) return [];
  return ref.watch(queueRepositoryProvider).getActiveEntriesForUser(user.id);
});

/// Real-time stream of student's active queue entries
final studentActiveEntriesStreamProvider = StreamProvider<List<QueueEntry>>((ref) {
  final user = ref.watch(currentUserProvider);
  if (user.id.isEmpty) return const Stream.empty();
  return ref.watch(queueRepositoryProvider).watchStudentActiveEntries(user.id);
});
