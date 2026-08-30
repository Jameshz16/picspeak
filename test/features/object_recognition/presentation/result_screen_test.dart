import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:picspeak/core/services/speech_recognition_service.dart';
import 'package:picspeak/core/services/tts_service.dart';
import 'package:picspeak/features/flashcard_review/data/flashcard_providers.dart';
import 'package:picspeak/features/flashcard_review/domain/flashcard_repository.dart';
import 'package:picspeak/features/object_recognition/domain/pronunciation_judge.dart';
import 'package:picspeak/features/object_recognition/domain/recognized_word.dart';
import 'package:picspeak/features/object_recognition/presentation/pronunciation_notifier.dart';
import 'package:picspeak/features/object_recognition/presentation/result_screen.dart';
import 'package:picspeak/features/object_recognition/presentation/tts_play_notifier.dart';
import 'package:picspeak/features/word_history/data/history_providers.dart';
import 'package:picspeak/features/word_history/domain/history_repository.dart';

class _MockTtsService implements TtsService {
  String? lastSpokenText;
  String? lastLocale;

  @override
  Future<bool> isLanguageAvailable(String locale) async => true;

  @override
  Future<void> setSpeed(double speed) async {}

  @override
  Future<void> speak(String text, String locale) async {
    lastSpokenText = text;
    lastLocale = locale;
  }

  @override
  Future<void> stop() async {}
}

class _MockSpeechRecognitionService implements SpeechRecognitionService {
  @override
  bool isListening = false;

  @override
  Future<bool> initialize() async => true;

  @override
  Future<void> listen({
    required void Function(String recognizedText, double? confidence) onResult,
    required void Function() onDone,
    required void Function(String error) onError,
  }) async {
    isListening = true;
  }

  @override
  Future<void> stop() async {
    isListening = false;
  }

  @override
  bool get isAvailable => true;
}

class _MockFlashcardRepository implements FlashcardRepository {
  final List<RecognizedWord> _cards = [];

  @override
  Future<bool> exists(String enLabel) async {
    return _cards.any((c) => c.enLabel == enLabel);
  }

  @override
  Future<List<RecognizedWord>> loadAll() async => _cards;

  @override
  Future<void> remove(String enLabel) async {
    _cards.removeWhere((c) => c.enLabel == enLabel);
  }

  @override
  Future<void> save(RecognizedWord word) async {
    if (!await exists(word.enLabel)) {
      _cards.add(word);
    }
  }

  @override
  Future<List<RecognizedWord>> getDueCards() async => _cards;

  @override
  Future<void> updateSrs({
    required String enLabel,
    required int interval,
    required double easeFactor,
    required DateTime nextReview,
  }) async {}

  @override
  Future<int> getDueCount() async => _cards.length;
}

class _MockHistoryRepository implements HistoryRepository {
  final List<RecognizedWord> _entries = [];

  @override
  Future<void> log(RecognizedWord word) async {
    _entries.add(word);
  }

  @override
  Future<List<RecognizedWord>> loadAll() async => _entries;

  @override
  Future<List<RecognizedWord>> search(String query) async => [];
}

