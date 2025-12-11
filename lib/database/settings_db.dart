import 'package:sqflite/sqflite.dart';
import 'database_helper.dart';

class SettingsDB {
  final dbHelper = DatabaseHelper.instance;
  static const int _settingsId = 1;

  Future<Map<String, double?>?> loadGlicemiaGoals() async {
    final db = await dbHelper.database;
    final maps = await db.query(
      'settings',
      where: 'id = ?',
      whereArgs: [_settingsId],
    );

    if (maps.isNotEmpty) {
      return {
        'minGlicemia': (maps.first['minGlicemia'] as num?)?.toDouble(),
        'maxGlicemia': (maps.first['maxGlicemia'] as num?)?.toDouble(),
      };
    }
    return null;
  }

  Future<void> saveGlicemiaGoals(double min, double max) async {
    final db = await dbHelper.database;
    await db.insert('settings', {
      'id': _settingsId,
      'minGlicemia': min,
      'maxGlicemia': max,
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }
}
