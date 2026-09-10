import 'package:epub_audio/features/reader/domain/entities/reader_preferences.dart';
import 'package:epub_audio/features/session/presentation/controllers/book_session_controller.dart';
import 'package:flutter/material.dart';

/// Docked mini player for audio playback control while reading.
class MiniAudioPlayer extends StatelessWidget {
  final BookSessionController session;
  final ReaderPreferences preferences;
  final VoidCallback onExpand;

  const MiniAudioPlayer({
    super.key,
    required this.session,
    required this.preferences,
    required this.onExpand,
  });

  @override
  Widget build(BuildContext context) {
    final colors = preferences.colors;
    final audioState = session.audioState;
    final currentText = audioState.currentText ??
        session.currentChapterContent?.title ??
        'Audiobook';

    return GestureDetector(
      onTap: onExpand,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: colors.cardBackground,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: audioState.isPlaying
                ? colors.accent
                : colors.divider.withValues(alpha: 0.8),
            width: audioState.isPlaying ? 1.5 : 1.0,
          ),
          boxShadow: [
            BoxShadow(
              color: colors.accent.withValues(alpha: audioState.isPlaying ? 0.12 : 0.04),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            // Animated Speaker Icon
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: colors.accent.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(
                audioState.isPlaying ? Icons.graphic_eq_rounded : Icons.headphones_rounded,
                color: colors.accent,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),

            // Text Snippet & Chapter
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Text(
                        'AUDIOBOOK',
                        style: TextStyle(
                          color: colors.accent,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.8,
                        ),
                      ),
                      if (audioState.totalParagraphsInChapter > 0) ...[
                        const SizedBox(width: 6),
                        Text(
                          '• ${session.currentParagraphIndex + 1}/${audioState.totalParagraphsInChapter}',
                          style: TextStyle(
                            color: colors.secondaryText,
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    currentText,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: colors.text,
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),

            // Audio Controls (Previous, Play/Pause, Next)
            IconButton(
              icon: Icon(Icons.skip_previous_rounded, color: colors.text, size: 22),
              onPressed: session.previousAudioParagraph,
              tooltip: 'Previous paragraph',
            ),
            IconButton(
              icon: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: colors.accent,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  audioState.isPlaying
                      ? Icons.pause_rounded
                      : Icons.play_arrow_rounded,
                  color: Colors.white,
                  size: 20,
                ),
              ),
              onPressed: session.toggleAudioPlayPause,
              tooltip: audioState.isPlaying ? 'Pause' : 'Play',
            ),
            IconButton(
              icon: Icon(Icons.skip_next_rounded, color: colors.text, size: 22),
              onPressed: session.nextAudioParagraph,
              tooltip: 'Next paragraph',
            ),
          ],
        ),
      ),
    );
  }
}
