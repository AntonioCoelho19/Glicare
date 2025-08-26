class Medication {
  final String id;
  final String name;
  final double dosage;
  final String unit;
  final int timesPerDay;
  final DateTime startDate;
  final int durationDays;

  Medication({
    required this.id,
    required this.name,
    required this.dosage,
    required this.unit,
    required this.timesPerDay,
    required this.startDate,
    required this.durationDays,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'dosage': dosage,
      'unit': unit,
      'timesPerDay': timesPerDay,
      'startDate': startDate.toIso8601String(),
      'durationDays': durationDays,
    };
  }

  factory Medication.fromMap(Map<String, dynamic> map) {
    return Medication(
      id: map['id'],
      name: map['name'],
      dosage: map['dosage'],
      unit: map['unit'],
      timesPerDay: map['timesPerDay'],
      startDate: DateTime.parse(map['startDate']),
      durationDays: map['durationDays'],
    );
  }
}
