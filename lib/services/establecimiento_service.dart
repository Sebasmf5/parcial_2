import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:parcial_2/models/establecimiento.dart';

/// Servicio encargado del CRUD completo de Establecimientos.
///
/// Consume la API REST del sistema de parqueadero en
/// parking.visiontic.com.co. Maneja envíos multipart/form-data
/// para la carga de logos (imágenes).
class EstablecimientoService {
  final Dio _dio;

  EstablecimientoService()
      : _dio = Dio(
          BaseOptions(
            baseUrl: dotenv.env['PARKING_API_URL'] ?? '',
            connectTimeout: const Duration(seconds: 15),
            receiveTimeout: const Duration(seconds: 15),
          ),
        );

  // ---------------------------------------------------------------------------
  // GET /establecimientos — Listar todos
  // ---------------------------------------------------------------------------
  /// Retorna la lista completa de establecimientos registrados.
  Future<List<Establecimiento>> getAll() async {
    try {
      final response = await _dio.get('/establecimientos');
      final data = response.data;

      if (data is Map<String, dynamic> && data['success'] == true) {
        final list = data['data'] as List;
        return list
            .map((json) => Establecimiento.fromJson(json as Map<String, dynamic>))
            .toList();
      }

      throw Exception('Respuesta inesperada del servidor');
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  // ---------------------------------------------------------------------------
  // GET /establecimientos/{id} — Ver uno
  // ---------------------------------------------------------------------------
  /// Retorna un establecimiento por su [id].
  Future<Establecimiento> getById(int id) async {
    try {
      final response = await _dio.get('/establecimientos/$id');
      final data = response.data;

      if (data is Map<String, dynamic>) {
        // La API puede retornar el objeto directamente o dentro de "data"
        final json = data.containsKey('data')
            ? data['data'] as Map<String, dynamic>
            : data;
        return Establecimiento.fromJson(json);
      }

      throw Exception('Respuesta inesperada del servidor');
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  // ---------------------------------------------------------------------------
  // POST /establecimientos — Crear
  // ---------------------------------------------------------------------------
  /// Crea un nuevo establecimiento con los datos de [establecimiento].
  ///
  /// Si [logoFile] no es null, se adjunta como archivo en multipart/form-data.
  Future<Establecimiento> create(
    Establecimiento establecimiento, {
    File? logoFile,
  }) async {
    try {
      final formMap = <String, dynamic>{
        'nombre': establecimiento.nombre,
        'nit': establecimiento.nit,
        'direccion': establecimiento.direccion,
        'telefono': establecimiento.telefono,
      };

      if (logoFile != null) {
        formMap['logo'] = await MultipartFile.fromFile(
          logoFile.path,
          filename: logoFile.path.split(Platform.pathSeparator).last,
        );
      }

      final formData = FormData.fromMap(formMap);

      final response = await _dio.post('/establecimientos', data: formData);
      final data = response.data;

      if (data is Map<String, dynamic>) {
        final json = data.containsKey('data')
            ? data['data'] as Map<String, dynamic>
            : data;
        return Establecimiento.fromJson(json);
      }

      throw Exception('Error al crear el establecimiento');
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  // ---------------------------------------------------------------------------
  // POST /establecimiento-update/{id} — Editar (method spoofing _method=PUT)
  // ---------------------------------------------------------------------------
  /// Actualiza el establecimiento con [id] usando method spoofing de Laravel.
  ///
  /// Se envía como POST con el campo `_method=PUT` en el form-data.
  /// Si [logoFile] no es null, se adjunta el nuevo logo.
  Future<Establecimiento> update(
    int id,
    Establecimiento establecimiento, {
    File? logoFile,
  }) async {
    try {
      final formMap = <String, dynamic>{
        '_method': 'PUT',
        'nombre': establecimiento.nombre,
        'nit': establecimiento.nit,
        'direccion': establecimiento.direccion,
        'telefono': establecimiento.telefono,
      };

      if (logoFile != null) {
        formMap['logo'] = await MultipartFile.fromFile(
          logoFile.path,
          filename: logoFile.path.split(Platform.pathSeparator).last,
        );
      }

      final formData = FormData.fromMap(formMap);

      final response = await _dio.post(
        '/establecimientos/$id',
        data: formData,
      );
      final data = response.data;

      if (data is Map<String, dynamic>) {
        final json = data.containsKey('data')
            ? data['data'] as Map<String, dynamic>
            : data;
        return Establecimiento.fromJson(json);
      }

      throw Exception('Error al actualizar el establecimiento');
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  // ---------------------------------------------------------------------------
  // DELETE /establecimientos/{id} — Eliminar
  // ---------------------------------------------------------------------------
  /// Elimina el establecimiento con [id].
  Future<bool> delete(int id) async {
    try {
      final response = await _dio.delete('/establecimientos/$id');
      return response.statusCode == 200 || response.statusCode == 204;
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  // ---------------------------------------------------------------------------
  // Manejo de errores de Dio
  // ---------------------------------------------------------------------------
  /// Convierte errores de [Dio] en excepciones con mensajes legibles.
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
