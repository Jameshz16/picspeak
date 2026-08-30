# Proposal: Notifications

## Intent

Kids stop returning: SRS cards go overdue, streaks die silently. Add friendly local notifications — SRS reminder ("You have 5 cards to review today") + streak reminder ("Don't lose your 3-day streak!") — scheduled at a time learned from usage, max 2/day, quiet hours. Wire FCM plumbing for future campaigns.

## Scope

### In Scope
- `flutter_local_notifications`: Android channel + `POST_NOTIFICATIONS` runtime permission (13+), iOS permission flow
- SRS reminder (`FlashcardRepository.getDueCount()`) + streak reminder (`StatsRepository`) — max 1 each/day
- Smart scheduling: learn review time from app opens; fallback 4 PM; ~30 min before
- Quiet hours (9 PM–8 AM)
- Settings: notification prefs section (master + per-type toggles)
- Tap → deep link to home (`/`)
- FCM foundation: `firebase_messaging`, token listener only

### Out of Scope
- FCM campaigns; in-app notification center; weekly digests; per-child profiles

## Capabilities

### New Capabilities
- `notifications`: local scheduling (SRS + streak), usage-time learning, quiet hours, permissions, deep-link routing, platform config, FCM init

### Modified Capabilities
- `app-settings`: notification preferences persisted via `shared_preferences` + Settings screen section

## Approach

New `lib/features/notifications/` feature (Clean Architecture + Riverpod). `NotificationScheduler` wraps `flutter_local_notifications` with `zonedSchedule`; `UsageTimeTracker` records app-open times and derives the modal review hour (fallback 4 PM until enough data). Reuses `getDueCount()` and `StatsRepository` streak keys. Init scheduler + FCM in `main.dart`; taps handled via `getNotificationAppLaunchDetails()` + router to `/`.

## Affected Areas

| Area | Impact | Description |
|------|--------|-------------|
| `lib/features/notifications/` | New | Scheduler, tracker, providers, prefs UI |
| `lib/features/app_settings/` | Modified | Prefs section + persisted fields |
| `lib/main.dart` | Modified | Scheduler + FCM init |
| `lib/app/router.dart` | Modified | Deep-link handling to `/` |
| `pubspec.yaml` | Modified | Add `flutter_local_notifications`, `firebase_messaging`, `timezone` |
| `android/`, `ios/` | Modified | Channel/receiver + `POST_NOTIFICATIONS`; iOS permission text |

## Risks

| Risk | Likelihood | Mitigation |
|------|------------|------------|
| Permission denied (parental controls) | Med | Graceful fallback, no crash |
| Parents find notifications spammy | Med | Cap 2/day, quiet hours, easy opt-out |
| Learned schedule unreliable | Med | Fallback 4 PM until ≥5 opens |
| Android 13+ permission timing | Low | In-app rationale, not first launch |

## Rollback Plan

Revert `lib/features/notifications/` and `main.dart` init lines; remove pubspec deps. Settings fields are additive — ignored when absent. Notifications self-cancel on revoke; FCM token listener is safe to remove. No server state.

## Dependencies

- New: `flutter_local_notifications`, `timezone`, `firebase_messaging`
- Existing: `shared_preferences`, `permission_handler`, Riverpod, go_router

## Success Criteria

- [ ] SRS + streak reminders fire max 1 each/day at learned time or 4 PM
- [ ] Quiet hours block all notifications 9 PM–8 AM
- [ ] Tapping a notification opens app at `/`
- [ ] Settings toggles persist and cancel scheduled notifications
- [ ] No reminders when due count is 0 and streak ≤ 1
- [ ] Android 13+ requests permission; denial degrades gracefully
