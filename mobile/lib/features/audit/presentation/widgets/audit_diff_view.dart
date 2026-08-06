import 'package:flutter/material.dart';

import '../../../../app/theme.dart';
import '../../domain/audit_entry.dart';

class AuditDiffView extends StatelessWidget {
  const AuditDiffView({super.key, required this.cambios});

  final List<AuditChange> cambios;

  @override
  Widget build(BuildContext context) {
    if (cambios.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final cambio in cambios)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  cambio.campo,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.mutedForeground,
                  ),
                ),
                const SizedBox(height: 4),
                Wrap(
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: 8,
                  runSpacing: 4,
                  children: [
                    _Value(
                      text: cambio.antes,
                      color: AppColors.destructive,
                      strikethrough: cambio.antes != null,
                    ),
                    const Icon(
                      Icons.arrow_forward,
                      size: 14,
                      color: AppColors.mutedForeground,
                    ),
                    _Value(text: cambio.despues, color: AppColors.secondary),
                  ],
                ),
              ],
            ),
          ),
      ],
    );
  }
}

class _Value extends StatelessWidget {
  const _Value({
    required this.text,
    required this.color,
    this.strikethrough = false,
  });

  final String? text;
  final Color color;
  final bool strikethrough;

  @override
  Widget build(BuildContext context) {
    final vacio = text == null;
    final resolved = vacio ? AppColors.mutedForeground : color;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: resolved.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: resolved.withValues(alpha: 0.35)),
      ),
      child: Text(
        text ?? '—',
        style: TextStyle(
          fontSize: 12,
          color: resolved,
          fontWeight: FontWeight.w500,
          decoration: strikethrough && !vacio
              ? TextDecoration.lineThrough
              : TextDecoration.none,
        ),
      ),
    );
  }
}
