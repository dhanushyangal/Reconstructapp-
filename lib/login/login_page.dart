import 'package:flutter/material.dart';

import 'register_page.dart';
import '../services/auth_service.dart';
import 'google_confirmation_page.dart';
import '../utils/network_utils.dart';
import '../utils/platform_features.dart';
import '../services/supabase_database_service.dart';

class LoginPage extends StatefulWidget {
  final bool showGoogleSignIn;

  const LoginPage({
    super.key,
    this.showGoogleSignIn = true,
  });

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  final AuthService _authService = AuthService.instance;

  Future<void> _handleLogin() async {
    if (_emailController.text.isEmpty || _passwordController.text.isEmpty) {
      debugPrint('Login attempt with empty fields');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter email and password')),
      );
      return;
    }

    setState(() => _isLoading = true);
    debugPrint('Attempting login for email: ${_emailController.text}');

    try {
      // First check if server is reachable
      final serverStatus = await NetworkUtils.getServerStatus();
      if (!serverStatus['serverReachable']) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(serverStatus['message'] ??
                'Cannot reach server. Please try again later.'),
            backgroundColor: Colors.red,
          ),
        );
        setState(() => _isLoading = false);
        return;
      }

      // Add a timeout to prevent hanging indefinitely
      final result = await _authService
          .loginWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      )
          .timeout(
        const Duration(seconds: 15),
        onTimeout: () {
          debugPrint('Login request timed out after 15 seconds');
          return {
            'success': false,
            'message':
                'Login request timed out. Please check your connection and try again.',
          };
        },
      );

      if (!mounted) return;

      if (result['success']) {
        debugPrint('Login successful: ${result['user']['email']}');
        debugPrint('Auth token received: ${result.containsKey('token')}');
        debugPrint(
            'User data stored in AuthService: ${_authService.userData != null}');

        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Login successful'),
            backgroundColor: Colors.green,
          ),
        );

        // Wait a moment for the user to see the success message
        await Future.delayed(const Duration(milliseconds: 800));

        // Check if the widget is still mounted before navigating
        if (!mounted) return;

        debugPrint('Navigating to /home route after successful login');
        // Navigate to the home page directly to avoid potential issues with the AuthWrapper
        Navigator.of(context)
            .pushNamedAndRemoveUntil('/home', (route) => false);
      } else {
        debugPrint('Login failed: ${result['message']}');
        // Show error message with more specific information
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['message'] ??
                'Login failed. Please check your email and password.'),
            backgroundColor: Colors.red,
            action: SnackBarAction(
              label: 'Try Again',
              textColor: Colors.white,
              onPressed: () {
                // Clear password field for security
                _passwordController.clear();
              },
            ),
          ),
        );
      }
    } catch (e) {
      debugPrint('Login error: $e');
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content:
              Text('An error occurred during login. Please try again later.'),
          backgroundColor: Colors.red,
          action: SnackBarAction(
            label: 'OK',
            textColor: Colors.white,
            onPressed: () {},
          ),
        ),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _handleGoogleSignIn() async {
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
      
      // Show confirmation page
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
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Logo and Title
                Image.asset(
                  'assets/reconstruct_transparent.png',
                  height: 48, // Adjust this value to match your desired size
                  fit: BoxFit.contain,
                ),
                const SizedBox(height: 16),
                const SizedBox(height: 8),
                const Text(
                  'Continue to sign in',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey,
                  ),
                ),
                const SizedBox(height: 32),

                // Conditionally show Google Sign In
                if (widget.showGoogleSignIn &&
                    PlatformFeatures.isFeatureAvailable('google_sign_in')) ...[
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: Colors.black87,
                      minimumSize: const Size(double.infinity, 50),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                        side: const BorderSide(color: Colors.grey, width: 1),
                      ),
                      elevation: 0,
                    ),
                    onPressed: _isLoading ? null : _handleGoogleSignIn,
                    icon: Image.asset('assets/google_logo.png', height: 24),
                    label: const Text(
                      'Continue with Google',
                      style: TextStyle(fontSize: 16),
                    ),
                  ),
                  const SizedBox(height: 24),
                  const Row(
                    children: [
                      Expanded(child: Divider()),
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 16),
                        child: Text('OR'),
                      ),
                      Expanded(child: Divider()),
                    ],
                  ),
                  const SizedBox(height: 24),
                ],

                // Email Field
                TextField(
                  controller: _emailController,
                  decoration: InputDecoration(
                    labelText: 'Email',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    prefixIcon: const Icon(Icons.email_outlined),
                  ),
                ),

                const SizedBox(height: 16),

                // Password Field
                TextField(
                  controller: _passwordController,
                  obscureText: true,
                  decoration: InputDecoration(
                    labelText: 'Password',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    prefixIcon: const Icon(Icons.lock_outline),
                  ),
                ),

                const SizedBox(height: 24),

                // Login Button
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).primaryColor,
                    foregroundColor: Colors.white,
                    minimumSize: const Size(double.infinity, 50),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  onPressed: _isLoading ? null : _handleLogin,
                  child: _isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : const Text(
                          'Sign in',
                          style: TextStyle(fontSize: 16),
                        ),
                ),

                const SizedBox(height: 24),

                // Register Link
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text('Don\'t have an account?'),
                    TextButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const RegisterPage(),
                          ),
                        );
                      },
                      child: const Text('Sign up'),
                    ),
                  ],
                ),
                PlatformFeatureWidget(
                    featureName: 'guest_sign_in',
                    child: 
                  TextButton(
                    onPressed: _isLoading
                        ? null
                        : () async {
                            await AuthService.signInAsGuest();
                            Navigator.of(context).pushNamedAndRemoveUntil('/home', (route) => false);
                          },
                    child: const Text('Continue as Guest'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
