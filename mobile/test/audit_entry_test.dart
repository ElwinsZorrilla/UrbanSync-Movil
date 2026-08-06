import 'package:flutter_test/flutter_test.dart';
import 'package:urbansync/features/audit/domain/audit_entry.dart';
import 'package:urbansync/features/audit/domain/audit_filter.dart';

void main() {
  group('AuditEntry.fromJson', () {
    test('mapea la respuesta completa del API', () {
      final entry = AuditEntry.fromJson({
        'id': 1002,
        'usuarioId': 'c5aca9bc-ed2c-4de0-8419-570bdb691e19',
        'nombreUsuario': 'Supervisor Municipal',
        'accion': 'Cambio de estado',
        'entidad': 'Incidencias',
        'entidadId': 1,
        'detalle': 'Incidencia INC-001. Estado: Asignada → EnProceso',
        'ipOrigen': '::ffff:172.25.0.1',
        'fechaHora': '2026-08-06T18:22:47.7528299Z',
      });

      expect(entry.id, 1002);
      expect(entry.kind, AuditActionKind.cambioEstado);
      expect(entry.entidadId, 1);
      expect(entry.esDeIncidencia, isTrue);
      expect(entry.fechaHora.isUtc, isTrue);
    });

    test('tolera los campos nulos del listado', () {
      final entry = AuditEntry.fromJson({
        'id': 7,
        'usuarioId': null,
        'nombreUsuario': null,
        'accion': 'Login',
        'entidad': null,
        'entidadId': null,
        'detalle': null,
        'ipOrigen': null,
        'fechaHora': '2026-08-06T18:22:47Z',
      });

      expect(entry.nombreUsuario, isNull);
      expect(entry.entidad, isNull);
      expect(entry.esDeIncidencia, isFalse);
      expect(entry.cambios, isEmpty);
    });

    test('una acción desconocida no revienta, cae en desconocida', () {
      final entry = AuditEntry.fromJson({
        'id': 8,
        'accion': 'Accion Que No Existe',
        'fechaHora': '2026-08-06T18:22:47Z',
      });

      expect(entry.kind, AuditActionKind.desconocida);
      expect(entry.accion, 'Accion Que No Existe');
    });
  });

  group('AuditChange.parse', () {
    test('extrae el campo ignorando el prefijo de la frase', () {
      final cambios = AuditChange.parse(
        'Incidencia INC-20260709-66D0935F. Estado: Asignada → EnProceso',
      );

      expect(cambios, hasLength(1));
      expect(cambios.single.campo, 'Estado');
      expect(cambios.single.antes, 'Asignada');
      expect(cambios.single.despues, 'EnProceso');
    });

    test('extrae varios cambios separados por punto y coma', () {
      final cambios = AuditChange.parse(
        'Incidencia INC-001 analizada. Estado: Registrada → Asignada; '
        'Prioridad: Media → Alta',
      );

      expect(cambios, hasLength(2));
      expect(cambios[0].campo, 'Estado');
      expect(cambios[1].campo, 'Prioridad');
      expect(cambios[1].despues, 'Alta');
    });

    test('trata el guion largo como ausencia de valor', () {
      final cambios = AuditChange.parse(
        'Incidencia INC-001 registrada. Estado: — → Registrada',
      );

      expect(cambios.single.antes, isNull);
      expect(cambios.single.despues, 'Registrada');
    });

    test('devuelve vacío cuando el detalle no tiene diff', () {
      expect(AuditChange.parse('Evidencia subida a la incidencia'), isEmpty);
      expect(AuditChange.parse(null), isEmpty);
      expect(AuditChange.parse(''), isEmpty);
    });
  });

  group('AuditFilter', () {
    test('toQueryParameters omite las claves nulas', () {
      expect(const AuditFilter().toQueryParameters(), isEmpty);

      final filter = const AuditFilter(
        entidad: 'Incidencias',
        accion: 'Triage',
      );

      expect(filter.toQueryParameters(), {
        'entidad': 'Incidencias',
        'accion': 'Triage',
      });
    });

    test('las fechas se envían en UTC ISO-8601', () {
      final filter = AuditFilter(
        desde: DateTime.utc(2026, 8, 1, 5, 30),
        hasta: DateTime.utc(2026, 8, 6),
      );

      expect(
        filter.toQueryParameters()['fechaInicio'],
        '2026-08-01T05:30:00.000Z',
      );
      expect(
        filter.toQueryParameters()['fechaFin'],
        '2026-08-06T00:00:00.000Z',
      );
    });

    test('copyWith permite limpiar un campo pasando null', () {
      const filter = AuditFilter(entidad: 'Incidencias', accion: 'Triage');

      expect(filter.copyWith(accion: null).accion, isNull);
      expect(filter.copyWith(accion: null).entidad, 'Incidencias');
      expect(filter.copyWith(entidad: 'Usuarios').entidad, 'Usuarios');
    });

    test('isEmpty y activeCount reflejan los filtros aplicados', () {
      expect(const AuditFilter().isEmpty, isTrue);
      expect(const AuditFilter().activeCount, 0);
      expect(
        const AuditFilter(entidad: 'Incidencias', accion: 'Triage').activeCount,
        2,
      );
    });
  });
}
