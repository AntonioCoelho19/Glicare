import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../models/medication.dart';
import 'package:intl/intl.dart';

class AddMedicationScreen extends StatefulWidget {
  final void Function(Medication) onAdd;

  const AddMedicationScreen({super.key, required this.onAdd});

  @override
  State<AddMedicationScreen> createState() => _AddMedicationScreenState();
}

class _AddMedicationScreenState extends State<AddMedicationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _dosageController = TextEditingController();
  final _unitController = TextEditingController();
  final _frequencyController = TextEditingController();
  DateTime _startDate = DateTime.now();
  int _durationDays = 1;

  void _submitForm() {
    if (_formKey.currentState!.validate()) {
      final medication = Medication(
        id: const Uuid().v4(),
        name: _nameController.text,
        dosage: double.parse(_dosageController.text),
        unit: _unitController.text,
        timesPerDay: int.parse(_frequencyController.text),
        startDate: _startDate,
        durationDays: _durationDays,
      );

      widget.onAdd(medication);
      Navigator.of(context).pop();
    }
  }

  void _pickStartDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _startDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (date != null) {
      setState(() => _startDate = date);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Adicionar Medicamento')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Card(
          elevation: 4,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Form(
              key: _formKey,
              child: ListView(
                children: [
                  _buildTextField(
                    _nameController,
                    'Nome do Medicamento',
                    Icons.medication,
                  ),
                  _buildTextField(
                    _dosageController,
                    'Dosagem',
                    Icons.local_hospital,
                    isNumber: true,
                  ),
                  _buildTextField(
                    _unitController,
                    'Unidade (mg/ml/etc)',
                    Icons.straighten,
                  ),
                  _buildTextField(
                    _frequencyController,
                    'Vezes ao dia',
                    Icons.schedule,
                    isNumber: true,
                  ),
                  const SizedBox(height: 16),
                  ListTile(
                    leading: const Icon(Icons.calendar_today),
                    title: const Text('Data de Início'),
                    subtitle: Text(DateFormat('dd/MM/yyyy').format(_startDate)),
                    trailing: IconButton(
                      icon: const Icon(Icons.edit_calendar),
                      onPressed: _pickStartDate,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Slider(
                    value: _durationDays.toDouble(),
                    min: 1,
                    max: 60,
                    divisions: 59,
                    label: '$_durationDays dias',
                    onChanged: (value) {
                      setState(() => _durationDays = value.toInt());
                    },
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    icon: const Icon(Icons.check, color: Colors.white),
                    label: const Text(
                      'Salvar Medicamento',
                      style: TextStyle(color: Colors.white),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      textStyle: const TextStyle(fontSize: 16),
                    ),
                    onPressed: _submitForm,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(
    TextEditingController controller,
    String label,
    IconData icon, {
    bool isNumber = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: TextFormField(
        controller: controller,
        keyboardType: isNumber ? TextInputType.number : TextInputType.text,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        ),
        validator: (value) {
          if (value == null || value.trim().isEmpty) return 'Campo obrigatório';
          if (isNumber && double.tryParse(value) == null)
            return 'Insira um número válido';
          return null;
        },
      ),
    );
  }
}
