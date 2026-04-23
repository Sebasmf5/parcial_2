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

  /// Carga la lista de establecimientos desde la API.
  Future<void> _loadEstablecimientos() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final result = await _service.getAll();
      if (!mounted) return;
      setState(() {
        _establecimientos = result;
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

  /// Construye la URL completa del logo del establecimiento.
  String _buildLogoUrl(String? logo) {
    if (logo == null || logo.isEmpty) return '';
    final baseUrl = dotenv.env['PARKING_LOGOS_URL'] ?? '';
    return '$baseUrl/$logo';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F0F23),
      appBar: AppBar(
        title: const Text(
          'Establecimientos',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: const Color(0xFF1A1A2E),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: _isLoading
          ? const SkeletonList()
          : _error != null
              ? _buildErrorState()
              : _buildList(),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          // Navegar al formulario de creación y recargar al volver
          await context.pushNamed('establecimiento-crear');
          _loadEstablecimientos();
        },
        backgroundColor: const Color(0xFF6C63FF),
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('Nuevo', style: TextStyle(color: Colors.white)),
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
            Icon(Icons.error_outline_rounded, size: 64, color: Colors.red[300]),
            const SizedBox(height: 16),
            Text(
              'Error al cargar establecimientos',
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
              onPressed: _loadEstablecimientos,
              icon: const Icon(Icons.refresh),
              label: const Text('Reintentar'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF6C63FF),
                foregroundColor: Colors.white,
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

  Widget _buildList() {
    if (_establecimientos.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.store_outlined, size: 64, color: Colors.grey[600]),
            const SizedBox(height: 16),
            Text(
              'No hay establecimientos registrados',
              style: TextStyle(color: Colors.grey[400], fontSize: 16),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadEstablecimientos,
      color: const Color(0xFF6C63FF),
      child: ListView.builder(
        itemCount: _establecimientos.length,
        padding: const EdgeInsets.all(16),
        itemBuilder: (context, index) {
          final est = _establecimientos[index];
          return _buildEstablecimientoCard(est);
        },
      ),
    );
  }

  Widget _buildEstablecimientoCard(Establecimiento est) {
    final logoUrl = _buildLogoUrl(est.logo);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A2E),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Container(
            width: 50,
            height: 50,
            color: const Color(0xFF2A2A3E),
            child: logoUrl.isNotEmpty
                ? Image.network(
                    logoUrl,
                    width: 50,
                    height: 50,
                    fit: BoxFit.cover,
                    errorBuilder: (_, e, s) => const Icon(
                      Icons.store_rounded,
                      color: Color(0xFF6C63FF),
                    ),
                  )
                : const Icon(
                    Icons.store_rounded,
                    color: Color(0xFF6C63FF),
                  ),
          ),
        ),
        title: Text(
          est.nombre,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
            fontSize: 15,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(
              'NIT: ${est.nit}',
              style: TextStyle(color: Colors.grey[400], fontSize: 13),
            ),
            Text(
              est.direccion,
              style: TextStyle(color: Colors.grey[500], fontSize: 12),
            ),
          ],
        ),
        trailing: Icon(
          Icons.chevron_right_rounded,
          color: Colors.grey[600],
        ),
        onTap: () async {
          // Navegar al detalle y recargar al volver
          await context.pushNamed(
            'establecimiento-detalle',
            pathParameters: {'id': est.id.toString()},
          );
          _loadEstablecimientos();
        },
      ),
    );
  }
}
