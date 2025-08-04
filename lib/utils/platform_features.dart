import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

/// Platform-specific feature control utility
/// Allows you to show/hide features based on iOS vs Android platform
class PlatformFeatures {
  // Platform detection
  static bool get isIOS => !kIsWeb && Platform.isIOS;
  static bool get isAndroid => !kIsWeb && Platform.isAndroid;
  static bool get isWeb => kIsWeb;
  static bool get isMobile => isIOS || isAndroid;

  // Feature flags - customize these based on your needs
  static const Map<String, bool> _featureFlags = {
    // Core features available on both platforms
    'authentication': true,
    'premium_subscription': true,
    'daily_notes': true,
    'vision_board': true,
    'annual_planner': true,
    'weekly_planner': true,
    'mind_tools_section': true,
    'google_sign_in': true, // Available on both platforms by default

    // Features available only on Android
    'android_widgets': true,
    'android_notifications': true,
    'android_background_sync': true,
    'android_deep_links': true,
    'android_home_widget': true,
    'android_activity_tracker': true,

    // Features available only on iOS
    'ios_widgets': true,
    'ios_notifications': true,
    'ios_background_fetch': true,
    'ios_deep_links': true,
    'ios_home_widget': true,
    'ios_activity_tracker': true,

    // Features to hide on iOS (examples)
    'break_things_tool': true, // Set to false to hide on iOS
    'bubble_wrap_popper': true, // Set to false to hide on iOS
    'thought_shredder': true, // Set to false to hide on iOS
    'make_me_smile': true, // Set to false to hide on iOS
    'add_widgets': true, // Set to false to hide on iOS

    // Features to hide on Android (examples)
    'ios_specific_feature': false, // Set to true to show only on iOS

    // Premium features
    'premium_themes': true,
    'advanced_planners': true,
    'export_features': true,
    'cloud_sync': true,

    // iOS free access - all features free for iOS users
    'ios_free_access': true,
  };

  /// Check if a feature is available on the current platform
  static bool isFeatureAvailable(String featureName) {
    // Get the base feature flag
    final baseFlag = _featureFlags[featureName] ?? false;

    if (!baseFlag) return false;

    // Platform-specific overrides
    switch (featureName) {
      // Features hidden on iOS
      case 'break_things_tool':
      case 'bubble_wrap_popper':
      case 'thought_shredder':
      case 'make_me_smile':
      case 'add_widgets': // Hide Add Widgets on iOS
        return isAndroid; // Only show on Android

      // Features hidden on Android
      case 'ios_specific_feature':
      case 'guest_sign_in':
        return isIOS; // Only show on iOS

      // Android-specific features
      case 'android_widgets':
      case 'android_notifications':
      case 'android_background_sync':
      case 'android_deep_links':
      case 'android_home_widget':
      case 'android_activity_tracker':
        return isAndroid;

      // iOS-specific features
      case 'ios_widgets':
      case 'ios_notifications':
      case 'ios_background_fetch':
      case 'ios_deep_links':
      case 'ios_home_widget':
      case 'ios_activity_tracker':
        return isIOS;

      // Features available on both platforms
      default:
        return true;
    }
  }

  /// Check if iOS users get free access to all features
  static bool get isIOSFreeAccess =>
      isIOS && _featureFlags['ios_free_access'] == true;

  /// Get a list of available features for the current platform
  static List<String> getAvailableFeatures() {
    return _featureFlags.keys
        .where((feature) => isFeatureAvailable(feature))
        .toList();
  }

  /// Get a list of hidden features for the current platform
  static List<String> getHiddenFeatures() {
    return _featureFlags.keys
        .where((feature) => !isFeatureAvailable(feature))
        .toList();
  }

  /// Check if multiple features are available
  static bool areFeaturesAvailable(List<String> featureNames) {
    return featureNames.every((feature) => isFeatureAvailable(feature));
  }

  /// Get platform-specific configuration
  static Map<String, dynamic> getPlatformConfig() {
    return {
      'platform': isIOS
          ? 'iOS'
          : isAndroid
              ? 'Android'
              : 'Web',
      'availableFeatures': getAvailableFeatures(),
      'hiddenFeatures': getHiddenFeatures(),
      'isMobile': isMobile,
      'isIOSFreeAccess': isIOSFreeAccess,
    };
  }

  /// Debug method to print all feature availability
  static void debugPrintFeatures() {
    debugPrint('=== Platform Features Debug ===');
    debugPrint('Platform: ${isIOS ? "iOS" : isAndroid ? "Android" : "Web"}');
    debugPrint('iOS Free Access: $isIOSFreeAccess');
    debugPrint('Available Features: ${getAvailableFeatures().join(", ")}');
    debugPrint('Hidden Features: ${getHiddenFeatures().join(", ")}');
    debugPrint('==============================');
  }
}

/// Extension for easy feature checking in widgets
extension PlatformFeatureExtension on String {
  bool get isAvailable => PlatformFeatures.isFeatureAvailable(this);
}

/// Widget wrapper for platform-specific features
class PlatformFeatureWidget extends StatelessWidget {
  final String featureName;
  final Widget child;
  final Widget? fallback;

  const PlatformFeatureWidget({
    super.key,
    required this.featureName,
    required this.child,
    this.fallback,
  });

  @override
  Widget build(BuildContext context) {
    if (PlatformFeatures.isFeatureAvailable(featureName)) {
      return child;
    }

    return fallback ?? const SizedBox.shrink();
  }
}

/// Conditional widget builder for platform-specific features
class PlatformFeatureBuilder extends StatelessWidget {
  final String featureName;
  final Widget Function(BuildContext) builder;
  final Widget? fallback;

  const PlatformFeatureBuilder({
    super.key,
    required this.featureName,
    required this.builder,
    this.fallback,
  });

  @override
  Widget build(BuildContext context) {
    if (PlatformFeatures.isFeatureAvailable(featureName)) {
      return builder(context);
    }

    return fallback ?? const SizedBox.shrink();
  }
}
