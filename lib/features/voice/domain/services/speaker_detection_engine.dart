import '../entities/content_block.dart';
import '../entities/character.dart';

/// Extensible interface for detecting dialogue and speakers in raw text.
/// Supports deterministic rule-based algorithms, ML models, or LLM-based analysis.
abstract class SpeakerDetectionEngine {
  /// Unique identifier of this detector (e.g. 'rule_based', 'ai_llm').
  String get detectorId;

  /// Deconstructs a block of raw text or chapter paragraphs into structured [ContentBlock] sequence.
  Future<List<ContentBlock>> detect({
    required String rawText,
    required List<Character> knownCharacters,
    String? chapterId,
  });

  /// Identifies the character ID who spoke a specific dialogue snippet given surrounding narrative context.
  Future<String> detectSpeakerForDialogue({
    required String dialogueText,
    required String surroundingContext,
    required List<Character> knownCharacters,
    String? lastSpeaker,
  });
}
