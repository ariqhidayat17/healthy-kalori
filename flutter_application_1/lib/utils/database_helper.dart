import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/calorie_entry.dart';

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
      version: 2,
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
  }

  Future<void> _upgradeDB(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.execute('ALTER TABLE daily_food_logs ADD COLUMN protein INTEGER DEFAULT 0');
      await db.execute('ALTER TABLE daily_food_logs ADD COLUMN carbs INTEGER DEFAULT 0');
      await db.execute('ALTER TABLE daily_food_logs ADD COLUMN fats INTEGER DEFAULT 0');
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
}
