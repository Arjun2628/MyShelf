import 'package:meta/meta.dart';

/// Universal book position representing the exact point in the book
/// shared across reading and audio listening.
@immutable
class BookPosition {
  final int chapterIndex;
  final int paragraphIndex;
  final int charOffset;
  final DateTime timestamp;

  const BookPosition({
    required this.chapterIndex,
    this.paragraphIndex = 0,
    this.charOffset = 0,
    required this.timestamp,
  });

  factory BookPosition.initial([int chapterIndex = 0]) {
    return BookPosition(
      chapterIndex: chapterIndex,
      paragraphIndex: 0,
      charOffset: 0,
      timestamp: DateTime.now(),
    );
  }

  BookPosition copyWith({
    int? chapterIndex,
    int? paragraphIndex,
    int? charOffset,
    DateTime? timestamp,
  }) {
    return BookPosition(
      chapterIndex: chapterIndex ?? this.chapterIndex,
      paragraphIndex: paragraphIndex ?? this.paragraphIndex,
      charOffset: charOffset ?? this.charOffset,
      timestamp: timestamp ?? this.timestamp,
    );
  }

  Map<String, dynamic> toJson() => {
        'chapterIndex': chapterIndex,
        'paragraphIndex': paragraphIndex,
        'charOffset': charOffset,
        'timestamp': timestamp.toIso8601String(),
      };

  factory BookPosition.fromJson(Map<String, dynamic> json) {
    return BookPosition(
      chapterIndex: json['chapterIndex'] as int? ?? 0,
      paragraphIndex: json['paragraphIndex'] as int? ?? 0,
      charOffset: json['charOffset'] as int? ?? 0,
      timestamp: json['timestamp'] != null
          ? DateTime.parse(json['timestamp'] as String)
          : DateTime.now(),
    );
  }

  @override
  String toString() =>
      'BookPosition(chapter: $chapterIndex, paragraph: $paragraphIndex, charOffset: $charOffset)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is BookPosition &&
          runtimeType == other.runtimeType &&
          chapterIndex == other.chapterIndex &&
          paragraphIndex == other.paragraphIndex &&
          charOffset == other.charOffset;

  @override
  int get hashCode =>
      chapterIndex.hashCode ^ paragraphIndex.hashCode ^ charOffset.hashCode;
}
