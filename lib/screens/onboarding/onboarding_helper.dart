import 'package:shared_preferences/shared_preferences.dart';

class OnboardingHelper {
  static const String _onboardingCompleteKey = 'onboardingComplete';
  
  // Verificar se o onboarding já foi mostrado
  static Future<bool> isOnboardingComplete() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_onboardingCompleteKey) ?? false;
  }
  
  // Marcar que o onboarding foi concluído
  static Future<void> setOnboardingComplete() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_onboardingCompleteKey, true);
  }
  
  // Resetar o estado do onboarding (útil para testes)
  static Future<void> resetOnboardingState() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_onboardingCompleteKey, false);
  }
}
