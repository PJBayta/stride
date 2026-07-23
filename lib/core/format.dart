/// Shared display formatters, kept in one place so tracking and summary
/// screens don't each grow their own copy.
library;

/// Formats a duration as `h:mm:ss`, or `mm:ss` when under an hour.
String formatDuration(Duration duration) {
  final hours = duration.inHours;
  final minutes = duration.inMinutes.remainder(60).toString().padLeft(2, '0');
  final seconds = duration.inSeconds.remainder(60).toString().padLeft(2, '0');
  return hours > 0 ? '$hours:$minutes:$seconds' : '$minutes:$seconds';
}

/// Formats a pace given in seconds-per-kilometer as `m:ss`.
String formatPace(double secondsPerKm) {
  if (secondsPerKm.isNaN || secondsPerKm.isInfinite || secondsPerKm <= 0) {
    return '--:--';
  }
  final totalSeconds = secondsPerKm.round();
  final minutes = totalSeconds ~/ 60;
  final seconds = (totalSeconds % 60).toString().padLeft(2, '0');
  return '$minutes:$seconds';
}

const _weekdayNames = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
const _monthNames = [
  'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
  'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
];

/// Formats a timestamp as `Mon, Jan 5 • 6:45 PM` in local time.
String formatSessionTimestamp(DateTime dateTime) {
  final local = dateTime.toLocal();
  final weekday = _weekdayNames[local.weekday - 1];
  final month = _monthNames[local.month - 1];
  final hour12 = local.hour % 12 == 0 ? 12 : local.hour % 12;
  final minute = local.minute.toString().padLeft(2, '0');
  final period = local.hour >= 12 ? 'PM' : 'AM';
  return '$weekday, $month ${local.day} • $hour12:$minute $period';
}
