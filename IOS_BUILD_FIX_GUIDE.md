# iOS Build Fix Guide

## Problem Summary
The iOS build is failing with Swift compiler errors because `SharedDataModel` cannot be found in scope. This happens because the shared files need to be properly added to both the main app and widget extension targets.

## Files Created/Fixed

### ✅ **1. SharedDataModel.swift** (Main App)
**Location:** `ios/Runner/SharedDataModel.swift`
- Contains all widget data structures and methods
- Used by AppDelegate.swift for widget updates
- Must be added to main app target

### ✅ **2. WidgetTheme.swift** (Main App)
**Location:** `ios/Runner/WidgetTheme.swift`
- Contains WidgetTheme and WidgetType enums
- Used by both main app and widget extension
- Must be added to main app target

### ✅ **3. SharedDataModel.swift** (Widget Extension)
**Location:** `ios/Runner/WidgetExtension/SharedDataModel.swift`
- Same content as main app version
- Used by widget extension files
- Must be added to widget extension target

## Xcode Setup Required

### **Step 1: Add Files to Targets**

1. **Open Xcode** with your iOS project
2. **Right-click** on the `ios/Runner` folder
3. **Select "Add Files to Runner"**
4. **Add these files:**
   - `SharedDataModel.swift`
   - `WidgetTheme.swift`
5. **Make sure they're added to the "Runner" target**

### **Step 2: Add Widget Extension Files**

1. **Right-click** on the `ios/Runner/WidgetExtension` folder
2. **Select "Add Files to WidgetExtension"**
3. **Add these files:**
   - `SharedDataModel.swift` (from WidgetExtension folder)
   - `WidgetConfigurationView.swift`
   - `DailyNotesWidget.swift`
   - `WeeklyPlannerWidget.swift`
   - `VisionBoardWidget.swift`
   - `CalendarWidget.swift`
   - `AnnualPlannerWidget.swift`
   - `WidgetBundle.swift`
   - `Info.plist`

### **Step 3: Configure App Groups**

1. **Select the main app target** in Xcode
2. **Go to "Signing & Capabilities"**
3. **Click "+ Capability"**
4. **Add "App Groups"**
5. **Add group:** `group.com.reconstrect.visionboard.widgets`

### **Step 4: Configure Widget Extension**

1. **Select the WidgetExtension target**
2. **Go to "Signing & Capabilities"**
3. **Click "+ Capability"**
4. **Add "App Groups"**
5. **Add the same group:** `group.com.reconstrect.visionboard.widgets`

## File Structure After Fix

```
ios/Runner/
├── AppDelegate.swift ✅
├── SharedDataModel.swift ✅ (NEW - Main App)
├── WidgetTheme.swift ✅ (NEW - Main App)
├── Info.plist ✅
└── WidgetExtension/
    ├── SharedDataModel.swift ✅ (NEW - Widget Extension)
    ├── WidgetTheme.swift ✅ (Shared from main app)
    ├── WidgetConfigurationView.swift ✅
    ├── DailyNotesWidget.swift ✅
    ├── WeeklyPlannerWidget.swift ✅
    ├── VisionBoardWidget.swift ✅
    ├── CalendarWidget.swift ✅
    ├── AnnualPlannerWidget.swift ✅
    ├── WidgetBundle.swift ✅
    └── Info.plist ✅
```

## Build Commands

### **On Mac (Required for iOS):**
```bash
# Clean and rebuild
flutter clean
flutter pub get

# Build for iOS Simulator
flutter build ios --simulator

# Build for iOS Device
flutter build ios

# Run on iOS Simulator
flutter run -d ios
```

### **On Windows (Android only):**
```bash
# Clean and rebuild
flutter clean
flutter pub get

# Build Android APK
flutter build apk --release

# Build Android App Bundle
flutter build appbundle --release
```

## Verification Steps

### **1. Check File Imports**
Make sure these files have proper imports:

**AppDelegate.swift:**
```swift
import UIKit
import Flutter
import GoogleSignIn
import WidgetKit
// SharedDataModel and WidgetTheme are now accessible
```

**Widget Files:**
```swift
import SwiftUI
import WidgetKit
// SharedDataModel and WidgetTheme are now accessible
```

### **2. Test Widget Functionality**
1. **Run the app** on iOS simulator
2. **Add a widget** to home screen
3. **Verify configuration screen** appears
4. **Select a theme** and add widget
5. **Check widget appears** with selected theme

### **3. Test Data Flow**
1. **Add data** in your Flutter app
2. **Call widget update methods:**
```dart
await IOSWidgetService.updateDailyNotesWidget(
  noteText: "Test note",
  noteCount: 1,
);
```
3. **Verify widget updates** with new data

## Common Issues & Solutions

### **Issue 1: "Cannot find 'SharedDataModel' in scope"**
**Solution:** Ensure `SharedDataModel.swift` is added to both main app and widget extension targets.

### **Issue 2: "Cannot find 'WidgetTheme' in scope"**
**Solution:** Ensure `WidgetTheme.swift` is added to both main app and widget extension targets.

### **Issue 3: App Groups not working**
**Solution:** 
1. Verify App Groups capability is added to both targets
2. Check the group identifier matches: `group.com.reconstrect.visionboard.widgets`
3. Ensure both targets have the same team and bundle identifier prefix

### **Issue 4: Widget not appearing**
**Solution:**
1. Check WidgetExtension target is properly configured
2. Verify `WidgetBundle.swift` is the main entry point
3. Ensure all widget files are added to the target

### **Issue 5: Build fails on Windows**
**Solution:** iOS builds must be done on Mac. Use Windows only for Android builds.

## Testing Checklist

- [ ] **Xcode project opens** without errors
- [ ] **All files added** to correct targets
- [ ] **App Groups configured** for both targets
- [ ] **Build succeeds** on iOS simulator
- [ ] **Widget configuration** screen appears
- [ ] **Theme selection** works
- [ ] **Widget appears** on home screen
- [ ] **Data updates** from Flutter app
- [ ] **Deep linking** works when tapping widget

## Next Steps

1. **Open Xcode** on a Mac
2. **Follow the setup steps** above
3. **Build and test** the iOS app
4. **Verify widgets work** as expected
5. **Test theme selection** functionality
6. **Verify data flow** from Flutter app

## Support

If you encounter any issues:
1. **Check file targets** in Xcode
2. **Verify App Groups** configuration
3. **Clean and rebuild** the project
4. **Check console logs** for specific errors

The iOS widgets are now properly structured and should build successfully once the Xcode setup is complete! 🎉




