class Meal {
  final String id;
  final String type;
  final List<MealItem> items;
  final DateTime date;
  final String? imagePath;

  Meal({
    required this.id,
    required this.type,
    required this.items,
    required this.date,
    this.imagePath,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'type': type,
      'date': date.toIso8601String(),
      'imagePath': imagePath,
    };
  }

  factory Meal.fromMap(Map<String, dynamic> map, List<MealItem> items) {
    return Meal(
      id: map['id'],
      type: map['type'],
      items: items,
      date: DateTime.parse(map['date']),
      imagePath: map['imagePath'],
    );
  }
}

class MealItem {
  final String name;
  final String? portion;
  final Map<String, dynamic> nutrition;

  MealItem({required this.name, this.portion, required this.nutrition});

  Map<String, dynamic> toMap() => {
    'name': name,
    'portion': portion,
    'nutrition': nutrition,
  };

  factory MealItem.fromMap(Map<String, dynamic> map) => MealItem(
    name: map['name'],
    portion: map['portion'],
    nutrition: Map<String, dynamic>.from(map['nutrition']),
  );
}
