import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../utils/prefs_service.dart';
import '../models/weight_entry.dart';
import '../utils/database_helper.dart';

class WeightLogScreen extends StatefulWidget {
  const WeightLogScreen({super.key});

  @override
  State<WeightLogScreen> createState() => _WeightLogScreenState();
}

class _WeightLogScreenState extends State<WeightLogScreen>
    with SingleTickerProviderStateMixin {
  List<WeightEntry> _history = [];
  bool _isLoading = true;
  double _userHeight = 1.70; // default 170cm in meters
  late AnimationController _animController;
  late Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _fadeAnim = CurvedAnimation(parent: _animController, curve: Curves.easeOut);
    _loadData();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    
    // Load height from profile
    final prefs = PrefsService.i.raw;
    final heightCm = prefs.getDouble('height') ?? 170.0;
    _userHeight = heightCm / 100.0; // Convert cm to meters

    // Load weight history
    final data = await DatabaseHelper.instance.getWeightHistory();
    setState(() {
      _history = data;
      _isLoading = false;
    });
    _animController.forward(from: 0);
  }

  Future<void> _loadHistory() async {
    final data = await DatabaseHelper.instance.getWeightHistory();
    setState(() {
      _history = data;
    });
  }

  double? get _latestWeight => _history.isNotEmpty ? _history.first.weight : null;
  double? get _previousWeight => _history.length > 1 ? _history[1].weight : null;

  double? _calculateBmi(double weight) {
    if (_userHeight <= 0) return null;
    return weight / (_userHeight * _userHeight);
  }

  String _bmiCategory(double bmi) {
    if (bmi < 18.5) return 'Kurus';
    if (bmi < 25.0) return 'Normal';
    if (bmi < 30.0) return 'Gemuk';
    return 'Obesitas';
  }

  Color _bmiColor(double bmi) {
    if (bmi < 18.5) return const Color(0xFF00B4DB);
    if (bmi < 25.0) return const Color(0xFF38EF7D);
    if (bmi < 30.0) return const Color(0xFFF2C94C);
    return const Color(0xFFE91E63);
  }

  void _showAddEditDialog({WeightEntry? existing}) {
    final weightCtrl = TextEditingController(
        text: existing != null ? existing.weight.toString() : '');
    final noteCtrl =
        TextEditingController(text: existing?.note ?? '');
    final today = DateFormat('dd/MM/yyyy').format(DateTime.now());

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFFFF9800).withOpacity(0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.monitor_weight_outlined,
                  color: Color(0xFFFF9800)),
            ),
            const SizedBox(width: 12),
            Text(
              existing == null ? 'Tambah Berat Badan' : 'Edit Entri',
              style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: weightCtrl,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              autofocus: true,
              style: const TextStyle(
                  color: Colors.black87, fontSize: 18, fontWeight: FontWeight.bold),
              decoration: InputDecoration(
                labelText: 'Berat Badan (kg)',
                labelStyle: const TextStyle(color: Colors.grey),
                suffixText: 'kg',
                suffixStyle: const TextStyle(color: Color(0xFFFF9800)),
                filled: true,
                fillColor: Colors.grey[100],
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFFFF9800), width: 1.5),
                ),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: noteCtrl,
              style: const TextStyle(color: Colors.black87),
              decoration: InputDecoration(
                labelText: 'Catatan (opsional)',
                labelStyle: const TextStyle(color: Colors.grey),
                hintText: 'contoh: setelah olahraga',
                hintStyle: TextStyle(color: Colors.grey[400]),
                filled: true,
                fillColor: Colors.grey[100],
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFFFF9800), width: 1.5),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Batal', style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFF9800),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              elevation: 0,
            ),
            onPressed: () async {
              final w = double.tryParse(weightCtrl.text);
              if (w == null || w <= 0) return;
              final entry = WeightEntry(
                id: existing?.id,
                date: existing?.date ?? today,
                weight: w,
                note: noteCtrl.text.trim(),
              );
              if (existing == null) {
                await DatabaseHelper.instance.insertWeight(entry);
              } else {
                await DatabaseHelper.instance.updateWeight(entry);
              }
              
              // Update weight in profile automatically
              final prefs = PrefsService.i.raw;
              await prefs.setDouble('weight', w);
              
              if (ctx.mounted) Navigator.pop(ctx);
              await _loadHistory();
            },
            child: const Text('Simpan', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteEntry(WeightEntry entry) async {
    await DatabaseHelper.instance.deleteWeight(entry.id!);
    await _loadHistory();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Entri ${entry.weight} kg dihapus'),
          action: SnackBarAction(
            label: 'Oke',
            textColor: const Color(0xFFFF9800),
            onPressed: () {},
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: const Text('Log Berat Badan', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black87)),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.black87),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddEditDialog(),
        backgroundColor: const Color(0xFFFF9800),
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text('Catat Sekarang',
            style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFFFF9800)))
          : FadeTransition(
              opacity: _fadeAnim,
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (_latestWeight != null) ...[
                      _buildCurrentWeightCard(),
                      const SizedBox(height: 24),
                    ],
                    _buildHistoryHeader(),
                    const SizedBox(height: 12),
                    if (_history.isEmpty)
                      _buildEmptyState()
                    else
                      ..._history.map((e) => _buildEntryCard(e)),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildCurrentWeightCard() {
    final bmi = _calculateBmi(_latestWeight!);
    final delta = _previousWeight != null
        ? _latestWeight! - _previousWeight!
        : null;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFFFF3E0), Color(0xFFFFE0B2)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFFF9800).withOpacity(0.2)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFFF9800).withOpacity(0.06),
            blurRadius: 15,
            offset: const Offset(0, 6),
          )
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Berat Saat Ini',
                      style: TextStyle(color: Colors.black54, fontSize: 13, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        _latestWeight!.toStringAsFixed(1),
                        style: const TextStyle(
                          color: Color(0xFFFF9800),
                          fontSize: 48,
                          fontWeight: FontWeight.bold,
                          height: 1,
                        ),
                      ),
                      const Padding(
                        padding: EdgeInsets.only(bottom: 8, left: 4),
                        child: Text('kg',
                            style: TextStyle(
                                color: Colors.black54, fontSize: 16, fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                  if (delta != null)
                    Row(
                      children: [
                        Icon(
                          delta < 0 ? Icons.trending_down : Icons.trending_up,
                          color: delta < 0
                              ? const Color(0xFF38EF7D)
                              : const Color(0xFFE91E63),
                          size: 16,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${delta >= 0 ? '+' : ''}${delta.toStringAsFixed(1)} kg',
                          style: TextStyle(
                            color: delta < 0
                                ? const Color(0xFF38EF7D)
                                : const Color(0xFFE91E63),
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const Text('  dari sebelumnya',
                            style: TextStyle(
                                color: Colors.grey, fontSize: 11, fontWeight: FontWeight.w500)),
                      ],
                    ),
                ],
              ),
              if (bmi != null) _buildBmiChip(bmi),
            ],
          ),
          if (bmi != null) ...[
            const SizedBox(height: 20),
            _buildBmiBar(bmi),
          ],
        ],
      ),
    );
  }

  Widget _buildBmiChip(double bmi) {
    final color = _bmiColor(bmi);
    final category = _bmiCategory(bmi);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Text(
            'BMI',
            style: TextStyle(color: color.withOpacity(0.8), fontSize: 11, fontWeight: FontWeight.bold),
          ),
          Text(
            bmi.toStringAsFixed(1),
            style: TextStyle(
                color: color, fontSize: 20, fontWeight: FontWeight.bold),
          ),
          Text(
            category,
            style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Widget _buildBmiBar(double bmi) {
    final normalized = ((bmi - 15) / 25).clamp(0.0, 1.0);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: const [
            Text('Kurus', style: TextStyle(color: Colors.grey, fontSize: 10, fontWeight: FontWeight.bold)),
            Text('Normal', style: TextStyle(color: Colors.grey, fontSize: 10, fontWeight: FontWeight.bold)),
            Text('Gemuk', style: TextStyle(color: Colors.grey, fontSize: 10, fontWeight: FontWeight.bold)),
            Text('Obesitas', style: TextStyle(color: Colors.grey, fontSize: 10, fontWeight: FontWeight.bold)),
          ],
        ),
        const SizedBox(height: 4),
        Stack(
          children: [
            Container(
              height: 8,
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: [
                  Color(0xFF00B4DB),
                  Color(0xFF38EF7D),
                  Color(0xFFF2C94C),
                  Color(0xFFE91E63),
                ]),
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            Positioned(
              left: (normalized * (MediaQuery.of(context).size.width - 80))
                  .clamp(0.0, MediaQuery.of(context).size.width - 80),
              top: -2,
              child: Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  border: Border.all(color: _bmiColor(bmi), width: 2),
                  boxShadow: [
                    BoxShadow(
                        color: _bmiColor(bmi).withOpacity(0.4),
                        blurRadius: 4)
                  ],
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildHistoryHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Text(
          'Riwayat Berat',
          style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.black87),
        ),
        Text(
          '${_history.length} entri',
          style: const TextStyle(color: Colors.grey, fontSize: 13, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }

  Widget _buildEntryCard(WeightEntry entry) {
    final bool isLatest = entry == _history.first;
    return Dismissible(
      key: Key('weight_${entry.id}'),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        margin: const EdgeInsets.only(bottom: 10),
        decoration: BoxDecoration(
          color: const Color(0xFFE91E63).withOpacity(0.15),
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Icon(Icons.delete_outline, color: Color(0xFFE91E63)),
      ),
      confirmDismiss: (dir) async {
        return await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            backgroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: const Text('Hapus Entri?', style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold)),
            content: Text(
                'Hapus catatan ${entry.weight} kg pada ${entry.date}?', style: const TextStyle(color: Colors.black54)),
            actions: [
              TextButton(
                  onPressed: () => Navigator.pop(ctx, false),
                  child: const Text('Batal', style: TextStyle(color: Colors.grey))),
              TextButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: const Text('Hapus',
                    style: TextStyle(color: Color(0xFFE91E63), fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        );
      },
      onDismissed: (_) => _deleteEntry(entry),
      child: GestureDetector(
        onTap: () => _showAddEditDialog(existing: entry),
        child: Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isLatest
                  ? const Color(0xFFFF9800).withOpacity(0.4)
                  : Colors.grey[200]!,
              width: isLatest ? 1.5 : 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.02),
                blurRadius: 8,
                offset: const Offset(0, 3),
              )
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: isLatest
                      ? const Color(0xFFFF9800).withOpacity(0.1)
                      : Colors.grey[100],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.monitor_weight_outlined,
                  color: isLatest
                      ? const Color(0xFFFF9800)
                      : Colors.grey[500],
                  size: 22,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      entry.date,
                      style: TextStyle(
                        color: isLatest
                            ? const Color(0xFFFF9800)
                            : Colors.black54,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (entry.note.isNotEmpty)
                      Text(
                        entry.note,
                        style: TextStyle(
                            color: Colors.grey[600], fontSize: 11),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                  ],
                ),
              ),
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    entry.weight.toStringAsFixed(1),
                    style: TextStyle(
                      color: isLatest
                          ? const Color(0xFFFF9800)
                          : Colors.black87,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Padding(
                    padding: EdgeInsets.only(bottom: 2, left: 2),
                    child: Text('kg',
                        style:
                            TextStyle(color: Colors.grey, fontSize: 12, fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
              const SizedBox(width: 8),
              Icon(Icons.edit_outlined,
                  size: 16, color: Colors.grey[400]),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 48),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF3E0),
                shape: BoxShape.circle,
                border: Border.all(
                    color: const Color(0xFFFF9800).withOpacity(0.2)),
              ),
              child: const Icon(Icons.monitor_weight_outlined,
                  size: 48, color: Color(0xFFFF9800)),
            ),
            const SizedBox(height: 20),
            const Text(
              'Belum ada catatan berat',
              style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87),
            ),
            const SizedBox(height: 8),
            const Text(
              'Tap tombol di bawah untuk mulai\nmemantau progress berat badanmu!',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey, fontSize: 13),
            ),
          ],
        ),
      ),
    );
  }
}
