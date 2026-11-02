import 'package:intl/intl.dart';

extension DateTimeExtensions on DateTime {
  String get chatTimestamp {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final msgDate = DateTime(year, month, day);

    if (msgDate == today) {
      return DateFormat('hh:mm a').format(this);
    } else if (msgDate == yesterday) {
      return 'Yesterday';
    } else if (now.difference(this).inDays < 7) {
      return DateFormat('EEEE').format(this);
    } else {
      return DateFormat('dd/MM/yyyy').format(this);
    }
  }

  String get timeOnly => DateFormat('hh:mm a').format(this);
  String get fullDateTime => DateFormat('dd MMM yyyy, hh:mm a').format(this);
  String get dateOnly => DateFormat('dd MMM yyyy').format(this);
}
