import 'package:meta/meta.dart';

/// Represents a user bookmark at a specific chapter and position.
@immutable
class Bookmark {
  final String id;
  final String bookId;
  final int chapterIndex;
  final String chapterTitle;
  final String snippet;
  final DateTime createdAt;
  final String? anchorId;

  const Bookmark({
    required this.id,
    required this.bookId,
    required this.chapterIndex,
    required this.chapterTitle,
    required this.snippet,
    required this.createdAt,
    this.anchorId,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'bookId': bookId,
        'chapterIndex': chapterIndex,
        'chapterTitle': chapterTitle,
        'snippet': snippet,
        'createdAt': createdAt.toIso8601String(),
        'anchorId': anchorId,
      };

  factory Bookmark.fromJson(Map<String, dynamic> json) {
    return Bookmark(
      id: json['id'] as String,
      bookId: json['bookId'] as String,
      chapterIndex: json['chapterIndex'] as int,
      chapterTitle: json['chapterTitle'] as String,
      snippet: json['snippet'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
      anchorId: json['anchorId'] as String?,
    );
  }
}
