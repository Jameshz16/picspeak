import 'package:shared_preferences/shared_preferences.dart';

import 'onboarding_repository.dart';

class OnboardingRepositoryImpl implements OnboardingRepository {
  static const _key = 'onboarding_seen';
  final SharedPreferences _prefs;

  OnboardingRepositoryImpl(this._prefs);

  @override
  Future<bool> hasSeenOnboarding() async {
    return _prefs.getBool(_key) ?? false;
  }

  @override
  Future<void> markOnboardingSeen() async {
    await _prefs.setBool(_key, true);
  }
}
