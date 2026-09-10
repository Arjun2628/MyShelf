import 'package:epub_audio/features/reader/domain/entities/bookmark.dart';
import 'package:epub_audio/features/reader/domain/entities/reader_preferences.dart';
import 'package:flutter/material.dart';

/// Modal displaying the list of user bookmarks for the current book.
class BookmarksModal extends StatelessWidget {
  final List<Bookmark> bookmarks;
  final ReaderPreferences preferences;
  final ValueChanged<Bookmark> onBookmarkSelected;
  final ValueChanged<Bookmark> onBookmarkDeleted;

  const BookmarksModal({
    super.key,
    required this.bookmarks,
    required this.preferences,
    required this.onBookmarkSelected,
    required this.onBookmarkDeleted,
  });

  @override
  Widget build(BuildContext context) {
    final colors = preferences.colors;

    return Container(
      decoration: BoxDecoration(
        color: colors.cardBackground,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag Handle & Header
          Container(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
            child: Column(
              children: [
                Center(
                  child: Container(
                    width: 36,
                    height: 4,
                    decoration: BoxDecoration(
                      color: colors.secondaryText.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Bookmarks (${bookmarks.length})',
                      style: TextStyle(
                        color: colors.text,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Divider(color: colors.divider, height: 1),

          if (bookmarks.isEmpty)
            Padding(
              padding: const EdgeInsets.all(48.0),
              child: Column(
                children: [
                  Icon(
                    Icons.bookmark_border_rounded,
                    size: 48,
                    color: colors.secondaryText.withValues(alpha: 0.5),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'No bookmarks yet',
                    style: TextStyle(
                      color: colors.secondaryText,
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Tap the bookmark icon on the top bar while reading.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: colors.secondaryText.withValues(alpha: 0.7),
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            )
          else
            Flexible(
              child: ListView.separated(
                shrinkWrap: true,
                itemCount: bookmarks.length,
                separatorBuilder: (context, index) => Divider(
                  color: colors.divider.withValues(alpha: 0.5),
                  height: 1,
                  indent: 16,
                  endIndent: 16,
                ),
                itemBuilder: (context, index) {
                  final bookmark = bookmarks[index];
                  return ListTile(
                    leading: Icon(
                      Icons.bookmark_rounded,
                      color: colors.accent,
                    ),
                    title: Text(
                      bookmark.chapterTitle,
                      style: TextStyle(
                        color: colors.text,
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                      ),
                    ),
                    subtitle: Text(
                      bookmark.snippet,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: colors.secondaryText,
                        fontSize: 13,
                      ),
                    ),
                    trailing: IconButton(
                      icon: Icon(
                        Icons.delete_outline_rounded,
                        color: colors.secondaryText,
                        size: 20,
                      ),
                      onPressed: () => onBookmarkDeleted(bookmark),
                    ),
                    onTap: () {
                      Navigator.pop(context);
                      onBookmarkSelected(bookmark);
                    },
                  );
                },
              ),
            ),
        ],
      ),
    );
  }
}
