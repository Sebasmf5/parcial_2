// ignore_for_file: avoid_print

import 'dart:isolate';

/// Contiene la lógica de procesamiento estadístico que se ejecuta
/// en un Isolate separado del hilo principal.
///
/// Al recibir miles de registros de accidentes, el procesamiento se
/// delega a [Isolate.run()] para evitar bloquear la UI.
class AccidenteIsolate {
  /// Procesa la lista completa de registros de accidentes en un Isolate
  /// y calcula 4 estadísticas.
  ///
  /// Retorna un `Map<String, dynamic>` con las claves:
  /// - `distribucionClase`: `Map<String, int>` (Choque, Atropello, Volcamiento, Otros)
  /// - `distribucionGravedad`: `Map<String, int>` (Con muertos, Con heridos, Solo daños)
  /// - `top5Barrios`: `List<Map<String, dynamic>>` con barrio y cantidad
  /// - `distribucionDia`: `Map<String, int>` (lunes..domingo)
  /// - `totalRegistros`: int
  static Future<Map<String, dynamic>> processAccidentes(
    List<Map<String, dynamic>> rawData,
  ) async {
    return await Isolate.run(() => _computeEstadisticas(rawData));
  }

  /// Función pura que realiza el cálculo estadístico.
  ///
  /// Se ejecuta dentro del Isolate, completamente aislada del hilo principal.
  /// Imprime mensajes de inicio y finalización con tiempos de ejecución.
  static Map<String, dynamic> _computeEstadisticas(
    List<Map<String, dynamic>> data,
  ) {
    final stopwatch = Stopwatch()..start();
    print('[Isolate] Iniciado — ${data.length} registros recibidos');

    // -----------------------------------------------------------------------
    // 1. Distribución por clase de accidente
    // -----------------------------------------------------------------------
    final Map<String, int> distribucionClase = {};
    for (final record in data) {
      final clase = _normalizeClaseAccidente(
        record['clase_de_accidente'] as String? ?? 'OTROS',
      );
      distribucionClase[clase] = (distribucionClase[clase] ?? 0) + 1;
    }

    // -----------------------------------------------------------------------
    // 2. Distribución por gravedad
    // -----------------------------------------------------------------------
    final Map<String, int> distribucionGravedad = {};
    for (final record in data) {
      final gravedad = _normalizeGravedad(
        record['gravedad_del_accidente'] as String? ?? 'SOLO DAÑOS',
      );
      distribucionGravedad[gravedad] = (distribucionGravedad[gravedad] ?? 0) + 1;
    }

    // -----------------------------------------------------------------------
    // 3. Top 5 barrios con más accidentes
    // -----------------------------------------------------------------------
    final Map<String, int> barriosCount = {};
    for (final record in data) {
      final barrio = (record['barrio_hecho'] as String? ?? 'Sin información')
          .toUpperCase()
          .trim();
      if (barrio.isNotEmpty && barrio != 'NO INFORMA' && barrio != 'SIN INFORMACIÓN') {
        barriosCount[barrio] = (barriosCount[barrio] ?? 0) + 1;
      }
    }
    // Ordenar por cantidad descendente y tomar los 5 primeros
    final sortedBarrios = barriosCount.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final top5Barrios = sortedBarrios.take(5).map((entry) {
      return {'barrio': entry.key, 'cantidad': entry.value};
    }).toList();

    // -----------------------------------------------------------------------
    // 4. Distribución por día de la semana
    // -----------------------------------------------------------------------
    final Map<String, int> distribucionDia = {
      'lunes': 0,
      'martes': 0,
      'miércoles': 0,
      'jueves': 0,
      'viernes': 0,
      'sábado': 0,
      'domingo': 0,
    };
    for (final record in data) {
      final dia = (record['dia'] as String? ?? '').toLowerCase().trim();
      // Normalizar tildes para mapear correctamente
      final diaNormalizado = _normalizeDia(dia);
      if (distribucionDia.containsKey(diaNormalizado)) {
        distribucionDia[diaNormalizado] = distribucionDia[diaNormalizado]! + 1;
      }
    }

    stopwatch.stop();
    print('[Isolate] Completado en ${stopwatch.elapsedMilliseconds} ms');

    return {
      'distribucionClase': distribucionClase,
      'distribucionGravedad': distribucionGravedad,
      'top5Barrios': top5Barrios,
      'distribucionDia': distribucionDia,
      'totalRegistros': data.length,
    };
  }

  /// Normaliza la clase de accidente a categorías principales.
  static String _normalizeClaseAccidente(String clase) {
    final upper = clase.toUpperCase().trim();
    if (upper.contains('CHOQUE')) return 'Choque';
    if (upper.contains('ATROPELLO')) return 'Atropello';
    if (upper.contains('VOLCAMIENTO')) return 'Volcamiento';
    if (upper.contains('CAIDA')) return 'Caída';
    return 'Otros';
  }

  /// Normaliza la gravedad del accidente.
  static String _normalizeGravedad(String gravedad) {
    final upper = gravedad.toUpperCase().trim();
    if (upper.contains('MUERTO') || upper.contains('MUERTOS')) {
      return 'Con muertos';
    }
    if (upper.contains('HERIDO') || upper.contains('HERIDOS')) {
      return 'Con heridos';
    }
    return 'Solo daños';
  }

  /// Normaliza el día de la semana (resuelve variantes sin tilde).
  static String _normalizeDia(String dia) {
    final d = dia.toLowerCase().trim();
    if (d == 'lunes') return 'lunes';
    if (d == 'martes') return 'martes';
    if (d == 'miercoles' || d == 'miércoles') return 'miércoles';
    if (d == 'jueves') return 'jueves';
    if (d == 'viernes') return 'viernes';
    if (d == 'sabado' || d == 'sábado') return 'sábado';
    if (d == 'domingo') return 'domingo';
    return d;
  }
}
