import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;

class GoogleSignInConfig {
  // Google OAuth configuration
  static const String webClientId =
      '633982729642-l3rnsu8636ib9bf2gvbaqmahraomb9f0.apps.googleusercontent.com';

  // Android client ID (updated from GoogleService-Info.plist)
  static const String androidClientId =
      '633982729642-h1n9cc07ut6515sefpbtr7vbu74gh1vr.apps.googleusercontent.com';

  // iOS client ID (real one from GoogleService-Info.plist)
  static const String iosClientId =
      '633982729642-p8p5svhsbuu6g18kmk8agshb5j92amkf.apps.googleusercontent.com';

  static const String projectId = 'recostrect3';

  // OAuth endpoints
  static const String authUri = 'https://accounts.google.com/o/oauth2/auth';
  static const String tokenUri = 'https://oauth2.googleapis.com/token';
  static const String authProviderX509CertUrl =
      'https://www.googleapis.com/oauth2/v1/certs';

  // Configuration for different platforms
  static String get currentPlatformClientId {
    if (kIsWeb) {
      return webClientId;
    } else if (Platform.isAndroid) {
      return androidClientId;
    } else if (Platform.isIOS) {
      // Use proper iOS client ID instead of web client ID
      return iosClientId;
    } else {
      // For other platforms, use web client ID as fallback
      return webClientId;
    }
  }

  // UPDATED: Use the real iOS client ID for Google Sign-In
  static String? get serverClientIdForGoogleSignIn {
    if (Platform.isIOS) {
      // Use the real iOS client ID for proper OAuth flow
      return iosClientId;
    } else if (Platform.isAndroid) {
      return androidClientId;
    } else if (kIsWeb) {
      return webClientId;
    }
    return null;
  }

  // Get the current platform name for debugging
  static String get currentPlatformName {
    if (kIsWeb) return 'Web';
    if (Platform.isAndroid) return 'Android';
    if (Platform.isIOS) return 'iOS';
    return 'Other';
  }
}
