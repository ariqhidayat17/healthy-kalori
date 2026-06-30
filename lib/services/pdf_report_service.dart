import 'dart:io';
import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:intl/intl.dart';
import '../utils/prefs_service.dart';
import '../utils/database_helper.dart';

class PdfReportService {
  static Future<void> generateAndShareWeeklyReport(BuildContext context) async {
    try {
      final pdf = pw.Document();
    
    // Tarik data profil
    final prefs = PrefsService.i.raw;
    final name = prefs.getString('name') ?? 'Pengguna';
    final weight = prefs.getDouble('weight') ?? 0.0;
    final goal = prefs.getString('goal') ?? 'Tidak diketahui';

    // Tarik data 7 hari terakhir
    List<Map<String, dynamic>> weeklyData = [];
    double totalCal = 0;
    int dataCount = 0;

    for (int i = 6; i >= 0; i--) {
      final date = DateTime.now().subtract(Duration(days: i));
      final dateStr = DateFormat('dd/MM/yyyy').format(date);
      final dayName = _getIndonesianDay(date.weekday);

      final cal = await DatabaseHelper.instance.getTotalCaloriesByDate(dateStr);
      final macros = await DatabaseHelper.instance.getTotalMacrosByDate(dateStr);
      
      weeklyData.add({
        'date': dateStr,
        'day': dayName,
        'cal': cal,
        'protein': macros['protein'] ?? 0,
        'carbs': macros['carbs'] ?? 0,
        'fats': macros['fats'] ?? 0,
      });

      if (cal > 0) {
        totalCal += cal;
        dataCount++;
      }
    }

    final avgCal = dataCount > 0 ? (totalCal / dataCount).round() : 0;

    // Build the PDF content
    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (pw.Context context) {
          return [
            _buildHeader(),
            pw.SizedBox(height: 20),
            _buildUserInfo(name, weight, goal, avgCal),
            pw.SizedBox(height: 30),
            pw.Text(
              'Ringkasan Nutrisi 7 Hari Terakhir',
              style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold, color: PdfColors.amber800),
            ),
            pw.SizedBox(height: 10),
            _buildDataTable(weeklyData),
            pw.SizedBox(height: 40),
            _buildFooter(),
          ];
        },
      ),
    );

    // Save and Share
      final output = await getTemporaryDirectory();
      final safeName = name.replaceAll(' ', '_');
      final file = File('${output.path}/Laporan_Kesehatan_$safeName.pdf');
      
      final bytes = await pdf.save();
      await file.writeAsBytes(bytes);
      
      if (context.mounted) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar(); // Sembunyikan loading
        
        // Get screen size to avoid iOS iPad/Share sheet crash
        final size = MediaQuery.of(context).size;
        
        await Share.shareXFiles(
          [XFile(file.path)], 
          text: 'Laporan Kebugaran & Nutrisi Mingguan Saya dari Your AI Coach!',
          sharePositionOrigin: Rect.fromLTWH(0, 0, size.width, size.height / 2),
        );
      }
    } catch (e) {
      debugPrint('Error generating PDF: $e');
      if (context.mounted) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal membuat PDF: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  static String _getIndonesianDay(int weekday) {
    switch (weekday) {
      case 1: return 'Senin';
      case 2: return 'Selasa';
      case 3: return 'Rabu';
      case 4: return 'Kamis';
      case 5: return 'Jumat';
      case 6: return 'Sabtu';
      case 7: return 'Minggu';
      default: return '';
    }
  }

  static pw.Widget _buildHeader() {
    return pw.Container(
      padding: const pw.EdgeInsets.all(20),
      decoration: pw.BoxDecoration(
        color: PdfColors.grey900,
        borderRadius: pw.BorderRadius.circular(10),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                'YOUR AI COACH',
                style: pw.TextStyle(
                  color: PdfColors.amberAccent,
                  fontSize: 24,
                  fontWeight: pw.FontWeight.bold,
                  letterSpacing: 2,
                ),
              ),
              pw.SizedBox(height: 4),
              pw.Text(
                'Laporan Kebugaran & Nutrisi Mingguan',
                style: const pw.TextStyle(
                  color: PdfColors.white,
                  fontSize: 14,
                ),
              ),
            ],
          ),
          pw.Container(
            padding: const pw.EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: pw.BoxDecoration(
              color: PdfColors.amber800,
              borderRadius: pw.BorderRadius.circular(20),
            ),
            child: pw.Text(
              DateFormat('dd MMM yyyy').format(DateTime.now()),
              style: pw.TextStyle(color: PdfColors.white, fontWeight: pw.FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  static pw.Widget _buildUserInfo(String name, double weight, String goal, int avgCal) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(15),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.grey300),
        borderRadius: pw.BorderRadius.circular(8),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
        children: [
          _buildInfoItem('Nama Pengguna', name),
          _buildInfoItem('Berat Saat Ini', '$weight kg'),
          _buildInfoItem('Target Fisik', goal),
          _buildInfoItem('Rata-rata Kalori', '$avgCal kcal/hari'),
        ],
      ),
    );
  }

  static pw.Widget _buildInfoItem(String title, String value) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(title, style: const pw.TextStyle(color: PdfColors.grey600, fontSize: 10)),
        pw.SizedBox(height: 4),
        pw.Text(value, style: pw.TextStyle(color: PdfColors.black, fontSize: 14, fontWeight: pw.FontWeight.bold)),
      ],
    );
  }

  static pw.Widget _buildDataTable(List<Map<String, dynamic>> data) {
    return pw.TableHelper.fromTextArray(
      context: null,
      border: pw.TableBorder.all(color: PdfColors.grey300, width: 1),
      headerDecoration: const pw.BoxDecoration(
        color: PdfColors.grey200,
      ),
      headerHeight: 40,
      cellHeight: 35,
      cellAlignments: {
        0: pw.Alignment.centerLeft,
        1: pw.Alignment.center,
        2: pw.Alignment.center,
        3: pw.Alignment.center,
        4: pw.Alignment.center,
      },
      headerStyle: pw.TextStyle(
        color: PdfColors.grey800,
        fontSize: 12,
        fontWeight: pw.FontWeight.bold,
      ),
      cellStyle: const pw.TextStyle(
        color: PdfColors.black,
        fontSize: 11,
      ),
      headers: ['Tanggal', 'Kalori (kcal)', 'Protein (g)', 'Karbo (g)', 'Lemak (g)'],
      data: data.map((item) {
        return [
          item['date'],
          item['cal'].toString(),
          item['protein'].toString(),
          item['carbs'].toString(),
          item['fats'].toString(),
        ];
      }).toList(),
    );
  }

  static pw.Widget _buildFooter() {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.center,
      children: [
        pw.Divider(color: PdfColors.grey300),
        pw.SizedBox(height: 10),
        pw.Text(
          '"Konsistensi adalah kunci. Tubuh impianmu dibangun dari apa yang kamu makan hari ini."',
          style: pw.TextStyle(fontStyle: pw.FontStyle.italic, color: PdfColors.grey600),
          textAlign: pw.TextAlign.center,
        ),
        pw.SizedBox(height: 5),
        pw.Text(
          'Dihasilkan secara otomatis oleh Aplikasi Your AI Coach.',
          style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey500),
        ),
      ],
    );
  }
}
