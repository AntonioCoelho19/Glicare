import 'package:sqflite/sqflite.dart';
import '../models/medication.dart';
import 'database_helper.dart';

class MedicationDB {
  Future<void> insertMedication(Medication medication) async {
    final db = await DatabaseHelper.instance.database;
    await db.insert(
      'medications',
      medication.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<Medication>> getAllMedications() async {
    final db = await DatabaseHelper.instance.database;
    final maps = await db.query('medications');
    return maps.map((map) => Medication.fromMap(map)).toList();
  }

  Future<Medication?> getMedicationById(String id) async {
    final db = await DatabaseHelper.instance.database;
    final maps = await db.query(
      'medications',
      where: 'id = ?',
      whereArgs: [id],
    );
    if (maps.isNotEmpty) {
      return Medication.fromMap(maps.first);
    }
    return null;
  }

  Future<void> deleteMedication(String id) async {
    final db = await DatabaseHelper.instance.database;
    await db.delete('medications', where: 'id = ?', whereArgs: [id]);
  }
}
