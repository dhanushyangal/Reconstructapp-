import 'package:flutter/material.dart';
import 'login_page.dart';
import 'register_page.dart';
import '../services/auth_service.dart';
import 'google_confirmation_page.dart';
import '../utils/platform_features.dart';

class InitialAuthPage extends StatefulWidget {
  const InitialAuthPage({super.key});

  @override
  State<InitialAuthPage> createState() => _InitialAuthPageState();
}

class _InitialAuthPageState extends State<InitialAuthPage> {
  final AuthService _authService = AuthService();
  bool _isLoading = false;

  Future<void> _handleGoogleSignIn(BuildContext context) async {
    setState(() {
      _isLoading = true;
    });

    try {
      final userCredential = await _authService.signInWithGoogle();
      if (userCredential == null) {
        if (!context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Google sign in cancelled or failed')),
        );
      } else {
        if (!context.mounted) return;

        // Show confirmation page
        final user = userCredential.user!;
        final displayName = user.displayName ?? 'User';
        final initial = displayName[0].toUpperCase();

        if (!context.mounted) return;
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => GoogleConfirmationPage(
              email: user.email!,
              displayName: displayName,
              initial: initial,
            ),
          ),
        );
      }
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
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
      body: SafeArea(
        child: Stack(
          children: [
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Logo and Title
                  Image.asset(
                    'assets/reconstruct_transparent.png',
                    height: 48,
                    fit: BoxFit.contain,
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Continue to sign up for free',
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.black87,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'If you already have an account, we\'ll log you in.',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 48),

                  // Google Sign In Button - Only show on Android
                  PlatformFeatureWidget(
                    featureName: 'google_sign_in',
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.all(16),
                        side: const BorderSide(color: Colors.grey, width: 1),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      onPressed: _isLoading
                          ? null
                          : () => _handleGoogleSignIn(context),
                      icon: Image.asset('assets/google_logo.png', height: 24),
                      label: const Text(
                        'Continue with Google',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.black87,
                        ),
                      ),
                    ),
                  ),

                  // Show spacing only if Google Sign-In is available
                  PlatformFeatureWidget(
                    featureName: 'google_sign_in',
                    child: const SizedBox(height: 16),
                  ),

                  // Email Button
                  OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.all(16),
                      side: const BorderSide(color: Colors.grey, width: 1),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    onPressed: _isLoading
                        ? null
                        : () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    const LoginPage(showGoogleSignIn: false),
                              ),
                            );
                          },
                    icon: const Icon(Icons.email_outlined),
                    label: const Text(
                      'Continue with email',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.black87,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Other options
                  TextButton(
                    onPressed: _isLoading
                        ? null
                        : () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    const RegisterPage(showGoogleSignIn: false),
                              ),
                            );
                          },
                    child: const Text(
                      'Don\'t have an account? Sign up',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.black87,
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    icon: Icon(Icons.person_outline),
                    label: Text('Continue as Guest'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.grey[200],
                      foregroundColor: Colors.black,
                      minimumSize: const Size(double.infinity, 50),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    onPressed: _isLoading
                        ? null
                        : () async {
                            setState(() => _isLoading = true);
                            await AuthService.enableGuestMode();
                            await Future.delayed(const Duration(milliseconds: 300));
                            if (!mounted) return;
                            Navigator.of(context).pushNamedAndRemoveUntil('/home', (route) => false);
                          },
                  ),

                  const Spacer(),

                  // Terms and Privacy
                  const Text(
                    'By continuing, you agree to our',
                    style: TextStyle(color: Colors.grey, fontSize: 12),
                    textAlign: TextAlign.center,
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      TextButton(
                        onPressed: _isLoading
                            ? null
                            : () {
                                // Handle Terms of Use
                              },
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
                        onPressed: _isLoading
                            ? null
                            : () {
                                // Handle Privacy Policy
                              },
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
            if (_isLoading)
              Container(
                color: Colors.black.withOpacity(0.3),
                child: const Center(
                  child: CircularProgressIndicator(),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
