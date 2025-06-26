import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart'; // Import Riverpod

// Import auth providers from new path
import 'package:aifinanceapp/features/authentication/presentation/providers/auth_provider.dart';

class VerifyEmailPage extends ConsumerStatefulWidget { // Changed to ConsumerStatefulWidget
  final String email;
  // Kept `fromGoogleSignIn` as per your original code, though its direct use might be reduced
  final bool fromGoogleSignIn;

  const VerifyEmailPage({
    super.key,
    required this.email,
    required this.fromGoogleSignIn,
  });

  @override
  ConsumerState<VerifyEmailPage> createState() => _VerifyEmailPageState(); // Changed to ConsumerState
}

class _VerifyEmailPageState extends ConsumerState<VerifyEmailPage> { // Changed to ConsumerState
  bool _isLoading = false;
  bool _isEmailVerified = false;
  Timer? _timer;

  final Color _primaryColor = const Color.fromARGB(255, 48, 98, 206);

  @override
  void initState() {
    super.initState();
    _checkEmailVerification();
    // Check every 3 seconds if email is verified
    _timer = Timer.periodic(
      const Duration(seconds: 3),
      (_) => _checkEmailVerification(),
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _checkEmailVerification() async {
    // Reload the user to get the latest email verification status
    await FirebaseAuth.instance.currentUser?.reload();
    final isVerified =
        FirebaseAuth.instance.currentUser?.emailVerified ?? false;

    if (isVerified && !_isEmailVerified) {
      if (mounted) {
        setState(() {
          _isEmailVerified = true;
        });
        _timer?.cancel(); // Stop the timer once verified

        // No explicit navigation here. main.dart's StreamBuilder will detect
        // the verified state and route the user to UserSetupScreen or DashboardScreen.
        // It's generally better to let the root widget handle top-level routing
        // based on global authentication/onboarding state.
      }
    }
  }

  Future<void> _resendVerificationEmail() async {
    // Access the AuthNotifier to send the verification email
    final authNotifier = ref.read(authNotifierProvider.notifier);

    try {
      setState(() {
        _isLoading = true;
      });

      await authNotifier.sendEmailVerification(); // Use the AuthNotifier method

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Verification email sent!')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to send verification email: ${e.toString()}')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Verify Email'),
        backgroundColor: _primaryColor,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Icon(
              _isEmailVerified ? Icons.verified : Icons.mark_email_unread,
              size: 80,
              color: _isEmailVerified ? Colors.green : _primaryColor,
            ),
            const SizedBox(height: 24),
            Text(
              _isEmailVerified ? 'Email Verified!' : 'Verify Your Email',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: _primaryColor,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              _isEmailVerified
                  ? 'Your email has been successfully verified.'
                  : 'A verification email has been sent to:',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 8),
            Text(
              widget.email,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 24),
            if (!_isEmailVerified) ...[
              _isLoading
                  ? const CircularProgressIndicator()
                  : ElevatedButton(
                      onPressed: _resendVerificationEmail,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _primaryColor,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 12,
                        ),
                      ),
                      child: const Text(
                        'Resend Verification Email',
                        style: TextStyle(fontSize: 16, color: Colors.white),
                      ),
                    ),
              const SizedBox(height: 16),
              TextButton(
                onPressed: () {
                  // Sign out and go back to the very first route (LandingPage)
                  FirebaseAuth.instance.signOut();
                  // This pops all routes until the first one, which main.dart will then handle
                  // and show LandingPage or Login based on auth state.
                  Navigator.popUntil(context, (route) => route.isFirst);
                },
                child: Text(
                  'Back to Login',
                  style: TextStyle(color: _primaryColor, fontSize: 16), // Match primary color
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                "Didn't receive the email? Check your spam folder.",
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey), // Adjusted for better visibility
              ),
            ],
            // If email is verified, show a "Continue" button
            if (_isEmailVerified) ...[
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () {
                  // No explicit navigation here. main.dart's StreamBuilder will detect
                  // the verified state and route the user to UserSetupScreen or DashboardScreen.
                  // Just pop the current screen if it's not the root, or let main.dart handle.
                  if (Navigator.of(context).canPop()) {
                    Navigator.pop(context);
                  }
                  // Even if it can't pop, main.dart's StreamBuilder will kick in.
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: _primaryColor,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                ),
                child: const Text(
                  'Continue',
                  style: TextStyle(fontSize: 16, color: Colors.white),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
