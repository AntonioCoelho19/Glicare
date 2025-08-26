import 'package:flutter/material.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  double? _minGlicose;
  double? _maxGlicose;

  final _formKey = GlobalKey<FormState>();
  final _minController = TextEditingController();
  final _maxController = TextEditingController();

  void _openGlicoseGoalsDialog() {
    if (_minGlicose != null) _minController.text = _minGlicose!.toString();
    if (_maxGlicose != null) _maxController.text = _maxGlicose!.toString();

    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Definir Metas de Glicose'),
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
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _maxController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Glicose máxima (mg/dL)',
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
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Cancelar'),
              ),
              ElevatedButton(
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

  @override
  void dispose() {
    _minController.dispose();
    _maxController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Configurações'), centerTitle: true),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          Card(
            elevation: 2,
            child: ListTile(
              leading: const Icon(Icons.health_and_safety, color: Colors.teal),
              title: const Text('Definir Metas de Glicose'),
              subtitle:
                  _minGlicose != null && _maxGlicose != null
                      ? Text('Meta atual: $_minGlicose - $_maxGlicose mg/dL')
                      : const Text('Nenhuma meta definida'),
              trailing: const Icon(Icons.edit, size: 18),
              onTap: _openGlicoseGoalsDialog,
            ),
          ),
          const SizedBox(height: 12),
          Card(
            elevation: 1,
            child: ListTile(
              leading: const Icon(Icons.info_outline, color: Colors.grey),
              title: const Text('Sobre o app'),
              subtitle: const Text('Versão 0.5'),
              onTap: () {
                showAboutDialog(
                  context: context,
                  applicationName: 'Glicare',
                  applicationVersion: '0.5',
                  applicationLegalese: '© 2025',
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
