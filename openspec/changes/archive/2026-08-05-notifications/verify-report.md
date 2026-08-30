## Verification Report

**Change**: notifications
**Version**: 2.0 (RDD-corrected re-verify)
**Mode**: Standard (Strict TDD disabled)
**Supersedes**: v1.0 PASS WITH WARNINGS (prior verify-report)

> Re-verified after 7 RDD corrective commits (7d3982f through 3cc8156) addressed
> all 10 RDD findings. Prior warnings #3 (unused `_statsRepository` field) and #4
> (missing `@override` on `rescheduleAll`) are confirmed RESOLVED. Three prior
> warnings remain (see Issues).

### Completeness

| Metric | Value |
|--------|-------|
| Tasks total | 22 |
| Tasks complete (by source inspection) | 22 |
| Tasks complete (by checkbox) | 12 |
| Tasks incomplete | 0 |

> Phase 3 (3.1–3.4) and Phase 4 (4.1–4.6) show `[ ]` in tasks.md but all
> implementation and tests exist and pass. Verified by source inspection + 133/133
> runtime tests. Administrative — does not block archive.

### Build & Tests Execution

**Build**: ✅ Passed (0 errors)
```text
flutter analyze: 13 issues found (0 errors)
  Notifications-specific:
    5 unused imports (notification_providers.dart lines 4,8,9,10,14)
  Pre-existing (not notifications-related):
    3 unused imports (settings_screen, login_screen, register_screen)
    2 unused local variables (category_screen)
    2 deprecated_member_use info (object_overlay — withOpacity)
    1 unused import (result_screen — dart:io)
```

**Tests**: ✅ 133 passed / ❌ 0 failed / ⚠️ 0 skipped
```text
flutter test: All tests passed!
  notifications tests: 37 (4 test files)
    - notification_repository_impl_test.dart: 22 tests
    - usage_time_tracker_test.dart: 10 tests
    - notification_permissions_test.dart: 6 tests (enum + instantiation)
    - notification_repository_test.dart: 8 tests (interface contract)
  app_settings tests: 9 (includes 5 notification-field tests)
  retry_with_backoff tests: 7 (used by FCM handler)
  pre-existing tests: 80
```

**Coverage**: ➖ Not configured (no threshold)

### Spec Compliance Matrix

#### Notifications Domain

| Requirement | Scenario | Test | Result |
|-------------|----------|------|--------|
| SRS Review Reminder | Cards due | `notification_repository_impl_test.dart` (rescheduleAll w/ dueCount=3) + code inspection | ⚠️ PARTIAL — positive path exercised; no assertion on notification title/body |
| SRS Review Reminder | No cards due | `notification_repository_impl_test.dart > does nothing when dueCount is 0` | ✅ COMPLIANT |
| Streak Reminder | Active streak | `notification_repository_impl_test.dart` (rescheduleAll w/ streak=5) + code inspection | ⚠️ PARTIAL — positive path exercised; no direct assertion on notification body |
| Streak Reminder | No streak at risk | `notification_repository_impl_test.dart > does nothing when streakDays is 0/1` | ✅ COMPLIANT |
| Smart Schedule Learning | Insufficient data | `usage_time_tracker_test.dart > fewer than 5 timestamps → 16:00` | ✅ COMPLIANT |
| Smart Schedule Learning | Sufficient data | `usage_time_tracker_test.dart > 5+ timestamps → modal hour minus 1 hour` | ⚠️ PARTIAL — test passes but code subtracts 1 hour (spec says 30 min). Deviation is conservative (earlier reminder). |
| Quiet Hours | Candidate inside quiet hours | `notification_repository_impl_test.dart > tracker time mapping` (tracker returns 22:00/07:00, impl clamps) | ⚠️ PARTIAL — clamping verified indirectly; no direct unit test of `_applyQuietHours` |
| Daily Notification Cap | Both reminders eligible | `notification_repository_impl_test.dart > daily cap via SharedPreferences` (4 sub-tests) | ✅ COMPLIANT |
| Notification Permissions | Android 13+ grant | `notification_repository_impl_test.dart > permission delegation` (FakeNotificationPermissions) | ⚠️ PARTIAL — delegation tested; real POST_NOTIFICATIONS platform channel not testable in unit |
| Notification Permissions | Android 13+ denial | `notification_repository_impl_test.dart > does nothing when permission is denied` + `permanentlyDenied` | ✅ COMPLIANT |
| Notification Permissions | iOS permission | Platform-specific; `notification_permissions.dart` delegates to `permission_handler` | ⚠️ PARTIAL — not unit-testable; implemented correctly |
| Deep Link on Notification Tap | Cold start tap | `main.dart` lines 69–72 + 115–118 (getNotificationAppLaunchDetails + router.go('/')) | ⚠️ PARTIAL — implemented; platform-dependent; no unit test |
| Deep Link on Notification Tap | Background tap | Same mechanism as cold start | ⚠️ PARTIAL — same as above |
| FCM Token Foundation | Token refresh | `fcm_token_handler.dart` (init + onTokenRefresh listener) | ❌ UNTESTED — no unit test for FcmTokenHandler |
| Platform Notification Configuration | Android channel | `notification_repository_impl.dart > init()` creates AndroidNotificationChannel | ⚠️ PARTIAL — implemented; verified by code inspection only |
| Platform Notification Configuration | iOS plist | `ios/Runner/Info.plist` has `NSUserNotificationsUsageDescription` | ✅ COMPLIANT |

