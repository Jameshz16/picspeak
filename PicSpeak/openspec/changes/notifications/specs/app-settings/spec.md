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
