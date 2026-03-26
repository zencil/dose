import 'package:dose/db/dose_database.dart';
import 'package:dose/models/intake_model.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  DatabaseHelper._init();

  Future<int> createlog(Intake intake) async {
    final db = await DoseDatabase.instance.database;
    return await db.insert('intake_log', intake.toMap());
  }

  Future<List<Intake>> readintakelog() async {
    final db = await DoseDatabase.instance.database;
    const orderBy = 'time ASC';
    final result = await db.query('intake_log', orderBy: orderBy);
    return result.map((json) => Intake.fromMap(json)).toList();
  }
}
