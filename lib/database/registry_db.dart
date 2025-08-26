import 'package:sqflite/sqflite.dart';
import '../models/registry.dart';
import 'medication_db.dart';
import 'database_helper.dart';

class RegistryDB {
  final dbHelper = DatabaseHelper.instance;

  Future<Database> get database async {
    return await dbHelper.database;
  }

  Future<void> insertRegistry(Registry r) async {
    final db = await database;

    await db.insert('registries', {
      'id': r.id,
      'date': r.date.toIso8601String(),
      'glicemia': r.glicemia,
      'insulinaCurta': r.insulinaCurta,
      'insulinaLonga': r.insulinaLonga,
      'medicationId': r.medication?.id,
      'weight': r.weight,
      'systolic': r.systolic,
      'diastolic': r.diastolic,
      'activityName': r.activityName,
      'activityDuration': r.activityDuration,
      'activityIntensity': r.activityIntensity,
      'caloriesBurned': r.caloriesBurned,
      'activityDescription': r.activityDescription,
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<void> deleteRegistry(String id) async {
    final db = await database;
    await db.delete('registries', where: 'id = ?', whereArgs: [id]);
  }

  Future<void> updateRegistry(Registry registry) async {
    final db = await database;
    await db.update(
      'registries',
      registry.toMap(),
      where: 'id = ?',
      whereArgs: [registry.id],
    );
  }

  Future<List<Registry>> getRegistries() async {
    final db = await database;

    final maps = await db.query('registries', orderBy: 'date DESC');

    final meds = await MedicationDB().getAllMedications();
    final medMap = {for (var m in meds) m.id: m};

    return maps.map((map) {
      return Registry(
        id: map['id'] as String,
        date: DateTime.parse(map['date'] as String),
        glicemia: (map['glicemia'] as num).toInt(),
        insulinaCurta: (map['insulinaCurta'] as num?)?.toDouble(),
        insulinaLonga: (map['insulinaLonga'] as num?)?.toDouble(),
        medication: medMap[map['medicationId']],
        weight:
            map['weight'] != null ? (map['weight'] as num).toDouble() : null,
        systolic: map['systolic'] as int?,
        diastolic: map['diastolic'] as int?,
        activityName: map['activityName'] as String?,
        activityDuration: map['activityDuration'] as int?,
        activityIntensity: map['activityIntensity'] as String?,
        caloriesBurned: map['caloriesBurned'] as int?,
        activityDescription: map['activityDescription'] as String?,
      );
    }).toList();
  }
}
