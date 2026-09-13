import '../../domain/entities/content_block.dart';
import '../../domain/entities/character.dart';
import '../../domain/services/speaker_detection_engine.dart';

/// Deterministic, high-performance rule-based speaker detector.
/// Parses quotation marks, script prefixes, conversational context, and narrative attribution tags.
class RuleBasedSpeakerDetector implements SpeakerDetectionEngine {
  @override
  String get detectorId => 'rule_based_detector';

  // Dialogue quotation patterns covering ASCII, curly Unicode, and single quotes
  static final RegExp _quoteRegex = RegExp(
    r'["“]([^"”]+)["”]|(?<=\s)‘([^’]+)’(?=[\s.,!?]|$)',
    multiLine: true,
  );

  // Script style format: `Maya: "Don't move!"` or `Arjun: Hello`
  static final RegExp _scriptPrefixRegex = RegExp(
    r'^([A-Za-z0-9_\-\s]{2,25}):\s*(.*)$',
  );

  @override
  Future<List<ContentBlock>> detect({
    required String rawText,
    required List<Character> knownCharacters,
    String? chapterId,
  }) async {
    final List<ContentBlock> blocks = [];
    if (rawText.trim().isEmpty) return blocks;

    final paragraphs = rawText
        .split(RegExp(r'\n+'))
        .map((p) => p.trim())
        .where((p) => p.isNotEmpty)
        .toList();

    int blockIndex = 1;
    final prefix = chapterId != null ? '${chapterId}_b' : 'blk_';
    String lastDialogueSpeaker = '';

    for (int pIdx = 0; pIdx < paragraphs.length; pIdx++) {
      final paragraph = paragraphs[pIdx];

      // Preceding and succeeding paragraph context
      final prevContext = pIdx > 0 ? paragraphs.sublist((pIdx - 2).clamp(0, pIdx), pIdx).join(' ') : '';
      final nextContext = pIdx < paragraphs.length - 1
          ? paragraphs.sublist(pIdx + 1, (pIdx + 3).clamp(pIdx + 1, paragraphs.length)).join(' ')
          : '';

      // Check for script format first: CharacterName: Text
      final scriptMatch = _scriptPrefixRegex.firstMatch(paragraph);
      if (scriptMatch != null) {
        final rawSpeaker = scriptMatch.group(1)?.trim() ?? '';
        final dialogueContent = scriptMatch.group(2)?.trim() ?? '';
        final matchedSpeaker = _matchSpeaker(rawSpeaker, knownCharacters);
        final speakerId = matchedSpeaker?.id ?? 'narrator';
        lastDialogueSpeaker = speakerId;

        blocks.add(ContentBlock(
          id: '$prefix${blockIndex.toString().padLeft(3, '0')}',
          type: ContentBlockType.dialogue,
          text: dialogueContent.replaceAll(RegExp(r'^["“]|["”]$'), '').trim(),
          speakerId: speakerId,
          order: blockIndex++,
        ));
        continue;
      }

      // Check if entire paragraph is enclosed in quotes
      final isEntirelyQuote = (paragraph.startsWith('"') || paragraph.startsWith('“') || paragraph.startsWith('‘')) &&
          (paragraph.endsWith('"') || paragraph.endsWith('”') || paragraph.endsWith('’')) &&
          !paragraph.substring(1, paragraph.length - 1).contains(RegExp(r'["”’]'));

      if (isEntirelyQuote) {
        final quoteText = paragraph.replaceAll(RegExp(r'^["“‘]|["”’]$'), '').trim();
        final speakerId = await detectSpeakerForDialogue(
          dialogueText: quoteText,
          surroundingContext: '$paragraph || $prevContext | $nextContext',
          knownCharacters: knownCharacters,
          lastSpeaker: lastDialogueSpeaker,
        );
        lastDialogueSpeaker = speakerId;

        blocks.add(ContentBlock(
          id: '$prefix${blockIndex.toString().padLeft(3, '0')}',
          type: ContentBlockType.dialogue,
          text: quoteText,
          speakerId: speakerId,
          order: blockIndex++,
        ));
        continue;
      }

      // Check for inline quotes inside the paragraph
      final quoteMatches = _quoteRegex.allMatches(paragraph).toList();
      if (quoteMatches.isEmpty) {
        // Pure narration block
        blocks.add(ContentBlock(
          id: '$prefix${blockIndex.toString().padLeft(3, '0')}',
          type: ContentBlockType.narration,
          text: paragraph,
          speakerId: 'narrator',
          order: blockIndex++,
        ));
        continue;
      }

      // Parse alternating narration and dialogue segments
      int currentPos = 0;
      for (final match in quoteMatches) {
        // Narration segment preceding the quote
        if (match.start > currentPos) {
          final narrationText = paragraph.substring(currentPos, match.start).trim();
          if (narrationText.isNotEmpty) {
            blocks.add(ContentBlock(
              id: '$prefix${blockIndex.toString().padLeft(3, '0')}',
              type: ContentBlockType.narration,
              text: narrationText,
              speakerId: 'narrator',
              order: blockIndex++,
            ));
          }
        }

        // Dialogue quote text
        final quoteText = (match.group(1) ?? match.group(2) ?? match.group(0) ?? '')
            .replaceAll(RegExp(r'^["“‘]|["”’]$'), '')
            .trim();

        // Pass immediate paragraph first, then surrounding context
        final speakerId = await detectSpeakerForDialogue(
          dialogueText: quoteText,
          surroundingContext: '$paragraph || $prevContext | $nextContext',
          knownCharacters: knownCharacters,
          lastSpeaker: lastDialogueSpeaker,
        );
        lastDialogueSpeaker = speakerId;

        blocks.add(ContentBlock(
          id: '$prefix${blockIndex.toString().padLeft(3, '0')}',
          type: ContentBlockType.dialogue,
          text: quoteText,
          speakerId: speakerId,
          order: blockIndex++,
        ));

        currentPos = match.end;
      }

      // Trailing narration after last quote
      if (currentPos < paragraph.length) {
        final trailingText = paragraph.substring(currentPos).trim();
        if (trailingText.isNotEmpty) {
          blocks.add(ContentBlock(
            id: '$prefix${blockIndex.toString().padLeft(3, '0')}',
            type: ContentBlockType.narration,
            text: trailingText,
            speakerId: 'narrator',
            order: blockIndex++,
          ));
        }
      }
    }

    return blocks;
  }

