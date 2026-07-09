import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/network/api_exception.dart';
import '../../../../shared/widgets/state_views.dart';
import '../../domain/incident.dart';
import 'incident_card.dart';

class IncidentListSection extends ConsumerWidget {
  const IncidentListSection({
    super.key,
    required this.provider,
    required this.emptyTitle,
    this.emptyMessage,
    this.routePrefix = '/incidents',
  });

  final FutureProvider<List<Incident>> provider;
  final String emptyTitle;
  final String? emptyMessage;
  final String routePrefix;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(provider);

    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(provider);
        await ref.read(provider.future);
      },
      child: async.when(
        loading: () => const _Filler(child: LoadingView()),
        error: (error, _) => _Filler(
          child: ErrorView(
            message: error is ApiException
                ? error.message
                : 'No se pudo cargar la información.',
            onRetry: () => ref.invalidate(provider),
          ),
        ),
        data: (items) {
          if (items.isEmpty) {
            return _Filler(
              child: EmptyState(title: emptyTitle, message: emptyMessage),
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: items.length,
            itemBuilder: (context, index) {
              final incident = items[index];
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: IncidentCard(
                  incident: incident,
                  onTap: () => context.push('$routePrefix/${incident.id}'),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class _Filler extends StatelessWidget {
  const _Filler({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) => SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: SizedBox(height: constraints.maxHeight, child: child),
      ),
    );
  }
}
