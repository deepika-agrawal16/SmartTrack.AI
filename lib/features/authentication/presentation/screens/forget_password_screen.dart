import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart'; // Import Riverpod
import 'package:aifinanceapp/features/authentication/presentation/providers/auth_provider.dart'; // Import auth providers

class ForgetPasswordPage extends ConsumerStatefulWidget { // Changed to ConsumerStatefulWidget
  const ForgetPasswordPage({super.key});

  @override
  ConsumerState<ForgetPasswordPage> createState() => _ForgetPasswordPageState(); // Changed to ConsumerState
}

class _ForgetPasswordPageState extends ConsumerState<ForgetPasswordPage> { // Changed to ConsumerState
  final TextEditingController _emailController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _sendResetEmail() async {
    final email = _emailController.text.trim();

    if (email.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter your email address')),
      );
      return;
    }

    // Access the AuthNotifier to send the reset email
    final authNotifier = ref.read(authNotifierProvider.notifier);

    try {
      await authNotifier.sendPasswordResetEmail(email);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Password reset link sent to your email')),
        );
        Navigator.pop(context); // Go back to login page
      }
    } catch (e) {
      if (mounted) {
        String message = 'Failed to send reset email.';
        // FirebaseAuthException provides more specific error codes
        // Check for common error types (though a generic message might be fine for user)
        if (e.toString().contains('user-not-found')) { // Checking string as direct `e.code` might not be available for all `e`
          message = 'No user found with this email.';
        } else if (e.toString().contains('invalid-email')) {
          message = 'The email address is badly formatted.';
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(message)),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Watch the loading state from authNotifierProvider
    final isLoading = ref.watch(authNotifierProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Forgot Password',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: const Color.fromARGB(255, 48, 98, 206),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'Enter your email to receive password reset instructions.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _emailController,
              decoration: const InputDecoration(
                labelText: 'Email',
                prefixIcon: Icon(Icons.email),
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.emailAddress,
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: isLoading ? null : _sendResetEmail, // Disable when loading
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color.fromARGB(255, 48, 98, 206),
                ),
                child: isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text(
                        'Send Reset Link',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
