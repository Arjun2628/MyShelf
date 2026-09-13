import 'dart:convert';

enum ContentBlockType {
  narration,
  dialogue,
  description,
  soundEffect,
  music,
}

extension ContentBlockTypeExtension on ContentBlockType {
  String get name {
    switch (this) {
      case ContentBlockType.narration:
        return 'narration';
      case ContentBlockType.dialogue:
        return 'dialogue';
      case ContentBlockType.description:
        return 'description';
      case ContentBlockType.soundEffect:
        return 'soundEffect';
      case ContentBlockType.music:
        return 'music';
    }
  }

  static ContentBlockType fromString(String? type) {
    switch (type?.toLowerCase()) {
      case 'dialogue':
        return ContentBlockType.dialogue;
      case 'description':
        return ContentBlockType.description;
      case 'soundeffect':
      case 'sound_effect':
        return ContentBlockType.soundEffect;
      case 'music':
        return ContentBlockType.music;
      case 'narration':
      default:
        return ContentBlockType.narration;
    }
  }
}

/// Represents an atomic structured unit of book text for multi-voice synthesis & reading.
class ContentBlock {
  final String id;
  final ContentBlockType type;
  final String text;
  final String speakerId;
  final int order;
  final Map<String, dynamic>? metadata;

  const ContentBlock({
    required this.id,
    required this.type,
    required this.text,
    required this.speakerId,
    required this.order,
    this.metadata,
  });

  ContentBlock copyWith({
    String? id,
    ContentBlockType? type,
    String? text,
    String? speakerId,
    int? order,
    Map<String, dynamic>? metadata,
  }) {
    return ContentBlock(
      id: id ?? this.id,
      type: type ?? this.type,
      text: text ?? this.text,
      speakerId: speakerId ?? this.speakerId,
      order: order ?? this.order,
      metadata: metadata ?? this.metadata,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'type': type.name,
      'text': text,
      'speakerId': speakerId,
      'order': order,
      if (metadata != null) 'metadata': metadata,
    };
  }

  factory ContentBlock.fromMap(Map<String, dynamic> map) {
    return ContentBlock(
      id: map['id'] as String? ?? '',
      type: ContentBlockTypeExtension.fromString(map['type'] as String?),
      text: map['text'] as String? ?? '',
      speakerId: map['speakerId'] as String? ?? 'narrator',
      order: (map['order'] as num?)?.toInt() ?? 0,
      metadata: map['metadata'] != null
          ? Map<String, dynamic>.from(map['metadata'] as Map)
          : null,
    );
  }

  String toJson() => json.encode(toMap());

  factory ContentBlock.fromJson(String source) =>
      ContentBlock.fromMap(json.decode(source) as Map<String, dynamic>);

  @override
  String toString() {
    return 'ContentBlock(id: $id, type: ${type.name}, speakerId: $speakerId, order: $order, text: "${text.length > 30 ? "${text.substring(0, 30)}..." : text}")';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ContentBlock &&
        other.id == id &&
        other.type == type &&
        other.text == text &&
        other.speakerId == speakerId &&
        other.order == order;
  }

  @override
  int get hashCode => Object.hash(id, type, text, speakerId, order);
}
