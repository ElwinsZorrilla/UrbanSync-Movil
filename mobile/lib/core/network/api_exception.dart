import 'package:dio/dio.dart';

class ApiException implements Exception {
  const ApiException(this.message, {this.statusCode});

  final String message;
  final int? statusCode;

  bool get isUnauthorized => statusCode == 401;

  @override
  String toString() => message;

  static ApiException fromDio(DioException error) {
    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return const ApiException('El servidor tardó demasiado en responder.');
      case DioExceptionType.connectionError:
        return const ApiException(
          'No se pudo conectar con el servidor. Revisa tu conexión.',
        );
      case DioExceptionType.badResponse:
        final status = error.response?.statusCode;
        return ApiException(
          _messageFromResponse(error.response?.data, status),
          statusCode: status,
        );
      default:
        return const ApiException('Ocurrió un error inesperado.');
    }
  }

  static String _messageFromResponse(dynamic data, int? status) {
    if (data is Map<String, dynamic>) {
      final detail = data['detail'] ?? data['title'] ?? data['message'];
      if (detail is String && detail.isNotEmpty) return detail;

      final errors = data['errors'];
      if (errors is Map<String, dynamic> && errors.isNotEmpty) {
        final first = errors.values.first;
        if (first is List && first.isNotEmpty) return first.first.toString();
      }
    }

    switch (status) {
      case 401:
        return 'Usuario o contraseña incorrectos.';
      case 403:
        return 'No tienes permisos para esta acción.';
      case 404:
        return 'Recurso no encontrado.';
      case 409:
        return 'El recurso ya existe o está en conflicto.';
      default:
        return 'Error del servidor ($status).';
    }
  }
}
