import 'package:shared_preferences/shared_preferences.dart';

class OnboardingStore {
  OnboardingStore({SharedPreferencesAsync? preferences})
    : _preferences = preferences ?? SharedPreferencesAsync();

  static const String _key = 'onboarding_completed';

  final SharedPreferencesAsync _preferences;

  Future<bool> isCompleted() async => await _preferences.getBool(_key) ?? false;

  Future<void> setCompleted(bool completed) =>
      _preferences.setBool(_key, completed);
}
