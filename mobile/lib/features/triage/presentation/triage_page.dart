import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/theme.dart';
import '../../../core/network/api_exception.dart';
import '../../../shared/widgets/app_card.dart';
import '../../../shared/widgets/buttons.dart';
import '../../../shared/widgets/state_views.dart';
import '../../incidents/data/incidents_repository.dart';
import '../../incidents/domain/catalog.dart';
import '../../incidents/domain/incident.dart';
import '../../incidents/presentation/incidents_providers.dart';

const _acciones = <String, String>{
  'asignar': 'Asignar a técnico',
  'derivar': 'Derivar a institución',
  'informacion': 'Solicitar información',
  'rechazar': 'Rechazar',
};

class TriagePage extends ConsumerStatefulWidget {
  const TriagePage({super.key, required this.incidentId});

  final int incidentId;

  @override
  ConsumerState<TriagePage> createState() => _TriagePageState();
}

class _TriagePageState extends ConsumerState<TriagePage> {
  bool _initialized = false;
  bool _submitting = false;

  int? _tipoId;
  String _prioridad = 'Media';
  String _accion = 'asignar';
  int? _jurisdiccionId;

  void _initFrom(Incident incident) {
    if (_initialized) return;
    _initialized = true;
    _tipoId = incident.tipoIncidenciaId;
    _prioridad = incident.prioridad;
    _jurisdiccionId = incident.jurisdiccionId;
  }

  Future<void> _submit() async {
    setState(() => _submitting = true);
    try {
      await ref
          .read(incidentsRepositoryProvider)
          .triage(
            widget.incidentId,
            tipoIncidenciaId: _tipoId,
            prioridad: _prioridad,
            accion: _accion,
            jurisdiccionId: _jurisdiccionId,
          );

      ref.invalidate(triageQueueProvider);
      ref.invalidate(allIncidentsProvider);
      ref.invalidate(incidentDetailProvider(widget.incidentId));

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Análisis registrado.'),
          backgroundColor: AppColors.secondary,
        ),
      );
      context.pop();
    } on ApiException catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(error.message),
            backgroundColor: AppColors.destructive,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final incidentAsync = ref.watch(incidentDetailProvider(widget.incidentId));
    final typesAsync = ref.watch(incidentTypesProvider);
    final jurisdictionsAsync = ref.watch(jurisdictionsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Análisis técnico')),
      body: incidentAsync.when(
        loading: () => const LoadingView(),
        error: (error, _) => ErrorView(
          message: error is ApiException
              ? error.message
              : 'No se pudo cargar la incidencia.',
          onRetry: () =>
              ref.invalidate(incidentDetailProvider(widget.incidentId)),
        ),
        data: (incident) {
          _initFrom(incident);
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              AppCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      incident.codigoCaso,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 6),
                    Text(incident.descripcion),
                    const SizedBox(height: 6),
                    Text(
                      'Dirección: ${incident.direccion}',
                      style: const TextStyle(
                        color: AppColors.mutedForeground,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              typesAsync.when(
                loading: () => const LinearProgressIndicator(),
                error: (_, __) =>
                    const Text('No se pudieron cargar los tipos.'),
                data: (types) => _typeField(types),
              ),
              const SizedBox(height: 16),
              _dropdown<String>(
                label: 'Prioridad',
                value: _prioridad,
                items: const ['Baja', 'Media', 'Alta', 'Critica'],
                itemLabel: (value) => value,
                onChanged: (value) =>
                    setState(() => _prioridad = value ?? 'Media'),
              ),
              const SizedBox(height: 16),
              _dropdown<String>(
                label: 'Acción',
                value: _accion,
                items: _acciones.keys.toList(),
                itemLabel: (value) => _acciones[value] ?? value,
                onChanged: (value) =>
                    setState(() => _accion = value ?? 'asignar'),
              ),
              const SizedBox(height: 16),
              jurisdictionsAsync.when(
                loading: () => const LinearProgressIndicator(),
                error: (_, __) => const SizedBox.shrink(),
                data: (jurisdictions) => _jurisdictionField(jurisdictions),
              ),
              const SizedBox(height: 24),
              PrimaryButton(
                label: 'Guardar análisis',
                loading: _submitting,
                icon: Icons.save_outlined,
                onPressed: _submit,
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _typeField(List<IncidentType> types) {
    final hasValue = types.any((t) => t.id == _tipoId);
    return _fieldWrapper(
      'Tipo de requerimiento',
      DropdownButtonFormField<int>(
        initialValue: hasValue ? _tipoId : null,
        isExpanded: true,
        items: types
            .map((t) => DropdownMenuItem(value: t.id, child: Text(t.nombre)))
            .toList(),
        onChanged: (value) => setState(() => _tipoId = value),
      ),
    );
  }

  Widget _jurisdictionField(List<Jurisdiction> jurisdictions) {
    final hasValue = jurisdictions.any((j) => j.id == _jurisdiccionId);
    return _fieldWrapper(
      'Jurisdicción',
      DropdownButtonFormField<int>(
        initialValue: hasValue ? _jurisdiccionId : null,
        isExpanded: true,
        items: jurisdictions
            .map((j) => DropdownMenuItem(value: j.id, child: Text(j.nombre)))
            .toList(),
        onChanged: (value) => setState(() => _jurisdiccionId = value),
      ),
    );
  }

  Widget _dropdown<T>({
    required String label,
    required T value,
    required List<T> items,
    required String Function(T) itemLabel,
    required ValueChanged<T?> onChanged,
  }) {
    return _fieldWrapper(
      label,
      DropdownButtonFormField<T>(
        initialValue: value,
        isExpanded: true,
        items: items
            .map(
              (item) =>
                  DropdownMenuItem(value: item, child: Text(itemLabel(item))),
            )
            .toList(),
        onChanged: onChanged,
      ),
    );
  }

  Widget _fieldWrapper(String label, Widget field) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: Theme.of(context).textTheme.labelLarge),
        const SizedBox(height: 6),
        field,
      ],
    );
  }
}
