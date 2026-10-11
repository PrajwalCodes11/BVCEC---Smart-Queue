import 'package:intl/intl.dart';

extension DateTimeExtension on DateTime {
  String toDisplayDate() => DateFormat('dd MMM yyyy').format(this);
  String toDisplayTime() => DateFormat('hh:mm a').format(this);
  String toDisplayDateTime() => DateFormat('dd MMM yyyy, hh:mm a').format(this);
  String toIso8601WithTz() => toUtc().toIso8601String();

  bool isSameDay(DateTime other) {
    return year == other.year && month == other.month && day == other.day;
  }

  String get timeAgo {
    final diff = DateTime.now().difference(this);
    if (diff.inSeconds < 60) return 'just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }
}

extension StringExtension on String {
  String get initials {
    final parts = trim().split(' ');
    if (parts.isEmpty) return '';
    if (parts.length == 1) return parts[0][0].toUpperCase();
    return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
  }

  String get titleCase {
    return split(' ')
        .map((w) => w.isEmpty ? w : '${w[0].toUpperCase()}${w.substring(1).toLowerCase()}')
        .join(' ');
  }
}
