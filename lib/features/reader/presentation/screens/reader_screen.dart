import 'package:epub_audio/features/audio/presentation/screens/audiobook_player_screen.dart';
import 'package:epub_audio/features/audio/presentation/widgets/mini_audio_player.dart';
import 'package:epub_audio/features/epub/domain/entities/book.dart';
import 'package:epub_audio/features/reader/domain/entities/reader_preferences.dart';
import 'package:epub_audio/features/reader/presentation/widgets/bookmarks_modal.dart';
import 'package:epub_audio/features/reader/presentation/widgets/reader_content_view.dart';
import 'package:epub_audio/features/reader/presentation/widgets/reader_settings_modal.dart';
import 'package:epub_audio/features/reader/presentation/widgets/toc_drawer.dart';
import 'package:epub_audio/features/session/presentation/controllers/book_session_controller.dart';
import 'package:flutter/material.dart';

/// Fullscreen Reading Screen providing comfortable reading, audio narration, and controls.
class ReaderScreen extends StatefulWidget {
  final Book book;
  final int initialChapterIndex;
  final int initialParagraphIndex;

  const ReaderScreen({
    super.key,
    required this.book,
    this.initialChapterIndex = 0,
    this.initialParagraphIndex = 0,
  });

  @override
  State<ReaderScreen> createState() => _ReaderScreenState();
}

