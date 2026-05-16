# Flashcard Review Specification

## Purpose

Allows users to save recognized words as favorites, auto-generates flashcards with the user's original photo, and provides a review mode with flip and swipe interactions.

## Requirements

### Requirement: Favorite and Flashcard Generation

The system SHALL allow users to save a recognized word to favorites, which automatically creates a flashcard with the original photo.

- GIVEN a recognized word result is displayed
- WHEN the user taps the "save to favorites" button
- THEN the system SHALL store the word, English label, Spanish label, and original photo path
- AND the system SHALL create a flashcard entry
- AND the system SHALL show a confirmation animation

#### Scenario: Save a new word

- GIVEN the result screen shows "Dog" / "Perro"
- WHEN the user taps the favorite button
- THEN the word and photo SHALL be saved to persistent storage
- AND a brief animation SHALL confirm the save

#### Scenario: Save a duplicate word

- GIVEN the word "Dog" / "Perro" is already in favorites
- WHEN the user taps the favorite button again
- THEN the system SHALL display a message indicating the word is already saved
- AND the system SHALL NOT create a duplicate entry

### Requirement: Flashcard Display

The system SHALL display flashcards with flip interaction showing English on one side and Spanish on the other.

- GIVEN the user opens the favorites/flashcard list
- WHEN the user taps a flashcard
- THEN the front side SHALL show the original photo and the English label
- WHEN the user taps the card again
- THEN the card SHALL flip to reveal the Spanish label

#### Scenario: Flip to Spanish

- GIVEN a flashcard is showing the English side "Dog" with photo
- WHEN the user taps the card
- THEN the card SHALL animate a flip transition
- AND the back side SHALL display "Perro" with the same photo

### Requirement: Pronunciation on Flashcard

Each flashcard side SHALL include a pronunciation button for the displayed language.

- GIVEN a flashcard is showing the English side
- WHEN the user taps the English speaker icon
- THEN the system SHALL pronounce the English word
- GIVEN a flashcard is showing the Spanish side
- WHEN the user taps the Spanish speaker icon
- THEN the system SHALL pronounce the Spanish word

### Requirement: Review Mode

The system SHALL provide a sequential review mode where flashcards are presented one at a time with swipe navigation.

- GIVEN the user has 3 or more saved flashcards
- WHEN the user starts review mode
- THEN the system SHALL present flashcards one at a time in shuffled order
- AND the user SHALL swipe left to advance to the next card
- AND the user SHALL swipe right to go back to the previous card
- AND a progress indicator SHALL show current position (e.g., "3/12")

#### Scenario: Complete review session

- GIVEN the user is in review mode with 5 cards
- WHEN the user has swiped through all 5 cards
- THEN the system SHALL display a session complete screen
- AND the system SHALL offer to restart or return to the favorites list

#### Scenario: Remove card during review

- GIVEN the user is in review mode
- WHEN the user long-presses a card and selects "remove"
- THEN the system SHALL remove the word from favorites
- AND the system SHALL advance to the next card