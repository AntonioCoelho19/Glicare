import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();

  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;

    _database = await _initDB('glicare.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    // await deleteDatabase(path);

    return await openDatabase(
      path,
      version: 3,
      onCreate: _createDB,
      onUpgrade: _upgradeDB,
    );
  }

  Future _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE registries (
        id TEXT PRIMARY KEY,
        glicemia REAL,
        insulinaCurta REAL,
        insulinaLonga REAL,
        date TEXT,
        medicationId TEXT,
        weight REAL,
        systolic INTEGER,
        diastolic INTEGER,
        activityName TEXT,
        activityDuration INTEGER,
        activityIntensity TEXT,
        caloriesBurned INTEGER,
        activityDescription TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE medications (
        id TEXT PRIMARY KEY,
        name TEXT,
        dosage REAL,
        unit TEXT,
        timesPerDay INTEGER,
        startDate TEXT,
        durationDays INTEGER
      )
    ''');

    await db.execute('''
      CREATE TABLE meals (
        id TEXT PRIMARY KEY,
        type TEXT NOT NULL,
        date TEXT NOT NULL,
        imagePath TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE meal_items (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        meal_id TEXT,
        name TEXT,
        portion TEXT,
        nutrition TEXT,
        FOREIGN KEY (meal_id) REFERENCES meals(id) ON DELETE CASCADE
      )
    ''');
  }

  Future<void> _upgradeDB(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.execute('ALTER TABLE registries ADD COLUMN insulinaCurta REAL');
      await db.execute('ALTER TABLE registries ADD COLUMN insulinaLonga REAL');
    }
    if (oldVersion < 3) {
      await db.execute('ALTER TABLE registries ADD COLUMN weight REAL');
      await db.execute('ALTER TABLE registries ADD COLUMN systolic INTEGER');
      await db.execute('ALTER TABLE registries ADD COLUMN diastolic INTEGER');
      await db.execute('ALTER TABLE registries ADD COLUMN activityName TEXT');
      await db.execute(
        'ALTER TABLE registries ADD COLUMN activityDuration INTEGER',
      );
      await db.execute(
        'ALTER TABLE registries ADD COLUMN activityIntensity TEXT',
      );
      await db.execute(
        'ALTER TABLE registries ADD COLUMN caloriesBurned INTEGER',
      );
      await db.execute(
        'ALTER TABLE registries ADD COLUMN activityDescription TEXT',
      );
    }
  }

  Future<void> deleteDatabaseFile() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'glicare.db');
    await deleteDatabase(path);
    _database = null;
  }
}
