import 'package:dio/dio.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Servicio encargado de consumir la API de Accidentes de Tránsito de Tuluá.
///
/// Utiliza [Dio] para hacer la petición HTTP y retorna los datos crudos
/// (List<Map>) para ser procesados posteriormente por el Isolate.
class AccidenteService {
  final Dio _dio;

  AccidenteService()
      : _dio = Dio(
          BaseOptions(
            baseUrl: dotenv.env['ACCIDENTS_API_URL'] ?? '',
            connectTimeout: const Duration(seconds: 30),
            receiveTimeout: const Duration(seconds: 60),
          ),
        );

  /// Obtiene todos los registros de accidentes con un límite de 100,000.
  ///
  /// Retorna una lista de mapas JSON crudos que serán pasados al Isolate
  /// para el cálculo estadístico.
  ///
  /// Lanza [DioException] si hay un error de red o del servidor.
  Future<List<Map<String, dynamic>>> fetchAccidentes() async {
    try {
      final response = await _dio.get(
        '',
        queryParameters: {'\$limit': 100000},
      );

      if (response.data is List) {
        return List<Map<String, dynamic>>.from(
          (response.data as List).map((item) => Map<String, dynamic>.from(item)),
        );
      }

      throw DioException(
        requestOptions: response.requestOptions,
        message: 'Formato de respuesta inesperado',
      );
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  /// Traduce errores de [Dio] a mensajes legibles.
  Exception _handleDioError(DioException e) {
    switch (e.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return Exception('Tiempo de espera agotado. Verifica tu conexión.');
      case DioExceptionType.connectionError:
        return Exception('Error de conexión. Verifica tu acceso a internet.');
      case DioExceptionType.badResponse:
        return Exception(
          'Error del servidor: ${e.response?.statusCode ?? "desconocido"}',
        );
      default:
        return Exception('Error inesperado: ${e.message}');
    }
  }
}
