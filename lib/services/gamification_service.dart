import '../utils/prefs_service.dart';

class GamificationService {
  // Daftar Rank beserta threshold XP-nya
  static const Map<String, int> rankThresholds = {
    'Bronze': 0,
    'Silver': 500,
    'Gold': 1500,
    'Diamond': 3000,
    'Spartan': 5000,
  };

  // 1. Dapatkan XP saat ini
  Future<int> getCurrentXP() async {
    return PrefsService.i.userXP;
  }

  // 2. Tambah XP
  Future<Map<String, dynamic>> addXP(int amount) async {
    final p = PrefsService.i;
    int currentXP = p.userXP;
    String oldRank = getCurrentRank(currentXP);

    currentXP += amount;
    await p.setUserXP(currentXP);

    String newRank = getCurrentRank(currentXP);
    bool leveledUp = newRank != oldRank;

    if (leveledUp) {
      await p.setUserLevel(newRank);
    }

    return {
      'new_xp': currentXP,
      'old_rank': oldRank,
      'new_rank': newRank,
      'leveled_up': leveledUp,
    };
  }

  // 3. Tentukan Rank berdasarkan XP
  String getCurrentRank(int xp) {
    if (xp >= rankThresholds['Spartan']!) return 'Spartan';
    if (xp >= rankThresholds['Diamond']!) return 'Diamond';
    if (xp >= rankThresholds['Gold']!) return 'Gold';
    if (xp >= rankThresholds['Silver']!) return 'Silver';
    return 'Bronze';
  }

  // 4. Hitung batas bawah dan atas XP untuk Rank saat ini
  Map<String, int> getRankProgress(int currentXP) {
    String currentRank = getCurrentRank(currentXP);
    int minXP = rankThresholds[currentRank]!;
    int maxXP;

    switch (currentRank) {
      case 'Bronze':   maxXP = rankThresholds['Silver']!;  break;
      case 'Silver':   maxXP = rankThresholds['Gold']!;    break;
      case 'Gold':     maxXP = rankThresholds['Diamond']!; break;
      case 'Diamond':  maxXP = rankThresholds['Spartan']!; break;
      case 'Spartan':  maxXP = currentXP;                  break;
      default:         maxXP = 500;
    }

    return {'min_xp': minXP, 'max_xp': maxXP, 'current_xp': currentXP};
  }

  // 5. Tentukan Rarity Makanan berdasarkan rasio protein & kalori
  static String determineFoodRarity(double calories, double protein) {
    if (calories <= 0) return 'Common';
    double ratio = (protein * 4) / calories;
    if (ratio > 0.6)  return 'Legendary';
    if (ratio > 0.3)  return 'Epic';
    if (ratio > 0.15) return 'Rare';
    return 'Common';
  }

  // 6. Hitung Level berdasarkan XP (1 Level = 150 XP)
  static int getCurrentLevel(int xp) => (xp / 150).floor() + 1;

  // 7. getUserStats
  Future<Map<String, dynamic>> getUserStats() async {
    final xp = PrefsService.i.userXP;
    return {'xp': xp, 'rank': getCurrentRank(xp)};
  }
}
