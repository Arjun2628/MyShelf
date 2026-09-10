import 'dart:io';
import 'dart:isolate';
import 'dart:ui';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

/// Top-level background action handler for notification action button taps.
@pragma('vm:entry-point')
void notificationTapBackground(NotificationResponse notificationResponse) {
  final actionId = notificationResponse.actionId ?? notificationResponse.payload;
  if (actionId != null && actionId.isNotEmpty) {
    final sendPort =
        IsolateNameServer.lookupPortByName(AudioNotificationService.isolatePortName);
    if (sendPort != null) {
      sendPort.send(actionId);
    } else {
      AudioNotificationService().handleActionId(actionId);
    }
  }
}

/// Service that creates and maintains media playback notifications in the system notification shade.
class AudioNotificationService {
  static const String isolatePortName = 'epub_audio_notification_port';
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

  ReceivePort? _receivePort;
  bool _isInitialized = false;

  VoidCallback? onPlayPressed;
  VoidCallback? onPausePressed;
  VoidCallback? onNextPressed;
  VoidCallback? onPrevPressed;
  VoidCallback? onStopPressed;

  /// Initializes the local notifications plugin and configures notification channels and isolate port.
  Future<void> init() async {
    if (_isInitialized) return;

    try {
      // Setup isolate communication for background notification clicks
      _receivePort?.close();
      _receivePort = ReceivePort();
      IsolateNameServer.removePortNameMapping(isolatePortName);
      IsolateNameServer.registerPortWithName(
        _receivePort!.sendPort,
        isolatePortName,
      );

      _receivePort!.listen((message) {
        if (message is String) {
          handleActionId(message);
        }
      });

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
            final action = response.actionId ?? response.payload;
            if (action != null && action.isNotEmpty) {
              handleActionId(action);
            }
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

  /// Handles action ID strings from either direct foreground callback or background isolate port.
  void handleActionId(String actionId) {
    debugPrint('[AudioNotificationService] Dispatched action: $actionId');

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

  /// Displays or updates the media control notification in the notification shade (Spotify-style rich media tile).
  Future<void> showOrUpdatePlaybackNotification({
    required String bookTitle,
    required String author,
    required String chapterTitle,
    required bool isPlaying,
    String? currentTextSnippet,
    Uint8List? coverImageBytes,
    int currentParagraph = 0,
    int totalParagraphs = 0,
  }) async {
    await init();
    if (!_isInitialized) return;

    try {
      final actions = <AndroidNotificationAction>[
        const AndroidNotificationAction(
          actionPrev,
          '⏮ Prev',
          showsUserInterface: false,
          cancelNotification: false,
        ),
        AndroidNotificationAction(
          isPlaying ? actionPause : actionPlay,
          isPlaying ? '⏸ Pause' : '▶ Play',
          showsUserInterface: false,
          cancelNotification: false,
        ),
        const AndroidNotificationAction(
          actionNext,
          '⏭ Next',
          showsUserInterface: false,
          cancelNotification: false,
        ),
        const AndroidNotificationAction(
          actionStop,
          '⏹ Stop',
          showsUserInterface: false,
          cancelNotification: true,
        ),
      ];

      final largeIcon = coverImageBytes != null
          ? ByteArrayAndroidBitmap(coverImageBytes)
          : null;

      final progressPercent = totalParagraphs > 0
          ? ((currentParagraph / totalParagraphs) * 100).toInt().clamp(0, 100)
          : 0;

      final androidDetails = AndroidNotificationDetails(
        channelId,
        channelName,
        channelDescription: channelDescription,
        importance: Importance.defaultImportance,
        priority: Priority.high,
        ongoing: isPlaying,
        autoCancel: false,
        showWhen: false,
        enableVibration: false,
        playSound: false,
        actions: actions,
        category: AndroidNotificationCategory.transport,
        visibility: NotificationVisibility.public,
        color: const Color(0xFF1DB954), // Spotify Green / Modern Media Tint
        colorized: true, // Renders the rich media background like Spotify
        largeIcon: largeIcon,
        subText: totalParagraphs > 0
            ? '$progressPercent% • Paragraph $currentParagraph of $totalParagraphs'
            : (author.isNotEmpty ? author : 'Audiobook'),
        showProgress: totalParagraphs > 0,
        maxProgress: 100,
        progress: progressPercent,
        indeterminate: false,
        styleInformation: BigTextStyleInformation(
          currentTextSnippet != null && currentTextSnippet.trim().isNotEmpty
              ? '$chapterTitle\n\n"$currentTextSnippet"'
              : chapterTitle,
          contentTitle: bookTitle,
          summaryText: author.isNotEmpty ? author : 'EPUB Audio',
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
