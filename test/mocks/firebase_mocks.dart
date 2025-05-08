import 'package:firebase_core_platform_interface/firebase_core_platform_interface.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';

// A simplified mock for Firebase Core
class MockFirebaseCore {
  static Future<void> setupMockFirebaseCore() async {
    TestWidgetsFlutterBinding.ensureInitialized();

    // Setup platform exception catcher
    FlutterError.onError = (details) {
      if (details.exception is PlatformException &&
          (details.exception as PlatformException).code == 'unavailable') {
        // Ignore the "unavailable" exception raised by Firebase initialization
        return;
      }
      FlutterError.presentError(details);
    };
  }
}

// Create a mock FirebaseApp
class MockFirebaseApp implements FirebaseApp {
  @override
  String get name => '[DEFAULT]';

  @override
  FirebaseOptions get options => FirebaseOptions(
        apiKey: 'mock-api-key',
        appId: 'mock-app-id',
        messagingSenderId: 'mock-sender-id',
        projectId: 'mock-project-id',
      );

  @override
  bool get isAutomaticDataCollectionEnabled => false;

  @override
  Future<void> delete() async {}

  @override
  Future<void> setAutomaticDataCollectionEnabled(bool enabled) async {}

  @override
  Future<void> setAutomaticResourceManagementEnabled(bool enabled) async {}
}
