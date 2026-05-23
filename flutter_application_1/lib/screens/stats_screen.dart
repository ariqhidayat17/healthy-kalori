import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../models/calorie_provider.dart';
import '../utils/database_helper.dart';
import '../models/weight_entry.dart';
import '../services/pdf_report_service.dart';

class StatsScreen extends StatefulWidget {
  const StatsScreen({super.key});

  @override
  State<StatsScreen> createState() => _StatsScreenState();
}

class _StatsScreenState extends State<StatsScreen> {
  bool _isLoading = true;
  String _selectedType = 'Calories';

  final Map<String, List<FlSpot>> _macroSpots = {
    'Calories': [],
    'Protein': [],
    'Carbs': [],
    'Fats': [],
    'Water': [],
  };

  final Map<String, double> _maxValues = {
    'Calories': 2000,
    'Protein': 150,
    'Carbs': 300,
    'Fats': 100,
    'Water': 4000,
  };

  List<String> _days = [];

  // Weight-specific data
  List<WeightEntry> _weightData = [];
  List<FlSpot> _weightSpots = [];
  double _weightMin = 40;
  double _weightMax = 100;
  List<String> _weightLabels = [];

  @override
  void initState() {
    super.initState();
    _loadWeeklyData();
  }

  Future<void> _loadWeeklyData() async {
    _days.clear();
    _macroSpots.forEach((key, value) => value.clear());

    Map<String, double> currentMax = {
      'Calories': 0,
      'Protein': 0,
      'Carbs': 0,
      'Fats': 0,
      'Water': 0,
    };

    // Tarik data 7 hari terakhir
    for (int i = 6; i >= 0; i--) {
      final date = DateTime.now().subtract(Duration(days: i));
      final dateStr = DateFormat('dd/MM/yyyy').format(date);
      final dayName = DateFormat('E').format(date);
      _days.add(dayName);

      // Fetch Calories
      final cal = await DatabaseHelper.instance.getTotalCaloriesByDate(dateStr);
      _macroSpots['Calories']!.add(FlSpot((6 - i).toDouble(), cal.toDouble()));
      if (cal > currentMax['Calories']!) currentMax['Calories'] = cal.toDouble();

      // Fetch Macros
      final macros = await DatabaseHelper.instance.getTotalMacrosByDate(dateStr);

      _macroSpots['Protein']!.add(FlSpot((6 - i).toDouble(), (macros['protein'] ?? 0).toDouble()));
      if ((macros['protein'] ?? 0) > currentMax['Protein']!) currentMax['Protein'] = (macros['protein'] ?? 0).toDouble();

      _macroSpots['Carbs']!.add(FlSpot((6 - i).toDouble(), (macros['carbs'] ?? 0).toDouble()));
      if ((macros['carbs'] ?? 0) > currentMax['Carbs']!) currentMax['Carbs'] = (macros['carbs'] ?? 0).toDouble();

      _macroSpots['Fats']!.add(FlSpot((6 - i).toDouble(), (macros['fats'] ?? 0).toDouble()));
      if ((macros['fats'] ?? 0) > currentMax['Fats']!) currentMax['Fats'] = (macros['fats'] ?? 0).toDouble();

      // Fetch Water
      final water = await DatabaseHelper.instance.getTotalWaterByDate(dateStr);
      _macroSpots['Water']!.add(FlSpot((6 - i).toDouble(), water.toDouble()));
      if (water > currentMax['Water']!) currentMax['Water'] = water.toDouble();
    }

    // Load weight history (up to 14 entries) for dedicated chart
    _weightData = await DatabaseHelper.instance.getWeightForChart(limit: 14);
    _buildWeightSpots();

    if (!mounted) return;
    final provider = context.read<CalorieProvider>();

    // Adjust max values for better padding
    setState(() {
      _maxValues['Calories'] = currentMax['Calories']! == 0 ? provider.targetCalories.toDouble() + 500 : currentMax['Calories']! + 500;
      _maxValues['Protein'] = currentMax['Protein']! == 0 ? provider.targetProtein.toDouble() + 40 : currentMax['Protein']! + 40;
      _maxValues['Carbs'] = currentMax['Carbs']! == 0 ? provider.targetCarbs.toDouble() + 60 : currentMax['Carbs']! + 60;
      _maxValues['Fats'] = currentMax['Fats']! == 0 ? provider.targetFats.toDouble() + 30 : currentMax['Fats']! + 30;
      _maxValues['Water'] = currentMax['Water']! == 0 ? provider.targetWater.toDouble() + 500 : currentMax['Water']! + 1000;
      _isLoading = false;
    });
  }

