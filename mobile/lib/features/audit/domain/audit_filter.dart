const Object _unset = Object();

class AuditFilter {
  const AuditFilter({
    this.usuarioId,
    this.entidad,
    this.accion,
    this.desde,
    this.hasta,
  });

  final String? usuarioId;
  final String? entidad;
  final String? accion;
  final DateTime? desde;
  final DateTime? hasta;

  bool get isEmpty =>
      usuarioId == null &&
      entidad == null &&
      accion == null &&
      desde == null &&
      hasta == null;

  bool get isNotEmpty => !isEmpty;

  int get activeCount =>
      [usuarioId, entidad, accion, desde, hasta].where((v) => v != null).length;

  Map<String, dynamic> toQueryParameters() => {
    if (usuarioId != null) 'usuarioId': usuarioId,
    if (entidad != null) 'entidad': entidad,
    if (accion != null) 'accion': accion,
    if (desde != null) 'fechaInicio': desde!.toUtc().toIso8601String(),
    if (hasta != null) 'fechaFin': hasta!.toUtc().toIso8601String(),
  };

  AuditFilter copyWith({
    Object? usuarioId = _unset,
    Object? entidad = _unset,
    Object? accion = _unset,
    Object? desde = _unset,
    Object? hasta = _unset,
  }) => AuditFilter(
    usuarioId: identical(usuarioId, _unset)
        ? this.usuarioId
        : usuarioId as String?,
    entidad: identical(entidad, _unset) ? this.entidad : entidad as String?,
    accion: identical(accion, _unset) ? this.accion : accion as String?,
    desde: identical(desde, _unset) ? this.desde : desde as DateTime?,
    hasta: identical(hasta, _unset) ? this.hasta : hasta as DateTime?,
  );

  @override
  bool operator ==(Object other) =>
      other is AuditFilter &&
      other.usuarioId == usuarioId &&
      other.entidad == entidad &&
      other.accion == accion &&
      other.desde == desde &&
      other.hasta == hasta;

  @override
  int get hashCode => Object.hash(usuarioId, entidad, accion, desde, hasta);
}
