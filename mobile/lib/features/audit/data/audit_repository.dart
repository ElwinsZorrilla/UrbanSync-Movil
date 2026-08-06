import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_exception.dart';
import '../../../core/network/dio_client.dart';
import '../domain/audit_entry.dart';
import '../domain/audit_filter.dart';

final auditRepositoryProvider = Provider<AuditRepository>(
  (ref) => AuditRepository(ref.read(dioProvider)),
);

class AuditRepository {
  const AuditRepository(this._dio);
  final Dio _dio;

  Future<List<AuditEntry>> list(AuditFilter filter) async {
    try {
      final response = await _dio.get<List<dynamic>>(
        '/api/activity',
        queryParameters: filter.toQueryParameters(),
      );
      return response.data!
          .map((e) => AuditEntry.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (error) {
      throw ApiException.fromDio(error);
    }
  }

  Future<AuditEntry> getById(int id) async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        '/api/activity/$id',
      );
      return AuditEntry.fromJson(response.data!);
    } on DioException catch (error) {
      throw ApiException.fromDio(error);
    }
  }

  /// El API filtra por `entidad` pero no por `entidadId`, así que la selección
  /// por incidencia se completa en el cliente.
  Future<List<AuditEntry>> forIncident(int incidentId) async {
    final entries = await list(const AuditFilter(entidad: entidadIncidencias));
    return entries.where((e) => e.entidadId == incidentId).toList();
  }

  Future<AuditEntry> log({
    required String accion,
    String? entidad,
    int? entidadId,
    String? detalle,
  }) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        '/api/activity',
        data: {
          'accion': accion,
          'entidad': ?entidad,
          'entidadId': ?entidadId,
          'detalle': ?detalle,
        },
      );
      return AuditEntry.fromJson(response.data!);
    } on DioException catch (error) {
      throw ApiException.fromDio(error);
    }
  }
}
