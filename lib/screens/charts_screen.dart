import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'dart:math';
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
      final start = now.subtract(const Duration(days: 7));
      return all.where((r) => r.date.isAfter(start)).toList();
    } else if (range == 'Mês') {
      final start = now.subtract(const Duration(days: 30));
      return all.where((r) => r.date.isAfter(start)).toList();
    }
    return all;
  }

  double _getMaxY() {
    if (_registries.isEmpty) return 100;
    double maxGlicemia =
        _registries.map((r) => r.glicemia).reduce(max).toDouble();
    return (maxGlicemia / 10).ceil() * 10 + 50;
  }

  double _getMinY() {
    if (_registries.isEmpty) return 0;
    double minGlicemia =
        _registries.map((r) => r.glicemia).reduce(min).toDouble();
    return max(0, minGlicemia - 10);
  }

  double _getIntervalY(double maxY) {
    if (maxY < 150) return 10;
    if (maxY < 300) return 30;
    return 50;
  }

  List<FlSpot> _getSpots() {
    final sorted = [..._registries];
    sorted.sort((a, b) => a.date.compareTo(b.date));
    return List.generate(
      sorted.length,
      (i) => FlSpot(i.toDouble(), sorted[i].glicemia.toDouble()),
    );
  }

  List<String> _getLabels() {
    final sorted = [..._registries];
    sorted.sort((a, b) => a.date.compareTo(b.date));
    return sorted.map((r) {
      if (_selectedRange == 'Dia') {
        return DateFormat.Hm().format(r.date);
      }
      return DateFormat('d/M').format(r.date);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final spots = _getSpots();
    final labels = _getLabels();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final Color tooltipBgColor =
        isDark ? Colors.grey.shade200 : Colors.grey.shade800;
    final Color tooltipTextColor = isDark ? Colors.black : Colors.white;

    final double maxY = _getMaxY();
    final double minY = _getMinY();
    final double intervalY = _getIntervalY(maxY);

    final axisTextColor = isDark ? Colors.white70 : Colors.black54;
    final gridColor = isDark ? Colors.white24 : Colors.grey.shade300;
    final borderColor = isDark ? Colors.white54 : Colors.black54;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Gráficos de Glicemia'),
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
                icon: Icon(
                  Icons.arrow_drop_down,
                  color: isDark ? Colors.white : Colors.black,
                ),
                dropdownColor: isDark ? Colors.grey[900] : Colors.white,
                isExpanded: true,
                underline: const SizedBox(),
                style: TextStyle(
                  color: isDark ? Colors.white : Colors.black,
                  fontSize: 16,
                ),
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
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Padding(
                            padding: const EdgeInsets.only(
                              bottom: 15,
                              left: 10,
                            ),
                            child: Text(
                              'mg/dl',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: axisTextColor,
                              ),
                            ),
                          ),
                          Expanded(
                            child: LineChart(
                              LineChartData(
                                minY: minY,
                                maxY: maxY,
                                lineTouchData: LineTouchData(
                                  enabled: true,
                                  touchTooltipData: LineTouchTooltipData(
                                    tooltipBgColor: tooltipBgColor,
                                    tooltipRoundedRadius: 8.0,
                                    tooltipPadding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 4,
                                    ),
                                    getTooltipItems: (
                                      List<LineBarSpot> touchedBarSpots,
                                    ) {
                                      return touchedBarSpots.map((barSpot) {
                                        final value = barSpot.y;

                                        return LineTooltipItem(
                                          '${value.toStringAsFixed(1)} mg/dL',
                                          TextStyle(
                                            color: tooltipTextColor,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 12,
                                          ),
                                        );
                                      }).toList();
                                    },
                                  ),
                                ),
                                titlesData: FlTitlesData(
                                  bottomTitles: AxisTitles(
                                    sideTitles: SideTitles(
                                      showTitles: true,
                                      reservedSize: 32,
                                      interval: 1,
                                      getTitlesWidget: (value, meta) {
                                        final index = value.toInt();
                                        if (index >= 0 &&
                                            index < labels.length) {
                                          return SideTitleWidget(
                                            axisSide: meta.axisSide,
                                            space: 6,
                                            child: Text(
                                              labels[index],
                                              style: TextStyle(
                                                fontSize: 10,
                                                color: axisTextColor,
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
                                      interval: intervalY,
                                      getTitlesWidget: (value, meta) {
                                        return SideTitleWidget(
                                          axisSide: meta.axisSide,
                                          space: 6,
                                          child: Text(
                                            value.toInt().toString(),
                                            style: TextStyle(
                                              fontSize: 10,
                                              color: axisTextColor,
                                            ),
                                          ),
                                        );
                                      },
                                    ),
                                  ),
                                  rightTitles: const AxisTitles(
                                    sideTitles: SideTitles(showTitles: false),
                                  ),
                                  topTitles: const AxisTitles(
                                    sideTitles: SideTitles(showTitles: false),
                                  ),
                                ),
                                gridData: FlGridData(
                                  show: true,
                                  drawVerticalLine: false,
                                  horizontalInterval: intervalY,
                                  getDrawingHorizontalLine:
                                      (value) => FlLine(
                                        color: gridColor,
                                        strokeWidth: 1,
                                      ),
                                ),
                                borderData: FlBorderData(
                                  show: true,
                                  border: Border(
                                    left: BorderSide(color: borderColor),
                                    bottom: BorderSide(color: borderColor),
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
                                                strokeColor:
                                                    isDark
                                                        ? Colors.black
                                                        : Colors.white,
                                                strokeWidth: 1.5,
                                              ),
                                    ),
                                    belowBarData: BarAreaData(
                                      show: true,
                                      color: Colors.tealAccent.withOpacity(0.1),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
          ),
        ],
      ),
    );
  }
}
