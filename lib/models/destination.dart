import 'package:cloud_firestore/cloud_firestore.dart';

class Destination {
  final String id;
  final String name;
  final double rating;
  final String description;
  final String imageUrl;
  final String? ttv; // Time to visit (best time to travel)
  final String? weather;
  final List<String>? searchKeywords;
  final String? region;
  final String? category;
  final Map<String, dynamic>? location;
  final List<LocalAttraction>? localAttractions;

  Destination({
    required this.id,
    required this.name,
    required this.rating,
    required this.description,
    required this.imageUrl,
    this.ttv,
    this.weather,
    this.searchKeywords,
    this.region,
    this.category,
    this.location,
    this.localAttractions,
  });

  factory Destination.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Destination(
      id: doc.id,
      name: data['name'] ?? '',
      rating: (data['rating'] is int)
          ? (data['rating'] as int).toDouble()
          : (data['rating'] ?? 0.0),
      description: data['description'] ?? '',
      imageUrl: data['imageUrl'] ?? '',
      ttv: data['ttv'],
      weather: data['weather'],
      searchKeywords: data['searchKeywords'] != null
          ? List<String>.from(data['searchKeywords'])
          : null,
      region: data['region'],
      category: data['category'],
      location: data['location'],
      localAttractions: null, // Will be loaded separately
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'rating': rating,
      'description': description,
      'imageUrl': imageUrl,
      'ttv': ttv,
      'weather': weather,
      'searchKeywords': searchKeywords,
      'region': region,
      'category': category,
      'location': location,
    };
  }
}

class LocalAttraction {
  final String id;
  final String name;
  final String? description;
  final String? imageUrl;
  final String? entryFee;

  LocalAttraction({
    required this.id,
    required this.name,
    this.description,
    this.imageUrl,
    this.entryFee,
  });

  factory LocalAttraction.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return LocalAttraction(
      id: doc.id,
      name: data['name'] ?? '',
      description: data['description'],
      imageUrl: data['imageUrl1'],
      entryFee: data['entryFee'],
    );
  }
}
