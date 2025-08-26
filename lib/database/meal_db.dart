import 'package:sqflite/sqflite.dart';
import '../models/meal.dart';
import 'database_helper.dart';
import 'dart:convert';

class MealDB {
  final dbHelper = DatabaseHelper.instance;

  Future<void> insertMeal(Meal meal) async {
    final db = await dbHelper.database;

    await db.transaction((txn) async {
      await txn.insert('meals', {
        'id': meal.id,
        'type': meal.type,
        'date': meal.date.toIso8601String(),
        'imagePath': meal.imagePath,
      }, conflictAlgorithm: ConflictAlgorithm.replace);

      await txn.delete(
        'meal_items',
        where: 'meal_id = ?',
        whereArgs: [meal.id],
      );

      for (var item in meal.items) {
        await txn.insert('meal_items', {
          'meal_id': meal.id,
          'name': item.name,
          'portion': item.portion,
          'nutrition': jsonEncode(item.nutrition),
        });
      }
    });
  }

  Future<void> deleteMeal(String mealId) async {
    final db = await dbHelper.database;

    await db.transaction((txn) async {
      await txn.delete('meal_items', where: 'meal_id = ?', whereArgs: [mealId]);

      await txn.delete('meals', where: 'id = ?', whereArgs: [mealId]);
    });
  }

  Future<List<Meal>> getAllMeals() async {
    final db = await dbHelper.database;

    final mealsMaps = await db.query('meals', orderBy: 'date DESC');

    List<Meal> meals = [];

    for (var mealMap in mealsMaps) {
      final itemsMaps = await db.query(
        'meal_items',
        where: 'meal_id = ?',
        whereArgs: [mealMap['id']],
      );

      List<MealItem> items =
          itemsMaps.map((itemMap) {
            return MealItem(
              name: itemMap['name'] as String,
              portion: itemMap['portion'] as String,
              nutrition: Map<String, dynamic>.from(
                jsonDecode(itemMap['nutrition'] as String),
              ),
            );
          }).toList();

      meals.add(
        Meal(
          id: mealMap['id'] as String,
          type: mealMap['type'] as String,
          date: DateTime.parse(mealMap['date'] as String),
          items: items,
          imagePath: mealMap['imagePath'] as String?,
        ),
      );
    }

    return meals;
  }
}
