# Tasks: PicSpeak MVP

## Review Workload Forecast

| Field | Value |
|-------|-------|
| Estimated changed lines | ~2000+ |
| 400-line budget risk | High |
| Chained PRs recommended | Yes |
| Suggested split | PR 1 (Foundation) → PR 2 (Camera+Recognition) → PR 3 (Flashcards+History) → PR 4 (Onboarding+Settings+Tests) |
| Delivery strategy | ask-on-risk |
| Chain strategy | pending |

Decision needed before apply: Yes
Chained PRs recommended: Yes
Chain strategy: pending
400-line budget risk: High

### Suggested Work Units

| Unit | Goal | Likely PR | Notes |
|------|------|-----------|-------|
| 1 | Foundation: dependencies, permissions, core services, domain models, router shell, settings/onboarding repos | PR 1 | Targets `main`; all tests/docs included |
| 2 | Camera + Recognition: camera screen, ML Kit integration, result screen, TTS, history logging | PR 2 | Targets PR 1 branch; depends on core services |
| 3 | Flashcards + Review: flashcard repo, list/review screens, flip/swipe, history-to-favorite | PR 3 | Targets PR 2 branch; depends on RecognizedWord model |
| 4 | Onboarding + Settings UI + Tests: onboarding flow, settings screen, navigation wiring, all tests | PR 4 | Targets PR 3 branch; final integration |

## Phase 1: Foundation

- [ ] 1.1 Add dependencies to `pubspec.yaml` (camera, mlkit, flutter_tts, riverpod, go_router, shared_prefs, path_provider, intl)
- [ ] 1.2 Add camera + audio permissions to `AndroidManifest.xml` and `Info.plist`
- [ ] 1.3 Create `assets/labels_es.json` with EN→ES mapping for ~400 ML Kit labels
- [x] 1.4 Create `lib/app/theme.dart` with ThemeMode notifier and light/dark themes
- [x] 1.5 Create `lib/app/router.dart` with GoRouter routes for all screens
- [x] 1.6 Rewrite `lib/main.dart` to `ProviderScope` + `MaterialApp.router`
- [x] 1.7 Create `lib/core/services/tts_service.dart` — FlutterTts wrapper with availability + speed
- [x] 1.8 Create `lib/core/services/permission_service.dart` — camera permission status stream
- [x] 1.9 Create `lib/core/data/label_map_repository.dart` — loads `labels_es.json`, exposes `translate()`
- [x] 1.10 Create settings domain model + `SettingsRepository` in `lib/features/app_settings/`
- [x] 1.11 Create `OnboardingRepository` in `lib/features/onboarding/data/` (shared_prefs bool flag)

## Phase 2: Camera + Recognition

- [x] 2.1 Create `CameraRepository` in `lib/features/camera/data/` wrapping `CameraController`
- [x] 2.2 Create `CameraScreen` in `lib/features/camera/presentation/` with full-screen preview + capture button
- [x] 2.3 Handle camera lifecycle (dispose on background, re-init on resume)
- [x] 2.4 Create `MlKitRepository` in `lib/features/object_recognition/data/` with 0.7 confidence threshold
- [x] 2.5 Create `RecognizedWord` model in `lib/features/object_recognition/domain/`
- [x] 2.6 Create `ResultScreen` in `lib/features/object_recognition/presentation/` showing bilingual card + TTS + favorite
- [x] 2.7 Integrate TTS pronunciation buttons for EN and ES on `ResultScreen`
- [x] 2.8 Create `HistoryRepository` in `lib/features/word_history/data/` (JSON in shared_prefs, 5-min dedup)
- [x] 2.9 Create `HistoryScreen` in `lib/features/word_history/presentation/` with reverse-chronological list + search

## Phase 3: Flashcards + Review

- [x] 3.1 Create `FlashcardRepository` in `lib/features/flashcard_review/data/` (save/load/remove, dedup)
- [x] 3.2 Create `FlashcardListScreen` in `lib/features/flashcard_review/presentation/`
- [x] 3.3 Create `FlashcardReviewScreen` with flip animation, swipe navigation, and progress indicator
- [x] 3.4 Add TTS pronunciation buttons to each side of the flashcard
- [x] 3.5 Add "Add to favorites" action on `HistoryScreen` entries

## Phase 4: Onboarding + Settings Integration

- [x] 4.1 Create `OnboardingScreen` in `lib/features/onboarding/presentation/` with 3 pages + skip
- [x] 4.2 Add permission education screens within onboarding flow
- [x] 4.3 Create `SettingsScreen` in `lib/features/app_settings/presentation/` (language, voice speed, theme)
- [x] 4.4 Wire onboarding guard in router: first launch routes to onboarding, then camera
- [x] 4.5 Wire bottom navigation across camera, favorites, history, and settings

## Phase 5: Testing

- [x] 5.1 Unit test `LabelMapRepository.translate` with known, unknown, and null inputs
- [x] 5.2 Unit test `FlashcardRepository` save/load/remove/dedup behavior
- [x] 5.3 Unit test `HistoryRepository` log, 5-minute dedup, and search
- [x] 5.4 Widget test `CameraScreen` permission granted/denied states
- [x] 5.5 Widget test `ResultScreen` tap-to-speak and favorite button interactions
- [x] 5.6 Widget test `FlashcardReviewScreen` flip animation and swipe navigation
