import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;

class GoogleSignInConfig {
  // Google OAuth configuration
  static const String webClientId =
      '633982729642-l3rnsu8636ib9bf2gvbaqmahraomb9f0.apps.googleusercontent.com';

  // Android client ID (from strings.xml)
  static const String androidClientId =
      '633982729642-4lotqibb3rnglifn79rt0ibjorg40oib.apps.googleusercontent.com';

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
    } else {
      // For iOS and other platforms, use web client ID
      return webClientId;
    }
  }
}
