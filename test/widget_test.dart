import 'dart:io';
import 'package:epub_audio/features/library/data/datasources/hive_storage_service.dart';
import 'package:epub_audio/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  setUp(() async {
    final tempDir = Directory.systemTemp.createTempSync('widget_test_hive');
    await HiveStorageService().init(tempDir.path);
  });

  testWidgets('LibraryScreen loads and renders sample books with read & listen actions', (WidgetTester tester) async {
    await tester.pumpWidget(const EpubReaderApp());

    // Initially shows loading indicator
    expect(find.byType(CircularProgressIndicator), findsOneWidget);

    // Pump enough time for async books provider & Hive to load
    await tester.pump(const Duration(milliseconds: 100));
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
