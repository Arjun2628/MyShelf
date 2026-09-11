import 'package:epub_audio/features/audio/domain/entities/audio_playback_state.dart';
import 'package:epub_audio/features/library/data/datasources/hive_storage_service.dart';
import 'package:epub_audio/features/reader/domain/entities/reader_preferences.dart';
import 'package:epub_audio/features/reader/domain/entities/text_highlight.dart';
import 'package:epub_audio/features/reader/presentation/widgets/book_translation_modal.dart';
import 'package:epub_audio/features/reader/presentation/widgets/reader_content_view.dart';
import 'package:epub_audio/features/reader/presentation/widgets/toc_drawer.dart';
import 'package:epub_audio/features/reader/presentation/widgets/translation_modal.dart';
import 'package:epub_audio/features/session/presentation/controllers/book_session_controller.dart';
import 'package:flutter/material.dart';

/// Dedicated Fullscreen Audiobook Player Screen with Live Synchronized Reader & Word Highlighting.
class AudiobookPlayerScreen extends StatefulWidget {
  final BookSessionController session;

  const AudiobookPlayerScreen({super.key, required this.session});

  @override
  State<AudiobookPlayerScreen> createState() => _AudiobookPlayerScreenState();
}

class _AudiobookPlayerScreenState extends State<AudiobookPlayerScreen> {
  BookSessionController get _session => widget.session;

  int? _sliderDragIndex;
  bool _showLiveTranscript = true;
  final ScrollController _transcriptScrollController = ScrollController();
  List<TextHighlight> _highlights = [];
  int _lastLoadedChapter = -1;

  @override
  void initState() {
    super.initState();
    _session.addListener(_onSessionUpdate);
    _loadHighlights();
  }

  void _loadHighlights() {
    _highlights = HiveStorageService().getHighlightsForChapter(
      _session.book.id,
      _session.currentChapterIndex,
    );
    _lastLoadedChapter = _session.currentChapterIndex;
  }

