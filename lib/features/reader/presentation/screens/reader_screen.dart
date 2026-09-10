import 'package:epub_audio/features/epub/domain/entities/book.dart';
import 'package:epub_audio/features/reader/presentation/controllers/reader_controller.dart';
import 'package:epub_audio/features/reader/presentation/widgets/bookmarks_modal.dart';
import 'package:epub_audio/features/reader/presentation/widgets/reader_content_view.dart';
import 'package:epub_audio/features/reader/presentation/widgets/reader_settings_modal.dart';
import 'package:epub_audio/features/reader/presentation/widgets/toc_drawer.dart';
import 'package:flutter/material.dart';

/// Fullscreen Reading Screen providing comfortable reading and navigation controls.
class ReaderScreen extends StatefulWidget {
  final Book book;
  final int initialChapterIndex;

  const ReaderScreen({
    super.key,
    required this.book,
    this.initialChapterIndex = 0,
  });

  @override
  State<ReaderScreen> createState() => _ReaderScreenState();
}

class _ReaderScreenState extends State<ReaderScreen> {
  late final ReaderController _controller;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _controller = ReaderController(
      book: widget.book,
      initialChapterIndex: widget.initialChapterIndex,
    );
    _controller.addListener(_onControllerUpdate);
  }

  void _onControllerUpdate() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _controller.removeListener(_onControllerUpdate);
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = _controller.preferences.colors;
    final currentContent = _controller.currentChapterContent;

    return Scaffold(
      backgroundColor: colors.background,
      body: Stack(
        children: [
          // 1. Main Reading Canvas
          GestureDetector(
            onTap: _controller.toggleControls,
            behavior: HitTestBehavior.translucent,
            child: SafeArea(
              child: _controller.isLoading
                  ? Center(
                      child: CircularProgressIndicator(color: colors.accent),
                    )
                  : _controller.errorMessage != null
                      ? _buildErrorState(colors)
                      : currentContent != null
                          ? ReaderContentView(
                              content: currentContent,
                              book: _controller.book,
                              preferences: _controller.preferences,
                              scrollController: _scrollController,
                              onLinkTapped: _controller.handleLink,
                            )
                          : const SizedBox.shrink(),
            ),
          ),

          // 2. Top Navigation Bar (Overlay)
          AnimatedPositioned(
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeInOut,
            top: _controller.showControls ? 0 : -100,
            left: 0,
            right: 0,
            child: _buildTopBar(colors),
          ),

          // 3. Bottom Controls (Overlay)
          AnimatedPositioned(
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeInOut,
            bottom: _controller.showControls ? 0 : -140,
            left: 0,
            right: 0,
            child: _buildBottomBar(colors),
          ),
        ],
      ),
    );
  }

  Widget _buildTopBar(colors) {
    final currentTitle = _controller.currentChapterContent?.title ??
        _controller.book.metadata.title;

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
                  _controller.book.metadata.title,
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
          IconButton(
            icon: Icon(
              _controller.isCurrentChapterBookmarked
                  ? Icons.bookmark_rounded
                  : Icons.bookmark_border_rounded,
              color: _controller.isCurrentChapterBookmarked
                  ? colors.accent
                  : colors.text,
            ),
            tooltip: 'Bookmark',
            onPressed: _controller.toggleBookmark,
          ),
          IconButton(
            icon: Icon(Icons.bookmarks_outlined, color: colors.text),
            tooltip: 'Bookmarks List',
            onPressed: _showBookmarksModal,
          ),
          IconButton(
            icon: Icon(Icons.text_format_rounded, color: colors.text),
            tooltip: 'Appearance',
            onPressed: _showSettingsModal,
          ),
        ],
      ),
    );
  }

  Widget _buildBottomBar(colors) {
    final progress = (_controller.readingProgress * 100).round();

    return Container(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 12,
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
          // Chapter Slider
          Row(
            children: [
              Text(
                'Ch ${_controller.currentChapterIndex + 1}',
                style: TextStyle(
                  color: colors.secondaryText,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Expanded(
                child: Slider(
                  value: _controller.currentChapterIndex.toDouble(),
                  min: 0,
                  max: (_controller.book.chapterCount - 1).toDouble().clamp(0, double.infinity),
                  divisions: _controller.book.chapterCount > 1
                      ? _controller.book.chapterCount - 1
                      : 1,
                  activeColor: colors.accent,
                  inactiveColor: colors.divider,
                  onChanged: (val) {
                    _controller.loadChapter(val.round());
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
                onPressed: _controller.hasPreviousChapter
                    ? _controller.previousChapter
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
                onPressed: _controller.hasNextChapter
                    ? _controller.nextChapter
                    : null,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(colors) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline_rounded, size: 48, color: Colors.redAccent),
            const SizedBox(height: 16),
            Text(
              _controller.errorMessage ?? 'An error occurred',
              textAlign: TextAlign.center,
              style: TextStyle(color: colors.text, fontSize: 16),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: colors.accent,
                foregroundColor: Colors.white,
              ),
              onPressed: () => _controller.loadChapter(_controller.currentChapterIndex),
              child: const Text('Retry'),
            ),
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
          book: _controller.book,
          currentChapterIndex: _controller.currentChapterIndex,
          preferences: _controller.preferences,
          onChapterSelected: (index, {anchorId}) {
            _controller.loadChapter(index, targetAnchor: anchorId);
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
        preferences: _controller.preferences,
        onPreferencesChanged: (newPrefs) {
          _controller.updatePreferences(newPrefs);
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
          bookmarks: _controller.bookmarks,
          preferences: _controller.preferences,
          onBookmarkSelected: (bm) {
            _controller.loadChapter(bm.chapterIndex, targetAnchor: bm.anchorId);
          },
          onBookmarkDeleted: (bm) {
            _controller.deleteBookmark(bm);
          },
        ),
      ),
    );
  }
}
