# Audio Notification & Background Playback Architecture

This document describes the design, implementation, and synchronization mechanisms of the media notification service and background audio playback system in the EPUB Audio application.

---

## 1. Overview & Objectives

The Notification Subsystem enables seamless background listening and quick control of audiobook narration from the device's system notification shade, lock screen, and wearable devices.

### Key Goals
1. **Background Playback**: Keep TTS narration alive when the app is minimized, screen is locked, or when the user navigates between screens.
2. **Design & State Parity**: Mirror the Home Screen floating player tile with 1:1 fidelity in data, text formatting, cover artwork, and reading progress.
3. **Low-Latency Action Dispatch**: Handle interactive button clicks (`⏮ Prev`, `⏯ Play/Pause`, `⏭ Next`, `✕ Close`) instantly without battery-saver throttling on Android 12+.

---

## 2. Notification Architecture Diagram

```
┌────────────────────────────────────────────────────────┐
│               Android System Notification Tray         │
│  ┌──────────────────────────────────────────────────┐  │
│  │ [Cover Art]  Chemmeen                            │  │
│  │              Chapter 1 • Para 4 of 28            │  │
│  │  ────────────●─────────────────────────────────  │  │
│  │     [⏮ Prev]   [⏸ Pause]   [⏭ Next]   [✕ Close]   │  │
│  └──────────────────────────────────────────────────┘  │
└──────────────────────────┬─────────────────────────────┘
                           │ (PendingIntent / Action)
                           ▼
┌────────────────────────────────────────────────────────┐
│            AudioNotificationService (Singleton)        │
│    • handleActionId(actionId)                          │
│    • showOrUpdatePlaybackNotification(...)             │
│    • cancelNotification()                              │
│    • IsolateNameServer port bridge                     │
└──────────────────────────┬─────────────────────────────┘
                           │
                           ▼
┌────────────────────────────────────────────────────────┐
│           BookSessionController (Active Session)       │
│    • playAudio() / pauseAudio()                        │
│    • nextAudioParagraph() / previousAudioParagraph()   │
│    • stopAudio()                                       │
│    • _syncNotification()                               │
└──────────────────────────┬─────────────────────────────┘
                           │
                           ▼
┌────────────────────────────────────────────────────────┐
│            TtsAudioService (TTS Narration Engine)      │
│    • FlutterTts engine with pitch/rate/volume          │
│    • Malayalam & multi-lingual synthesis               │
│    • Real-time word offset callbacks                   │
└────────────────────────────────────────────────────────┘
```

---

## 3. Component Details

### 3.1 `AudioNotificationService`
Located at `lib/features/audio/data/services/audio_notification_service.dart`.
- **Channel Configuration**:
  - `channelId`: `epub_audio_playback`
  - `channelName`: `Audiobook Playback`
  - `importance`: `Importance.defaultImportance`
  - `priority`: `Priority.high`
  - `category`: `AndroidNotificationCategory.transport`
  - `ongoing`: `isPlaying` (prevents accidental swipe-away while active)
- **Visuals**:
  - `largeIcon`: `ByteArrayAndroidBitmap(coverImageBytes)` (Dynamic EPUB cover art thumbnail)
  - `showProgress`: `true`
  - `maxProgress`: `100`
  - `progress`: Percentage calculated from `(currentParagraph / totalParagraphs) * 100`
  - `color`: `Color(0xFF2563EB)` (Accent Blue)
  - `subText`: `Now Playing` / `Paused`
- **Actions**:
  - `actionPrev` (`'⏮ Prev'`): Skips to previous paragraph.
  - `actionPlay` / `actionPause` (`'▶ Play'` / `'⏸ Pause'`): Toggles narration playback.
  - `actionNext` (`'⏭ Next'`): Skips to next paragraph.
  - `actionStop` (`'✕ Close'`): Stops playback and removes notification.

### 3.2 Action Dispatch & Android 12+ (API 31+) Compatibility
On modern Android versions, broadcast receivers in background tasks may suffer from battery optimization delays. The notification service uses:
- `showsUserInterface: true` on `AndroidNotificationAction` to route PendingIntents directly into `MainActivity` (configured with `launchMode="singleTop"`).
- `onDidReceiveNotificationResponse` & `onDidReceiveBackgroundNotificationResponse` (VM entry point `@pragma('vm:entry-point') notificationTapBackground`).
- An `IsolateNameServer` port bridge (`epub_audio_notification_port`) ensuring background isolate clicks route cleanly to `BookSessionController.activeSession`.

---

## 4. Permissions & Android Manifest Configuration

### 4.1 Android Permissions (`android/app/src/main/AndroidManifest.xml`)
```xml
<!-- Foreground & Background Audio Playback Permissions -->
<uses-permission android:name="android.permission.FOREGROUND_SERVICE" />
<uses-permission android:name="android.permission.FOREGROUND_SERVICE_MEDIA_PLAYBACK" />
<uses-permission android:name="android.permission.POST_NOTIFICATIONS" />
<uses-permission android:name="android.permission.WAKE_LOCK" />
```

### 4.2 Desugaring Configuration (`android/app/build.gradle.kts`)
`flutter_local_notifications` requires core library desugaring on Android:
```kotlin
android {
    compileOptions {
        isCoreLibraryDesugaringEnabled = true
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }
}

dependencies {
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4")
}
```

---

## 5. Synchronization with Home Screen & Reader

The notification text and progress are synchronized in real-time by `BookSessionController._syncNotification()` whenever:
1. Playback starts, pauses, resumes, or stops.
2. The paragraph index changes (during continuous playback or manual seek).
3. The reader chapter changes.
4. Word-level seeking occurs.

```dart
void _syncNotification() {
  final chTitle = _currentChapterContent?.title ??
      'Chapter ${_currentPosition.chapterIndex + 1}';

  AudioNotificationService().showOrUpdatePlaybackNotification(
    bookTitle: book.metadata.title,
    author: book.metadata.author,
    chapterTitle: chTitle,
    isPlaying: _audioState.isPlaying,
    coverImageBytes: book.coverImageBytes,
    currentParagraph: _currentPosition.paragraphIndex + 1,
    totalParagraphs: _currentChapterParagraphs.length,
  );
}
```

---

## 6. Testing & Quality Assurance

- **Unit & Synchronization Tests**: Tested in `test/unit/book_session_controller_test.dart` and `test/widget_test.dart`.
- **Platform Check Graceful Fallback**: In test environments or unsupported platforms, notification initialization gracefully catches `LateInitializationError` without breaking UI widget tests.
- **Verification Commands**:
  ```bash
  flutter analyze
  flutter test
  flutter build apk --release
  ```
