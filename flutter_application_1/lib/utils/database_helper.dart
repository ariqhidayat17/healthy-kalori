import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/calorie_entry.dart';
import '../models/workout_entry.dart';
import '../models/weight_entry.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('calories.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(
      path,
      version: 5,
      onCreate: _createDB,
      onUpgrade: _upgradeDB,
    );
  }

  Future<void> _createDB(Database db, int version) async {
    const defaultType = 'TEXT NOT NULL';
    const integerType = 'INTEGER NOT NULL';

    await db.execute('''
CREATE TABLE daily_food_logs (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  date $defaultType,
  foodName $defaultType,
  calories $integerType,
  protein INTEGER DEFAULT 0,
  carbs INTEGER DEFAULT 0,
  fats INTEGER DEFAULT 0
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
  }

  Future<void> _upgradeDB(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.execute('ALTER TABLE daily_food_logs ADD COLUMN protein INTEGER DEFAULT 0');
      await db.execute('ALTER TABLE daily_food_logs ADD COLUMN carbs INTEGER DEFAULT 0');
      await db.execute('ALTER TABLE daily_food_logs ADD COLUMN fats INTEGER DEFAULT 0');
    }
    if (oldVersion < 3) {
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
    }
    if (oldVersion < 4) {
      await db.execute('''
        CREATE TABLE water_logs (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          date TEXT NOT NULL,
          amount INTEGER NOT NULL
        )
      ''');
    }
    if (oldVersion < 5) {
      await db.execute('''
        CREATE TABLE weight_logs (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          date TEXT NOT NULL,
          weight REAL NOT NULL,
          note TEXT DEFAULT ''
        )
      ''');
    }
  }

  Future<int> insertFood(CalorieEntry entry) async {
    final db = await instance.database;
    return await db.insert('daily_food_logs', entry.toMap());
  }

  Future<List<CalorieEntry>> getFoodsByDate(String date) async {
    final db = await instance.database;
    final maps = await db.query(
      'daily_food_logs',
      where: 'date = ?',
      whereArgs: [date],
    );

    if (maps.isNotEmpty) {
      return maps.map((map) => CalorieEntry.fromMap(map)).toList();
    } else {
      return [];
    }
  }

  Future<int> deleteFood(int id) async {
    final db = await instance.database;
    return await db.delete(
      'daily_food_logs',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<int> updateFood(CalorieEntry entry) async {
    final db = await instance.database;
    return await db.update(
      'daily_food_logs',
      entry.toMap(),
      where: 'id = ?',
      whereArgs: [entry.id],
    );
  }

  Future<int> getTotalCaloriesByDate(String date) async {
    final db = await instance.database;
    final result = await db.rawQuery(
      'SELECT SUM(calories) as total FROM daily_food_logs WHERE date = ?',
      [date],
    );
    
    if (result.first['total'] != null) {
      return result.first['total'] as int;
    }
    return 0;
  }

  Future<Map<String, int>> getTotalMacrosByDate(String date) async {
    final db = await instance.database;
    final result = await db.rawQuery(
      'SELECT SUM(protein) as protein, SUM(carbs) as carbs, SUM(fats) as fats FROM daily_food_logs WHERE date = ?',
      [date],
    );
    
    if (result.isNotEmpty && result.first['protein'] != null) {
      return {
        'protein': (result.first['protein'] as num).toInt(),
        'carbs': (result.first['carbs'] as num).toInt(),
        'fats': (result.first['fats'] as num).toInt(),
      };
    }
    return {'protein': 0, 'carbs': 0, 'fats': 0};
  }

  // --- CRUD WORKOUT LOGS ---
  
  Future<int> insertWorkout(WorkoutEntry entry) async {
    final db = await instance.database;
    try {
      return await db.insert('workout_logs', entry.toMap());
    } catch (e) {
      await db.execute('''
        CREATE TABLE IF NOT EXISTS workout_logs (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          date TEXT NOT NULL,
          exerciseName TEXT NOT NULL,
          sets INTEGER NOT NULL,
          reps INTEGER NOT NULL,
          weight REAL NOT NULL
        )
      ''');
      return await db.insert('workout_logs', entry.toMap());
    }
  }

  Future<List<WorkoutEntry>> getWorkoutsByDate(String date) async {
    final db = await instance.database;
    try {
      final maps = await db.query(
        'workout_logs',
        where: 'date = ?',
        whereArgs: [date],
      );

      if (maps.isNotEmpty) {
        return maps.map((map) => WorkoutEntry.fromMap(map)).toList();
      } else {
        return [];
      }
    } catch (e) {
      // Jika tabel belum ada karena bug versi sebelumnya, buat paksa
      await db.execute('''
        CREATE TABLE IF NOT EXISTS workout_logs (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          date TEXT NOT NULL,
          exerciseName TEXT NOT NULL,
          sets INTEGER NOT NULL,
          reps INTEGER NOT NULL,
          weight REAL NOT NULL
        )
      ''');
      return [];
    }
  }

  Future<int> deleteWorkout(int id) async {
    final db = await instance.database;
    return await db.delete(
      'workout_logs',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // --- CRUD WATER LOGS ---

  Future<int> insertWater(String date, int amount) async {
    final db = await instance.database;
    return await db.insert('water_logs', {
      'date': date,
      'amount': amount,
    });
  }

  Future<int> getTotalWaterByDate(String date) async {
    final db = await instance.database;
    final result = await db.rawQuery(
      'SELECT SUM(amount) as total FROM water_logs WHERE date = ?',
      [date],
    );
    
    if (result.isNotEmpty && result.first['total'] != null) {
      return (result.first['total'] as num).toInt();
    }
    return 0;
  }

  Future<void> deleteLastWaterEntry(String date) async {
    final db = await instance.database;
    // Hapus entry air terakhir pada tanggal tersebut
    final lastEntry = await db.query(
      'water_logs',
      where: 'date = ?',
      whereArgs: [date],
      orderBy: 'id DESC',
      limit: 1,
    );
    
    if (lastEntry.isNotEmpty) {
      final id = lastEntry.first['id'];
      await db.delete('water_logs', where: 'id = ?', whereArgs: [id]);
    }
  }

  // --- CRUD WEIGHT LOGS ---

  Future<int> insertWeight(WeightEntry entry) async {
    final db = await instance.database;
    return await db.insert('weight_logs', entry.toMap());
  }

  Future<int> updateWeight(WeightEntry entry) async {
    final db = await instance.database;
    return await db.update(
      'weight_logs',
      entry.toMap(),
      where: 'id = ?',
      whereArgs: [entry.id],
    );
  }

  Future<int> deleteWeight(int id) async {
    final db = await instance.database;
    return await db.delete('weight_logs', where: 'id = ?', whereArgs: [id]);
  }

  /// Ambil semua riwayat berat badan, diurutkan dari terbaru
  Future<List<WeightEntry>> getWeightHistory() async {
    final db = await instance.database;
    final maps = await db.query(
      'weight_logs',
      orderBy: 'id DESC',
    );
    return maps.map((m) => WeightEntry.fromMap(m)).toList();
  }

  /// Ambil berat badan terbaru (untuk ditampilkan di beranda/stats)
  Future<WeightEntry?> getLatestWeight() async {
    final db = await instance.database;
    final maps = await db.query(
      'weight_logs',
      orderBy: 'id DESC',
      limit: 1,
    );
    if (maps.isNotEmpty) return WeightEntry.fromMap(maps.first);
    return null;
  }

  /// Ambil N entri terakhir untuk chart di StatsScreen
  Future<List<WeightEntry>> getWeightForChart({int limit = 14}) async {
    final db = await instance.database;
    final maps = await db.query(
      'weight_logs',
      orderBy: 'id ASC',
      limit: limit,
    );
    return maps.map((m) => WeightEntry.fromMap(m)).toList();
  }
}

