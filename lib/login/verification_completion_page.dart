import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
  import '../services/auth_service.dart';

class VerificationCompletionPage extends StatefulWidget {
  final String email;
  final String username;
  final String password; // Add password parameter

  const VerificationCompletionPage({
    super.key,
    required this.email,
    required this.username,
    required this.password, // Add password requirement
  });

  @override
  State<VerificationCompletionPage> createState() =>
      _VerificationCompletionPageState();
}

class _VerificationCompletionPageState
    extends State<VerificationCompletionPage> {
  bool _isLoading = false;
  final AuthService _authService = AuthService.instance;

  Future<void> _checkVerificationAndLogin() async {
    setState(() => _isLoading = true);

    try {
      debugPrint(
          '🔍 Starting verification check and login for: ${widget.email}');

      // First, try to sign in with the provided credentials
      final loginResult = await _authService
          .signInWithEmailPassword(
        email: widget.email,
        password: widget.password,
      )
          .timeout(
        const Duration(seconds: 30),
        onTimeout: () {
          debugPrint('⏰ Login request timed out');
          return {
            'success': false,
            'message': 'Login request timed out. Please try again.',
          };
        },
      );

      if (!mounted) return;

      debugPrint('🔍 Login result: ${loginResult['success']}');
      debugPrint('🔍 Login message: ${loginResult['message']}');

      if (loginResult['success'] == true) {
        // Login successful, check if user is verified
        final currentUser = _authService.currentUser;
        debugPrint('🔍 Current user: $currentUser');

        if (currentUser != null) {
          // Check various possible verification properties
          final isVerified = currentUser.emailConfirmedAt != null;

          debugPrint('🔍 Email confirmed at: ${currentUser.emailConfirmedAt}');
          debugPrint('🔍 Is verified: $isVerified');

          if (isVerified) {
            // User is verified and logged in, proceed to home page
            debugPrint('✅ User verified, navigating to home page');
            
            // Clear the payment prompt flag so payment page shows after registration
            final prefs = await SharedPreferences.getInstance();
            await prefs.setBool('has_shown_payment_prompt_session', false);
            
            Navigator.of(context)
                .pushNamedAndRemoveUntil('/home', (route) => false);
          } else {
            // User logged in but not verified yet
            debugPrint('⚠️ User logged in but not verified');
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text(
                    'Please check your email and click the verification link first.'),
                backgroundColor: Colors.orange,
                duration: Duration(seconds: 4),
              ),
            );
          }
        } else {
          // No current user found
          debugPrint('❌ No current user found after login');
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Login successful but user data not found.'),
              backgroundColor: Colors.orange,
              duration: Duration(seconds: 4),
            ),
          );
        }
      } else {
        // Login failed, show error message
        debugPrint('❌ Login failed: ${loginResult['message']}');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(loginResult['message'] ??
                'Login failed. Please check your credentials.'),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 4),
          ),
        );
      }
    } catch (e) {
      debugPrint('❌ Error during login: $e');
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error during login: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
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
                // Logo
                Image.asset(
                  'assets/reconstruct_transparent.png',
                  height: 80,
                  fit: BoxFit.contain,
                ),

                const SizedBox(height: 40),

                // Success Icon
                Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.check_circle_outline,
                    size: 60,
                    color: Colors.green,
                  ),
                ),

                const SizedBox(height: 32),

                // Title
                const Text(
                  'Account Created Successfully!',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                  textAlign: TextAlign.center,
                ),

                const SizedBox(height: 16),

                // Subtitle
                Text(
                  'Welcome, ${widget.username}!',
                  style: const TextStyle(
                    fontSize: 18,
                    color: Colors.grey,
                  ),
                  textAlign: TextAlign.center,
                ),

                const SizedBox(height: 32),

                // Instructions
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.blue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.blue.withOpacity(0.3)),
                  ),
                  child: Column(
                    children: [
                      const Icon(
                        Icons.email_outlined,
                        size: 40,
                        color: Colors.blue,
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Verify Your Email',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.blue,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'We\'ve sent a verification link to:\n${widget.email}',
                        style: const TextStyle(
                          fontSize: 14,
                          color: Colors.grey,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Please check your email and click the verification link to complete your registration. Then click the button below to log in.',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 32),

                // Verification Complete Button
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                    minimumSize: const Size(double.infinity, 50),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  onPressed: _isLoading ? null : _checkVerificationAndLogin,
                  child: _isLoading
                      ? const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            ),
                            SizedBox(width: 12),
                            Text(
                              'Logging in...',
                              style: TextStyle(fontSize: 16),
                            ),
                          ],
                        )
                      : const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.login, size: 20),
                            SizedBox(width: 8),
                            Text(
                              'I\'ve Verified My Email - Log Me In',
                              style: TextStyle(fontSize: 16),
                            ),
                          ],
                        ),
                ),

                // Resend Email Button
                TextButton(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(
                            'Please check your email for the verification link.'),
                        backgroundColor: Colors.blue,
                      ),
                    );
                  },
                  child: const Text(
                    'Didn\'t receive the email?',
                    style: TextStyle(
                      color: Colors.blue,
                      fontSize: 14,
                    ),
                  ),
                ),

                const SizedBox(height: 24),

                // Additional Info
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.grey.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Column(
                    children: [
                      Icon(
                        Icons.info_outline,
                        color: Colors.grey,
                        size: 24,
                      ),
                      SizedBox(height: 8),
                      Text(
                        'After verifying your email, you\'ll have full access to all features including vision boards, planners, and more!',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
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
