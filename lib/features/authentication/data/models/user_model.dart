import 'package:cloud_firestore/cloud_firestore.dart';

class User {
  final String id;
  final String userName;
  final bool onboardingComplete;
  final String? profileImagePath; // This should be the Cloudinary URL
  final double? monthlyBudget; // Add this field for AI context

  User({
    required this.id,
    required this.userName,
    required this.onboardingComplete,
    this.profileImagePath,
    this.monthlyBudget,
  });

  // Factory constructor to create a User object from a Firestore DocumentSnapshot
  factory User.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;

    // Safely retrieve values, providing defaults or handling nulls
    return User(
      id: doc.id,
      userName: data['userName'] as String? ?? 'N/A', // Provide a default if null
      onboardingComplete: data['onboardingComplete'] as bool? ?? false, // Default to false
      profileImagePath: data['profileImagePath'] as String?,
      monthlyBudget: (data['monthlyBudget'] as num?)?.toDouble(), // Safely cast to double
    );
  }

  // Convert a User object to a Firestore-compatible Map
  Map<String, dynamic> toFirestore() {
    return {
      'userName': userName,
      'onboardingComplete': onboardingComplete,
      'profileImagePath': profileImagePath,
      'monthlyBudget': monthlyBudget,
      // Do NOT include 'id' here, as it's the document ID in Firestore
    };
  }

  // For debugging and logging (optional)
  @override
  String toString() {
    return 'User(id: $id, userName: $userName, onboardingComplete: $onboardingComplete, '
           'profileImagePath: $profileImagePath, monthlyBudget: $monthlyBudget)';
  }
}