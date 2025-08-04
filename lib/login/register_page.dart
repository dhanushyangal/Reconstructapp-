import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/auth_service.dart';
import '../services/supabase_database_service.dart';
import '../services/subscription_manager.dart';
import '../utils/platform_features.dart';
import 'google_confirmation_page.dart';
import 'login_page.dart';

class RegisterPage extends StatefulWidget {
  final bool showGoogleSignIn;

  const RegisterPage({
    super.key,
    this.showGoogleSignIn = true,
  });

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _usernameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _isLoading = false;
  bool _isValidatingUsername = false;
  bool _isValidatingEmail = false;
  String? _usernameError;
  String? _emailError;
  String? _passwordError;
  final AuthService _authService = AuthService();

  @override
  void initState() {
    super.initState();
    // Add listeners for real-time validation
    _usernameController.addListener(_validateUsername);
    _emailController.addListener(_validateEmail);
    _passwordController.addListener(_validatePassword);
    _confirmPasswordController.addListener(_validatePassword);
  }

  // Real-time username validation
  Future<void> _validateUsername() async {
    final username = _usernameController.text.trim();

    if (username.isEmpty) {
      setState(() {
        _usernameError = null;
        _isValidatingUsername = false;
      });
      return;
    }

    if (username.length < 3) {
      setState(() {
        _usernameError = 'Username must be at least 3 characters long';
        _isValidatingUsername = false;
      });
      return;
    }

    setState(() {
      _isValidatingUsername = true;
      _usernameError = null;
    });

    try {
      // Add a small delay to avoid too many requests
      await Future.delayed(const Duration(milliseconds: 500));

      if (_usernameController.text.trim() != username) {
        // User has typed more, skip this validation
        return;
      }

      final result = await _authService.checkUsernameAvailability(username);

      if (mounted) {
        setState(() {
          _isValidatingUsername = false;
          if (!result['success']) {
            _usernameError = result['message'];
          } else {
            _usernameError = null;
          }
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isValidatingUsername = false;
          _usernameError = 'Error checking username availability';
        });
      }
    }
  }

  // Real-time email validation
  Future<void> _validateEmail() async {
    final email = _emailController.text.trim();

    if (email.isEmpty) {
      setState(() {
        _emailError = null;
        _isValidatingEmail = false;
      });
      return;
    }

    // Basic email format validation
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!emailRegex.hasMatch(email)) {
      setState(() {
        _emailError = 'Please enter a valid email address';
        _isValidatingEmail = false;
      });
      return;
    }

    setState(() {
      _isValidatingEmail = true;
      _emailError = null;
    });

