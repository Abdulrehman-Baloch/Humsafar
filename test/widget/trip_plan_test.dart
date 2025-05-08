import 'package:flutter_test/flutter_test.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:mockito/mockito.dart';
import 'package:humsafar_app/models/trip_plan.dart';

// Create a mock that provides the DocumentSnapshot interface
class MockDocumentSnapshot extends Mock
    implements DocumentSnapshot<Map<String, dynamic>> {
  final String _id;
  final Map<String, dynamic> _data;

  MockDocumentSnapshot({required String id, required Map<String, dynamic> data})
      : _id = id,
        _data = data;

  @override
  String get id => _id;

  @override
  Map<String, dynamic>? data() => _data;

  @override
  dynamic get(dynamic field) => _data[field];
}

void main() {
  group('TripPlan Model Tests', () {
    test('fromFirestore and toMap Test', () {
      // Create mock data
      final mockData = {
        'name': 'winter break 2025',
        'userEmail': 'ayesh@gmail.com',
        'userID': 'UuJ8jqsGidPTaY8ZPAR1qjBsszi2',
        'numberOfTravelers': 2,
        'totalDays': 9,
        'startDate': Timestamp.fromDate(DateTime(2025, 5, 1)),
        'endDate': Timestamp.fromDate(DateTime(2025, 5, 8)),
        'createdAt': Timestamp.fromDate(DateTime.now()),
        'updatedAt': Timestamp.fromDate(DateTime.now()),
        'isCompleted': false,
      };

      // Create properly typed mock snapshot
      final mockDoc = MockDocumentSnapshot(
        id: 'Sb5gQUTsrGGjv15kqy8I',
        data: mockData,
      );

      // Test fromFirestore
      final tripPlan = TripPlan.fromFirestore(mockDoc);

      // Verify fields
      expect(tripPlan.id, 'Sb5gQUTsrGGjv15kqy8I');
      expect(tripPlan.name, 'winter break 2025');
      expect(tripPlan.numberOfTravelers, 2);
      expect(tripPlan.totalDays, 9);
      expect(tripPlan.isCompleted, false);

      // Test toMap
      final map = tripPlan.toMap();
      expect(map['name'], 'winter break 2025');
      expect(map['numberOfTravelers'], 2);
    });
  });

  group('TripDestination Model Tests', () {
    test('fromFirestore and toMap Test', () {
      // Create mock data
      final mockData = {
        'destinationId': '26o3aYc6yU1Zr24RKuGq',
        'destinationName': 'Swat Valley',
        'daysOfStay': 9,
        'startDate': Timestamp.fromDate(DateTime(2025, 6, 1)),
        'endDate': Timestamp.fromDate(DateTime(2025, 6, 4)),
        'addedAt': Timestamp.fromDate(DateTime(2025, 3, 1)),
        'notes': 'Beautiful valley in Pakistan',
      };

      // Create properly typed mock snapshot
      final mockDoc = MockDocumentSnapshot(
        id: '26o3aYc6yU1Zr24RKuGq',
        data: mockData,
      );

      // Test fromFirestore
      final destination = TripDestination.fromFirestore(mockDoc);

      // Verify fields
      expect(destination.id, '26o3aYc6yU1Zr24RKuGq');
      expect(destination.destinationName, 'Swat Valley');
      expect(destination.daysOfStay, 9);
      expect(destination.notes, 'Beautiful valley in Pakistan');

      // Test toMap
      final map = destination.toMap();
      expect(map['destinationName'], 'Swat Valley');
      expect(map['daysOfStay'], 9);
    });
  });
}
