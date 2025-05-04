import 'package:cloud_firestore/cloud_firestore.dart';

class PackingList {
  final String id;
  final String name;
  final DateTime createdAt;
  final List<PackingItem> items;
  final String? tripId; // Add this

  PackingList({
    required this.id,
    required this.name,
    required this.createdAt,
    required this.items,
    this.tripId,
  });
  // Getter to check if all items are packed
  bool get isCompleted {
    if (items.isEmpty) return false;
    return items.every((item) => item.isPacked);
  }

  // Create a PackingList from a Firestore document
  factory PackingList.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    final Timestamp timestamp = data['createdAt'] as Timestamp;

    return PackingList(
      id: doc.id,
      name: data['name'] ?? '',
      items: (data['items'] as List<dynamic>?)
              ?.map((item) => PackingItem.fromMap(item as Map<String, dynamic>))
              .toList() ??
          [],
      createdAt: timestamp.toDate(),
      tripId: data['tripId'],
    );
  }

  // Convert a PackingList to a Map for Firestore
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'items': items.map((item) => item.toMap()).toList(),
      'createdAt': Timestamp.fromDate(createdAt),
      'tripId': tripId,
    };
  }
}

class PackingItem {
  final String name;
  final String category;
  bool isPacked;
  bool isEssential;
  int quantity;

  PackingItem({
    required this.name,
    required this.category,
    this.isPacked = false,
    this.isEssential = false,
    this.quantity = 1,
  });
  // Convert a PackingItem to a Map for Firestore
  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'category': category,
      'isEssential': isEssential,
      'isPacked': isPacked,
      'quantity': quantity,
    };
  }

  // Create a PackingItem from a Firestore document
  factory PackingItem.fromMap(Map<String, dynamic> map) {
    return PackingItem(
      name: map['name'] ?? '',
      category: map['category'] ?? 'Other',
      isEssential: map['isEssential'] ?? false,
      isPacked: map['isPacked'] ?? false,
      quantity: map['quantity'] ?? 1,
    );
  }
}
