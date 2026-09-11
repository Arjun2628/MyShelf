import 'package:epub_audio/features/audio/presentation/screens/audiobook_player_screen.dart';
import 'package:epub_audio/features/epub/domain/entities/book.dart';
import 'package:epub_audio/features/library/data/datasources/hive_storage_service.dart';
import 'package:epub_audio/features/reader/domain/entities/reader_preferences.dart';
import 'package:epub_audio/features/reader/domain/entities/text_highlight.dart';
import 'package:epub_audio/features/reader/presentation/widgets/book_translation_modal.dart';
import 'package:epub_audio/features/reader/presentation/widgets/bookmarks_modal.dart';
import 'package:epub_audio/features/reader/presentation/widgets/highlights_modal.dart';
import 'package:epub_audio/features/reader/presentation/widgets/reader_content_view.dart';
import 'package:epub_audio/features/reader/presentation/widgets/reader_settings_modal.dart';
import 'package:epub_audio/features/reader/presentation/widgets/toc_drawer.dart';
import 'package:epub_audio/features/reader/presentation/widgets/translation_modal.dart';
import 'package:epub_audio/features/session/presentation/controllers/book_session_controller.dart';
import 'package:flutter/material.dart';

/// Fullscreen Reading Screen providing comfortable reading, audio narration, and controls.
class ReaderScreen extends StatefulWidget {
  final Book book;
  final int? initialChapterIndex;
  final int? initialParagraphIndex;

  const ReaderScreen({
    super.key,
    required this.book,
    this.initialChapterIndex,
    this.initialParagraphIndex,
  });

  @override
  State<ReaderScreen> createState() => _ReaderScreenState();
}

class _ReaderScreenState extends State<ReaderScreen> {
  late final BookSessionController _session;
  final ScrollController _scrollController = ScrollController();
  List<TextHighlight> _highlights = [];
  int _lastLoadedChapter = -1;

  @override
  void initState() {
    super.initState();
    _session = BookSessionController(
      book: widget.book,
      initialChapterIndex: widget.initialChapterIndex,
      initialParagraphIndex: widget.initialParagraphIndex,
    );
    _session.addListener(_onSessionUpdate);
    _loadHighlights();
  }

  void _loadHighlights() {
    _highlights = HiveStorageService().getHighlightsForChapter(
      widget.book.id,
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
    _session.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = _session.preferences.colors;
    final currentContent = _session.currentChapterContent;

    return Scaffold(
      backgroundColor: colors.background,
      body: Stack(
        children: [
          // 1. Main Reading Canvas
          SafeArea(
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
                            chapterIndex: _session.currentChapterIndex,
                            preferences: _session.preferences,
                            activeParagraphIndex: null,
                            charOffset: null,
                            isPlaying: false,
                            highlights: List<TextHighlight>.from(_highlights),
                            scrollController: _scrollController,
                            onParagraphTapped: null,
                            onLinkTapped: _session.handleLink,
                            onHighlightCreated: _onHighlightCreated,
                            onTranslateRequested: _showTranslationModal,
                            onSpeakTextRequested: (text) => _session.speakCustomText(text),
                          )
                        : const SizedBox.shrink(),
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

          // 3. Bottom Navigation (Overlay) - Clean Chapter Controls
          AnimatedPositioned(
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeInOut,
            bottom: _session.showControls ? 0 : -200,
            left: 0,
            right: 0,
            child: _buildBottomBar(colors),
          ),

          // 4. Quick Controls Pill (when overlay is hidden)
          if (!_session.showControls)
            Positioned(
              bottom: MediaQuery.of(context).padding.bottom + 16,
              right: 16,
              child: InkWell(
                onTap: _session.toggleControls,
                borderRadius: BorderRadius.circular(24),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: colors.cardBackground.withValues(alpha: 0.92),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: colors.divider),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.12),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.tune_rounded, size: 16, color: colors.accent),
                      const SizedBox(width: 6),
                      Text(
                        'Menu',
                        style: TextStyle(
                          color: colors.text,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
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
                if (_session.isTranslated)
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                          decoration: BoxDecoration(
                            color: const Color(0xFF3B82F6).withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(
                              color: const Color(0xFF3B82F6).withValues(alpha: 0.35),
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                '${_session.activeTranslationLanguageFlag} ${_session.activeTranslationLanguageName.split('(').first.trim()}',
                                style: const TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF2563EB),
                                ),
                              ),
                              const SizedBox(width: 4),
                              InkWell(
                                onTap: () => _session.revertToOriginalLanguage(),
                                child: const Icon(
                                  Icons.close_rounded,
                                  size: 11,
                                  color: Color(0xFF2563EB),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),

          // Full Chapter / Entire Book Translation
          IconButton(
            icon: Icon(
              Icons.translate_rounded,
              color: _session.isTranslated ? const Color(0xFF3B82F6) : colors.text,
            ),
            tooltip: _session.isTranslated
                ? 'Translated: ${_session.activeTranslationLanguageName}'
                : 'Translate Book & Audio',
            onPressed: _showBookTranslationModal,
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

          // Highlights & Notes
          IconButton(
            icon: Icon(Icons.border_color_outlined, color: colors.text),
            tooltip: 'Highlights & Notes',
            onPressed: _showHighlightsModal,
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

  Future<void> _onHighlightCreated(TextHighlight highlight) async {
    if (!_highlights.any((h) => h.id == highlight.id)) {
      _highlights.add(highlight);
    }
    setState(() {});

    await HiveStorageService().saveHighlight(highlight);
    _loadHighlights();
    if (mounted) setState(() {});

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  color: highlight.color,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 8),
              const Text('Highlight saved'),
            ],
          ),
          duration: const Duration(seconds: 1),
        ),
      );
    }
  }

  void _showTranslationModal(String text) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => TranslationModal(
        text: text,
        preferences: _session.preferences,
        bookLanguage: widget.book.metadata.language,
        onSaveAsNote: (translatedText) {
          final hl = TextHighlight(
            id: 'hl_${DateTime.now().millisecondsSinceEpoch}',
            bookId: widget.book.id,
            chapterIndex: _session.currentChapterIndex,
            selectedText: text,
            colorValue: Colors.amber.toARGB32(),
            createdAt: DateTime.now(),
            note: translatedText,
          );
          _onHighlightCreated(hl);
        },
      ),
    );
  }

  void _showHighlightsModal() {
    final bookHighlights = HiveStorageService().getHighlightsForBook(widget.book.id);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => FractionallySizedBox(
        heightFactor: 0.75,
        child: HighlightsModal(
          highlights: bookHighlights,
          preferences: _session.preferences,
          onHighlightSelected: (hl) {
            _session.loadChapter(hl.chapterIndex);
          },
          onHighlightDeleted: (hl) {
            HiveStorageService().deleteHighlight(hl.id);
            _loadHighlights();
            setState(() {});
          },
        ),
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
}
