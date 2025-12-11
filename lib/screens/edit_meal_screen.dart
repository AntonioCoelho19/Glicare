import 'dart:io';
import 'package:flutter/cupertino.dart';
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

    // Sincronizando o _selectedDate para garantir que não seja nulo na inicialização
    if (_selectedDate == null) {
      _selectedDate = DateTime.now();
    }

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

    // Define a cor de destaque (accentColor) para o TextButton
    final accentColor =
        Theme.of(context).brightness == Brightness.dark
            ? Theme.of(context).colorScheme.secondary
            : Colors.deepOrange;

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

  Future<void> _showCupertinoTimePicker() async {
    // Garantia de não-nulidade: Inicializa com a hora atual se nulo.
    if (_selectedDate == null) {
      _selectedDate = DateTime.now();
    }

    // Usa o valor garantido (_selectedDate!)
    DateTime tempDateTime = DateTime(
      _selectedDate!.year,
      _selectedDate!.month,
      _selectedDate!.day,
      _selectedDate!.hour,
      _selectedDate!.minute,
    );

    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final pickerTextColor = isDark ? Colors.white : Colors.black;
    final pickerBackgroundColor = isDark ? Colors.black : Colors.white;

    final titleTextColor = isDark ? Colors.white : Colors.deepOrange.shade700;

    late Color finalButtonColor;
    late Color finalContentColor;

    if (isDark) {
      finalButtonColor = theme.colorScheme.secondary;
      finalContentColor = Colors.black;
    } else {
      finalButtonColor = Colors.deepOrange;
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
                    'Selecione a Hora da Refeição',
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
    // 💡 DEFINIÇÕES DE TEMA PARA CONTRASTE
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final accentColor =
        isDark
            ? theme.colorScheme.secondary
            : Colors.deepOrange; // DeepOrange para claro, Accent para escuro
    final lightBgColor =
        isDark
            ? Colors.grey.shade900
            : Colors
                .grey
                .shade100; // Fundo claro adaptável (Usando shade100 que é mais neutro que orange.shade50)
    final primaryTextColor = isDark ? Colors.white : Colors.deepOrange.shade700;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Editar Refeição'),
        backgroundColor: Colors.deepOrange,
        foregroundColor:
            Colors.white, // Garantir cor do título/ícones no AppBar
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: ListView(
          children: [
            // --- 1. Dropdown Tipo de Refeição ---
            DropdownButtonFormField<String>(
              initialValue: _selectedMealType,
              items:
                  _mealTypes
                      .map(
                        (type) => DropdownMenuItem<String>(
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
              onChanged: (value) {
                setState(() {
                  _selectedMealType = value;
                });
              },
              decoration: InputDecoration(
                labelText: 'Tipo da refeição *',
                prefixIcon: Icon(Icons.restaurant, color: accentColor),
                border: const OutlineInputBorder(),
                filled: true,
                fillColor: lightBgColor,
              ),
            ),

            const SizedBox(height: 20),

            // --- 2. Título da Seção Alimentos ---
            Text(
              'Alimentos',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 18,
                color: primaryTextColor,
              ),
            ),
            const SizedBox(height: 8),

            ElevatedButton.icon(
              onPressed: _addFood,
              icon: const Icon(Icons.add, color: Colors.white),
              label: const Text(
                'Adicionar alimento',
                style: TextStyle(color: Colors.white),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.deepOrange,
                padding: const EdgeInsets.symmetric(vertical: 10),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),

            const SizedBox(height: 12),

            // Lista de Alimentos
            if (_foods.isNotEmpty)
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _foods.length,
                itemBuilder: (context, index) {
                  final food = _foods[index];
                  return Card(
                    margin: const EdgeInsets.symmetric(vertical: 6),
                    color:
                        isDark
                            ? Colors.grey.shade800
                            : null, // Cor do Card adaptável
                    child: ListTile(
                      title: Text(
                        food['name'],
                        style: TextStyle(
                          color: isDark ? Colors.white : Colors.black,
                        ),
                      ),
                      subtitle: Text(
                        food['portion'],
                        style: TextStyle(
                          color:
                              isDark
                                  ? Colors.grey.shade400
                                  : Colors.grey.shade700,
                        ),
                      ),
                      trailing: IconButton(
                        icon: Icon(
                          Icons.delete,
                          color: isDark ? Colors.red.shade400 : Colors.red,
                        ),
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

            const SizedBox(height: 20),

            // --- 3. Título da Seção Data/Hora ---
            Text(
              'Data e Hora da Refeição',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: primaryTextColor, // Cor adaptável
              ),
            ),
            const SizedBox(height: 8),

            // Botões de Data e Hora
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _pickDate,
                    icon: const Icon(Icons.calendar_today, color: Colors.white),
                    label: Text(
                      _selectedDate == null
                          ? 'Selecionar data'
                          : DateFormat('dd/MM/yyyy').format(_selectedDate!),
                      style: const TextStyle(color: Colors.white),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.deepOrange.shade400,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _showCupertinoTimePicker,
                    icon: const Icon(Icons.access_time, color: Colors.white),
                    label: Text(
                      _selectedDate == null
                          ? 'Selecionar hora'
                          : DateFormat('HH:mm').format(_selectedDate!),
                      style: const TextStyle(color: Colors.white),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.deepOrange.shade400,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 20),

            // --- 4. Seção Imagem ---
            Text(
              'Foto da refeição',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 18,
                color: primaryTextColor,
              ),
            ),
            const SizedBox(height: 12),

            // Container de Imagem
            Container(
              height: 200,
              decoration: BoxDecoration(
                color: lightBgColor, // Fundo adaptável
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

            // Botão Selecionar Imagem
            TextButton.icon(
              onPressed: _pickImage,
              icon: Icon(Icons.photo_library, color: accentColor),
              label: Text(
                'Selecionar imagem',
                style: TextStyle(
                  color: accentColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Botão Salvar Alterações
            ElevatedButton(
              onPressed: _saveMeal,
              child: const Text(
                'Salvar Alterações',
                style: TextStyle(color: Colors.white),
              ),
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
