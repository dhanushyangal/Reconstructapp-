# Platform-Specific Features Guide

## Overview
This guide shows how to implement platform-specific features in Flutter, allowing you to show/hide features based on iOS vs Android platform.

## Features Implemented

### 1. Platform Features Utility (`lib/utils/platform_features.dart`)

#### Core Components:
- **Platform Detection**: Easy platform checking (iOS, Android, Web)
- **Feature Flags**: Centralized feature configuration
- **Widget Wrappers**: Easy-to-use widgets for conditional rendering
- **Debug Tools**: Built-in debugging and logging

#### Key Features:
```dart
// Platform detection
PlatformFeatures.isIOS
PlatformFeatures.isAndroid
PlatformFeatures.isWeb
PlatformFeatures.isMobile

// Feature checking
PlatformFeatures.isFeatureAvailable('break_things_tool')
```

### 2. Widget Wrappers

#### PlatformFeatureWidget
```dart
PlatformFeatureWidget(
  featureName: 'break_things_tool',
  child: YourWidget(),
  fallback: AlternativeWidget(), // Optional
)
```

#### PlatformFeatureBuilder
```dart
PlatformFeatureBuilder(
  featureName: 'mind_tools_section',
  builder: (context) => YourWidget(),
  fallback: AlternativeWidget(), // Optional
)
```

### 3. Extension for Easy Checking
```dart
// Using extension
if ('break_things_tool'.isAvailable) {
  // Show feature
}
```

## Current Platform-Specific Configuration

### Features Hidden on iOS (Android Only)
- **Break Things Tool**: Stress relief tool
- **Bubble Wrap Popper**: Interactive bubble popping
- **Thought Shredder**: Thought processing tool
- **Make Me Smile**: Mood improvement tool

### Features Available on Both Platforms
- **Authentication**: Login/registration
- **Premium Subscription**: Payment features
- **Daily Notes**: Note-taking functionality
- **Vision Board**: Goal visualization
- **Annual Planner**: Yearly planning
- **Weekly Planner**: Weekly planning
- **Mind Tools Section**: Overall section (with platform-specific tools)

### Platform-Specific Features
- **Android Widgets**: Home screen widgets
- **Android Notifications**: Push notifications
- **Android Background Sync**: Background data sync
- **Android Deep Links**: App-to-app linking
- **iOS Widgets**: iOS home screen widgets
- **iOS Notifications**: iOS push notifications
- **iOS Background Fetch**: Background data fetching

## How to Use

### 1. Basic Feature Checking
```dart
// Check if a feature is available
if (PlatformFeatures.isFeatureAvailable('break_things_tool')) {
  // Show the feature
} else {
  // Hide or show alternative
}
```

### 2. Widget Wrapping
```dart
// Wrap individual widgets
PlatformFeatureWidget(
  featureName: 'break_things_tool',
  child: BreakThingsCard(),
)

// Wrap entire sections
PlatformFeatureBuilder(
  featureName: 'mind_tools_section',
  builder: (context) => MindToolsSection(),
)
```

### 3. Navigation Control
```dart
// In navigation logic
if (title == 'Break Things' && 'break_things_tool'.isAvailable) {
  Navigator.push(context, MaterialPageRoute(
    builder: (context) => const BreakThingsPage(),
  ));
}
```

### 4. Menu Building
```dart
// Build dynamic menus
List<Widget> buildMenuItems() {
  final items = <Widget>[];
  
  if ('break_things_tool'.isAvailable) {
    items.add(BreakThingsMenuItem());
  }
  
  if ('bubble_wrap_popper'.isAvailable) {
    items.add(BubbleWrapMenuItem());
  }
  
  return items;
}
```

## Adding New Platform-Specific Features

### 1. Define the Feature
```dart
// In platform_features.dart
static const Map<String, bool> _featureFlags = {
  'your_new_feature': true, // or false
  // ... other features
};
```

### 2. Add Platform Logic
```dart
// In the isFeatureAvailable method
switch (featureName) {
  case 'your_new_feature':
    return isAndroid; // or isIOS, or true for both
  // ... other cases
}
```

### 3. Use in Your Code
```dart
PlatformFeatureWidget(
  featureName: 'your_new_feature',
  child: YourNewFeatureWidget(),
)
```

## Debugging and Testing

### 1. Debug Print Features
```dart
// Print all feature availability
PlatformFeatures.debugPrintFeatures();
```

