import 'package:shared_preferences/shared_preferences.dart';

class OnboardingHelper {
  static const String _onboardingCompleteKey = 'onboardingComplete';

  static Future<bool> isOnboardingComplete() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getBool(_onboardingCompleteKey) ?? false;
    } catch (e) {
      return false;
    }
  }

  static Future<void> setOnboardingComplete() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_onboardingCompleteKey, true);
    } catch (e) {
      // Handle error silently or log it
    }
  }
}