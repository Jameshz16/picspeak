# App Settings Specification

## Purpose

Provides persistent user preferences for language, voice speed, and visual theme that affect the entire app experience.

## Requirements

### Requirement: Language Preference

The system SHALL allow the user to select their primary language and secondary language from the supported options.

- GIVEN the user opens the Settings screen
- WHEN the user selects a primary language
- THEN the system SHALL save the preference to persistent storage
- AND the system SHALL use this language for the primary label display order

#### Scenario: Switch primary language to Spanish

- GIVEN the default primary language is English
- WHEN the user selects Spanish as primary
- THEN flashcards SHALL show the Spanish label on the front
- AND the English label SHALL appear on the back

### Requirement: Voice Speed Control

The system SHALL allow the user to adjust the TTS speech rate from 0.25x to 2.0x.

- GIVEN the user opens the Settings screen
- WHEN the user adjusts the voice speed slider
- THEN the system SHALL save the speed value to persistent storage
- AND the system SHALL apply the new speed to all subsequent TTS playback

#### Scenario: Slow down pronunciation

- GIVEN the default speed is 1.0x
- WHEN the user adjusts the slider to 0.5x
- THEN all future TTS playback SHALL use 0.5x speed
- AND the system SHALL retain this setting across app restarts

### Requirement: Theme Selection

The system SHALL allow the user to choose between light, dark, and system-following themes.

- GIVEN the user opens the Settings screen
- WHEN the user selects a theme
- THEN the system SHALL apply the theme immediately
- AND the system SHALL persist the selection across app restarts

#### Scenario: Follow system theme

- GIVEN the user selects "Follow System"
- WHEN the device switches to dark mode
- THEN the app SHALL switch to dark theme within 1 second

### Requirement: Persistent Storage

All settings MUST be persisted to the device using `shared_preferences` and survive app restarts.

- GIVEN the user has configured settings
- WHEN the app is closed and reopened
- THEN all settings (language, voice speed, theme) SHALL be restored to their last values