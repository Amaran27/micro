import 'package:shared_preferences/shared_preferences.dart';
import 'package:micro/core/constants.dart';
import 'package:flutter/widgets.dart'; // Import for WidgetsFlutterBinding

void main() async {
  WidgetsFlutterBinding.ensureInitialized(); // Required for SharedPreferences
  final prefs = await SharedPreferences.getInstance();
  final onboardingComplete = prefs.getBool(AppConstants.onboardingCompleteKey) ?? false;
  print('Onboarding Complete: $onboardingComplete');
}