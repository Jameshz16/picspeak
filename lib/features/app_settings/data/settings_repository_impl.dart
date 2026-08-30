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

  /// Reads a user-scoped key with a one-time migration from the legacy
  /// unscoped key. Once migrated the legacy key is removed so a future
  /// different user on the same device never sees the previous user's data.
  String? _getWithLegacy(String base) {
    final scoped = _prefs.getString(_key(base));
    if (scoped != null) return scoped;
    if (currentUserId.isEmpty) return null;
    final legacy = _prefs.getString(base);
    if (legacy != null) {
      _prefs.setString(_key(base), legacy);
      _prefs.remove(base);
      return legacy;
    }
    return null;
  }

  @override
  Future<AppSettings> load() async {
    final jsonString = _getWithLegacy('app_settings');
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
