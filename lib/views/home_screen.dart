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

  Future<void> _loadResumen() async {
    setState(() { _isLoading = true; _error = null; });

    try {
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
      setState(() { _error = e.toString(); _isLoading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0B1121),
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
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFFFF6B6B).withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.wifi_off_rounded,
                size: 48,
                color: Color(0xFFFF6B6B),
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Sin conexión',
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'No se pudieron cargar los datos.\nVerifica tu conexión a internet.',
              style: TextStyle(color: Colors.grey[500], fontSize: 14, height: 1.5),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 28),
            FilledButton.icon(
              onPressed: _loadResumen,
              icon: const Icon(Icons.refresh_rounded, size: 20),
              label: const Text('Reintentar'),
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFF7C5CFC),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent() {
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 8),
            // Header
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF7C5CFC), Color(0xFF38BDF8)],
                    ),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(Icons.dashboard_rounded, color: Colors.white, size: 24),
                ),
                const SizedBox(width: 14),
                const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Parcial 2',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.5,
                      ),
                    ),
                    Text(
                      'Desarrollo Móvil',
                      style: TextStyle(
                        color: Color(0xFF64748B),
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 28),

            // Resumen stats
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 8),
              decoration: BoxDecoration(
                color: const Color(0xFF131B2E),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xFF1E293B)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: _buildStatItem(
                      icon: Icons.car_crash_rounded,
                      value: _totalAccidentes.toString(),
                      label: 'Accidentes',
                      color: const Color(0xFF38BDF8),
                    ),
                  ),
                  Container(
                    width: 1,
                    height: 48,
                    color: const Color(0xFF1E293B),
                  ),
                  Expanded(
                    child: _buildStatItem(
                      icon: Icons.storefront_rounded,
                      value: _totalEstablecimientos.toString(),
                      label: 'Establecimientos',
                      color: const Color(0xFF34D399),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 28),

            // Sección módulos
            const Text(
              'MÓDULOS',
              style: TextStyle(
                color: Color(0xFF64748B),
                fontSize: 12,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.5,
              ),
            ),
            const SizedBox(height: 14),

            // Card Accidentes
            DashboardCard(
              icon: Icons.bar_chart_rounded,
              title: 'Estadísticas de Accidentes',
              subtitle: '$_totalAccidentes registros de Tuluá procesados con Isolate',
              gradientColors: const [Color(0xFF6366F1), Color(0xFF8B5CF6)],
              onTap: () => context.pushNamed('estadisticas'),
            ),
            const SizedBox(height: 14),

            // Card Establecimientos
            DashboardCard(
              icon: Icons.storefront_rounded,
              title: 'Gestión de Establecimientos',
              subtitle: '$_totalEstablecimientos registros — CRUD con carga de logo',
              gradientColors: const [Color(0xFF0EA5E9), Color(0xFF38BDF8)],
              onTap: () => context.pushNamed('establecimientos'),
            ),
            const SizedBox(height: 28),

            // Footer info
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF131B2E),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFF1E293B)),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline_rounded, color: Colors.grey[600], size: 18),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Datos de accidentes: Datos Abiertos Colombia\nEstablecimientos: API Parking VisionTIC',
                      style: TextStyle(color: Colors.grey[600], fontSize: 12, height: 1.5),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem({
    required IconData icon,
    required String value,
    required String label,
    required Color color,
  }) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: color, size: 22),
        ),
        const SizedBox(height: 10),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 22,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: const TextStyle(
            color: Color(0xFF64748B),
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}
