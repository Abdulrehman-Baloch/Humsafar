// trip_plan_repository.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:humsafar_app/models/trip_plan.dart';
import 'package:humsafar_app/models/destination.dart';

class TripPlanRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Collection references
  CollectionReference get _tripPlansCollection =>
      _firestore.collection('tripPlans');
  CollectionReference get _destinationsCollection =>
      _firestore.collection('destinations');

  // Get all destinations from Firestore
  Future<List<Destination>> getAllDestinations() async {
    final snapshot = await _destinationsCollection.get();
    List<Destination> destinations = [];

    for (var doc in snapshot.docs) {
      final destination = Destination.fromFirestore(doc);

      // Load local attractions for each destination
      try {
        final attractionsSnapshot = await _destinationsCollection
            .doc(destination.id)
            .collection('localAttractions')
            .get();

        List<LocalAttraction> attractions = attractionsSnapshot.docs
            .map(
                (attractionDoc) => LocalAttraction.fromFirestore(attractionDoc))
            .toList();

        // Create a new destination with the loaded attractions
        destinations.add(Destination(
          id: destination.id,
          name: destination.name,
          rating: destination.rating,
          description: destination.description,
          imageUrl: destination.imageUrl,
          ttv: destination.ttv,
          weather: destination.weather,
          searchKeywords: destination.searchKeywords,
          region: destination.region,
          category: destination.category,
          location: destination.location,
          localAttractions: attractions,
        ));
      } catch (e) {
        // If there's an error loading attractions, just add the destination without them
        destinations.add(destination);
      }
    }

    return destinations;
  }

  // Save a trip plan to Firestore
  Future<String> saveTripPlan(TripPlan tripPlan) async {
    try {
      // First, create the main trip plan document
      final tripPlanRef = await _tripPlansCollection.add(tripPlan.toMap());
      final tripPlanId = tripPlanRef.id;

      // Then, save all destinations as subcollection documents
      for (var destination in tripPlan.destinations) {
        await tripPlanRef
            .collection('tripDestinations')
            .add(destination.toMap());
      }

      return tripPlanId;
    } catch (e) {
      throw Exception('Failed to save trip plan: $e');
    }
  }

  // Get all trip plans for a user
  Future<List<TripPlan>> getTripPlansForUser(String userId) async {
    try {
      final snapshot = await _tripPlansCollection
          .where('userId', isEqualTo: userId)
          .orderBy('createdAt', descending: true)
          .get();

      // Create a list of trip plans without destinations first
      List<TripPlan> tripPlans =
          snapshot.docs.map((doc) => TripPlan.fromFirestore(doc)).toList();

      // For each trip plan, get its destinations
      for (int i = 0; i < tripPlans.length; i++) {
        final destSnapshot = await _tripPlansCollection
            .doc(tripPlans[i].id)
            .collection('tripDestinations')
            .get();

        final destinations = destSnapshot.docs
            .map((doc) => TripDestination.fromFirestore(doc))
            .toList();

        // We need to create a new TripPlan object with the destinations
        tripPlans[i] = TripPlan(
          id: tripPlans[i].id,
          name: tripPlans[i].name,
          userEmail: tripPlans[i].userEmail,
          userID: tripPlans[i].userID,
          numberOfTravelers: tripPlans[i].numberOfTravelers,
          totalDays: tripPlans[i].totalDays,
          startDate: tripPlans[i].startDate,
          endDate: tripPlans[i].endDate,
          createdAt: tripPlans[i].createdAt,
          updatedAt: tripPlans[i].updatedAt,
          isCompleted: tripPlans[i].isCompleted,
          destinations: destinations,
        );
      }

      return tripPlans;
    } catch (e) {
      throw Exception('Failed to get trip plans: $e');
    }
  }

  // Get a single trip plan by ID
  Future<TripPlan> getTripPlanById(String tripPlanId) async {
    try {
      final doc = await _tripPlansCollection.doc(tripPlanId).get();
      final tripPlan = TripPlan.fromFirestore(doc);

      // Get destinations for this trip plan
      final destSnapshot = await _tripPlansCollection
          .doc(tripPlanId)
          .collection('tripDestinations')
          .get();

      final destinations = destSnapshot.docs
          .map((doc) => TripDestination.fromFirestore(doc))
          .toList();

      // Return a new TripPlan with the destinations
      return TripPlan(
        id: tripPlan.id,
        name: tripPlan.name,
        userEmail: tripPlan.userEmail,
        userID: tripPlan.userID,
        numberOfTravelers: tripPlan.numberOfTravelers,
        totalDays: tripPlan.totalDays,
        startDate: tripPlan.startDate,
        endDate: tripPlan.endDate,
        createdAt: tripPlan.createdAt,
        updatedAt: tripPlan.updatedAt,
        isCompleted: tripPlan.isCompleted,
        destinations: destinations,
      );
    } catch (e) {
      throw Exception('Failed to get trip plan: $e');
    }
  }

  // Update a trip plan
  Future<void> updateTripPlan(TripPlan tripPlan) async {
    try {
      if (tripPlan.id == null) {
        throw Exception('Cannot update a trip plan without an ID');
      }

      // Update the main document
      await _tripPlansCollection.doc(tripPlan.id).update({
        'name': tripPlan.name,
        'numberOfTravelers': tripPlan.numberOfTravelers,
        'totalDays': tripPlan.totalDays,
        'startDate': Timestamp.fromDate(tripPlan.startDate),
        'endDate': Timestamp.fromDate(tripPlan.endDate),
        'updatedAt': Timestamp.fromDate(DateTime.now()),
        'isCompleted': tripPlan.isCompleted,
      });

      // Delete all existing destinations
      final destSnapshot = await _tripPlansCollection
          .doc(tripPlan.id)
          .collection('tripDestinations')
          .get();

      for (var doc in destSnapshot.docs) {
        await doc.reference.delete();
      }

      // Add the new destinations
      for (var destination in tripPlan.destinations) {
        await _tripPlansCollection
            .doc(tripPlan.id)
            .collection('tripDestinations')
            .add(destination.toMap());
      }
    } catch (e) {
      throw Exception('Failed to update trip plan: $e');
    }
  }

  // Delete a trip plan
  Future<void> deleteTripPlan(String tripPlanId) async {
    try {
      // First delete all destinations
      final destSnapshot = await _tripPlansCollection
          .doc(tripPlanId)
          .collection('tripDestinations')
          .get();

      for (var doc in destSnapshot.docs) {
        await doc.reference.delete();
      }

      // Then delete the main document
      await _tripPlansCollection.doc(tripPlanId).delete();
    } catch (e) {
      throw Exception('Failed to delete trip plan: $e');
    }
  }
}
