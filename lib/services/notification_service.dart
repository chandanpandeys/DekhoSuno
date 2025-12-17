/// Notification Service stub - notifications disabled for stability
/// TODO: Re-enable when flutter_local_notifications dependency is resolved
class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  /// Initialize - no-op for now
  Future<void> initialize() async {}

  /// Schedule a reminder - currently just prints to debug
  Future<void> scheduleReminder({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledTime,
  }) async {
    // Notifications disabled - would show at $scheduledTime
  }

  /// Show an immediate notification - no-op
  Future<void> showNotification({
    required int id,
    required String title,
    required String body,
  }) async {}

  /// Cancel a reminder - no-op
  Future<void> cancelReminder(int id) async {}

  /// Cancel all - no-op
  Future<void> cancelAll() async {}

  /// Parse natural language time expressions to DateTime
  /// Supports: "in X minutes", "at X:XX", "X o'clock", "tomorrow at X"
  static DateTime? parseTimeExpression(String text) {
    final now = DateTime.now();
    text = text.toLowerCase();

    // "in X minutes/hours"
    final inMinutesMatch = RegExp(r'in (\d+) ?min').firstMatch(text);
    if (inMinutesMatch != null) {
      final minutes = int.parse(inMinutesMatch.group(1)!);
      return now.add(Duration(minutes: minutes));
    }

    final inHoursMatch = RegExp(r'in (\d+) ?hour').firstMatch(text);
    if (inHoursMatch != null) {
      final hours = int.parse(inHoursMatch.group(1)!);
      return now.add(Duration(hours: hours));
    }

    // "at X:XX" or "X:XX"
    final timeMatch = RegExp(r'(\d{1,2}):(\d{2})').firstMatch(text);
    if (timeMatch != null) {
      var hour = int.parse(timeMatch.group(1)!);
      final minute = int.parse(timeMatch.group(2)!);
      if (text.contains('pm') && hour < 12) hour += 12;
      if (text.contains('am') && hour == 12) hour = 0;
      var scheduled = DateTime(now.year, now.month, now.day, hour, minute);
      if (scheduled.isBefore(now)) {
        scheduled = scheduled.add(const Duration(days: 1));
      }
      return scheduled;
    }

    // "X o'clock"
    final oclockMatch = RegExp(r"(\d{1,2}) ?o'?clock").firstMatch(text);
    if (oclockMatch != null) {
      var hour = int.parse(oclockMatch.group(1)!);
      if (text.contains('pm') && hour < 12) hour += 12;
      var scheduled = DateTime(now.year, now.month, now.day, hour, 0);
      if (scheduled.isBefore(now)) {
        scheduled = scheduled.add(const Duration(days: 1));
      }
      return scheduled;
    }

    // "tomorrow at X"
    final tomorrowMatch = RegExp(r'tomorrow at (\d{1,2})').firstMatch(text);
    if (tomorrowMatch != null) {
      var hour = int.parse(tomorrowMatch.group(1)!);
      if (text.contains('pm') && hour < 12) hour += 12;
      return DateTime(now.year, now.month, now.day + 1, hour, 0);
    }

    return null;
  }
}
