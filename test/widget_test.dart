import 'package:epub_audio/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('LibraryScreen loads and renders sample books', (WidgetTester tester) async {
    await tester.pumpWidget(const EpubReaderApp());

    // Initially shows loading indicator
    expect(find.byType(CircularProgressIndicator), findsOneWidget);

    // Pump to complete async loading of sample books
    await tester.pumpAndSettle();

    // Verify Library Screen elements
    expect(find.text('EPUB Reader'), findsOneWidget);
    expect(find.text('Import EPUB'), findsOneWidget);
    expect(find.textContaining('Chemmeen'), findsWidgets);
    expect(find.textContaining('Alice'), findsWidgets);
  });
}
