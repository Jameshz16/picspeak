# Onboarding Specification

## Purpose

Guides new users through the app's core flow and explains why permissions are needed before they encounter permission prompts.

## Requirements

### Requirement: First-Launch Onboarding

The system SHALL present an onboarding flow on first app launch that explains the app's purpose and required permissions.

- GIVEN the app is launched for the first time
- WHEN the onboarding flow starts
- THEN the system SHALL present 3 onboarding screens in sequence
- AND the system SHALL NOT show the onboarding again after completion

#### Scenario: Complete onboarding

- GIVEN the user launches the app for the first time
- WHEN the user advances through all 3 screens and taps "Get Started"
- THEN the system SHALL store that onboarding is complete
- AND the system SHALL navigate to the camera screen

#### Scenario: Skip onboarding

- GIVEN the onboarding flow is showing
- WHEN the user taps "Skip" on any screen
- THEN the system SHALL mark onboarding as complete
- AND the system SHALL navigate to the camera screen

### Requirement: Permission Education Screens

The onboarding SHALL include educational content about why each permission is needed before the system requests it.

- GIVEN the onboarding flow is active
- WHEN the camera permission screen is shown
- THEN the system SHALL explain that the camera is needed to take photos of objects
- AND the system SHALL show a diagram or animation illustrating the scan flow
- WHEN the microphone explanation is shown
- THEN the system SHALL explain that microphone may be requested by the camera plugin
- AND the system SHALL clarify that voice features use TTS, not recording

#### Scenario: User grants permission after education

- GIVEN the permission education screen is shown
- WHEN the user taps "Allow Camera"
- THEN the system SHALL request the camera permission from the OS

#### Scenario: User denies permission after education

- GIVEN the permission education screen is shown
- WHEN the user taps "Not Now"
- THEN the system SHALL proceed to the next onboarding step
- AND the system SHALL show the permission-denied state when the camera screen is accessed later