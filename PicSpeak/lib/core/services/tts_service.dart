import 'package:flutter_tts/flutter_tts.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

abstract class TtsService {
  Future<void> speak(String text, String locale);
  Future<void> setSpeed(double speed);
  Future<bool> isLanguageAvailable(String locale);
  Future<void> stop();
}

class TtsServiceImpl implements TtsService {
  final FlutterTts _flutterTts;

  TtsServiceImpl({FlutterTts? flutterTts})
      : _flutterTts = flutterTts ?? FlutterTts();

  Future<void> initialize() async {
    await _flutterTts.setLanguage('en-US');
    await _flutterTts.setSpeechRate(1.0);
    await _flutterTts.setVolume(1.0);
    await _flutterTts.setPitch(1.0);
  }

  @override
  Future<void> speak(String text, String locale) async {
    final available = await isLanguageAvailable(locale);
    if (!available) {
      // ignore: avoid_print
      print('TTS language not available: $locale');
      return;
    }
    await _flutterTts.setLanguage(locale);
    await _flutterTts.speak(text);
  }

  @override
  Future<void> setSpeed(double speed) async {
    await _flutterTts.setSpeechRate(speed);
  }

  @override
  Future<bool> isLanguageAvailable(String locale) async {
    final languages = await _flutterTts.getLanguages;
    if (languages is List) {
      return languages.contains(locale);
    }
    return false;
  }

  @override
  Future<void> stop() async {
    await _flutterTts.stop();
  }
}

final ttsServiceProvider = Provider<TtsService>((ref) {
  final service = TtsServiceImpl();
  service.initialize();
  return service;
});
