import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:app/models/profile.dart';

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
  }

  Future<int> createprof(profile profile) async {
    final db = await instance.database;
    return await db.insert('profile', profile.toMap());
  }

  Future<List<profile>> readprofile() async {
    final db = await instance.database;
    final result = await db.query('profile');
    return result.map((json) => profile.fromMap(json)).toList();
  }

}