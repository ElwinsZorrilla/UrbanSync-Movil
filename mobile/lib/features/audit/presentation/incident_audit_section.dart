import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_exception.dart';
import '../../../shared/widgets/state_views.dart';
import 'audit_providers.dart';
import 'widgets/audit_timeline.dart';

class IncidentAuditSection extends ConsumerWidget {
  const IncidentAuditSection({super.key, required this.incidentId});

  final int incidentId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(incidentAuditProvider(incidentId));

    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(incidentAuditProvider(incidentId));
        await ref.read(incidentAuditProvider(incidentId).future);
      },
      child: async.when(
        loading: () => const LoadingView(message: 'Cargando auditoría...'),
        error: (error, _) => ListView(
          children: [
            const SizedBox(height: 80),
            ErrorView(
              message: error is ApiException
                  ? error.message
                  : 'No se pudo cargar la auditoría.',
              onRetry: () => ref.invalidate(incidentAuditProvider(incidentId)),
            ),
          ],
        ),
        data: (entries) {
          if (entries.isEmpty) {
            return ListView(
              children: const [
                SizedBox(height: 80),
                EmptyState(
                  title: 'Sin eventos de auditoría',
                  message:
                      'Los cambios sobre esta incidencia aparecerán aquí en '
                      'cuanto ocurran.',
                  icon: Icons.history,
                ),
              ],
            );
          }

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              AuditTimeline(entries: entries),
              const SizedBox(height: 80),
            ],
          );
        },
      ),
    );
  }
}
