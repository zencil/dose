import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:dose/models/intake_model.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('intake_log.db');
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
CREATE TABLE intake_log ( 
  id $idType, 
  name $textType,
  ttime $textType,
  time $textType,
  date $textType,
  currstock $integerType
  )''');
  }

  Future<int> createlog(Intake intake) async {
    final db = await instance.database;
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
    return await db.insert('intake_log', intake.toMap());
  }

  Future<List<Intake>> readintakelog() async {
    final db = await instance.database;
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
    const orderBy = 'time ASC';
    final result = await db.query('intake_log', orderBy: orderBy);
    return result.map((json) => Intake.fromMap(json)).toList();
  }
}
