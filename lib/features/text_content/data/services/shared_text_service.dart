import 'dart:async';
import 'package:flutter/services.dart';

/// Service that listens for OS shared text intents (Google Keep, Notes, WhatsApp, Browser, Gmail, etc.)
class SharedTextService {
  static const MethodChannel _channel =
      MethodChannel('com.example.epub_audio/share_intent');

  static final StreamController<String> _sharedTextController =
      StreamController<String>.broadcast();

  /// Stream of shared text events received while the app is active or in background.
  static Stream<String> get sharedTextStream => _sharedTextController.stream;

  static bool _isInitialized = false;

  /// Initializes the listener for shared text intents.
  static void initialize() {
    if (_isInitialized) return;
    _isInitialized = true;

    _channel.setMethodCallHandler((call) async {
      if (call.method == 'onSharedTextReceived') {
        final text = call.arguments as String?;
        if (text != null && text.trim().isNotEmpty) {
          _sharedTextController.add(text.trim());
        }
      }
    });
  }

  /// Retrieves initial shared text if the app was launched via a Share intent.
  static Future<String?> getInitialSharedText() async {
    try {
      final text = await _channel.invokeMethod<String>('getInitialSharedText');
      if (text != null && text.trim().isNotEmpty) {
        return text.trim();
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  /// Clears any cached shared text on the native side.
  static Future<void> clearSharedText() async {
    try {
      await _channel.invokeMethod('clearSharedText');
    } catch (_) {}
  }
}
