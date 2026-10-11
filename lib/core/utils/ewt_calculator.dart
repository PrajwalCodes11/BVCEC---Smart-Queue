/// Waiting-Time Estimator using exponential smoothing.
///
/// PROTOTYPE ASSUMPTION:
///   α = 0.3 (smoothing factor) — chosen as reasonable default.
///   Should be tuned based on collected data and MAE measurement.
///
/// Formula:
///   newAvg = α × actualDuration + (1 - α) × previousAvg
///
/// EWT for a student at position [position] with [activeCounters] available:
///   EWT ≈ (position / activeCounters) × avgDuration
class EwtCalculator {
  static const double _alpha = 0.3;

  /// Updates the running average with a new [actualDurationMinutes] observation.
  /// Returns the new average.
  static double updateAverage({
    required double previousAverage,
    required double actualDurationMinutes,
  }) {
    return _alpha * actualDurationMinutes + (1 - _alpha) * previousAverage;
  }

  /// Estimates wait time in minutes for a student joining at [positionInQueue]
  /// (1-based: position 1 means next to be served).
  ///
  /// [customersAhead] = positionInQueue - 1
  /// [activeCounters] = number of counters currently available or serving
  /// [avgServiceDurationMinutes] = current running average for this service
  static int estimateWaitMinutes({
    required int positionInQueue,
    required int activeCounters,
    required double avgServiceDurationMinutes,
  }) {
    if (activeCounters <= 0) return -1; // Unknown / counter offline
    if (positionInQueue <= 0) return 0;

    final customersAhead = positionInQueue - 1;
    // Approximate: customers ahead served across active counters
    final batches = (customersAhead / activeCounters);
    final estimatedWait = batches * avgServiceDurationMinutes;

    return estimatedWait.ceil();
  }

  /// Formats minutes into a human-readable string.
  /// E.g., 75 → "1 hr 15 min"
  static String formatWait(int minutes) {
    if (minutes < 0) return 'Unknown';
    if (minutes == 0) return 'Your turn soon';
    if (minutes < 60) return '$minutes min';
    final h = minutes ~/ 60;
    final m = minutes % 60;
    if (m == 0) return '$h hr';
    return '$h hr $m min';
  }
}
