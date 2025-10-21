import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../models/meal.dart';
import 'dart:convert';
import 'package:intl/intl.dart';

class EditMealScreen extends StatefulWidget {
  final Meal meal;
  final void Function(Meal) onUpdate;

  const EditMealScreen({required this.meal, required this.onUpdate, super.key});

  @override
  State<EditMealScreen> createState() => _EditMealScreenState();
}

class _EditMealScreenState extends State<EditMealScreen> {
  final _mealTypes = ['Café da manhã', 'Almoço', 'Jantar', 'Lanche', 'Ceia'];

  String? _selectedMealType;
  List<Map<String, dynamic>> _foods = [];
  File? _mealImage;
  DateTime? _selectedDate;

  final _foodNameController = TextEditingController();
  final _portionController = TextEditingController();
  final _nutritionController = TextEditingController();

  @override
  void initState() {
    super.initState();

    _selectedMealType = widget.meal.type;
    _selectedDate = widget.meal.date;
    _foods =
        widget.meal.items
            .map(
              (item) => {
                'name': item.name,
                'portion': item.portion,
                'nutrition': item.nutrition,
              },
            )
            .toList();

    if (widget.meal.imagePath != null) {
      _mealImage = File(widget.meal.imagePath!);
    }
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
                              keyboardType:
                                  const TextInputType.numberWithOptions(
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
                              initialValue: _selectedUnit,
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
        _foods
            .map(
              (food) => MealItem(
                name: food['name'],
                portion: food['portion'],
                nutrition: Map<String, dynamic>.from(food['nutrition']),
              ),
            )
            .toList();

    final updatedMeal = Meal(
      id: widget.meal.id,
      type: _selectedMealType!,
      items: mealItems,
      date: _selectedDate ?? DateTime.now(),
      imagePath: _mealImage?.path,
    );

    widget.onUpdate(updatedMeal);
    Navigator.pop(context, updatedMeal);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Editar Refeição'),
        backgroundColor: Colors.deepOrange,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: ListView(
          children: [
            DropdownButtonFormField<String>(
              initialValue: _selectedMealType,
              items:
                  _mealTypes
                      .map(
                        (type) => DropdownMenuItem<String>(
                          value: type,
                          child: Text(type),
                        ),
                      )
                      .toList(),
              onChanged: (value) {
                setState(() {
                  _selectedMealType = value;
                });
              },
              decoration: const InputDecoration(
                labelText: 'Tipo da refeição *',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _addFood,
              icon: const Icon(Icons.add),
              label: const Text('Adicionar alimento'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.deepOrange,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
            const SizedBox(height: 12),
            if (_foods.isNotEmpty)
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _foods.length,
                itemBuilder: (context, index) {
                  final food = _foods[index];
                  return Card(
                    margin: const EdgeInsets.symmetric(vertical: 6),
                    child: ListTile(
                      title: Text(food['name']),
                      subtitle: Text(food['portion']),
                      trailing: IconButton(
                        icon: const Icon(Icons.delete),
                        onPressed: () {
                          setState(() {
                            _foods.removeAt(index);
                          });
                        },
                      ),
                    ),
                  );
                },
              ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _pickDate,
                    icon: const Icon(Icons.calendar_today),
                    label: Text(
                      _selectedDate == null
                          ? 'Selecionar data'
                          : DateFormat('dd/MM/yyyy').format(_selectedDate!),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.deepOrange,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _pickTime,
                    icon: const Icon(Icons.access_time),
                    label: Text(
                      _selectedDate == null
                          ? 'Selecionar hora'
                          : DateFormat('HH:mm').format(_selectedDate!),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.deepOrange,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _pickImage,
              icon: const Icon(Icons.photo_library),
              label: const Text('Selecionar imagem'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.deepOrange,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
            if (_mealImage != null)
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Image.file(_mealImage!),
              ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _saveMeal,
              child: const Text('Salvar Alterações'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.deepOrange,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
