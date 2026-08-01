/// Helper untuk judul RPG berdasarkan rank dan level.
/// Dipakai di AppBar, HeroCard, dan ProfileScreen secara konsisten.
class RPGTitleHelper {
  RPGTitleHelper._();

  /// Judul RPG berdasarkan rank (sesuai desain baru)
  static String title(String rank) => switch (rank) {
        'Bronze'  => 'Rookie',
        'Silver'  => 'Apprentice',
        'Gold'    => 'Warrior',
        'Diamond' => 'Champion',
        'Spartan' => 'Legend',
        _         => 'Petualang',
      };

  /// Format lengkap berdasarkan rank: "Gold Warrior"
  static String fullTitle(int level, String rank) =>
      '$rank ${title(rank)}';

  /// Subtitle screen per konteks (sesuai desain Stitch)
  static String screenSubtitle(String screen) => switch (screen) {
        'food'    => 'ADVENTURE LOG',
        'quest'   => 'SANG PENJELAJAH',
        'rank'    => 'GOLD WARRIOR',
        'apex'    => 'APEX\'S GUILD HALL',
        'profile' => 'HERO PROFILE',
        _         => 'ADVENTURER',
      };

  /// Emoji ikon rank
  static String rankIcon(String rank) => switch (rank) {
        'Bronze'  => '🥉',
        'Silver'  => '🥈',
        'Gold'    => '🥇',
        'Diamond' => '💎',
        'Spartan' => '👑',
        _         => '⭐',
      };
}
