import '../../core/errors/app_exception.dart';

/// Defines valid queue entry status values.
enum QueueEntryStatus {
  waiting,
  called,
  serving,
  completed,
  cancelled,
  noShow,
  transferred;

  static QueueEntryStatus fromString(String value) {
    return QueueEntryStatus.values.firstWhere(
      (e) => e.name == value || e.name == _toCamel(value),
      orElse: () => throw AppException('Unknown status: $value'),
    );
  }

  static String _toCamel(String value) {
    // Converts snake_case to camelCase: no_show -> noShow
    final parts = value.split('_');
    if (parts.length == 1) return value;
    return parts[0] +
        parts.skip(1).map((p) => p[0].toUpperCase() + p.substring(1)).join();
  }

  String toDbString() {
    switch (this) {
      case QueueEntryStatus.noShow:
        return 'no_show';
      default:
        return name;
    }
  }
}

/// Defines valid counter status values.
enum CounterStatus {
  available,
  serving,
  paused,
  offline;

  static CounterStatus fromString(String value) {
    return CounterStatus.values.firstWhere(
      (e) => e.name == value,
      orElse: () => throw AppException('Unknown counter status: $value'),
    );
  }
}

/// Validates and enforces queue entry state transitions.
///
/// Valid paths:
/// WAITING → CANCELLED
/// WAITING → CALLED
/// CALLED  → NO_SHOW
/// CALLED  → SERVING
/// SERVING → COMPLETED
/// SERVING → TRANSFERRED
class QueueStateMachine {
  static const Map<QueueEntryStatus, Set<QueueEntryStatus>> _validTransitions = {
    QueueEntryStatus.waiting: {
      QueueEntryStatus.cancelled,
      QueueEntryStatus.called,
    },
    QueueEntryStatus.called: {
      QueueEntryStatus.noShow,
      QueueEntryStatus.serving,
    },
    QueueEntryStatus.serving: {
      QueueEntryStatus.completed,
      QueueEntryStatus.transferred,
    },
    // Terminal states — no outgoing transitions
    QueueEntryStatus.completed: {},
    QueueEntryStatus.cancelled: {},
    QueueEntryStatus.noShow: {},
    QueueEntryStatus.transferred: {},
  };

  /// Returns true if transitioning from [current] to [next] is valid.
  static bool canTransition(QueueEntryStatus current, QueueEntryStatus next) {
    return _validTransitions[current]?.contains(next) ?? false;
  }

  /// Validates the transition or throws [InvalidStateTransitionException].
  static void validateTransition(
      QueueEntryStatus current, QueueEntryStatus next) {
    if (!canTransition(current, next)) {
      throw InvalidStateTransitionException(current.name, next.name);
    }
  }

  /// Returns all valid next states from the given [current] state.
  static Set<QueueEntryStatus> validNextStates(QueueEntryStatus current) {
    return _validTransitions[current] ?? {};
  }
}
