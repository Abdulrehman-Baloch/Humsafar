// lib/models/user.dart
import 'package:cloud_firestore/cloud_firestore.dart';

class User {
  final String uid;
  final String name;
  final String email;
  final DateTime createdAt;

  User({
    required this.uid,
    required this.name,
    required this.email,
    required this.createdAt,
  });

  // Create User from Firestore document
  factory User.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return User(
      uid: doc.id,
      name: data['name'] ?? '',
      email: data['email'] ?? '',
      createdAt: (data['createdAt'] as Timestamp).toDate(),
    );
  }

  // Convert User to a Map for Firestore
  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'email': email,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  // Copy user with some fields changed
  User copyWith({
    String? uid,
    String? name,
    String? email,
    DateTime? createdAt,
  }) {
    return User(
      uid: uid ?? this.uid,
      name: name ?? this.name,
      email: email ?? this.email,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  String toString() {
    return 'User(uid: $uid, name: $name, email: $email, createdAt: $createdAt)';
  }
}
