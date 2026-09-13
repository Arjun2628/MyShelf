import 'dart:convert';

/// Represents a character in a book or story who can speak dialogue.
class Character {
  final String id;
  final String name;
  final String? description;
  final String voiceProfileId;
  final String? colorHex;

  const Character({
    required this.id,
    required this.name,
    this.description,
    required this.voiceProfileId,
    this.colorHex,
  });

  Character copyWith({
    String? id,
    String? name,
    String? description,
    String? voiceProfileId,
    String? colorHex,
  }) {
    return Character(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      voiceProfileId: voiceProfileId ?? this.voiceProfileId,
      colorHex: colorHex ?? this.colorHex,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      if (description != null) 'description': description,
      'voiceProfileId': voiceProfileId,
      if (colorHex != null) 'colorHex': colorHex,
    };
  }

  factory Character.fromMap(Map<String, dynamic> map) {
    return Character(
      id: map['id'] as String? ?? '',
      name: map['name'] as String? ?? '',
      description: map['description'] as String?,
      voiceProfileId: map['voiceProfileId'] as String? ?? '',
      colorHex: map['colorHex'] as String?,
    );
  }

  String toJson() => json.encode(toMap());

  factory Character.fromJson(String source) =>
      Character.fromMap(json.decode(source) as Map<String, dynamic>);

  @override
  String toString() => 'Character(id: $id, name: $name, voiceProfileId: $voiceProfileId)';

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Character &&
        other.id == id &&
        other.name == name &&
        other.description == description &&
        other.voiceProfileId == voiceProfileId &&
        other.colorHex == colorHex;
  }

  @override
  int get hashCode => Object.hash(id, name, description, voiceProfileId, colorHex);
}
