import 'package:epub_audio/features/reader/domain/entities/text_highlight.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('TextHighlight Entity', () {
    test('serializes to and deserializes from JSON map correctly', () {
      final now = DateTime(2026, 9, 10, 12, 0);
      final hl = TextHighlight(
        id: 'hl_12345',
        bookId: 'book_sample_1',
        chapterIndex: 2,
        selectedText: 'അദ്ധ്യായം ഒന്ന്: കടപ്പുറവും കാറ്റും',
        colorValue: Colors.yellow.toARGB32(),
        createdAt: now,
        note: 'Important opening setting',
      );

      final map = hl.toMap();
      final restored = TextHighlight.fromMap(map);

      expect(restored.id, equals(hl.id));
      expect(restored.bookId, equals(hl.bookId));
      expect(restored.chapterIndex, equals(2));
      expect(restored.selectedText, equals('അദ്ധ്യായം ഒന്ന്: കടപ്പുറവും കാറ്റും'));
      expect(restored.colorValue, equals(Colors.yellow.toARGB32()));
      expect(restored.note, equals('Important opening setting'));
      expect(restored.createdAt.millisecondsSinceEpoch, equals(now.millisecondsSinceEpoch));
    });

    test('default highlight color options are available', () {
      expect(TextHighlight.defaultColors.length, greaterThanOrEqualTo(5));
      final yellow = TextHighlight.defaultColors.firstWhere((o) => o.name == 'Yellow');
      expect(yellow.color, equals(const Color(0xFFFDE047)));
    });
  });
}
