import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../utils/prefs_service.dart';
import '../utils/database_helper.dart';

class BackupService {
  static Future<void> exportDataAsJson(BuildContext context) async {
    try {
      final prefs = PrefsService.i.raw;
      
      // Ambil data SharedPreferences
      final prefsData = {
        'name': prefs.getString('name'),
        'age': prefs.getInt('age'),
        'weight': prefs.getDouble('weight'),
        'height': prefs.getDouble('height'),
        'gender': prefs.getString('gender'),
        'activity_level': prefs.getString('activity_level'),
        'goal': prefs.getString('goal'),
        'target_calories': prefs.getInt('target_calories'),
        'target_protein': prefs.getInt('target_protein'),
        'target_carbs': prefs.getInt('target_carbs'),
        'target_fats': prefs.getInt('target_fats'),
        'target_water': prefs.getInt('target_water'),
        'notifications_enabled': prefs.getBool('notifications_enabled'),
        'ai_chat_history': prefs.getString('ai_chat_history'),
      };

      // Ambil seluruh data SQLite
      final db = await DatabaseHelper.instance.database;
      final foodsData = await db.query('daily_food_logs');
      final waterData = await db.query('water_logs');
      final weightHistoryData = await db.query('weight_logs');

      // Satukan ke dalam satu JSON besar
      final backupData = {
        'version': '1.0',
        'export_date': DateTime.now().toIso8601String(),
        'preferences': prefsData,
        'sqlite': {
          'daily_food_logs': foodsData,
          'water_logs': waterData,
          'weight_logs': weightHistoryData,
        }
      };

      final jsonString = jsonEncode(backupData);

      // Simpan ke file lokal sementara
      final output = await getTemporaryDirectory();
      final username = (prefsData['name'] as String?)?.replaceAll(' ', '_') ?? 'User';
      final file = File('${output.path}/Backup_Data_$username.json');
      
      await file.writeAsString(jsonString);

      if (context.mounted) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        // Tampilkan popup Share
        final size = MediaQuery.of(context).size;
        await Share.shareXFiles(
          [XFile(file.path)],
          text: 'Ini adalah file backup raw data JSON dari Your AI Coach saya.',
          sharePositionOrigin: Rect.fromLTWH(0, 0, size.width, size.height / 2),
        );
      }

    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal mencadangkan data: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }
}
