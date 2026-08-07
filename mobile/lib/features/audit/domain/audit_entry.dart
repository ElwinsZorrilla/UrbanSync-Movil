const String entidadIncidencias = 'Incidencias';

enum AuditActionKind {
  reporte,
  triage,
  cambioEstado,
  evidencia,
  ordenTrabajo,
  usuario,
  seguridad,
  desconocida;

  static AuditActionKind fromApi(String raw) {
    switch (raw.trim().toLowerCase()) {
      case 'reporte de incidencia':
        return AuditActionKind.reporte;
      case 'triage':
        return AuditActionKind.triage;
      case 'cambio de estado':
        return AuditActionKind.cambioEstado;
      case 'evidencia':
        return AuditActionKind.evidencia;
      case 'orden de trabajo':
        return AuditActionKind.ordenTrabajo;
      case 'creación de usuario':
      case 'cambio de estado de usuario':
        return AuditActionKind.usuario;
      case 'cambio de contraseña':
        return AuditActionKind.seguridad;
      default:
        return AuditActionKind.desconocida;
    }
  }
}

class AuditChange {
  const AuditChange({required this.campo, this.antes, this.despues});

  final String campo;
  final String? antes;
  final String? despues;

  static const String _sinValor = '—';

  /// Extrae los cambios del texto libre `detalle`, que el backend y la app
  /// escriben con la convención `Campo: antes → después`, varios separados
  /// por `;`. Un valor `—` representa la ausencia de dato.
  static List<AuditChange> parse(String? detalle) {
    if (detalle == null || detalle.isEmpty) return const [];

    final changes = <AuditChange>[];

    for (final segment in detalle.split(';')) {
      final arrow = segment.indexOf('→');
      if (arrow < 0) continue;

      final left = segment.substring(0, arrow);
      final right = segment.substring(arrow + 1).trim();

      final colon = left.lastIndexOf(':');
      if (colon < 0) continue;

      final campo = _lastSentence(left.substring(0, colon));
      if (campo.isEmpty) continue;

      changes.add(
        AuditChange(
          campo: campo,
          antes: _value(left.substring(colon + 1)),
          despues: _value(right),
        ),
      );
    }

    return changes;
  }

  static String _lastSentence(String value) {
    final dot = value.lastIndexOf('. ');
    return (dot < 0 ? value : value.substring(dot + 2)).trim();
  }

  static String? _value(String raw) {
    final trimmed = raw.trim();
    if (trimmed.isEmpty || trimmed == _sinValor) return null;
    return trimmed;
  }
}

class AuditEntry {
  const AuditEntry({
    required this.id,
    required this.accion,
    required this.fechaHora,
    this.usuarioId,
    this.nombreUsuario,
    this.entidad,
    this.entidadId,
    this.detalle,
    this.ipOrigen,
  });

  final int id;
  final String accion;
  final DateTime fechaHora;
  final String? usuarioId;
  final String? nombreUsuario;
  final String? entidad;
  final int? entidadId;
  final String? detalle;
  final String? ipOrigen;

  AuditActionKind get kind => AuditActionKind.fromApi(accion);

  List<AuditChange> get cambios => AuditChange.parse(detalle);

  bool get tieneCambios => cambios.isNotEmpty;

  bool get esDeIncidencia => entidad == entidadIncidencias && entidadId != null;

  /// `usuarioId` llega como entero en unas implementaciones del API y como
  /// GUID en otras, así que se normaliza a texto.
  factory AuditEntry.fromJson(Map<String, dynamic> json) => AuditEntry(
    id: (json['id'] as num).toInt(),
    accion: json['accion'] as String? ?? '',
    fechaHora: DateTime.parse(json['fechaHora'] as String),
    usuarioId: json['usuarioId']?.toString(),
    nombreUsuario: json['nombreUsuario'] as String?,
    entidad: json['entidad'] as String?,
    entidadId: (json['entidadId'] as num?)?.toInt(),
    detalle: json['detalle'] as String?,
    ipOrigen: json['ipOrigen'] as String?,
  );
}
