import 'package:flutter/material.dart';
import 'package:epub_audio/features/explore/domain/entities/book_shelf.dart';

class EditShelfModal extends StatefulWidget {
  final BookShelf? shelf;
  final Function(BookShelf updatedShelf) onSave;
  final VoidCallback? onDelete;

  const EditShelfModal({
    super.key,
    this.shelf,
    required this.onSave,
    this.onDelete,
  });

  static Future<void> show(
    BuildContext context, {
    BookShelf? shelf,
    required Function(BookShelf updatedShelf) onSave,
    VoidCallback? onDelete,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => EditShelfModal(
        shelf: shelf,
        onSave: onSave,
        onDelete: onDelete,
      ),
    );
  }

  @override
  State<EditShelfModal> createState() => _EditShelfModalState();
}

class _EditShelfModalState extends State<EditShelfModal> {
  late TextEditingController _titleController;
  late TextEditingController _subtitleController;
  late ShelfDisplayStyle _selectedStyle;
  late String? _selectedCategory;
  late List<String> _bookIds;

  final List<String> _availableBooks = [
    'sample_chemmeen',
    'sample_alice',
    'book_sherlock',
    'book_starlight',
    'book_dracula',
    'book_indulekha',
    'book_balyakalasakhi',
    'book_timemachine',
    'book_artofwar',
  ];

  @override
  void initState() {
    super.initState();
    final initial = widget.shelf;
    _titleController = TextEditingController(text: initial?.title ?? 'New Curated Shelf');
    _subtitleController = TextEditingController(text: initial?.subtitle ?? 'Featured collection');
    _selectedStyle = initial?.displayStyle ?? ShelfDisplayStyle.horizontalShelf;
    _selectedCategory = initial?.categoryId;
    _bookIds = List.from(initial?.bookIds ?? ['sample_chemmeen', 'book_sherlock']);
  }

  @override
  void dispose() {
    _titleController.dispose();
    _subtitleController.dispose();
    super.dispose();
  }

