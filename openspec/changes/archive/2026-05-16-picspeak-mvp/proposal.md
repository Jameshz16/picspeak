# Proposal: PicSpeak MVP

## Intent

Kids and teens learning English/Spanish vocabulary need an engaging, offline-first way to explore real-world objects and learn their names in both languages. PicSpeak uses the device camera + ML Kit image labeling + TTS to create a scan-to-learn loop, with a flashcard review system that reinforces vocabulary through the user's own photos.

## Scope

### In Scope
- Full-screen camera preview with large capture button
- Snapshot → ML Kit image labeling → bilingual card (EN + ES name + TTS pronunciation)
- Favorites system that auto-generates flashcards with the user's original photo
- Flashcard review mode (flip EN/ES, swipe to advance, tap to hear pronunciation)
- Scanned word history list
- Splash screen + app branding
- Onboarding flow (2-3 screens: why camera, how to scan, flashcard review)
- Robust permission handling with clear explanations
- Settings screen (language preference, voice speed, light/dark theme)
- Feedback animations (recognition success, favorited, flip)
- English→Spanish curated mapping for ML Kit's 400 labels
- 100% offline — no backend, no accounts

### Out of Scope
- Real-time scanning without button press (v2)
- Gamification: streaks, badges, progress tracking (v2)
- User accounts / cloud sync (v2)
- Custom ML models / AutoML (v2)
- Category-based filtering (v2)

## Capabilities

### New Capabilities
- `camera-capture`: Camera preview, permission handling, snapshot capture, and lifecycle management
- `object-recognition`: ML Kit image labeling, confidence thresholds, EN→ES label mapping
- `bilingual-pronunciation`: TTS playback in English and Spanish, language availability checks, graceful degradation
- `flashcard-review`: Favorites list, flashcard generation with user photos, flip animation, review mode with swipe navigation
- `onboarding`: Welcome screens explaining app flow and permissions
- `app-settings`: Language preference, voice speed, theme selection, persistent storage
- `word-history`: Scanned word history list with search and recall

### Modified Capabilities
- None (fresh project)

## Approach

Feature-first Clean Architecture with Riverpod. Each capability lives under `lib/features/{name}/` with `presentation/`, `domain/`, and `data/` layers. Camera, ML Kit, and TTS are wrapped behind repository interfaces for testability. Snapshot-based flow (not real-time stream) for v1 reliability and battery conservation. English→Spanish mapping via a bundled JSON map for the ~400 ML Kit labels.

## Affected Areas

| Area | Impact | Description |
|------|--------|-------------|
| `lib/` | New | Full app rewrite from scaffold counter app |
| `pubspec.yaml` | Modified | Add camera, ML Kit, flutter_tts, riverpod, intl dependencies |
| `android/app/src/main/AndroidManifest.xml` | Modified | Camera + microphone permissions, queries block |
| `ios/Runner/Info.plist` | Modified | Camera + microphone usage descriptions |
| `assets/` | New | EN→ES label mapping JSON, onboarding images |
| `test/` | New | Unit + widget tests for each feature |

## Risks

| Risk | Likelihood | Mitigation |
|------|------------|------------|
| ML Kit labels are English-only | High | Bundled curated EN→ES JSON mapping; fallback message for unknown labels |
| Camera permission denied/restricted (parental controls) | Medium | Onboarding explains WHY; graceful empty state; link to settings |
| 400-label model misses user's object | Medium | Confidence threshold display; manual text entry fallback |
| TTS voice quality varies by device | Medium | Check `isLanguageInstalled()` at startup; visual-only fallback |
| Battery drain from camera + ML + TTS | Low | Snapshot model (not stream); dispose camera when not active |
| iOS armv7 build conflict with ML Kit | Low | Exclude armv7 in Xcode build settings per plugin docs |

## Rollback Plan

Since this is a greenfield MVP, rollback is simply reverting to the previous commit. No data migration concerns. Each capability is isolated in a feature folder, so partial reverts are safe.

## Dependencies

- `camera ^0.12.0+1` — Flutter camera plugin
- `google_mlkit_image_labeling ^0.14.2` — On-device image labeling
- `flutter_tts ^4.2.5` — Cross-platform TTS
- `flutter_riverpod` + `riverpod_annotation` — State management + DI
- `intl` + `flutter_localizations` — UI localization ES/EN
- `shared_preferences` — Persistent settings storage
- `path_provider` — File system access for saved photos
- Minimum SDK: Android 24+, iOS 15.5+

## Success Criteria

- [ ] User can open camera, take a photo, and see the object name in EN + ES
- [ ] TTS pronounces the word in both languages
- [ ] User can save a word to favorites and it generates a flashcard
- [ ] Flashcard review mode works: flip, swipe, and pronounce
- [ ] Onboarding flow runs on first launch
- [ ] Settings persist across app restarts (theme, voice speed, language)
- [ ] App works 100% offline after first install
- [ ] App handles denied camera permission gracefully