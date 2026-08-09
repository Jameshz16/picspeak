import 'package:shared_preferences/shared_preferences.dart';

import 'onboarding_repository.dart';

// Onboarding key stays global (per-device, not per-user).
// SharedPreferences key is NOT uid-scoped because onboarding
// should only be shown once per device regardless of user account.
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
