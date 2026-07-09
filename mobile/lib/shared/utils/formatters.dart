import 'package:intl/intl.dart';

final _dateTimeFormat = DateFormat('dd/MM/yyyy HH:mm');
final _dateFormat = DateFormat('dd/MM/yyyy');

String formatDateTime(DateTime value) =>
    _dateTimeFormat.format(value.toLocal());

String formatDate(DateTime value) => _dateFormat.format(value.toLocal());