    try {
      // Add a small delay to avoid too many requests
      await Future.delayed(const Duration(milliseconds: 500));

      if (_emailController.text.trim() != email) {
        // User has typed more, skip this validation
        return;
      }

      final result = await _authService.checkEmailAvailability(email);

      if (mounted) {
        setState(() {
          _isValidatingEmail = false;
          if (!result['success']) {
            _emailError = result['message'];
          } else {
            _emailError = null;
          }
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isValidatingEmail = false;
          _emailError = 'Error checking email availability';
        });
      }
    }
  }

  // Real-time password validation
  void _validatePassword() {
    final password = _passwordController.text;
    final confirmPassword = _confirmPasswordController.text;

    if (password.isEmpty && confirmPassword.isEmpty) {
      setState(() {
        _passwordError = null;
      });
      return;
    }

    if (password.length < 6) {
      setState(() {
        _passwordError = 'Password must be at least 6 characters long';
      });
      return;
    }

    if (confirmPassword.isNotEmpty && password != confirmPassword) {
      setState(() {
        _passwordError = 'Passwords do not match';
      });
      return;
    }

    setState(() {
      _passwordError = null;
    });
  }

  // Check if the form is valid for submission
  bool _isFormValid() {
    return !_isLoading &&
        !_isValidatingUsername &&
        !_isValidatingEmail &&
        _usernameError == null &&
        _emailError == null &&
        _passwordError == null &&
        _usernameController.text.trim().isNotEmpty &&
        _emailController.text.trim().isNotEmpty &&
        _passwordController.text.isNotEmpty &&
        _confirmPasswordController.text.isNotEmpty;
  }

  // Remove any usage of _authService.signInWithGoogle
  // If Google sign-in is needed, use signInWithGoogleFirebase instead

  Future<void> _handleRegistration() async {
    // Password validation is now handled in real-time
    // The form validation ensures passwords match and meet requirements

    setState(() => _isLoading = true);
    debugPrint('Attempting registration for email: ${_emailController.text}');

    // Show initial loading message
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Creating your account...'),
        backgroundColor: Colors.blue,
        duration: Duration(seconds: 2),
      ),
    );

    try {
      // Add a timeout to prevent hanging indefinitely (increased to 45 seconds)
      final result = await _authService
          .registerUser(
        username: _usernameController.text.trim(),
        email: _emailController.text.trim(),
        password: _passwordController.text,
      )
          .timeout(
        const Duration(seconds: 45),
        onTimeout: () {
          debugPrint('Registration request timed out after 45 seconds');
          return {
            'success': false,
            'message':
                'Registration request timed out. Please check your connection and try again.',
          };
        },
      );

      if (!mounted) return;

      if (result['success']) {
        debugPrint('Registration successful: ${result['user']['email']}');

        // Enable free trial for new user
        try {
          final subscriptionManager = SubscriptionManager();
          await subscriptionManager.startFreeTrial();
          debugPrint('Free trial enabled for new user');
        } catch (e) {
          debugPrint('Error enabling free trial: $e');
          // Don't fail registration if free trial setup fails
        }

        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Account created successfully! Your 7-day free trial has started. Please check your email for verification.'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 4),
          ),
        );

        // Wait a moment for the user to see the success message
        await Future.delayed(const Duration(milliseconds: 800));

        // Check if the widget is still mounted before navigating
        if (!mounted) return;

        // Force AuthService to refresh user data
        await _authService.initialize();

        debugPrint('Navigating to home page after successful registration');
        // Navigate directly to the home page
        Navigator.of(context)
            .pushNamedAndRemoveUntil('/home', (route) => false);
      } else {
        debugPrint('Registration failed: ${result['message']}');

        // Show error message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['message'] ?? 'Registration failed'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      debugPrint('Registration error: $e');
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('An error occurred during registration: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _usernameController.removeListener(_validateUsername);
    _emailController.removeListener(_validateEmail);
    _passwordController.removeListener(_validatePassword);
    _confirmPasswordController.removeListener(_validatePassword);
    _usernameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
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
                  'Continue to sign up for free',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey,
                  ),
                ),
                const Text(
                  'If you already have an account, we\'ll log you in.',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey,
                  ),
                ),
                const SizedBox(height: 32),

                // Google Sign Up Button - Only show on Android
                PlatformFeatureWidget(
                  featureName: 'google_sign_in',
                  child: ElevatedButton.icon(
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
                                    photoUrl: userData['photoUrl'],
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
                      style: TextStyle(fontSize: 16),
                    ),
                  ),
                ),

                // Apple Sign Up Button - Only show on iOS
                PlatformFeatureWidget(
                  featureName: 'apple_sign_in',
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.black,
                      foregroundColor: Colors.white,
                      minimumSize: const Size(double.infinity, 50),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      elevation: 0,
                    ),
                    onPressed: _isLoading
                        ? null
                        : () async {
                            setState(() => _isLoading = true);
                            try {
                              debugPrint('Starting Apple sign-in process...');
                              
                              final result = await _authService.signInWithAppleFirebase();
                              
                              if (!result['success']) {
                                if (mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(result['message'] ?? 'Apple sign in failed'),
                                      backgroundColor: Colors.red,
                                    ),
                                  );
                                }
                                return;
                              }
                              
                              final userData = result['user'];
                              
                              debugPrint('Apple sign-in successful, checking Supabase authentication...');
                              
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
                                    photoUrl: userData['photoUrl'],
                                  ),
                                ),
                              );
                              
                            } catch (e) {
                              debugPrint('Apple sign-in error: $e');
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
                    icon: const Icon(Icons.apple, size: 24, color: Colors.white),
                    label: const Text(
                      'Continue with Apple',
                      style: TextStyle(fontSize: 16, color: Colors.white),
                    ),
                  ),
                ),

                // Show divider only if any social sign-in is available
                if (PlatformFeatures.isFeatureAvailable('google_sign_in') ||
                    PlatformFeatures.isFeatureAvailable('apple_sign_in'))
                  const SizedBox(height: 24),

                // Divider - Only show if any social sign-in is available
                if (PlatformFeatures.isFeatureAvailable('google_sign_in') ||
                    PlatformFeatures.isFeatureAvailable('apple_sign_in'))
                  const Row(
                    children: [
                      Expanded(child: Divider()),
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 16),
                        child: Text(
                          'OR',
                          style: TextStyle(color: Colors.grey),
                        ),
                      ),
                      Expanded(child: Divider()),
                    ],
                  ),

                // Show spacing only if any social sign-in is available
                if (PlatformFeatures.isFeatureAvailable('google_sign_in') ||
                    PlatformFeatures.isFeatureAvailable('apple_sign_in'))
                  const SizedBox(height: 24),

                // Registration Fields
                TextField(
                  controller: _usernameController,
                  decoration: InputDecoration(
                    labelText: 'Username',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    prefixIcon: const Icon(Icons.person_outline),
                    suffixIcon: _isValidatingUsername
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: Padding(
                              padding: EdgeInsets.all(8.0),
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                          )
                        : _usernameError == null &&
                                _usernameController.text.isNotEmpty
                            ? const Icon(Icons.check_circle,
                                color: Colors.green)
                            : null,
                    errorText: _usernameError,
                  ),
                ),

                const SizedBox(height: 16),

                TextField(
                  controller: _emailController,
                  decoration: InputDecoration(
                    labelText: 'Email',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    prefixIcon: const Icon(Icons.email_outlined),
                    suffixIcon: _isValidatingEmail
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: Padding(
                              padding: EdgeInsets.all(8.0),
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                          )
                        : _emailError == null &&
                                _emailController.text.isNotEmpty
                            ? const Icon(Icons.check_circle,
                                color: Colors.green)
                            : null,
                    errorText: _emailError,
                  ),
                ),

                const SizedBox(height: 16),

                TextField(
                  controller: _passwordController,
                  obscureText: true,
                  decoration: InputDecoration(
                    labelText: 'Password',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    prefixIcon: const Icon(Icons.lock_outline),
                    errorText: _passwordError,
                  ),
                ),

                const SizedBox(height: 16),

                TextField(
                  controller: _confirmPasswordController,
                  obscureText: true,
                  decoration: InputDecoration(
                    labelText: 'Confirm Password',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    prefixIcon: const Icon(Icons.lock_outline),
                    errorText: _passwordError,
                  ),
                ),

                const SizedBox(height: 24),

                // Register Button
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).primaryColor,
                    foregroundColor: Colors.white,
                    minimumSize: const Size(double.infinity, 50),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  onPressed: _isFormValid() ? _handleRegistration : null,
                  child: _isLoading
                      ? Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            ),
                            const SizedBox(width: 12),
                            const Text(
                              'Creating account...',
                              style: TextStyle(fontSize: 16),
                            ),
                          ],
                        )
                      : const Text(
                          'Sign up',
                          style: TextStyle(fontSize: 16),
                        ),
                ),

                const SizedBox(height: 24),

                // Login Link
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text('Already have an account?'),
                    TextButton(
                      onPressed: () {
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const LoginPage(),
                          ),
                        );
                      },
                      child: const Text('Sign in'),
                    ),
                  ],
                ),
                // Guest access
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
                // Terms and Privacy
                const SizedBox(height: 16),
                const Text(
                  'By continuing, you agree to our',
                  style: TextStyle(color: Colors.grey, fontSize: 12),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    TextButton(
                      onPressed: () {
                        // Handle Terms of Use
                      },
                      child: const Text(
                        'Terms of Use',
                        style: TextStyle(fontSize: 12),
                      ),
                    ),
                    const Text('and',
                        style: TextStyle(color: Colors.grey, fontSize: 12)),
                    TextButton(
                      onPressed: () {
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
        ),
      ),
    );
  }
}
