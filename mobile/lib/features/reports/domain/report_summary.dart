class CountItem {
  const CountItem({required this.clave, required this.total});

  final String clave;
  final int total;

  factory CountItem.fromJson(Map<String, dynamic> json) => CountItem(
    clave: json['clave'] as String? ?? '',
    total: json['total'] as int? ?? 0,
  );
}

class ReportSummary {
  const ReportSummary({
    required this.total,
    required this.porEstado,
    required this.porTipo,
    required this.porPrioridad,
    required this.porJurisdiccion,
  });

  final int total;
  final List<CountItem> porEstado;
  final List<CountItem> porTipo;
  final List<CountItem> porPrioridad;
  final List<CountItem> porJurisdiccion;

  static List<CountItem> _list(dynamic raw) =>
      (raw as List<dynamic>?)
          ?.map((e) => CountItem.fromJson(e as Map<String, dynamic>))
          .toList() ??
      const [];

  factory ReportSummary.fromJson(Map<String, dynamic> json) => ReportSummary(
    total: json['total'] as int? ?? 0,
    porEstado: _list(json['porEstado']),
    porTipo: _list(json['porTipo']),
    porPrioridad: _list(json['porPrioridad']),
    porJurisdiccion: _list(json['porJurisdiccion']),
  );
}
