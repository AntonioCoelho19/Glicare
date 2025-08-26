import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../models/meal.dart';
import 'dart:convert';
import 'package:intl/intl.dart';

class AddMealScreen extends StatefulWidget {
  final Meal? meal;
  final void Function(Meal) onAdd;

  const AddMealScreen({required this.onAdd, super.key, this.meal});

  @override
  State<AddMealScreen> createState() => _AddMealScreenState();
}

class _AddMealScreenState extends State<AddMealScreen> {
  final _mealTypes = ['Café da manhã', 'Almoço', 'Jantar', 'Lanche', 'Ceia'];
  String? _selectedMealType;
  List<Map<String, dynamic>> _foods = [];
  File? _mealImage;

  final _foodNameController = TextEditingController();
  final _portionController = TextEditingController();
  final _nutritionController = TextEditingController();
  DateTime? _selectedDate;

  @override
  void initState() {
    super.initState();
    _selectedDate = DateTime.now();
  }

  Future<void> _pickImage() async {
    final picked = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (picked != null) {
      setState(() {
        _mealImage = File(picked.path);
      });
    }
  }

  void _addFood() {
    String? _selectedUnit;

    final List<String> allUnits = [
      'Pequena',
      'Média',
      'Grande',
      'Gramas',
      'Colheres',
      'Unidades',
      'Pratos',
    ];

    _foodNameController.clear();
    _portionController.clear();
    _nutritionController.clear();

    showDialog(
      context: context,
      builder:
          (_) => StatefulBuilder(
            builder:
                (context, setState) => AlertDialog(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  title: const Text('Adicionar Alimento'),
                  content: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextField(
                        controller: _foodNameController,
                        decoration: const InputDecoration(
                          labelText: 'Nome do alimento *',
                          border: OutlineInputBorder(),
                        ),
                        onChanged: (value) {
                          setState(() {
                            if (value.isEmpty &&
                                (_selectedUnit == 'Pequena' ||
                                    _selectedUnit == 'Média' ||
                                    _selectedUnit == 'Grande')) {
                              _selectedUnit = null;
                            }
                          });
                        },
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            flex: 2,
                            child: TextField(
                              controller: _portionController,
                              keyboardType: TextInputType.numberWithOptions(
                                decimal: true,
                              ),
                              decoration: const InputDecoration(
                                labelText: 'Quantidade',
                                border: OutlineInputBorder(),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            flex: 3,
                            child: DropdownButtonFormField<String>(
                              value: _selectedUnit,
                              items:
                                  allUnits
                                      .map(
                                        (unit) => DropdownMenuItem<String>(
                                          value: unit,
                                          enabled:
                                              !(unit == 'Pequena' ||
                                                  unit == 'Média' ||
                                                  unit == 'Grande') ||
                                              _foodNameController
                                                  .text
                                                  .isNotEmpty,
                                          child: Text(unit),
                                        ),
                                      )
                                      .toList(),
                              onChanged: (value) {
                                setState(() {
                                  _selectedUnit = value;
                                });
                              },
                              decoration: const InputDecoration(
                                labelText: 'Unidade/Porção *',
                                border: OutlineInputBorder(),
                              ),
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Selecione uma unidade';
                                }
                                return null;
                              },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: _nutritionController,
                        decoration: const InputDecoration(
                          labelText: 'Dados nutricionais',
                          border: OutlineInputBorder(),
                        ),
                        maxLines: 3,
                      ),
                    ],
                  ),
                  actions: [
                    TextButton(
                      onPressed: () {
                        _foodNameController.clear();
                        _portionController.clear();
                        _nutritionController.clear();
                        Navigator.pop(context);
                      },
                      child: const Text('Cancelar'),
                    ),
                    ElevatedButton(
                      onPressed: () {
                        if (_foodNameController.text.isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('O nome do alimento é obrigatório'),
                            ),
                          );
                          return;
                        }

                        if (_selectedUnit == null) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Selecione uma unidade'),
                            ),
                          );
                          return;
                        }

                        final quantidade = _portionController.text.trim();

                        final porcaoFormatada =
                            quantidade.isNotEmpty
                                ? '$quantidade $_selectedUnit'
                                : _selectedUnit;

                        Map<String, dynamic> nutritionMap = {};
                        try {
                          nutritionMap = jsonDecode(_nutritionController.text);
                          if (nutritionMap is! Map<String, dynamic>) {
                            nutritionMap = {'info': _nutritionController.text};
                          }
                        } catch (e) {
                          nutritionMap = {'info': _nutritionController.text};
                        }

                        setState(() {
                          _foods.add({
                            'name': _foodNameController.text,
                            'portion': porcaoFormatada,
                            'nutrition': nutritionMap,
                          });
                        });

                        _foodNameController.clear();
                        _portionController.clear();
                        _nutritionController.clear();
                        Navigator.pop(context);
                      },
                      style: ElevatedButton.styleFrom(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Text('Adicionar'),
                    ),
                  ],
                ),
          ),
    );
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? now,
      firstDate: DateTime(now.year - 5),
      lastDate: DateTime(now.year + 5),
      locale: const Locale('pt', 'BR'),
    );
    if (pickedDate != null) {
      final currentTime = TimeOfDay.fromDateTime(_selectedDate ?? now);
      setState(() {
        _selectedDate = DateTime(
          pickedDate.year,
          pickedDate.month,
          pickedDate.day,
          currentTime.hour,
          currentTime.minute,
        );
      });
    }
  }

  Future<void> _pickTime() async {
    final now = TimeOfDay.now();
    final initialTime = TimeOfDay.fromDateTime(_selectedDate ?? DateTime.now());
    final pickedTime = await showTimePicker(
      context: context,
      initialTime: initialTime,
    );
    if (pickedTime != null) {
      final currentDate = _selectedDate ?? DateTime.now();
      setState(() {
        _selectedDate = DateTime(
          currentDate.year,
          currentDate.month,
          currentDate.day,
          pickedTime.hour,
          pickedTime.minute,
        );
      });
    }
  }

  void _saveMeal() {
    if (_selectedMealType == null || _foods.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Preencha o tipo e adicione pelo menos um alimento'),
        ),
      );
      return;
    }

    final mealItems =
        _foods.map((food) {
          return MealItem(
            name: food['name'],
            portion: food['portion'],
            nutrition: Map<String, dynamic>.from(food['nutrition']),
          );
        }).toList();

    final newMeal = Meal(
      id: DateTime.now().toIso8601String(),
      type: _selectedMealType!,
      items: mealItems,
      date: _selectedDate ?? DateTime.now(),
      imagePath: _mealImage?.path,
    );

    widget.onAdd(newMeal);
    Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Adicionar Refeição'),
        backgroundColor: Colors.deepOrange,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: ListView(
          children: [
            DropdownButtonFormField<String>(
              value: _selectedMealType,
              items:
                  _mealTypes
                      .map(
                        (type) =>
                            DropdownMenuItem(value: type, child: Text(type)),
                      )
                      .toList(),
              onChanged: (value) => setState(() => _selectedMealType = value),
              decoration: InputDecoration(
                labelText: 'Tipo de refeição',
                prefixIcon: const Icon(Icons.restaurant),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: Colors.orange.shade50,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Data da refeição',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: Colors.deepOrange.shade700,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.calendar_today),
                    label: Text(
                      _selectedDate != null
                          ? DateFormat('dd/MM/yyyy').format(_selectedDate!)
                          : 'Selecionar data',
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.deepOrange.shade400,
                    ),
                    onPressed: _pickDate,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.access_time),
                    label: Text(
                      _selectedDate != null
                          ? DateFormat('HH:mm').format(_selectedDate!)
                          : 'Selecionar hora',
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.deepOrange.shade400,
                    ),
                    onPressed: _pickTime,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Text(
              'Alimentos adicionados',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 18,
                color: Colors.deepOrange.shade700,
              ),
            ),
            const SizedBox(height: 8),
            if (_foods.isEmpty)
              Text(
                'Nenhum alimento adicionado.',
                style: TextStyle(color: Colors.grey[600]),
              ),
            ..._foods.map(
              (food) => Card(
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                margin: const EdgeInsets.symmetric(vertical: 6),
                child: ListTile(
                  leading: const Icon(
                    Icons.food_bank,
                    color: Colors.deepOrange,
                  ),
                  title: Text(
                    food['name'],
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  subtitle: Text(
                    'Porção: ${food['portion']}\nDados: ${food['nutrition']}',
                    style: TextStyle(color: Colors.grey[700]),
                  ),
                  isThreeLine: true,
                ),
              ),
            ),
            TextButton.icon(
              onPressed: _addFood,
              icon: const Icon(
                Icons.add_circle_outline,
                color: Colors.deepOrange,
              ),
              label: Text(
                'Adicionar Alimento',
                style: TextStyle(
                  color: Colors.deepOrange.shade700,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Foto da refeição',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 18,
                color: Colors.deepOrange.shade700,
              ),
            ),
            const SizedBox(height: 12),
            Container(
              height: 200,
              decoration: BoxDecoration(
                color: Colors.orange.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.deepOrange.shade200),
              ),
              child: Center(
                child:
                    _mealImage != null
                        ? ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.file(
                            _mealImage!,
                            fit: BoxFit.cover,
                            width: double.infinity,
                          ),
                        )
                        : Text(
                          'Nenhuma imagem selecionada',
                          style: TextStyle(color: Colors.grey[600]),
                        ),
              ),
            ),
            const SizedBox(height: 8),
            TextButton.icon(
              onPressed: _pickImage,
              icon: const Icon(Icons.camera_alt, color: Colors.deepOrange),
              label: Text(
                'Selecionar Foto',
                style: TextStyle(
                  color: Colors.deepOrange.shade700,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 30),
            ElevatedButton.icon(
              onPressed: _saveMeal,
              icon: const Icon(Icons.check, color: Colors.white),
              label: const Text(
                'Salvar Refeição',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.deepOrange,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 6,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
