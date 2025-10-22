import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:permission_handler/permission_handler.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();

  // Notification channel details
  static const String _channelId = 'timer_channel';
  static const String _channelName = 'Timer Notifications';
  static const String _channelDescription = 'Shows timer running notifications';
  
  // Notification ID for timer (using constant ID allows updating same notification)
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
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: false, // No sound for ongoing timer
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
    const AndroidNotificationChannel channel = AndroidNotificationChannel(
      _channelId,
      _channelName,
      description: _channelDescription,
      importance: Importance.low, // Low importance for ongoing notifications
      playSound: false,
      enableVibration: false,
      showBadge: false,
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
    int? progress,
    int? maxProgress,
  }) async {
    if (!_isInitialized) {
      await initialize();
    }

    // Request permission if not granted
    if (!await requestPermissions()) {
      print('Notification permission not granted');
      return;
    }

    // Android notification details
    AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      _channelId,
      _channelName,
      channelDescription: _channelDescription,
      importance: Importance.low,
      priority: Priority.low,
      ongoing: true, // Makes notification persistent (non-dismissable)
      autoCancel: false,
      playSound: false,
      enableVibration: false,
      showWhen: false,
      usesChronometer: false, // We'll update manually
      // Show progress bar if progress is provided
      showProgress: progress != null && maxProgress != null,
      maxProgress: maxProgress ?? 0,
      progress: progress ?? 0,
      // Notification style
      styleInformation: BigTextStyleInformation(
        timerText,
        contentTitle: taskName,
      ),
    );

    // iOS notification details
    const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: false,
      presentSound: false,
    );

    NotificationDetails notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

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
    int? progress,
    int? maxProgress,
  }) async {
    // Simply call showTimerNotification with same ID to update
    await showTimerNotification(
      taskName: taskName,
      timerText: timerText,
      progress: progress,
      maxProgress: maxProgress,
    );
  }

  Future<void> cancelTimerNotification() async {
    await _notifications.cancel(_timerNotificationId);
  }

  Future<void> cancelAllNotifications() async {
    await _notifications.cancelAll();
  }

  void _onNotificationTapped(NotificationResponse response) {
    // Handle notification tap - could navigate to timer page
    print('Notification tapped: ${response.payload}');
  }

  // Format seconds to readable time string
  static String formatDuration(int seconds) {
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
}
