import 'package:shared_preferences/shared_preferences.dart';

/// Service responsible for persisting and retrieving Swarm-related settings.
/// Currently supports a single setting: max specialists to execute per swarm run.
class SwarmSettingsService {
  static const String _keyMaxSpecialists = 'swarm:max_specialists';
  static const int _defaultMaxSpecialists = 3; // sensible cost-control default
  static const int _min = 1;
  static const int _max = 10;

  /// Clamp a value into the allowed range [1, 10].
  int _clamp(int value) => value < _min ? _min : (value > _max ? _max : value);

  /// Returns the persisted max specialists value or the default if not set.
  Future<int> getMaxSpecialists() async {
    final prefs = await SharedPreferences.getInstance();
    final value = prefs.getInt(_keyMaxSpecialists);
    if (value == null) return _defaultMaxSpecialists;
    return _clamp(value);
  }

  /// Persists the max specialists value (clamped to allowed range).
  Future<void> setMaxSpecialists(int value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_keyMaxSpecialists, _clamp(value));
  }

  /// Resets the value back to default.
  Future<void> reset() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyMaxSpecialists);
  }
}
