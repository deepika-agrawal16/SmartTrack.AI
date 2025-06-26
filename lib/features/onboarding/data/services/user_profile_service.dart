// ignore: unused_import
import 'dart:io'; // Still needed if you handle other file types or local ops elsewhere
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
// import 'package:path_provider/path_provider.dart'; // No longer needed for local image saving

class UserProfileService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // --- MODIFIED: Accepts profileImageUrl (String) instead of profileImagePath ---
  Future<void> saveUserProfile({
    required String uid,
    required String userName,
    String? profileImageUrl, // Now stores the Cloudinary URL
    required bool onboardingComplete,
  }) async {
    debugPrint('UserProfileService: Attempting to save user profile for UID: $uid');
    debugPrint('UserProfileService: Name: $userName, Image URL: $profileImageUrl, Onboarding Complete: $onboardingComplete');
    try {
      await _firestore.collection('users').doc(uid).set({
        'userName': userName,
        'profileImageUrl': profileImageUrl, // Storing Cloudinary URL
        'onboardingComplete': onboardingComplete,
        'createdAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
      debugPrint('UserProfileService: User profile saved successfully for UID: $uid');
    } catch (e) {
      debugPrint('UserProfileService: Error saving user profile for UID: $uid - $e');
      throw Exception('Failed to save user profile: $e');
    }
  }

  

  // Fetch user profile data from Firestore (now expecting profileImageUrl)
  Future<Map<String, dynamic>?> getUserProfile(String uid) async {
    debugPrint('UserProfileService: Attempting to fetch user profile for UID: $uid');
    try {
      final docSnapshot = await _firestore.collection('users').doc(uid).get();
      if (docSnapshot.exists) {
        debugPrint('UserProfileService: Fetched profile data: ${docSnapshot.data()}');
        return docSnapshot.data();
      } else {
        debugPrint('UserProfileService: Profile document does not exist for UID: $uid');
        return null;
      }
    } catch (e) {
      debugPrint('UserProfileService: Error fetching user profile for UID: $uid - $e');
      return null;
    }
  }

  // Update Firebase Auth user's display name (no change here)
  Future<void> updateAuthDisplayName(String newName) async {
    final user = _auth.currentUser;
    if (user != null) {
      debugPrint('UserProfileService: Updating Firebase Auth display name to: $newName');
      try {
        await user.updateDisplayName(newName);
        debugPrint('UserProfileService: Firebase Auth display name updated.');
      } catch (e) {
        debugPrint('UserProfileService: Error updating Firebase Auth display name: $e');
      }
    }
  }
}