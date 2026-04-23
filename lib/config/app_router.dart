import 'package:go_router/go_router.dart';

import 'package:parcial_2/views/home_screen.dart';
import 'package:parcial_2/views/accidentes/estadisticas_screen.dart';
import 'package:parcial_2/views/establecimientos/listado_screen.dart';
import 'package:parcial_2/views/establecimientos/detalle_screen.dart';
import 'package:parcial_2/views/establecimientos/formulario_screen.dart';

/// Configuración centralizada de rutas con [GoRouter].
///
/// Define la navegación de la app con rutas nombradas y paso de parámetros.
/// Rutas:
///   /                            → Dashboard (Home)
///   /estadisticas                → Estadísticas de Accidentes (4 gráficas)
///   /establecimientos            → Listado de Establecimientos
///   /establecimientos/crear      → Formulario de creación
///   /establecimientos/:id        → Detalle del establecimiento
///   /establecimientos/:id/editar → Formulario de edición
final GoRouter appRouter = GoRouter(
  initialLocation: '/',
  routes: [
    // Dashboard principal
    GoRoute(
      path: '/',
      name: 'home',
      builder: (context, state) => const HomeScreen(),
    ),

    // Estadísticas de Accidentes
    GoRoute(
      path: '/estadisticas',
      name: 'estadisticas',
      builder: (context, state) => const EstadisticasScreen(),
    ),

    // Establecimientos — CRUD completo
    GoRoute(
      path: '/establecimientos',
      name: 'establecimientos',
      builder: (context, state) => const ListadoScreen(),
      routes: [
        // Crear nuevo establecimiento
        GoRoute(
          path: 'crear',
          name: 'establecimiento-crear',
          builder: (context, state) => const FormularioScreen(),
        ),

        // Detalle de un establecimiento
        GoRoute(
          path: ':id',
          name: 'establecimiento-detalle',
          builder: (context, state) {
            final id = int.parse(state.pathParameters['id']!);
            return DetalleScreen(establecimientoId: id);
          },
          routes: [
            // Editar establecimiento
            GoRoute(
              path: 'editar',
              name: 'establecimiento-editar',
              builder: (context, state) {
                final id = int.parse(state.pathParameters['id']!);
                return FormularioScreen(establecimientoId: id);
              },
            ),
          ],
        ),
      ],
    ),
  ],
);
