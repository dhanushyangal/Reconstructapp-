# iOS Widget Setup Guide

This guide explains how to set up iOS widgets for the Reconstruct app that mirror the functionality of the Android widgets.

## Overview

The iOS widgets provide the same functionality as the Android widgets:
- **Daily Notes Widget**: Quick access to daily notes and thoughts
- **Weekly Planner Widget**: Weekly goals and task progress
- **Vision Board Widget**: Goals and motivation display
- **Calendar Widget**: Interactive calendar with events
- **Annual Planner Widget**: Year-long goals and milestones

## File Structure

```
ios/Runner/WidgetExtension/
├── WidgetBundle.swift              # Main widget bundle
├── DailyNotesWidget.swift          # Daily Notes widget
├── WeeklyPlannerWidget.swift       # Weekly Planner widget
├── VisionBoardWidget.swift         # Vision Board widget
├── CalendarWidget.swift            # Calendar widget
├── AnnualPlannerWidget.swift       # Annual Planner widget
├── SharedDataModel.swift           # Shared data model
└── Info.plist                      # Widget extension configuration
```

## Setup Instructions

### 1. Xcode Project Configuration

1. Open your iOS project in Xcode
2. Add a new Widget Extension target:
   - File → New → Target
   - Choose "Widget Extension"
   - Name it "WidgetExtension"
   - Make sure "Include Configuration Intent" is unchecked

### 2. App Groups Configuration

1. In Xcode, select your main app target
2. Go to "Signing & Capabilities"
3. Add "App Groups" capability
4. Create a new app group: `group.com.reconstrect.visionboard.widgets`
5. Repeat for the WidgetExtension target

### 3. Bundle Identifier Setup

Ensure your bundle identifiers are properly configured:
- Main app: `com.reconstrect.visionboard`
- Widget extension: `com.reconstrect.visionboard.WidgetExtension`

### 4. Copy Widget Files

Copy all the Swift files from the `ios/Runner/WidgetExtension/` directory to your Xcode project's WidgetExtension target.

### 5. Update AppDelegate

The AppDelegate.swift file has been updated to include the platform channel for widget data updates. Make sure the widget service channel is properly configured.

## Widget Features

### Daily Notes Widget
- Displays current note text and count
- Updates every 30 minutes
- Deep link to daily notes section
- Small and medium sizes supported

### Weekly Planner Widget
- Shows weekly goals and task progress
- Progress bar for completed vs total tasks
- Updates every hour
- Small, medium, and large sizes supported

### Vision Board Widget
- Displays goals and motivation quotes
- Purple gradient background
- Updates every 2 hours
- Small, medium, and large sizes supported

### Calendar Widget
- Interactive calendar grid (large size)
- Shows current month and events
- Updates daily at midnight
- Small, medium, and large sizes supported

### Annual Planner Widget
- Year goals and milestone progress
- Progress bar for completed milestones
- Updates weekly
- Small, medium, and large sizes supported

## Data Communication

### Shared Data Model
The widgets use a shared data model (`SharedDataModel.swift`) that communicates with the main app through App Groups and UserDefaults.

### Flutter Integration
Use the `IOSWidgetService` class in your Flutter code to update widget data:

```dart
// Update Daily Notes widget
await IOSWidgetService.updateDailyNotesWidget(
  noteText: "Today's thoughts...",
  noteCount: 5,
);

// Update Weekly Planner widget
await IOSWidgetService.updateWeeklyPlannerWidget(
  weekGoals: ["Goal 1", "Goal 2"],
  completedTasks: 3,
  totalTasks: 7,
);

// Refresh all widgets
await IOSWidgetService.refreshAllWidgets();
```

## Deep Linking

The widgets support deep linking to specific sections of the app:
- `reconstrect://dailynotes` - Opens Daily Notes
- `reconstrect://weeklyplanner` - Opens Weekly Planner
- `reconstrect://visionboard` - Opens Vision Board
- `reconstrect://calendar` - Opens Calendar
- `reconstrect://annualplanner` - Opens Annual Planner

## Testing

1. Build and run the app on a physical iOS device (widgets don't work in simulator)
2. Long press on the home screen and tap the "+" button
3. Search for "Reconstruct" to find your widgets
4. Add widgets to your home screen
5. Test deep linking by tapping on widget elements

## Troubleshooting

### Common Issues

1. **Widgets not appearing**: Make sure App Groups are properly configured
2. **Data not updating**: Check that the shared data model is working correctly
3. **Deep links not working**: Verify URL schemes are configured in Info.plist
4. **Build errors**: Ensure all Swift files are added to the correct target

### Debug Tips

1. Use Xcode's console to check for widget-related logs
2. Test shared data access in the main app
3. Verify App Group permissions
4. Check bundle identifiers match

## Performance Considerations

- Widgets have limited memory and processing time
- Keep widget updates lightweight
- Use efficient data structures
- Avoid heavy computations in widget providers

## Security

- App Groups provide secure data sharing between app and widgets
- No sensitive data is stored in widget storage
- All data is encrypted when stored

## Future Enhancements

Potential improvements for the widgets:
- Live Activities support for real-time updates
- Interactive widget elements
- Custom widget themes
- More widget sizes and configurations
- Background refresh capabilities

