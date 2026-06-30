/// Helper untuk judul RPG berdasarkan rank dan level.
/// Dipakai di AppBar, HeroCard, dan ProfileScreen secara konsisten.
class RPGTitleHelper {
  RPGTitleHelper._();

  /// Judul RPG berdasarkan rank (sesuai desain Stitch)
  static String title(String rank) => switch (rank) {
        'Bronze'  => 'Penjelajah',
        'Silver'  => 'Ksatria',
        'Gold'    => 'Paladin',
        'Diamond' => 'Guardian',
        'Spartan' => 'Spartan',
        _         => 'Petualang',
      };

  /// Format lengkap: "Lvl. 24 Paladin"
  static String fullTitle(int level, String rank) =>
      'Lvl. $level ${title(rank)}';

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
