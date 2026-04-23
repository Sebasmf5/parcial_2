import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:parcial_2/services/accidente_service.dart';
import 'package:parcial_2/services/establecimiento_service.dart';
import 'package:parcial_2/widgets/dashboard_card.dart';
import 'package:parcial_2/widgets/skeleton_list.dart';

/// Pantalla principal (Dashboard) de la aplicación.
///
/// Muestra un resumen con el total de accidentes y establecimientos,
/// junto con dos cards de navegación a los módulos principales.
/// Usa [Skeletonizer] mientras carga los datos iniciales.
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final AccidenteService _accidenteService = AccidenteService();
  final EstablecimientoService _establecimientoService = EstablecimientoService();

  bool _isLoading = true;
  int _totalAccidentes = 0;
  int _totalEstablecimientos = 0;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadResumen();
  }

  /// Carga el resumen inicial: total de accidentes y establecimientos.
  Future<void> _loadResumen() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      // Ejecutar ambas peticiones en paralelo
      final results = await Future.wait([
        _accidenteService.fetchAccidentes(),
        _establecimientoService.getAll(),
      ]);

      if (!mounted) return;

      setState(() {
        _totalAccidentes = (results[0] as List).length;
        _totalEstablecimientos = (results[1] as List).length;
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
          'Parcial 2 — Dashboard',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: const Color(0xFF1A1A2E),
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
      ),
      body: _isLoading
          ? const SkeletonDashboard()
          : _error != null
              ? _buildErrorState()
              : _buildContent(),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline_rounded,
              size: 64,
              color: Colors.red[300],
            ),
            const SizedBox(height: 16),
            Text(
              'Error al cargar datos',
              style: TextStyle(
                color: Colors.red[300],
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _error!,
              style: TextStyle(
                color: Colors.grey[400],
                fontSize: 14,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _loadResumen,
              icon: const Icon(Icons.refresh),
              label: const Text('Reintentar'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF6C63FF),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
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

  Widget _buildContent() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Título de bienvenida
          const Text(
            '¡Bienvenido!',
            style: TextStyle(
              color: Colors.white,
              fontSize: 28,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Panel de control del parcial',
            style: TextStyle(
              color: Colors.grey[400],
              fontSize: 15,
            ),
          ),
          const SizedBox(height: 24),

          // Resumen con totales
          _buildResumenCard(),
          const SizedBox(height: 24),

          // Sección de módulos
          Text(
            'Módulos',
            style: TextStyle(
              color: Colors.grey[300],
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),

          // Card — Estadísticas de Accidentes
          DashboardCard(
            icon: Icons.bar_chart_rounded,
            title: 'Estadísticas de Accidentes',
            subtitle: '$_totalAccidentes accidentes registrados en Tuluá',
            gradientColors: const [Color(0xFF667EEA), Color(0xFF764BA2)],
            onTap: () => context.pushNamed('estadisticas'),
          ),
          const SizedBox(height: 16),

          // Card — Gestión de Establecimientos
          DashboardCard(
            icon: Icons.store_rounded,
            title: 'Gestión de Establecimientos',
            subtitle: '$_totalEstablecimientos establecimientos registrados',
            gradientColors: const [Color(0xFFF093FB), Color(0xFFF5576C)],
            onTap: () => context.pushNamed('establecimientos'),
          ),
        ],
      ),
    );
  }

  Widget _buildResumenCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A2E),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.08),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: _buildResumenItem(
              icon: Icons.car_crash_rounded,
              label: 'Accidentes',
              value: _totalAccidentes.toString(),
              color: const Color(0xFF667EEA),
            ),
          ),
          Container(
            width: 1,
            height: 50,
            color: Colors.white.withValues(alpha: 0.1),
          ),
          Expanded(
            child: _buildResumenItem(
              icon: Icons.store_rounded,
              label: 'Establecimientos',
              value: _totalEstablecimientos.toString(),
              color: const Color(0xFFF5576C),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResumenItem({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Column(
      children: [
        Icon(icon, color: color, size: 28),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: TextStyle(
            color: Colors.grey[500],
            fontSize: 13,
          ),
        ),
      ],
    );
  }
}
