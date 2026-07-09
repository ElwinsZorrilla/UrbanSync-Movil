import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:urbansync/features/incidents/data/incidents_repository.dart';
import 'package:urbansync/features/incidents/domain/catalog.dart';
import 'package:urbansync/features/incidents/presentation/report_incident_page.dart';

class _FakeIncidentsRepository extends IncidentsRepository {
  _FakeIncidentsRepository() : super(Dio());

  @override
  Future<List<IncidentType>> incidentTypes() async => const [
    IncidentType(
      id: 1,
      nombre: 'Problema Electrico',
      institucionId: 1,
      institucionNombre: 'EDE',
    ),
  ];

  @override
  Future<Jurisdiction> resolveJurisdiction(double lat, double lng) async =>
      const Jurisdiction(
        id: 1,
        nombre: 'Distrito Nacional',
        nivel: 'Provincia',
      );
}

void main() {
  testWidgets('ReportIncidentPage renderiza el formulario', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          incidentsRepositoryProvider.overrideWithValue(
            _FakeIncidentsRepository(),
          ),
        ],
        child: const MaterialApp(home: ReportIncidentPage()),
      ),
    );

    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    expect(find.text('Reportar incidencia'), findsOneWidget);
    expect(find.text('Tipo de incidencia'), findsOneWidget);
  });
}
