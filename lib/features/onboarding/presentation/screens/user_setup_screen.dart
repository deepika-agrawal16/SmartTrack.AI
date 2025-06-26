import 'dart:io';
import 'package:aifinanceapp/features/authentication/presentation/providers/auth_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cloudinary_sdk/cloudinary_sdk.dart'; // IMPORTANT: Add this import!

import 'package:aifinanceapp/features/onboarding/presentation/providers/user_profile_providers.dart';

class UserSetupScreen extends ConsumerStatefulWidget {
  const UserSetupScreen({super.key});

  @override
  ConsumerState<UserSetupScreen> createState() => _UserSetupScreenState();
}

class _UserSetupScreenState extends ConsumerState<UserSetupScreen> {
  final TextEditingController _nameController = TextEditingController();
  File? _profileImage;
  bool _isLoading = false;

  // --- Cloudinary Configuration for 5.x.x ---
  // CORRECTED: Initialize Cloudinary using Cloudinary.unsignedConfig
  // This constructor is specifically for unsigned uploads in 5.x.x
  final Cloudinary _cloudinary = Cloudinary.full(
    cloudName: 'dxmxvnv9r',
    apiKey: '359143929514693',
    apiSecret: 'FrbBrRsME4mgwqlFAkf3fkSPUZk',
  );
  // Your actual Cloudinary Cloud Name

  // Your Unsigned Upload Preset Name: 'ejhvgnx5'
  // This must be set up in your Cloudinary dashboard settings -> Upload -> Upload presets
  final String _cloudinaryUploadPreset = 'ejhvgnx5';

  // Your API Key and API Secret are NOT needed for unsigned client-side uploads.
  // Keep them secure and do not embed them directly in your Flutter app.
  // --- End Cloudinary Configuration ---

  final Color _primaryColor = const Color.fromARGB(255, 48, 98, 206);

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _profileImage = File(pickedFile.path);
      });
    }
  }

  Future<void> _saveUserData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('User not logged in.')));
      }
      return;
    }

    if (_nameController.text.trim().isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please enter your name.')),
        );
      }
      return;
    }

    setState(() {
      _isLoading = true;
    });

    String? profileImageUrl; // This will hold the URL from Cloudinary

    try {
      if (_profileImage != null) {
        debugPrint('Attempting to upload image to Cloudinary...');
        // CORRECTED for 5.x.x:
        // - 'file' parameter expects File object directly, not just path.
        // - 'resourceType' is typically lowercase 'image' in 5.x.x examples.
        // - 'uploadPreset' is now a direct named parameter, not inside 'params'.
        // ignore: deprecated_member_use
        final response = await _cloudinary.uploadFile(
          filePath: _profileImage!.path, // Pass the file path as a String
          resourceType: CloudinaryResourceType
              .image, // Likely lowercase 'image' for v5.x.x
          folder: 'aifinanceapp_profiles',
          optParams: {'upload_preset': _cloudinaryUploadPreset},
        );

        if (response.isSuccessful && response.secureUrl != null) {
          profileImageUrl = response.secureUrl;
          debugPrint(
            'Image uploaded successfully to Cloudinary. URL: $profileImageUrl',
          );
        } else {
          // Handle Cloudinary upload failure
          debugPrint('Cloudinary upload failed: ${response.error}');
          throw Exception('Image upload failed: ${response.error}');
        }
      }

      // Save user data (name and Cloudinary image URL) to Firestore via provider
      await ref
          .read(userProfileNotifierProvider.notifier)
          .saveUserProfile(
            userName: _nameController.text.trim(),
            profileImageUrl: profileImageUrl, // Pass the Cloudinary URL
          );

      // Invalidate the onboardingStatusProvider to force main.dart to re-evaluate the navigation.
      ref.invalidate(onboardingStatusProvider);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to save user data: ${e.toString()}')),
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
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Complete Your Profile',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            GestureDetector(
              onTap: _pickImage,
              child: CircleAvatar(
                radius: 60,
                backgroundColor: Colors.grey[200],
                backgroundImage: _profileImage != null
                    ? FileImage(_profileImage!)
                    : const AssetImage('assets/default_avatar.png')
                          as ImageProvider,
                child: _profileImage == null
                    ? Icon(Icons.camera_alt, size: 40, color: Colors.grey[600])
                    : null,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Upload Profile Picture',
              style: TextStyle(fontSize: 16, color: Colors.grey[700]),
            ),
            const SizedBox(height: 30),
            TextField(
              controller: _nameController,
              decoration: InputDecoration(
                labelText: 'Your Name',
                hintText: 'Enter your full name',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                prefixIcon: Icon(Icons.person, color: _primaryColor),
                filled: true,
                fillColor: Colors.grey[100],
              ),
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 40),
            _isLoading
                ? const CircularProgressIndicator()
                : ElevatedButton(
                    onPressed: _saveUserData,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _primaryColor,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 50,
                        vertical: 15,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'Continue',
                      style: TextStyle(fontSize: 18, color: Colors.white),
                    ),
                  ),
          ],
        ),
      ),
    );
  }
}
