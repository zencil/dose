import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:app/models/cabinet_model.dart';

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

    return await openDatabase(path, version: 1, onCreate: _createDB);
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
  priority $integerType
  )
''');
  }

  Future<int> createMedicine(Cabinet cabinet) async {
    final db = await instance.database;
    await db.execute('''
      CREATE TABLE IF NOT EXISTS cabinet ( 
        id INTEGER PRIMARY KEY AUTOINCREMENT, 
        name TEXT NOT NULL,
        dosage TEXT NOT NULL,
        time TEXT NOT NULL,
        currstock INTEGER NOT NULL,
        initstock INTEGER NOT NULL,
        priority INTEGER NOT NULL
      )
    ''');
    return await db.insert('cabinet', cabinet.toMap());
  }

  Future<Cabinet?> readMedicine(int id) async {
    final db = await instance.database;
    await db.execute('''
      CREATE TABLE IF NOT EXISTS cabinet ( 
        id INTEGER PRIMARY KEY AUTOINCREMENT, 
        name TEXT NOT NULL,
        dosage TEXT NOT NULL,
        time TEXT NOT NULL,
        currstock INTEGER NOT NULL,
        initstock INTEGER NOT NULL,
        priority INTEGER NOT NULL
      )
    ''');
    final maps = await db.query('cabinet', where: 'id = ?', whereArgs: [id]);

    if (maps.isNotEmpty) {
      return Cabinet.fromMap(maps.first);
    }
    return null;
  }

  Future<List<Cabinet>> readAllMedicines() async {
    final db = await instance.database;
    await db.execute('''
      CREATE TABLE IF NOT EXISTS cabinet ( 
        id INTEGER PRIMARY KEY AUTOINCREMENT, 
        name TEXT NOT NULL,
        dosage TEXT NOT NULL,
        time TEXT NOT NULL,
        currstock INTEGER NOT NULL,
        initstock INTEGER NOT NULL,
        priority INTEGER NOT NULL
      )
    ''');
    const orderBy = 'time ASC';
    final result = await db.query('cabinet', orderBy: orderBy);
    return result.map((json) => Cabinet.fromMap(json)).toList();
  }

  Future<int> updateMedicine(Cabinet medicine) async {
    final db = await instance.database;
    await db.execute('''
      CREATE TABLE IF NOT EXISTS cabinet ( 
        id INTEGER PRIMARY KEY AUTOINCREMENT, 
        name TEXT NOT NULL,
        dosage TEXT NOT NULL,
        time TEXT NOT NULL,
        currstock INTEGER NOT NULL,
        initstock INTEGER NOT NULL,
        priority INTEGER NOT NULL
      )
    ''');
    return await db.update(
      'cabinet',
      medicine.toMap(),
      where: 'id = ?',
      whereArgs: [medicine.id],
    );
  }

  Future<int> deleteMedicine(int id) async {
    final db = await instance.database;
    await db.execute('''
      CREATE TABLE IF NOT EXISTS cabinet ( 
        id INTEGER PRIMARY KEY AUTOINCREMENT, 
        name TEXT NOT NULL,
        dosage TEXT NOT NULL,
        time TEXT NOT NULL,
        currstock INTEGER NOT NULL,
        initstock INTEGER NOT NULL,
        priority INTEGER NOT NULL
      )
    ''');
    return await db.delete('cabinet', where: 'id = ?', whereArgs: [id]);
  }
}
