import 'package:flutter/material.dart';
import 'package:skeletonizer/skeletonizer.dart';

const _darkShimmerEffect = ShimmerEffect(
  baseColor: Color(0xFF1E293B),
  highlightColor: Color(0xFF334155),
);

/// Widget genérico que muestra un efecto skeleton mientras los datos cargan.
///
/// Usa [Skeletonizer] para envolver una lista de tarjetas placeholder.
class SkeletonList extends StatelessWidget {
  final int itemCount;

  const SkeletonList({super.key, this.itemCount = 5});

  @override
  Widget build(BuildContext context) {
    return Skeletonizer(
      enabled: true,
      effect: _darkShimmerEffect,
      child: ListView.builder(
        itemCount: itemCount,
        padding: const EdgeInsets.all(16),
        itemBuilder: (context, index) {
          return Container(
            margin: const EdgeInsets.only(bottom: 14),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFF162032),
              borderRadius: BorderRadius.circular(18),
            ),
            child: Row(
              children: [
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E2A40),
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                const SizedBox(width: 14),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Nombre del lugar aquí'),
                      SizedBox(height: 6),
                      Text('NIT: 000000 · Dirección'),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

/// Widget que muestra un skeleton para la pantalla de estadísticas.
class SkeletonEstadisticas extends StatelessWidget {
  const SkeletonEstadisticas({super.key});

  @override
  Widget build(BuildContext context) {
    return Skeletonizer(
      enabled: true,
      effect: _darkShimmerEffect,
      child: ListView.builder(
        itemCount: 4,
        padding: const EdgeInsets.all(16),
        itemBuilder: (context, index) {
          return Container(
            margin: const EdgeInsets.only(bottom: 16),
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: const Color(0xFF162032),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Título de la estadística',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                Container(
                  height: 200,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E2A40),
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

/// Widget para mostrar el skeleton del Dashboard.
class SkeletonDashboard extends StatelessWidget {
  const SkeletonDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    return Skeletonizer(
      enabled: true,
      effect: _darkShimmerEffect,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const SizedBox(height: 12),
            // Skeleton resumen
            Container(
              width: double.infinity,
              height: 90,
              decoration: BoxDecoration(
                color: const Color(0xFF162032),
                borderRadius: BorderRadius.circular(20),
              ),
            ),
            const SizedBox(height: 24),
            // Skeleton card 1
            Container(
              width: double.infinity,
              height: 90,
              decoration: BoxDecoration(
                color: const Color(0xFF162032),
                borderRadius: BorderRadius.circular(24),
              ),
            ),
            const SizedBox(height: 16),
            // Skeleton card 2
            Container(
              width: double.infinity,
              height: 90,
              decoration: BoxDecoration(
                color: const Color(0xFF162032),
                borderRadius: BorderRadius.circular(24),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Widget para mostrar el skeleton del Detalle.
class SkeletonDetalle extends StatelessWidget {
  const SkeletonDetalle({super.key});

  @override
  Widget build(BuildContext context) {
    return Skeletonizer(
      enabled: true,
      effect: _darkShimmerEffect,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Container(
              width: double.infinity,
              height: 180,
              decoration: BoxDecoration(
                color: const Color(0xFF131B2E),
                borderRadius: BorderRadius.circular(22),
              ),
            ),
            const SizedBox(height: 20),
            Container(
              width: double.infinity,
              height: 300,
              decoration: BoxDecoration(
                color: const Color(0xFF131B2E),
                borderRadius: BorderRadius.circular(22),
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: Container(
                    height: 50,
                    decoration: BoxDecoration(
                      color: const Color(0xFF131B2E),
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Container(
                    height: 50,
                    decoration: BoxDecoration(
                      color: const Color(0xFF131B2E),
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Widget para mostrar el skeleton del Formulario.
class SkeletonFormulario extends StatelessWidget {
  const SkeletonFormulario({super.key});

  @override
  Widget build(BuildContext context) {
    return Skeletonizer(
      enabled: true,
      effect: _darkShimmerEffect,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              height: 150,
              decoration: BoxDecoration(
                color: const Color(0xFF131B2E),
                borderRadius: BorderRadius.circular(22),
              ),
            ),
            const SizedBox(height: 24),
            Container(height: 55, decoration: BoxDecoration(color: const Color(0xFF131B2E), borderRadius: BorderRadius.circular(16))),
            const SizedBox(height: 14),
            Container(height: 55, decoration: BoxDecoration(color: const Color(0xFF131B2E), borderRadius: BorderRadius.circular(16))),
            const SizedBox(height: 14),
            Container(height: 55, decoration: BoxDecoration(color: const Color(0xFF131B2E), borderRadius: BorderRadius.circular(16))),
            const SizedBox(height: 14),
            Container(height: 55, decoration: BoxDecoration(color: const Color(0xFF131B2E), borderRadius: BorderRadius.circular(16))),
            const SizedBox(height: 32),
            Container(height: 50, decoration: BoxDecoration(color: const Color(0xFF131B2E), borderRadius: BorderRadius.circular(16))),
          ],
        ),
      ),
    );
  }
}
