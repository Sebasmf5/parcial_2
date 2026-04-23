import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

import 'package:parcial_2/services/accidente_service.dart';
import 'package:parcial_2/isolates/accidente_isolate.dart';
import 'package:parcial_2/widgets/skeleton_list.dart';

/// Pantalla de Estadísticas de Accidentes de Tránsito.
///
/// Consume la API de Datos Abiertos, procesa los registros con un Isolate
/// y renderiza 4 gráficas:
///   1. PieChart — Distribución por clase de accidente
///   2. PieChart — Distribución por gravedad
///   3. BarChart — Top 5 barrios con más accidentes
///   4. BarChart — Distribución por día de la semana
class EstadisticasScreen extends StatefulWidget {
  const EstadisticasScreen({super.key});

  @override
  State<EstadisticasScreen> createState() => _EstadisticasScreenState();
}

class _EstadisticasScreenState extends State<EstadisticasScreen> {
  final AccidenteService _service = AccidenteService();

  bool _isLoading = true;
  String? _error;
  Map<String, dynamic>? _estadisticas;

  // Paleta de colores vibrante para las gráficas
  static const List<Color> _chartColors = [
    Color(0xFF667EEA),
    Color(0xFFF5576C),
    Color(0xFF43E97B),
    Color(0xFFFA709A),
    Color(0xFFFEE140),
    Color(0xFF4FACFE),
    Color(0xFFF093FB),
  ];

  @override
  void initState() {
    super.initState();
    _loadEstadisticas();
  }

  /// Carga los datos de accidentes y los procesa en un Isolate.
  Future<void> _loadEstadisticas() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      // 1. Obtener datos crudos de la API
      final rawData = await _service.fetchAccidentes();

      // 2. Procesar en Isolate (fuera del hilo principal)
      final result = await AccidenteIsolate.processAccidentes(rawData);

      if (!mounted) return;

