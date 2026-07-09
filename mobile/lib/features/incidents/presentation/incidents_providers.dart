import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/incidents_repository.dart';
import '../domain/catalog.dart';
import '../domain/incident.dart';

final incidentTypesProvider = FutureProvider<List<IncidentType>>(
  (ref) => ref.read(incidentsRepositoryProvider).incidentTypes(),
);

final jurisdictionsProvider = FutureProvider<List<Jurisdiction>>(
  (ref) => ref.read(incidentsRepositoryProvider).jurisdictions(),
);

final myIncidentsProvider = FutureProvider.autoDispose<List<Incident>>(
  (ref) => ref.read(incidentsRepositoryProvider).list(mine: true),
);

final allIncidentsProvider = FutureProvider.autoDispose<List<Incident>>(
  (ref) => ref.read(incidentsRepositoryProvider).list(),
);

final triageQueueProvider = FutureProvider.autoDispose<List<Incident>>(
  (ref) => ref.read(incidentsRepositoryProvider).list(status: 'Registrada'),
);

final technicianJobsProvider = FutureProvider.autoDispose<List<Incident>>((
  ref,
) async {
  final all = await ref.read(incidentsRepositoryProvider).list();
  return all
      .where((i) => i.estado == 'Asignada' || i.estado == 'EnProceso')
      .toList();
});

final incidentDetailProvider = FutureProvider.autoDispose.family<Incident, int>(
  (ref, id) => ref.read(incidentsRepositoryProvider).getById(id),
);
