import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/services/tts_service.dart';

class TtsPlayNotifier extends StateNotifier<String?> {
  final TtsService _ttsService;

  TtsPlayNotifier(this._ttsService) : super(null);

  Future<void> speak(String text, String locale) async {
    if (state == locale) return;
    state = locale;
    try {
      await _ttsService.speak(text, locale);
      await Future.delayed(const Duration(milliseconds: 500));
    } finally {
      if (state == locale) {
        state = null;
      }
    }
  }
}

final ttsPlayNotifierProvider =
    StateNotifierProvider<TtsPlayNotifier, String?>((ref) {
  final tts = ref.watch(ttsServiceProvider);
  return TtsPlayNotifier(tts);
});