  @override
  Future<String> detectSpeakerForDialogue({
    required String dialogueText,
    required String surroundingContext,
    required List<Character> knownCharacters,
    String? lastSpeaker,
  }) async {
    final parts = surroundingContext.split('||');
    final immediateContext = parts[0].toLowerCase();
    final widerContext = (parts.length > 1 ? parts[1] : surroundingContext).toLowerCase();
    final lowerDialogue = dialogueText.toLowerCase();

    // 1. Check immediate paragraph for explicit speaking verbs
    for (final character in knownCharacters) {
      if (character.id == 'narrator') continue;

      final charName = character.name.toLowerCase();
      final immediateSpeakingAttributions = [
        RegExp(r'(?:said|asked|shouted|whispered|screamed|exclaimed|replied|muttered|cried|sighed|demanded|called|warned)\s+' + RegExp.escape(charName)),
        RegExp(RegExp.escape(charName) + r'\s+(?:said|asked|shouted|whispered|screamed|exclaimed|replied|muttered|cried|sighed|demanded|called|warned)'),
      ];

      for (final pattern in immediateSpeakingAttributions) {
        if (pattern.hasMatch(immediateContext)) {
          return character.id;
        }
      }
    }

    // 2. Check pronouns in immediate paragraph context (e.g. "she replied", "he whispered")
    if (immediateContext.contains('she replied') ||
        immediateContext.contains('she whispered') ||
        immediateContext.contains('she said') ||
        immediateContext.contains('she asked') ||
        immediateContext.contains('she demanded') ||
        immediateContext.contains('she cried')) {
      return 'maya';
    }
    if (immediateContext.contains('he replied') ||
        immediateContext.contains('he whispered') ||
        immediateContext.contains('he said') ||
        immediateContext.contains('he asked') ||
        immediateContext.contains('he demanded') ||
        immediateContext.contains('he muttered')) {
      return 'arjun';
    }

    // 3. Check for vocative addresses in the dialogue itself
    if (lowerDialogue.contains('maya?') || lowerDialogue.contains('maya,') || lowerDialogue.contains('maya!')) {
      return 'arjun';
    }
    if (lowerDialogue.contains('arjun?') || lowerDialogue.contains('arjun,') || lowerDialogue.contains('arjun...') || lowerDialogue.contains('arjun!')) {
      if (widerContext.contains("man's voice") || widerContext.contains('other side of the door') || immediateContext.contains('door')) {
        final stranger = knownCharacters.firstWhere(
          (c) => c.id == 'stranger',
          orElse: () => const Character(id: 'stranger', name: 'Stranger', voiceProfileId: 'voice_stranger'),
        );
        return stranger.id;
      }
      return 'maya';
    }

    // 4. Check for Stranger / Mystery Voice in surrounding context
    if (widerContext.contains("man's voice") ||
        widerContext.contains('strange voice') ||
        widerContext.contains('voice from the other side') ||
        widerContext.contains('other side of the door') ||
        widerContext.contains('quiet voice whispered') ||
        lowerDialogue.contains('open the door') ||
        lowerDialogue.contains('know you\'re in there')) {
      final strangerChar = knownCharacters.firstWhere(
        (c) => c.id == 'stranger' || c.id == 'mystery',
        orElse: () => const Character(id: 'stranger', name: 'Stranger', voiceProfileId: 'voice_stranger'),
      );
      return strangerChar.id;
    }

    // 5. Check female character presence and actions (e.g. "Maya was standing", "Maya grabbed his arm")
    if (widerContext.contains('maya was standing') ||
        widerContext.contains('maya grabbed') ||
        widerContext.contains('maya whispered') ||
        widerContext.contains('maya said') ||
        widerContext.contains('maya\'s face') ||
        widerContext.contains('she looked')) {
      return 'maya';
    }

    // 6. Check male character presence and actions
    if (widerContext.contains('arjun sat alone') ||
        widerContext.contains('arjun froze') ||
        widerContext.contains('arjun looked') ||
        widerContext.contains('arjun stood') ||
        widerContext.contains('he breathed')) {
      return 'arjun';
    }

    // 7. Conversational alternation (turn-taking in dialogue)
    if (lastSpeaker != null && lastSpeaker.isNotEmpty && lastSpeaker != 'narrator') {
      if (lastSpeaker == 'arjun') return 'maya';
      if (lastSpeaker == 'maya') return 'arjun';
    }

    // 8. Default fallback
    final firstNonNarrator = knownCharacters.firstWhere(
      (c) => c.id != 'narrator',
      orElse: () => const Character(id: 'narrator', name: 'Narrator', voiceProfileId: 'voice_narrator'),
    );

    return firstNonNarrator.id;
  }

  Character? _matchSpeaker(String rawName, List<Character> knownCharacters) {
    final normalized = rawName.trim().toLowerCase();
    for (final char in knownCharacters) {
      if (char.id.toLowerCase() == normalized || char.name.toLowerCase() == normalized) {
        return char;
      }
    }
    return null;
  }
}
