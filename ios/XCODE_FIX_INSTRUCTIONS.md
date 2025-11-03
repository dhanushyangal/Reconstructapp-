# Fix for "Cannot find Widget in scope" Error

## Problem
Swift compiler errors:
- Cannot find 'CalendarWidget' in scope
- Cannot find 'WeeklyPlannerWidget' in scope  
- Cannot find 'AnnualPlannerWidget' in scope

## Root Cause
The widget Swift files are not added to the WidgetExtension target in Xcode.

## Solution - Step by Step

### Option 1: Using File Inspector (Recommended)

1. Open your project in Xcode
2. In Project Navigator, select these files one by one:
   - `ios/WidgetExtension/CalendarWidget.swift`
   - `ios/WidgetExtension/WeeklyPlannerWidget.swift`
   - `ios/WidgetExtension/AnnualPlannerWidget.swift`
   - `ios/Shared/SharedDataModel.swift`
3. For each file:
   - Click on the file in Project Navigator
   - Open **File Inspector** (right panel, first icon)
   - Under **Target Membership**, check **WidgetExtension** ✓
   - Uncheck **Runner** if it's checked (widgets should be in WidgetExtension target only)

### Option 2: Using Target Settings

1. Click on your project in Project Navigator (top item)
2. Select **WidgetExtension** target
3. Go to **Build Phases** tab
4. Expand **Compile Sources**
5. Click **+** button
6. Add these files if missing:
   - `CalendarWidget.swift`
   - `WeeklyPlannerWidget.swift`
   - `AnnualPlannerWidget.swift`
   - `SharedDataModel.swift` (from ios/Shared folder)

### Option 3: Verify All Widget Files

Make sure ALL these files have WidgetExtension checked:
- ✅ `WidgetBundle.swift`
- ✅ `NotesWidget.swift`
- ✅ `VisionBoardWidget.swift`
- ✅ `CalendarWidget.swift`
- ✅ `WeeklyPlannerWidget.swift`
- ✅ `AnnualPlannerWidget.swift`
- ✅ `SharedDataModel.swift` (from ios/Shared/)

## After Fixing

1. Clean build folder: **Product → Clean Build Folder** (Shift + Cmd + K)
2. Close and reopen Xcode (sometimes helps)
3. Build again: **Product → Build** (Cmd + B)

## Verification

After fixing, you should be able to build without the "Cannot find in scope" errors.


