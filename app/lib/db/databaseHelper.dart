import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:app/models/medicine.dart';

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
CREATE TABLE medicines ( 
  id $idType, 
  name $textType,
  dosage $textType,
  time $textType,
  cycle $integerType,
  condition $textType,
  doctor $textType,
  stock $integerType,
  priority $integerType
  )
''');
  }

  Future<int> create(Medicine medicine) async {
    final db = await instance.database;
    return await db.insert('medicines', medicine.toMap());
  }

  Future<List<Medicine>> readAllMedicines() async {
    final db = await instance.database;
    const orderBy = 'time ASC';
    final result = await db.query('medicines', orderBy: orderBy);
    return result.map((json) => Medicine.fromMap(json)).toList();
  }

  Future<int> delete(int id) async {
    final db = await instance.database;
    return await db.delete(
      'medicines',
      where: 'id = ?',
      whereArgs: [id],
    );
  }
}