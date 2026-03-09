import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:app/models/intake.dart';

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
    const timeType = 'TIME NOT NULL';

    await db.execute('''
CREATE TABLE intake_log ( 
  id $idType, 
  name $textType,
  ttime $timeType,
  time $timeType,
  date $textType,
  currstock $integerType,
  FOREIGN KEY (id) REFERENCES cabinet (id),
  FOREIGN KEY (name) REFERENCES cabinet (name),
  FOREIGN KEY (ttime) REFERENCES cabinet (time),
  FOREIGN KEY (currstock) REFERENCES cabinet (currstock)
  )'''
 );
  }

  Future<int> createlog(Intake intake) async {
    final db = await instance.database;
    return await db.insert('intake_log', intake.toMap());
  }

  Future<List<Intake>> readintakelog() async {
    final db = await instance.database;
    const orderBy = 'time ASC';
    final result = await db.query('intake_log', orderBy: orderBy);
    return result.map((json) => Intake.fromMap(json)).toList();
  }

}