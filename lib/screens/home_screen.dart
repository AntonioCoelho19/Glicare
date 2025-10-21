import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/registry.dart';
import '../models/medication.dart';
import 'meals_screen.dart';
import 'meal_detail_screen.dart';
import 'list_screen.dart';
import 'charts_screen.dart';
import 'add_registry_screen.dart';
import '../database/registry_db.dart';
import '../database/medication_db.dart';
import '../models/meal.dart';
import 'add_meal_screen.dart';
import '../database/meal_db.dart';
import 'settings_screen.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

class HomeScreen extends StatefulWidget {
  final bool isDarkMode;
  final Function(bool) onThemeChanged;

  const HomeScreen({
    required this.isDarkMode,
    required this.onThemeChanged,
    super.key,
  });
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;
  List<Registry> _registries = [];
  List<Medication> _medications = [];
  List<Meal> _meals = [];

  final _registryDB = RegistryDB();
  final _medicationDB = MedicationDB();
  final _mealDB = MealDB();

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _printDatabasePath() async {
    final databasesPath = await getDatabasesPath();
    final path = join(databasesPath, 'glicare.db');
    print('Caminho completo do banco: $path');
  }

  Future<void> _loadData() async {
    final meds = await _medicationDB.getAllMedications();
    final regs = await _registryDB.getRegistries();
    final meals = await _mealDB.getAllMeals();

    setState(() {
      _medications = meds;
      _registries = regs;
      _meals = meals;
    });
  }

  Future<void> _addRegistry(Registry registry) async {
    await _registryDB.insertRegistry(registry);
    await _loadData();
  }

  Future<void> _addMedication(Medication medication) async {
    await _medicationDB.insertMedication(medication);
    await _loadData();
  }

  Future<void> _addMeal(Meal meal) async {
    await _mealDB.insertMeal(meal);
    await _loadData();
  }

