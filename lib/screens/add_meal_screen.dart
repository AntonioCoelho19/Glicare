import 'dart:io';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../models/meal.dart';
import 'dart:convert';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

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
  TimeOfDay _selectedTime = TimeOfDay.now();

  List<Map<String, dynamic>> _recentFoods = [];
  static const String _recentFoodsKey = 'recentFoods';

  List<Map<String, dynamic>> _favoriteFoods = [];
  static const String _favoriteFoodsKey = 'favoriteFoods';

  @override
  void initState() {
    super.initState();
    _selectedDate = DateTime.now();
    _selectedTime = TimeOfDay.fromDateTime(_selectedDate!);
    _loadRecentFoods();
    _loadFavoriteFoods();
  }

  Future<void> _loadRecentFoods() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonList = prefs.getStringList(_recentFoodsKey) ?? [];

    try {
      setState(() {
        _recentFoods =
            jsonList.map((e) => jsonDecode(e) as Map<String, dynamic>).toList();
      });
    } catch (e) {
      _recentFoods = [];
      print('Erro ao carregar alimentos recentes: $e');
    }
  }

  Future<void> _saveRecentFoods() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonList = _recentFoods.map((food) => jsonEncode(food)).toList();
    await prefs.setStringList(_recentFoodsKey, jsonList);
  }

  void _addFoodToRecents(Map<String, dynamic> food) {
    final foodToSave = {
      'name': food['name'],
      'portion': food['portion'],
      'nutrition': jsonEncode(food['nutrition']),
    };

    _recentFoods.removeWhere((f) => f['name'] == foodToSave['name']);

    _recentFoods.insert(0, foodToSave);

    if (_recentFoods.length > 10) {
      _recentFoods = _recentFoods.sublist(0, 10);
    }

    _saveRecentFoods();
  }

  Future<void> _loadFavoriteFoods() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonList = prefs.getStringList(_favoriteFoodsKey) ?? [];

    try {
      setState(() {
        _favoriteFoods =
            jsonList.map((e) => jsonDecode(e) as Map<String, dynamic>).toList();
      });
    } catch (e) {
      _favoriteFoods = [];
      print('Erro ao carregar favoritos: $e');
    }
  }

  Future<void> _saveFavoriteFoods() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonList = _favoriteFoods.map((food) => jsonEncode(food)).toList();
    await prefs.setStringList(_favoriteFoodsKey, jsonList);
  }

  void _toggleFavoriteFood(Map<String, dynamic> food) {
    final foodName = food['name'];
    final isFavorite = _favoriteFoods.any((f) => f['name'] == foodName);

    if (isFavorite) {
      _favoriteFoods.removeWhere((f) => f['name'] == foodName);
    } else {
      final foodToSave = {
        'name': food['name'],
        'portion': food['portion'],
        'nutrition': jsonEncode(food['nutrition']),
      };
      _favoriteFoods.insert(0, foodToSave);
    }

    _saveFavoriteFoods();
  }

  void _clearRecentFoods() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_recentFoodsKey);
    setState(() {
      _recentFoods = [];
    });
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Alimentos recentes limpos!')));
  }

  Map<String, String> _portionFromSavedString(String savedPortion) {
    final parts = savedPortion.split(' ');
    final allUnits = [
      'Pequena',
      'Média',
      'Grande',
      'Gramas',
      'Colheres',
      'Unidades',
      'Pratos',
      'Pedaços',
      'Copos',
    ];

    if (parts.length > 1 && !allUnits.contains(parts.first)) {
      return {'amount': parts.first, 'unit': parts.last};
    } else {
      return {'amount': '', 'unit': savedPortion};
    }
  }

  void _clearAndCloseDialog(BuildContext context) {
    _foodNameController.clear();
    _portionController.clear();
    _nutritionController.clear();
    Navigator.pop(context);
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
    String? currentSelectedUnit;

    final List<String> allUnits = [
      'Pequena',
      'Média',
      'Grande',
      'Gramas',
      'Colheres',
      'Unidades',
      'Pratos',
      'Pedaços',
      'Copos',
    ];

    _foodNameController.clear();
    _portionController.clear();
    _nutritionController.clear();

    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final dialogBackgroundColor = isDark ? Colors.grey.shade900 : Colors.white;
    final dialogTitleColor =
        isDark
            ? Colors.white
            : Colors.deepOrange; // CORREÇÃO: Força branco no dark mode

    showDialog(
      context: context,
      builder:
          (context) => StatefulBuilder(
            builder:
                (context, dialogSetState) => AlertDialog(
                  backgroundColor:
                      dialogBackgroundColor, // Aplica a cor de fundo do Dark Mode
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  contentPadding: const EdgeInsets.all(24),
                  titlePadding: const EdgeInsets.only(top: 24, left: 24),

                  title: Text(
                    'Adicionar Alimento',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 22,
                      color: dialogTitleColor, // Usa a cor adaptada
                    ),
                  ),

                  content: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // --- Seleção Rápida (Estilo Limpo) ---
                        if (_favoriteFoods.isNotEmpty ||
                            _recentFoods.isNotEmpty) ...[
                          const Text(
                            'Seleção Rápida:',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 8),

                          // 1. Favoritos (Star Icon + Outline Button)
                          if (_favoriteFoods.isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.only(bottom: 8.0),
                              child: OutlinedButton.icon(
                                icon: const Icon(
                                  Icons.star,
                                  color: Colors.amber,
                                ),
                                label: const Text('Favoritos'),
                                style: OutlinedButton.styleFrom(
                                  side: const BorderSide(color: Colors.amber),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                  ),
                                ),
                                onPressed: () {
                                  showModalBottomSheet(
                                    context: context,
                                    builder:
                                        (ctx) => ListView(
                                          children: [
                                            Padding(
                                              padding: const EdgeInsets.all(
                                                16.0,
                                              ),
                                              child: Text(
                                                'Alimentos Favoritos',
                                                style:
                                                    Theme.of(
                                                      context,
                                                    ).textTheme.titleLarge,
                                              ),
                                            ),
                                            const Divider(height: 1),
                                            ..._favoriteFoods.map((food) {
                                              final parsedPortion =
                                                  _portionFromSavedString(
                                                    food['portion'],
                                                  );

                                              return ListTile(
                                                leading: const Icon(
                                                  Icons.star_border,
                                                  color: Colors.amber,
                                                ),
                                                title: Text(food['name']),
                                                subtitle: Text(
                                                  'Porção: ${food['portion']}',
                                                ),
                                                onTap: () {
                                                  String nutritionText = '';
                                                  try {
                                                    final decodedNutrition =
                                                        jsonDecode(
                                                          food['nutrition']
                                                              as String,
                                                        );
                                                    if (decodedNutrition
                                                            is Map &&
                                                        decodedNutrition
                                                            .containsKey(
                                                              'info',
                                                            )) {
                                                      nutritionText =
                                                          decodedNutrition['info'];
                                                    } else {
                                                      nutritionText =
                                                          food['nutrition']
                                                              .toString();
                                                    }
                                                  } catch (e) {
                                                    nutritionText =
                                                        food['nutrition']
                                                            .toString();
                                                  }

                                                  dialogSetState(() {
                                                    _foodNameController.text =
                                                        food['name'];
                                                    _portionController.text =
                                                        parsedPortion['amount'] ??
                                                        '';
                                                    _nutritionController.text =
                                                        nutritionText;
                                                    currentSelectedUnit =
                                                        parsedPortion['unit'];
                                                  });
                                                  Navigator.pop(ctx);
                                                },
                                              );
                                            }).toList(),
                                          ],
                                        ),
                                  );
                                },
                              ),
                            ),

                          // 2. Recentes (History Icon + Outline Button)
                          if (_recentFoods.isNotEmpty)
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                OutlinedButton.icon(
                                  icon: const Icon(
                                    Icons.history,
                                    color: Colors.blueGrey,
                                  ),
                                  label: const Text('Recentes'),
                                  style: OutlinedButton.styleFrom(
                                    side: const BorderSide(
                                      color: Colors.blueGrey,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 16,
                                    ),
                                  ),
                                  onPressed: () {
                                    showModalBottomSheet(
                                      context: context,
                                      builder:
                                          (ctx) => ListView(
                                            children: [
                                              Padding(
                                                padding: const EdgeInsets.all(
                                                  16.0,
                                                ),
                                                child: Text(
                                                  'Alimentos Recentes',
                                                  style:
                                                      Theme.of(
                                                        context,
                                                      ).textTheme.titleLarge,
                                                ),
                                              ),
                                              const Divider(height: 1),
                                              ..._recentFoods.map((food) {
                                                final parsedPortion =
                                                    _portionFromSavedString(
                                                      food['portion'],
                                                    );

                                                return ListTile(
                                                  leading: const Icon(
                                                    Icons.watch_later_outlined,
                                                    color: Colors.blueGrey,
                                                  ),
                                                  title: Text(food['name']),
                                                  subtitle: Text(
                                                    'Porção: ${food['portion']}',
                                                  ),
                                                  onTap: () {
                                                    String nutritionText = '';
                                                    try {
                                                      final decodedNutrition =
                                                          jsonDecode(
                                                            food['nutrition']
                                                                as String,
                                                          );
                                                      if (decodedNutrition
                                                              is Map &&
                                                          decodedNutrition
                                                              .containsKey(
                                                                'info',
                                                              )) {
                                                        nutritionText =
                                                            decodedNutrition['info'];
                                                      } else {
                                                        nutritionText =
                                                            food['nutrition']
                                                                .toString();
                                                      }
                                                    } catch (e) {
                                                      nutritionText =
                                                          food['nutrition']
                                                              .toString();
                                                    }

                                                    dialogSetState(() {
                                                      _foodNameController.text =
                                                          food['name'];
                                                      _portionController.text =
                                                          parsedPortion['amount'] ??
                                                          '';
                                                      _nutritionController
                                                          .text = nutritionText;
                                                      currentSelectedUnit =
                                                          parsedPortion['unit'];
                                                    });
                                                    Navigator.pop(ctx);
                                                  },
                                                );
                                              }).toList(),
                                            ],
                                          ),
                                    );
                                  },
                                ),

                                // Botão Limpar Recentes (Discreto)
                                TextButton.icon(
                                  onPressed: () {
                                    Navigator.pop(context);
                                    _clearRecentFoods();
                                  },
                                  icon: const Icon(
                                    Icons.clear_all,
                                    size: 18,
                                    color: Colors.red,
                                  ),
                                  label: const Text(
                                    'Limpar Recentes',
                                    style: TextStyle(color: Colors.red),
                                  ),
                                ),
                              ],
                            ),

                          const Divider(height: 30),
                        ],

                        // --- FIM: Seleção Rápida ---
                        TextField(
                          controller: _foodNameController,
                          decoration: InputDecoration(
                            labelText: 'Nome do alimento *',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          onChanged: (value) {
                            dialogSetState(() {
                              if (value.isEmpty &&
                                  (currentSelectedUnit == 'Pequena' ||
                                      currentSelectedUnit == 'Média' ||
                                      currentSelectedUnit == 'Grande')) {
                                currentSelectedUnit = null;
                              }
                            });
                          },
                        ),
                        const SizedBox(height: 16),
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
                                decoration: InputDecoration(
                                  labelText: 'Quantidade',
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              flex: 3,
                              child: DropdownButtonFormField<String>(
                                value: currentSelectedUnit,
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
                                  dialogSetState(() {
                                    currentSelectedUnit = value;

                                    // Lógica para limpar a quantidade
                                    if (value != null &&
                                        (value == 'Pequena' ||
                                            value == 'Média' ||
                                            value == 'Grande')) {
                                      _portionController.text = '';
                                    }
                                  });
                                },
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Selecione uma unidade';
                                  }
                                  return null;
                                },
                                decoration: InputDecoration(
                                  labelText: 'Unidade/Porção *',
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        TextField(
                          controller: _nutritionController,
                          decoration: InputDecoration(
                            labelText:
                                'Dados nutricionais (opcional, JSON ou texto)',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          maxLines: 3,
                        ),
                      ],
                    ),
                  ),
                  actions: [
                    TextButton(
                      onPressed: () {
                        _clearAndCloseDialog(context);
                      },
                      child: Text(
                        'Cancelar',
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.secondary,
                        ),
                      ),
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
                        if (currentSelectedUnit == null) {
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
                                ? '$quantidade $currentSelectedUnit'
                                : currentSelectedUnit;

                        Map<String, dynamic> nutritionMap = {};
                        try {
                          nutritionMap = jsonDecode(_nutritionController.text);
                        } catch (e) {
                          nutritionMap = {
                            'info': _nutritionController.text.trim(),
                          };
                        }

                        final newFood = {
                          'name': _foodNameController.text.trim(),
                          'portion': porcaoFormatada,
                          'nutrition': nutritionMap,
                        };

                        _addFoodToRecents(newFood);

                        setState(() {
                          _foods.add(newFood);
                        });

                        _clearAndCloseDialog(context);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.deepOrange,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 12,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        elevation: 4,
                      ),
                      child: const Text(
                        'Adicionar',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
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
      lastDate: DateTime.now(),
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

  Future<void> _showCupertinoTimePicker() async {
    DateTime tempDateTime = DateTime(
      _selectedDate!.year,
      _selectedDate!.month,
      _selectedDate!.day,
      _selectedTime.hour,
      _selectedTime.minute,
    );

    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final pickerTextColor = isDark ? Colors.white : Colors.black;
    final pickerBackgroundColor = isDark ? Colors.black : Colors.white;

    final titleTextColor = isDark ? Colors.white : theme.primaryColor;

    late Color finalButtonColor;
    late Color finalContentColor;

    if (isDark) {
      finalButtonColor = theme.colorScheme.secondary;
      finalContentColor = Colors.black;
    } else {
      finalButtonColor = theme.primaryColor;
      finalContentColor = Colors.white;
    }

    await showModalBottomSheet(
      context: context,
      useSafeArea: true,
      builder:
          (_) => Container(
            color: pickerBackgroundColor,
            height: 320,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Text(
                    'Selecione a Hora do Registro',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: titleTextColor,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),

                const Divider(height: 1),

                Expanded(
                  child: CupertinoTheme(
                    data: CupertinoThemeData(
                      textTheme: CupertinoTextThemeData(
                        dateTimePickerTextStyle: TextStyle(
                          color: pickerTextColor,
                          fontSize: 21,
                        ),
                      ),
                    ),
                    child: CupertinoDatePicker(
                      initialDateTime: tempDateTime,
                      mode: CupertinoDatePickerMode.time,
                      onDateTimeChanged: (newDateTime) {
                        tempDateTime = newDateTime;
                      },
                      backgroundColor: pickerBackgroundColor,
                      use24hFormat: true,
                      minuteInterval: 1,
                    ),
                  ),
                ),

                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
                  child: ElevatedButton.icon(
                    onPressed: () {
                      setState(() {
                        _selectedTime = TimeOfDay.fromDateTime(tempDateTime);
                        _selectedDate = DateTime(
                          _selectedDate!.year,
                          _selectedDate!.month,
                          _selectedDate!.day,
                          tempDateTime.hour,
                          tempDateTime.minute,
                        );
                      });
                      Navigator.of(context).pop();
                    },

                    icon: Icon(
                      Icons.check_circle_outline,
                      color: finalContentColor,
                    ),
                    label: Text(
                      'Confirmar Hora',

                      style: TextStyle(color: finalContentColor, fontSize: 16),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: finalButtonColor,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      elevation: 3,
                    ),
                  ),
                ),
              ],
            ),
          ),
    );
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
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final accentColor =
        isDark ? theme.colorScheme.secondary : Colors.deepOrange;
    final lightBgColor = isDark ? Colors.grey.shade900 : Colors.orange.shade50;
    final primaryTextColor = isDark ? Colors.white : Colors.deepOrange.shade700;

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
                        (type) => DropdownMenuItem(
                          value: type,
                          child: Text(
                            type,
                            style: TextStyle(
                              color: isDark ? Colors.white70 : Colors.black,
                            ),
                          ),
                        ),
                      )
                      .toList(),
              onChanged: (value) => setState(() => _selectedMealType = value),
              decoration: InputDecoration(
                labelText: 'Tipo de refeição',
                prefixIcon: Icon(Icons.restaurant, color: accentColor),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: lightBgColor,
              ),
            ),

            const SizedBox(height: 16),

            Text(
              'Data e Hora da Refeição',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: primaryTextColor,
              ),
            ),

            const SizedBox(height: 8),

            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.calendar_today, color: Colors.white),
                    label: Text(
                      _selectedDate != null
                          ? DateFormat('dd/MM/yyyy').format(_selectedDate!)
                          : 'Selecionar data',
                      style: const TextStyle(color: Colors.white),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.deepOrange.shade400,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    onPressed: _pickDate,
                  ),
                ),

                const SizedBox(width: 12),

                Expanded(
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.access_time, color: Colors.white),
                    label: Text(
                      _selectedDate != null
                          ? DateFormat('HH:mm').format(_selectedDate!)
                          : 'Selecionar hora',
                      style: const TextStyle(color: Colors.white),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.deepOrange.shade400,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    onPressed: _showCupertinoTimePicker,
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
                color: primaryTextColor,
              ),
            ),

            const SizedBox(height: 8),

            if (_foods.isEmpty)
              Text(
                'Nenhum alimento adicionado.',
                style: TextStyle(
                  color: isDark ? Colors.grey[400] : Colors.grey[600],
                ),
              ),

            ..._foods.asMap().entries.map((entry) {
              final index = entry.key;
              final food = entry.value;
              final isFavorite = _favoriteFoods.any(
                (f) => f['name'] == food['name'],
              );

              return Card(
                elevation: 2,
                color: isDark ? Colors.grey.shade800 : null,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                margin: const EdgeInsets.symmetric(vertical: 6),
                child: ListTile(
                  contentPadding: const EdgeInsets.only(left: 16, right: 8),
                  leading: Icon(Icons.food_bank, color: accentColor),
                  title: Text(
                    food['name'],
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: isDark ? Colors.white : Colors.black,
                    ),
                  ),
                  subtitle: Text(
                    'Porção: ${food['portion']}',
                    style: TextStyle(
                      color: isDark ? Colors.grey[400] : Colors.grey[700],
                    ),
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: Icon(
                          isFavorite ? Icons.star : Icons.star_border,
                          color: Colors.amber,
                        ),
                        onPressed: () {
                          setState(() {
                            _toggleFavoriteFood(food);
                          });
                        },
                      ),
                      IconButton(
                        icon: Icon(
                          Icons.delete_sweep_outlined,
                          color: Colors.red.shade700,
                        ),
                        onPressed: () {
                          setState(() {
                            _foods.removeAt(index);
                          });
                        },
                      ),
                    ],
                  ),
                ),
              );
            }),

            TextButton.icon(
              onPressed: _addFood,
              icon: Icon(Icons.add_circle_outline, color: accentColor),
              label: Text(
                'Adicionar Alimento',
                style: TextStyle(
                  color: accentColor,
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
                color: primaryTextColor,
              ),
            ),

            const SizedBox(height: 12),

            Container(
              height: 200,
              decoration: BoxDecoration(
                color: lightBgColor,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color:
                      isDark
                          ? Colors.grey.shade700
                          : Colors.deepOrange.shade200,
                ),
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
                          style: TextStyle(
                            color: isDark ? Colors.grey[400] : Colors.grey[600],
                          ),
                        ),
              ),
            ),

            const SizedBox(height: 8),

            TextButton.icon(
              onPressed: _pickImage,
              icon: Icon(Icons.camera_alt, color: accentColor),
              label: Text(
                'Selecionar Foto',
                style: TextStyle(
                  color: accentColor,
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
