import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:async';
import 'package:aifinanceapp/screens/home_screen.dart';

class VerifyEmailPage extends StatefulWidget {
  final String email;
  const VerifyEmailPage({
    super.key,
    required this.email,
    required bool fromGoogleSignIn,
  });

  @override
  State<VerifyEmailPage> createState() => _VerifyEmailPageState();
}

class _VerifyEmailPageState extends State<VerifyEmailPage> {
  bool _isLoading = false;
  bool _isEmailVerified = false;
  Timer? _timer;

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
    await FirebaseAuth.instance.currentUser?.reload();
    final isVerified =
        FirebaseAuth.instance.currentUser?.emailVerified ?? false;

    if (isVerified && !_isEmailVerified) {
      if (mounted) {
        setState(() {
          _isEmailVerified = true;
        });
        _timer?.cancel();

        // Navigate to home screen or wherever you want after verification
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const HomeScreen()),
        );
      }
    }
  }

  Future<void> _resendVerificationEmail() async {
    try {
      setState(() {
        _isLoading = true;
      });

      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        await user.sendEmailVerification();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Verification email sent!')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to send verification email: $e')),
      );
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
        backgroundColor: const Color.fromARGB(255, 48, 98, 206),
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
              color: _isEmailVerified
                  ? Colors.green
                  : const Color.fromARGB(255, 48, 98, 206),
            ),
            const SizedBox(height: 24),
            Text(
              _isEmailVerified ? 'Email Verified!' : 'Verify Your Email',
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Color.fromARGB(
                  255,
                  48,
                  98,
                  206,
                ), // Changed to match app's primary color
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
                        backgroundColor: const Color.fromARGB(255, 48, 98, 206),
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
                  FirebaseAuth.instance.signOut();
                  Navigator.popUntil(context, (route) => route.isFirst);
                },
                child: const Text(
                  'Back to Login',
                  style: TextStyle(color: Colors.white, fontSize: 16),
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                "Didn't receive the email? Check your spam folder.",
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white),
              ),
            ],
            if (_isEmailVerified) ...[
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (_) => const HomeScreen()),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color.fromARGB(255, 48, 98, 206),
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
