import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:picspeak/core/services/tts_service.dart';
import 'package:picspeak/features/flashcard_review/data/flashcard_providers.dart';
import 'package:picspeak/features/flashcard_review/domain/flashcard_repository.dart';
import 'package:picspeak/features/object_recognition/domain/recognized_word.dart';
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
          flashcardRepositoryProvider.overrideWithValue(mockFlashcardRepo),
          historyRepositoryProvider.overrideWithValue(mockHistoryRepo),
          ttsPlayNotifierProvider.overrideWith((ref) {
            return TtsPlayNotifier(mockTts);
          }),
        ],
        child: MaterialApp.router(
          routerConfig: router,
        ),
      );
    }

    testWidgets('renders bilingual card with EN and ES labels',
        (WidgetTester tester) async {
      await tester.pumpWidget(buildTestWidget());
      router.go('/result', extra: {'word': testWord});
      await tester.pumpAndSettle();

      expect(find.text('dog'), findsOneWidget);
      expect(find.text('perro'), findsOneWidget);
      expect(find.textContaining('95.0%'), findsOneWidget);
    });

    testWidgets('favorite button toggles and shows saved state',
        (WidgetTester tester) async {
      await tester.pumpWidget(buildTestWidget());
      router.go('/result', extra: {'word': testWord});
      await tester.pumpAndSettle();

      expect(find.text('Add to favorites'), findsOneWidget);

      await tester.ensureVisible(find.text('Add to favorites'));
      await tester.tap(find.text('Add to favorites'));
      await tester.pumpAndSettle();

      expect(find.text('Saved to favorites'), findsOneWidget);
    });

    testWidgets('TTS buttons trigger speak with correct locale',
        (WidgetTester tester) async {
      await tester.pumpWidget(buildTestWidget());
      router.go('/result', extra: {'word': testWord});
      await tester.pumpAndSettle();

      await tester.ensureVisible(find.text('Escuchar en inglés'));
      await tester.tap(find.text('Escuchar en inglés'));
      await tester.pumpAndSettle();

      expect(mockTts.lastSpokenText, equals('dog'));
      expect(mockTts.lastLocale, equals('en-US'));
    });
  });
}
