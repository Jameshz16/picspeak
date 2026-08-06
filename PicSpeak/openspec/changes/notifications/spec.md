# Notifications — Spec (concatenated)

Domains: `notifications` (new full spec) | `app-settings` (delta).

---

# Notifications Specification

## Purpose

Friendly local reminders that bring learners back: an SRS review reminder and a streak reminder, delivered at most once each per day, at a time learned from usage (fallback 4:00 PM), respecting quiet hours and notification permissions. Includes deep-link routing to home and Firebase Cloud Messaging plumbing for future campaigns.

## Requirements

### Requirement: SRS Review Reminder

The system SHALL schedule one local SRS review reminder per day when `FlashcardRepository.getDueCount()` returns more than zero, showing the count of due cards.

#### Scenario: Cards due

- GIVEN `getDueCount()` returns 5 and SRS notifications are enabled
- WHEN the daily schedule is computed
- THEN one reminder SHALL be scheduled stating "You have 5 cards to review today"

#### Scenario: No cards due

- GIVEN `getDueCount()` returns 0
- WHEN the daily schedule is computed
- THEN no SRS reminder SHALL be scheduled

### Requirement: Streak Reminder

The system SHALL schedule one streak reminder per day when the current streak (from `StatsRepository`) is greater than one, reminding the user to protect the streak.

#### Scenario: Active streak

- GIVEN the current streak is 3 days and streak notifications are enabled
- WHEN the daily schedule is computed
- THEN one reminder SHALL be scheduled saying "Don't lose your 3-day streak!"

#### Scenario: No streak at risk

- GIVEN the current streak is 1 or less
- WHEN the daily schedule is computed
- THEN no streak reminder SHALL be scheduled

### Requirement: Smart Schedule Learning

The system SHALL derive the daily reminder time from recorded app-open events and SHALL fall back to 4:00 PM until at least 5 distinct app opens have been recorded.

#### Scenario: Insufficient data

- GIVEN fewer than 5 app opens have been recorded
- WHEN the daily schedule is computed
- THEN reminders SHALL be scheduled at 4:00 PM

#### Scenario: Sufficient data

- GIVEN 5 or more app opens have been recorded
- WHEN the daily schedule is computed
- THEN reminders SHALL be scheduled 30 minutes before the modal app-open hour

### Requirement: Quiet Hours

The system SHALL NOT display notifications between 9:00 PM and 8:00 AM.

#### Scenario: Candidate time inside quiet hours

- GIVEN the candidate reminder time falls between 9:00 PM and 8:00 AM
- WHEN the daily schedule is computed
- THEN the reminder SHALL be deferred to 8:00 AM
- AND the notification SHALL NOT fire during quiet hours

### Requirement: Daily Notification Cap

The system SHALL schedule at most one SRS reminder and one streak reminder per calendar day (maximum two notifications).

#### Scenario: Both reminders eligible

- GIVEN due cards exist and the streak exceeds 1
- WHEN the daily schedule is computed
- THEN exactly one SRS and one streak notification SHALL be scheduled
- AND no duplicate of the same type SHALL be scheduled that day

### Requirement: Notification Permissions

The system SHALL request notification permission before scheduling and SHALL degrade gracefully on denial.

#### Scenario: Android 13+ grant

- GIVEN Android 13+ and `POST_NOTIFICATIONS` not yet granted
- WHEN the user enables notifications
- THEN the system SHALL request `POST_NOTIFICATIONS`
- AND upon grant, reminders SHALL display

#### Scenario: Android 13+ denial

- GIVEN the user denies `POST_NOTIFICATIONS`
- WHEN the scheduler runs
- THEN the app SHALL continue without crashing
- AND no notification SHALL display

#### Scenario: iOS permission

- GIVEN iOS and permission not yet granted
- WHEN the user enables notifications
- THEN the system SHALL present the system permission dialog using the plist description text

### Requirement: Deep Link on Notification Tap

The system SHALL open the app at the home route (`/`) when a notification is tapped.

#### Scenario: Cold start tap

- GIVEN the app is terminated
- WHEN the user taps a notification
- THEN the app SHALL launch and navigate to `/`

#### Scenario: Background tap

- GIVEN the app is in the background
- WHEN the user taps a notification
- THEN the app SHALL foreground and navigate to `/`

### Requirement: FCM Token Foundation

The system SHALL register a Firebase Cloud Messaging token listener and persist token refresh events; it SHALL NOT send campaigns.

#### Scenario: Token refresh

- GIVEN FCM issues a new or refreshed token
- WHEN the listener fires
- THEN the token SHALL be persisted for future use
- AND no campaign message SHALL be sent

### Requirement: Platform Notification Configuration

The system SHALL configure platform notification prerequisites.

#### Scenario: Android channel

- GIVEN the app runs on Android
- WHEN the scheduler initializes
- THEN a notification channel with a name, importance level, and default sound SHALL be registered

#### Scenario: iOS plist

- GIVEN the app runs on iOS
- WHEN the app is built
- THEN the Info.plist SHALL declare the notification permission usage description

## Non-Functional Requirements

- The scheduler MUST be resilient: if a repository or permission call fails, the system SHALL log the failure and skip that day without crashing.
- Scheduling logic MUST be testable with an injectable clock, independent of wall-clock time.
- When permissions are revoked, all scheduled notifications SHALL be cancelled.

---

# Delta for App Settings

## ADDED Requirements

### Requirement: Notification Preferences

The system SHALL expose a notification preferences section in the Settings screen with a master toggle, per-type toggles for SRS and streak reminders, and an optional preferred schedule time. All values MUST persist via `shared_preferences` and survive app restarts.

#### Scenario: Disable all notifications

- GIVEN the notification master toggle is on
- WHEN the user turns it off
- THEN the system SHALL persist the choice
- AND the system SHALL cancel all scheduled notifications

#### Scenario: Disable one reminder type

- GIVEN the master toggle is on and both reminders are scheduled
- WHEN the user disables streak reminders only
- THEN the system SHALL cancel the streak reminder
- AND the SRS reminder SHALL remain scheduled

#### Scenario: Set preferred schedule time

- GIVEN the user sets a preferred schedule time within allowed hours
- WHEN the daily schedule is computed
- THEN the system SHALL use the preferred time instead of the learned time
- AND the choice SHALL persist across app restarts

#### Scenario: Preferred time inside quiet hours

- GIVEN the user sets a preferred schedule time between 9:00 PM and 8:00 AM
- WHEN the daily schedule is computed
- THEN the reminder SHALL be deferred to 8:00 AM
