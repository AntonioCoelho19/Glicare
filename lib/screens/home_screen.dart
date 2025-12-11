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
import '../database/settings_db.dart'; // Importar o novo DB
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

  // Metas de Glicemia
  double? _minGlicemiaGoal;
  double? _maxGlicemiaGoal;

  final _registryDB = RegistryDB();
  final _medicationDB = MedicationDB();
  final _mealDB = MealDB();
  final _settingsDB = SettingsDB(); // Instância do novo DB

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
    final goals = await _settingsDB.loadGlicemiaGoals(); // Carregar metas

    setState(() {
      _medications = meds;
      _registries = regs;
      _meals = meals;
      _minGlicemiaGoal = goals?['minGlicemia'];
      _maxGlicemiaGoal = goals?['maxGlicemia'];
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
      margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 16),
      child: ListTile(
        onTap: () async {
          final shouldReload = await Navigator.of(context).push<bool>(
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
          if (shouldReload == true) {
            await _loadData();
          }
        },
        leading: const Icon(Icons.bloodtype, color: Colors.red),
        title: Text('Glicemia: ${registry.glicemia} mg/dL'),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Insulina Longa: ${registry.insulinaLonga ?? 0} U'),
            Text('Insulina Curta: ${registry.insulinaCurta ?? 0} U'),
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
      margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 16),
      child: ListTile(
        onTap: () async {
          final shouldReload = await Navigator.of(context).push<bool>(
            MaterialPageRoute(
              builder:
                  (_) => MealDetailScreen(
                    meal: meal,
                    onUpdate: (updatedMeal) async {
                      await _mealDB.insertMeal(updatedMeal);
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

  Widget _buildGlicemiaAlert(double avgGly) {
    if (_minGlicemiaGoal == null || _maxGlicemiaGoal == null || avgGly == 0) {
      if (_minGlicemiaGoal == null || _maxGlicemiaGoal == null) {
        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          color: Colors.orange.shade100,
          elevation: 2,
          child: const ListTile(
            leading: Icon(Icons.warning_amber, color: Colors.orange),
            title: Text(
              'Metas de Glicemia não definidas',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            subtitle: Text(
              'Defina suas metas nas Configurações para monitorar seu controle.',
              style: TextStyle(color: Colors.black54),
            ),
          ),
        );
      }
      return const SizedBox.shrink();
    }

    String message;
    Color color;
    IconData icon;

    // Alerta de Hipoglicemia (abaixo do mínimo)
    if (avgGly < _minGlicemiaGoal!) {
      message =
          'Glicemia média baixa (${avgGly.toStringAsFixed(1)} mg/dL). Risco de hipoglicemia!';
      color = Colors.red.shade100;
      icon = Icons.arrow_downward;
    }
    // Alerta de Hiperglicemia (acima do máximo)
    else if (avgGly > _maxGlicemiaGoal!) {
      message =
          'Glicemia média alta (${avgGly.toStringAsFixed(1)} mg/dL). Risco de hiperglicemia.';
      color = Colors.yellow.shade100;
      icon = Icons.arrow_upward;
    }
    // Dentro da meta
    else {
      message =
          'Glicemia média (${avgGly.toStringAsFixed(1)} mg/dL) está dentro da sua meta!';
      color = Colors.green.shade100;
      icon = Icons.check_circle_outline;
    }

    final title =
        (avgGly >= _minGlicemiaGoal! && avgGly <= _maxGlicemiaGoal!)
            ? 'Controle Glicêmico'
            : 'Atenção!';

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: color,
      elevation: 2,
      child: ListTile(
        leading: Icon(icon, color: Colors.black87),
        title: Text(
          title,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        subtitle: Text(message, style: const TextStyle(color: Colors.black54)),
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

    final double avgGly =
        todayRegs.isNotEmpty
            ? todayRegs.map((r) => r.glicemia).reduce((a, b) => a + b) /
                todayRegs.length
            : 0;

    return SingleChildScrollView(
      padding: const EdgeInsets.only(bottom: 80),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildGlicemiaAlert(avgGly),

          Card(
            margin: const EdgeInsets.all(16),
            elevation: 4,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            color:
                Theme.of(context).brightness == Brightness.dark
                    ? Colors.teal.withOpacity(0.2)
                    : Colors.green.shade50,
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Resumo de Hoje',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color:
                          Theme.of(context).brightness == Brightness.dark
                              ? Colors.tealAccent
                              : Colors.green,
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
                          Text(
                            'Glicemia média',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              color:
                                  Theme.of(context).brightness ==
                                          Brightness.dark
                                      ? Colors.white70
                                      : Colors.black87,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${avgGly.toStringAsFixed(1)} mg/dL',
                            style: TextStyle(
                              fontSize: 16,
                              color:
                                  Theme.of(context).brightness ==
                                          Brightness.dark
                                      ? Colors.white
                                      : Colors.black87,
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
                          Text(
                            'Refeições',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              color:
                                  Theme.of(context).brightness ==
                                          Brightness.dark
                                      ? Colors.white70
                                      : Colors.black87,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${todayMeals.length}',
                            style: TextStyle(
                              fontSize: 16,
                              color:
                                  Theme.of(context).brightness ==
                                          Brightness.dark
                                      ? Colors.white
                                      : Colors.black87,
                            ),
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
                          Text(
                            'Registros',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              color:
                                  Theme.of(context).brightness ==
                                          Brightness.dark
                                      ? Colors.white70
                                      : Colors.black87,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${todayRegs.length}',
                            style: TextStyle(
                              fontSize: 16,
                              color:
                                  Theme.of(context).brightness ==
                                          Brightness.dark
                                      ? Colors.white
                                      : Colors.black87,
                            ),
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
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
              onTap: () async {
                Navigator.of(context).pop();
                await Navigator.push(
                  // Usa 'await' para esperar o retorno e recarregar
                  context,
                  MaterialPageRoute(
                    builder:
                        (context) => SettingsScreen(
                          isDarkMode: widget.isDarkMode,
                          onThemeChanged: widget.onThemeChanged,
                        ),
                  ),
                );
                _loadData(); // Recarrega os dados (incluindo as metas)
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
