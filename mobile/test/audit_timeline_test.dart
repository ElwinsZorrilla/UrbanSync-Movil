import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:urbansync/features/audit/domain/audit_entry.dart';
import 'package:urbansync/features/audit/presentation/widgets/audit_diff_view.dart';
import 'package:urbansync/features/audit/presentation/widgets/audit_timeline.dart';

AuditEntry _entry({
  int id = 1,
  String accion = 'Cambio de estado',
  String? detalle,
  String? usuario = 'Supervisor Municipal',
}) => AuditEntry(
  id: id,
  accion: accion,
  fechaHora: DateTime.now().subtract(const Duration(hours: 2)),
  nombreUsuario: usuario,
  entidad: 'Incidencias',
  entidadId: 7,
  detalle: detalle,
);

Widget _wrap(Widget child) => MaterialApp(
  home: Scaffold(body: SingleChildScrollView(child: child)),
);

void main() {
  testWidgets('el timeline lista los eventos con actor y tiempo relativo', (
    tester,
  ) async {
    await tester.pumpWidget(
      _wrap(
        AuditTimeline(
          entries: [
            _entry(id: 1, detalle: 'Estado: Asignada → EnProceso'),
            _entry(id: 2, accion: 'Evidencia', detalle: 'Evidencia subida'),
          ],
        ),
      ),
    );

    expect(find.text('Cambio de estado'), findsOneWidget);
    expect(find.text('Evidencia'), findsOneWidget);
    expect(find.textContaining('Supervisor Municipal'), findsNWidgets(2));
    expect(find.textContaining('hace 2 horas'), findsNWidgets(2));
  });

  testWidgets('al tocar un evento con cambios se despliega el diff', (
    tester,
  ) async {
    await tester.pumpWidget(
      _wrap(
        AuditTimeline(
          entries: [
            _entry(detalle: 'Incidencia INC-001. Estado: Asignada → EnProceso'),
          ],
        ),
      ),
    );

    expect(find.byType(AuditDiffView), findsNothing);

    await tester.tap(find.text('Cambio de estado'));
    await tester.pumpAndSettle();

    expect(find.byType(AuditDiffView), findsOneWidget);
    expect(find.text('Estado'), findsOneWidget);
    expect(find.text('Asignada'), findsOneWidget);
    expect(find.text('EnProceso'), findsOneWidget);
  });

  testWidgets('un evento sin cambios no es desplegable', (tester) async {
    await tester.pumpWidget(
      _wrap(
        AuditTimeline(
          entries: [_entry(accion: 'Evidencia', detalle: 'Evidencia subida')],
        ),
      ),
    );

    await tester.tap(find.text('Evidencia'));
    await tester.pumpAndSettle();

    expect(find.byType(AuditDiffView), findsNothing);
  });

  testWidgets('AuditDiffView pinta el valor ausente como guion', (
    tester,
  ) async {
    await tester.pumpWidget(
      _wrap(
        const AuditDiffView(
          cambios: [AuditChange(campo: 'Estado', despues: 'Registrada')],
        ),
      ),
    );

    expect(find.text('Estado'), findsOneWidget);
    expect(find.text('—'), findsOneWidget);
    expect(find.text('Registrada'), findsOneWidget);
  });

  testWidgets('el actor nulo se muestra como Sistema', (tester) async {
    await tester.pumpWidget(
      _wrap(AuditTimeline(entries: [_entry(usuario: null)])),
    );

    expect(find.textContaining('Sistema'), findsOneWidget);
  });
}
