// add_registry_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:intl/intl.dart';
import '../models/registry.dart';
import '../models/medication.dart';
import '../database/registry_db.dart';
import 'add_medication_screen.dart';
import 'add_meal_screen.dart';
// import 'package:image_picker/image_picker.dart'; // Não é usado neste arquivo
// import 'dart:io'; // Não é usado neste arquivo
import '../models/meal.dart';
import '../database/medication_db.dart'; // Adicionado para deletar

class AddRegistryScreen extends StatefulWidget {
  final Future<void> Function(Registry)? onAdd;
  final Registry? registry;
  final List<Medication>
  medications; // Esta lista será usada apenas no initState
  final Future<void> Function(Medication) onAddMedication;

  const AddRegistryScreen({
    super.key,
    this.onAdd,
    this.registry,
    required this.medications,
    required this.onAddMedication,
  });

  @override
  State<AddRegistryScreen> createState() => _AddRegistryScreenState();
}

class _AddRegistryScreenState extends State<AddRegistryScreen> {
  final RegistryDB _registryDB = RegistryDB();
  final MedicationDB _medicationDB = MedicationDB(); // Adicionado para deletar

  final _formKey = GlobalKey<FormState>();
  final _glycemiaController = TextEditingController();
  final _insulinLongaController = TextEditingController();
  final _insulinCurtaController = TextEditingController();

  int _selectedTabIndex = 0;
  DateTime _selectedDate = DateTime.now();
  TimeOfDay _selectedTime = TimeOfDay.now();
  Medication? _selectedMedication;

  // Lista local para gerenciar o estado e permitir atualização
  List<Medication> _localMedications = [];

  List<Meal> _meals = [];

  final TextEditingController _weightController = TextEditingController();
  bool _isPressureEnabled = false;
  int? _systolic;
  int? _diastolic;

  final TextEditingController _activityNameController = TextEditingController();
  final TextEditingController _durationController = TextEditingController();
  final TextEditingController _caloriesController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  String? _intensity;
  bool _showActivityFields = false;

  @override
  void initState() {
    super.initState();
    // Inicializa a lista local com os medicamentos passados
    _localMedications = List.from(widget.medications);

    if (widget.registry != null) {
      final registry = widget.registry!;
      _glycemiaController.text = registry.glicemia.toString();
      _insulinLongaController.text = registry.insulinaLonga.toString();
      _insulinCurtaController.text = registry.insulinaCurta.toString();
      _selectedDate = registry.date;
      _selectedTime = TimeOfDay.fromDateTime(registry.date);

      final selectedList =
          _localMedications
              .where((m) => m.name == registry.medication?.name)
              .toList();

      _selectedMedication = selectedList.isNotEmpty ? selectedList.first : null;

      _weightController.text = registry.weight?.toString() ?? '';
      _systolic = registry.systolic;
      _diastolic = registry.diastolic;
      _activityNameController.text = registry.activityName ?? '';
      _durationController.text = registry.activityDuration?.toString() ?? '';
      _caloriesController.text = registry.caloriesBurned?.toString() ?? '';
      _descriptionController.text = registry.activityDescription ?? '';
      _intensity = registry.activityIntensity;
      _showActivityFields =
          registry.activityName != null && registry.activityName!.isNotEmpty;
    } else {
      _insulinLongaController.text = '0';
      _insulinCurtaController.text = '0';
      _intensity = 'Moderada';
    }
  }

  Future<void> _reloadMedications() async {
    final updatedMedications = await _medicationDB.getAllMedications();
    setState(() {
      _localMedications = updatedMedications;
    });
  }

