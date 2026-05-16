# Word History Specification

## Purpose

Maintains a chronological record of all scanned words for easy recall and review, independent of the favorites/flashcard system.

## Requirements

### Requirement: Automatic History Logging

The system SHALL automatically log every recognized word to the history when a scan result is confirmed.

- GIVEN the user scans an object and ML Kit returns a result above the confidence threshold
- WHEN the result is displayed on screen
- THEN the system SHALL create a history entry containing: English label, Spanish label, confidence score, timestamp, and photo path
- AND the system SHALL NOT create a duplicate if the same word is scanned within 5 minutes

#### Scenario: First scan of a word

- GIVEN the user scans a dog
- WHEN the result "Dog" / "Perro" appears
- THEN a history entry SHALL be created with the current timestamp and photo

#### Scenario: Re-scan within 5 minutes

- GIVEN the user scanned "Dog" / "Perro" 2 minutes ago
- WHEN the user scans a dog again
- THEN the system SHALL NOT create a duplicate entry
- AND the system SHALL update the existing entry's timestamp

### Requirement: History Browsing

The system SHALL display the word history in reverse chronological order with search functionality.

- GIVEN the history contains 20+ entries
- WHEN the user opens the history screen
- THEN the most recent entries SHALL appear at the top
- AND each entry SHALL show the photo thumbnail, English word, and Spanish word
- AND the system SHALL provide a search field that filters by either language

#### Scenario: Search for a word

- GIVEN the history contains "Dog", "Cat", "Chair"
- WHEN the user types "Perro" in the search field
- THEN the list SHALL filter to show only "Dog" / "Perro"

#### Scenario: Empty history

- GIVEN the user has never scanned any object
- WHEN the user opens the history screen
- THEN the system SHALL display an empty state with a call-to-action to start scanning

### Requirement: History-to-Flashcard Conversion

The system SHALL allow converting any history entry into a flashcard favorite.

- GIVEN the user views a history entry
- WHEN the user taps "Add to favorites"
- THEN the entry SHALL be added to the flashcard favorites list
- AND the system SHALL show a confirmation
- AND if the word is already a favorite, the system SHALL show "already saved"