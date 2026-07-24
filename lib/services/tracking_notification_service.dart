import 'package:flutter/foundation.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';

import '../models/activity_type.dart';

/// Manages Strava-style ongoing background system notifications for live activities.
class TrackingNotificationService {
  /// Initializes notification options and channel at app startup.
  static Future<void> init() async {
    if (kIsWeb) return;
    try {
      FlutterForegroundTask.initCommunicationPort();
      FlutterForegroundTask.init(
        androidNotificationOptions: AndroidNotificationOptions(
          channelId: 'stride_tracking_channel',
          channelName: 'Stride Activity Tracking',
          channelDescription: 'Shows live activity duration, distance, and speed.',
          channelImportance: NotificationChannelImportance.LOW,
          priority: NotificationPriority.LOW,
        ),
        iosNotificationOptions: const IOSNotificationOptions(
          showNotification: true,
          playSound: false,
        ),
        foregroundTaskOptions: ForegroundTaskOptions(
          eventAction: ForegroundTaskEventAction.repeat(1000),
          autoRunOnBoot: false,
          allowWifiLock: false,
        ),
      );
    } catch (_) {
      // Graceful fallback for web/test environments
    }
  }

  /// Starts the foreground service notification when an activity starts.
  static Future<void> start(ActivityType activityType) async {
    if (kIsWeb) return;
    try {
      if (await FlutterForegroundTask.isRunningService) {
        await FlutterForegroundTask.restartService();
      } else {
        await FlutterForegroundTask.requestNotificationPermission();
        await FlutterForegroundTask.startService(
          serviceId: 256,
          notificationTitle: '${activityType.label} Session',
          notificationText: 'Tracking in progress…',
        );
      }
    } catch (_) {
      // Graceful fallback for test/unsupported environments
    }
  }

  /// Updates the notification text with live metrics (duration, distance, speed/pace).
  static Future<void> update({
    required ActivityType activityType,
    required String durationText,
    required String distanceText,
    required String speedOrPaceText,
  }) async {
    if (kIsWeb) return;
    try {
      if (!await FlutterForegroundTask.isRunningService) return;
      await FlutterForegroundTask.updateService(
        notificationTitle: '${activityType.label} in Progress',
        notificationText: '$distanceText  •  $durationText  •  $speedOrPaceText',
      );
    } catch (_) {
      // Graceful fallback
    }
  }

  /// Stops and removes the foreground notification.
  static Future<void> stop() async {
    if (kIsWeb) return;
    try {
      if (await FlutterForegroundTask.isRunningService) {
        await FlutterForegroundTask.stopService();
      }
    } catch (_) {
      // Graceful fallback
    }
  }
}
