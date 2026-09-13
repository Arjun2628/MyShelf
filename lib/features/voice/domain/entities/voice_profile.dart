import 'dart:convert';

/// Represents acoustic settings and TTS parameters assigned to a speaker/character.
class VoiceProfile {
  final String id;
  final String name;
  final String provider;
  final String providerVoiceId;
  final String language;
  final double speed;
  final double pitch;
  final double volume;
  final String? emotion;
  final bool enabled;

  const VoiceProfile({
    required this.id,
    required this.name,
    this.provider = 'device_tts',
    required this.providerVoiceId,
    this.language = 'en-US',
    this.speed = 1.0,
    this.pitch = 1.0,
    this.volume = 1.0,
    this.emotion,
    this.enabled = true,
  });

  /// Generates a deterministic hash code based on acoustic parameters for cache keying.
  String generateSettingsHash() {
    final raw = '$provider:$providerVoiceId:$language:${speed.toStringAsFixed(2)}:${pitch.toStringAsFixed(2)}:${volume.toStringAsFixed(2)}:${emotion ?? "none"}';
    return raw.hashCode.toRadixString(16);
  }

  VoiceProfile copyWith({
    String? id,
    String? name,
    String? provider,
    String? providerVoiceId,
    String? language,
    double? speed,
    double? pitch,
    double? volume,
    String? emotion,
    bool? enabled,
  }) {
    return VoiceProfile(
      id: id ?? this.id,
      name: name ?? this.name,
      provider: provider ?? this.provider,
      providerVoiceId: providerVoiceId ?? this.providerVoiceId,
      language: language ?? this.language,
      speed: speed ?? this.speed,
      pitch: pitch ?? this.pitch,
      volume: volume ?? this.volume,
      emotion: emotion ?? this.emotion,
      enabled: enabled ?? this.enabled,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'provider': provider,
      'providerVoiceId': providerVoiceId,
      'language': language,
      'speed': speed,
      'pitch': pitch,
      'volume': volume,
      if (emotion != null) 'emotion': emotion,
      'enabled': enabled,
    };
  }

  factory VoiceProfile.fromMap(Map<String, dynamic> map) {
    return VoiceProfile(
      id: map['id'] as String? ?? '',
      name: map['name'] as String? ?? '',
      provider: map['provider'] as String? ?? 'device_tts',
      providerVoiceId: map['providerVoiceId'] as String? ?? '',
      language: map['language'] as String? ?? 'en-US',
      speed: (map['speed'] as num?)?.toDouble() ?? 1.0,
      pitch: (map['pitch'] as num?)?.toDouble() ?? 1.0,
      volume: (map['volume'] as num?)?.toDouble() ?? 1.0,
      emotion: map['emotion'] as String?,
      enabled: map['enabled'] as bool? ?? true,
    );
  }

  String toJson() => json.encode(toMap());

  factory VoiceProfile.fromJson(String source) =>
      VoiceProfile.fromMap(json.decode(source) as Map<String, dynamic>);

  @override
  String toString() {
    return 'VoiceProfile(id: $id, name: $name, voice: $providerVoiceId, speed: $speed, pitch: $pitch)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is VoiceProfile &&
        other.id == id &&
        other.name == name &&
        other.provider == provider &&
        other.providerVoiceId == providerVoiceId &&
        other.language == language &&
        other.speed == speed &&
        other.pitch == pitch &&
        other.volume == volume &&
        other.emotion == emotion &&
        other.enabled == enabled;
  }

  @override
  int get hashCode => Object.hash(
        id,
        name,
        provider,
        providerVoiceId,
        language,
        speed,
        pitch,
        volume,
        emotion,
        enabled,
      );
}
