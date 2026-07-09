import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:latlong2/latlong.dart';

import '../../../app/theme.dart';
import '../../../core/network/api_exception.dart';
import '../../../shared/utils/validators.dart';
import '../../../shared/widgets/app_text_field.dart';
import '../../../shared/widgets/buttons.dart';
import '../data/incidents_repository.dart';
import '../domain/catalog.dart';
import 'incidents_providers.dart';

const _defaultCenter = LatLng(18.4861, -69.9312);

class ReportIncidentPage extends ConsumerStatefulWidget {
  const ReportIncidentPage({super.key});

  @override
  ConsumerState<ReportIncidentPage> createState() => _ReportIncidentPageState();
}

class _ReportIncidentPageState extends ConsumerState<ReportIncidentPage> {
  final _formKey = GlobalKey<FormState>();
  final _mapController = MapController();
  final _descripcionController = TextEditingController();
  final _direccionController = TextEditingController();
  final _referenciaController = TextEditingController();

  int? _tipoId;
  String _prioridad = 'Media';
  LatLng _point = _defaultCenter;
  Jurisdiction? _jurisdiccion;
  String? _photoPath;
  String? _locationNote;
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _initLocation());
  }

  @override
  void dispose() {
    _descripcionController.dispose();
    _direccionController.dispose();
    _referenciaController.dispose();
    super.dispose();
  }

  Future<void> _initLocation() async {
    try {
      if (!await Geolocator.isLocationServiceEnabled()) {
        if (!mounted) return;
        setState(
          () => _locationNote =
              'Activa la ubicación para autodetectar tu posición.',
        );
        await _resolveJurisdiction();
        return;
      }

      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        if (!mounted) return;
        setState(
          () => _locationNote =
              'Permiso de ubicación denegado. Ajusta el pin manualmente.',
        );
        await _resolveJurisdiction();
        return;
      }

      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      );
      if (!mounted) return;
      _updatePoint(
        LatLng(position.latitude, position.longitude),
        moveMap: true,
      );
    } catch (_) {
      if (!mounted) return;
      setState(
        () => _locationNote =
            'No se pudo obtener la ubicación. Ajusta el pin manualmente.',
      );
      await _resolveJurisdiction();
    }
  }

  void _updatePoint(LatLng point, {bool moveMap = false}) {
    setState(() => _point = point);
    if (moveMap) _mapController.move(point, 16);
    _resolveJurisdiction();
  }

  Future<void> _resolveJurisdiction() async {
    try {
      final jurisdiction = await ref
          .read(incidentsRepositoryProvider)
          .resolveJurisdiction(_point.latitude, _point.longitude);
      if (mounted) setState(() => _jurisdiccion = jurisdiction);
    } catch (_) {
      // La jurisdicción se corrige en triage si no se puede resolver.
    }
  }

  Future<void> _pickPhoto() async {
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_camera_outlined),
              title: const Text('Tomar foto'),
              onTap: () => Navigator.pop(context, ImageSource.camera),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: const Text('Elegir de galería'),
              onTap: () => Navigator.pop(context, ImageSource.gallery),
            ),
          ],
        ),
      ),
    );

    if (source == null) return;

    final picked = await ImagePicker().pickImage(
      source: source,
      imageQuality: 70,
      maxWidth: 1600,
    );
    if (!mounted || picked == null) return;
    setState(() => _photoPath = picked.path);
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_tipoId == null) {
      _showError('Selecciona el tipo de incidencia.');
      return;
    }

    setState(() => _submitting = true);
    final repo = ref.read(incidentsRepositoryProvider);
    try {
      final incident = await repo.create(
        tipoIncidenciaId: _tipoId!,
        descripcion: _descripcionController.text.trim(),
        prioridad: _prioridad,
        lat: _point.latitude,
        lng: _point.longitude,
        direccion: _direccionController.text.trim(),
        referencia: _referenciaController.text.trim().isEmpty
            ? null
            : _referenciaController.text.trim(),
        jurisdiccionId: _jurisdiccion?.id,
      );

      if (_photoPath != null) {
        await repo.uploadEvidence(
          incident.id,
          filePath: _photoPath!,
          tipo: 'Foto',
          lat: _point.latitude,
          lng: _point.longitude,
          descripcion: 'Evidencia inicial',
        );
      }

      ref.invalidate(myIncidentsProvider);
      ref.invalidate(allIncidentsProvider);
      ref.invalidate(triageQueueProvider);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Incidencia ${incident.codigoCaso} registrada.'),
          backgroundColor: AppColors.secondary,
        ),
      );
      context.pop();
    } on ApiException catch (error) {
      _showError(error.message);
    } catch (_) {
      _showError('No se pudo registrar la incidencia.');
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: AppColors.destructive),
    );
  }

  @override
  Widget build(BuildContext context) {
    final typesAsync = ref.watch(incidentTypesProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Reportar incidencia')),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _mapCard(),
              const SizedBox(height: 8),
              _jurisdictionBanner(),
              if (_locationNote != null) ...[
                const SizedBox(height: 8),
                Text(
                  _locationNote!,
                  style: const TextStyle(
                    color: AppColors.mutedForeground,
                    fontSize: 12,
                  ),
                ),
              ],
              const SizedBox(height: 16),
              typesAsync.when(
                loading: () => const LinearProgressIndicator(),
                error: (_, __) => const Text(
                  'No se pudieron cargar los tipos de incidencia.',
                ),
                data: (types) => _typeDropdown(types),
              ),
              const SizedBox(height: 16),
              _priorityDropdown(),
              const SizedBox(height: 16),
              AppTextField(
                label: 'Dirección',
                controller: _direccionController,
                prefixIcon: Icons.place_outlined,
                validator: (v) => Validators.required(v, field: 'La dirección'),
              ),
              const SizedBox(height: 16),
              AppTextField(
                label: 'Referencia (opcional)',
                controller: _referenciaController,
                prefixIcon: Icons.signpost_outlined,
              ),
              const SizedBox(height: 16),
              AppTextField(
                label: 'Descripción',
                controller: _descripcionController,
                maxLines: 4,
                validator: (v) =>
                    Validators.required(v, field: 'La descripción'),
              ),
              const SizedBox(height: 16),
              _photoPicker(),
              const SizedBox(height: 24),
              PrimaryButton(
                label: 'Enviar reporte',
                loading: _submitting,
                icon: Icons.send_outlined,
                onPressed: _submit,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _mapCard() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: SizedBox(
        height: 220,
        child: FlutterMap(
          mapController: _mapController,
          options: MapOptions(
            initialCenter: _point,
            initialZoom: 15,
            onTap: (_, latLng) => _updatePoint(latLng),
          ),
          children: [
            TileLayer(
              urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
              userAgentPackageName: 'com.urbansync.urbansync',
            ),
            MarkerLayer(
              markers: [
                Marker(
                  point: _point,
                  width: 44,
                  height: 44,
                  child: const Icon(
                    Icons.location_on,
                    color: AppColors.destructive,
                    size: 44,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _jurisdictionBanner() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.account_balance_outlined,
            size: 18,
            color: AppColors.primary,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              _jurisdiccion == null
                  ? 'Detectando jurisdicción…'
                  : 'Jurisdicción: ${_jurisdiccion!.nombre}',
              style: const TextStyle(
                color: AppColors.primary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _typeDropdown(List<IncidentType> types) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Tipo de incidencia',
          style: Theme.of(context).textTheme.labelLarge,
        ),
        const SizedBox(height: 6),
        DropdownButtonFormField<int>(
          initialValue: _tipoId,
          isExpanded: true,
          hint: const Text('Selecciona un tipo'),
          items: types
              .map((t) => DropdownMenuItem(value: t.id, child: Text(t.nombre)))
              .toList(),
          onChanged: (value) => setState(() => _tipoId = value),
        ),
      ],
    );
  }

  Widget _priorityDropdown() {
    const priorities = ['Baja', 'Media', 'Alta', 'Critica'];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Prioridad', style: Theme.of(context).textTheme.labelLarge),
        const SizedBox(height: 6),
        DropdownButtonFormField<String>(
          initialValue: _prioridad,
          isExpanded: true,
          items: priorities
              .map((p) => DropdownMenuItem(value: p, child: Text(p)))
              .toList(),
          onChanged: (value) => setState(() => _prioridad = value ?? 'Media'),
        ),
      ],
    );
  }

  Widget _photoPicker() {
    return Row(
      children: [
        if (_photoPath != null)
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.file(
              File(_photoPath!),
              width: 64,
              height: 64,
              fit: BoxFit.cover,
            ),
          )
        else
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: AppColors.muted,
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              Icons.image_outlined,
              color: AppColors.mutedForeground,
            ),
          ),
        const SizedBox(width: 12),
        Expanded(
          child: SecondaryButton(
            label: _photoPath == null ? 'Agregar foto' : 'Cambiar foto',
            icon: Icons.add_a_photo_outlined,
            onPressed: _pickPhoto,
          ),
        ),
      ],
    );
  }
}
