import 'package:shared_preferences/shared_preferences.dart';

/// Speichert Lernfortschritt lokal auf dem Gerät (Android + iOS).
class ProgressStorage {
  static const _knownKey = 'known_ids_v1';
  static const _bestQuizKey = 'best_quiz_v1';
  static const _xpKey = 'xp_v1';
  static const _streakKey = 'streak_v1'; // Format: "anzahl|jahr-monat-tag"

  static Future<Set<String>> loadKnown() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getStringList(_knownKey)?.toSet() ?? <String>{};
  }

  static Future<void> saveKnown(Set<String> ids) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_knownKey, ids.toList());
  }

  static Future<int> loadBestQuiz() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_bestQuizKey) ?? 0;
  }

  static Future<void> saveBestQuiz(int score) async {
    final prefs = await SharedPreferences.getInstance();
    final old = prefs.getInt(_bestQuizKey) ?? 0;
    if (score > old) await prefs.setInt(_bestQuizKey, score);
  }

  static Future<int> loadXP() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_xpKey) ?? 0;
  }

  static Future<int> loadStreakCount() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_streakKey);
    if (raw == null || !raw.contains('|')) return 0;
    return int.tryParse(raw.split('|').first) ?? 0;
  }

  /// +n XP und Tages-Streak fortschreiben (1x pro Tag).
  static Future<void> addXP(int n) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_xpKey, (prefs.getInt(_xpKey) ?? 0) + n);
    final now = DateTime.now();
    final today = '${now.year}-${now.month}-${now.day}';
    int count = 0;
    String last = '';
    final raw = prefs.getString(_streakKey);
    if (raw != null && raw.contains('|')) {
      final parts = raw.split('|');
      count = int.tryParse(parts.first) ?? 0;
      last = parts.last;
    }
    if (last != today) {
      final y = now.subtract(const Duration(days: 1));
      final yesterday = '${y.year}-${y.month}-${y.day}';
      count = (last == yesterday) ? count + 1 : 1;
      await prefs.setString(_streakKey, '$count|$today');
    }
  }

  static Future<void> reset() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_knownKey);
    await prefs.remove(_bestQuizKey);
    await prefs.remove(_xpKey);
    await prefs.remove(_streakKey);
  }
}
