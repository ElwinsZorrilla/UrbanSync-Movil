import 'package:flutter/material.dart';

import '../../app/theme.dart';

class StatusChip extends StatelessWidget {
  const StatusChip({
    super.key,
    required this.label,
    this.kind = ChipKind.estado,
  });

  final String label;
  final ChipKind kind;

  @override
  Widget build(BuildContext context) {
    final color = _colorFor(label, kind);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w600,
          fontSize: 12,
        ),
      ),
    );
  }

  static Color _colorFor(String value, ChipKind kind) {
    if (kind == ChipKind.prioridad) {
      switch (value) {
        case 'Critica':
          return AppColors.destructive;
        case 'Alta':
          return const Color(0xFFE07A00);
        case 'Baja':
          return AppColors.secondary;
        default:
          return AppColors.primary;
      }
    }

    switch (value) {
      case 'Registrada':
        return AppColors.mutedForeground;
      case 'EnAnalisis':
        return AppColors.accent;
      case 'Asignada':
        return AppColors.primary;
      case 'EnProceso':
        return const Color(0xFF7C3AED);
      case 'Cerrada':
        return AppColors.secondary;
      case 'Rechazada':
        return AppColors.destructive;
      default:
        return AppColors.mutedForeground;
    }
  }
}

enum ChipKind { estado, prioridad }
