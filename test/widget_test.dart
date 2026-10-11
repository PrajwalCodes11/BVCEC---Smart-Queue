import 'package:flutter_test/flutter_test.dart';
import 'package:smartqueue/domain/queue_state_machine.dart';
import 'package:smartqueue/core/errors/app_exception.dart';
import 'package:smartqueue/core/utils/ewt_calculator.dart';

void main() {
  group('QueueStateMachine', () {
    group('valid transitions', () {
      test('WAITING → CANCELLED is valid', () {
        expect(
          QueueStateMachine.canTransition(
              QueueEntryStatus.waiting, QueueEntryStatus.cancelled),
          isTrue,
        );
      });

      test('WAITING → CALLED is valid', () {
        expect(
          QueueStateMachine.canTransition(
              QueueEntryStatus.waiting, QueueEntryStatus.called),
          isTrue,
        );
      });

      test('CALLED → SERVING is valid', () {
        expect(
          QueueStateMachine.canTransition(
              QueueEntryStatus.called, QueueEntryStatus.serving),
          isTrue,
        );
      });

      test('CALLED → NO_SHOW is valid', () {
        expect(
          QueueStateMachine.canTransition(
              QueueEntryStatus.called, QueueEntryStatus.noShow),
          isTrue,
        );
      });

      test('SERVING → COMPLETED is valid', () {
        expect(
          QueueStateMachine.canTransition(
              QueueEntryStatus.serving, QueueEntryStatus.completed),
          isTrue,
        );
      });

      test('SERVING → TRANSFERRED is valid', () {
        expect(
          QueueStateMachine.canTransition(
              QueueEntryStatus.serving, QueueEntryStatus.transferred),
          isTrue,
        );
      });
    });

    group('invalid transitions', () {
      test('WAITING → SERVING is invalid', () {
        expect(
          QueueStateMachine.canTransition(
              QueueEntryStatus.waiting, QueueEntryStatus.serving),
          isFalse,
        );
      });

      test('WAITING → COMPLETED is invalid', () {
        expect(
          QueueStateMachine.canTransition(
              QueueEntryStatus.waiting, QueueEntryStatus.completed),
          isFalse,
        );
      });

      test('COMPLETED → any is invalid (terminal state)', () {
        for (final next in QueueEntryStatus.values) {
          expect(
            QueueStateMachine.canTransition(QueueEntryStatus.completed, next),
            isFalse,
            reason: 'COMPLETED → ${next.name} should be invalid',
          );
        }
      });

      test('CANCELLED → any is invalid (terminal state)', () {
        for (final next in QueueEntryStatus.values) {
          expect(
            QueueStateMachine.canTransition(QueueEntryStatus.cancelled, next),
            isFalse,
          );
        }
      });

      test('CALLED → WAITING is invalid (no rollback)', () {
        expect(
          QueueStateMachine.canTransition(
              QueueEntryStatus.called, QueueEntryStatus.waiting),
          isFalse,
        );
      });
    });

    group('validateTransition', () {
      test('throws InvalidStateTransitionException for invalid transition', () {
        expect(
          () => QueueStateMachine.validateTransition(
              QueueEntryStatus.waiting, QueueEntryStatus.completed),
          throwsA(isA<InvalidStateTransitionException>()),
        );
      });

      test('does not throw for valid transition', () {
        expect(
          () => QueueStateMachine.validateTransition(
              QueueEntryStatus.waiting, QueueEntryStatus.called),
          returnsNormally,
        );
      });
    });

    group('validNextStates', () {
      test('WAITING has exactly 2 valid next states', () {
        final states = QueueStateMachine.validNextStates(QueueEntryStatus.waiting);
        expect(states.length, equals(2));
        expect(states, contains(QueueEntryStatus.cancelled));
        expect(states, contains(QueueEntryStatus.called));
      });

      test('COMPLETED has no valid next states', () {
        final states =
            QueueStateMachine.validNextStates(QueueEntryStatus.completed);
        expect(states, isEmpty);
      });
    });
  });

  group('EwtCalculator', () {
    group('estimateWaitMinutes', () {
      test('returns 0 for position 1 (next to serve)', () {
        final ewt = EwtCalculator.estimateWaitMinutes(
          positionInQueue: 1,
          activeCounters: 1,
          avgServiceDurationMinutes: 10.0,
        );
        expect(ewt, equals(0));
      });

      test('returns -1 when no active counters', () {
        final ewt = EwtCalculator.estimateWaitMinutes(
          positionInQueue: 5,
          activeCounters: 0,
          avgServiceDurationMinutes: 10.0,
        );
        expect(ewt, equals(-1));
      });

      test('estimates correctly for position 3, 1 counter, 10 min avg', () {
        // 2 people ahead / 1 counter × 10 min = 20 min
        final ewt = EwtCalculator.estimateWaitMinutes(
          positionInQueue: 3,
          activeCounters: 1,
          avgServiceDurationMinutes: 10.0,
        );
        expect(ewt, equals(20));
      });

      test('halves wait time with 2 active counters', () {
        final singleCounter = EwtCalculator.estimateWaitMinutes(
          positionInQueue: 5,
          activeCounters: 1,
          avgServiceDurationMinutes: 10.0,
        );
        final twoCounters = EwtCalculator.estimateWaitMinutes(
          positionInQueue: 5,
          activeCounters: 2,
          avgServiceDurationMinutes: 10.0,
        );
        expect(twoCounters, lessThan(singleCounter));
      });
    });

    group('updateAverage (exponential smoothing)', () {
      test('blends new and old observation', () {
        final newAvg = EwtCalculator.updateAverage(
          previousAverage: 10.0,
          actualDurationMinutes: 20.0,
        );
        // α=0.3: 0.3×20 + 0.7×10 = 6 + 7 = 13.0
        expect(newAvg, closeTo(13.0, 0.001));
      });

      test('converges toward actual duration over many samples', () {
        double avg = 10.0;
        for (int i = 0; i < 50; i++) {
          avg = EwtCalculator.updateAverage(
            previousAverage: avg,
            actualDurationMinutes: 20.0,
          );
        }
        expect(avg, closeTo(20.0, 0.5));
      });

      test('does not change if actual equals average', () {
        final newAvg = EwtCalculator.updateAverage(
          previousAverage: 10.0,
          actualDurationMinutes: 10.0,
        );
        expect(newAvg, closeTo(10.0, 0.001));
      });
    });

    group('formatWait', () {
      test('formats 0 minutes', () {
        expect(EwtCalculator.formatWait(0), equals('Your turn soon'));
      });

      test('formats negative as Unknown', () {
        expect(EwtCalculator.formatWait(-1), equals('Unknown'));
      });

      test('formats minutes under 60', () {
        expect(EwtCalculator.formatWait(30), equals('30 min'));
      });

      test('formats exactly 60 minutes as 1 hr', () {
        expect(EwtCalculator.formatWait(60), equals('1 hr'));
      });

      test('formats 75 minutes as 1 hr 15 min', () {
        expect(EwtCalculator.formatWait(75), equals('1 hr 15 min'));
      });
    });
  });

  group('QueueEntryStatus', () {
    test('fromString parses "waiting" correctly', () {
      expect(QueueEntryStatus.fromString('waiting'), QueueEntryStatus.waiting);
    });

    test('fromString parses "no_show" (DB format)', () {
      expect(QueueEntryStatus.fromString('no_show'), QueueEntryStatus.noShow);
    });

    test('toDbString converts noShow to "no_show"', () {
      expect(QueueEntryStatus.noShow.toDbString(), equals('no_show'));
    });

    test('toDbString passes through "waiting" unchanged', () {
      expect(QueueEntryStatus.waiting.toDbString(), equals('waiting'));
    });

    test('fromString throws for unknown status', () {
      expect(
        () => QueueEntryStatus.fromString('flying'),
        throwsA(isA<AppException>()),
      );
    });
  });
}
