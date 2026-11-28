import 'package:shared_preferences/shared_preferences.dart';

class ComparisonPreferencesService {
  ComparisonPreferencesService({SharedPreferencesAsync? preferences})
    : _preferences = preferences ?? SharedPreferencesAsync();

  final SharedPreferencesAsync _preferences;

  static const String _storageKey = 'restaurant_comparison_selection';

  Future<void> saveSelection(String? firstId, String? secondId) async {
    if (firstId == null && secondId == null) {
      await clearSelection();
      return;
    }

    await _preferences.setStringList(_storageKey, [
      firstId ?? '',
      secondId ?? '',
    ]);
  }

  Future<({String? firstId, String? secondId})> loadSelection() async {
    final saved = await _preferences.getStringList(_storageKey);

    if (saved == null || saved.length != 2) {
      return (firstId: null, secondId: null);
    }

    final firstId = saved[0].isEmpty ? null : saved[0];
    final secondId = saved[1].isEmpty ? null : saved[1];

    return (firstId: firstId, secondId: firstId == secondId ? null : secondId);
  }

  Future<void> clearSelection() async {
    await _preferences.remove(_storageKey);
  }
}
