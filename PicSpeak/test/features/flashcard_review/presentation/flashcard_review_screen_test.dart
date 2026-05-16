import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:picspeak/core/services/tts_service.dart';
import 'package:picspeak/features/app_settings/data/settings_providers.dart';
import 'package:picspeak/features/app_settings/domain/app_settings.dart';
import 'package:picspeak/features/flashcard_review/data/flashcard_providers.dart';
import 'package:picspeak/features/flashcard_review/domain/flashcard_repository.dart';
import 'package:picspeak/features/flashcard_review/presentation/flashcard_review_screen.dart';
import 'package:picspeak/features/object_recognition/domain/recognized_word.dart';
import 'package:picspeak/features/object_recognition/presentation/tts_play_notifier.dart';

class _MockTtsService implements TtsService {
  @override
  Future<bool> isLanguageAvailable(String locale) async => true;

  @override
  Future<void> setSpeed(double speed) async {}

  @override
  Future<void> speak(String text, String locale) async {}

  @override
  Future<void> stop() async {}
}

class _MockFlashcardRepository implements FlashcardRepository {
  final List<RecognizedWord> _cards;

  _MockFlashcardRepository(this._cards);

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
}

void main() {
  group('FlashcardReviewScreen', () {
    late List<RecognizedWord> testCards;
    late _MockFlashcardRepository mockRepo;
    late _MockTtsService mockTts;

    setUp(() {
      testCards = [
        RecognizedWord(
          enLabel: 'dog',
          esLabel: 'perro',
          confidence: 0.95,
          photoPath: '/fake/path1.jpg',
          timestamp: DateTime(2024, 1, 1),
        ),
        RecognizedWord(
          enLabel: 'cat',
          esLabel: 'gato',
          confidence: 0.88,
          photoPath: '/fake/path2.jpg',
          timestamp: DateTime(2024, 1, 1),
        ),
      ];
      mockRepo = _MockFlashcardRepository(testCards);
      mockTts = _MockTtsService();
    });

    Widget buildTestWidget({int initialIndex = 0}) {
      return ProviderScope(
        overrides: [
          flashcardRepositoryProvider.overrideWithValue(mockRepo),
          ttsServiceProvider.overrideWithValue(mockTts),
          ttsPlayNotifierProvider.overrideWith((ref) {
            return TtsPlayNotifier(mockTts);
          }),
          settingsProvider.overrideWith(
            (ref) => Stream.value(const AppSettings(locale: 'en')),
          ),
        ],
        child: MaterialApp(
          home: FlashcardReviewScreen(initialIndex: initialIndex),
        ),
      );
    }

    testWidgets('shows front side (EN label) in initial state',
        (WidgetTester tester) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      expect(find.text('dog'), findsOneWidget);
      expect(find.text('perro'), findsNothing);
    });

    testWidgets('when locale is es, shows front side (ES label) in initial state',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            flashcardRepositoryProvider.overrideWithValue(mockRepo),
            ttsServiceProvider.overrideWithValue(mockTts),
            ttsPlayNotifierProvider.overrideWith((ref) {
              return TtsPlayNotifier(mockTts);
            }),
            settingsProvider.overrideWith(
              (ref) => Stream.value(const AppSettings(locale: 'es')),
            ),
          ],
          child: const MaterialApp(
            home: FlashcardReviewScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('perro'), findsOneWidget);
      expect(find.text('dog'), findsNothing);
    });

    testWidgets('tap triggers flip and shows back side (ES label)',
        (WidgetTester tester) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      expect(find.text('dog'), findsOneWidget);
      expect(find.text('perro'), findsNothing);

      await tester.tap(find.byType(GestureDetector).first);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.text('perro'), findsOneWidget);
    });

    testWidgets('progress indicator shows correct count at index 0',
        (WidgetTester tester) async {
      await tester.pumpWidget(buildTestWidget(initialIndex: 0));
      await tester.pumpAndSettle();

      expect(find.text('1 de 2'), findsOneWidget);
    });

    testWidgets('progress indicator shows correct count at index 1',
        (WidgetTester tester) async {
      await tester.pumpWidget(buildTestWidget(initialIndex: 1));
      await tester.pumpAndSettle();

      expect(find.text('2 de 2'), findsOneWidget);
    });

    testWidgets('swipe gesture navigates to next card',
        (WidgetTester tester) async {
      await tester.pumpWidget(buildTestWidget(initialIndex: 0));
      await tester.pumpAndSettle();

      expect(find.text('dog'), findsOneWidget);

      await tester.fling(
        find.byType(GestureDetector).first,
        const Offset(-300, 0),
        1000,
      );
      await tester.pumpAndSettle();

      expect(find.text('cat'), findsOneWidget);
    });

testWidgets('on last card, next button advances to completion view',
        (WidgetTester tester) async {
      await tester.pumpWidget(buildTestWidget(initialIndex: 1));
      await tester.pumpAndSettle();

      expect(find.text('cat'), findsOneWidget);

      // Tap forward arrow to go to completion
      final forwardButton = find.widgetWithIcon(IconButton, Icons.arrow_forward_ios);
      expect(forwardButton, findsOneWidget);
      await tester.tap(forwardButton);
      await tester.pumpAndSettle();

      // Should show completion view
      expect(find.text('¡Review completado!'), findsOneWidget);
    });
  });
}
