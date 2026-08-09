import 'dart:async';
import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../../../../core/utils/current_user.dart';
import '../domain/app_settings.dart';
import '../domain/settings_repository.dart';

class SettingsRepositoryImpl implements SettingsRepository {
  final SharedPreferences _prefs;
  final _controller = StreamController<AppSettings>.broadcast();

  SettingsRepositoryImpl(this._prefs);

  String _key(String base) =>
      currentUserId.isEmpty ? base : '${currentUserId}_$base';

  @override
  Future<AppSettings> load() async {
    final jsonString = _prefs.getString(_key('app_settings'));
    if (jsonString == null) {
      return const AppSettings();
    }
    final json = jsonDecode(jsonString) as Map<String, dynamic>;
    return AppSettings.fromJson(json);
  }

  @override
  Future<void> save(AppSettings settings) async {
    final jsonString = jsonEncode(settings.toJson());
    await _prefs.setString(_key('app_settings'), jsonString);
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
