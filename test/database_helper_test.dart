import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:healthy_calories/models/calorie_entry.dart';
import 'package:healthy_calories/models/workout_entry.dart';
import 'package:healthy_calories/models/weight_entry.dart';

/// Test untuk DatabaseHelper.
///
/// Menggunakan sqflite_common_ffi + in-memory database agar test berjalan
/// di CI tanpa perangkat fisik / emulator.
///
/// Setup pubspec.yaml (dev_dependencies):
///   sqflite_common_ffi: ^2.3.0
///
/// Jalankan dengan:
///   flutter test test/database_helper_test.dart

// ── In-memory DB helper (tidak bergantung singleton DatabaseHelper) ─────────

Future<Database> _openTestDb() async {
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;

  final db = await databaseFactory.openDatabase(
    inMemoryDatabasePath,
    options: OpenDatabaseOptions(
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE daily_food_logs (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            date TEXT NOT NULL,
            foodName TEXT NOT NULL,
            calories INTEGER NOT NULL,
            protein INTEGER DEFAULT 0,
            carbs INTEGER DEFAULT 0,
            fats INTEGER DEFAULT 0,
            mealTime TEXT DEFAULT 'Breakfast',
            rarity TEXT DEFAULT 'Common'
          )
        ''');
        await db.execute('''
          CREATE TABLE workout_logs (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            date TEXT NOT NULL,
            exerciseName TEXT NOT NULL,
            sets INTEGER NOT NULL,
            reps INTEGER NOT NULL,
            weight REAL NOT NULL
          )
        ''');
        await db.execute('''
          CREATE TABLE water_logs (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            date TEXT NOT NULL,
            amount INTEGER NOT NULL
          )
        ''');
        await db.execute('''
          CREATE TABLE weight_logs (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            date TEXT NOT NULL,
            weight REAL NOT NULL,
            note TEXT DEFAULT ''
          )
        ''');
      },
    ),
  );
  return db;
}

// ── Helpers ──────────────────────────────────────────────────────────────────

CalorieEntry makeFood({
  String date = '01/06/2025',
  String name = 'Nasi Putih',
  int cal = 200,
  int prot = 5,
  int carbs = 40,
  int fats = 1,
}) =>
    CalorieEntry(
      date: date,
      foodName: name,
      calories: cal,
      protein: prot,
      carbs: carbs,
      fats: fats,
    );

// ── Tests ─────────────────────────────────────────────────────────────────────

void main() {
  late Database db;

  setUp(() async => db = await _openTestDb());
  tearDown(() async => await db.close());

  // ─── daily_food_logs ────────────────────────────────────────────────────

  group('daily_food_logs — insert & query', () {
    test('Insert dan query by date mengembalikan data yang sama', () async {
      final entry = makeFood();
      await db.insert('daily_food_logs', entry.toMap()..remove('id'));
      final rows = await db.query('daily_food_logs',
          where: 'date = ?', whereArgs: ['01/06/2025']);
      expect(rows.length, equals(1));
      expect(rows.first['foodName'], equals('Nasi Putih'));
      expect(rows.first['calories'], equals(200));
    });

    test('Query tanggal berbeda tidak cross-contaminate', () async {
      await db.insert('daily_food_logs',
          makeFood(date: '01/06/2025', name: 'A').toMap()..remove('id'));
      await db.insert('daily_food_logs',
          makeFood(date: '02/06/2025', name: 'B').toMap()..remove('id'));
      final rows = await db.query('daily_food_logs',
          where: 'date = ?', whereArgs: ['01/06/2025']);
      expect(rows.length, equals(1));
      expect(rows.first['foodName'], equals('A'));
    });

    test('Multiple entries pada tanggal sama semuanya ter-query', () async {
      for (int i = 0; i < 3; i++) {
        await db.insert('daily_food_logs',
            makeFood(name: 'Food $i').toMap()..remove('id'));
      }
      final rows = await db.query('daily_food_logs',
          where: 'date = ?', whereArgs: ['01/06/2025']);
      expect(rows.length, equals(3));
    });

    test('Delete by id menghapus hanya entry yang dimaksud', () async {
      final id1 = await db.insert('daily_food_logs',
          makeFood(name: 'Hapus ini').toMap()..remove('id'));
      await db.insert('daily_food_logs',
          makeFood(name: 'Jangan hapus').toMap()..remove('id'));
      await db.delete('daily_food_logs', where: 'id = ?', whereArgs: [id1]);
      final rows = await db.query('daily_food_logs');
      expect(rows.length, equals(1));
      expect(rows.first['foodName'], equals('Jangan hapus'));
    });
  });

  group('daily_food_logs — agregasi kalori & makro', () {
    test('SUM kalori hanya untuk tanggal yang diminta', () async {
      await db.insert('daily_food_logs',
          makeFood(date: '01/06/2025', cal: 300).toMap()..remove('id'));
      await db.insert('daily_food_logs',
          makeFood(date: '01/06/2025', cal: 500).toMap()..remove('id'));
      await db.insert('daily_food_logs',
          makeFood(date: '02/06/2025', cal: 999).toMap()..remove('id'));

      final result = await db.rawQuery(
          'SELECT COALESCE(SUM(calories),0) AS total FROM daily_food_logs WHERE date=?',
          ['01/06/2025']);
      expect((result.first['total'] as num).toInt(), equals(800));
    });

    test('SUM protein dan carbs dihitung benar', () async {
      await db.insert('daily_food_logs',
          makeFood(prot: 30, carbs: 50, fats: 10).toMap()..remove('id'));
      await db.insert('daily_food_logs',
          makeFood(prot: 20, carbs: 30, fats: 5).toMap()..remove('id'));

      final result = await db.rawQuery(
          'SELECT SUM(protein) AS p, SUM(carbs) AS c, SUM(fats) AS f '
          'FROM daily_food_logs WHERE date=?',
          ['01/06/2025']);
      expect((result.first['p'] as num).toInt(), equals(50));
      expect((result.first['c'] as num).toInt(), equals(80));
      expect((result.first['f'] as num).toInt(), equals(15));
    });

    test('Query tanggal tanpa data → SUM = 0', () async {
      final result = await db.rawQuery(
          'SELECT COALESCE(SUM(calories),0) AS total FROM daily_food_logs WHERE date=?',
          ['31/12/2099']);
      expect((result.first['total'] as num).toInt(), equals(0));
    });
  });

  // ─── water_logs ──────────────────────────────────────────────────────────

  group('water_logs', () {
    test('Insert dan SUM air pada tanggal yang sama', () async {
      for (final amount in [250, 250, 500]) {
        await db.insert('water_logs', {'date': '01/06/2025', 'amount': amount});
      }
      final result = await db.rawQuery(
          'SELECT COALESCE(SUM(amount),0) AS total FROM water_logs WHERE date=?',
          ['01/06/2025']);
      expect((result.first['total'] as num).toInt(), equals(1000));
    });

    test('Delete entri terakhir mengurangi total air', () async {
      await db.insert('water_logs', {'date': '01/06/2025', 'amount': 250});
      final lastId = await db.insert(
          'water_logs', {'date': '01/06/2025', 'amount': 500});
      await db.delete('water_logs', where: 'id = ?', whereArgs: [lastId]);
      final rows =
          await db.query('water_logs', where: 'date = ?', whereArgs: ['01/06/2025']);
      expect(rows.length, equals(1));
      expect(rows.first['amount'], equals(250));
    });

    test('Total air 0 jika tidak ada entri', () async {
      final result = await db.rawQuery(
          'SELECT COALESCE(SUM(amount),0) AS total FROM water_logs WHERE date=?',
          ['01/01/2099']);
      expect((result.first['total'] as num).toInt(), equals(0));
    });
  });

  // ─── weight_logs ─────────────────────────────────────────────────────────

  group('weight_logs', () {
    test('Insert berat dan ambil entri terbaru', () async {
      await db.insert('weight_logs',
          {'date': '01/06/2025', 'weight': 79.5, 'note': ''});
      await db.insert('weight_logs',
          {'date': '02/06/2025', 'weight': 79.2, 'note': ''});
      final rows = await db.query('weight_logs',
          orderBy: 'id DESC', limit: 1);
      expect((rows.first['weight'] as num).toDouble(), equals(79.2));
    });

    test('ORDER BY date ASC menghasilkan urutan kronologis', () async {
      // Insert out-of-order
      await db.insert('weight_logs',
          {'date': '03/06/2025', 'weight': 80.0, 'note': ''});
      await db.insert('weight_logs',
          {'date': '01/06/2025', 'weight': 82.0, 'note': ''});
      await db.insert('weight_logs',
          {'date': '02/06/2025', 'weight': 81.0, 'note': ''});

      final rows = await db.query('weight_logs', orderBy: 'date ASC');
      final weights = rows.map((r) => (r['weight'] as num).toDouble()).toList();
      expect(weights, equals([82.0, 81.0, 80.0]));
    });

    test('Update berat mengubah nilai yang tersimpan', () async {
      final id = await db.insert('weight_logs',
          {'date': '01/06/2025', 'weight': 80.0, 'note': ''});
      await db.update('weight_logs', {'weight': 79.5},
          where: 'id = ?', whereArgs: [id]);
      final rows = await db.query('weight_logs',
          where: 'id = ?', whereArgs: [id]);
      expect((rows.first['weight'] as num).toDouble(), equals(79.5));
    });

    test('Delete by id berhasil', () async {
      final id = await db.insert('weight_logs',
          {'date': '01/06/2025', 'weight': 80.0, 'note': ''});
      await db.delete('weight_logs', where: 'id = ?', whereArgs: [id]);
      final rows = await db.query('weight_logs');
      expect(rows, isEmpty);
    });
  });

  // ─── workout_logs ─────────────────────────────────────────────────────────

  group('workout_logs', () {
    test('Insert workout dan query by date', () async {
      final entry = WorkoutEntry(
        date: '01/06/2025',
        exerciseName: 'Bench Press',
        sets: 4,
        reps: 8,
        weight: 80.0,
      );
      await db.insert('workout_logs', entry.toMap()..remove('id'));
      final rows = await db.query('workout_logs',
          where: 'date = ?', whereArgs: ['01/06/2025']);
      expect(rows.length, equals(1));
      expect(rows.first['exerciseName'], equals('Bench Press'));
    });

    test('COUNT DISTINCT date untuk 7 hari dihitung benar', () async {
      final dates = ['01/06/2025', '01/06/2025', '02/06/2025', '04/06/2025'];
      for (final d in dates) {
        await db.insert('workout_logs', {
          'date': d,
          'exerciseName': 'Squat',
          'sets': 3, 'reps': 10, 'weight': 60.0,
        });
      }
      final result = await db.rawQuery('''
        SELECT COUNT(DISTINCT date) AS count FROM workout_logs
        WHERE date IN (?,?,?,?,?,?,?)
      ''', ['01/06/2025', '02/06/2025', '03/06/2025', '04/06/2025',
            '05/06/2025', '06/06/2025', '07/06/2025']);
      // 3 tanggal unik: 01, 02, 04
      expect((result.first['count'] as num).toInt(), equals(3));
    });
  });

  // ─── Integritas antar tabel ───────────────────────────────────────────────

  group('Integritas data lintas tabel', () {
    test('Delete food tidak mempengaruhi water_logs', () async {
      final foodId = await db.insert('daily_food_logs',
          makeFood().toMap()..remove('id'));
      await db.insert('water_logs', {'date': '01/06/2025', 'amount': 500});
      await db.delete('daily_food_logs', where: 'id = ?', whereArgs: [foodId]);
      final waterRows = await db.query('water_logs');
      expect(waterRows.length, equals(1));
    });

    test('Tabel kosong pada tanggal berbeda mengembalikan list kosong', () async {
      await db.insert('daily_food_logs',
          makeFood(date: '01/06/2025').toMap()..remove('id'));
      final rows = await db.query('daily_food_logs',
          where: 'date = ?', whereArgs: ['15/06/2025']);
      expect(rows, isEmpty);
    });
  });
}