  void _onSessionUpdate() {
    if (_lastLoadedChapter != _session.currentChapterIndex) {
      _loadHighlights();
    }
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _session.removeListener(_onSessionUpdate);
    _transcriptScrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = _session.preferences.colors;
    final book = _session.book;
    final audioState = _session.audioState;
    final currentChapterTitle =
        _session.currentChapterContent?.title ??
        'Chapter ${_session.currentChapterIndex + 1}';
    final currentParagraph =
        audioState.currentText ??
        (_session.currentChapterParagraphs.isNotEmpty
            ? _session.currentChapterParagraphs[_session.currentParagraphIndex
                  .clamp(0, _session.currentChapterParagraphs.length - 1)]
            : 'Ready to listen');

    final totalParagraphs = _session.currentChapterParagraphs.length;
    final activeParaIndex = _sliderDragIndex ?? _session.currentParagraphIndex;
    final currentParagraphNum = (activeParaIndex + 1).clamp(0, totalParagraphs);
    final currentContent = _session.currentChapterContent;

    return Scaffold(
      backgroundColor: colors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_rounded, color: colors.text),
          onPressed: () => Navigator.pop(context),
        ),
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Mode Toggle Switcher
            Container(
              padding: const EdgeInsets.all(3),
              decoration: BoxDecoration(
                color: colors.cardBackground,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: colors.divider),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  GestureDetector(
                    onTap: () {
                      setState(() {
                        _showLiveTranscript = true;
                      });
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: _showLiveTranscript
                            ? colors.accent
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.auto_stories_rounded,
                            size: 14,
                            color: _showLiveTranscript
                                ? Colors.white
                                : colors.secondaryText,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'Live Reading',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: _showLiveTranscript
                                  ? Colors.white
                                  : colors.secondaryText,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  GestureDetector(
                    onTap: () {
                      setState(() {
                        _showLiveTranscript = false;
                      });
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: !_showLiveTranscript
                            ? colors.accent
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.album_rounded,
                            size: 14,
                            color: !_showLiveTranscript
                                ? Colors.white
                                : colors.secondaryText,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'Cover Art',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: !_showLiveTranscript
                                  ? Colors.white
                                  : colors.secondaryText,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        centerTitle: true,
        actions: [
          // Translate Audiobook Button
          IconButton(
            icon: Icon(
              Icons.translate_rounded,
              color: _session.isTranslated ? colors.accent : colors.text,
            ),
            tooltip: _session.isTranslated
                ? 'Audiobook Translated'
                : 'Translate Audiobook',
            onPressed: _showBookTranslationModal,
          ),
          // Table of Contents
          IconButton(
            icon: Icon(Icons.menu_book_rounded, color: colors.text),
            tooltip: 'Table of Contents',
            onPressed: _showTocModal,
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
          child: Column(
            children: [
              // Header: Book & Chapter Info
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 2.0),
                child: Column(
                  children: [
                    Text(
                      book.metadata.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: colors.text,
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 1),
                    Text(
                      currentChapterTitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: colors.secondaryText,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 4),

              // Main Display: Full Synchronized ReaderContentView or Cover Art View
              Expanded(
                child: _showLiveTranscript
                    ? (currentContent != null
                          ? ReaderContentView(
                              content: currentContent,
                              book: _session.book,
                              chapterIndex: _session.currentChapterIndex,
                              preferences: _session.preferences,
                              activeParagraphIndex:
                                  _session.currentParagraphIndex,
                              charOffset: _session.currentPosition.charOffset,
                              isPlaying: audioState.isPlaying,
                              highlights: List<TextHighlight>.from(_highlights),
                              scrollController: _transcriptScrollController,
                              onParagraphTapped: (paraIdx) {
                                _session.seekToParagraph(
                                  paraIdx,
                                  autoPlay: true,
                                );
                              },
                              onLinkTapped: _session.handleLink,
                              onHighlightCreated: (hl) {
                                HiveStorageService().saveHighlight(hl);
                                _loadHighlights();
                                setState(() {});
                              },
                              onTranslateRequested: _showTranslationModal,
                              onSpeakTextRequested: (text) =>
                                  _session.speakCustomText(text),
                            )
                          : Center(
                              child: CircularProgressIndicator(
                                color: colors.accent,
                              ),
                            ))
                    : _buildCoverArtView(
                        colors,
                        book,
                        currentParagraph,
                        audioState,
                      ),
              ),

              const SizedBox(height: 8),

              // Scrubber / Paragraph Slider
              Row(
                children: [
                  Text(
                    'P $currentParagraphNum',
                    style: TextStyle(
                      color: colors.secondaryText,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Expanded(
                    child: Slider(
                      value: activeParaIndex.toDouble().clamp(
                        0,
                        (totalParagraphs > 0 ? totalParagraphs - 1 : 0)
                            .toDouble(),
                      ),
                      min: 0,
                      max: (totalParagraphs > 0 ? totalParagraphs - 1 : 0)
                          .toDouble(),
                      divisions: totalParagraphs > 1 ? totalParagraphs - 1 : 1,
                      activeColor: colors.accent,
                      inactiveColor: colors.divider,
                      onChanged: (val) {
                        setState(() {
                          _sliderDragIndex = val.round();
                        });
                      },
                      onChangeEnd: (val) {
                        final target = _sliderDragIndex ?? val.round();
                        setState(() {
                          _sliderDragIndex = null;
                        });
                        _session.seekToParagraph(target, autoPlay: true);
                      },
                    ),
                  ),
                  Text(
                    'P $totalParagraphs',
                    style: TextStyle(
                      color: colors.secondaryText,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),

              // Main Audio Playback Controls: Clean, Centered Previous / Play-Pause / Next
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 4.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    IconButton(
                      iconSize: 38,
                      padding: const EdgeInsets.all(12),
                      icon: Icon(
                        Icons.skip_previous_rounded,
                        color: colors.text,
                      ),
                      tooltip: 'Previous Paragraph',
                      onPressed: _session.previousAudioParagraph,
                    ),
                    const SizedBox(width: 24),
                    GestureDetector(
                      onTap: _session.toggleAudioPlayPause,
                      child: Container(
                        width: 68,
                        height: 68,
                        decoration: BoxDecoration(
                          color: colors.accent,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: colors.accent.withValues(alpha: 0.35),
                              blurRadius: 18,
                              offset: const Offset(0, 6),
                            ),
                          ],
                        ),
                        child: Icon(
                          audioState.isPlaying
                              ? Icons.pause_rounded
                              : Icons.play_arrow_rounded,
                          color: Colors.white,
                          size: 38,
                        ),
                      ),
                    ),
                    const SizedBox(width: 24),
                    IconButton(
                      iconSize: 38,
                      padding: const EdgeInsets.all(12),
                      icon: Icon(Icons.skip_next_rounded, color: colors.text),
                      tooltip: 'Next Paragraph',
                      onPressed: _session.nextAudioParagraph,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 6),

              // Secondary Options (Speed, Sleep Timer, Translate, Return to Reader)
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  // Speed Selector Chip
                  TextButton.icon(
                    icon: Icon(
                      Icons.speed_rounded,
                      size: 18,
                      color: colors.text,
                    ),
                    label: Text(
                      '${audioState.speechRate.toStringAsFixed(2).replaceAll('.00', '')}x',
                      style: TextStyle(
                        color: colors.text,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    onPressed: _showSpeedModal,
                  ),

                  // Sleep Timer
                  TextButton.icon(
                    icon: Icon(
                      audioState.sleepTimerRemaining != null
                          ? Icons.snooze_rounded
                          : Icons.bedtime_outlined,
                      size: 18,
                      color: audioState.sleepTimerRemaining != null
                          ? colors.accent
                          : colors.text,
                    ),
                    label: Text(
                      audioState.sleepTimerRemaining != null
                          ? _formatDuration(audioState.sleepTimerRemaining!)
                          : 'Sleep',
                      style: TextStyle(
                        color: audioState.sleepTimerRemaining != null
                            ? colors.accent
                            : colors.text,
                      ),
                    ),
                    onPressed: _showSleepTimerModal,
                  ),

                  // // Translate Quick Action
                  // TextButton.icon(
                  //   icon: Icon(
                  //     Icons.translate_rounded,
                  //     size: 18,
                  //     color: _session.isTranslated ? colors.accent : colors.text,
                  //   ),
                  //   label: Text(
                  //     _session.isTranslated ? 'Translated' : 'Translate',
                  //     style: TextStyle(
                  //       color: _session.isTranslated ? colors.accent : colors.text,
                  //       fontWeight: _session.isTranslated ? FontWeight.bold : FontWeight.normal,
                  //     ),
                  //   ),
                  //   onPressed: _showBookTranslationModal,
                  // ),

                  // Return to Quiet Reader
                  OutlinedButton.icon(
                    icon: Icon(
                      Icons.auto_stories_rounded,
                      size: 16,
                      color: colors.accent,
                    ),
                    label: Text(
                      'Reader',
                      style: TextStyle(color: colors.accent, fontSize: 13),
                    ),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      side: BorderSide(
                        color: colors.accent.withValues(alpha: 0.5),
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),

              const SizedBox(height: 4),
            ],
          ),
        ),
      ),
    );
  }

  void _showTranslationModal(String text) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => TranslationModal(
        text: text,
        preferences: _session.preferences,
        bookLanguage: widget.session.book.metadata.language,
        onSaveAsNote: (translatedText) {
          final hl = TextHighlight(
            id: 'hl_${DateTime.now().millisecondsSinceEpoch}',
            bookId: widget.session.book.id,
            chapterIndex: _session.currentChapterIndex,
            selectedText: text,
            colorValue: Colors.amber.toARGB32(),
            createdAt: DateTime.now(),
            note: translatedText,
          );
          HiveStorageService().saveHighlight(hl);
          _loadHighlights();
          setState(() {});
        },
      ),
    );
  }

  void _showBookTranslationModal() {
    BookTranslationModal.show(
      context,
      session: _session,
      preferences: _session.preferences,
    );
  }

  Widget _buildCoverArtView(
    ReaderThemeColors colors,
    dynamic book,
    String currentParagraph,
    AudioPlaybackState audioState,
  ) {
    return Center(
      child: SingleChildScrollView(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 160,
              height: 220,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(18),
                boxShadow: [
                  BoxShadow(
                    color: colors.accent.withValues(alpha: 0.2),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(18),
                child: book.coverImageBytes != null
                    ? Image.memory(
                        book.coverImageBytes!,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) =>
                            _buildDefaultCover(colors),
                      )
                    : _buildDefaultCover(colors),
              ),
            ),
            const SizedBox(height: 14),
            Container(
              constraints: const BoxConstraints(maxHeight: 75),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: audioState.isPlaying
                    ? colors.accent.withValues(alpha: 0.10)
                    : colors.cardBackground,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: audioState.isPlaying
                      ? colors.accent
                      : colors.accent.withValues(alpha: 0.3),
                  width: audioState.isPlaying ? 1.5 : 1.0,
                ),
              ),
              child: Center(
                child: SingleChildScrollView(
                  child: Text(
                    '"$currentParagraph"',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: audioState.isPlaying ? colors.accent : colors.text,
                      fontSize: 13,
                      fontWeight: audioState.isPlaying
                          ? FontWeight.w600
                          : FontWeight.normal,
                      fontStyle: FontStyle.italic,
                      height: 1.3,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDefaultCover(ReaderThemeColors colors) {
    final hash = _session.book.metadata.title.hashCode;
    final color1 = HSLColor.fromAHSL(
      1.0,
      (hash.abs() % 360).toDouble(),
      0.65,
      0.45,
    ).toColor();
    final color2 = HSLColor.fromAHSL(
      1.0,
      ((hash.abs() + 40) % 360).toDouble(),
      0.75,
      0.35,
    ).toColor();

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [color1, color2],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.headphones_rounded,
            color: Colors.white.withValues(alpha: 0.8),
            size: 48,
          ),
          const SizedBox(height: 12),
          Text(
            _session.book.metadata.title,
            textAlign: TextAlign.center,
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }

  void _showSpeedModal() {
    final colors = _session.preferences.colors;
    final currentSpeed = _session.audioState.speechRate;
    final speeds = [0.5, 0.65, 0.75, 0.85, 1.0, 1.25, 1.5, 2.0];

    showModalBottomSheet(
      context: context,
      backgroundColor: colors.cardBackground,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Narration Speed',
              style: TextStyle(
                color: colors.text,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: speeds.map((speed) {
                final isSelected = currentSpeed == speed;
                return ChoiceChip(
                  label: Text('${speed}x'),
                  selected: isSelected,
                  selectedColor: colors.accent,
                  labelStyle: TextStyle(
                    color: isSelected ? Colors.white : colors.text,
                    fontWeight: FontWeight.bold,
                  ),
                  onSelected: (selected) {
                    Navigator.pop(context);
                    _session.setAudioSpeed(speed);
                  },
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  void _showSleepTimerModal() {
    final colors = _session.preferences.colors;
    final options = [
      {'label': 'Off', 'duration': null},
      {'label': '15 minutes', 'duration': const Duration(minutes: 15)},
      {'label': '30 minutes', 'duration': const Duration(minutes: 30)},
      {'label': '45 minutes', 'duration': const Duration(minutes: 45)},
      {'label': '60 minutes', 'duration': const Duration(minutes: 60)},
    ];

    showModalBottomSheet(
      context: context,
      backgroundColor: colors.cardBackground,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Sleep Timer',
              style: TextStyle(
                color: colors.text,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            ...options.map((opt) {
              final label = opt['label'] as String;
              final duration = opt['duration'] as Duration?;
              return ListTile(
                title: Text(label, style: TextStyle(color: colors.text)),
                trailing: Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: 14,
                  color: colors.secondaryText,
                ),
                onTap: () {
                  Navigator.pop(context);
                  _session.setSleepTimer(duration);
                },
              );
            }),
          ],
        ),
      ),
    );
  }

  void _showTocModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => FractionallySizedBox(
        heightFactor: 0.75,
        child: TocDrawer(
          book: _session.book,
          currentChapterIndex: _session.currentChapterIndex,
          preferences: _session.preferences,
          onChapterSelected: (index, {anchorId}) {
            _session.loadChapter(index, targetAnchor: anchorId);
          },
        ),
      ),
    );
  }

  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds % 60;
    return '${minutes}m ${seconds}s';
  }
}
