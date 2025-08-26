import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../models/registry.dart';
import '../database/registry_db.dart';

class ChartsScreen extends StatefulWidget {
  @override
  State<ChartsScreen> createState() => _ChartsScreenState();
}

class _ChartsScreenState extends State<ChartsScreen> {
  final RegistryDB _registryDB = RegistryDB();
  List<Registry> _registries = [];

  String _selectedRange = 'Semana';

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final all = await _registryDB.getRegistries();
    setState(() {
      _registries = _filterByDateRange(all, _selectedRange);
    });
  }

  List<Registry> _filterByDateRange(List<Registry> all, String range) {
    final now = DateTime.now();

    if (range == 'Dia') {
      final start = DateTime(now.year, now.month, now.day);
      return all.where((r) => r.date.isAfter(start)).toList();
    } else if (range == 'Semana') {
      final start = now.subtract(Duration(days: 7));
      return all.where((r) => r.date.isAfter(start)).toList();
    } else if (range == 'Mês') {
      final start = now.subtract(Duration(days: 30));
      return all.where((r) => r.date.isAfter(start)).toList();
    }
    return all;
  }

  List<FlSpot> _getSpots() {
    final sorted = [..._registries];
    sorted.sort((a, b) => a.date.compareTo(b.date));

    return List.generate(sorted.length, (i) {
      return FlSpot(i.toDouble(), sorted[i].glicemia.toDouble());
    });
  }

  List<String> _getLabels() {
    final sorted = [..._registries];
    sorted.sort((a, b) => a.date.compareTo(b.date));

    return sorted.map((r) {
      if (_selectedRange == 'Dia') {
        return DateFormat.Hm().format(r.date);
      } else {
        return DateFormat('d/M').format(r.date);
      }
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final spots = _getSpots();
    final labels = _getLabels();

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Gráficos de Glicemia',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        backgroundColor: Colors.teal,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.teal),
              ),
              child: DropdownButton<String>(
                value: _selectedRange,
                icon: const Icon(Icons.arrow_drop_down),
                isExpanded: true,
                underline: SizedBox(),
                items:
                    ['Dia', 'Semana', 'Mês']
                        .map((r) => DropdownMenuItem(value: r, child: Text(r)))
                        .toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedRange = value!;
                    _loadData();
                  });
                },
              ),
            ),
          ),
          Expanded(
            child:
                spots.isEmpty
                    ? const Center(
                      child: Text(
                        'Sem dados para o período selecionado.',
                        style: TextStyle(fontSize: 16, color: Colors.grey),
                      ),
                    )
                    : Padding(
                      padding: const EdgeInsets.all(16),
                      child: LineChart(
                        LineChartData(
                          minY: 0,
                          titlesData: FlTitlesData(
                            bottomTitles: AxisTitles(
                              sideTitles: SideTitles(
                                showTitles: true,
                                reservedSize: 32,
                                interval: 1,
                                getTitlesWidget: (value, meta) {
                                  final index = value.toInt();
                                  if (index >= 0 && index < labels.length) {
                                    return SideTitleWidget(
                                      axisSide: meta.axisSide,
                                      space: 6,
                                      child: Text(
                                        labels[index],
                                        style: const TextStyle(
                                          fontSize: 10,
                                          color: Colors.black54,
                                        ),
                                      ),
                                    );
                                  }
                                  return const SizedBox.shrink();
                                },
                              ),
                            ),
                            leftTitles: AxisTitles(
                              sideTitles: SideTitles(
                                showTitles: true,
                                reservedSize: 40,
                                interval: 10,
                                getTitlesWidget: (value, meta) {
                                  return SideTitleWidget(
                                    axisSide: meta.axisSide,
                                    space: 6,
                                    child: Text(
                                      value.toInt().toString(),
                                      style: const TextStyle(
                                        fontSize: 10,
                                        color: Colors.black54,
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),
                            rightTitles: AxisTitles(
                              sideTitles: SideTitles(showTitles: false),
                            ),
                            topTitles: AxisTitles(
                              sideTitles: SideTitles(showTitles: false),
                            ),
                          ),
                          gridData: FlGridData(
                            show: true,
                            drawVerticalLine: false,
                            getDrawingHorizontalLine:
                                (value) => FlLine(
                                  color: Colors.grey.shade300,
                                  strokeWidth: 1,
                                ),
                          ),
                          borderData: FlBorderData(
                            show: true,
                            border: const Border(
                              left: BorderSide(color: Colors.black54),
                              bottom: BorderSide(color: Colors.black54),
                            ),
                          ),
                          lineBarsData: [
                            LineChartBarData(
                              isCurved: true,
                              spots: spots,
                              color: Colors.teal,
                              barWidth: 2.5,
                              isStrokeCapRound: true,
                              dotData: FlDotData(
                                show: true,
                                getDotPainter:
                                    (spot, percent, barData, index) =>
                                        FlDotCirclePainter(
                                          radius: 4,
                                          color: Colors.teal,
                                          strokeColor: Colors.white,
                                          strokeWidth: 1.5,
                                        ),
                              ),
                              belowBarData: BarAreaData(
                                show: true,
                                color: Colors.teal.withOpacity(0.1),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
          ),
        ],
      ),
    );
  }
}
