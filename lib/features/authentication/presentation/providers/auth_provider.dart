import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; // For checking onboarding status
import 'package:aifinanceapp/features/authentication/data/services/auth_service.dart'; // Import AuthService

// Provide the AuthService instance
final authServiceProvider = Provider<AuthService>((ref) => AuthService());

// Provider for the current Firebase User (User? means it can be null)
final authStateChangesProvider = StreamProvider<User?>(
  (ref) => FirebaseAuth.instance.authStateChanges(),
);

// StateNotifierProvider for authentication logic and loading state
class AuthNotifier extends StateNotifier<bool> {
  final Ref ref;
  AuthNotifier(this.ref) : super(false);

  Future<void> signInWithEmail(String email, String password) async {
    state = true; // Set loading to true
    try {
      await ref.read(authServiceProvider).signInWithEmail(email, password);
      // State will be handled by authStateChanges stream
    } catch (e) {
      rethrow; // Rethrow to be caught by UI
    } finally {
      state = false; // Set loading to false
    }
  }

  Future<void> signUpWithEmail(String email, String password) async {
    state = true; // Set loading to true
    try {
      await ref.read(authServiceProvider).signUpWithEmail(email, password);
      // After signup, send verification email
      await ref.read(authServiceProvider).sendEmailVerification();
    } catch (e) {
      rethrow; // Rethrow to be caught by UI
    } finally {
      state = false; // Set loading to false
    }
  }

  Future<void> signInWithGoogle() async {
    state = true; // Set loading to true
    try {
      await ref.read(authServiceProvider).signInWithGoogle();
      // State will be handled by authStateChanges stream
    } catch (e) {
      rethrow; // Rethrow to be caught by UI
    } finally {
      state = false; // Set loading to false
    }
  }

  Future<void> signOut() async {
    state = true; // Set loading to true
    try {
      await ref.read(authServiceProvider).signOut();
    } catch (e) {
      rethrow; // Rethrow to be caught by UI
    } finally {
      state = false; // Set loading to false
    }
  }

  Future<void> sendPasswordResetEmail(String email) async {
    state = true;
    try {
      await ref.read(authServiceProvider).sendPasswordResetEmail(email);
    } catch (e) {
      rethrow;
    } finally {
      state = false;
    }
  }
  Future<void> sendEmailVerification() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null && !user.emailVerified) {
      await user.sendEmailVerification();
    }
  }
}

final authNotifierProvider =
    StateNotifierProvider<AuthNotifier, bool>((ref) => AuthNotifier(ref));

// Provider to check if user onboarding is complete
final onboardingStatusProvider = FutureProvider<bool>((ref) async {
  final user = ref.watch(authStateChangesProvider).value; // Get current user from auth state
  if (user == null) {
    return false; // Not logged in, so onboarding isn't complete
  }

  // Try to fetch user data from Firestore
  try {
    final docSnapshot = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
    return docSnapshot.exists && (docSnapshot.data()?['onboardingComplete'] == true);
  } catch (e) {
    // Log error but assume false to not block user flow unnecessarily
    debugPrint('Error checking onboarding status: $e');
    return false;
  }
});
