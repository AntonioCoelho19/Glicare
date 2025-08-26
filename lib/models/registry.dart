import 'medication.dart';
import 'meal.dart';

class Registry {
  String id;
  DateTime date;
  int glicemia;
  double? insulinaLonga;
  double? insulinaCurta;
  String? medicationId;
  Medication? medication;
  Meal? meal;

  double? weight;
  int? systolic;
  int? diastolic;

  String? activityName;
  int? activityDuration;
  String? activityIntensity;
  int? caloriesBurned;
  String? activityDescription;

  Registry({
    required this.id,
    required this.date,
    required this.glicemia,
    this.insulinaLonga,
    this.insulinaCurta,
    this.medicationId,
    this.medication,
    this.meal,
    this.weight,
    this.systolic,
    this.diastolic,
    this.activityName,
    this.activityDuration,
    this.activityIntensity,
    this.caloriesBurned,
    this.activityDescription,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'date': date.toIso8601String(),
      'glicemia': glicemia,
      'insulinaLonga': insulinaLonga,
      'insulinaCurta': insulinaCurta,
      'medicationId': medicationId,
      'weight': weight,
      'systolic': systolic,
      'diastolic': diastolic,
      'activityName': activityName,
      'activityDuration': activityDuration,
      'activityIntensity': activityIntensity,
      'caloriesBurned': caloriesBurned,
      'activityDescription': activityDescription,
    };
  }

  factory Registry.fromMap(Map<String, dynamic> map, {Medication? medication}) {
    return Registry(
      id: map['id'],
      date: DateTime.parse(map['date']),
      glicemia: map['glicemia'],
      insulinaLonga:
          map['insulinaLonga'] != null ? map['insulinaLonga'] * 1.0 : null,
      insulinaCurta:
          map['insulinaCurta'] != null ? map['insulinaCurta'] * 1.0 : null,
      medicationId: map['medicationId'],
      medication: medication,
      weight: map['weight'] != null ? (map['weight'] as num).toDouble() : null,
      systolic: map['systolic'],
      diastolic: map['diastolic'],
      activityName: map['activityName'],
      activityDuration: map['activityDuration'],
      activityIntensity: map['activityIntensity'],
      caloriesBurned: map['caloriesBurned'],
      activityDescription: map['activityDescription'],
    );
  }
}
