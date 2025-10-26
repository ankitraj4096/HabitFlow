import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter/material.dart';
import 'package:demo/services/notification_preferences.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();

  final NotificationPreferences _prefs = NotificationPreferences();

  // Timer notification channel
  static const String _channelId = 'habit_flow_timer';
  static const String _channelName = 'Task Timers';
  static const String _channelDescription = 'Running task timer notifications';
  static const int _timerNotificationId = 1000;

  // ✅ NEW: Task notification channel
  static const String _taskChannelId = 'habit_flow_tasks';
  static const String _taskChannelName = 'Task Notifications';
  static const String _taskChannelDescription = 'Notifications for new tasks';

  bool _isInitialized = false;

  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      const AndroidInitializationSettings androidSettings =
          AndroidInitializationSettings('ic_notification');

      const DarwinInitializationSettings iosSettings =
          DarwinInitializationSettings(
            requestAlertPermission: false,
            requestBadgePermission: false,
            requestSoundPermission: false,
          );

      const InitializationSettings initSettings = InitializationSettings(
        android: androidSettings,
        iOS: iosSettings,
      );

      await _notifications.initialize(
        initSettings,
        onDidReceiveNotificationResponse: _onNotificationTapped,
      );

      await _createNotificationChannel();
      await _createTaskNotificationChannel(); // ✅ NEW
      _isInitialized = true;
    } catch (e) {
      debugPrint('Notification init error: $e');
    }
  }

  Future<void> _createNotificationChannel() async {
    try {
      const AndroidNotificationChannel channel = AndroidNotificationChannel(
        _channelId,
        _channelName,
        description: _channelDescription,
        importance: Importance.low,
        playSound: false,
        enableVibration: false,
        showBadge: false,
      );

      await _notifications
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >()
          ?.createNotificationChannel(channel);
    } catch (e) {
      debugPrint('Channel creation error: $e');
    }
  }

  // ✅ NEW: Create task notification channel
  Future<void> _createTaskNotificationChannel() async {
    try {
      const AndroidNotificationChannel channel = AndroidNotificationChannel(
        _taskChannelId,
        _taskChannelName,
        description: _taskChannelDescription,
        importance: Importance.high,
        playSound: true,
        enableVibration: true,
        showBadge: true,
      );

      await _notifications
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >()
          ?.createNotificationChannel(channel);
    } catch (e) {
      debugPrint('Task channel creation error: $e');
    }
  }

  Future<bool> requestPermissions() async {
    try {
      if (await Permission.notification.isGranted) return true;
      final status = await Permission.notification.request();
      return status.isGranted;
    } catch (e) {
      debugPrint('Permission error: $e');
      return false;
    }
  }

  Future<void> showTimerNotification({
    required String taskName,
    required String timerText,
    String? subText,
    int? progress,
    int? maxProgress,
    double? percentComplete,
  }) async {
    try {
      if (!_isInitialized) await initialize();
      if (!await requestPermissions()) return;

      ProgressBarStyle progressBarStyle = ProgressBarStyle.thickBlocks;
      bool showPercentage = true;
      bool showElapsedTime = false;
      bool showTotalTime = false;
      bool showSystemProgressBar = false;

      try {
        progressBarStyle = await _prefs.getProgressBarStyle();
        showPercentage = await _prefs.getShowPercentage();
        showElapsedTime = await _prefs.getShowElapsedTime();
        showTotalTime = await _prefs.getShowTotalTime();
        showSystemProgressBar = await _prefs.getShowSystemProgressBar();
      } catch (e) {
        debugPrint('Error loading preferences: $e');
      }

      final int remaining = (maxProgress != null && progress != null)
          ? maxProgress - progress
          : 0;
      final int elapsed = progress ?? 0;
      final int total = maxProgress ?? 0;

      final String remainingTime = formatDuration(remaining);
      final String elapsedTime = formatDuration(elapsed);
      final String totalTime = formatDuration(total);

      final int percentInt = percentComplete?.round() ?? 0;

      final String progressBar = _prefs.getProgressBarChars(
        progressBarStyle,
        percentInt,
      );

      final List<String> contentLines = [];

      if (showPercentage) {
        contentLines.add('$progressBar  $percentInt%');
      } else {
        contentLines.add(progressBar);
      }

      if (showElapsedTime) {
        contentLines.add('⏱️ Elapsed: $elapsedTime');
      }

      if (showTotalTime) {
        contentLines.add('🎯 Total: $totalTime');
      }

      final String contentText = contentLines.join('\n');

      final AndroidNotificationDetails androidDetails =
          AndroidNotificationDetails(
            _channelId,
            _channelName,
            channelDescription: _channelDescription,

            importance: Importance.low,
            priority: Priority.low,
            ongoing: true,
            autoCancel: false,
            playSound: false,
            enableVibration: false,
            onlyAlertOnce: true,
            showWhen: false,
            usesChronometer: false,

            showProgress:
                showSystemProgressBar &&
                progress != null &&
                maxProgress != null,
            maxProgress: maxProgress ?? 100,
            progress: progress ?? 0,

            styleInformation: BigTextStyleInformation(
              contentText,
              htmlFormatBigText: false,
              contentTitle: taskName,
              htmlFormatContentTitle: false,
              summaryText: null,
              htmlFormatSummaryText: false,
            ),

            color: const Color(0xFF6A1B9A),
            colorized: false,
            category: AndroidNotificationCategory.progress,
            visibility: NotificationVisibility.public,
          );

      const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
        presentAlert: false,
        presentBadge: false,
        presentSound: false,
        threadIdentifier: 'timer_thread',
      );

      final NotificationDetails details = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );

      await _notifications.show(
        _timerNotificationId,
        taskName,
        remainingTime,
        details,
      );
    } catch (e) {
      debugPrint('Show notification error: $e');
    }
  }

  Future<void> updateTimerNotification({
    required String taskName,
    required String timerText,
    String? subText,
    int? progress,
    int? maxProgress,
    double? percentComplete,
  }) async {
    await showTimerNotification(
      taskName: taskName,
      timerText: timerText,
      subText: subText,
      progress: progress,
      maxProgress: maxProgress,
      percentComplete: percentComplete,
    );
  }

  // ✅ UPDATED: Simpler notification
  Future<void> showNewTaskNotification({
    required String taskName,
    required String senderName,
    int notificationId = 2000,
  }) async {
    try {
      if (!_isInitialized) await initialize();
      if (!await requestPermissions()) return;

      final AndroidNotificationDetails androidDetails =
          AndroidNotificationDetails(
            _taskChannelId,
            _taskChannelName,
            channelDescription: _taskChannelDescription,

            importance: Importance.high,
            priority: Priority.high,
            playSound: true,
            enableVibration: true,
            showWhen: true,
            autoCancel: true,

            // ✅ Simplified - no BigTextStyle
            color: const Color(0xFF6A1B9A),
            colorized: true,
            category: AndroidNotificationCategory.message,
            visibility: NotificationVisibility.public,
          );

      const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
        sound: 'default',
      );

      final NotificationDetails details = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );

      // ✅ Simple title and body
      await _notifications.show(
        notificationId,
        'New Task Request', // Simple title
        taskName, // Just the task name
        details,
        payload: 'task_request',
      );
    } catch (e) {
      debugPrint('Show task notification error: $e');
    }
  }

  // ✅ NEW: Show notification for friend requests
  Future<void> showFriendRequestNotification({
    required String message,
    int notificationId = 4000,
  }) async {
    try {
      if (!_isInitialized) await initialize();
      if (!await requestPermissions()) return;

      final AndroidNotificationDetails androidDetails =
          AndroidNotificationDetails(
            _taskChannelId,
            _taskChannelName,
            channelDescription: _taskChannelDescription,

            importance: Importance.high,
            priority: Priority.high,
            playSound: true,
            enableVibration: true,
            showWhen: true,
            autoCancel: true,

            color: const Color(0xFF6A1B9A),
            colorized: true,
            category: AndroidNotificationCategory.social,
            visibility: NotificationVisibility.public,
          );

      const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
        sound: 'default',
      );

      final NotificationDetails details = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );

      // Show friend request notification
      await _notifications.show(
        notificationId,
        'Friend Request', // Title
        message, // Body
        details,
        payload: 'friend_request',
      );
    } catch (e) {
      debugPrint('Show friend request notification error: $e');
    }
  }

  Future<void> cancelTimerNotification() async {
    try {
      await _notifications.cancel(_timerNotificationId);
    } catch (e) {
      debugPrint('Cancel notification error: $e');
    }
  }

  Future<void> cancelAllNotifications() async {
    try {
      await _notifications.cancelAll();
    } catch (e) {
      debugPrint('Cancel all error: $e');
    }
  }

  void _onNotificationTapped(NotificationResponse response) {
    debugPrint('Notification tapped: ${response.payload}');
  }

  static String formatDuration(int seconds) {
    final hours = seconds ~/ 3600;
    final minutes = (seconds % 3600) ~/ 60;
    final secs = seconds % 60;

    if (hours > 0) {
      return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
    } else {
      return '${minutes.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
    }
  }

  static String formatDurationWithLabels(int seconds) {
    final hours = seconds ~/ 3600;
    final minutes = (seconds % 3600) ~/ 60;
    final secs = seconds % 60;

    if (hours > 0) {
      return '${hours}h ${minutes}m ${secs}s';
    } else if (minutes > 0) {
      return '${minutes}m ${secs}s';
    } else {
      return '${secs}s';
    }
  }

  static double calculatePercentage(int current, int total) {
    if (total == 0) return 0.0;
    return (current / total * 100).clamp(0.0, 100.0);
  }
}
