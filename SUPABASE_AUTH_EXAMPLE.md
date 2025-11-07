# Supabase Authentication Examples

## ✅ **Yes, You Can Use Supabase for Normal Login and Registration!**

Your app is already set up to use Supabase for email/password authentication. Here's how it works:

## 🔐 **Login with Supabase**

### **Method 1: Using AuthService (Recommended)**
```dart
// In your login page
final result = await _authService.signInWithEmailPassword(
  email: 'user@example.com',
  password: 'password123',
);

if (result['success']) {
  print('Login successful: ${result['user']['email']}');
  // Navigate to home page
} else {
  print('Login failed: ${result['message']}');
}
```

### **Method 2: Direct Supabase Call**
```dart
// Direct Supabase authentication
final supabaseService = SupabaseDatabaseService();
final result = await supabaseService.loginUser(
  email: 'user@example.com',
  password: 'password123',
);

if (result['success']) {
  print('User logged in: ${result['user']['email']}');
  print('Token: ${result['token']}');
} else {
  print('Login error: ${result['message']}');
}
```

## 📝 **Registration with Supabase**

### **Method 1: Using AuthService (Recommended)**
```dart
// In your registration page
final result = await _authService.registerWithEmailPassword(
  username: 'john_doe',
  email: 'john@example.com',
  password: 'securepassword123',
);

if (result['success']) {
  print('Registration successful: ${result['user']['email']}');
  print('Message: ${result['message']}');
  // User will receive email verification
} else {
  print('Registration failed: ${result['message']}');
}
```

### **Method 2: Direct Supabase Call**
```dart
// Direct Supabase registration
final supabaseService = SupabaseDatabaseService();
final result = await supabaseService.registerUser(
  username: 'john_doe',
  email: 'john@example.com',
  password: 'securepassword123',
);

if (result['success']) {
  print('User registered: ${result['user']['email']}');
  print('Email verification required: ${result['user']['email_confirmed']}');
} else {
  print('Registration error: ${result['message']}');
}
```

## 🔄 **Complete Authentication Flow**

### **1. User Registration**
```dart
class RegistrationExample {
  Future<void> registerUser() async {
    final authService = AuthService.instance;
    
    final result = await authService.registerWithEmailPassword(
      username: 'newuser',
      email: 'newuser@example.com',
      password: 'MySecurePassword123!',
    );
    
    if (result['success']) {
      // ✅ Registration successful
      // 📧 Email verification sent
      // 🎉 Free trial started
      
      print('Registration successful!');
      print('User ID: ${result['user']['id']}');
      print('Email: ${result['user']['email']}');
      print('Message: ${result['message']}');
      
      // Navigate to home or show verification message
    } else {
      // ❌ Registration failed
      print('Registration failed: ${result['message']}');
    }
  }
}
```

### **2. User Login**
```dart
class LoginExample {
  Future<void> loginUser() async {
    final authService = AuthService.instance;
    
    final result = await authService.signInWithEmailPassword(
      email: 'newuser@example.com',
      password: 'MySecurePassword123!',
    );
    
    if (result['success']) {
      // ✅ Login successful
      // 🔑 Token received
      // 👤 User data loaded
      
      print('Login successful!');
      print('User: ${result['user']['name']}');
      print('Email: ${result['user']['email']}');
      print('Premium: ${result['user']['is_premium']}');
      
      // Navigate to home page
    } else {
      // ❌ Login failed
      print('Login failed: ${result['message']}');
    }
  }
}
```

### **3. Password Reset**
```dart
class PasswordResetExample {
  Future<void> resetPassword() async {
    final supabaseService = SupabaseDatabaseService();
    
    try {
      await supabaseService._nativeAuthClient.auth.resetPasswordForEmail(
        'user@example.com',
        redirectTo: 'https://reconstructyourmind.com/reset-password',
      );
      
      print('Password reset email sent!');
    } catch (e) {
      print('Password reset error: $e');
    }
  }
}
```

## 🎯 **Your Current Setup Benefits**

### **✅ What Works Now:**

1. **Email/Password Registration** - ✅ Supabase handles this
2. **Email/Password Login** - ✅ Supabase handles this  
3. **Email Verification** - ✅ Supabase sends verification emails
4. **Password Reset** - ✅ Supabase handles password resets
5. **User Data Storage** - ✅ Supabase database stores user data
6. **Session Management** - ✅ Supabase manages sessions
7. **Google/Apple Login** - ✅ Firebase handles social logins
8. **Unified User Management** - ✅ Both sync to same database

### **🔧 Configuration Status:**

| Feature | Status | Provider |
|---------|--------|----------|
| Email Registration | ✅ Active | Supabase |
| Email Login | ✅ Active | Supabase |
| Google Login | ✅ Active | Firebase |
| Apple Login | ✅ Active | Firebase |
| Email Verification | ✅ Active | Supabase |
| Password Reset | ✅ Active | Supabase |
| User Database | ✅ Active | Supabase |

## 📱 **Platform Support**

| Platform | Email/Password | Google Login | Apple Login |
|----------|---------------|--------------|-------------|
| **Web**  | ✅ Supabase   | ✅ Firebase  | ✅ Firebase  |
| **iOS**  | ✅ Supabase   | ✅ Firebase  | ✅ Firebase  |
| **Android**| ✅ Supabase | ✅ Firebase  | ❌ N/A      |

## 🚀 **Usage Examples**

### **Simple Login Form:**
```dart
class SimpleLoginForm extends StatefulWidget {
  @override
  _SimpleLoginFormState createState() => _SimpleLoginFormState();
}

class _SimpleLoginFormState extends State<SimpleLoginForm> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;

  Future<void> _login() async {
    setState(() => _isLoading = true);
    
    try {
      final result = await AuthService.instance.signInWithEmailPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );
      
      if (result['success']) {
        // Navigate to home
        Navigator.pushReplacementNamed(context, '/home');
      } else {
        // Show error
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(result['message'])),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        TextField(
          controller: _emailController,
          decoration: InputDecoration(labelText: 'Email'),
        ),
        TextField(
          controller: _passwordController,
          decoration: InputDecoration(labelText: 'Password'),
          obscureText: true,
        ),
        ElevatedButton(
          onPressed: _isLoading ? null : _login,
          child: _isLoading 
            ? CircularProgressIndicator() 
            : Text('Login'),
        ),
      ],
    );
  }
}
```

## 🎉 **Conclusion**

**Yes, you can absolutely use Supabase for normal login and registration!** 

Your current setup is already configured and working. The hybrid approach gives you:

- ✅ **Supabase** for email/password authentication
- ✅ **Firebase** for social logins (Google, Apple)
- ✅ **Unified** user management in Supabase database
- ✅ **Cross-platform** support (Web, iOS, Android)

This is actually the **best approach** because you get the benefits of both platforms without the drawbacks of either one alone. 