import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:go_router/go_router.dart';

import 'package:parcial_2/models/establecimiento.dart';
import 'package:parcial_2/services/establecimiento_service.dart';
import 'package:parcial_2/widgets/skeleton_list.dart';

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
        backgroundColor: const Color(0xFF131B2E),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Color(0xFFFF6B6B), size: 24),
            SizedBox(width: 10),
            Text('Eliminar', style: TextStyle(color: Colors.white, fontSize: 18)),
          ],
        ),
        content: Text(
          '¿Eliminar "${_establecimiento?.nombre}"?\nEsta acción es permanente.',
          style: TextStyle(color: Colors.grey[400], height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text('Cancelar', style: TextStyle(color: Colors.grey[500])),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFFFF6B6B),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
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
          SnackBar(
            content: const Text('Establecimiento eliminado'),
            backgroundColor: const Color(0xFF34D399),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
        context.pop();
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: const Color(0xFFFF6B6B),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0B1121),
      appBar: AppBar(
        title: const Text('Detalle', style: TextStyle(fontWeight: FontWeight.w700)),
        backgroundColor: const Color(0xFF0B1121),
        foregroundColor: Colors.white,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        actions: _establecimiento != null
            ? [
                IconButton(
                  icon: const Icon(Icons.edit_rounded, size: 22),
                  onPressed: () async {
                    await context.pushNamed(
                      'establecimiento-editar',
                      pathParameters: {'id': widget.establecimientoId.toString()},
                    );
                    _loadDetalle();
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline_rounded, size: 22, color: Color(0xFFFF6B6B)),
                  onPressed: _confirmDelete,
                ),
              ]
            : null,
      ),
      body: _isLoading
          ? const SkeletonDetalle()
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
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFFFF6B6B).withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.error_outline, size: 48, color: Color(0xFFFF6B6B)),
            ),
            const SizedBox(height: 20),
            const Text('Error al cargar',
                style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            Text(_error!, style: TextStyle(color: Colors.grey[500]), textAlign: TextAlign.center),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: _loadDetalle,
              icon: const Icon(Icons.refresh_rounded, size: 20),
              label: const Text('Reintentar'),
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFF7C5CFC),
                foregroundColor: Colors.white,
              ),
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
            height: 180,
            decoration: BoxDecoration(
              color: const Color(0xFF131B2E),
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: const Color(0xFF1E293B)),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(22),
              child: logoUrl.isNotEmpty
                  ? Image.network(logoUrl, fit: BoxFit.contain,
                      errorBuilder: (_, e, s) => const Center(
                          child: Icon(Icons.storefront_rounded, size: 56, color: Color(0xFF7C5CFC))))
                  : const Center(
                      child: Icon(Icons.storefront_rounded, size: 56, color: Color(0xFF7C5CFC))),
            ),
          ),
          const SizedBox(height: 20),

          // Info card
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: const Color(0xFF131B2E),
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: const Color(0xFF1E293B)),
            ),
            child: Column(
              children: [
                _infoRow(Icons.storefront_rounded, 'Nombre', est.nombre),
                _divider(),
                _infoRow(Icons.badge_rounded, 'NIT', est.nit),
                _divider(),
                _infoRow(Icons.location_on_rounded, 'Dirección', est.direccion),
                _divider(),
                _infoRow(Icons.phone_rounded, 'Teléfono', est.telefono),
                if (est.estado != null) ...[
                  _divider(),
                  _infoRow(
                    est.estado == 'A' ? Icons.check_circle_rounded : Icons.cancel_rounded,
                    'Estado',
                    est.estado == 'A' ? 'Activo' : 'Inactivo',
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Action buttons
          Row(
            children: [
              Expanded(
                child: FilledButton.icon(
                  onPressed: () async {
                    await context.pushNamed('establecimiento-editar',
                        pathParameters: {'id': widget.establecimientoId.toString()});
                    _loadDetalle();
                  },
                  icon: const Icon(Icons.edit_rounded, size: 20),
                  label: const Text('Editar'),
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFF7C5CFC),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _confirmDelete,
                  icon: const Icon(Icons.delete_outline_rounded, size: 20),
                  label: const Text('Eliminar'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFFFF6B6B),
                    side: const BorderSide(color: Color(0xFFFF6B6B), width: 1.5),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
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
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFF7C5CFC).withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: const Color(0xFF7C5CFC), size: 20),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: const TextStyle(color: Color(0xFF64748B), fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 0.5)),
                const SizedBox(height: 2),
                Text(value,
                    style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w500)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _divider() => Divider(color: const Color(0xFF1E293B), height: 1, thickness: 1);
}
