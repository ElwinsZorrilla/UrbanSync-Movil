class Evidence {
  const Evidence({
    required this.id,
    required this.tipoEvidencia,
    required this.url,
    required this.fechaSubida,
    required this.usuarioSube,
    this.descripcion,
    this.latitud,
    this.longitud,
  });

  final int id;
  final String tipoEvidencia;
  final String url;
  final DateTime fechaSubida;
  final String usuarioSube;
  final String? descripcion;
  final double? latitud;
  final double? longitud;

  factory Evidence.fromJson(Map<String, dynamic> json) => Evidence(
    id: json['id'] as int,
    tipoEvidencia: json['tipoEvidencia'] as String? ?? '',
    url: json['url'] as String? ?? '',
    fechaSubida: DateTime.parse(json['fechaSubida'] as String),
    usuarioSube: json['usuarioSube'] as String? ?? '',
    descripcion: json['descripcion'] as String?,
    latitud: (json['latitud'] as num?)?.toDouble(),
    longitud: (json['longitud'] as num?)?.toDouble(),
  );
}

class Incident {
  const Incident({
    required this.id,
    required this.codigoCaso,
    required this.estado,
    required this.prioridad,
    required this.descripcion,
    required this.tipoIncidenciaId,
    required this.tipoIncidencia,
    required this.jurisdiccionId,
    required this.jurisdiccion,
    required this.direccion,
    required this.usuarioReporta,
    required this.fechaReporte,
    this.institucionAsignadaId,
    this.institucionAsignada,
    this.referencia,
    this.latitud,
    this.longitud,
    this.fechaAsignacion,
    this.fechaCierre,
    this.evidencias = const [],
  });

  final int id;
  final String codigoCaso;
  final String estado;
  final String prioridad;
  final String descripcion;
  final int tipoIncidenciaId;
  final String tipoIncidencia;
  final int jurisdiccionId;
  final String jurisdiccion;
  final String direccion;
  final String usuarioReporta;
  final DateTime fechaReporte;
  final int? institucionAsignadaId;
  final String? institucionAsignada;
  final String? referencia;
  final double? latitud;
  final double? longitud;
  final DateTime? fechaAsignacion;
  final DateTime? fechaCierre;
  final List<Evidence> evidencias;

  factory Incident.fromJson(Map<String, dynamic> json) => Incident(
    id: json['id'] as int,
    codigoCaso: json['codigoCaso'] as String? ?? '',
    estado: json['estado'] as String? ?? '',
    prioridad: json['prioridad'] as String? ?? '',
    descripcion: json['descripcion'] as String? ?? '',
    tipoIncidenciaId: json['tipoIncidenciaId'] as int? ?? 0,
    tipoIncidencia: json['tipoIncidencia'] as String? ?? '',
    jurisdiccionId: json['jurisdiccionId'] as int? ?? 0,
    jurisdiccion: json['jurisdiccion'] as String? ?? '',
    direccion: json['direccion'] as String? ?? '',
    usuarioReporta: json['usuarioReporta'] as String? ?? '',
    fechaReporte: DateTime.parse(json['fechaReporte'] as String),
    institucionAsignadaId: json['institucionAsignadaId'] as int?,
    institucionAsignada: json['institucionAsignada'] as String?,
    referencia: json['referencia'] as String?,
    latitud: (json['latitud'] as num?)?.toDouble(),
    longitud: (json['longitud'] as num?)?.toDouble(),
    fechaAsignacion: json['fechaAsignacion'] == null
        ? null
        : DateTime.parse(json['fechaAsignacion'] as String),
    fechaCierre: json['fechaCierre'] == null
        ? null
        : DateTime.parse(json['fechaCierre'] as String),
    evidencias:
        (json['evidencias'] as List<dynamic>?)
            ?.map((e) => Evidence.fromJson(e as Map<String, dynamic>))
            .toList() ??
        const [],
  );
}