  void _buildWeightSpots() {
    _weightSpots = [];
    _weightLabels = [];
    if (_weightData.isEmpty) return;

    final weights = _weightData.map((e) => e.weight).toList();
    _weightMin = weights.reduce((a, b) => a < b ? a : b) - 2;
    _weightMax = weights.reduce((a, b) => a > b ? a : b) + 2;

    for (int i = 0; i < _weightData.length; i++) {
      _weightSpots.add(FlSpot(i.toDouble(), _weightData[i].weight));
      // Ambil label hari singkat dari date string dd/MM/yyyy
      try {
        final parts = _weightData[i].date.split('/');
        _weightLabels.add('${parts[0]}/${parts[1]}');
      } catch (_) {
        _weightLabels.add('${i + 1}');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Statistik Nutrisi'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.picture_as_pdf, color: Color(0xFFD4AF37)),
            tooltip: 'Cetak Laporan PDF',
            onPressed: () async {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Menyiapkan Laporan PDF...'), duration: Duration(seconds: 10)), // Tambah durasi biar gak hilang cepat
              );
              await PdfReportService.generateAndShareWeeklyReport(context);
            },
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFFD4AF37)))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeader(),
                  const SizedBox(height: 20),
                  _buildSelector(),
                  const SizedBox(height: 24),
                  _selectedType == 'Weight'
                      ? _buildWeightChartContainer()
                      : _buildChartContainer(),
                  const SizedBox(height: 24),
                  if (_selectedType == 'Weight')
                    _buildWeightSummaryCard()
                  else
                    _buildTipsCard(),
                ],
              ),
            ),
    );
  }

  Widget _buildHeader() {
    final labels = {
      'Calories': 'Kalori',
      'Protein': 'Protein',
      'Carbs': 'Karbohidrat',
      'Fats': 'Lemak',
      'Water': 'Air Minum',
      'Weight': 'Berat Badan',
    };
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Tren ${labels[_selectedType] ?? _selectedType}',
          style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 4),
        Text(
          _selectedType == 'Weight'
              ? 'Pantau progres berat badanmu dari waktu ke waktu.'
              : 'Memantau konsistensi ${_selectedType.toLowerCase()} harian Anda.',
          style: const TextStyle(fontSize: 14, color: Color(0xFFBBAA88)),
        ),
      ],
    );
  }

  Widget _buildSelector() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Container(
        height: 45,
        decoration: BoxDecoration(
          color: const Color(0xFF1A1A1A),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white.withOpacity(0.05)),
        ),
        child: Row(
          children: [
            _buildSelectorItem('Calories', 'Kalori'),
            _buildSelectorItem('Protein', 'Protein'),
            _buildSelectorItem('Carbs', 'Karbo'),
            _buildSelectorItem('Fats', 'Lemak'),
            _buildSelectorItem('Water', 'Air'),
            _buildSelectorItem('Weight', 'Berat'),
          ],
        ),
      ),
    );
  }

  Widget _buildSelectorItem(String type, String label) {
    bool isSelected = _selectedType == type;
    return GestureDetector(
      onTap: () => setState(() => _selectedType = type),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFD4AF37) : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.black : Colors.white60,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            fontSize: 13,
          ),
        ),
      ),
    );
  }

  Widget _buildChartContainer() {
    return Container(
      height: 300,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF161616), Color(0xFF1E1E1E)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withOpacity(0.08), width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.4),
            blurRadius: 20,
            offset: const Offset(0, 10),
          )
        ],
      ),
      padding: const EdgeInsets.only(right: 20, left: 10, top: 24, bottom: 12),
      child: LineChart(_mainData()),
    );
  }

  Widget _buildWeightChartContainer() {
    if (_weightData.isEmpty) {
      return Container(
        height: 300,
        decoration: BoxDecoration(
          color: const Color(0xFF161616),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: Colors.white.withOpacity(0.08)),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.monitor_weight_outlined,
                  size: 48, color: Color(0xFF444444)),
              const SizedBox(height: 12),
              const Text('Belum ada data berat badan',
                  style: TextStyle(color: Color(0xFFBBAA88))),
              const SizedBox(height: 8),
              const Text('Catat berat badanmu dari halaman Profil',
                  style: TextStyle(color: Color(0xFF665C44), fontSize: 12)),
            ],
          ),
        ),
      );
    }

    return Container(
      height: 300,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF161616), Color(0xFF1E1E1E)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withOpacity(0.08), width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.4),
            blurRadius: 20,
            offset: const Offset(0, 10),
          )
        ],
      ),
      padding: const EdgeInsets.only(right: 20, left: 10, top: 24, bottom: 12),
      child: LineChart(_weightChartData()),
    );
  }

  LineChartData _weightChartData() {
    const mainColor = Color(0xFFD4AF37);
    return LineChartData(
      gridData: FlGridData(
        show: true,
        drawVerticalLine: false,
        horizontalInterval: 2,
        getDrawingHorizontalLine: (value) => FlLine(
          color: const Color(0xFF2A2A2A),
          strokeWidth: 1,
          dashArray: [5, 5],
        ),
      ),
      titlesData: FlTitlesData(
        show: true,
        rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        bottomTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            reservedSize: 30,
            interval: 1,
            getTitlesWidget: (value, meta) {
              final idx = value.toInt();
              if (idx >= 0 && idx < _weightLabels.length) {
                // Show every other label if many data points
                if (_weightData.length > 7 && idx % 2 != 0) return const SizedBox();
                return SideTitleWidget(
                  axisSide: meta.axisSide,
                  child: Text(
                    _weightLabels[idx],
                    style: const TextStyle(color: Color(0xFFBBAA88), fontSize: 9),
                  ),
                );
              }
              return const SizedBox();
            },
          ),
        ),
        leftTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            interval: 2,
            reservedSize: 42,
            getTitlesWidget: (value, meta) {
              return Text(
                value.toInt().toString(),
                style: const TextStyle(color: Color(0xFFBBAA88), fontSize: 10),
              );
            },
          ),
        ),
      ),
      borderData: FlBorderData(show: false),
      minX: 0,
      maxX: (_weightSpots.length - 1).toDouble().clamp(1, 13),
      minY: _weightMin,
      maxY: _weightMax,
      lineBarsData: [
        LineChartBarData(
          spots: _weightSpots,
          isCurved: true,
          curveSmoothness: 0.3,
          color: mainColor,
          barWidth: 3,
          isStrokeCapRound: true,
          dotData: FlDotData(
            show: true,
            getDotPainter: (spot, percent, barData, index) => FlDotCirclePainter(
              radius: 4,
              color: mainColor,
              strokeWidth: 2,
              strokeColor: const Color(0xFF161616),
            ),
          ),
          belowBarData: BarAreaData(
            show: true,
            gradient: LinearGradient(
              colors: [
                mainColor.withOpacity(0.25),
                mainColor.withOpacity(0.0),
              ],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
        ),
      ],
    );
  }

  LineChartData _mainData() {
    Color mainColor = _getColorForType(_selectedType);
    double interval = _selectedType == 'Calories' ? 1000 : (_selectedType == 'Water' ? 1000 : 50);

    return LineChartData(
      gridData: FlGridData(
        show: true,
        drawVerticalLine: false,
        horizontalInterval: interval,
        getDrawingHorizontalLine: (value) => FlLine(
          color: const Color(0xFF2A2A2A),
          strokeWidth: 1,
          dashArray: [5, 5],
        ),
      ),
      titlesData: FlTitlesData(
        show: true,
        rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        bottomTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            reservedSize: 30,
            interval: 1,
            getTitlesWidget: (value, meta) {
              if (value.toInt() >= 0 && value.toInt() < _days.length) {
                return SideTitleWidget(
                  axisSide: meta.axisSide,
                  child: Text(
                    _days[value.toInt()],
                    style: const TextStyle(color: Color(0xFFBBAA88), fontSize: 10),
                  ),
                );
              }
              return const SizedBox();
            },
          ),
        ),
        leftTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            interval: interval,
            reservedSize: 42,
            getTitlesWidget: (value, meta) {
              return Text(
                value.toInt().toString(),
                style: const TextStyle(color: Color(0xFFBBAA88), fontSize: 10),
              );
            },
          ),
        ),
      ),
      borderData: FlBorderData(show: false),
      minX: 0,
      maxX: 6,
      minY: 0,
      maxY: _maxValues[_selectedType]!,
      lineBarsData: [
        LineChartBarData(
          spots: _macroSpots[_selectedType]!,
          isCurved: true,
          curveSmoothness: 0.3,
          color: mainColor,
          barWidth: 4,
          isStrokeCapRound: true,
          dotData: FlDotData(
            show: true,
            getDotPainter: (spot, percent, barData, index) => FlDotCirclePainter(
              radius: 4,
              color: mainColor,
              strokeWidth: 2,
              strokeColor: const Color(0xFF161616),
            ),
          ),
          belowBarData: BarAreaData(
            show: true,
            gradient: LinearGradient(
              colors: [mainColor.withOpacity(0.3), mainColor.withOpacity(0.0)],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
        ),
      ],
    );
  }

  Color _getColorForType(String type) {
    switch (type) {
      case 'Protein': return const Color(0xFFFF512F);
      case 'Carbs': return const Color(0xFFF2C94C);
      case 'Fats': return const Color(0xFF38EF7D);
      case 'Water': return const Color(0xFF00B4DB);
      case 'Weight': return const Color(0xFFD4AF37);
      default: return const Color(0xFFFFD700);
    }
  }

  Widget _buildWeightSummaryCard() {
    if (_weightData.isEmpty) return _buildTipsCard();

    final latest = _weightData.last;
    final first = _weightData.first;
    final delta = latest.weight - first.weight;
    final isLoss = delta < 0;

    return Container(
      padding: const EdgeInsets.all(20.0),
      decoration: BoxDecoration(
        color: const Color(0xFF161616),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFD4AF37).withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.analytics_outlined, color: Color(0xFFD4AF37)),
              SizedBox(width: 10),
              Text('Ringkasan Progress',
                  style: TextStyle(
                      fontWeight: FontWeight.bold, color: Color(0xFFF0E6C8))),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _buildWeightStat('Pertama', '${first.weight.toStringAsFixed(1)} kg', first.date),
              _buildWeightStatDivider(),
              _buildWeightStat('Terbaru', '${latest.weight.toStringAsFixed(1)} kg', latest.date),
              _buildWeightStatDivider(),
              _buildWeightStat(
                'Perubahan',
                '${isLoss ? '' : '+'}${delta.toStringAsFixed(1)} kg',
                '${_weightData.length} entri',
                color: isLoss ? const Color(0xFF38EF7D) : const Color(0xFFCF6679),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildWeightStat(String label, String value, String sub, {Color? color}) {
    return Expanded(
      child: Column(
        children: [
          Text(label,
              style: const TextStyle(color: Color(0xFF665C44), fontSize: 11)),
          const SizedBox(height: 4),
          Text(value,
              style: TextStyle(
                color: color ?? const Color(0xFFF0E6C8),
                fontSize: 15,
                fontWeight: FontWeight.bold,
              )),
          Text(sub,
              style: const TextStyle(color: Color(0xFF665C44), fontSize: 10)),
        ],
      ),
    );
  }

  Widget _buildWeightStatDivider() {
    return Container(
      width: 1,
      height: 40,
      color: Colors.white.withOpacity(0.08),
      margin: const EdgeInsets.symmetric(horizontal: 8),
    );
  }

  Widget _buildTipsCard() {
    return Container(
      padding: const EdgeInsets.all(20.0),
      decoration: BoxDecoration(
        color: const Color(0xFF161616),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _getColorForType(_selectedType).withOpacity(0.2)),
      ),
      child: Row(
        children: [
          Icon(Icons.lightbulb_outline, color: _getColorForType(_selectedType)),
          const SizedBox(width: 16),
          const Expanded(
            child: Text(
              'Konsistensi adalah kunci. Pastikan asupan makro Anda tidak berfluktuasi terlalu tajam setiap harinya.',
              style: TextStyle(color: Color(0xFFF0E6C8), fontSize: 13),
            ),
          )
        ],
      ),
    );
  }
}
