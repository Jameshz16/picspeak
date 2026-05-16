# Camera Capture Specification

## Purpose

Manages the device camera preview, permissions, snapshot capture, and lifecycle for the core scan-to-learn flow.

## Requirements

### Requirement: Camera Preview Display

The system SHALL display a full-screen live camera preview when the camera screen is active.

- GIVEN the user navigates to the camera screen
- WHEN the camera permission has been granted
- THEN the system SHALL show a live camera preview filling the screen
- AND the system SHALL overlay a large capture button at the bottom center

#### Scenario: Camera permission granted

- GIVEN the app is opened and camera permission was previously granted
- WHEN the camera screen loads
- THEN the live preview SHALL appear within 1 second

#### Scenario: Camera permission denied

- GIVEN the user denied camera permission
- WHEN the camera screen loads
- THEN the system SHALL display a friendly explanation of why the camera is needed
- AND the system SHALL provide a button to open system settings

#### Scenario: Camera permission restricted (parental controls)

- GIVEN the device has parental controls restricting camera access
- WHEN the camera screen loads
- THEN the system SHALL display a message explaining the restriction
- AND the system SHALL suggest that a parent adjust the restriction

### Requirement: Snapshot Capture

The system SHALL allow the user to capture a still image from the camera preview.

- GIVEN the camera preview is active
- WHEN the user taps the capture button
- THEN the system SHALL capture a high-resolution still image
- AND the system SHALL provide haptic feedback
- AND the system SHALL pass the image to the recognition module

#### Scenario: Successful capture

- GIVEN the camera preview is active
- WHEN the user taps the capture button
- THEN the system SHALL save the captured image to a temporary path
- AND navigation to the result screen SHALL occur

#### Scenario: Capture failure

- GIVEN the camera preview is active
- WHEN the capture fails due to a hardware error
- THEN the system SHALL display an error message
- AND the system SHALL return to the live preview state

### Requirement: Camera Lifecycle Management

The system MUST properly manage camera controller lifecycle to prevent black screens and crashes.

- GIVEN the app is in the foreground with camera active
- WHEN the app transitions to `AppLifecycleState.inactive`
- THEN the system SHALL dispose the camera controller
- WHEN the app transitions to `AppLifecycleState.resumed`
- THEN the system SHALL re-initialize the camera controller

#### Scenario: App goes to background

- GIVEN the camera is active
- WHEN the user switches to another app
- THEN the camera controller SHALL be disposed
- WHEN the user returns
- THEN the camera controller SHALL be re-initialized and the preview restored