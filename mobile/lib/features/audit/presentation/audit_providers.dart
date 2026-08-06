import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/audit_repository.dart';
import '../domain/audit_entry.dart';
import '../domain/audit_filter.dart';

final auditFilterProvider = NotifierProvider<AuditFilterNotifier, AuditFilter>(
  AuditFilterNotifier.new,
);

class AuditFilterNotifier extends Notifier<AuditFilter> {
  @override
  AuditFilter build() => const AuditFilter();

  void apply(AuditFilter filter) => state = filter;

  void clear() => state = const AuditFilter();
}

final auditLogProvider = FutureProvider.autoDispose<List<AuditEntry>>((ref) {
  final filter = ref.watch(auditFilterProvider);
  return ref.read(auditRepositoryProvider).list(filter);
});

final incidentAuditProvider = FutureProvider.autoDispose
    .family<List<AuditEntry>, int>(
      (ref, incidentId) =>
          ref.read(auditRepositoryProvider).forIncident(incidentId),
    );

final auditEntryProvider = FutureProvider.autoDispose.family<AuditEntry, int>(
  (ref, id) => ref.read(auditRepositoryProvider).getById(id),
);
