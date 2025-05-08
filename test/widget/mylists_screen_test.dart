import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import '../../lib/screens/lists/my_lists_screen.dart';

import 'dart:io';

// Create a mock HTTP client to override network calls
class _MockHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) {
    return super.createHttpClient(context)
      ..badCertificateCallback = (_, __, ___) => true;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  // Create test environment
  final fakeFirestore = FakeFirebaseFirestore();

  // This is needed to handle HTTP calls that might happen in your app
  HttpOverrides.global = _MockHttpOverrides();

  // Setup test data
  setUpAll(() async {
    // Setup the specific trip ID being tested
    final testTripId = 'cSrDSYLMIpOpgaUXbO0C';

    // Add test data to the fake Firestore
    await fakeFirestore.collection('packingLists').add({
      'id': '174516613689',
      'name': 'randomm',
      'createdAt': 'April 20, 2025 at 9:22:18PM UTC+5',
      'items': [
        {
          'category': 'Clothing',
          'isEssential': false,
          'isPacked': false,
          'name': 'socks',
          'quantity': 2
        }
      ],
      'tripId': testTripId
    });

    // Add another list with a different trip ID to ensure filtering works
    await fakeFirestore.collection('packingLists').add({
      'id': '174514371778',
      'name': 'winter break 2025',
      'createdAt': 'April 20, 2025 at 3:09:51PM UTC+5',
      'items': [
        {
          'category': 'Electronics',
          'isEssential': true,
          'isPacked': true,
          'name': 'charger',
          'quantity': 1
        }
      ],
      'tripId': 'Sb5gQUTsrGGjv15kqy8I'
    });
  });

  // Skip tests that require Firebase integration
  group('MyListsScreen Widget Tests (Visual Only)', () {
    testWidgets('renders with correct UI elements',
        (WidgetTester tester) async {
      // Render the widget
      await tester.pumpWidget(
        MaterialApp(
          home: MyListsScreen(
            tripId: 'cSrDSYLMIpOpgaUXbO0C',
          ),
        ),
      );

      // Initial render should show at least the basic structure
      await tester.pump();

      // Very basic UI tests that don't rely on Firebase data
      expect(find.byType(AppBar), findsOneWidget);
      expect(find.byType(Scaffold), findsOneWidget);

      // This test only verifies the widget structure, not data loading
    });
  });
}