  Future<void> _deleteRegistry() async {
    if (widget.registry == null) return;
    await _registryDB.deleteRegistry(widget.registry!.id);
    Navigator.of(context).pop(true);
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;

    // Pequena correção: Garante que os valores de insulina sejam double
    final insulinaLongaValue =
        double.tryParse(_insulinLongaController.text) ?? 0.0;
    final insulinaCurtaValue =
        double.tryParse(_insulinCurtaController.text) ?? 0.0;

    final combinedDateTime = DateTime(
      _selectedDate.year,
      _selectedDate.month,
      _selectedDate.day,
      _selectedTime.hour,
      _selectedTime.minute,
    );

    final newRegistry = Registry(
      id:
          widget.registry?.id ??
          DateTime.now().millisecondsSinceEpoch.toString(),
      date: combinedDateTime,
      glicemia: int.parse(_glycemiaController.text),
      insulinaLonga: insulinaLongaValue,
      insulinaCurta: insulinaCurtaValue,
      medication: _selectedMedication,
      weight: double.tryParse(_weightController.text),
      systolic: _systolic,
      diastolic: _diastolic,
      // Garante que se a atividade não for mostrada, os campos sejam nulos/vazios
      activityName: _showActivityFields ? _activityNameController.text : null,
      activityDuration:
          _showActivityFields ? int.tryParse(_durationController.text) : null,
      activityIntensity: _showActivityFields ? _intensity : null,
      caloriesBurned:
          _showActivityFields ? int.tryParse(_caloriesController.text) : null,
      activityDescription:
          _showActivityFields ? _descriptionController.text : null,
    );

    await widget.onAdd!(newRegistry);
    Navigator.of(context).pop(true);
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  // ... (O resto da função _showCupertinoTimePicker permanece o mesmo) ...
  Future<void> _showCupertinoTimePicker() async {
    // ... Código da função de seleção de hora permanece o mesmo ...
    DateTime tempDateTime = DateTime(
      _selectedDate.year,
      _selectedDate.month,
      _selectedDate.day,
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
  // ... (Fim da função _showCupertinoTimePicker) ...

  void _chooseMedication() async {
    final choice = await showModalBottomSheet<String>(
      context: context,
      builder: (_) {
        return Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.list),
              title: const Text('Escolher existente'),
              onTap: () => Navigator.of(context).pop('select'),
            ),
            ListTile(
              leading: const Icon(Icons.add),
              title: const Text('Criar novo'),
              onTap: () => Navigator.of(context).pop('new'),
            ),
            // NOVA OPÇÃO: EXCLUIR MEDICAMENTO
            if (_localMedications.isNotEmpty)
              ListTile(
                leading: const Icon(Icons.delete_forever, color: Colors.red),
                title: const Text(
                  'Excluir medicamento',
                  style: TextStyle(color: Colors.red),
                ),
                onTap: () => Navigator.of(context).pop('delete'),
              ),
            // Opção para remover seleção atual, se houver
            if (_selectedMedication != null)
              ListTile(
                leading: const Icon(Icons.clear),
                title: const Text('Remover seleção atual'),
                onTap: () => Navigator.of(context).pop('remove'),
              ),
          ],
        );
      },
    );

    if (choice == 'remove') {
      setState(() {
        _selectedMedication = null;
      });
      return;
    }

