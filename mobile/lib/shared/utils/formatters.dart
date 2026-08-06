import 'package:intl/intl.dart';

final _dateTimeFormat = DateFormat('dd/MM/yyyy HH:mm');
final _dateFormat = DateFormat('dd/MM/yyyy');

String formatDateTime(DateTime value) =>
    _dateTimeFormat.format(value.toLocal());

String formatDate(DateTime value) => _dateFormat.format(value.toLocal());

String formatRelative(DateTime value, {DateTime? now}) {
  final diff = (now ?? DateTime.now()).difference(value.toLocal());

  if (diff.isNegative) return 'ahora';
  if (diff.inMinutes < 1) return 'hace unos segundos';
  if (diff.inMinutes < 60) return 'hace ${diff.inMinutes} min';
  if (diff.inHours < 24) {
    return 'hace ${diff.inHours} ${diff.inHours == 1 ? 'hora' : 'horas'}';
  }
  if (diff.inDays < 30) {
    return 'hace ${diff.inDays} ${diff.inDays == 1 ? 'día' : 'días'}';
  }

  final meses = diff.inDays ~/ 30;
  if (meses < 12) return 'hace $meses ${meses == 1 ? 'mes' : 'meses'}';

  final anios = diff.inDays ~/ 365;
  return 'hace $anios ${anios == 1 ? 'año' : 'años'}';
}

String formatDayHeader(DateTime value, {DateTime? now}) {
  final local = value.toLocal();
  final hoy = (now ?? DateTime.now()).toLocal();
  final ayer = hoy.subtract(const Duration(days: 1));

  bool mismoDia(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  if (mismoDia(local, hoy)) return 'Hoy';
  if (mismoDia(local, ayer)) return 'Ayer';
  return formatDate(local);
}
