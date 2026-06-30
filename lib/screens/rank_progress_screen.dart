import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../services/gamification_service.dart';
import '../config/app_colors.dart';
import '../widgets/rpg_app_bar.dart';
import '../widgets/fantasy_rank_badge.dart';
import '../widgets/fantasy_card.dart';

class RankProgressScreen extends StatefulWidget {
  const RankProgressScreen({super.key});

  @override
  State<RankProgressScreen> createState() => _RankProgressScreenState();
}

class _RankProgressScreenState extends State<RankProgressScreen> {
  int _currentXP = 0;
  String _currentRank = 'Bronze';
  String _nextRank = 'Silver';
  int _xpForNextRank = 500;
  double _progress = 0.0;

  static const List<String> _rankOrder = ['Bronze', 'Silver', 'Gold', 'Diamond', 'Spartan'];

  @override
  void initState() {
    super.initState();
    _loadProgress();
  }

  Future<void> _loadProgress() async {
    final stats = await GamificationService().getUserStats();
    final xp = stats['xp'] as int? ?? 0;
    final rank = stats['rank'] as String? ?? 'Bronze';
    final thresholds = GamificationService.rankThresholds;

    int currentRankBaseXP = thresholds[rank] ?? 0;
    int nextRankXP = xp;
    String nextRankName = 'Max Rank';

    final currentIndex = _rankOrder.indexOf(rank);
    if (currentIndex >= 0 && currentIndex < _rankOrder.length - 1) {
      final nextRankKey = _rankOrder[currentIndex + 1];
      nextRankXP = thresholds[nextRankKey] ?? xp;
      nextRankName = nextRankKey;
    }

    double progress = 0.0;
    if (nextRankXP > currentRankBaseXP) {
      progress = (xp - currentRankBaseXP) / (nextRankXP - currentRankBaseXP);
    } else {
      progress = 1.0;
    }

    setState(() {
      _currentXP = xp;
      _currentRank = rank;
      _nextRank = nextRankName;
      _xpForNextRank = nextRankXP;
      _progress = progress.clamp(0.0, 1.0);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.kBgCream,
      appBar: RPGAppBar(screenKey: 'rank'),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            // Current Rank Display
            FantasyCard(
              padding: const EdgeInsets.all(32),
              child: Column(
                children: [
                  Text(
                    'CURRENT RANK',
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      fontWeight: FontWeight.w900,
                      color: Colors.black38,
                      letterSpacing: 2,
                    ),
                  ),
                  const SizedBox(height: 24),
                  FantasyRankBadge(
                    rankName: _currentRank,
                    level: GamificationService.getCurrentLevel(_currentXP),
                    progress: _progress,
                    size: 160,
                  ).animate().scale(duration: 800.ms, curve: Curves.elasticOut),
                  const SizedBox(height: 32),
                  _buildXPProgress(),
                ],
              ),
            ).animate().fadeIn().slideY(begin: 0.1),
            
            const SizedBox(height: 32),

            _sectionTitle('RANK PROGRESSION'),
            const SizedBox(height: 16),
            _buildRankStepper(),

            const SizedBox(height: 24),

            // ── Next Rank Reward Detail — sesuai desain Stitch ───────────────
            _buildNextRankRewardCard(),

            const SizedBox(height: 32),
            
            _sectionTitle('LEADERBOARD'),
            const SizedBox(height: 16),
            _buildLeaderboard(),
            const SizedBox(height: 100),
          ],
        ),
      ),
    );
  }

  Widget _sectionTitle(String title) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Text(
        title,
        style: GoogleFonts.poppins(
          fontSize: 14,
          fontWeight: FontWeight.w900,
          color: Colors.black87,
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  Widget _buildXPProgress() {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '$_currentXP XP',
              style: GoogleFonts.montserrat(fontWeight: FontWeight.bold, color: AppColors.kPrimaryOrange),
            ),
            Text(
              '$_xpForNextRank XP',
              style: GoogleFonts.montserrat(fontWeight: FontWeight.bold, color: Colors.black38),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Stack(
          children: [
            Container(
              height: 10,
              width: double.infinity,
              decoration: BoxDecoration(color: Colors.grey[100], borderRadius: BorderRadius.circular(5)),
            ),
            FractionallySizedBox(
              widthFactor: _progress,
              child: Container(
                height: 10,
                decoration: BoxDecoration(
                  gradient: AppColors.kGradientSunset,
                  borderRadius: BorderRadius.circular(5),
                  boxShadow: [
                    BoxShadow(color: AppColors.kPrimaryOrange.withOpacity(0.3), blurRadius: 4),
                  ],
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Text(
          _nextRank == 'Max Rank'
              ? 'YOU ARE AT THE TOP! 👑'
              : 'Need ${(_xpForNextRank - _currentXP)} XP more for $_nextRank',
          style: GoogleFonts.nunito(fontWeight: FontWeight.w800, color: Colors.black54, fontSize: 12),
        ),
      ],
    );
  }

  Widget _buildRankStepper() {
    return FantasyCard(
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: _rankOrder.map((rank) {
            bool isCurrent = rank == _currentRank;
            bool isPast = _rankOrder.indexOf(rank) < _rankOrder.indexOf(_currentRank);
            
            return Row(
              children: [
                Column(
                  children: [
                    Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        color: isCurrent || isPast ? AppColors.kPrimaryGold.withOpacity(0.1) : Colors.grey[50],
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: isCurrent ? AppColors.kPrimaryGold : (isPast ? AppColors.kPrimaryGold.withOpacity(0.5) : Colors.grey[200]!),
                          width: 2,
                        ),
                      ),
                      child: Center(
                        child: Text(
                          _getRankIcon(rank),
                          style: TextStyle(
                            fontSize: 24,
                            color: Colors.black.withOpacity(isCurrent || isPast ? 1.0 : 0.3),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      rank,
                      style: GoogleFonts.nunito(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: isCurrent ? AppColors.kPrimaryGold : Colors.black38,
                      ),
                    ),
                  ],
                ),
                if (rank != _rankOrder.last)
                  Container(
                    width: 30,
                    height: 2,
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    color: isPast ? AppColors.kPrimaryGold.withOpacity(0.5) : Colors.grey[100],
                  ),
              ],
            );
          }).toList(),
        ),
      ),
    );
  }

  String _getRankIcon(String rank) {
    switch (rank) {
      case 'Bronze': return '🥉';
      case 'Silver': return '🥈';
      case 'Gold': return '🥇';
      case 'Diamond': return '💎';
      case 'Spartan': return '👑';
      default: return '🛡️';
    }
  }

  // ── Next Rank reward detail — sesuai desain Stitch ───────────────────────
  Widget _buildNextRankRewardCard() {
    if (_nextRank == 'Max Rank') {
      return FantasyCard(
        padding: const EdgeInsets.all(20),
        gradient: const LinearGradient(colors: [Color(0x1AFFB800), Colors.white]),
        child: Row(
          children: [
            const Text('👑', style: TextStyle(fontSize: 40)),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                'Kamu sudah mencapai rank tertinggi! Pertahankan posisimu di puncak.',
                style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 13, color: Colors.black87),
              ),
            ),
          ],
        ),
      );
    }

    final xpNeeded = (_xpForNextRank - _currentXP).clamp(0, _xpForNextRank);

    return FantasyCard(
      padding: const EdgeInsets.all(20),
      border: Border.all(color: AppColors.kPrimaryGold.withOpacity(0.4), width: 1.5),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: AppColors.kPrimaryGold.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Center(
                  child: Text(_getRankIcon(_nextRank), style: const TextStyle(fontSize: 28)),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '$_nextRank Warrior',
                      style: GoogleFonts.montserrat(fontSize: 17, fontWeight: FontWeight.w800, color: Colors.black87),
                    ),
                    Text(
                      'Butuh $xpNeeded XP lagi untuk naik tingkat.',
                      style: GoogleFonts.inter(fontSize: 12, color: Colors.black54),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: const Color(0xFFB23B00),
                  borderRadius: BorderRadius.circular(100),
                ),
                child: Text(
                  'NEXT RANK',
                  style: GoogleFonts.nunitoSans(fontSize: 9, fontWeight: FontWeight.w800, color: Colors.white, letterSpacing: 0.5),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(height: 1),
          const SizedBox(height: 16),
          // Grid 2x2 reward unlock
          Row(
            children: [
              Expanded(child: _RewardChip(icon: Icons.face_retouching_natural_rounded, label: 'Avatar Frame')),
              const SizedBox(width: 10),
              Expanded(child: _RewardChip(icon: Icons.verified_rounded, label: 'Gelar Eksklusif')),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(child: _RewardChip(icon: Icons.support_agent_rounded, label: 'Coach Premium')),
              const SizedBox(width: 10),
              Expanded(child: _RewardChip(icon: Icons.trending_up_rounded, label: 'Bonus XP +10%')),
            ],
          ),
        ],
      ),
    ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.05);
  }

  Widget _buildLeaderboard() {
    // Mock Leaderboard Data
    final List<Map<String, dynamic>> leaderboard = [
      {'name': 'Ariq (You)', 'xp': _currentXP, 'rank': _currentRank, 'isMe': true},
      {'name': 'Budi Pekerti', 'xp': 1250, 'rank': 'Gold', 'isMe': false},
      {'name': 'Siti Nurhaliza', 'xp': 980, 'rank': 'Silver', 'isMe': false},
      {'name': 'Andi Wijaya', 'xp': 850, 'rank': 'Silver', 'isMe': false},
      {'name': 'Rina Pratama', 'xp': 420, 'rank': 'Bronze', 'isMe': false},
    ];

    leaderboard.sort((a, b) => b['xp'].compareTo(a['xp']));

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: AppColors.kSoftShadow,
      ),
      child: Column(
        children: leaderboard.asMap().entries.map((entry) {
          int index = entry.key;
          var user = entry.value;
          bool isMe = user['isMe'];

          return Column(
            children: [
              ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                leading: _buildRankPosition(index + 1),
                title: Text(
                  user['name'],
                  style: GoogleFonts.poppins(
                    fontWeight: isMe ? FontWeight.w900 : FontWeight.bold,
                    color: isMe ? AppColors.kPrimaryOrange : Colors.black87,
                    fontSize: 14,
                  ),
                ),
                subtitle: Text(
                  '${user['rank']} Warrior',
                  style: GoogleFonts.inter(fontSize: 11, color: Colors.black38, fontWeight: FontWeight.w600),
                ),
                trailing: Text(
                  '${user['xp']} XP',
                  style: GoogleFonts.montserrat(fontWeight: FontWeight.w900, color: isMe ? AppColors.kPrimaryOrange : Colors.black54),
                ),
              ),
              if (index != leaderboard.length - 1)
                Divider(height: 1, indent: 70, color: Colors.grey[50]),
            ],
          );
        }).toList(),
      ),
    );
  }

  Widget _buildRankPosition(int pos) {
    if (pos == 1) return const Text('🥇', style: TextStyle(fontSize: 24));
    if (pos == 2) return const Text('🥈', style: TextStyle(fontSize: 24));
    if (pos == 3) return const Text('🥉', style: TextStyle(fontSize: 24));
    
    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(color: Colors.grey[100], shape: BoxShape.circle),
      child: Center(
        child: Text(
          '$pos',
          style: GoogleFonts.montserrat(fontWeight: FontWeight.w900, fontSize: 12, color: Colors.black38),
        ),
      ),
    );
  }
}

// ── Reward chip kecil untuk grid Next Rank ──────────────────────────────────
class _RewardChip extends StatelessWidget {
  final IconData icon;
  final String label;
  const _RewardChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFFBF1E3),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(icon, size: 16, color: const Color(0xFF8A5A1E)),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              label,
              style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w600, color: Colors.black87),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