  void _handleSave() {
    if (_titleController.text.trim().isEmpty) return;

    final updated = BookShelf(
      id: widget.shelf?.id ?? 'shelf_${DateTime.now().millisecondsSinceEpoch}',
      title: _titleController.text.trim(),
      subtitle: _subtitleController.text.trim().isEmpty ? null : _subtitleController.text.trim(),
      displayStyle: _selectedStyle,
      categoryId: _selectedCategory,
      bookIds: _bookIds.isEmpty ? ['sample_chemmeen'] : _bookIds,
    );

    widget.onSave(updated);
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgGradient = isDark
        ? [const Color(0xFF141724), const Color(0xFF1E212B)]
        : [const Color(0xFFFAF4EA), Colors.white];
    final textColor = isDark ? Colors.white : const Color(0xFF1E1812);
    final subColor = isDark ? Colors.white60 : Colors.black54;
    final cardBg = isDark ? const Color(0xFF262A36) : const Color(0xFFF3EBE0);
    final borderCol = isDark ? Colors.white12 : Colors.black12;

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.88,
        ),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: bgGradient,
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          border: Border.all(color: borderCol),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.4),
              blurRadius: 30,
              offset: const Offset(0, -10),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Drag handle
            Center(
              child: Container(
                margin: const EdgeInsets.only(top: 12, bottom: 8),
                width: 44,
                height: 4.5,
                decoration: BoxDecoration(
                  color: isDark ? Colors.white24 : Colors.black12,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),

            // Header Title
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              child: Row(
                children: [
                  const Icon(Icons.dashboard_customize_rounded, color: Color(0xFF8B5CF6), size: 22),
                  const SizedBox(width: 10),
                  Text(
                    widget.shelf == null ? 'Create Curated Shelf' : 'Edit Curated Shelf',
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                      color: textColor,
                    ),
                  ),
                  const Spacer(),
                  if (widget.onDelete != null)
                    IconButton(
                      icon: const Icon(Icons.delete_outline_rounded, color: Color(0xFFEF4444), size: 20),
                      onPressed: () {
                        widget.onDelete!();
                        Navigator.of(context).pop();
                      },
                    ),
                ],
              ),
            ),

            Flexible(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                shrinkWrap: true,
                children: [
                  // Title Input
                  TextField(
                    controller: _titleController,
                    style: TextStyle(color: textColor, fontSize: 14),
                    decoration: _inputDecoration('Shelf Title', Icons.title_rounded, cardBg, borderCol),
                  ),
                  const SizedBox(height: 10),

                  // Subtitle Input
                  TextField(
                    controller: _subtitleController,
                    style: TextStyle(color: textColor, fontSize: 14),
                    decoration: _inputDecoration('Subtitle / Tagline', Icons.subtitles_rounded, cardBg, borderCol),
                  ),
                  const SizedBox(height: 16),

                  // Display Style Selector
                  Text(
                    'Shelf Display Style',
                    style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold, color: subColor),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: ShelfDisplayStyle.values.map((style) {
                      final isSelected = _selectedStyle == style;
                      return ChoiceChip(
                        label: Text(_formatStyleName(style)),
                        selected: isSelected,
                        selectedColor: const Color(0xFF8B5CF6),
                        backgroundColor: cardBg,
                        labelStyle: TextStyle(
                          fontSize: 11.5,
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                          color: isSelected ? Colors.white : textColor,
                        ),
                        onSelected: (val) {
                          if (val) setState(() => _selectedStyle = style);
                        },
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 16),

                  // Books in Shelf
                  Text(
                    'Included Books (${_bookIds.length})',
                    style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold, color: subColor),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: _availableBooks.map((bookId) {
                      final isIncluded = _bookIds.contains(bookId);
                      return FilterChip(
                        label: Text(bookId.replaceAll('sample_', '').replaceAll('book_', '')),
                        selected: isIncluded,
                        selectedColor: const Color(0xFFD4A373),
                        backgroundColor: cardBg,
                        labelStyle: TextStyle(
                          fontSize: 11,
                          fontWeight: isIncluded ? FontWeight.bold : FontWeight.normal,
                          color: isIncluded ? Colors.black : textColor,
                        ),
                        onSelected: (val) {
                          setState(() {
                            if (val) {
                              _bookIds.add(bookId);
                            } else {
                              _bookIds.remove(bookId);
                            }
                          });
                        },
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 24),

                  // Save Action Button
                  ElevatedButton(
                    onPressed: _handleSave,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF8B5CF6),
                      foregroundColor: Colors.white,
                      minimumSize: const Size(double.infinity, 46),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      elevation: 0,
                    ),
                    child: const Text(
                      'Save & Apply to Explore',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                    ),
                  ),
                  const SizedBox(height: 14),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatStyleName(ShelfDisplayStyle style) {
    switch (style) {
      case ShelfDisplayStyle.largeFeatured:
        return '🌟 Large Featured';
      case ShelfDisplayStyle.storyCards:
        return '🃏 Story Cards';
      case ShelfDisplayStyle.horizontalCarousel:
        return '🎠 Carousel';
      case ShelfDisplayStyle.coverCarousel:
        return '📚 Cover Carousel';
      case ShelfDisplayStyle.horizontalShelf:
        return '➡️ Standard Shelf';
      case ShelfDisplayStyle.verticalList:
        return '📋 Vertical List';
      case ShelfDisplayStyle.grid:
        return '🔲 Grid';
    }
  }

  InputDecoration _inputDecoration(String hint, IconData icon, Color bg, Color border) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(fontSize: 13, color: Colors.grey),
      prefixIcon: Icon(icon, size: 18, color: const Color(0xFF8B5CF6)),
      filled: true,
      fillColor: bg,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: border),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Color(0xFF8B5CF6), width: 1.5),
      ),
    );
  }
}
