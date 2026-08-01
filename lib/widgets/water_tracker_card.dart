import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../models/calorie_provider.dart';
import '../services/gamification_service.dart';

class WaterTrackerCard extends StatelessWidget {
  const WaterTrackerCard({super.key});

  void _showEditWaterTargetDialog(BuildContext context, int currentTarget) {
    final controller = TextEditingController(text: currentTarget.toString());
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(ctx).viewInsets.bottom,
        ),
        child: Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'Target Air Minum',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: controller,
                keyboardType: TextInputType.number,
                autofocus: true,
                decoration: const InputDecoration(
                  labelText: 'Target per hari',
                  suffixText: 'ml',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.all(Radius.circular(12)),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(ctx),
                    child: const Text('Batal', style: TextStyle(color: Colors.grey)),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF03A9F4),
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    ),
                    onPressed: () {
                      final val = int.tryParse(controller.text) ?? 4000;
                      if (val > 0) {
                        context.read<CalorieProvider>().updateTargetWater(val);
                        HapticFeedback.mediumImpact();
                        Navigator.pop(ctx);
                      }
                    },
                    child: const Text('Simpan', style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _addWaterWithXP(BuildContext context, int amount) async {
    context.read<CalorieProvider>().addWater(amount);
    HapticFeedback.lightImpact();

    // +5 XP per 250ml gelas
    final cupsAdded = (amount / 250).round();
    if (cupsAdded > 0) {
      final xpResult = await GamificationService().addXP(cupsAdded * 5);
      final leveledUp = xpResult['leveled_up'] as bool;
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(leveledUp
                ? '🎉 NAIK RANK ke ${xpResult['new_rank']}! (+${cupsAdded * 5} XP)'
                : '💧 +${amount}ml air! +${cupsAdded * 5} XP'),
            backgroundColor:
                leveledUp ? const Color(0xFF4CAF50) : const Color(0xFF03A9F4),
            behavior: SnackBarBehavior.floating,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            margin: const EdgeInsets.all(16),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final calorieProvider = context.watch<CalorieProvider>();
    final consumedWater = calorieProvider.totalConsumedWater;
    final targetWater = calorieProvider.targetWater;
    final double waterPercentage =
        targetWater > 0 ? (consumedWater / targetWater).clamp(0.0, 1.0) : 0.0;

    // Hitung gelas
    final int cups = (consumedWater / 250).floor();
    final int targetCups = (targetWater / 250).floor();

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFE1F5FE), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF03A9F4).withOpacity(0.06),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE1F5FE),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.water_drop,
                          color: Color(0xFF03A9F4), size: 22),
                    ),
                    const SizedBox(width: 10),
                    const Text(
                      'Water Tracker',
                      style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF1A1A2E)),
                    ),
                  ],
                ),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFF03A9F4).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '+5 XP/gelas',
                        style: TextStyle(
                          color: const Color(0xFF03A9F4),
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    if (consumedWater > 0)
                      GestureDetector(
                        onTap: () =>
                            context.read<CalorieProvider>().addWater(-250),
                        child: const Icon(Icons.undo,
                            color: Colors.grey, size: 18),
                      ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Progress & count
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                TweenAnimationBuilder<int>(
                  tween: IntTween(begin: 0, end: consumedWater),
                  duration: const Duration(milliseconds: 500),
                  builder: (context, value, child) {
                    return GestureDetector(
                      onTap: () =>
                          _showEditWaterTargetDialog(context, targetWater),
                      child: RichText(
                        text: TextSpan(
                          children: [
                            TextSpan(
                              text: '$value',
                              style: const TextStyle(
                                  fontWeight: FontWeight.w900,
                                  color: Color(0xFF03A9F4),
                                  fontSize: 20),
                            ),
                            TextSpan(
                              text: ' / $targetWater ml',
                              style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  color: Colors.grey[500],
                                  fontSize: 13),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
                Text(
                  '$cups / $targetCups 🥤',
                  style: const TextStyle(
                      color: Color(0xFF03A9F4),
                      fontWeight: FontWeight.w700,
                      fontSize: 13),
                ),
              ],
            ),
            const SizedBox(height: 10),

            // Progress bar
            LayoutBuilder(
              builder: (context, constraints) {
                return Stack(
                  children: [
                    Container(
                        height: 12,
                        decoration: BoxDecoration(
                            color: Colors.grey[200],
                            borderRadius: BorderRadius.circular(8))),
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 1000),
                      curve: Curves.easeOutCubic,
                      height: 12,
                      width: constraints.maxWidth * waterPercentage,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        gradient: const LinearGradient(
                            colors: [Color(0xFF29B6F6), Color(0xFF03A9F4)]),
                      ),
                    ),
                  ],
                );
              },
            ),
            const SizedBox(height: 18),

            // Tombol tambah air
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildWaterBtn(context, 250, Icons.local_drink, '250ml'),
                _buildWaterBtn(context, 500, Icons.water_drop, '500ml'),
                _buildWaterBtn(context, 1000, Icons.sports_mma, '1L'),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWaterBtn(
      BuildContext context, int amount, IconData icon, String label) {
    return GestureDetector(
      onTap: () => _addWaterWithXP(context, amount),
      child: Container(
        padding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: const Color(0xFFE1F5FE),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
              color: const Color(0xFF03A9F4).withOpacity(0.2), width: 1.5),
        ),
        child: Column(
          children: [
            Icon(icon, color: const Color(0xFF03A9F4), size: 18),
            const SizedBox(height: 3),
            Text(
              label,
              style: const TextStyle(
                  color: Color(0xFF03A9F4),
                  fontWeight: FontWeight.w800,
                  fontSize: 11),
            ),
          ],
        ),
      ),
    );
  }
}
