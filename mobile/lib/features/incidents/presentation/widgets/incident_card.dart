import 'package:flutter/material.dart';

import '../../../../app/theme.dart';
import '../../../../shared/utils/formatters.dart';
import '../../../../shared/widgets/app_card.dart';
import '../../../../shared/widgets/status_chip.dart';
import '../../domain/incident.dart';

class IncidentCard extends StatelessWidget {
  const IncidentCard({super.key, required this.incident, this.onTap});

  final Incident incident;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  incident.codigoCaso,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
              StatusChip(label: incident.estado),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            incident.tipoIncidencia,
            style: const TextStyle(
              color: AppColors.primary,
              fontWeight: FontWeight.w600,
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            incident.descripcion,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(color: AppColors.foreground),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              const Icon(
                Icons.place_outlined,
                size: 16,
                color: AppColors.mutedForeground,
              ),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  incident.direccion,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.mutedForeground,
                    fontSize: 12,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              StatusChip(label: incident.prioridad, kind: ChipKind.prioridad),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            formatDateTime(incident.fechaReporte),
            style: const TextStyle(
              color: AppColors.mutedForeground,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }
}
