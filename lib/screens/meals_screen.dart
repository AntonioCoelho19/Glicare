import 'dart:io';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/meal.dart';
import 'meal_detail_screen.dart';

class MealsScreen extends StatefulWidget {
  final List<Meal> meals;

  const MealsScreen({super.key, required this.meals});

  @override
  State<MealsScreen> createState() => _MealsScreenState();
}

class _MealsScreenState extends State<MealsScreen> {
  Map<String, List<Meal>> _groupMealsByDate() {
    Map<String, List<Meal>> grouped = {};

    final sortedMeals = [...widget.meals];
    sortedMeals.sort((a, b) => b.date.compareTo(a.date));

    for (var m in sortedMeals) {
      final dateKey = _formatDate(m.date);
      grouped.putIfAbsent(dateKey, () => []).add(m);
    }

    return grouped;
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final dateToCompare = DateTime(date.year, date.month, date.day);

    if (dateToCompare == today) {
      return 'Hoje';
    } else if (dateToCompare == yesterday) {
      return 'Ontem';
    } else {
      return DateFormat("d 'de' MMM", 'pt_BR').format(date);
    }
  }

  Icon _getMealIcon(String mealType) {
    switch (mealType.toLowerCase()) {
      case 'café da manhã':
        return const Icon(
          Icons.free_breakfast,
          size: 36,
          color: Colors.deepOrange,
        );
      case 'almoço':
        return const Icon(Icons.restaurant, size: 36, color: Colors.deepOrange);
      case 'jantar':
        return const Icon(
          Icons.dinner_dining,
          size: 36,
          color: Colors.deepOrange,
        );
      case 'lanche':
      case 'snack':
        return const Icon(Icons.fastfood, size: 36, color: Colors.deepOrange);
      default:
        return const Icon(Icons.food_bank, size: 36, color: Colors.deepOrange);
    }
  }

  String _formatNutrition(Map<String, dynamic> nutrition) {
    if (nutrition.isEmpty) return '';

    List<String> parts = [];

    nutrition.forEach((key, value) {
      if (value != null) {
        final strValue = value.toString().trim();
        if (strValue.isNotEmpty) {
          parts.add('$strValue $key');
        }
      }
    });

    return parts.join(', ');
  }

  Widget _buildMealCard(BuildContext context, Meal meal) {
    return GestureDetector(
      onTap: () async {
        final updated = await Navigator.push(
          context,
          MaterialPageRoute(
            builder:
                (_) => MealDetailScreen(
                  meal: meal,
                  onUpdate: (updatedMeal) async {
                    setState(() {
                      final index = widget.meals.indexWhere(
                        (m) => m.id == updatedMeal.id,
                      );
                      if (index != -1) {
                        widget.meals[index] = updatedMeal;
                      }
                    });
                  },
                ),
          ),
        );
        if (updated == true) {
          setState(() {
            widget.meals.removeWhere((m) => m.id == meal.id);
          });
        }
      },

      child: Card(
        elevation: 5,
        margin: const EdgeInsets.symmetric(vertical: 8),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        shadowColor: Colors.deepOrangeAccent.withOpacity(0.3),
        child: ListTile(
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 10,
          ),
          leading:
              (meal.imagePath != null && meal.imagePath!.isNotEmpty)
                  ? ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.file(
                      File(meal.imagePath!),
                      width: 60,
                      height: 60,
                      fit: BoxFit.cover,
                    ),
                  )
                  : Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      color: Colors.deepOrange.shade100,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Center(child: _getMealIcon(meal.type)),
                  ),
          title: Text(
            meal.type,
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 18,
              color: Colors.deepOrange,
            ),
          ),
          subtitle: Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children:
                  meal.items.map((item) {
                    final portion = item.portion?.trim();
                    final nutritionStr = _formatNutrition(item.nutrition);
                    List<String> infos = [];
                    if (portion != null &&
                        portion.isNotEmpty &&
                        portion != '1') {
                      infos.add(portion);
                    }
                    if (nutritionStr.isNotEmpty) {
                      infos.add(nutritionStr);
                    }

                    String infosText =
                        infos.isNotEmpty ? ' (${infos.join(' | ')})' : '';

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: RichText(
                        text: TextSpan(
                          style: const TextStyle(
                            fontSize: 14,
                            color: Colors.black87,
                          ),
                          children: [
                            TextSpan(text: item.name),
                            if (infosText.isNotEmpty)
                              TextSpan(
                                text: infosText,
                                style: TextStyle(
                                  fontStyle: FontStyle.italic,
                                  color: Colors.grey.shade700,
                                ),
                              ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
            ),
          ),
          trailing: Text(
            DateFormat('HH:mm').format(meal.date),
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade600,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final groupedMeals = _groupMealsByDate();

    return Scaffold(
      appBar: AppBar(title: const Text('Refeições')),
      body:
          widget.meals.isEmpty
              ? Center(
                child: Text(
                  'Nenhuma refeição registrada.',
                  style: TextStyle(fontSize: 16, color: Colors.grey.shade700),
                ),
              )
              : ListView.builder(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                itemCount: groupedMeals.length,
                itemBuilder: (ctx, index) {
                  final entry = groupedMeals.entries.elementAt(index);
                  final date = entry.key;
                  final items = entry.value;

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        date,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.deepOrange.shade700,
                        ),
                      ),
                      const SizedBox(height: 10),
                      ...items
                          .map((meal) => _buildMealCard(context, meal))
                          .toList(),
                      const SizedBox(height: 20),
                    ],
                  );
                },
              ),
    );
  }
}
