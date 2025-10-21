import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsScreen extends StatefulWidget {
  final bool isDarkMode;
  final Function(bool) onThemeChanged;
  const SettingsScreen({
    required this.isDarkMode,
    required this.onThemeChanged,
    super.key,
  });

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  // Campos do perfil
  String? _nome;
  int? _idade;
  double? _peso;
  String? _tipoDiabetes;

  // Metas de glicose
  double? _minGlicose;
  double? _maxGlicose;

  // Modo escuro
  bool _isDarkMode = false;

  final _formKey = GlobalKey<FormState>();
  final _minController = TextEditingController();
  final _maxController = TextEditingController();

  final _nomeController = TextEditingController();
  final _idadeController = TextEditingController();
  final _pesoController = TextEditingController();
  String? _tipoSelecionado;

  @override
  void initState() {
    super.initState();
    _loadDarkModePreference();
  }

  Future<void> _loadDarkModePreference() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _isDarkMode = prefs.getBool('darkMode') ?? false;
    });
  }

  Future<void> _saveDarkModePreference(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('darkMode', value);
  }

  void _toggleDarkMode(bool value) {
    setState(() => _isDarkMode = value);
    _saveDarkModePreference(value);
    widget.onThemeChanged(value);
  }

  void _openGlicoseGoalsDialog() {
    if (_minGlicose != null) _minController.text = _minGlicose!.toString();
    if (_maxGlicose != null) _maxController.text = _maxGlicose!.toString();

    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            backgroundColor: _isDarkMode ? Colors.grey[900] : Colors.white,
            title: const Text(
              'Definir Metas de Glicose',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            content: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: _minController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Glicose mínima (mg/dL)',
                      prefixIcon: Icon(
                        Icons.arrow_downward,
                        color: Colors.teal,
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Informe a glicose mínima';
                      }
                      final v = double.tryParse(value);
                      if (v == null || v < 0) {
                        return 'Informe um valor válido';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _maxController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Glicose máxima (mg/dL)',
                      prefixIcon: Icon(Icons.arrow_upward, color: Colors.teal),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Informe a glicose máxima';
                      }
                      final v = double.tryParse(value);
                      if (v == null || v <= 0) {
                        return 'Informe um valor válido';
                      }
                      return null;
                    },
                  ),
                ],
              ),
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            actionsPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 8,
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Cancelar'),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.teal,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: () {
                  if (_formKey.currentState!.validate()) {
                    setState(() {
                      _minGlicose = double.parse(_minController.text);
                      _maxGlicose = double.parse(_maxController.text);
                    });
                    Navigator.of(context).pop();
                  }
                },
                child: const Text('Salvar'),
              ),
            ],
          ),
    );
  }

  void _openUserProfileDialog() {
    _nomeController.text = _nome ?? '';
    _idadeController.text = _idade?.toString() ?? '';
    _pesoController.text = _peso?.toString() ?? '';
    _tipoSelecionado = _tipoDiabetes;

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: _isDarkMode ? Colors.grey[900] : Colors.white,
          title: const Text(
            'Perfil do Usuário',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: _nomeController,
                  decoration: const InputDecoration(
                    labelText: 'Nome',
                    prefixIcon: Icon(Icons.person_outline, color: Colors.teal),
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: _idadeController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Idade',
                    prefixIcon: Icon(Icons.calendar_today, color: Colors.teal),
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: _pesoController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Peso (kg)',
                    prefixIcon: Icon(Icons.monitor_weight, color: Colors.teal),
                  ),
                ),
                const SizedBox(height: 10),
                DropdownButtonFormField<String>(
                  value: _tipoSelecionado,
                  decoration: const InputDecoration(
                    labelText: 'Tipo de diabetes',
                    prefixIcon: Icon(Icons.bloodtype, color: Colors.teal),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'Tipo 1', child: Text('Tipo 1')),
                    DropdownMenuItem(value: 'Tipo 2', child: Text('Tipo 2')),
                    DropdownMenuItem(
                      value: 'Gestacional',
                      child: Text('Gestacional'),
                    ),
                    DropdownMenuItem(value: 'Outro', child: Text('Outro')),
                  ],
                  onChanged: (value) {
                    setState(() {
                      _tipoSelecionado = value;
                    });
                  },
                ),
              ],
            ),
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          actionsPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 8,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.teal,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onPressed: () {
                setState(() {
                  _nome = _nomeController.text;
                  _idade = int.tryParse(_idadeController.text);
                  _peso = double.tryParse(_pesoController.text);
                  _tipoDiabetes = _tipoSelecionado;
                });
                Navigator.pop(context);
              },
              child: const Text('Salvar'),
            ),
          ],
        );
      },
    );
  }

  @override
  void dispose() {
    _minController.dispose();
    _maxController.dispose();
    _nomeController.dispose();
    _idadeController.dispose();
    _pesoController.dispose();
    super.dispose();
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 4),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: _isDarkMode ? Colors.teal[200] : Colors.teal,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bgColor = _isDarkMode ? Colors.grey[900] : Colors.grey[100];
    final cardColor = _isDarkMode ? Colors.grey[850] : Colors.white;
    final textColor = _isDarkMode ? Colors.white : Colors.black87;

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        title: const Text('Configurações'),
        centerTitle: true,
        backgroundColor: Colors.teal,
        elevation: 1,
      ),
      body: Theme(
        data:
            _isDarkMode
                ? ThemeData.dark().copyWith(cardColor: cardColor)
                : ThemeData.light(),
        child: ListView(
          padding: const EdgeInsets.all(16.0),
          children: [
            _buildSectionTitle('Perfil'),
            Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              elevation: 3,
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: Colors.teal.withOpacity(0.1),
                  child: const Icon(Icons.person, color: Colors.teal),
                ),
                title: Text(
                  'Perfil do Usuário',
                  style: TextStyle(color: textColor),
                ),
                subtitle:
                    _nome != null
                        ? Text(
                          '$_nome, ${_idade ?? '-'} anos\n${_peso ?? '-'} kg | ${_tipoDiabetes ?? 'Não informado'}',
                          style: TextStyle(
                            height: 1.4,
                            color: textColor.withOpacity(0.8),
                          ),
                        )
                        : Text(
                          'Toque para adicionar informações do perfil',
                          style: TextStyle(color: textColor.withOpacity(0.8)),
                        ),
                trailing: const Icon(Icons.edit, size: 18, color: Colors.teal),
                onTap: _openUserProfileDialog,
              ),
            ),
            const SizedBox(height: 20),

            _buildSectionTitle('Metas de Glicose'),
            Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              elevation: 3,
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: Colors.teal.withOpacity(0.1),
                  child: const Icon(
                    Icons.health_and_safety,
                    color: Colors.teal,
                  ),
                ),
                title: Text(
                  'Definir Metas de Glicose',
                  style: TextStyle(color: textColor),
                ),
                subtitle:
                    _minGlicose != null && _maxGlicose != null
                        ? Text(
                          'Meta atual: $_minGlicose - $_maxGlicose mg/dL',
                          style: TextStyle(color: textColor.withOpacity(0.8)),
                        )
                        : Text(
                          'Nenhuma meta definida',
                          style: TextStyle(color: textColor.withOpacity(0.8)),
                        ),
                trailing: const Icon(Icons.edit, size: 18, color: Colors.teal),
                onTap: _openGlicoseGoalsDialog,
              ),
            ),
            const SizedBox(height: 20),

            _buildSectionTitle('Aparência'),
            Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              elevation: 2,
              child: SwitchListTile(
                title: Text('Modo escuro', style: TextStyle(color: textColor)),
                subtitle: Text(
                  _isDarkMode ? 'Ativado' : 'Desativado',
                  style: TextStyle(color: textColor.withOpacity(0.8)),
                ),
                secondary: const Icon(Icons.dark_mode, color: Colors.teal),
                activeColor: Colors.teal,
                value: _isDarkMode,
                onChanged: _toggleDarkMode,
              ),
            ),
            const SizedBox(height: 20),

            _buildSectionTitle('Informações'),
            Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              elevation: 2,
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: Colors.grey.withOpacity(0.1),
                  child: const Icon(Icons.info_outline, color: Colors.grey),
                ),
                title: Text('Sobre o app', style: TextStyle(color: textColor)),
                subtitle: Text(
                  'Versão 0.5',
                  style: TextStyle(color: textColor.withOpacity(0.8)),
                ),
                onTap: () {
                  showAboutDialog(
                    context: context,
                    applicationName: 'Glicare',
                    applicationVersion: '0.5',
                    applicationLegalese: '© 2025 Glicare',
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
