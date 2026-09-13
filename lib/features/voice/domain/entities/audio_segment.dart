import 'dart:convert';

enum AudioSegmentStatus {
  pending,
  generating,
  ready,
  failed,
}

extension AudioSegmentStatusExtension on AudioSegmentStatus {
  String get name {
    switch (this) {
      case AudioSegmentStatus.pending:
        return 'pending';
      case AudioSegmentStatus.generating:
        return 'generating';
      case AudioSegmentStatus.ready:
        return 'ready';
      case AudioSegmentStatus.failed:
        return 'failed';
    }
  }

  static AudioSegmentStatus fromString(String? status) {
    switch (status?.toLowerCase()) {
      case 'generating':
        return AudioSegmentStatus.generating;
      case 'ready':
        return AudioSegmentStatus.ready;
      case 'failed':
        return AudioSegmentStatus.failed;
      case 'pending':
      default:
        return AudioSegmentStatus.pending;
    }
  }
}

/// Represents an audio artifact or ready-to-play segment linked to a ContentBlock.
class AudioSegment {
  final String id;
  final String contentBlockId;
  final String speakerId;
  final String voiceProfileId;
  final String? audioPath;
  final Duration? duration;
  final AudioSegmentStatus status;
  final String? errorMessage;

  const AudioSegment({
    required this.id,
    required this.contentBlockId,
    required this.speakerId,
    required this.voiceProfileId,
    this.audioPath,
    this.duration,
    this.status = AudioSegmentStatus.pending,
    this.errorMessage,
  });

  AudioSegment copyWith({
    String? id,
    String? contentBlockId,
    String? speakerId,
    String? voiceProfileId,
    String? audioPath,
    Duration? duration,
    AudioSegmentStatus? status,
    String? errorMessage,
  }) {
    return AudioSegment(
      id: id ?? this.id,
      contentBlockId: contentBlockId ?? this.contentBlockId,
      speakerId: speakerId ?? this.speakerId,
      voiceProfileId: voiceProfileId ?? this.voiceProfileId,
      audioPath: audioPath ?? this.audioPath,
      duration: duration ?? this.duration,
      status: status ?? this.status,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'contentBlockId': contentBlockId,
      'speakerId': speakerId,
      'voiceProfileId': voiceProfileId,
      if (audioPath != null) 'audioPath': audioPath,
      if (duration != null) 'durationMs': duration!.inMilliseconds,
      'status': status.name,
      if (errorMessage != null) 'errorMessage': errorMessage,
    };
  }

  factory AudioSegment.fromMap(Map<String, dynamic> map) {
    return AudioSegment(
      id: map['id'] as String? ?? '',
      contentBlockId: map['contentBlockId'] as String? ?? '',
      speakerId: map['speakerId'] as String? ?? 'narrator',
      voiceProfileId: map['voiceProfileId'] as String? ?? '',
      audioPath: map['audioPath'] as String?,
      duration: map['durationMs'] != null
          ? Duration(milliseconds: (map['durationMs'] as num).toInt())
          : null,
      status: AudioSegmentStatusExtension.fromString(map['status'] as String?),
      errorMessage: map['errorMessage'] as String?,
    );
  }

  String toJson() => json.encode(toMap());

  factory AudioSegment.fromJson(String source) =>
      AudioSegment.fromMap(json.decode(source) as Map<String, dynamic>);

  @override
  String toString() {
    return 'AudioSegment(id: $id, block: $contentBlockId, speaker: $speakerId, status: ${status.name}, path: $audioPath)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is AudioSegment &&
        other.id == id &&
        other.contentBlockId == contentBlockId &&
        other.speakerId == speakerId &&
        other.voiceProfileId == voiceProfileId &&
        other.audioPath == audioPath &&
        other.status == status;
  }

  @override
  int get hashCode => Object.hash(id, contentBlockId, speakerId, voiceProfileId, audioPath, status);
}
