import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:urbansync/core/network/api_exception.dart';
import 'package:urbansync/features/audit/data/audit_repository.dart';
import 'package:urbansync/features/audit/domain/audit_filter.dart';

class _MockDio extends Mock implements Dio {}

Map<String, dynamic> _entry({
  required int id,
  String accion = 'Cambio de estado',
  String? entidad = 'Incidencias',
  int? entidadId,
  String? detalle,
}) => {
  'id': id,
  'usuarioId': 'c5aca9bc',
  'nombreUsuario': 'Supervisor Municipal',
  'accion': accion,
  'entidad': entidad,
  'entidadId': entidadId,
  'detalle': detalle,
  'ipOrigen': '::1',
  'fechaHora': '2026-08-06T18:22:47.7528299Z',
};

void main() {
  late _MockDio dio;
  late AuditRepository repository;

  setUp(() {
    dio = _MockDio();
    repository = AuditRepository(dio);
  });

  test('list envía los filtros como query parameters', () async {
    when(
      () => dio.get<List<dynamic>>(
        '/api/activity',
        queryParameters: any(named: 'queryParameters'),
      ),
    ).thenAnswer(
      (_) async => Response<List<dynamic>>(
        requestOptions: RequestOptions(path: '/api/activity'),
        data: [_entry(id: 1, entidadId: 5)],
      ),
    );

    final entries = await repository.list(
      const AuditFilter(entidad: 'Incidencias', accion: 'Triage'),
    );

    expect(entries, hasLength(1));
    expect(entries.single.entidadId, 5);

    final captured = verify(
      () => dio.get<List<dynamic>>(
        '/api/activity',
        queryParameters: captureAny(named: 'queryParameters'),
      ),
    ).captured.single;

    expect(captured, {'entidad': 'Incidencias', 'accion': 'Triage'});
  });

  test('forIncident filtra en cliente por entidadId', () async {
    when(
      () => dio.get<List<dynamic>>(
        '/api/activity',
        queryParameters: any(named: 'queryParameters'),
      ),
    ).thenAnswer(
      (_) async => Response<List<dynamic>>(
        requestOptions: RequestOptions(path: '/api/activity'),
        data: [
          _entry(id: 1, entidadId: 7, detalle: 'Estado: Asignada → EnProceso'),
          _entry(id: 2, entidadId: 99),
          _entry(id: 3, entidadId: 7, accion: 'Evidencia'),
          _entry(id: 4, entidad: null, entidadId: null),
        ],
      ),
    );

    final entries = await repository.forIncident(7);

    expect(entries.map((e) => e.id), [1, 3]);
    expect(entries.first.cambios.single.despues, 'EnProceso');

    final captured = verify(
      () => dio.get<List<dynamic>>(
        '/api/activity',
        queryParameters: captureAny(named: 'queryParameters'),
      ),
    ).captured.single;

    expect(captured, {'entidad': 'Incidencias'});
  });

  test('log omite las claves nulas del cuerpo', () async {
    when(
      () => dio.post<Map<String, dynamic>>(
        '/api/activity',
        data: any(named: 'data'),
      ),
    ).thenAnswer(
      (_) async => Response<Map<String, dynamic>>(
        requestOptions: RequestOptions(path: '/api/activity'),
        data: _entry(id: 10, accion: 'Verificacion', entidadId: 7),
      ),
    );

    await repository.log(accion: 'Verificacion', entidadId: 7);

    final captured = verify(
      () => dio.post<Map<String, dynamic>>(
        '/api/activity',
        data: captureAny(named: 'data'),
      ),
    ).captured.single;

    expect(captured, {'accion': 'Verificacion', 'entidadId': 7});
  });

  test('el 403 de rol insuficiente se mapea a ApiException', () async {
    when(
      () => dio.get<List<dynamic>>(
        '/api/activity',
        queryParameters: any(named: 'queryParameters'),
      ),
    ).thenThrow(
      DioException(
        requestOptions: RequestOptions(path: '/api/activity'),
        type: DioExceptionType.badResponse,
        response: Response(
          requestOptions: RequestOptions(path: '/api/activity'),
          statusCode: 403,
        ),
      ),
    );

    await expectLater(
      () => repository.list(const AuditFilter()),
      throwsA(
        isA<ApiException>()
            .having((e) => e.statusCode, 'statusCode', 403)
            .having(
              (e) => e.message,
              'message',
              'No tienes permisos para esta acción.',
            ),
      ),
    );
  });
}
