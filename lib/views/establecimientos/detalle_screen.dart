import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:go_router/go_router.dart';

import 'package:parcial_2/models/establecimiento.dart';
import 'package:parcial_2/services/establecimiento_service.dart';

/// Pantalla de detalle de un Establecimiento.
///
/// Muestra todos los campos incluyendo el logo.
/// Permite editar y eliminar (con confirmación).
class DetalleScreen extends StatefulWidget {
  final int establecimientoId;

  const DetalleScreen({super.key, required this.establecimientoId});

  @override
  State<DetalleScreen> createState() => _DetalleScreenState();
}

class _DetalleScreenState extends State<DetalleScreen> {
  final EstablecimientoService _service = EstablecimientoService();

  bool _isLoading = true;
  String? _error;
  Establecimiento? _establecimiento;

  @override
  void initState() {
    super.initState();
    _loadDetalle();
  }

  Future<void> _loadDetalle() async {
    setState(() { _isLoading = true; _error = null; });
    try {
      final result = await _service.getById(widget.establecimientoId);
      if (!mounted) return;
      setState(() { _establecimiento = result; _isLoading = false; });
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

  Future<void> _confirmDelete() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A2E),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('¿Eliminar?', style: TextStyle(color: Colors.white)),
        content: Text(
          'Se eliminará "${_establecimiento?.nombre}" permanentemente.',
          style: TextStyle(color: Colors.grey[400]),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text('Cancelar', style: TextStyle(color: Colors.grey[400])),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red[600],
              foregroundColor: Colors.white,
            ),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );

    if (confirm == true && mounted) {
      try {
        await _service.delete(widget.establecimientoId);
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Eliminado exitosamente'),
            backgroundColor: Color(0xFF43E97B),
          ),
        );
        context.pop();
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F0F23),
      appBar: AppBar(
        title: const Text('Detalle', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFF1A1A2E),
        foregroundColor: Colors.white,
        elevation: 0,
        actions: _establecimiento != null
            ? [
                IconButton(
                  icon: const Icon(Icons.edit_rounded),
                  onPressed: () async {
                    await context.pushNamed(
                      'establecimiento-editar',
                      pathParameters: {'id': widget.establecimientoId.toString()},
                    );
                    _loadDetalle();
                  },
                ),
                IconButton(
                  icon: Icon(Icons.delete_rounded, color: Colors.red[300]),
                  onPressed: _confirmDelete,
                ),
              ]
            : null,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF6C63FF)))
          : _error != null
              ? _buildError()
              : _buildDetalle(),
    );
  }

  Widget _buildError() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: Colors.red[300]),
            const SizedBox(height: 16),
            Text('Error al cargar', style: TextStyle(color: Colors.red[300], fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text(_error!, style: TextStyle(color: Colors.grey[400]), textAlign: TextAlign.center),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _loadDetalle,
              icon: const Icon(Icons.refresh),
              label: const Text('Reintentar'),
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF6C63FF), foregroundColor: Colors.white),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetalle() {
    final est = _establecimiento!;
    final logoUrl = _buildLogoUrl(est.logo);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          // Logo
          Container(
            width: double.infinity,
            height: 200,
            decoration: BoxDecoration(
              color: const Color(0xFF1A1A2E),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: logoUrl.isNotEmpty
                  ? Image.network(logoUrl, fit: BoxFit.contain,
                      errorBuilder: (_, e, s) => const Center(child: Icon(Icons.store_rounded, size: 64, color: Color(0xFF6C63FF))))
                  : const Center(child: Icon(Icons.store_rounded, size: 64, color: Color(0xFF6C63FF))),
            ),
          ),
          const SizedBox(height: 24),

          // Info card
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: const Color(0xFF1A1A2E),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
            ),
            child: Column(
              children: [
                _infoRow(Icons.store_rounded, 'Nombre', est.nombre),
                _divider(),
                _infoRow(Icons.badge_rounded, 'NIT', est.nit),
                _divider(),
                _infoRow(Icons.location_on_rounded, 'Dirección', est.direccion),
                _divider(),
                _infoRow(Icons.phone_rounded, 'Teléfono', est.telefono),
                if (est.estado != null) ...[
                  _divider(),
                  _infoRow(Icons.circle, 'Estado', est.estado == 'A' ? 'Activo' : 'Inactivo'),
                ],
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Action buttons
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () async {
                    await context.pushNamed('establecimiento-editar',
                        pathParameters: {'id': widget.establecimientoId.toString()});
                    _loadDetalle();
                  },
                  icon: const Icon(Icons.edit_rounded),
                  label: const Text('Editar'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF6C63FF),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _confirmDelete,
                  icon: const Icon(Icons.delete_rounded),
                  label: const Text('Eliminar'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red[600],
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _infoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, color: const Color(0xFF6C63FF), size: 22),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: TextStyle(color: Colors.grey[500], fontSize: 12)),
              const SizedBox(height: 2),
              Text(value, style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w500)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _divider() => Divider(color: Colors.white.withValues(alpha: 0.06), height: 1);
}
