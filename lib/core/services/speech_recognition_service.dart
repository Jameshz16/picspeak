import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:speech_to_text/speech_recognition_error.dart';
import 'package:speech_to_text/speech_to_text.dart';

/// User-facing message shown when speech recognition cannot run.
const String speechRecognitionUnavailableMessage =
    'El reconocimiento de voz no está disponible en este dispositivo';

abstract class SpeechRecognitionService {
  /// Prepares the platform speech recognition service (and requests
  /// microphone permission if needed). Returns true when ready to listen.
  Future<bool> initialize();

  /// Starts a listening session in English (en-US).
  ///
  /// [onResult] is invoked with each recognized fragment (partial and
  /// final). [confidence] is null when the platform does not provide a
  /// confidence rating. [onDone] fires once when the final result has
  /// been delivered. [onError] fires with a user-facing message when
  /// the session fails.
  Future<void> listen({
    required void Function(String recognizedText, double? confidence) onResult,
    required void Function() onDone,
    required void Function(String error) onError,
  });

  /// Stops the current listening session, if any.
  Future<void> stop();

  bool get isListening;

  /// True once [initialize] has succeeded.
  bool get isAvailable;
}

class SpeechRecognitionServiceImpl implements SpeechRecognitionService {
  final SpeechToText _speechToText;
  bool _initialized = false;
  bool _initializing = false;
  void Function(String message)? _activeListenError;

  SpeechRecognitionServiceImpl({SpeechToText? speechToText})
      : _speechToText = speechToText ?? SpeechToText();

  @override
  bool get isListening => _speechToText.isListening;

  @override
  bool get isAvailable => _initialized;

  @override
  Future<bool> initialize() async {
    if (_initialized) return true;
    if (_initializing) return false;
    _initializing = true;
    try {
      // The plugin routes errors that happen during initialization and
      // during listening sessions through this same callback.
      _initialized = await _speechToText.initialize(onError: _handleError);
      return _initialized;
    } catch (_) {
      _initialized = false;
      return false;
    } finally {
      _initializing = false;
    }
  }

  @override
  Future<void> listen({
    required void Function(String recognizedText, double? confidence) onResult,
    required void Function() onDone,
    required void Function(String error) onError,
  }) async {
    if (!_initialized) {
      final ready = await initialize();
      if (!ready) {
        onError(speechRecognitionUnavailableMessage);
        return;
      }
    }
    _activeListenError = onError;
    try {
      await _speechToText.listen(
        onResult: (result) {
          onResult(
            result.recognizedWords,
            result.hasConfidenceRating ? result.confidence : null,
          );
          if (result.finalResult) {
            onDone();
          }
        },
        listenOptions: SpeechListenOptions(
          localeId: 'en-US',
          partialResults: true,
          onDevice: true,
        ),
      );
    } on SpeechToTextNotInitializedException {
      onError(speechRecognitionUnavailableMessage);
    } on ListenFailedException {
      onError('No se pudo iniciar la escucha');
    } catch (_) {
      onError('Error inesperado al escuchar');
    } finally {
      _activeListenError = null;
    }
  }

  /// Translates a platform error into a user-facing message and forwards
  /// it to the active listening session (if any).
  void _handleError(SpeechRecognitionError error) {
    final message = error.errorMsg.contains('not_found')
        ? speechRecognitionUnavailableMessage
        : 'Error de reconocimiento de voz';
    _activeListenError?.call(message);
  }

  @override
  Future<void> stop() async {
    await _speechToText.stop();
  }
}

final speechRecognitionServiceProvider = Provider<SpeechRecognitionService>((ref) {
  // Lazy initialization: the platform permission prompt only appears when
  // the user actually taps the pronunciation button (start() calls
  // initialize()), not at app startup.
  return SpeechRecognitionServiceImpl();
});
