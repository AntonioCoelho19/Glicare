import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/registry.dart';
import '../models/medication.dart';
import '../database/registry_db.dart';
import '../database/medication_db.dart';
import 'add_registry_screen.dart';

class ListScreen extends StatefulWidget {
  const ListScreen({super.key});

  @override
  State<ListScreen> createState() => _ListScreenState();
}

class _ListScreenState extends State<ListScreen> {
  final RegistryDB _registryDB = RegistryDB();
  final MedicationDB _medicationDB = MedicationDB();

  List<Registry> _registries = [];
  List<Medication> _medications = [];

  DateTime? _startDate;
  DateTime? _endDate;
  String? _selectedPeriod = 'Última semana';
  String _searchText = '';
  Medication? _selectedMedication;
  int? _glicemiaMin;
  int? _glicemiaMax;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final loadedRegistries = await _registryDB.getRegistries();
    final loadedMedications = await _medicationDB.getAllMedications();
    setState(() {
      _registries = loadedRegistries;
      _medications = loadedMedications;
    });
  }

  void _applyFilterPeriod(String? selected) async {
    final now = DateTime.now();
    setState(() {
      _selectedPeriod = selected;
      if (selected == 'Última semana') {
        _startDate = now.subtract(const Duration(days: 7));
        _endDate = now;
      } else if (selected == 'Último mês') {
        _startDate = DateTime(now.year, now.month - 1, now.day);
        _endDate = now;
      } else if (selected == 'Personalizado') {
        _startDate = null;
        _endDate = null;
      } else if (selected == '-') {
        _startDate = null;
        _endDate = null;
      }
    });

    if (selected == 'Personalizado') {
      final picked = await showDateRangePicker(
        context: context,
        firstDate: DateTime(2000),
        lastDate: DateTime.now(),
      );
      if (picked != null) {
        setState(() {
          _startDate = picked.start;
          _endDate = picked.end;
        });
      }
    }
  }

  List<Registry> _getFilteredRegistries() {
    return _registries.where((r) {
      final isWithinPeriod =
          _startDate == null ||
          (_startDate!.isBefore(r.date) && _endDate!.isAfter(r.date));
      final matchesMedication =
          _selectedMedication == null ||
          (r.medication?.name == _selectedMedication!.name);
      final matchesSearch =
          _searchText.isEmpty ||
          (r.medication?.name.toLowerCase().contains(
                _searchText.toLowerCase(),
              ) ??
              false);
      final matchesGlicemia =
          (_glicemiaMin == null || r.glicemia >= _glicemiaMin!) &&
          (_glicemiaMax == null || r.glicemia <= _glicemiaMax!);

      return isWithinPeriod &&
          matchesMedication &&
          matchesSearch &&
          matchesGlicemia;
    }).toList();
  }

  Map<String, List<Registry>> _groupRegistriesByDate(List<Registry> filtered) {
    Map<String, List<Registry>> grouped = {};

    final sortedRegistries = [...filtered];
    sortedRegistries.sort((a, b) => b.date.compareTo(a.date));

    for (var r in sortedRegistries) {
      final dateKey = _formatDate(r.date);
      grouped.putIfAbsent(dateKey, () => []).add(r);
    }

    return grouped;
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final dateToCompare = DateTime(date.year, date.month, date.day);

    if (dateToCompare == today) return 'Hoje';
    if (dateToCompare == yesterday) return 'Ontem';
    return DateFormat("d 'de' MMM", 'pt_BR').format(date);
  }

  Widget _buildRegistryCard(Registry registry) {
    return InkWell(
      onTap: () async {
        final updatedRegistry = await Navigator.push(
          context,
          MaterialPageRoute(
            builder:
                (_) => AddRegistryScreen(
                  registry: registry,
                  medications: _medications,
                  onAdd: (updated) async {
                    await _registryDB.updateRegistry(updated);
                  },
                  onAddMedication: (newMed) async {
                    await _medicationDB.insertMedication(newMed);
                    await _loadData();
                  },
                ),
          ),
        );

        if (updatedRegistry != null) {
          await _loadData();
          setState(() {});
        }
      },
      child: Card(
        elevation: 2,
        margin: const EdgeInsets.symmetric(vertical: 6),
        child: ListTile(
          leading: const Icon(Icons.bloodtype, color: Colors.red),
          title: Text('Glicemia: ${registry.glicemia} mg/dL'),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Insulina Longa: ${registry.insulinaLonga} U'),
              Text('Insulina Curta: ${registry.insulinaCurta} U'),
              if (registry.medication != null)
                Text('Medicação: ${registry.medication!.name}'),
              if (registry.weight != null) Text('Peso: ${registry.weight} kg'),
              if (registry.systolic != null && registry.diastolic != null)
                Text(
                  'Pressão: ${registry.systolic}/${registry.diastolic} mmHg',
                ),
              if (registry.activityName != null &&
                  registry.activityName!.trim().isNotEmpty)
                Text(
                  registry.activityIntensity != null &&
                          registry.activityIntensity!.trim().isNotEmpty
                      ? 'Atividade: ${registry.activityName} (${registry.activityIntensity})'
                      : 'Atividade: ${registry.activityName}',
                ),
            ],
          ),
          trailing: Text(
            DateFormat('HH:mm').format(registry.date),
            style: const TextStyle(fontSize: 14, color: Colors.deepOrange),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _getFilteredRegistries();
    final grouped = _groupRegistriesByDate(filtered);

    return Scaffold(
      appBar: AppBar(title: const Text('Registros')),
      body: Column(
        children: [
          ExpansionTile(
            title: const Text('Filtros'),
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  children: [
                    DropdownButtonFormField<String>(
                      initialValue: _selectedPeriod,
                      items: const [
                        DropdownMenuItem(value: '-', child: Text('-')),
                        DropdownMenuItem(
                          value: 'Última semana',
                          child: Text('Última semana'),
                        ),
                        DropdownMenuItem(
                          value: 'Último mês',
                          child: Text('Último mês'),
                        ),
                        DropdownMenuItem(
                          value: 'Personalizado',
                          child: Text('Personalizado'),
                        ),
                      ],

                      onChanged: _applyFilterPeriod,
                      decoration: const InputDecoration(labelText: 'Período'),
                    ),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<Medication>(
                      initialValue: _selectedMedication,
                      items: [
                        const DropdownMenuItem<Medication>(
                          value: null,
                          child: Text('-'),
                        ),
                        ..._medications.map(
                          (m) =>
                              DropdownMenuItem(value: m, child: Text(m.name)),
                        ),
                      ],

                      onChanged:
                          (value) =>
                              setState(() => _selectedMedication = value),
                      decoration: const InputDecoration(
                        labelText: 'Filtrar por Medicação',
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      decoration: const InputDecoration(
                        labelText: 'Buscar medicamento...',
                      ),
                      onChanged: (value) => setState(() => _searchText = value),
                    ),
                    Row(
                      children: [
                        Flexible(
                          child: TextFormField(
                            decoration: const InputDecoration(
                              labelText: 'Glicemia Mín.',
                            ),
                            keyboardType: TextInputType.number,
                            onChanged:
                                (v) => setState(
                                  () => _glicemiaMin = int.tryParse(v),
                                ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Flexible(
                          child: TextFormField(
                            decoration: const InputDecoration(
                              labelText: 'Glicemia Máx.',
                            ),
                            keyboardType: TextInputType.number,
                            onChanged:
                                (v) => setState(
                                  () => _glicemiaMax = int.tryParse(v),
                                ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
            ],
          ),
          Expanded(
            child:
                filtered.isEmpty
                    ? const Center(child: Text('Nenhum registro encontrado.'))
                    : ListView.builder(
                      padding: const EdgeInsets.all(12),
                      itemCount: grouped.length,
                      itemBuilder: (ctx, index) {
                        final entry = grouped.entries.elementAt(index);
                        final date = entry.key;
                        final items = entry.value;
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              date,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.green,
                              ),
                            ),
                            const SizedBox(height: 8),
                            ...items.map((r) => _buildRegistryCard(r)).toList(),
                            const SizedBox(height: 16),
                          ],
                        );
                      },
                    ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        child: const Icon(Icons.add),
        onPressed: () async {
          final newRegistry = await Navigator.push(
            context,
            MaterialPageRoute(
              builder:
                  (_) => AddRegistryScreen(
                    medications: _medications,
                    onAdd: (newReg) async {
                      await _registryDB.insertRegistry(newReg);
                    },
                    onAddMedication: (newMed) async {
                      await _medicationDB.insertMedication(newMed);
                      await _loadData();
                    },
                  ),
            ),
          );

          if (newRegistry != null) {
            await _loadData();
            setState(() {});
          }
        },
      ),
    );
  }
}
