import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:dose/models/cabinet_model.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('dose.db');
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

  Future _createDB(Database db, int version) async {
    const idType = 'INTEGER PRIMARY KEY AUTOINCREMENT';
    const textType = 'TEXT NOT NULL';
    const integerType = 'INTEGER NOT NULL';

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
  }

  Future _upgradeDB(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.execute(
        "ALTER TABLE cabinet ADD COLUMN category TEXT NOT NULL DEFAULT 'tablet'",
      );
      await db.execute(
        "ALTER TABLE cabinet ADD COLUMN unit TEXT NOT NULL DEFAULT 'pills'",
      );
    }
  }

  static const String _ensureTable = '''
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
  ''';

  Future<int> createMedicine(Cabinet cabinet) async {
    final db = await instance.database;
    await db.execute(_ensureTable);
    return await db.insert('cabinet', cabinet.toMap());
  }

  Future<Cabinet?> readMedicine(int id) async {
    final db = await instance.database;
    await db.execute(_ensureTable);
    final maps = await db.query('cabinet', where: 'id = ?', whereArgs: [id]);

    if (maps.isNotEmpty) {
      return Cabinet.fromMap(maps.first);
    }
    return null;
  }

  Future<List<Cabinet>> readAllMedicines() async {
    final db = await instance.database;
    await db.execute(_ensureTable);
    const orderBy = 'time ASC';
    final result = await db.query('cabinet', orderBy: orderBy);
    return result.map((json) => Cabinet.fromMap(json)).toList();
  }

  Future<int> updateMedicine(Cabinet medicine) async {
    final db = await instance.database;
    await db.execute(_ensureTable);
    return await db.update(
      'cabinet',
      medicine.toMap(),
      where: 'id = ?',
      whereArgs: [medicine.id],
    );
  }

  Future<int> deleteMedicine(int id) async {
    final db = await instance.database;
    await db.execute(_ensureTable);
    return await db.delete('cabinet', where: 'id = ?', whereArgs: [id]);
  }
}
