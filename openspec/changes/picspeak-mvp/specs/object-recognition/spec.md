# Object Recognition Specification

## Purpose

Identifies objects in captured images using ML Kit on-device image labeling and maps English labels to Spanish equivalents via a bundled dictionary.

## Requirements

### Requirement: Image Labeling

The system SHALL analyze captured images using ML Kit Image Labeling and return recognized object labels with confidence scores.

- GIVEN a captured image from the camera
- WHEN the image is processed by ML Kit
- THEN the system SHALL return up to 5 labels with confidence scores
- AND the system SHALL filter labels below the minimum confidence threshold of 0.7

#### Scenario: Object recognized with high confidence

- GIVEN the user captures a photo of a dog
- WHEN ML Kit processes the image
- THEN the top label SHALL be "Dog" with confidence ≥ 0.7
- AND the system SHALL present the bilingual result

#### Scenario: No labels above threshold

- GIVEN the user captures a photo of an unclear or ambiguous object
- WHEN ML Kit returns labels all below 0.7 confidence
- THEN the system SHALL display a "not recognized" message
- AND the system SHALL offer the option to try again or enter the word manually

#### Scenario: Multiple labels above threshold

- GIVEN the image returns multiple labels above 0.7
- WHEN the results are displayed
- THEN the system SHALL show the top label as the primary result
- AND the system SHALL offer alternate suggestions as tappable options

### Requirement: English to Spanish Mapping

The system SHALL map each ML Kit English label to its Spanish equivalent using a bundled JSON dictionary.

- GIVEN ML Kit returns an English label
- WHEN the mapping lookup is performed
- THEN the system SHALL return the Spanish translation
- AND the system SHALL fall back to displaying the English label with a "translation unavailable" note if the label is not in the dictionary

#### Scenario: Label found in dictionary

- GIVEN ML Kit returns the label "Dog"
- WHEN the system looks up the mapping
- THEN the system SHALL return "Perro" as the Spanish equivalent

#### Scenario: Label not in dictionary

- GIVEN ML Kit returns the label "Thermostat"
- WHEN the system looks up the mapping
- THEN the system SHALL display "Thermostat" with a note indicating translation unavailable
- AND the system SHALL NOT crash or show an empty string

### Requirement: Offline Operation

The system MUST function entirely offline after initial app installation.

- GIVEN the device has no network connection
- WHEN the user captures and processes an image
- THEN ML Kit on-device labeling SHALL still work
- AND the EN→ES mapping SHALL still resolve