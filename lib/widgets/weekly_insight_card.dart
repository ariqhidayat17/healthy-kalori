import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:google_fonts/google_fonts.dart';
import '../config/app_colors.dart';
import '../services/weekly_insight_service.dart';

/// Kartu ringkasan mingguan AI yang tampil di HomeScreen.
/// Menampilkan loading state, error, dan teks insight ber-Markdown.
class WeeklyInsightCard extends StatefulWidget {
  const WeeklyInsightCard({super.key});

  @override
  State<WeeklyInsightCard> createState() => _WeeklyInsightCardState();
}

class _WeeklyInsightCardState extends State<WeeklyInsightCard> {
  final _service = WeeklyInsightService();
  String? _insight;
  bool _isLoading = false;
  String? _error;
  bool _isFromCache = false;
  bool _isExpanded = true;

  @override
  void initState() {
    super.initState();
    _loadInsight();
  }

  Future<void> _loadInsight({bool forceRefresh = false}) async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    final result = await _service.generateInsight(forceRefresh: forceRefresh);

    if (!mounted) return;
    setState(() {
      _isLoading = false;
      if (result.hasError) {
        _error = result.error;
      } else {
        _insight = result.insight;
        _isFromCache = result.isFromCache;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1A1A2E), Color(0xFF16213E)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header ──────────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 18, 12, 0),
            child: Row(
              children: [
                const Text('🤖', style: TextStyle(fontSize: 22)),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Weekly AI Insight',
                        style: GoogleFonts.poppins(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                        ),
                      ),
                      Text(
                        _isFromCache
                            ? 'Ringkasan minggu ini (tersimpan)'
                            : 'Ringkasan 7 hari terakhirmu',
                        style: GoogleFonts.nunito(
                          fontSize: 11,
                          color: Colors.white54,
                        ),
                      ),
                    ],
                  ),
                ),
                // Refresh button
                if (!_isLoading)
                  IconButton(
                    icon: const Icon(Icons.refresh_rounded,
                        color: Colors.white38, size: 20),
                    tooltip: 'Generate ulang',
                    onPressed: () => _loadInsight(forceRefresh: true),
                  ),
                // Expand/collapse
                IconButton(
                  icon: AnimatedRotation(
                    turns: _isExpanded ? 0 : -0.5,
                    duration: const Duration(milliseconds: 300),
                    child: const Icon(Icons.keyboard_arrow_down_rounded,
                        color: Colors.white38, size: 22),
                  ),
                  onPressed: () =>
                      setState(() => _isExpanded = !_isExpanded),
                ),
              ],
            ),
          ),

          // ── Body ────────────────────────────────────────────────────────
          AnimatedCrossFade(
            duration: const Duration(milliseconds: 300),
            crossFadeState: _isExpanded
                ? CrossFadeState.showFirst
                : CrossFadeState.showSecond,
            firstChild: Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
              child: _buildBody(),
            ),
            secondChild: const SizedBox(width: double.infinity),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 500.ms).slideY(begin: 0.05, end: 0);
  }

  Widget _buildBody() {
    if (_isLoading) return _LoadingShimmer();

    if (_error != null) {
      return Column(
        children: [
          const Icon(Icons.wifi_off_rounded, color: Colors.white38, size: 40),
          const SizedBox(height: 8),
          Text(
            _error!,
            style: GoogleFonts.nunito(color: Colors.white54, fontSize: 13),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          TextButton.icon(
            onPressed: () => _loadInsight(forceRefresh: true),
            icon: const Icon(Icons.refresh, color: AppColors.kPrimaryOrange),
            label: Text(
              'Coba lagi',
              style: GoogleFonts.nunito(
                  color: AppColors.kPrimaryOrange,
                  fontWeight: FontWeight.bold),
            ),
          ),
        ],
      );
    }

    if (_insight == null || _insight!.isEmpty) {
      return Center(
        child: Text(
          'Belum ada data untuk minggu ini.',
          style: GoogleFonts.nunito(color: Colors.white54),
        ),
      );
    }

    return MarkdownBody(
      data: _insight!,
      styleSheet: MarkdownStyleSheet(
        p: GoogleFonts.nunito(
            fontSize: 13, color: Colors.white70, height: 1.6),
        strong: GoogleFonts.nunito(
            fontSize: 13,
            color: Colors.white,
            fontWeight: FontWeight.w800),
        h2: GoogleFonts.poppins(
            fontSize: 13,
            fontWeight: FontWeight.w800,
            color: AppColors.kPrimaryOrange),
        blockquoteDecoration: BoxDecoration(
          color: Colors.white.withOpacity(0.05),
          borderRadius: BorderRadius.circular(8),
          border: Border(
              left: BorderSide(
                  color: AppColors.kPrimaryOrange.withOpacity(0.5),
                  width: 3)),
        ),
      ),
    );
  }
}

/// Shimmer loading placeholder
class _LoadingShimmer extends StatefulWidget {
  @override
  State<_LoadingShimmer> createState() => _LoadingShimmerState();
}

class _LoadingShimmerState extends State<_LoadingShimmer>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1200))
      ..repeat(reverse: true);
    _anim = Tween(begin: 0.3, end: 0.7).animate(_ctrl);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _anim,
      builder: (_, __) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            const Text('🧠', style: TextStyle(fontSize: 16)),
            const SizedBox(width: 8),
            Text(
              'Apex sedang menganalisis data minggu ini...',
              style: GoogleFonts.nunito(
                  color: Colors.white.withOpacity(_anim.value),
                  fontSize: 12,
                  fontStyle: FontStyle.italic),
            ),
          ]),
          const SizedBox(height: 12),
          ...[0.9, 0.7, 0.8, 0.5].map((w) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Container(
                  height: 12,
                  width: double.infinity * w,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(_anim.value * 0.3),
                    borderRadius: BorderRadius.circular(6),
                  ),
                ),
              )),
        ],
      ),
    );
  }
}
