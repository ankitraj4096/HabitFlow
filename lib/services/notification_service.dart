import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter/material.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();

  static const String _channelId = 'habit_flow_timer';
  static const String _channelName = 'Task Timers';
  static const String _channelDescription = 'Running task timer notifications';
  static const int _timerNotificationId = 1000;

  bool _isInitialized = false;

  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      const AndroidInitializationSettings androidSettings =
          AndroidInitializationSettings('@drawable/ic_notification');

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
              AndroidFlutterLocalNotificationsPlugin>()
          ?.createNotificationChannel(channel);
    } catch (e) {
      debugPrint('Channel creation error: $e');
    }
  }

  Future<bool> requestPermissions() async {
    try {
      if (await Permission.notification.isGranted) return true;
      final status = await Permission.notification.request();
      return status.isGranted;
    } catch (e) {
      return false;
    }
  }

  /// Show/Update timer notification - REMAINING TIME ONLY
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

      // ✅ Calculate remaining time
      final int remaining = (maxProgress != null && progress != null) 
          ? maxProgress - progress 
          : 0;
      final String remainingTime = formatDuration(remaining);
      
      // ✅ Integer percentage (no decimals)
      final int percentInt = percentComplete?.round() ?? 0;
      
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
        
        // Progress bar
        showProgress: progress != null && maxProgress != null,
        maxProgress: maxProgress ?? 100,
        progress: progress ?? 0,
        indeterminate: false,
        
        // ✅ Simple styling - REMAINING TIME ONLY
        styleInformation: BigTextStyleInformation(
          remainingTime,
          htmlFormatBigText: false,
          contentTitle: '⏱️ $taskName',
          htmlFormatContentTitle: false,
          summaryText: '$percentInt% complete',
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
        '⏱️ $taskName',
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
    debugPrint('Notification tapped');
  }

  /// Format duration in MM:SS or HH:MM:SS
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