  Widget _buildRegistryCard(BuildContext context, Registry registry) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.symmetric(vertical: 6),
      child: ListTile(
        onTap: () async {
          await Navigator.of(context).push(
            MaterialPageRoute(
              builder:
                  (_) => AddRegistryScreen(
                    registry: registry,
                    onAdd: _addRegistry,
                    medications: _medications,
                    onAddMedication: _addMedication,
                  ),
            ),
          );
          await _loadData();
        },
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
              Text('Pressão: ${registry.systolic}/${registry.diastolic} mmHg'),
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
    );
  }

  Widget _buildMealCard(BuildContext context, Meal meal) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.symmetric(vertical: 6),
      child: ListTile(
        onTap: () async {
          final shouldReload = await Navigator.of(context).push<bool>(
            MaterialPageRoute(
              builder:
                  (_) => MealDetailScreen(
                    meal: meal,
                    onUpdate: (updatedMeal) async {
                      await _mealDB.insertMeal(updatedMeal);
                      await _loadData();
                    },
                  ),
            ),
          );
          if (shouldReload == true) {
            await _loadData();
          }
        },
        leading: const Icon(Icons.restaurant, color: Colors.green),
        title: Text(meal.type),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (var food in meal.items) Text('${food.name} - ${food.portion}'),
          ],
        ),
        trailing: Text(
          DateFormat('HH:mm').format(meal.date),
          style: const TextStyle(fontSize: 14, color: Colors.deepOrange),
        ),
      ),
    );
  }

  Widget _buildHomeSummary(BuildContext context) {
    final now = DateTime.now();
    final todayRegs =
        _registries
            .where(
              (r) =>
                  r.date.year == now.year &&
                  r.date.month == now.month &&
                  r.date.day == now.day,
            )
            .toList();

    final todayMeals =
        _meals
            .where(
              (m) =>
                  m.date.year == now.year &&
                  m.date.month == now.month &&
                  m.date.day == now.day,
            )
            .toList();

    final avgGly =
        todayRegs.isNotEmpty
            ? todayRegs.map((r) => r.glicemia).reduce((a, b) => a + b) /
                todayRegs.length
            : 0;

    return SingleChildScrollView(
      padding: const EdgeInsets.only(bottom: 80),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Card(
            margin: const EdgeInsets.all(16),
            elevation: 4,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            color: Colors.green.shade50,
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Resumo de Hoje',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.green,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      Column(
                        children: [
                          const Icon(
                            Icons.water_drop,
                            size: 32,
                            color: Colors.red,
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            'Glicemia média',
                            style: TextStyle(fontWeight: FontWeight.w600),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${avgGly.toStringAsFixed(1)} mg/dL',
                            style: const TextStyle(
                              fontSize: 16,
                              color: Colors.black87,
                            ),
                          ),
                        ],
                      ),
                      Column(
                        children: [
                          const Icon(
                            Icons.restaurant_menu,
                            size: 32,
                            color: Colors.orange,
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            'Refeições',
                            style: TextStyle(fontWeight: FontWeight.w600),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${todayMeals.length}',
                            style: const TextStyle(fontSize: 16),
                          ),
                        ],
                      ),
                      Column(
                        children: [
                          const Icon(
                            Icons.fact_check,
                            size: 32,
                            color: Colors.blue,
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            'Registros',
                            style: TextStyle(fontWeight: FontWeight.w600),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${todayRegs.length}',
                            style: const TextStyle(fontSize: 16),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          if (todayRegs.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                'Registros de Hoje',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
          ...todayRegs.map((r) => _buildRegistryCard(context, r)).toList(),
          if (todayMeals.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Text(
                'Refeições de Hoje',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
          ...todayMeals.map((m) => _buildMealCard(context, m)).toList(),
        ],
      ),
    );
  }

  List<Widget> _buildScreens(BuildContext context) => [
    Center(child: _buildHomeSummary(context)),
    ListScreen(),
    MealsScreen(meals: _meals),
    ChartsScreen(),
  ];

  void _onItemTapped(int index) => setState(() => _selectedIndex = index);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Glicare - Controle da Diabetes',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.green.shade800, Colors.green.shade400],
                ),
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(height: 12),
                  Text(
                    'Glicare Menu',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            ListTile(
              leading: const Icon(Icons.settings),
              title: const Text('Configurações'),
              onTap: () {
                Navigator.of(context).pop();
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder:
                        (context) => SettingsScreen(
                          isDarkMode: widget.isDarkMode,
                          onThemeChanged: widget.onThemeChanged,
                        ),
                  ),
                );
              },
            ),
            const ListTile(
              leading: Icon(Icons.info_outline),
              title: Text('Sobre Nós'),
            ),
            const ListTile(leading: Icon(Icons.logout), title: Text('Sair')),
          ],
        ),
      ),
      body: _buildScreens(context)[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        type: BottomNavigationBarType.fixed,
        selectedItemColor: Colors.green[700],
        unselectedItemColor: Colors.grey,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.list), label: 'Lista'),
          BottomNavigationBarItem(
            icon: Icon(Icons.restaurant),
            label: 'Refeições',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.bar_chart),
            label: 'Gráficos',
          ),
        ],
      ),
      floatingActionButton:
          (_selectedIndex == 1 || _selectedIndex == 2)
              ? FloatingActionButton(
                onPressed: () async {
                  if (_selectedIndex == 1) {
                    await Navigator.of(context).push(
                      MaterialPageRoute(
                        builder:
                            (_) => AddRegistryScreen(
                              onAdd: _addRegistry,
                              medications: _medications,
                              onAddMedication: _addMedication,
                            ),
                      ),
                    );
                    await _loadData();
                  } else if (_selectedIndex == 2) {
                    final result = await Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => AddMealScreen(onAdd: _addMeal),
                      ),
                    );
                    if (result == true) await _loadData();
                  }
                },
                child: const Icon(Icons.add, size: 28),
              )
              : null,
    );
  }
}
