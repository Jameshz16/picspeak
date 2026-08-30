import 'package:flutter_test/flutter_test.dart';
import 'package:picspeak/core/services/speech_recognition_service.dart';
import 'package:picspeak/features/object_recognition/domain/pronunciation_judge.dart';
import 'package:picspeak/features/object_recognition/presentation/pronunciation_notifier.dart';

class _MockSpeechRecognitionService implements SpeechRecognitionService {
  bool initResult = true;
  bool initThrows = false;
  @override
  bool isListening = false;
  @override
  bool isAvailable = false;
  int initCalls = 0;
  int stopCalls = 0;

  void Function(String recognizedText, double? confidence)? onResult;
  void Function()? onDone;
  void Function(String error)? onError;

  @override
  Future<bool> initialize() async {
    initCalls++;
    if (initThrows) throw Exception('init failed');
    isAvailable = initResult;
    return initResult;
  }

  @override
  Future<void> listen({
    required void Function(String recognizedText, double? confidence) onResult,
    required void Function() onDone,
    required void Function(String error) onError,
  }) async {
    this.onResult = onResult;
    this.onDone = onDone;
    this.onError = onError;
    isListening = true;
  }

  @override
  Future<void> stop() async {
    stopCalls++;
    isListening = false;
  }
}

void main() {
  late _MockSpeechRecognitionService mockService;
  late PronunciationNotifier notifier;

  setUp(() {
    mockService = _MockSpeechRecognitionService();
    notifier = PronunciationNotifier(mockService, const PronunciationJudge());
  });

  tearDown(() {
    notifier.dispose();
  });

  group('PronunciationNotifier', () {
    test('starts in idle phase', () {
      expect(notifier.state.phase, PronunciationPhase.idle);
      expect(notifier.state.verdict, isNull);
      expect(notifier.state.error, isNull);
    });

    test('start() transitions idle -> listening and initializes the service',
        () async {
      await notifier.start(expected: 'dog');

      expect(mockService.initCalls, 1);
      expect(mockService.isListening, isTrue);
      expect(notifier.state.phase, PronunciationPhase.listening);
    });

    test('successful attempt with exact match yields excellent verdict',
        () async {
      await notifier.start(expected: 'dog');

      mockService.onResult!('dog', 0.95);
      mockService.onDone!();

      expect(notifier.state.phase, PronunciationPhase.success);
      expect(notifier.state.verdict, PronunciationVerdict.excellent);
      expect(notifier.state.recognizedText, 'dog');
      expect(notifier.state.error, isNull);
    });

    test('partial match with good confidence yields good verdict', () async {
      await notifier.start(expected: 'dog');

      mockService.onResult!('a dog', 0.9);
      mockService.onDone!();

      expect(notifier.state.phase, PronunciationPhase.success);
      expect(notifier.state.verdict, PronunciationVerdict.good);
    });

    test('no speech yields failure phase', () async {
      await notifier.start(expected: 'dog');

      mockService.onResult!('', null);
      mockService.onDone!();

      expect(notifier.state.phase, PronunciationPhase.failure);
      expect(notifier.state.verdict, PronunciationVerdict.noSpeech);
    });

    test('service error yields failure phase with the message', () async {
      await notifier.start(expected: 'dog');

      mockService.onError!('No se pudo iniciar la escucha');

      expect(notifier.state.phase, PronunciationPhase.failure);
      expect(notifier.state.error, 'No se pudo iniciar la escucha');
      expect(notifier.state.verdict, isNull);
    });

    test('initialize failure yields failure with unavailable message',
        () async {
      mockService.initResult = false;

      await notifier.start(expected: 'dog');

      expect(notifier.state.phase, PronunciationPhase.failure);
      expect(
        notifier.state.error,
        'El reconocimiento de voz no está disponible en este dispositivo',
      );
    });

    test('initialize exception is handled gracefully', () async {
      mockService.initThrows = true;

      await notifier.start(expected: 'dog');

      expect(notifier.state.phase, PronunciationPhase.failure);
      expect(notifier.state.error, isNotNull);
    });

    test('start() is a no-op while already listening', () async {
      await notifier.start(expected: 'dog');
      expect(mockService.initCalls, 1);

      await notifier.start(expected: 'dog');

      expect(mockService.initCalls, 1);
      expect(notifier.state.phase, PronunciationPhase.listening);
    });

    test('retry() resets and starts a new session', () async {
      await notifier.start(expected: 'dog');
      mockService.onResult!('', null);
      mockService.onDone!();
      expect(notifier.state.phase, PronunciationPhase.failure);

      await notifier.retry(expected: 'dog');

      expect(notifier.state.phase, PronunciationPhase.listening);
      expect(notifier.state.error, isNull);
      expect(mockService.stopCalls, greaterThanOrEqualTo(1));
    });

    test('reset() returns to idle and stops the service', () async {
      await notifier.start(expected: 'dog');

      await notifier.reset();

      expect(notifier.state.phase, PronunciationPhase.idle);
      expect(notifier.state.recognizedText, isNull);
      expect(mockService.stopCalls, 1);
    });
  });
}
