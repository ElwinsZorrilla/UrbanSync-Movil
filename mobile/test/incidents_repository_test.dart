import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:urbansync/features/incidents/data/incidents_repository.dart';

class _MockDio extends Mock implements Dio {}

Map<String, dynamic> _incidentJson(int id) => {
  'id': id,
  'codigoCaso': 'INC-$id',
  'estado': 'Registrada',
  'prioridad': 'Media',
  'descripcion': 'Poste caído',
  'tipoIncidenciaId': 1,
  'tipoIncidencia': 'Problema Electrico',
  'jurisdiccionId': 1,
  'jurisdiccion': 'Distrito Nacional',
  'direccion': 'Av. Central',
  'usuarioReporta': 'Ana',
  'fechaReporte': '2026-07-09T10:00:00Z',
};

void main() {
  late _MockDio dio;
  late IncidentsRepository repository;

  setUp(() {
    dio = _MockDio();
    repository = IncidentsRepository(dio);
  });

  test('list parsea la colección de incidencias', () async {
    when(
      () => dio.get<List<dynamic>>(
        '/api/incidents',
        queryParameters: any(named: 'queryParameters'),
      ),
    ).thenAnswer(
      (_) async => Response<List<dynamic>>(
        requestOptions: RequestOptions(path: '/api/incidents'),
        data: [_incidentJson(1), _incidentJson(2)],
      ),
    );

    final incidents = await repository.list(mine: true);

    expect(incidents, hasLength(2));
    expect(incidents.first.codigoCaso, 'INC-1');
    expect(incidents.first.jurisdiccion, 'Distrito Nacional');
  });

  test('create envía la ubicación y devuelve la incidencia', () async {
    when(
      () => dio.post<Map<String, dynamic>>(
        '/api/incidents',
        data: any(named: 'data'),
      ),
    ).thenAnswer(
      (_) async => Response<Map<String, dynamic>>(
        requestOptions: RequestOptions(path: '/api/incidents'),
        data: _incidentJson(5),
      ),
    );

    final incident = await repository.create(
      tipoIncidenciaId: 1,
      descripcion: 'Poste caído',
      prioridad: 'Alta',
      lat: 18.48,
      lng: -69.93,
      direccion: 'Av. Central',
    );

    expect(incident.id, 5);
    expect(incident.estado, 'Registrada');
  });
}
