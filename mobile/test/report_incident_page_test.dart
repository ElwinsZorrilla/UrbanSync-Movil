import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:urbansync/features/incidents/data/incidents_repository.dart';
import 'package:urbansync/features/incidents/domain/catalog.dart';
import 'package:urbansync/features/incidents/presentation/report_incident_page.dart';

class _FakeIncidentsRepository extends IncidentsRepository {
  _FakeIncidentsRepository({this.types}) : super(Dio());

  final List<IncidentType>? types;

  int typesCalls = 0;

  @override
  Future<List<IncidentType>> incidentTypes() async {
    typesCalls++;

    return types ??
        const [
          IncidentType(
            id: 1,
            nombre: 'Problema Electrico',
            institucionId: 1,
            institucionNombre: 'EDE',
          ),
        ];
  }

  @override
  Future<Jurisdiction> resolveJurisdiction(double lat, double lng) async =>
      const Jurisdiction(
        id: 1,
        nombre: 'Distrito Nacional',
        nivel: 'Provincia',
      );
}

Future<void> _pumpPage(
  WidgetTester tester,
  _FakeIncidentsRepository repository,
) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [incidentsRepositoryProvider.overrideWithValue(repository)],
      child: const MaterialApp(home: ReportIncidentPage()),
    ),
  );

  await tester.pump();
  await tester.pump(const Duration(milliseconds: 50));
}

void main() {
  testWidgets('ReportIncidentPage renderiza el formulario', (tester) async {
    await _pumpPage(tester, _FakeIncidentsRepository());

    expect(find.text('Reportar incidencia'), findsOneWidget);
    expect(find.text('Tipo de incidencia'), findsOneWidget);
    expect(find.byType(DropdownButtonFormField<int>), findsOneWidget);
  });

  testWidgets('sin tipos disponibles avisa y ofrece reintentar, en vez de '
      'dejar el formulario sin campo', (tester) async {
    final repository = _FakeIncidentsRepository(types: const []);

    await _pumpPage(tester, repository);

    expect(
      find.textContaining('No hay tipos de incidencia configurados'),
      findsOneWidget,
    );
    expect(find.text('Reintentar'), findsOneWidget);
    expect(find.byType(DropdownButtonFormField<int>), findsNothing);
    expect(repository.typesCalls, 1);

    await tester.tap(find.text('Reintentar'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    expect(repository.typesCalls, 2);
  });
}