class _ReaderScreenState extends State<ReaderScreen> {
  late final BookSessionController _session;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _session = BookSessionController(
      book: widget.book,
      initialChapterIndex: widget.initialChapterIndex,
      initialParagraphIndex: widget.initialParagraphIndex,
    );
    _session.addListener(_onSessionUpdate);
  }

  void _onSessionUpdate() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _session.removeListener(_onSessionUpdate);
    _session.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = _session.preferences.colors;
    final currentContent = _session.currentChapterContent;
    final audioPlaying = _session.audioState.isPlaying;

    return Scaffold(
      backgroundColor: colors.background,
      body: Stack(
        children: [
          // 1. Main Reading Canvas
          GestureDetector(
            onTap: _session.toggleControls,
            behavior: HitTestBehavior.translucent,
            child: SafeArea(
              child: _session.isLoading
                  ? Center(
                      child: CircularProgressIndicator(color: colors.accent),
                    )
                  : _session.errorMessage != null
                      ? _buildErrorState(colors)
                      : currentContent != null
                          ? ReaderContentView(
                              content: currentContent,
                              book: _session.book,
                              preferences: _session.preferences,
                              activeParagraphIndex: audioPlaying
                                  ? _session.currentParagraphIndex
                                  : null,
                              scrollController: _scrollController,
                              onParagraphTapped: (paraIdx) {
                                _session.seekToParagraph(paraIdx);
                                if (!audioPlaying) {
                                  _session.playAudio();
                                }
                              },
                              onLinkTapped: _session.handleLink,
                            )
                          : const SizedBox.shrink(),
            ),
          ),

          // 2. Top Navigation Bar (Overlay)
          AnimatedPositioned(
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeInOut,
            top: _session.showControls ? 0 : -100,
            left: 0,
            right: 0,
            child: _buildTopBar(colors),
          ),

          // 3. Bottom Navigation & Mini Player (Overlay)
          AnimatedPositioned(
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeInOut,
            bottom: _session.showControls ? 0 : -200,
            left: 0,
            right: 0,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Docked Mini Audiobook Player
                MiniAudioPlayer(
                  session: _session,
                  preferences: _session.preferences,
                  onExpand: _openAudiobookPlayer,
                ),
                _buildBottomBar(colors),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopBar(ReaderThemeColors colors) {
    final currentTitle = _session.currentChapterContent?.title ??
        _session.book.metadata.title;

    return Container(
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 6,
        left: 8,
        right: 8,
        bottom: 8,
      ),
      decoration: BoxDecoration(
        color: colors.cardBackground.withValues(alpha: 0.95),
        border: Border(bottom: BorderSide(color: colors.divider)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          IconButton(
            icon: Icon(Icons.arrow_back_rounded, color: colors.text),
            onPressed: () => Navigator.pop(context),
          ),
          const SizedBox(width: 4),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  _session.book.metadata.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: colors.text,
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  currentTitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: colors.secondaryText,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),

          // Switch to Fullscreen Audiobook Mode
          IconButton(
            icon: Icon(
              _session.audioState.isPlaying
                  ? Icons.graphic_eq_rounded
                  : Icons.headphones_outlined,
              color: _session.audioState.isPlaying ? colors.accent : colors.text,
            ),
            tooltip: 'Audiobook Player',
            onPressed: _openAudiobookPlayer,
          ),

          // Bookmark Button
          IconButton(
            icon: Icon(
              _session.isCurrentChapterBookmarked
                  ? Icons.bookmark_rounded
                  : Icons.bookmark_border_rounded,
              color: _session.isCurrentChapterBookmarked
                  ? colors.accent
                  : colors.text,
            ),
            tooltip: 'Bookmark',
            onPressed: _session.toggleBookmark,
          ),

          // Bookmarks List
          IconButton(
            icon: Icon(Icons.bookmarks_outlined, color: colors.text),
            tooltip: 'Bookmarks List',
            onPressed: _showBookmarksModal,
          ),

          // Appearance Settings
          IconButton(
            icon: Icon(Icons.text_format_rounded, color: colors.text),
            tooltip: 'Appearance',
            onPressed: _showSettingsModal,
          ),
        ],
      ),
    );
  }

  Widget _buildBottomBar(ReaderThemeColors colors) {
    final progress = (_session.readingProgress * 100).round();

    return Container(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 10,
        bottom: MediaQuery.of(context).padding.bottom + 12,
      ),
      decoration: BoxDecoration(
        color: colors.cardBackground.withValues(alpha: 0.95),
        border: Border(top: BorderSide(color: colors.divider)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Chapter Progress Slider
          Row(
            children: [
              Text(
                'Ch ${_session.currentChapterIndex + 1}',
                style: TextStyle(
                  color: colors.secondaryText,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Expanded(
                child: Slider(
                  value: _session.currentChapterIndex.toDouble(),
                  min: 0,
                  max: (_session.book.chapterCount - 1).toDouble().clamp(0, double.infinity),
                  divisions: _session.book.chapterCount > 1
                      ? _session.book.chapterCount - 1
                      : 1,
                  activeColor: colors.accent,
                  inactiveColor: colors.divider,
                  onChanged: (val) {
                    _session.loadChapter(val.round());
                  },
                ),
              ),
              Text(
                '$progress%',
                style: TextStyle(
                  color: colors.secondaryText,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),

          // Prev / TOC / Next Actions
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              TextButton.icon(
                icon: Icon(Icons.arrow_back_ios_new_rounded, size: 16, color: colors.text),
                label: Text('Prev', style: TextStyle(color: colors.text)),
                onPressed: _session.hasPreviousChapter
                    ? _session.previousChapter
                    : null,
              ),
              OutlinedButton.icon(
                icon: Icon(Icons.menu_book_rounded, size: 18, color: colors.accent),
                label: Text('Contents', style: TextStyle(color: colors.accent)),
                style: OutlinedButton.styleFrom(
                  side: BorderSide(color: colors.accent.withValues(alpha: 0.5)),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                ),
                onPressed: _showTocModal,
              ),
              TextButton.icon(
                icon: Text('Next', style: TextStyle(color: colors.text)),
                label: Icon(Icons.arrow_forward_ios_rounded, size: 16, color: colors.text),
                onPressed: _session.hasNextChapter
                    ? _session.nextChapter
                    : null,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(ReaderThemeColors colors) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline_rounded, size: 48, color: Colors.redAccent),
            const SizedBox(height: 16),
            Text(
              _session.errorMessage ?? 'An error occurred',
              textAlign: TextAlign.center,
              style: TextStyle(color: colors.text, fontSize: 16),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: colors.accent,
                foregroundColor: Colors.white,
              ),
              onPressed: () => _session.loadChapter(_session.currentChapterIndex),
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  void _openAudiobookPlayer() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AudiobookPlayerScreen(session: _session),
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

  void _showSettingsModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => ReaderSettingsModal(
        preferences: _session.preferences,
        onPreferencesChanged: (newPrefs) {
          _session.updatePreferences(newPrefs);
        },
      ),
    );
  }

  void _showBookmarksModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => FractionallySizedBox(
        heightFactor: 0.6,
        child: BookmarksModal(
          bookmarks: _session.bookmarks,
          preferences: _session.preferences,
          onBookmarkSelected: (bm) {
            _session.loadChapter(bm.chapterIndex, targetAnchor: bm.anchorId);
          },
          onBookmarkDeleted: (bm) {
            _session.deleteBookmark(bm);
          },
        ),
      ),
    );
  }
}
