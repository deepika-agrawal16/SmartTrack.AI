// ignore: unused_import
import 'dart:io'; // Still needed if you handle other file types or local ops elsewhere
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:aifinanceapp/features/onboarding/data/services/user_profile_service.dart';
import 'package:rxdart/rxdart.dart';
import 'package:flutter/foundation.dart';

part 'user_profile_providers.g.dart';

@Riverpod(keepAlive: true)
// ignore: deprecated_member_use_from_same_package
UserProfileService userProfileService(UserProfileServiceRef ref) {
  return UserProfileService();
}

@Riverpod(keepAlive: true)
class UserProfileNotifier extends _$UserProfileNotifier {
  @override
  Map<String, dynamic> build() {
    return {};
  }

  // --- MODIFIED: Accepts profileImageUrl (String) instead of profileImageFile (File) ---
  Future<void> saveUserProfile({
    required String userName,
    String? profileImageUrl, // Now accepts the Cloudinary URL
  }) async {
    debugPrint('UserProfileNotifier: Attempting to save profile...');
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      debugPrint('UserProfileNotifier: User not logged in during saveUserProfile.');
      throw Exception('User not logged in.');
    }

    final userProfileService = ref.read(userProfileServiceProvider);

    // Call the service to save the user profile with the Cloudinary URL
    await userProfileService.saveUserProfile(
      uid: user.uid,
      userName: userName,
      profileImageUrl: profileImageUrl, // Pass the Cloudinary URL
      onboardingComplete: true,
    );

    await userProfileService.updateAuthDisplayName(userName);

    // Update the state to reflect the new profile data including the Cloudinary URL
    state = {
      'userName': userName,
      'profileImageUrl': profileImageUrl, // Store Cloudinary URL in state
      'onboardingComplete': true,
    };
    debugPrint('UserProfileNotifier: Profile save process completed with Cloudinary URL. State updated.');
  }

  Future<void> fetchUserProfile() async {
    debugPrint('UserProfileNotifier: Attempting to fetch profile...');
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      debugPrint('UserProfileNotifier: No user logged in for fetching profile.');
      state = {};
      return;
    }
    final userProfileService = ref.read(userProfileServiceProvider);
    final profileData = await userProfileService.getUserProfile(user.uid);
    if (profileData != null) {
      state = profileData;
      debugPrint('UserProfileNotifier: Profile fetched and state updated.');
    } else {
      state = {};
      debugPrint('UserProfileNotifier: No profile data found for user.');
    }
  }
}

@Riverpod(keepAlive: true)
// ignore: deprecated_member_use_from_same_package
Stream<Map<String, dynamic>?> currentUserProfile(CurrentUserProfileRef ref) {
  final auth = FirebaseAuth.instance;
  return auth.authStateChanges().distinct().switchMap((user) {
    debugPrint('currentUserProfileProvider: Auth state changed. User: ${user?.uid}');
    if (user == null) {
      return Stream.value(null);
    }
    return FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .snapshots()
        .map((snapshot) {
          debugPrint('currentUserProfileProvider: Firestore snapshot received for ${user.uid}. Exists: ${snapshot.exists}');
          if (snapshot.exists) {
            debugPrint('currentUserProfileProvider: Snapshot data: ${snapshot.data()}');
            return snapshot.data();
          }
          return null;
        })
        .onErrorReturnWith((error, stackTrace) {
          debugPrint('currentUserProfileProvider: Error fetching profile snapshot: $error');
          return null;
        });
  });
}