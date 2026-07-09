class IncidentType {
  const IncidentType({
    required this.id,
    required this.nombre,
    required this.institucionId,
    required this.institucionNombre,
    this.descripcion,
  });

  final int id;
  final String nombre;
  final int institucionId;
  final String institucionNombre;
  final String? descripcion;

  factory IncidentType.fromJson(Map<String, dynamic> json) => IncidentType(
    id: json['id'] as int,
    nombre: json['nombre'] as String? ?? '',
    institucionId: json['institucionId'] as int? ?? 0,
    institucionNombre: json['institucionNombre'] as String? ?? '',
    descripcion: json['descripcion'] as String?,
  );
}

class Jurisdiction {
  const Jurisdiction({
    required this.id,
    required this.nombre,
    required this.nivel,
  });

  final int id;
  final String nombre;
  final String nivel;

  factory Jurisdiction.fromJson(Map<String, dynamic> json) => Jurisdiction(
    id: json['id'] as int,
    nombre: json['nombre'] as String? ?? '',
    nivel: json['nivel'] as String? ?? '',
  );
}

class Institution {
  const Institution({
    required this.id,
    required this.nombre,
    required this.tipoInstitucion,
  });

  final int id;
  final String nombre;
  final String tipoInstitucion;

  factory Institution.fromJson(Map<String, dynamic> json) => Institution(
    id: json['id'] as int,
    nombre: json['nombre'] as String? ?? '',
    tipoInstitucion: json['tipoInstitucion'] as String? ?? '',
  );
}