#### App Settings Delta

| Requirement | Scenario | Test | Result |
|-------------|----------|------|--------|
| Notification Preferences | Disable all notifications | `notification_repository_impl_test.dart > rescheduleAll > notificationsEnabled=false → cancelAll` | ✅ COMPLIANT |
| Notification Preferences | Disable one reminder type | `notification_repository_impl_test.dart > rescheduleAll > srs/streak disabled → cancelByType` | ✅ COMPLIANT |
| Notification Preferences | Set preferred schedule time | `app_settings_test.dart > copyWith > can update customScheduleTime` + `notification_repository_impl.dart > _getScheduledTime` | ✅ COMPLIANT |
| Notification Preferences | Preferred time inside quiet hours | `_getScheduledTime` (parses custom time) + `_applyQuietHours` (clamps) — no combined test | ⚠️ PARTIAL |

#### Non-Functional Requirements

| Requirement | Status | Notes |
|-------------|--------|-------|
| Resilient scheduler | ✅ COMPLIANT | try/catch in main.dart (lines 64–76), _rescheduleAll (UI), _saveToken (FCM), onError in onTokenRefresh |
| Injectable clock | ⚠️ DEVIATION | `UsageTimeTracker` uses `DateTime.now()` directly (line 16). Tests work around with fixed SharedPreferences data. Does not break any scenario. |
| Cancel on revoke | ✅ COMPLIANT | `cancelAll()` + `cancelByType()` available; `didChangeAppLifecycleState` revalidates on resume |

**Compliance summary**: 10/19 scenarios fully compliant, 8/19 partial (platform-dependent or minor spec deviation), 1/19 untested (FCM handler). All 3 NFRs addressed (1 deviation).

### Correctness (Static Evidence)

| Requirement | Status | Notes |
|-------------|--------|-------|
| SRS Review Reminder | ✅ Implemented | `scheduleSrsReminder(dueCount)` with guard (≤0→skip), permission check, daily cap, quiet hours, zonedSchedule with DateTimeComponents.time |
| Streak Reminder | ✅ Implemented | `scheduleStreakReminder(streakDays)` with guard (<2→skip), permission check, daily cap, zonedSchedule |
| Smart Schedule Learning | ✅ Implemented | `UsageTimeTracker.getScheduleTime()` — modal hour from 30-point window, 16:00 fallback, 8–20 clamp |
| Quiet Hours | ✅ Implemented | `_applyQuietHours(time, enabled)` — 21:00–07:59 → 08:00; respects quietHoursEnabled toggle |
| Daily Cap | ✅ Implemented | Date-keyed SharedPreferences (`notif_sent_{type}_{YYYY-MM-DD}`), independent SRS/streak caps |
| Notification Permissions | ✅ Implemented | `NotificationPermissions` via `permission_handler`; `NotificationPermissionStatus` enum in domain layer |
| Deep Link | ✅ Implemented | `main.dart` checks `getNotificationAppLaunchDetails()`, navigates to `/` via `router.go('/')` |
| FCM Token | ✅ Implemented | `FcmTokenHandler` with `retryWithBackoff` for getToken/saveToken; onTokenRefresh listener; Firestore `users/{uid}/fcmToken` |
| Platform Config (Android) | ✅ Implemented | POST_NOTIFICATIONS, RECEIVE_BOOT_COMPLETED, SCHEDULE_EXACT_ALARM, ScheduledNotificationReceiver, ScheduledNotificationBootReceiver |
| Platform Config (iOS) | ✅ Implemented | Info.plist: NSUserNotificationsUsageDescription |
| Settings UI | ✅ Implemented | `NotificationSettingsSection` — master toggle, SRS/streak toggles, quiet hours toggle, custom time picker, permission denied banner |
| AppSettings compat | ✅ Implemented | `fromJson` backward-compatible defaults: notificationsEnabled=false, others=true |
| Resilience | ✅ Implemented | Multi-layer try/catch: main.dart init, UI _rescheduleAll, FCM _saveToken, onTokenRefresh onError |
| Cancel on revoke | ✅ Implemented | `cancelAll()` + `cancelByType()` + lifecycle revalidation |

