import 'dart:async';
import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../domain/app_settings.dart';
import '../domain/settings_repository.dart';

class SettingsRepositoryImpl implements SettingsRepository {
  static const _key = 'app_settings';
  final SharedPreferences _prefs;
  final _controller = StreamController<AppSettings>.broadcast();

  SettingsRepositoryImpl(this._prefs);

  @override
  Future<AppSettings> load() async {
    final jsonString = _prefs.getString(_key);
    if (jsonString == null) {
      return const AppSettings();
    }
    final json = jsonDecode(jsonString) as Map<String, dynamic>;
    return AppSettings.fromJson(json);
  }

  @override
  Future<void> save(AppSettings settings) async {
    final jsonString = jsonEncode(settings.toJson());
    await _prefs.setString(_key, jsonString);
    _controller.add(settings);
  }

  @override
  Stream<AppSettings> watch() async* {
    yield await load();
    yield* _controller.stream;
  }

  void dispose() {
    _controller.close();
  }
}