### 2. Get Platform Config
```dart
// Get detailed platform information
final config = PlatformFeatures.getPlatformConfig();
print('Platform: ${config['platform']}');
print('Available: ${config['availableFeatures']}');
print('Hidden: ${config['hiddenFeatures']}');
```

### 3. Test on Different Platforms
```dart
// Simulate different platforms for testing
// (You can modify the platform detection logic for testing)
```

## Best Practices

### 1. Feature Organization
- Group related features together
- Use descriptive feature names
- Document feature purposes

### 2. Fallback Handling
```dart
PlatformFeatureWidget(
  featureName: 'break_things_tool',
  child: BreakThingsWidget(),
  fallback: AlternativeStressReliefWidget(), // Provide alternatives
)
```

### 3. User Experience
- Don't leave empty spaces when features are hidden
- Provide alternative features when possible
- Inform users about platform limitations

### 4. Performance
- Feature checks are fast (no database calls)
- Cache platform detection results
- Use const constructors where possible

## Example Implementations

### 1. Dashboard Cards
```dart
// In your dashboard
Row(
  children: [
    // Always available
    VisionBoardCard(),
    
    // Platform-specific
    PlatformFeatureWidget(
      featureName: 'break_things_tool',
      child: BreakThingsCard(),
    ),
    
    // Alternative for iOS
    PlatformFeatureWidget(
      featureName: 'break_things_tool',
      child: BreakThingsCard(),
      fallback: MeditationCard(), // iOS alternative
    ),
  ],
)
```

### 2. Navigation Menu
```dart
// Build dynamic navigation
List<NavigationItem> buildNavigationItems() {
  final items = <NavigationItem>[];
  
  // Core features (both platforms)
  items.addAll([
    NavigationItem('Vision Board', '/vision-board'),
    NavigationItem('Daily Notes', '/daily-notes'),
  ]);
  
  // Platform-specific features
  if ('break_things_tool'.isAvailable) {
    items.add(NavigationItem('Break Things', '/break-things'));
  }
  
  return items;
}
```

### 3. Settings Screen
```dart
// Platform-specific settings
List<SettingItem> buildSettings() {
  final settings = <SettingItem>[];
  
  // Common settings
  settings.addAll([
    SettingItem('Account', Icons.person),
    SettingItem('Premium', Icons.star),
  ]);
  
  // Platform-specific settings
  if (PlatformFeatures.isAndroid) {
    settings.add(SettingItem('Widgets', Icons.widgets));
  }
  
  if (PlatformFeatures.isIOS) {
    settings.add(SettingItem('iOS Widgets', Icons.phone_iphone));
  }
  
  return settings;
}
```

## Configuration Examples

### Hide Multiple Features on iOS
```dart
// In platform_features.dart
case 'break_things_tool':
case 'bubble_wrap_popper':
case 'thought_shredder':
case 'make_me_smile':
  return isAndroid; // Only show on Android
```

### Show Features Only on iOS
```dart
case 'ios_specific_feature':
  return isIOS; // Only show on iOS
```

### Conditional Based on Premium Status
```dart
// Combine with premium status
if (PlatformFeatures.isFeatureAvailable('premium_feature') && isPremium) {
  // Show premium feature
}
```

## Testing Strategy

### 1. Unit Tests
```dart
test('Platform features work correctly', () {
  // Test feature availability
  expect(PlatformFeatures.isFeatureAvailable('break_things_tool'), isTrue);
});
```

### 2. Widget Tests
```dart
testWidgets('Platform-specific widgets render correctly', (tester) async {
  await tester.pumpWidget(PlatformFeatureWidget(
    featureName: 'break_things_tool',
    child: Text('Break Things'),
  ));
  
  // Verify widget renders or doesn't render based on platform
});
```

### 3. Integration Tests
```dart
// Test full app flow with platform-specific features
testWidgets('App works with platform-specific features', (tester) async {
  await tester.pumpWidget(MyApp());
  
  // Navigate and test platform-specific features
});
```

## Future Enhancements

### 1. Remote Configuration
- Load feature flags from server
- A/B testing capabilities
- Dynamic feature rollout

### 2. Analytics Integration
- Track feature usage by platform
- Monitor user engagement
- Performance metrics

### 3. Advanced Platform Detection
- Device capability detection
- OS version checking
- Hardware feature detection

This platform-specific feature system provides a flexible and maintainable way to control feature availability across different platforms while maintaining a clean codebase. 