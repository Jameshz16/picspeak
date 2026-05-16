# Bilingual Pronunciation Specification

## Purpose

Provides text-to-speech pronunciation of recognized words in both English and Spanish, with graceful degradation when voices are unavailable.

## Requirements

### Requirement: Dual-Language Pronunciation

The system SHALL pronounce recognized words in both English and Spanish when the user taps the speaker button.

- GIVEN a recognized word with English and Spanish labels
- WHEN the user taps the English pronunciation button
- THEN the system SHALL speak the English label using TTS with the English voice
- WHEN the user taps the Spanish pronunciation button
- THEN the system SHALL speak the Spanish label using TTS with the Spanish voice

#### Scenario: Both languages available

- GIVEN the device has English and Spanish TTS voices installed
- WHEN the user taps the English speaker icon
- THEN the system SHALL speak the English word at the configured speed
- WHEN the user taps the Spanish speaker icon
- THEN the system SHALL speak the Spanish word at the configured speed

#### Scenario: One language unavailable

- GIVEN the device lacks a Spanish TTS voice
- WHEN the pronunciation screen loads
- THEN the system SHALL show the Spanish pronunciation button as disabled with a "voice not available" tooltip
- AND the system SHALL still allow English pronunciation

### Requirement: Language Availability Check

The system MUST check TTS language availability at app startup and inform the user of missing voices.

- GIVEN the app is starting
- WHEN TTS initialization completes
- THEN the system SHALL check `isLanguageAvailable` for both "en-US" and "es-ES"
- AND the system SHALL store availability status for use throughout the app

#### Scenario: All voices available

- GIVEN both "en-US" and "es-ES" voices are installed
- WHEN TTS initializes
- THEN the system SHALL mark both languages as available
- AND both pronunciation buttons SHALL be active

#### Scenario: Voice needs download

- GIVEN the Spanish voice is not installed but downloadable
- WHEN TTS initializes
- THEN the system SHALL prompt the user to download the Spanish voice
- AND the system SHALL offer a link to the system TTS settings

### Requirement: Graceful Degradation

When TTS is completely unavailable, the system SHALL continue to function with visual-only presentation.

- GIVEN TTS fails to initialize on the device
- WHEN the user views a recognized word
- THEN the system SHALL display both language labels prominently
- AND the system SHALL show a visual speaker icon indicating pronunciation is unavailable
- AND the system SHALL NOT block any other functionality