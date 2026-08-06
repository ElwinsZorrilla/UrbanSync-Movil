import 'package:flutter/material.dart';

import '../../../../app/theme.dart';
import '../../domain/audit_entry.dart';

class AuditActionStyle {
  const AuditActionStyle._();

  static IconData icon(AuditActionKind kind) {
    switch (kind) {
      case AuditActionKind.reporte:
        return Icons.add_location_alt_outlined;
      case AuditActionKind.triage:
        return Icons.fact_check_outlined;
      case AuditActionKind.cambioEstado:
        return Icons.swap_horiz;
      case AuditActionKind.evidencia:
        return Icons.photo_camera_outlined;
      case AuditActionKind.ordenTrabajo:
        return Icons.build_outlined;
      case AuditActionKind.usuario:
        return Icons.person_outline;
      case AuditActionKind.seguridad:
        return Icons.lock_outline;
      case AuditActionKind.desconocida:
        return Icons.history;
    }
  }

  static Color color(AuditActionKind kind) {
    switch (kind) {
      case AuditActionKind.reporte:
        return AppColors.primary;
      case AuditActionKind.triage:
        return AppColors.accent;
      case AuditActionKind.cambioEstado:
        return const Color(0xFF7C3AED);
      case AuditActionKind.evidencia:
        return AppColors.secondary;
      case AuditActionKind.ordenTrabajo:
        return AppColors.primary;
      case AuditActionKind.usuario:
        return AppColors.mutedForeground;
      case AuditActionKind.seguridad:
        return AppColors.destructive;
      case AuditActionKind.desconocida:
        return AppColors.mutedForeground;
    }
  }
}