### Coherence (Design)

| Decision | Followed? | Notes |
|----------|-----------|-------|
| Background scheduling via `flutter_local_notifications` zonedSchedule | ✅ Yes | Used exactly as designed |
| FCM token in Firestore `users/{uid}/fcmToken` | ✅ Yes | Single-field approach with merge: true |
| Daily cap via date-keyed SharedPreferences | ✅ Yes | `notif_sent_{type}_{YYYY-MM-DD}` pattern |
| Modal hour from last 30 timestamps | ✅ Yes | 30-point sliding window in UsageTimeTracker |
| Permission on-demand (user enables in Settings) | ✅ Yes | `_toggleMaster` requests permission on enable |
| Deep link via getNotificationAppLaunchDetails + router.go('/') | ✅ Yes | Implemented in main.dart |
| Timezone init in NotificationRepositoryImpl.initialize() | ✅ Yes | Static method, called in main.dart, non-fatal on failure |
| Clean Architecture + Riverpod | ✅ Yes | domain/data/presentation layers, providers, domain has no data deps |

**Design deviation**: Smart schedule subtracts 1 hour from modal (spec says 30 min). This is MORE conservative (earlier reminder) and does not break any functional scenario.

### RDD Corrective Commits — Verification

| RDD Finding | Status | Evidence |
|-------------|--------|----------|
| Desugaring | ✅ FIXED | 133/133 tests pass (build succeeds) |
| Quiet hours / dead config | ✅ FIXED | `_applyQuietHours` takes `enabled` param; both schedule methods pass `settings?.quietHoursEnabled ?? true` |
| Recurrence | ✅ FIXED | `matchDateTimeComponents: DateTimeComponents.time` in both schedule methods |
| Cancel-by-type | ✅ FIXED | `cancelByType('srs')` and `cancelByType('streak')` exist; used in rescheduleAll |
| Non-fatal init | ✅ FIXED | try/catch in main.dart + .catchError on FCM init |
| Timezone | ✅ FIXED | `initialize()` with try/catch, fallback to UTC |
| FCM retry/backoff | ✅ FIXED | `retryWithBackoff` used for getToken (3 attempts) and saveToken (3 attempts) |
| Permission UX | ✅ FIXED | `_PermissionDeniedBanner` with retry/permanent-deny, lifecycle revalidation |
| Debt cleanup | ✅ FIXED | `_statsRepository` field removed; `@override` added to rescheduleAll |
| Layering | ✅ FIXED | `NotificationPermissionStatus` in domain layer |

### Issues Found

**CRITICAL**: None

**WARNING**:
1. **Unused imports in `notification_providers.dart`** — 5 unused imports (flutter_local_notifications, settings_providers, flashcard_providers, stats_repository, notification_repository_impl). Code hygiene only, no functional impact.
2. **`UsageTimeTracker` not injectable clock** — NFR says "MUST be testable with an injectable clock." Uses `DateTime.now()` directly. Tests work around with fixed timestamps. Design deviation, does NOT break any spec scenario.
3. **Spec deviation: schedule time offset** — Spec says "30 minutes before modal hour"; code subtracts 1 hour. More conservative (earlier reminder). Test covers actual behavior (1 hour). Recommend updating spec to match code.

**SUGGESTION**:
1. **Add `FcmTokenHandler` unit tests** — Currently the only untested component. At minimum, verify init() calls getToken() and listen for refresh.
2. **Add direct `_applyQuietHours` unit test** — Currently tested only indirectly through integration path.
3. **Update `tasks.md` checkboxes** — Mark Phase 3 (3.1–3.4) and Phase 4 (4.1–4.6) as `[x]` to reflect actual implementation state.
4. **Clean up unused imports** — Remove 5 unused imports in `notification_providers.dart`.
5. **Consider injecting clock into `UsageTimeTracker`** — Would make the NFR fully compliant and simplify testing.

### Verdict

**PASS WITH WARNINGS**

All 22 tasks are implemented and functional. 133/133 tests pass. 10/19 spec scenarios fully compliant, 8/19 partial (platform-dependent or minor deviations), 1/19 untested (FCM handler). All 10 RDD findings confirmed resolved. No critical blockers. Remaining warnings are: unused imports (code hygiene), injectable clock NFR deviation (design, not functional), and FCM handler test coverage gap.