void main() {
  group('ResultScreen', () {
    late RecognizedWord testWord;
    late _MockTtsService mockTts;
    late _MockSpeechRecognitionService mockSpeech;
    late _MockFlashcardRepository mockFlashcardRepo;
    late _MockHistoryRepository mockHistoryRepo;
    late GoRouter router;

    setUp(() {
      testWord = RecognizedWord(
        enLabel: 'dog',
        esLabel: 'perro',
        confidence: 0.95,
        photoPath: '/fake/path.jpg',
        timestamp: DateTime(2024, 1, 1),
      );
      mockTts = _MockTtsService();
      mockSpeech = _MockSpeechRecognitionService();
      mockFlashcardRepo = _MockFlashcardRepository();
      mockHistoryRepo = _MockHistoryRepository();
    });

    Widget buildTestWidget({String initialRoute = '/result'}) {
      router = GoRouter(
        initialLocation: initialRoute,
        routes: [
          GoRoute(
            path: '/',
            builder: (_, __) => const Scaffold(body: Text('Home')),
          ),
          GoRoute(
            path: '/result',
            builder: (_, state) {
              final extra = state.extra as Map<String, dynamic>? ?? {};
              final word = extra['word'] as RecognizedWord?;
              if (word == null) {
                return const Scaffold(
                  body: Center(child: Text('No word')),
                );
              }
              return ResultScreen(
                word: word,
                allLabels: const [],
              );
            },
          ),
        ],
      );

      return ProviderScope(
        overrides: [
          ttsServiceProvider.overrideWithValue(mockTts),
          speechRecognitionServiceProvider.overrideWithValue(mockSpeech),
          flashcardRepositoryProvider.overrideWithValue(mockFlashcardRepo),
          historyRepositoryProvider.overrideWithValue(mockHistoryRepo),
          ttsPlayNotifierProvider.overrideWith((ref) {
            return TtsPlayNotifier(mockTts);
          }),
          pronunciationNotifierProvider.overrideWith((ref) {
            return PronunciationNotifier(mockSpeech, const PronunciationJudge());
          }),
        ],
        child: MaterialApp.router(
          routerConfig: router,
        ),
      );
    }

    /// Navigates to the result screen and pumps through the finite
    /// animations (route transition, typewriter, fade-in). pumpAndSettle
    /// cannot be used here because ScanLineOverlay and FloatingLabel run
    /// infinite repeating animations.
    Future<void> pumpResultScreen(WidgetTester tester) async {
      router.go('/result', extra: {'word': testWord});
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      await tester.pump(const Duration(milliseconds: 200));
      await tester.pump(const Duration(milliseconds: 250));
    }

    testWidgets('renders bilingual card with EN and ES labels',
        (WidgetTester tester) async {
      await tester.pumpWidget(buildTestWidget());
      await pumpResultScreen(tester);

      expect(find.text('dog'), findsOneWidget);
      expect(find.text('perro'), findsOneWidget);
      expect(find.textContaining('95%'), findsOneWidget);
    });

    testWidgets('favorite button toggles and shows saved state',
        (WidgetTester tester) async {
      await tester.pumpWidget(buildTestWidget());
      await pumpResultScreen(tester);

      expect(find.text('Guardar como favorito'), findsOneWidget);

      await tester.ensureVisible(find.text('Guardar como favorito'));
      await tester.tap(find.text('Guardar como favorito'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('Guardado'), findsOneWidget);

      // Let the snackbar timer expire so no timer is pending at teardown.
      await tester.pump(const Duration(seconds: 5));
      await tester.pump(const Duration(milliseconds: 300));
    });

    testWidgets('TTS buttons trigger speak with correct locale',
        (WidgetTester tester) async {
      await tester.pumpWidget(buildTestWidget());
      await pumpResultScreen(tester);

      await tester.ensureVisible(find.text('Escuchar en inglés'));
      await tester.tap(find.text('Escuchar en inglés'));
      // TtsPlayNotifier defers state reset by 500ms; flush it.
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 600));

      expect(mockTts.lastSpokenText, equals('dog'));
      expect(mockTts.lastLocale, equals('en-US'));
    });

    testWidgets('pronunciation button starts listening on tap',
        (WidgetTester tester) async {
      await tester.pumpWidget(buildTestWidget());
      await pumpResultScreen(tester);

      expect(find.text('Probá tu pronunciación'), findsOneWidget);

      await tester.ensureVisible(find.text('Probá tu pronunciación'));
      await tester.tap(find.text('Probá tu pronunciación'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('Escuchando...'), findsOneWidget);
      expect(mockSpeech.isListening, isTrue);
    });
  });
}
