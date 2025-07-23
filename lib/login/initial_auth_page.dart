import 'package:flutter/material.dart';
import 'login_page.dart';
import 'register_page.dart';
import '../services/auth_service.dart';
import 'google_confirmation_page.dart';
import '../utils/platform_features.dart';
import '../services/supabase_database_service.dart';

class InitialAuthPage extends StatefulWidget {
  const InitialAuthPage({super.key});

  @override
  State<InitialAuthPage> createState() => _InitialAuthPageState();
}

class _InitialAuthPageState extends State<InitialAuthPage> {
  final AuthService _authService = AuthService();
  bool _isLoading = false;

  // Remove any usage of _authService.signInWithGoogle
  // If Google sign-in is needed, use signInWithGoogleFirebase instead

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
                          : () async {
                              setState(() => _isLoading = true);
                              try {
                                debugPrint('Starting Google sign-in process...');
                                
                                final result = await _authService.signInWithGoogleFirebase();
                                
                                if (!result['success']) {
                                  if (mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(result['message'] ?? 'Google sign in failed'),
                                        backgroundColor: Colors.red,
                                      ),
                                    );
                                  }
                                  return;
                                }
                                
                                final userData = result['user'];
                                final firebaseUser = result['firebaseUser'];
                                
                                debugPrint('Google sign-in successful, checking Supabase authentication...');
                                
                                // When using accessToken function, Supabase automatically handles authentication
                                // No need to check currentUser or currentSession - they're not accessible
                                debugPrint('Supabase authentication handled automatically via Firebase JWT');
                                
                                // Now safely upsert user data into the database
                                try {
                                  await SupabaseDatabaseService().upsertUserToUserAndUsersTables(
                                    id: userData['id'],
                                    email: userData['email'],
                                    name: userData['name'],
                                    photoUrl: userData['photoUrl'],
                                  );
                                  debugPrint('User data upserted successfully');
                                } catch (e) {
                                  debugPrint('Error upserting user data: $e');
                                  // Don't fail the sign-in if upsert fails, just log it
                                }
                                
                                final displayName = userData['name'] ?? 'User';
                                final initial = displayName[0].toUpperCase();
                                
                                if (!context.mounted) return;
                                
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => GoogleConfirmationPage(
                                      email: userData['email'],
                                      displayName: displayName,
                                      initial: initial,
                                    ),
                                  ),
                                );
                                
                              } catch (e) {
                                debugPrint('Google sign-in error: $e');
                                if (!mounted) return;
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('Error: ${e.toString()}'),
                                    backgroundColor: Colors.red,
                                  ),
                                );
                              } finally {
                                if (mounted) setState(() => _isLoading = false);
                              }
                            },
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
                  // Guest access
                  TextButton(
                    onPressed: _isLoading
                        ? null
                        : () async {
                            await AuthService.signInAsGuest();
                            Navigator.of(context).pushNamedAndRemoveUntil('/home', (route) => false);
                        },
                    child: const Text('Continue as Guest'),
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
