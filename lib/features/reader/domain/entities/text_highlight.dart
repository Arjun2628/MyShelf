import 'package:flutter/material.dart';

/// Represents a persistent user highlight on a passage of text in an EPUB book.
class TextHighlight {
  final String id;
  final String bookId;
  final int chapterIndex;
  final String selectedText;
  final int colorValue;
  final DateTime createdAt;
  final String? note;

  const TextHighlight({
    required this.id,
    required this.bookId,
    required this.chapterIndex,
    required this.selectedText,
    required this.colorValue,
    required this.createdAt,
    this.note,
  });

  Color get color => Color(colorValue);

  /// Predefined highlight palette colors.
  static const List<HighlightColorOption> defaultColors = [
    HighlightColorOption(name: 'Yellow', color: Color(0xFFFDE047), textColor: Color(0xFF854D0E)),
    HighlightColorOption(name: 'Green', color: Color(0xFF86EFAC), textColor: Color(0xFF166534)),
    HighlightColorOption(name: 'Blue', color: Color(0xFF93C5FD), textColor: Color(0xFF1E40AF)),
    HighlightColorOption(name: 'Pink', color: Color(0xFFF472B6), textColor: Color(0xFF9D174D)),
    HighlightColorOption(name: 'Purple', color: Color(0xFFC084FC), textColor: Color(0xFF6B21A8)),
    HighlightColorOption(name: 'Orange', color: Color(0xFFFDBA74), textColor: Color(0xFF9A3412)),
  ];

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'bookId': bookId,
      'chapterIndex': chapterIndex,
      'selectedText': selectedText,
      'colorValue': colorValue,
      'createdAt': createdAt.toIso8601String(),
      'note': note,
    };
  }

  factory TextHighlight.fromMap(Map<dynamic, dynamic> map) {
    return TextHighlight(
      id: map['id'] as String? ?? '',
      bookId: map['bookId'] as String? ?? '',
      chapterIndex: (map['chapterIndex'] as num?)?.toInt() ?? 0,
      selectedText: map['selectedText'] as String? ?? '',
      colorValue: (map['colorValue'] as num?)?.toInt() ?? 0xFFFDE047,
      createdAt: map['createdAt'] != null
          ? DateTime.tryParse(map['createdAt'] as String) ?? DateTime.now()
          : DateTime.now(),
      note: map['note'] as String?,
    );
  }

  TextHighlight copyWith({
    String? id,
    String? bookId,
    int? chapterIndex,
    String? selectedText,
    int? colorValue,
    DateTime? createdAt,
    String? note,
  }) {
    return TextHighlight(
      id: id ?? this.id,
      bookId: bookId ?? this.bookId,
      chapterIndex: chapterIndex ?? this.chapterIndex,
      selectedText: selectedText ?? this.selectedText,
      colorValue: colorValue ?? this.colorValue,
      createdAt: createdAt ?? this.createdAt,
      note: note ?? this.note,
    );
  }
}

class HighlightColorOption {
  final String name;
  final Color color;
  final Color textColor;

  const HighlightColorOption({
    required this.name,
    required this.color,
    required this.textColor,
  });
}