    if (choice == 'select') {
      final selected = await showDialog<Medication>(
        context: context,
        builder:
            (_) => SimpleDialog(
              title: const Text('Escolha um medicamento'),
              children: [
                // Adiciona a opção de NENHUM medicamento
                SimpleDialogOption(
                  child: const Text('Nenhum'),
                  onPressed: () => Navigator.pop(context, null),
                ),
                // Mapeia a lista LOCAL de medicamentos
                ..._localMedications
                    .map(
                      (med) => SimpleDialogOption(
                        child: Text(med.name),
                        onPressed: () => Navigator.pop(context, med),
                      ),
                    )
                    .toList(),
              ],
            ),
      );

      if (selected != null || selected == null) {
        // Permite selecionar NULL
        setState(() {
          _selectedMedication = selected;
        });
      }
    } else if (choice == 'new') {
      // Abre a tela de adição e espera o resultado
      final newMed = await Navigator.of(context).push(
        MaterialPageRoute(
          builder:
              (_) => AddMedicationScreen(
                // Modificado para retornar o novo medicamento
                onAdd: (med) => widget.onAddMedication(med),
              ),
        ),
      );

      // Se um novo medicamento foi retornado e adicionado, recarregamos a lista
      if (newMed != null) {
        await _reloadMedications(); // Recarrega a lista
        setState(() {
          _selectedMedication = newMed; // Seleciona o recém-adicionado
        });
      }
    } else if (choice == 'delete') {
      await _deleteMedicationOption();
    }
  }

  // NOVA FUNÇÃO: DELETAR MEDICAMENTO
  Future<void> _deleteMedicationOption() async {
    final medicationToDelete = await showDialog<Medication>(
      context: context,
      builder:
          (_) => SimpleDialog(
            title: const Text(
              'Selecione o medicamento para EXCLUIR',
              style: TextStyle(color: Colors.red),
            ),
            children:
                _localMedications
                    .map(
                      (med) => SimpleDialogOption(
                        child: Text(
                          med.name,
                          style: const TextStyle(color: Colors.red),
                        ),
                        onPressed: () => Navigator.pop(context, med),
                      ),
                    )
                    .toList(),
          ),
    );

    if (medicationToDelete != null) {
      final confirmed = await showDialog<bool>(
        context: context,
        builder:
            (ctx) => AlertDialog(
              title: const Text('Confirmar Exclusão'),
              content: Text(
                'Tem certeza que deseja excluir o medicamento "${medicationToDelete.name}"?',
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(ctx).pop(false),
                  child: const Text('Cancelar'),
                ),
                TextButton(
                  onPressed: () => Navigator.of(ctx).pop(true),
                  child: const Text(
                    'Excluir',
                    style: TextStyle(color: Colors.red),
                  ),
                ),
              ],
            ),
      );

      if (confirmed == true) {
        await _medicationDB.deleteMedication(
          medicationToDelete.id,
        ); // Assumindo que a model Medication tem 'id'
        await _reloadMedications(); // Recarrega a lista
        if (_selectedMedication?.id == medicationToDelete.id) {
          setState(() {
            _selectedMedication =
                null; // Remove a seleção se for o medicamento excluído
          });
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${medicationToDelete.name} excluído com sucesso!'),
          ),
        );
      }
    }
  }

  // ... (O resto dos métodos de construção de abas permanecem os mesmos) ...

  Widget _buildPrincipalTab() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Form(
        key: _formKey,
        child: ListView(
          children: [
            TextFormField(
              controller: _glycemiaController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Glicemia (mg/dL)',
                prefixIcon: Icon(Icons.water_drop),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) return 'Informe a glicemia';
                return null;
              },
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _insulinLongaController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Insulina Longa(U)',
                prefixIcon: Icon(Icons.bloodtype),
              ),
              validator: (value) {
                if (value == null || value.isEmpty)
                  return 'Informe a insulina longa';
                return null;
              },
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _insulinCurtaController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Insulina Curta(U)',
                prefixIcon: Icon(Icons.bloodtype),
              ),
              validator: (value) {
                if (value == null || value.isEmpty)
                  return 'Informe a insulina curta';
                return null;
              },
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(Icons.calendar_today),
              title: Text(
                'Data: ${DateFormat('dd/MM/yyyy').format(_selectedDate)}',
              ),
              trailing: const Icon(Icons.edit),
              onTap: _pickDate,
            ),
            ListTile(
              leading: const Icon(Icons.access_time),
              title: Text('Hora: ${_selectedTime.format(context)}'),
              trailing: const Icon(Icons.edit),
              onTap: _showCupertinoTimePicker,
            ),
            ListTile(
              leading: const Icon(Icons.medication),
              title: Text(
                _selectedMedication == null
                    ? 'Nenhum medicamento selecionado'
                    : 'Medicamento: ${_selectedMedication!.name}',
              ),
              trailing: const Icon(Icons.edit),
              onTap: _chooseMedication,
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: _submitForm,
              icon: const Icon(Icons.check, color: Colors.white),
              label: Text(
                style: TextStyle(color: Colors.white),
                widget.registry != null
                    ? 'Atualizar Registro'
                    : 'Salvar Registro',
              ),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
                backgroundColor: Colors.green,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRefeicoesTab() {
    return AddMealScreen(
      onAdd: (Meal meal) {
        setState(() {
          _meals.add(meal);
        });
      },
    );
  }

  void _showBloodPressurePicker() {
    int tempSystolic = _systolic ?? 120;
    int tempDiastolic = _diastolic ?? 80;

    showModalBottomSheet(
      context: context,
      builder:
          (_) => SizedBox(
            height: 300,
            child: Column(
              children: [
                const SizedBox(height: 12),
                const Text(
                  'Selecione a Pressão Arterial',
                  style: TextStyle(fontSize: 16),
                ),
                Expanded(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Expanded(
                        child: CupertinoPicker(
                          itemExtent: 32,
                          scrollController: FixedExtentScrollController(
                            initialItem: tempSystolic - 50,
                          ),
                          onSelectedItemChanged: (value) {
                            tempSystolic = value + 50;
                          },
                          children: List.generate(
                            200,
                            (i) => Text('${i + 50}'),
                          ),
                        ),
                      ),
                      const Text('/', style: TextStyle(fontSize: 18)),
                      Expanded(
                        child: CupertinoPicker(
                          itemExtent: 32,
                          scrollController: FixedExtentScrollController(
                            initialItem: tempDiastolic - 30,
                          ),
                          onSelectedItemChanged: (value) {
                            tempDiastolic = value + 30;
                          },
                          children: List.generate(
                            150,
                            (i) => Text('${i + 30}'),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    TextButton(
                      onPressed: () {
                        setState(() {
                          _systolic = null;
                          _diastolic = null;
                        });
                        Navigator.of(context).pop();
                      },
                      child: const Text('Limpar'),
                    ),
                    TextButton(
                      onPressed: () {
                        setState(() {
                          _systolic = tempSystolic;
                          _diastolic = tempDiastolic;
                        });
                        Navigator.of(context).pop();
                      },
                      child: const Text('Confirmar'),
                    ),
                  ],
                ),
              ],
            ),
          ),
    );
  }

  Widget _buildGeneralTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
            controller: _weightController,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(labelText: 'Peso (kg)'),
          ),
          const SizedBox(height: 24),

          ListTile(
            title: const Text('Pressão Sanguínea'),
            subtitle: Text(
              (_systolic != null && _diastolic != null)
                  ? '$_systolic/$_diastolic mmHg'
                  : 'Não informada',
            ),
            trailing: const Icon(Icons.arrow_forward_ios),
            onTap: _showBloodPressurePicker,
          ),
          const SizedBox(height: 24),

          ListTile(
            title: const Text('Atividade Física'),
            trailing: Icon(
              _showActivityFields ? Icons.expand_less : Icons.expand_more,
            ),
            onTap: () {
              setState(() => _showActivityFields = !_showActivityFields);
            },
          ),

          if (_showActivityFields) ...[
            const SizedBox(height: 8),
            TextField(
              controller: _activityNameController,
              decoration: const InputDecoration(labelText: 'Nome da Atividade'),
            ),
            TextField(
              controller: _durationController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Duração (min)'),
            ),
            DropdownButtonFormField<String?>(
              initialValue: _intensity,
              items: const [
                DropdownMenuItem(value: null, child: Text('-')),
                DropdownMenuItem(value: 'Leve', child: Text('Leve')),
                DropdownMenuItem(value: 'Moderada', child: Text('Moderada')),
                DropdownMenuItem(value: 'Intensa', child: Text('Intensa')),
              ],
              onChanged: (value) => setState(() => _intensity = value),
              decoration: const InputDecoration(labelText: 'Intensidade'),
              hint: const Text('Selecione a intensidade'),
            ),
            TextField(
              controller: _caloriesController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Calorias Gastas'),
            ),
            TextField(
              controller: _descriptionController,
              maxLines: 2,
              decoration: const InputDecoration(labelText: 'Descrição'),
            ),
          ],
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screens = [
      _buildPrincipalTab(),
      _buildRefeicoesTab(),
      _buildGeneralTab(),
    ];

    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.registry != null ? 'Editar Registro' : 'Novo Registro',
        ),
        actions: [
          if (widget.registry != null)
            IconButton(
              icon: const Icon(Icons.delete),
              onPressed: _deleteRegistry,
            ),
        ],
      ),
      body: screens[_selectedTabIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedTabIndex,
        onTap: (index) => setState(() => _selectedTabIndex = index),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.edit), label: 'Principal'),
          BottomNavigationBarItem(
            icon: Icon(Icons.restaurant),
            label: 'Refeições',
          ),
          BottomNavigationBarItem(icon: Icon(Icons.settings), label: 'Geral'),
        ],
      ),
    );
  }
}
