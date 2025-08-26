import 'package:flutter/material.dart';
import '../models/registry.dart';
import '../models/medication.dart';
import '../database/registry_db.dart';
import '../database/medication_db.dart';
import 'add_registry_screen.dart';

class RegistryDetailScreen extends StatefulWidget {
  final Registry registry;
  final List<Medication> medications;
  final Future<void> Function(Registry)? onUpdate;
  final Future<void> Function(Medication) onAddMedication;

  const RegistryDetailScreen({
    super.key,
    required this.registry,
    required this.medications,
    this.onUpdate,
    required this.onAddMedication,
  });

  @override
  State<RegistryDetailScreen> createState() => _RegistryDetailScreenState();
}

class _RegistryDetailScreenState extends State<RegistryDetailScreen> {
  final RegistryDB _registryDB = RegistryDB();
  final MedicationDB _medicationDB = MedicationDB();
  late Registry _editableRegistry;

  @override
  void initState() {
    super.initState();
    _editableRegistry = widget.registry;
  }

  Future<void> _editRegistry() async {
    final updated = await Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (_) => AddRegistryScreen(
              registry: _editableRegistry,
              medications: widget.medications,
              onAdd: widget.onUpdate,
              onAddMedication: widget.onAddMedication,
            ),
      ),
    );

    if (updated is Registry) {
      setState(() {
        _editableRegistry = updated;
      });
    }
  }

  void _deleteRegistry() async {
    await _registryDB.deleteRegistry(_editableRegistry.id);
    Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Detalhes do Registro'),
        actions: [
          IconButton(icon: const Icon(Icons.edit), onPressed: _editRegistry),
          IconButton(
            icon: const Icon(Icons.delete),
            onPressed: _deleteRegistry,
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Glicemia: ${_editableRegistry.glicemia} mg/dL'),
            const SizedBox(height: 8),
            Text('Insulina Longa: ${_editableRegistry.insulinaLonga} U'),
            const SizedBox(height: 8),
            Text('Insulina Longa: ${_editableRegistry.insulinaCurta} U'),
            const SizedBox(height: 8),
            Text('Data: ${_editableRegistry.date.toLocal()}'),
            const SizedBox(height: 8),
            if (_editableRegistry.medication != null)
              Text('Medicamento: ${_editableRegistry.medication!.name}'),
          ],
        ),
      ),
    );
  }
}
