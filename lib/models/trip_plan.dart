// trip_plan.dart
import 'package:cloud_firestore/cloud_firestore.dart';

class TripPlan {
  final String? id;
  final String name;
  final String userEmail;
  final String userID; // Changed from userId to userID to match existing code
  final int numberOfTravelers;
  final int totalDays;
  final DateTime startDate;
  final DateTime endDate;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool isCompleted;
  final List<TripDestination> destinations;

  TripPlan({
    this.id,
    required this.name,
    required this.userEmail,
    required this.userID,
    required this.numberOfTravelers,
    required this.totalDays,
    required this.startDate,
    required this.endDate,
    required this.createdAt,
    required this.updatedAt,
    required this.isCompleted,
    required this.destinations,
  });

  factory TripPlan.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return TripPlan(
      id: doc.id,
      name: data['name'] ?? '',
      userEmail: data['userEmail'] ?? '',
      userID: data['userID'] ?? '',
      numberOfTravelers: data['numberOfTravelers'] ?? 0,
      totalDays: data['totalDays'] ?? 0,
      startDate: (data['startDate'] as Timestamp).toDate(),
      endDate: (data['endDate'] as Timestamp).toDate(),
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      updatedAt: (data['updatedAt'] as Timestamp).toDate(),
      isCompleted: data['isCompleted'] ?? false,
      destinations: [], // Will be populated separately
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'userEmail': userEmail,
      'userID': userID, // Changed to match existing code
      'numberOfTravelers': numberOfTravelers,
      'totalDays': totalDays,
      'startDate': Timestamp.fromDate(startDate),
      'endDate': Timestamp.fromDate(endDate),
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'isCompleted': isCompleted,
    };
  }
}

class TripDestination {
  final String? id;
  final String destinationId;
  final String destinationName;
  final int daysOfStay;
  final DateTime startDate;
  final DateTime endDate;
  final DateTime addedAt;
  final String? notes; // Added based on your existing code

  TripDestination({
    this.id,
    required this.destinationId,
    required this.destinationName,
    required this.daysOfStay,
    required this.startDate,
    required this.endDate,
    required this.addedAt,
    this.notes,
  });

  factory TripDestination.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return TripDestination(
      id: doc.id,
      destinationId: data['destinationId'] ?? '',
      destinationName: data['destinationName'] ?? '',
      daysOfStay: data['daysOfStay'] ?? 0,
      startDate: (data['startDate'] as Timestamp).toDate(),
      endDate: (data['endDate'] as Timestamp).toDate(),
      addedAt: data['addedAt'] != null
          ? (data['addedAt'] as Timestamp).toDate()
          : DateTime.now(),
      notes: data['notes'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'destinationId': destinationId,
      'destinationName': destinationName,
      'daysOfStay': daysOfStay,
      'startDate': Timestamp.fromDate(startDate),
      'endDate': Timestamp.fromDate(endDate),
      'addedAt': Timestamp.fromDate(addedAt),
      'notes': notes ?? '',
    };
  }
}
