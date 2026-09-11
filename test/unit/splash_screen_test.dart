import 'dart:io';
import 'package:epub_audio/features/library/data/datasources/hive_storage_service.dart';
import 'package:epub_audio/features/splash/presentation/screens/feature_guide_screen.dart';
import 'package:epub_audio/features/splash/presentation/screens/splash_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  setUp(() async {
    final tempDir = Directory.systemTemp.createTempSync('splash_test_hive');
    await HiveStorageService().init(tempDir.path);
  });
  testWidgets('SplashScreen renders without text overlap and triggers guide on tap',
      (WidgetTester tester) async {
    bool getStartedTapped = false;

    await tester.pumpWidget(
      MaterialApp(
        home: SplashScreen(
          onGetStarted: () {
            getStartedTapped = true;
          },
        ),
      ),
    );

    await tester.pumpAndSettle();

    // Verify background image widget renders
    expect(find.byType(Image), findsOneWidget);

    // Tap screen to navigate to guide
    await tester.tap(find.byType(InkWell).first);
    await tester.pumpAndSettle();

    expect(getStartedTapped, isTrue);
  });

  testWidgets('FeatureGuideScreen walks through all app features and finishes',
      (WidgetTester tester) async {
    bool guideFinished = false;

    await tester.pumpWidget(
      MaterialApp(
        home: FeatureGuideScreen(
          onCompleted: () {
            guideFinished = true;
          },
        ),
      ),
    );

    await tester.pumpAndSettle();

    // Verify Page 1 (Reader)
    expect(find.text('READING EXPERIENCE'), findsOneWidget);
    expect(find.text('Immersive EPUB & PDF Reader'), findsOneWidget);
    expect(find.text('Next'), findsOneWidget);
    expect(find.text('Skip'), findsOneWidget);

    // Advance to Page 2 (Audiobooks)
    await tester.tap(find.text('Next'));
    await tester.pumpAndSettle();

    expect(find.text('AUDIOBOOK MODE'), findsOneWidget);
    expect(find.text('Live Synchronized Audiobooks'), findsOneWidget);

    // Advance to Page 3 (OCR Scanner)
    await tester.tap(find.text('Next'));
    await tester.pumpAndSettle();

    expect(find.text('SMART DIGITIZATION'), findsOneWidget);
    expect(find.text('Camera OCR Book Scanner'), findsOneWidget);

    // Advance to Page 4 (Translation)
    await tester.tap(find.text('Next'));
    await tester.pumpAndSettle();

    expect(find.text('GLOBAL LANGUAGES'), findsOneWidget);
    expect(find.text('Real-Time Translation & Notes'), findsOneWidget);
    expect(find.text('Get Started'), findsOneWidget);

    // Finish guide
    await tester.tap(find.text('Get Started'));
    await tester.pumpAndSettle();

    expect(guideFinished, isTrue);
  });
}
