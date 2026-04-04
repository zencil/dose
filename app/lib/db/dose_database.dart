import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'dart:io';

class DoseDatabase {
  static final DoseDatabase instance = DoseDatabase._init();
  static Database? _database;

  DoseDatabase._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('dose.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    final db = await openDatabase(
      path,
      version: 2,
      onCreate: _createDB,
      onUpgrade: _upgradeDB,
    );

    // Check if legacy intake_log.db exists and needs migration
    final legacyPath = join(dbPath, 'intake_log.db');
    final legacyFile = File(legacyPath);
    if (await legacyFile.exists()) {
      await _migrateLegacyIntakeLog(db, legacyPath);
    }

    return db;
  }

  Future _createDB(Database db, int version) async {
    const idType = 'INTEGER PRIMARY KEY AUTOINCREMENT';
    const textType = 'TEXT NOT NULL';
    const integerType = 'INTEGER NOT NULL';

    // Cabinet Table
    await db.execute('''
      CREATE TABLE cabinet ( 
        id $idType, 
        name $textType,
        dosage $textType,
        time $textType,
        currstock $integerType,
        initstock $integerType,
        priority $integerType,
        category $textType DEFAULT 'tablet',
        unit $textType DEFAULT 'pills'
      )
    ''');

    // Profile Table
    await db.execute('''
      CREATE TABLE profile ( 
        id $idType, 
        name $textType,
        donor $textType,
        dob $textType,
        bloodtype $textType,
        sex $textType
      )
    ''');

    // Intake Log Table
    await db.execute('''
      CREATE TABLE intake_log ( 
        id $idType, 
        name $textType,
        ttime $textType,
        time $textType,
        date $textType,
        currstock $integerType
      )
    ''');
  }

  Future _upgradeDB(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      // It's possible dose.db was created purely by profile_db or cabinet_db.
      // We safely ensure all tables exist with their latest schemas.

      await db.execute('''
        CREATE TABLE IF NOT EXISTS cabinet ( 
          id INTEGER PRIMARY KEY AUTOINCREMENT, 
          name TEXT NOT NULL,
          dosage TEXT NOT NULL,
          time TEXT NOT NULL,
          currstock INTEGER NOT NULL,
          initstock INTEGER NOT NULL,
          priority INTEGER NOT NULL,
          category TEXT NOT NULL DEFAULT 'tablet',
          unit TEXT NOT NULL DEFAULT 'pills'
        )
      ''');

      // If cabinet already existed from v1, we alter it for Category/Unit.
      // Catching the error gracefully handles if the table was newly created.
      try {
        await db.execute(
          "ALTER TABLE cabinet ADD COLUMN category TEXT NOT NULL DEFAULT 'tablet'",
        );
      } catch (_) {}

      try {
        await db.execute(
          "ALTER TABLE cabinet ADD COLUMN unit TEXT NOT NULL DEFAULT 'pills'",
        );
      } catch (_) {}

      await db.execute('''
        CREATE TABLE IF NOT EXISTS profile ( 
          id INTEGER PRIMARY KEY AUTOINCREMENT, 
          name TEXT NOT NULL,
          donor TEXT NOT NULL,
          dob TEXT NOT NULL,
          bloodtype TEXT NOT NULL,
          sex TEXT NOT NULL
        )
      ''');

      await db.execute('''
        CREATE TABLE IF NOT EXISTS intake_log ( 
          id INTEGER PRIMARY KEY AUTOINCREMENT, 
          name TEXT NOT NULL,
          ttime TEXT NOT NULL,
          time TEXT NOT NULL,
          date TEXT NOT NULL,
          currstock INTEGER NOT NULL
        )
      ''');
    }
  }

  Future<void> _migrateLegacyIntakeLog(
    Database newDb,
    String legacyPath,
  ) async {
    try {
      final oldDb = await openDatabase(legacyPath);
      final logs = await oldDb.query('intake_log');

      for (final log in logs) {
        // Insert old logs into new combined dose.db
        await newDb.insert(
          'intake_log',
          log,
          conflictAlgorithm: ConflictAlgorithm.ignore,
        );
      }

      await oldDb.close();
      final file = File(legacyPath);
      await file.delete();
    } catch (_) {
      // Fail silently for migrations so it doesn't crash app startup
    }
  }
}
