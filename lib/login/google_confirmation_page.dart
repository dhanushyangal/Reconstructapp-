import 'package:flutter/material.dart';
import '../services/auth_service.dart';

class GoogleConfirmationPage extends StatelessWidget {
  final String email;
  final String displayName;
  final String initial;

  const GoogleConfirmationPage({
    super.key,
    required this.email,
    required this.displayName,
    required this.initial,
  });

  @override
  Widget build(BuildContext context) {
    final user = AuthService.instance.currentUser;

    // Get profile image URL from Supabase user metadata
    String? profileImageUrl;
    if (user?.userMetadata != null) {
      profileImageUrl = user!.userMetadata!['avatar_url'] ??
          user.userMetadata!['picture'] ??
          user.userMetadata!['profile_image_url'];
    }

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Logo
              Image.asset(
                'assets/reconstruct_transparent.png',
                height: 48,
                fit: BoxFit.contain,
              ),
              const SizedBox(height: 32),

              Text(
                'Jump back in!',
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const SizedBox(height: 32),

              // User Avatar
              CircleAvatar(
                radius: 40,
                backgroundColor:
                    Theme.of(context).primaryColor.withOpacity(0.1),
                backgroundImage: profileImageUrl != null
                    ? NetworkImage(profileImageUrl)
                    : null,
                child: profileImageUrl == null
                    ? Text(
                        initial,
                        style: TextStyle(
                          fontSize: 32,
                          color: Theme.of(context).primaryColor,
                        ),
                      )
                    : null,
              ),
              const SizedBox(height: 16),

              // User Info
              Text(
                displayName,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                email,
                style: const TextStyle(
                  color: Colors.grey,
                ),
              ),
              const SizedBox(height: 32),

              // Continue Button
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).primaryColor,
                  minimumSize: const Size(double.infinity, 50),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                onPressed: () {
                  Navigator.of(context)
                      .pushNamedAndRemoveUntil('/home', (route) => false);
                },
                child: const Text(
                  'Continue',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                  ),
                ),
              ),

              const SizedBox(height: 16),
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                },
                child: const Text('Continue with another account'),
              ),

              const Spacer(),
              // Terms text
              const Text(
                'By continuing, you agree to our',
                style: TextStyle(color: Colors.grey, fontSize: 12),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  TextButton(
                    onPressed: () {},
                    child: const Text(
                      'Terms of Use',
                      style: TextStyle(fontSize: 12),
                    ),
                  ),
                  const Text(
                    'and',
                    style: TextStyle(color: Colors.grey, fontSize: 12),
                  ),
                  TextButton(
                    onPressed: () {},
                    child: const Text(
                      'Privacy Policy',
                      style: TextStyle(fontSize: 12),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
