import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter/material.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();

  // Notification channel details
  static const String _channelId = 'timer_channel_v2';
  static const String _channelName = 'Task Timer';
  static const String _channelDescription =
      'Shows real-time progress of running task timers';

  // Notification ID for timer
  static const int _timerNotificationId = 1000;

  bool _isInitialized = false;

  Future<void> initialize() async {
    if (_isInitialized) return;

    // Android initialization settings
    const AndroidInitializationSettings androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    // iOS initialization settings
    const DarwinInitializationSettings iosSettings =
        DarwinInitializationSettings(
      requestAlertPermission: false, // Changed to false to prevent pop-ups
      requestBadgePermission: true,
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

    // Create notification channel for Android
    await _createNotificationChannel();

    _isInitialized = true;
  }

  Future<void> _createNotificationChannel() async {
    // Silent notification channel - no sound, no vibration
    const AndroidNotificationChannel channel = AndroidNotificationChannel(
      _channelId,
      _channelName,
      description: _channelDescription,
      importance: Importance.low, // Changed back to low to prevent pushiness
      playSound: false,
      enableVibration: false,
      showBadge: false,
      enableLights: false, // Disabled lights
    );

    await _notifications
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);
  }

  Future<bool> requestPermissions() async {
    if (await Permission.notification.isGranted) {
      return true;
    }

    final status = await Permission.notification.request();
    return status.isGranted;
  }

  Future<void> showTimerNotification({
    required String taskName,
    required String timerText,
    String? subText,
    int? progress,
    int? maxProgress,
    double? percentComplete,
  }) async {
    if (!_isInitialized) {
      await initialize();
    }

    // Request permission if not granted
    if (!await requestPermissions()) {
      debugPrint('Notification permission not granted');
      return;
    }

    // Build enhanced content text
    String contentText = subText ?? timerText;

    // Enhanced Android notification details with silent updates
    AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      _channelId,
      _channelName,
      channelDescription: _channelDescription,
      importance: Importance.low, // Low importance = less intrusive
      priority: Priority.low, // Low priority = stays in background
      ongoing: true, // Persistent but not pushy
      autoCancel: false,
      playSound: false,
      enableVibration: false,
      showWhen: false,
      usesChronometer: false,
      onlyAlertOnce: true, // KEY FIX: Only alert once, updates are silent
      
      // Enhanced visual styling
      color: const Color(0xFF6A1B9A),
      colorized: true,
      
      // Large icon
      largeIcon: const DrawableResourceAndroidBitmap('@mipmap/ic_launcher'),
      
      // Progress bar configuration
      showProgress: progress != null && maxProgress != null,
      maxProgress: maxProgress ?? 100,
      progress: progress ?? 0,
      indeterminate: progress == null || maxProgress == null,
      
      // Improved BigTextStyle with cleaner UI
      styleInformation: BigTextStyleInformation(
        contentText,
        htmlFormatBigText: true,
        contentTitle: '<b>$taskName</b>',
        htmlFormatContentTitle: true,
        summaryText: percentComplete != null
            ? '${percentComplete.toStringAsFixed(0)}% complete'
            : 'In progress',
        htmlFormatSummaryText: true,
      ),
      
      // Category
      category: AndroidNotificationCategory.progress,
      
      // Visibility
      visibility: NotificationVisibility.public,
      
      // Silent notification updates
      silent: false, // Keep as false but onlyAlertOnce handles it
    );

    // iOS notification details - silent
    const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
      presentAlert: false, // Don't show alert banner on updates
      presentBadge: false,
      presentSound: false,
      interruptionLevel: InterruptionLevel.passive, // Changed to passive
      threadIdentifier: 'timer_thread',
    );

    NotificationDetails notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    // Show notification with enhanced formatting
    await _notifications.show(
      _timerNotificationId,
      taskName,
      timerText,
      notificationDetails,
    );
  }

  Future<void> updateTimerNotification({
    required String taskName,
    required String timerText,
    String? subText,
    int? progress,
    int? maxProgress,
    double? percentComplete,
  }) async {
    // Simply call showTimerNotification with same ID to update silently
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
    await _notifications.cancel(_timerNotificationId);
  }

  Future<void> cancelAllNotifications() async {
    await _notifications.cancelAll();
  }

  void _onNotificationTapped(NotificationResponse response) {
    debugPrint('Notification tapped: ${response.payload}');
  }

  // Enhanced format duration
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

  // Helper method with labels
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

  // Helper to calculate percentage
  static double calculatePercentage(int current, int total) {
    if (total == 0) return 0.0;
    return (current / total * 100).clamp(0.0, 100.0);
  }
}