      setState(() {
        _estadisticas = result;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F0F23),
      appBar: AppBar(
        title: const Text(
          'Estadísticas de Accidentes',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: const Color(0xFF1A1A2E),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: _isLoading
          ? const SkeletonEstadisticas()
          : _error != null
              ? _buildErrorState()
              : _buildCharts(),
    );
  }

  // ---------------------------------------------------------------------------
  // Estado de Error
  // ---------------------------------------------------------------------------
  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline_rounded, size: 64, color: Colors.red[300]),
            const SizedBox(height: 16),
            Text(
              'Error al cargar estadísticas',
              style: TextStyle(
                color: Colors.red[300],
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _error!,
              style: TextStyle(color: Colors.grey[400], fontSize: 14),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _loadEstadisticas,
              icon: const Icon(Icons.refresh),
              label: const Text('Reintentar'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF6C63FF),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Contenido Principal — 4 gráficas
  // ---------------------------------------------------------------------------
  Widget _buildCharts() {
    final stats = _estadisticas!;
    final totalRegistros = stats['totalRegistros'] as int;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Encabezado con total
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: const Color(0xFF1A1A2E),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
          ),
          child: Row(
            children: [
              const Icon(Icons.analytics_rounded, color: Color(0xFF667EEA)),
              const SizedBox(width: 12),
              Text(
                'Total de registros procesados: $totalRegistros',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Gráfica 1: Distribución por clase de accidente (PieChart)
        _buildChartCard(
          title: 'Distribución por Clase de Accidente',
          subtitle: 'Choque / Atropello / Volcamiento / Otros',
          child: _buildPieChart(
            Map<String, int>.from(stats['distribucionClase']),
          ),
        ),
        const SizedBox(height: 16),

        // Gráfica 2: Distribución por gravedad (PieChart)
        _buildChartCard(
          title: 'Distribución por Gravedad',
          subtitle: 'Con muertos / Con heridos / Solo daños',
          child: _buildPieChart(
            Map<String, int>.from(stats['distribucionGravedad']),
          ),
        ),
        const SizedBox(height: 16),

        // Gráfica 3: Top 5 barrios (BarChart)
        _buildChartCard(
          title: 'Top 5 Barrios con Más Accidentes',
          subtitle: 'Barrios con mayor cantidad de siniestros',
          child: _buildBarChartTop5(
            List<Map<String, dynamic>>.from(stats['top5Barrios']),
          ),
        ),
        const SizedBox(height: 16),

        // Gráfica 4: Distribución por día de la semana (BarChart)
        _buildChartCard(
          title: 'Distribución por Día de la Semana',
          subtitle: 'Lunes a Domingo',
          child: _buildBarChartDias(
            Map<String, int>.from(stats['distribucionDia']),
          ),
        ),
        const SizedBox(height: 24),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // Card contenedora de gráfica
  // ---------------------------------------------------------------------------
  Widget _buildChartCard({
    required String title,
    required String subtitle,
    required Widget child,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A2E),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 17,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: TextStyle(color: Colors.grey[500], fontSize: 13),
          ),
          const SizedBox(height: 20),
          child,
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // PieChart genérico
  // ---------------------------------------------------------------------------
  Widget _buildPieChart(Map<String, int> data) {
    final total = data.values.fold<int>(0, (sum, v) => sum + v);
    final entries = data.entries.toList();

    return Column(
      children: [
        SizedBox(
          height: 220,
          child: PieChart(
            PieChartData(
              sectionsSpace: 3,
              centerSpaceRadius: 40,
              sections: List.generate(entries.length, (i) {
                final entry = entries[i];
                final percentage = (entry.value / total * 100).toStringAsFixed(1);
                return PieChartSectionData(
                  color: _chartColors[i % _chartColors.length],
                  value: entry.value.toDouble(),
                  title: '$percentage%',
                  titleStyle: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                  radius: 55,
                );
              }),
            ),
          ),
        ),
        const SizedBox(height: 16),
        // Leyenda
        Wrap(
          spacing: 16,
          runSpacing: 8,
          alignment: WrapAlignment.center,
          children: List.generate(entries.length, (i) {
            return Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: _chartColors[i % _chartColors.length],
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  '${entries[i].key} (${entries[i].value})',
                  style: TextStyle(color: Colors.grey[400], fontSize: 12),
                ),
              ],
            );
          }),
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // BarChart — Top 5 barrios
  // ---------------------------------------------------------------------------
  Widget _buildBarChartTop5(List<Map<String, dynamic>> barrios) {
    if (barrios.isEmpty) {
      return const Center(
        child: Text('Sin datos', style: TextStyle(color: Colors.grey)),
      );
    }

    final maxY = (barrios.first['cantidad'] as int).toDouble() * 1.2;

    return SizedBox(
      height: 250,
      child: BarChart(
        BarChartData(
          maxY: maxY,
          alignment: BarChartAlignment.spaceAround,
          barTouchData: BarTouchData(
            enabled: true,
            touchTooltipData: BarTouchTooltipData(
              getTooltipItem: (group, groupIndex, rod, rodIndex) {
                final barrio = barrios[groupIndex]['barrio'] as String;
                return BarTooltipItem(
                  '$barrio\n${rod.toY.toInt()}',
                  const TextStyle(color: Colors.white, fontSize: 12),
                );
              },
            ),
          ),
          titlesData: FlTitlesData(
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 40,
                getTitlesWidget: (value, meta) {
                  return Text(
                    value.toInt().toString(),
                    style: TextStyle(color: Colors.grey[500], fontSize: 11),
                  );
                },
              ),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 50,
                getTitlesWidget: (value, meta) {
                  final index = value.toInt();
                  if (index < 0 || index >= barrios.length) {
                    return const SizedBox.shrink();
                  }
                  final name = (barrios[index]['barrio'] as String);
                  // Truncar nombres largos
                  final displayName =
                      name.length > 8 ? '${name.substring(0, 8)}...' : name;
                  return Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Transform.rotate(
                      angle: -0.5,
                      child: Text(
                        displayName,
                        style: TextStyle(color: Colors.grey[400], fontSize: 10),
                      ),
                    ),
                  );
                },
              ),
            ),
            topTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            rightTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
          ),
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            horizontalInterval: maxY / 5,
            getDrawingHorizontalLine: (value) {
              return FlLine(
                color: Colors.white.withValues(alpha: 0.05),
                strokeWidth: 1,
              );
            },
          ),
          borderData: FlBorderData(show: false),
          barGroups: List.generate(barrios.length, (i) {
            return BarChartGroupData(
              x: i,
              barRods: [
                BarChartRodData(
                  toY: (barrios[i]['cantidad'] as int).toDouble(),
                  width: 24,
                  color: _chartColors[i % _chartColors.length],
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(6),
                    topRight: Radius.circular(6),
                  ),
                ),
              ],
            );
          }),
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // BarChart — Distribución por día de la semana
  // ---------------------------------------------------------------------------
  Widget _buildBarChartDias(Map<String, int> diasData) {
    final dias = [
      'lunes',
      'martes',
      'miércoles',
      'jueves',
      'viernes',
      'sábado',
      'domingo',
    ];
    final diasCortos = ['Lun', 'Mar', 'Mié', 'Jue', 'Vie', 'Sáb', 'Dom'];
    final values = dias.map((d) => (diasData[d] ?? 0).toDouble()).toList();
    final maxY = values.reduce((a, b) => a > b ? a : b) * 1.2;

    return SizedBox(
      height: 250,
      child: BarChart(
        BarChartData(
          maxY: maxY,
          alignment: BarChartAlignment.spaceAround,
          barTouchData: BarTouchData(
            enabled: true,
            touchTooltipData: BarTouchTooltipData(
              getTooltipItem: (group, groupIndex, rod, rodIndex) {
                return BarTooltipItem(
                  '${dias[groupIndex]}\n${rod.toY.toInt()}',
                  const TextStyle(color: Colors.white, fontSize: 12),
                );
              },
            ),
          ),
          titlesData: FlTitlesData(
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 40,
                getTitlesWidget: (value, meta) {
                  return Text(
                    value.toInt().toString(),
                    style: TextStyle(color: Colors.grey[500], fontSize: 11),
                  );
                },
              ),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 30,
                getTitlesWidget: (value, meta) {
                  final index = value.toInt();
                  if (index < 0 || index >= diasCortos.length) {
                    return const SizedBox.shrink();
                  }
                  return Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      diasCortos[index],
                      style: TextStyle(color: Colors.grey[400], fontSize: 11),
                    ),
                  );
                },
              ),
            ),
            topTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            rightTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
          ),
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            horizontalInterval: maxY / 5,
            getDrawingHorizontalLine: (value) {
              return FlLine(
                color: Colors.white.withValues(alpha: 0.05),
                strokeWidth: 1,
              );
            },
          ),
          borderData: FlBorderData(show: false),
          barGroups: List.generate(7, (i) {
            return BarChartGroupData(
              x: i,
              barRods: [
                BarChartRodData(
                  toY: values[i],
                  width: 20,
                  gradient: LinearGradient(
                    colors: [
                      _chartColors[i % _chartColors.length],
                      _chartColors[i % _chartColors.length].withValues(alpha: 0.6),
                    ],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(6),
                    topRight: Radius.circular(6),
                  ),
                ),
              ],
            );
          }),
        ),
      ),
    );
  }
}
