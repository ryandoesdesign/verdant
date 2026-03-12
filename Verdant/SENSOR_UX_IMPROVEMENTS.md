# Sensor UX Improvements - Apple-like Experience

This document summarizes all the improvements made to provide an Apple-like user experience when sensors are not found in HomeKit.

## Overview

The improvements follow Apple's design principles:
- **Silent resilience**: Don't crash or show alerts immediately
- **Visual indicators**: Show status in the UI (similar to AirPods battery/connection status)
- **Contextual help**: Provide actionable guidance when user investigates
- **Deep integration**: Link to Home app where the user can fix the issue
- **User control**: Let them dismiss the pairing if they removed the sensor

## Changes Made

### 1. Plant Model (`Plant.swift`)
**New Features:**
- Added `SensorStatus` enum with cases: `.connected`, `.disconnected`, `.notFound`, `.unknown`
- Added `sensorStatus: SensorStatus` property to track current sensor state
- Added `lastSuccessfulConnection: Date?` to track when sensor was last reachable
- Each status has display properties (name, icon, color) for consistent UI

### 2. Sensor Monitor (`SensorMonitor.swift`)
**Enhanced Monitoring:**
- Tracks when sensors are first reported as missing via `sensorIssueTimestamps`
- Updates plant's `sensorStatus` when accessories are found/not found
- Sends user notifications when issues persist for 24+ hours
- Updates status to connected when data is received
- Handles reachability changes gracefully

**New Methods:**
- `updateSensorStatus(sensorId:status:)` - Updates plant sensor status and saves
- `checkForPersistentIssue(sensorId:)` - Tracks how long issue has existed
- `notifyUserOfPersistentIssue(plantName:sensorId:)` - Sends notification after 24h
- `requestNotificationAuthorization()` - Requests permission on initialization

### 3. Sensor Status View (`SensorStatusView.swift` - NEW FILE)
**Visual Feedback:**
- `SensorStatusView` - Full status display with interactive alerts
  - Shows current status with color-coded background
  - Displays "last seen" timestamp for disconnected sensors
  - Tappable when disconnected to show help dialog
  - Alert offers:
    - "Open Home App" - Deep links to Home app
    - "Remove Sensor" - Unpairs sensor from plant
    - "Cancel" - Dismisses alert

- `SensorStatusBadge` - Compact badge for grid views
  - Small icon overlay on plant images
  - Color-coded status indicator
  - Uses `.regularMaterial` for glassmorphic effect

### 4. Plant Detail View (`PlantDetailView.swift`)
**Updated UI:**
- Replaced simple green "Sensor Connected" banner
- Now uses `SensorStatusView` component
- Dynamically shows status with appropriate styling
- Interactive alerts guide user to fix issues

### 5. Plants Grid View (`PlantsView.swift`)
**Visual Indicators:**
- Added `SensorStatusBadge` overlay on plant images
- Shows status at-a-glance in grid view
- Badge positioned in top-right corner
- Only appears for plants with paired sensors

### 6. App Configuration (`VerdantApp.swift`)
**Notification Setup:**
- Configured notification categories for sensor issues
- Adds "Open Home App" and "Dismiss" actions
- Properly registers categories on app launch

## User Experience Flow

### Scenario 1: Sensor Temporarily Unavailable
1. User opens app
2. SensorMonitor detects sensor not found
3. Plant's status updated to `.notFound` silently
4. Grid view shows orange warning badge
5. Detail view shows "Sensor Not Found" with last seen time
6. No immediate interruption - user can continue using app

### Scenario 2: User Investigates Issue
1. User taps on plant with warning badge
2. Detail view shows "Sensor Not Found" status
3. User taps status banner
4. Alert appears with clear explanation
5. User can:
   - Open Home app to check sensor
   - Remove sensor pairing
   - Cancel and check later

### Scenario 3: Persistent Issue (24+ hours)
1. Sensor remains unavailable for 24 hours
2. System sends notification:
   - Title: "Sensor Disconnected"
   - Body: "[Plant name]'s sensor hasn't been found for 24 hours..."
3. Notification includes actions:
   - "Open Home App" - Direct link to fix issue
   - "Dismiss" - Acknowledge notification
4. User can address issue when convenient

### Scenario 4: Sensor Reconnects
1. Sensor comes back online
2. SensorMonitor receives data update
3. Status immediately updates to `.connected`
4. Green checkmark appears in UI
5. Issue timestamp cleared
6. No notification sent (silent resolution)

## Design Patterns Used

### Apple HIG Compliance
- **Anticipation**: App predicts sensor issues and tracks them
- **Feedback**: Clear visual indicators of sensor status
- **User Control**: Users decide when to act on issues
- **Consistency**: Status colors match system conventions (green=good, orange=warning)

### Similar to Apple Apps
- **Health**: Shows data source connection status similarly
- **Home**: Uses same orange warning colors for unreachable accessories
- **Find My**: Shows "last seen" timestamps like offline devices
- **AirPods**: Status badges on device images in grid views

## Code Quality Improvements
- Separated concerns (status tracking vs UI display)
- Reusable components (`SensorStatusView`, `SensorStatusBadge`)
- Comprehensive error handling
- Clear documentation
- Preview-ready components for testing

## Future Enhancements
Consider adding:
- Settings to customize notification timing
- History of connection issues
- Battery level monitoring (if supported by sensors)
- Multiple sensor support per plant
- Sensor recommendation when adding plants
