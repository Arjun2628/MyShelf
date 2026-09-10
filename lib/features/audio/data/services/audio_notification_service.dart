import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

/// Top-level or static background action handler for notification action button taps.
@pragma('vm:entry-point')
void notificationTapBackground(NotificationResponse notificationResponse) {
  AudioNotificationService().handleNotificationResponse(notificationResponse);
}

/// Service that creates and maintains media playback notifications in the system notification shade.
class AudioNotificationService {
  static const int notificationId = 8801;
  static const String channelId = 'epub_audio_playback';
  static const String channelName = 'Audiobook Playback';
  static const String channelDescription =
      'Shows ongoing playback status and controls for EPUB audiobook narration';

  static const String actionPlay = 'action_play';
  static const String actionPause = 'action_pause';
  static const String actionNext = 'action_next';
  static const String actionPrev = 'action_prev';
  static const String actionStop = 'action_stop';

  static final AudioNotificationService _instance =
      AudioNotificationService._internal();
  factory AudioNotificationService() => _instance;
  AudioNotificationService._internal();

  final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();

  bool _isInitialized = false;

  VoidCallback? onPlayPressed;
  VoidCallback? onPausePressed;
  VoidCallback? onNextPressed;
  VoidCallback? onPrevPressed;
  VoidCallback? onStopPressed;

  /// Initializes the local notifications plugin and configures notification channels.
  Future<void> init() async {
    if (_isInitialized) return;

    try {
      const androidSettings =
          AndroidInitializationSettings('@mipmap/ic_launcher');
      const darwinSettings = DarwinInitializationSettings(
        requestAlertPermission: true,
        requestBadgePermission: false,
        requestSoundPermission: false,
      );

      const initSettings = InitializationSettings(
        android: androidSettings,
        iOS: darwinSettings,
        macOS: darwinSettings,
      );

      try {
        await _notificationsPlugin.initialize(
          settings: initSettings,
          onDidReceiveNotificationResponse: (response) {
            handleNotificationResponse(response);
          },
          onDidReceiveBackgroundNotificationResponse: notificationTapBackground,
        );

        if (Platform.isAndroid) {
          final androidImpl = _notificationsPlugin
              .resolvePlatformSpecificImplementation<
                  AndroidFlutterLocalNotificationsPlugin>();
          await androidImpl?.requestNotificationsPermission();
        }

        _isInitialized = true;
      } catch (e) {
        debugPrint('[AudioNotificationService] Platform init skipped: $e');
      }
    } catch (e) {
      debugPrint('[AudioNotificationService] Init error: $e');
    }
  }

  /// Handles action button taps from the system notification bar.
  void handleNotificationResponse(NotificationResponse response) {
    final actionId = response.actionId;
    debugPrint('[AudioNotificationService] Notification action received: $actionId');

    if (actionId == actionPlay) {
      onPlayPressed?.call();
    } else if (actionId == actionPause) {
      onPausePressed?.call();
    } else if (actionId == actionNext) {
      onNextPressed?.call();
    } else if (actionId == actionPrev) {
      onPrevPressed?.call();
    } else if (actionId == actionStop) {
      onStopPressed?.call();
      cancelNotification();
    }
  }

  /// Displays or updates the media control notification in the notification shade.
  Future<void> showOrUpdatePlaybackNotification({
    required String bookTitle,
    required String author,
    required String chapterTitle,
    required bool isPlaying,
    String? currentTextSnippet,
  }) async {
    await init();
    if (!_isInitialized) return;

    try {
      final actions = <AndroidNotificationAction>[
        const AndroidNotificationAction(
          actionPrev,
          'Previous',
          showsUserInterface: false,
          cancelNotification: false,
        ),
        AndroidNotificationAction(
          isPlaying ? actionPause : actionPlay,
          isPlaying ? 'Pause' : 'Play',
          showsUserInterface: false,
          cancelNotification: false,
        ),
        const AndroidNotificationAction(
          actionNext,
          'Next',
          showsUserInterface: false,
          cancelNotification: false,
        ),
        const AndroidNotificationAction(
          actionStop,
          'Stop',
          showsUserInterface: false,
          cancelNotification: true,
        ),
      ];

      final androidDetails = AndroidNotificationDetails(
        channelId,
        channelName,
        channelDescription: channelDescription,
        importance: Importance.low,
        priority: Priority.low,
        ongoing: isPlaying,
        autoCancel: false,
        showWhen: false,
        enableVibration: false,
        playSound: false,
        actions: actions,
        category: AndroidNotificationCategory.transport,
        visibility: NotificationVisibility.public,
        styleInformation: BigTextStyleInformation(
          currentTextSnippet != null && currentTextSnippet.trim().isNotEmpty
              ? '$chapterTitle\n$currentTextSnippet'
              : chapterTitle,
          contentTitle: bookTitle,
          summaryText: author.isNotEmpty ? author : 'Audiobook',
        ),
      );

      const darwinDetails = DarwinNotificationDetails(
        presentAlert: false,
        presentBadge: false,
        presentSound: false,
      );

      final notificationDetails = NotificationDetails(
        android: androidDetails,
        iOS: darwinDetails,
        macOS: darwinDetails,
      );

      await _notificationsPlugin.show(
        id: notificationId,
        title: bookTitle,
        body: chapterTitle,
        notificationDetails: notificationDetails,
      );
    } catch (e) {
      debugPrint('[AudioNotificationService] Show notification error: $e');
    }
  }

  /// Cancels and removes the playback notification from the notification tray.
  Future<void> cancelNotification() async {
    try {
      await _notificationsPlugin.cancel(id: notificationId);
    } catch (e) {
      debugPrint('[AudioNotificationService] Cancel notification error: $e');
    }
  }
}
