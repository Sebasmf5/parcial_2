import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:go_router/go_router.dart';

import 'package:parcial_2/models/establecimiento.dart';
import 'package:parcial_2/services/establecimiento_service.dart';
import 'package:parcial_2/widgets/skeleton_list.dart';

/// Pantalla de listado de Establecimientos.
///
/// Consume GET /establecimientos y muestra los resultados en un
/// [ListView.builder]. Incluye Skeletonizer durante la carga,
/// manejo de error, y FAB para crear nuevos establecimientos.
class ListadoScreen extends StatefulWidget {
  const ListadoScreen({super.key});

  @override
  State<ListadoScreen> createState() => _ListadoScreenState();
}

class _ListadoScreenState extends State<ListadoScreen> {
  final EstablecimientoService _service = EstablecimientoService();

  bool _isLoading = true;
  String? _error;
  List<Establecimiento> _establecimientos = [];

  @override
  void initState() {
    super.initState();
    _loadEstablecimientos();
  }

  Future<void> _loadEstablecimientos() async {
    setState(() { _isLoading = true; _error = null; });
    try {
      final result = await _service.getAll();
      if (!mounted) return;
      setState(() { _establecimientos = result; _isLoading = false; });
    } catch (e) {
      if (!mounted) return;
      setState(() { _error = e.toString(); _isLoading = false; });
    }
  }

  String _buildLogoUrl(String? logo) {
    if (logo == null || logo.isEmpty) return '';
    final baseUrl = dotenv.env['PARKING_LOGOS_URL'] ?? '';
    return '$baseUrl/$logo';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0B1121),
      appBar: AppBar(
        title: const Text('Establecimientos',
            style: TextStyle(fontWeight: FontWeight.w700, letterSpacing: -0.3)),
        backgroundColor: const Color(0xFF0B1121),
        foregroundColor: Colors.white,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
      ),
      body: _isLoading
          ? const SkeletonList()
          : _error != null
              ? _buildErrorState()
              : _buildList(),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          await context.pushNamed('establecimiento-crear');
          _loadEstablecimientos();
        },
        backgroundColor: const Color(0xFF7C5CFC),
        elevation: 6,
        child: const Icon(Icons.add_rounded, color: Colors.white, size: 28),
      ),
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
              child: const Icon(Icons.error_outline_rounded, size: 48, color: Color(0xFFFF6B6B)),
            ),
            const SizedBox(height: 20),
            const Text('Error al cargar',
                style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            Text(_error!, style: TextStyle(color: Colors.grey[500], fontSize: 14), textAlign: TextAlign.center),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: _loadEstablecimientos,
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

  Widget _buildList() {
    if (_establecimientos.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.storefront_outlined, size: 56, color: Colors.grey[700]),
            const SizedBox(height: 14),
            Text('Sin establecimientos',
                style: TextStyle(color: Colors.grey[500], fontSize: 16, fontWeight: FontWeight.w500)),
            const SizedBox(height: 4),
            Text('Toca + para crear uno nuevo', style: TextStyle(color: Colors.grey[700], fontSize: 13)),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadEstablecimientos,
      color: const Color(0xFF7C5CFC),
      backgroundColor: const Color(0xFF131B2E),
      child: ListView.builder(
        itemCount: _establecimientos.length,
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
        itemBuilder: (context, index) {
          final est = _establecimientos[index];
          return _buildCard(est);
        },
      ),
    );
  }

  Widget _buildCard(Establecimiento est) {
    final logoUrl = _buildLogoUrl(est.logo);

    return GestureDetector(
      onTap: () async {
        await context.pushNamed(
          'establecimiento-detalle',
          pathParameters: {'id': est.id.toString()},
        );
        _loadEstablecimientos();
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: const Color(0xFF131B2E),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: const Color(0xFF1E293B)),
        ),
        child: Row(
          children: [
            // Logo
            ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: Container(
                width: 52,
                height: 52,
                color: const Color(0xFF1E293B),
                child: logoUrl.isNotEmpty
                    ? Image.network(logoUrl, width: 52, height: 52, fit: BoxFit.cover,
                        errorBuilder: (_, e, s) => const Icon(Icons.storefront_rounded, color: Color(0xFF7C5CFC), size: 24))
                    : const Icon(Icons.storefront_rounded, color: Color(0xFF7C5CFC), size: 24),
              ),
            ),
            const SizedBox(width: 14),
            // Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    est.nombre,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(Icons.badge_outlined, size: 13, color: Colors.grey[600]),
                      const SizedBox(width: 4),
                      Text('NIT: ${est.nit}',
                          style: TextStyle(color: Colors.grey[500], fontSize: 12)),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      Icon(Icons.location_on_outlined, size: 13, color: Colors.grey[600]),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(est.direccion,
                            style: TextStyle(color: Colors.grey[600], fontSize: 12),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            // Arrow
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: const Color(0xFF1E293B),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(Icons.chevron_right_rounded, color: Colors.grey[500], size: 20),
            ),
          ],
        ),
      ),
    );
  }
}
