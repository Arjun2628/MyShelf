/// Domain entity representing a custom text document created via direct writing,
/// clipboard paste, OS share mechanism, or file import.
class TextDocument {
  final String id;
  final String title;
  final String content;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String source; // 'direct_write', 'clipboard', 'shared_text', 'file_import'
  final int lastReadPosition;
  final Map<String, dynamic>? metadata;

  const TextDocument({
    required this.id,
    required this.title,
    required this.content,
    required this.createdAt,
    required this.updatedAt,
    this.source = 'direct_write',
    this.lastReadPosition = 0,
    this.metadata,
  });

  /// Factory to construct a TextDocument easily from raw text.
  factory TextDocument.fromRawText({
    required String id,
    required String title,
    required String rawContent,
    String source = 'direct_write',
    int lastReadPosition = 0,
    Map<String, dynamic>? metadata,
  }) {
    final now = DateTime.now();
    final effectiveTitle = title.trim().isNotEmpty
        ? title.trim()
        : (rawContent.trim().isNotEmpty
            ? rawContent.trim().split('\n').first.replaceAll(RegExp(r'^#+\s*'), '').trim()
            : 'Untitled Document');
    return TextDocument(
      id: id,
      title: effectiveTitle.length > 50 ? effectiveTitle.substring(0, 50) : effectiveTitle,
      content: rawContent,
      createdAt: now,
      updatedAt: now,
      source: source,
      lastReadPosition: lastReadPosition,
      metadata: metadata,
    );
  }

  /// Normalizes and splits the raw content into structured paragraphs.
  List<String> get paragraphs {
    if (content.trim().isEmpty) return [];
    return content
        .split(RegExp(r'\r?\n\s*\r?\n|\r?\n'))
        .map((p) => p.trim())
        .where((p) => p.isNotEmpty)
        .toList();
  }

  /// Splits content into ordered sentences across all paragraphs.
  List<String> get sentences {
    final result = <String>[];
    for (final p in paragraphs) {
      final matches = RegExp(r'[^.!?]+[.!?]+|[^.!?]+$')
          .allMatches(p)
          .map((m) => m.group(0)?.trim() ?? '')
          .where((s) => s.isNotEmpty);
      result.addAll(matches);
    }
    return result;
  }

  /// Calculates total word count.
  int get wordCount {
    if (content.trim().isEmpty) return 0;
    return content.trim().split(RegExp(r'\s+')).length;
  }

  /// Calculates total character count.
  int get characterCount => content.length;

  /// Estimated reading time in minutes (assumes 200 words per minute).
  int get estimatedReadingMinutes {
    final words = wordCount;
    if (words == 0) return 0;
    final mins = (words / 200).ceil();
    return mins < 1 ? 1 : mins;
  }

  /// Creates a copy with optional updated fields.
  TextDocument copyWith({
    String? id,
    String? title,
    String? content,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? source,
    int? lastReadPosition,
    Map<String, dynamic>? metadata,
  }) {
    return TextDocument(
      id: id ?? this.id,
      title: title ?? this.title,
      content: content ?? this.content,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      source: source ?? this.source,
      lastReadPosition: lastReadPosition ?? this.lastReadPosition,
      metadata: metadata ?? this.metadata,
    );
  }

  /// Serializes to JSON Map for Hive storage.
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'content': content,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'source': source,
      'lastReadPosition': lastReadPosition,
      if (metadata != null) 'metadata': metadata,
    };
  }

  /// Deserializes from JSON Map.
  factory TextDocument.fromJson(Map<dynamic, dynamic> json) {
    return TextDocument(
      id: json['id'] as String? ?? 'doc_${DateTime.now().millisecondsSinceEpoch}',
      title: json['title'] as String? ?? 'Untitled Document',
      content: json['content'] as String? ?? '',
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'] as String) ?? DateTime.now()
          : DateTime.now(),
      updatedAt: json['updatedAt'] != null
          ? DateTime.tryParse(json['updatedAt'] as String) ?? DateTime.now()
          : DateTime.now(),
      source: json['source'] as String? ?? 'direct_write',
      lastReadPosition: (json['lastReadPosition'] as num?)?.toInt() ?? 0,
      metadata: json['metadata'] != null ? Map<String, dynamic>.from(json['metadata'] as Map) : null,
    );
  }
}
