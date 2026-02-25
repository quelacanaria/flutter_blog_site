import 'package:intl/intl.dart';

class DateTimeHelper {
  static String formatFull(String? date) {
    if (date == null) return '';

    final DateTime parsed = DateTime.parse(date).toLocal();
    return DateFormat('MMM d, yyyy • hh:mm a').format(parsed);
  }

  /// Example: 5m ago, 2h ago, 3d ago
  static String timeAgo(String? date) {
    if (date == null) return '';

    final DateTime parsed = DateTime.parse(date).toLocal();
    final Duration diff = DateTime.now().difference(parsed);

    if (diff.inSeconds < 60) {
      return '${diff.inSeconds}s ago';
    } else if (diff.inMinutes < 60) {
      return '${diff.inMinutes}m ago';
    } else if (diff.inHours < 24) {
      return '${diff.inHours}h ago';
    } else if (diff.inDays < 7) {
      return '${diff.inDays}d ago';
    } else {
      return formatFull(date);
    }
  }
}
