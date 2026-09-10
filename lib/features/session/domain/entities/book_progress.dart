/// Represents saved reading and playback progress for a specific book.
class BookProgress {
  final String bookId;
  final int chapterIndex;
  final int paragraphIndex;
  final DateTime lastUpdated;

  const BookProgress({
    required this.bookId,
    required this.chapterIndex,
    required this.paragraphIndex,
    required this.lastUpdated,
  });

  Map<String, dynamic> toMap() {
    return {
      'bookId': bookId,
      'chapterIndex': chapterIndex,
      'paragraphIndex': paragraphIndex,
      'lastUpdated': lastUpdated.toIso8601String(),
    };
  }

  factory BookProgress.fromMap(Map<dynamic, dynamic> map) {
    return BookProgress(
      bookId: map['bookId'] as String? ?? '',
      chapterIndex: (map['chapterIndex'] as num?)?.toInt() ?? 0,
      paragraphIndex: (map['paragraphIndex'] as num?)?.toInt() ?? 0,
      lastUpdated: map['lastUpdated'] != null
          ? DateTime.tryParse(map['lastUpdated'] as String) ?? DateTime.now()
          : DateTime.now(),
    );
  }

  BookProgress copyWith({
    String? bookId,
    int? chapterIndex,
    int? paragraphIndex,
    DateTime? lastUpdated,
  }) {
    return BookProgress(
      bookId: bookId ?? this.bookId,
      chapterIndex: chapterIndex ?? this.chapterIndex,
      paragraphIndex: paragraphIndex ?? this.paragraphIndex,
      lastUpdated: lastUpdated ?? this.lastUpdated,
    );
  }
}
