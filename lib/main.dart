import 'package:aifinanceapp/features/authentication/presentation/providers/auth_provider.dart';
import 'package:firebase_core/firebase_core.dart'; // Keep for general Firebase setup (Auth, Firestore)
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:aifinanceapp/features/authentication/presentation/screens/landing_screen.dart';
import 'package:aifinanceapp/features/onboarding/presentation/screens/user_setup_screen.dart';
import 'package:aifinanceapp/features/transactions/presentation/screens/dashboard_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Load .env file first
  await dotenv.load(fileName: ".env");

  // Initialize Firebase Core (without explicit options, relies on google-services.json)
  await Firebase.initializeApp();

  runApp(
    const ProviderScope(
      child: MyApp(),
    ),
  );
}

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authStateChangesProvider);

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: authState.when(
        data: (user) {
          if (user == null) {
            // User is not logged in, show LandingPage
            return const LandingPage();
          } else {
            // User is logged in, now check onboarding status
            final onboardingStatusAsync = ref.watch(onboardingStatusProvider);

            return onboardingStatusAsync.when(
              data: (isComplete) {
                if (isComplete) {
                  final userDisplayName = user.displayName ?? 'User';
                  return DashboardScreen(
                    userName: userDisplayName,
                    profileImage: null, // This can be null as DashboardScreen will fetch from Firestore
                  );
                } else {
                  // User is logged in but onboarding is not complete, show UserSetupScreen
                  return const UserSetupScreen();
                }
              },
              loading: () => const Scaffold(
                body: Center(child: CircularProgressIndicator()), // Loading onboarding status
              ),
              error: (error, stack) => Scaffold(
                body: Center(child: Text('Error loading profile: $error')),
              ),
            );
          }
        },
        loading: () => const Scaffold(
          body: Center(child: CircularProgressIndicator()), // Loading initial auth state
        ),
        error: (error, stack) => Scaffold(
          body: Center(child: Text('Error: $error')), // Handle initial auth error
        ),
      ),
    );
  }
}