import 'package:epub_audio/features/epub/domain/entities/book.dart';
import 'package:epub_audio/features/epub/domain/entities/toc_entry.dart';
import 'package:epub_audio/features/reader/domain/entities/reader_preferences.dart';
import 'package:flutter/material.dart';

/// Table of Contents bottom sheet / drawer for book navigation.
class TocDrawer extends StatelessWidget {
  final Book book;
  final int currentChapterIndex;
  final ReaderPreferences preferences;
  final void Function(int chapterIndex, {String? anchorId}) onChapterSelected;

  const TocDrawer({
    super.key,
    required this.book,
    required this.currentChapterIndex,
    required this.preferences,
    required this.onChapterSelected,
  });

  @override
  Widget build(BuildContext context) {
    final colors = preferences.colors;

    return Container(
      decoration: BoxDecoration(
        color: colors.cardBackground,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
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
                      'Table of Contents',
                      style: TextStyle(
                        color: colors.text,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      '${book.chapterCount} chapters',
                      style: TextStyle(
                        color: colors.secondaryText,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Divider(color: colors.divider, height: 1),

          // Chapter List
          Expanded(
            child: ListView.separated(
              itemCount: book.toc.isNotEmpty ? book.toc.length : book.chapterCount,
              separatorBuilder: (context, index) => Divider(
                color: colors.divider.withValues(alpha: 0.5),
                height: 1,
                indent: 16,
                endIndent: 16,
              ),
              itemBuilder: (context, index) {
                if (book.toc.isNotEmpty) {
                  final entry = book.toc[index];
                  return _buildTocTile(context, entry, 0, colors);
                } else {
                  // Fallback spine items
                  final isCurrent = index == currentChapterIndex;
                  return ListTile(
                    title: Text(
                      'Chapter ${index + 1}',
                      style: TextStyle(
                        color: isCurrent ? colors.accent : colors.text,
                        fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                    trailing: isCurrent
                        ? Icon(Icons.bookmark_rounded, color: colors.accent, size: 20)
                        : null,
                    onTap: () {
                      Navigator.pop(context);
                      onChapterSelected(index);
                    },
                  );
                }
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTocTile(
    BuildContext context,
    TocEntry entry,
    int depth,
    ReaderThemeColors colors,
  ) {
    // Find matching spine index for this TOC item
    final spineIndex = _findSpineIndexForPath(entry.fullPath);
    final isCurrent = spineIndex == currentChapterIndex;

    if (entry.children.isEmpty) {
      return ListTile(
        contentPadding: EdgeInsets.only(left: 20.0 + (depth * 16.0), right: 20.0),
        leading: Icon(
          isCurrent ? Icons.play_arrow_rounded : Icons.article_outlined,
          color: isCurrent ? colors.accent : colors.secondaryText,
          size: 20,
        ),
        title: Text(
          entry.title,
          style: TextStyle(
            color: isCurrent ? colors.accent : colors.text,
            fontWeight: isCurrent ? FontWeight.w600 : FontWeight.normal,
            fontSize: depth == 0 ? 15 : 14,
          ),
        ),
        onTap: () {
          Navigator.pop(context);
          if (spineIndex != null) {
            onChapterSelected(spineIndex, anchorId: entry.anchor);
          }
        },
      );
    }

    return ExpansionTile(
      tilePadding: EdgeInsets.only(left: 20.0 + (depth * 16.0), right: 20.0),
      leading: Icon(
        isCurrent ? Icons.play_arrow_rounded : Icons.folder_open_outlined,
        color: isCurrent ? colors.accent : colors.secondaryText,
        size: 20,
      ),
      title: Text(
        entry.title,
        style: TextStyle(
          color: isCurrent ? colors.accent : colors.text,
          fontWeight: isCurrent ? FontWeight.w600 : FontWeight.normal,
        ),
      ),
      children: entry.children
          .map((child) => _buildTocTile(context, child, depth + 1, colors))
          .toList(),
    );
  }

  int? _findSpineIndexForPath(String fullPath) {
    for (int i = 0; i < book.spine.length; i++) {
      if (book.spine[i].fullPath == fullPath) {
        return i;
      }
    }
    return null;
  }
}
