import 'package:dose/db/dose_database.dart';
import 'package:dose/models/cabinet_model.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  DatabaseHelper._init();

  Future<int> createMedicine(Cabinet cabinet) async {
    final db = await DoseDatabase.instance.database;
    return await db.insert('cabinet', cabinet.toMap());
  }

  Future<Cabinet?> readMedicine(int id) async {
    final db = await DoseDatabase.instance.database;
    final maps = await db.query('cabinet', where: 'id = ?', whereArgs: [id]);

    if (maps.isNotEmpty) {
      return Cabinet.fromMap(maps.first);
    }
    return null;
  }

  Future<List<Cabinet>> readAllMedicines() async {
    final db = await DoseDatabase.instance.database;
    const orderBy = 'time ASC';
    final result = await db.query('cabinet', orderBy: orderBy);
    return result.map((json) => Cabinet.fromMap(json)).toList();
  }

  Future<int> updateMedicine(Cabinet medicine) async {
    final db = await DoseDatabase.instance.database;
    return await db.update(
      'cabinet',
      medicine.toMap(),
      where: 'id = ?',
      whereArgs: [medicine.id],
    );
  }

  Future<int> deleteMedicine(int id) async {
    final db = await DoseDatabase.instance.database;
    return await db.delete('cabinet', where: 'id = ?', whereArgs: [id]);
  }
}
