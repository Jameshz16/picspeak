# Design: PicSpeak MVP

## Technical Approach

Greenfield Flutter app using Feature-first Clean Architecture with Riverpod. Each capability maps to `lib/features/{name}/` with `presentation/`, `domain/`, and `data/` layers. Camera, ML Kit, and TTS are wrapped behind repository interfaces for testability. Snapshot-based flow (not real-time stream) for v1 reliability and battery conservation. English→Spanish mapping via a bundled JSON map for the ~400 ML Kit labels.

## Architecture Decisions

| Decision | Options | Tradeoffs | Choice |
|----------|---------|-----------|--------|
| State management | Riverpod / BLoC / GetX | Riverpod = built-in DI + testable; BLoC = boilerplate; GetX = less explicit | **Riverpod** with `StateNotifier`/`AsyncValue` |
| Navigation | GoRouter / Navigator 2.0 / imperative | GoRouter = deep-link ready; imperative = simpler for 5 screens | **GoRouter** for declarative routing |
| Local persistence | shared_prefs / Hive / sqflite | shared_prefs = simple key-value for settings; Hive = faster but adds dep; sqflite = overkill | **shared_preferences** for settings; **path_provider + File** for photos |
| Image labeling | google_mlkit_image_labeling / TensorFlow Lite | ML Kit = simpler, on-device, ~400 labels; TFLite = custom model overhead | **google_mlkit_image_labeling** |
| EN→ES mapping | Bundled JSON / hardcoded Map / API | JSON = editable, ~20KB; Map = compiled but large; API = breaks offline | **Bundled `assets/labels_es.json`** loaded into `Map<String,String>` at startup |
| TTS engine | flutter_tts / speech_to_text | flutter_tts = cross-platform TTS; speech_to_text = not needed | **flutter_tts** with `isLanguageAvailable` checks |
| Flashcard storage | In-memory + shared_prefs / sqflite / Hive | In-memory list serialized to JSON in shared_prefs = simplest for MVP | **JSON string in shared_prefs** for favorites/history |

## Data Flow

```
CameraScreen (UI)
  → CameraController (Riverpod)
  → takePicture() → temp File path
  → ObjectRecognitionNotifier
    → MlKitRepository.labelImage(path)
    → LabelMapRepository.lookup(enLabel)
    → emit RecognizedWord(en, es, confidence, photoPath)
  → ResultScreen
    → TtsNotifier.speak(en|es)
    → FlashcardRepository.save(word) → shared_prefs
    → HistoryRepository.log(word) → shared_prefs
```

## File Changes

| File | Action | Description |
|------|--------|-------------|
| `lib/main.dart` | Modify | Replace counter scaffold with `ProviderScope` + `MaterialApp.router` |
| `lib/app/router.dart` | Create | GoRouter config: onboarding → camera → result → favorites → history → settings |
| `lib/app/theme.dart` | Create | `ThemeMode` notifier + `ThemeData` for light/dark/system |
| `lib/core/services/tts_service.dart` | Create | Wrapper around `FlutterTts`; checks availability; applies speed |
| `lib/core/services/permission_service.dart` | Create | Camera permission + status stream |
| `lib/core/data/label_map_repository.dart` | Create | Loads `assets/labels_es.json`; exposes `String? translate(String en)` |
| `lib/features/camera/` | Create | `presentation/camera_screen.dart`, `domain/camera_state.dart`, `data/camera_repository.dart` |
| `lib/features/object_recognition/` | Create | `presentation/result_screen.dart`, `domain/recognized_word.dart`, `data/mlkit_repository.dart` |
| `lib/features/flashcard_review/` | Create | `presentation/flashcard_list_screen.dart`, `flashcard_review_screen.dart`, `domain/flashcard.dart`, `data/flashcard_repository.dart` |
| `lib/features/onboarding/` | Create | `presentation/onboarding_screen.dart`, `data/onboarding_repository.dart` (bool flag in shared_prefs) |
| `lib/features/app_settings/` | Create | `presentation/settings_screen.dart`, `domain/app_settings.dart`, `data/settings_repository.dart` |
| `lib/features/word_history/` | Create | `presentation/history_screen.dart`, `domain/history_entry.dart`, `data/history_repository.dart` |
| `assets/labels_es.json` | Create | Curated EN→ES mapping for ML Kit labels |
| `pubspec.yaml` | Modify | Add `camera`, `google_mlkit_image_labeling`, `flutter_tts`, `flutter_riverpod`, `go_router`, `shared_preferences`, `path_provider`, `intl` |
| `android/app/src/main/AndroidManifest.xml` | Modify | Add `CAMERA`, `RECORD_AUDIO` permissions + queries block |
| `ios/Runner/Info.plist` | Modify | Add `NSCameraUsageDescription`, `NSMicrophoneUsageDescription` |
| `test/` | Create | Unit tests for repositories; widget tests for screens |

## Interfaces / Contracts

```dart
// Domain model
class RecognizedWord {
  final String enLabel;
  final String esLabel;
  final double confidence;
  final String photoPath;
  final DateTime timestamp;
}

// Repository contracts
abstract class MlKitRepository {
  Future<List<Label>> labelImage(String path);
}

abstract class LabelMapRepository {
  String? translate(String enLabel);
}

abstract class FlashcardRepository {
  Future<void> save(RecognizedWord word);
  Future<List<RecognizedWord>> loadAll();
  Future<bool> exists(String enLabel);
  Future<void> remove(String enLabel);
}

abstract class HistoryRepository {
  Future<void> log(RecognizedWord word);
  Future<List<RecognizedWord>> loadAll();
  Future<List<RecognizedWord>> search(String query);
}
```

## Testing Strategy

| Layer | What to Test | Approach |
|-------|-------------|----------|
| Unit | `LabelMapRepository.translate`, `FlashcardRepository.save/load`, `HistoryRepository.dedup` | Pure Dart tests with in-memory shared_prefs mock |
| Widget | `CameraScreen` permission states, `ResultScreen` tap-to-speak, `FlashcardListScreen` flip | `WidgetTester` + mocked Riverpod providers |
| Integration | End-to-end scan-to-favorite flow | **Not in scope** (no integration test infra yet) |

## Migration / Rollout

No migration required — greenfield project. Rollback is a single git revert. Each feature is isolated in its folder, enabling partial reverts.

## Resolved Questions

- [x] ~~Do we need `freezed` + `json_serializable` for immutability?~~ → **Manual classes**. Only 3-4 models, not worth adding build_runner. Revisit if models scale in v2.
- [x] ~~Should the EN→ES JSON mapping be loaded eagerly or lazily?~~ → **Eagerly at startup**. 20KB JSON is instant to parse; avoids latency on first scan which would feel broken for kids.
