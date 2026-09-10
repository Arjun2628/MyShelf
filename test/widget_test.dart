import 'package:epub_audio/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('LibraryScreen loads and renders sample books with read & listen actions', (WidgetTester tester) async {
    await tester.pumpWidget(const EpubReaderApp());

    // Initially shows loading indicator
    expect(find.byType(CircularProgressIndicator), findsOneWidget);

    // Pump to complete async loading of sample books
    await tester.pumpAndSettle();

    // Verify Library Screen elements
    expect(find.textContaining('EPUB'), findsWidgets);
    expect(find.text('Import EPUB'), findsOneWidget);
    expect(find.textContaining('Chemmeen'), findsWidgets);
    expect(find.textContaining('Alice'), findsWidgets);
    expect(find.text('Read'), findsWidgets);
    expect(find.text('Listen'), findsWidgets);
  });
}
