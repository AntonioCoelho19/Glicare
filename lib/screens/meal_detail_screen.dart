import 'dart:io';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/meal.dart';
import '../database/meal_db.dart';
import 'add_meal_screen.dart';
import 'edit_meal_screen.dart';

class MealDetailScreen extends StatefulWidget {
  final Meal meal;
  final Future<void> Function(Meal)? onUpdate;

  const MealDetailScreen({super.key, required this.meal, this.onUpdate});

  @override
  State<MealDetailScreen> createState() => _MealDetailScreenState();
}

class _MealDetailScreenState extends State<MealDetailScreen> {
  final MealDB _mealDB = MealDB();
  late Meal _editableMeal;

  @override
  void initState() {
    super.initState();
    _editableMeal = widget.meal;
  }

  Future<void> _editMeal() async {
    final updatedMeal = await Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (_) => EditMealScreen(
              meal: widget.meal,
              onUpdate: (updatedMeal) {
                setState(() {});
              },
            ),
      ),
    );

    if (updatedMeal != null) {
      widget.onUpdate?.call(updatedMeal);
      setState(() {});
    }
  }

  Future<void> _deleteMeal() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder:
          (_) => AlertDialog(
            title: const Text('Confirmar exclusão'),
            content: const Text('Deseja realmente excluir esta refeição?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancelar'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Excluir'),
              ),
            ],
          ),
    );
    if (confirm == true) {
      await _mealDB.deleteMeal(_editableMeal.id);
      Navigator.pop(context, true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Detalhes da Refeição'),
        backgroundColor: Colors.deepOrange,
        elevation: 4,
        actions: [
          IconButton(icon: const Icon(Icons.edit), onPressed: _editMeal),
          IconButton(icon: const Icon(Icons.delete), onPressed: _deleteMeal),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: ListView(
          children: [
            Card(
              elevation: 3,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              margin: const EdgeInsets.only(bottom: 20),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  vertical: 20,
                  horizontal: 24,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Tipo',
                      style: TextStyle(fontSize: 14, color: Colors.grey[700]),
                    ),
                    Text(
                      _editableMeal.type,
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Data',
                      style: TextStyle(fontSize: 14, color: Colors.grey[700]),
                    ),
                    Text(
                      DateFormat("dd/MM/yyyy HH:mm").format(_editableMeal.date),
                      style: const TextStyle(fontSize: 16),
                    ),
                  ],
                ),
              ),
            ),
            if (_editableMeal.imagePath != null &&
                _editableMeal.imagePath!.isNotEmpty)
              ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Image.file(
                  File(_editableMeal.imagePath!),
                  height: 200,
                  width: double.infinity,
                  fit: BoxFit.cover,
                ),
              ),
            const SizedBox(height: 20),
            Text(
              'Alimentos',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 20,
                color: Colors.deepOrange.shade700,
              ),
            ),
            const SizedBox(height: 12),
            ..._editableMeal.items.map(
              (item) => Card(
                margin: const EdgeInsets.symmetric(vertical: 6),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 2,
                child: ListTile(
                  leading: const Icon(
                    Icons.food_bank,
                    color: Colors.deepOrange,
                  ),
                  title: Text(
                    item.name,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  subtitle: Text(
                    'Porção: ${item.portion}\nDados: ${item.nutrition}',
                    style: TextStyle(color: Colors.grey[700]),
                  ),
                  isThreeLine: true,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
