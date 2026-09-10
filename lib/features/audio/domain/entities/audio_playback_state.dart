import 'package:epub_audio/features/session/domain/entities/book_position.dart';
import 'package:meta/meta.dart';

/// Audio playback status states.
enum AudioPlaybackStatus {
  stopped,
  playing,
  paused,
  buffering,
  error,
}

/// Progress event emitted during audio playback.
class AudioProgressEvent {
  final int paragraphIndex;
  final int totalParagraphs;
  final double progressFraction; // 0.0 to 1.0 within the chapter
  final bool isCompleted;

  const AudioProgressEvent({
    required this.paragraphIndex,
    required this.totalParagraphs,
    required this.progressFraction,
    this.isCompleted = false,
  });
}

/// Comprehensive audio playback state.
@immutable
class AudioPlaybackState {
  final AudioPlaybackStatus status;
  final BookPosition position;
  final double speechRate; // 0.5x to 2.0x (1.0 = normal)
  final double pitch; // 0.5 to 2.0
  final double volume; // 0.0 to 1.0
  final String? currentText;
  final int totalParagraphsInChapter;
  final String? errorMessage;
  final Duration? sleepTimerRemaining;

  const AudioPlaybackState({
    this.status = AudioPlaybackStatus.stopped,
    required this.position,
    this.speechRate = 1.0,
    this.pitch = 1.0,
    this.volume = 1.0,
    this.currentText,
    this.totalParagraphsInChapter = 0,
    this.errorMessage,
    this.sleepTimerRemaining,
  });

  bool get isPlaying => status == AudioPlaybackStatus.playing;
  bool get isPaused => status == AudioPlaybackStatus.paused;
  bool get isStopped => status == AudioPlaybackStatus.stopped;

  AudioPlaybackState copyWith({
    AudioPlaybackStatus? status,
    BookPosition? position,
    double? speechRate,
    double? pitch,
    double? volume,
    String? currentText,
    int? totalParagraphsInChapter,
    String? errorMessage,
    Duration? sleepTimerRemaining,
    bool clearSleepTimer = false,
  }) {
    return AudioPlaybackState(
      status: status ?? this.status,
      position: position ?? this.position,
      speechRate: speechRate ?? this.speechRate,
      pitch: pitch ?? this.pitch,
      volume: volume ?? this.volume,
      currentText: currentText ?? this.currentText,
      totalParagraphsInChapter:
          totalParagraphsInChapter ?? this.totalParagraphsInChapter,
      errorMessage: errorMessage,
      sleepTimerRemaining: clearSleepTimer
          ? null
          : (sleepTimerRemaining ?? this.sleepTimerRemaining),
    );
  }
}
