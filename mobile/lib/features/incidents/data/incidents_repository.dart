import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_exception.dart';
import '../../../core/network/dio_client.dart';
import '../domain/catalog.dart';
import '../domain/incident.dart';

final incidentsRepositoryProvider = Provider<IncidentsRepository>(
  (ref) => IncidentsRepository(ref.read(dioProvider)),
);

class IncidentsRepository {
  const IncidentsRepository(this._dio);
  final Dio _dio;

  Future<List<Incident>> list({String? status, bool mine = false}) async {
    try {
      final response = await _dio.get<List<dynamic>>(
        '/api/incidents',
        queryParameters: {
          if (status != null) 'status': status,
          if (mine) 'mine': true,
        },
      );
      return response.data!
          .map((e) => Incident.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (error) {
      throw ApiException.fromDio(error);
    }
  }

  Future<Incident> getById(int id) async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        '/api/incidents/$id',
      );
      return Incident.fromJson(response.data!);
    } on DioException catch (error) {
      throw ApiException.fromDio(error);
    }
  }

  Future<Incident> create({
    required int tipoIncidenciaId,
    required String descripcion,
    required String prioridad,
    required double lat,
    required double lng,
    required String direccion,
    String? referencia,
    int? jurisdiccionId,
  }) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        '/api/incidents',
        data: {
          'tipoIncidenciaId': tipoIncidenciaId,
          'descripcion': descripcion,
          'prioridad': prioridad,
          'ubicacion': {
            'lat': lat,
            'lng': lng,
            'direccion': direccion,
            'referencia': referencia,
            'jurisdiccionId': jurisdiccionId,
          },
        },
      );
      return Incident.fromJson(response.data!);
    } on DioException catch (error) {
      throw ApiException.fromDio(error);
    }
  }

  Future<Incident> triage(
    int id, {
    int? tipoIncidenciaId,
    String? prioridad,
    String? accion,
    int? jurisdiccionId,
  }) async {
    try {
      final response = await _dio.patch<Map<String, dynamic>>(
        '/api/incidents/$id/triage',
        data: {
          'tipoIncidenciaId': tipoIncidenciaId,
          'prioridad': prioridad,
          'accion': accion,
          'jurisdiccionId': jurisdiccionId,
        },
      );
      return Incident.fromJson(response.data!);
    } on DioException catch (error) {
      throw ApiException.fromDio(error);
    }
  }

  Future<Incident> updateStatus(int id, String estado) async {
    try {
      final response = await _dio.patch<Map<String, dynamic>>(
        '/api/incidents/$id/status',
        data: {'estado': estado},
      );
      return Incident.fromJson(response.data!);
    } on DioException catch (error) {
      throw ApiException.fromDio(error);
    }
  }

  Future<List<Evidence>> listEvidences(int incidentId) async {
    try {
      final response = await _dio.get<List<dynamic>>(
        '/api/incidents/$incidentId/evidences',
      );
      return response.data!
          .map((e) => Evidence.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (error) {
      throw ApiException.fromDio(error);
    }
  }

  Future<Evidence> uploadEvidence(
    int incidentId, {
    required String filePath,
    required String tipo,
    double? lat,
    double? lng,
    String? descripcion,
    void Function(int sent, int total)? onProgress,
  }) async {
    try {
      final formData = FormData.fromMap({
        'file': await MultipartFile.fromFile(filePath),
        'tipo': tipo,
        if (lat != null) 'lat': lat,
        if (lng != null) 'lng': lng,
        if (descripcion != null) 'descripcion': descripcion,
      });

      final response = await _dio.post<Map<String, dynamic>>(
        '/api/incidents/$incidentId/evidences',
        data: formData,
        onSendProgress: onProgress,
      );
      return Evidence.fromJson(response.data!);
    } on DioException catch (error) {
      throw ApiException.fromDio(error);
    }
  }

  Future<List<IncidentType>> incidentTypes() async {
    try {
      final response = await _dio.get<List<dynamic>>('/api/incident-types');
      return response.data!
          .map((e) => IncidentType.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (error) {
      throw ApiException.fromDio(error);
    }
  }

  Future<List<Jurisdiction>> jurisdictions() async {
    try {
      final response = await _dio.get<List<dynamic>>('/api/jurisdictions');
      return response.data!
          .map((e) => Jurisdiction.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (error) {
      throw ApiException.fromDio(error);
    }
  }

  Future<Jurisdiction> resolveJurisdiction(double lat, double lng) async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        '/api/jurisdictions/resolve',
        queryParameters: {'lat': lat, 'lng': lng},
      );
      return Jurisdiction.fromJson(response.data!);
    } on DioException catch (error) {
      throw ApiException.fromDio(error);
    }
  }
}
