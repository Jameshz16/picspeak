import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/services/speech_recognition_service.dart';
import '../domain/pronunciation_judge.dart';

/// Phase of the active (or last) pronunciation attempt.
enum PronunciationPhase { idle, listening, judging, success, failure }

/// Immutable snapshot of a pronunciation attempt.
class PronunciationState {
  final PronunciationPhase phase;
  final PronunciationVerdict? verdict;
  final String? recognizedText;
  final String? error;

  const PronunciationState({
    this.phase = PronunciationPhase.idle,
    this.verdict,
    this.recognizedText,
    this.error,
  });

  PronunciationState copyWith({
    PronunciationPhase? phase,
    PronunciationVerdict? verdict,
    String? recognizedText,
    String? error,
  }) {
    return PronunciationState(
      phase: phase ?? this.phase,
      verdict: verdict ?? this.verdict,
      recognizedText: recognizedText ?? this.recognizedText,
      error: error ?? this.error,
    );
  }
}

/// Drives a single "pronounce the word" attempt: starts the listening
/// session, collects the recognized text and grades it with the
/// [PronunciationJudge], then exposes the outcome to the UI.
class PronunciationNotifier extends StateNotifier<PronunciationState> {
  final SpeechRecognitionService _speechService;
  final PronunciationJudge _judge;

  String _expected = '';
  String? _lastRecognized;
  double? _lastConfidence;

  PronunciationNotifier(this._speechService, this._judge)
      : super(const PronunciationState());

  /// Starts a new listening session for [expected].
  ///
  /// No-op while a session is already running or being judged.
  Future<void> start({required String expected}) async {
    if (state.phase == PronunciationPhase.listening ||
        state.phase == PronunciationPhase.judging) {
      return;
    }
    _expected = expected;
    _lastRecognized = null;
    _lastConfidence = null;
    state = const PronunciationState(phase: PronunciationPhase.listening);

    var available = false;
    try {
      available = await _speechService.initialize();
    } catch (_) {
      // Swallow: `available` stays false and the attempt fails cleanly.
    }
    if (!available) {
      state = const PronunciationState(
        phase: PronunciationPhase.failure,
        error: speechRecognitionUnavailableMessage,
      );
      return;
    }

    try {
      await _speechService.listen(
        onResult: _onPartialResult,
        onDone: _evaluate,
        onError: _onError,
      );
    } catch (_) {
      state = PronunciationState(
        phase: PronunciationPhase.failure,
        error: 'No se pudo iniciar la escucha',
        recognizedText: _lastRecognized,
      );
    }
  }

  /// Retries the last attempt (or starts fresh) from any settled phase.
  Future<void> retry({required String expected}) async {
    await reset();
    await start(expected: expected);
  }

  /// Returns to the idle phase and stops any active listening session.
  Future<void> reset() async {
    await _speechService.stop();
    _lastRecognized = null;
    _lastConfidence = null;
    state = const PronunciationState();
  }

  void _onPartialResult(String recognized, double? confidence) {
    _lastRecognized = recognized;
    _lastConfidence = confidence;
    state = state.copyWith(recognizedText: recognized);
  }

  void _onError(String message) {
    state = PronunciationState(
      phase: PronunciationPhase.failure,
      error: message,
      recognizedText: _lastRecognized,
    );
  }

  void _evaluate() {
    final recognized = _lastRecognized ?? '';
    state = PronunciationState(
      phase: PronunciationPhase.judging,
      recognizedText: recognized,
    );

    final verdict = _judge.judge(
      expected: _expected,
      recognized: recognized,
      confidence: _lastConfidence,
    );

    // excellent, good and needsWork are all "evaluated" outcomes that
    // land in the success phase with their own message; noSpeech and
    // errors land in the failure phase.
    final phase = verdict == PronunciationVerdict.noSpeech
        ? PronunciationPhase.failure
        : PronunciationPhase.success;

    state = PronunciationState(
      phase: phase,
      verdict: verdict,
      recognizedText: recognized,
    );
  }

  @override
  void dispose() {
    _speechService.stop();
    super.dispose();
  }
}

final pronunciationNotifierProvider =
    StateNotifierProvider<PronunciationNotifier, PronunciationState>((ref) {
  final speechService = ref.watch(speechRecognitionServiceProvider);
  return PronunciationNotifier(speechService, const PronunciationJudge());
});
