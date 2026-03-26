import 'package:dose/db/dose_database.dart';
import 'package:dose/models/profile_model.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  DatabaseHelper._init();

  Future<int> createprof(Profile profile) async {
    final db = await DoseDatabase.instance.database;
    return await db.insert('profile', profile.toMap());
  }

  Future<List<Profile>> readprofile() async {
    final db = await DoseDatabase.instance.database;
    final result = await db.query('profile');
    return result.map((json) => Profile.fromMap(json)).toList();
  }

  Future<int> updateProfile(Profile profileData) async {
    final db = await DoseDatabase.instance.database;
    return await db.update(
      'profile',
      profileData.toMap(),
      where: 'id = ?',
      whereArgs: [profileData.id],
    );
  }
}
