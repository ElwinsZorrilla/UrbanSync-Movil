import 'package:flutter/material.dart';

import '../../../../app/theme.dart';
import '../../../../shared/utils/formatters.dart';
import '../../domain/audit_entry.dart';
import 'audit_action_style.dart';
import 'audit_diff_view.dart';

class AuditTimeline extends StatelessWidget {
  const AuditTimeline({
    super.key,
    required this.entries,
    this.shrinkWrap = true,
  });

  final List<AuditEntry> entries;
  final bool shrinkWrap;

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      shrinkWrap: shrinkWrap,
      physics: shrinkWrap ? const NeverScrollableScrollPhysics() : null,
      padding: EdgeInsets.zero,
      itemCount: entries.length,
      itemBuilder: (context, index) => AuditTimelineTile(
        entry: entries[index],
        isLast: index == entries.length - 1,
      ),
    );
  }
}

class AuditTimelineTile extends StatefulWidget {
  const AuditTimelineTile({
    super.key,
    required this.entry,
    this.isLast = false,
  });

  final AuditEntry entry;
  final bool isLast;

  @override
  State<AuditTimelineTile> createState() => _AuditTimelineTileState();
}

class _AuditTimelineTileState extends State<AuditTimelineTile> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final entry = widget.entry;
    final color = AuditActionStyle.color(entry.kind);
    final cambios = entry.cambios;

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                  border: Border.all(color: color.withValues(alpha: 0.35)),
                ),
                child: Icon(
                  AuditActionStyle.icon(entry.kind),
                  size: 17,
                  color: color,
                ),
              ),
              if (!widget.isLast)
                Expanded(child: Container(width: 2, color: AppColors.muted)),
            ],
          ),
          const SizedBox(width: 12),
          Expanded(
            child: InkWell(
              onTap: cambios.isEmpty
                  ? null
                  : () => setState(() => _expanded = !_expanded),
              borderRadius: BorderRadius.circular(8),
              child: Padding(
                padding: EdgeInsets.only(
                  bottom: widget.isLast ? 0 : 20,
                  right: 4,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            entry.accion,
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                            ),
                          ),
                        ),
                        if (cambios.isNotEmpty)
                          Icon(
                            _expanded ? Icons.expand_less : Icons.expand_more,
                            size: 18,
                            color: AppColors.mutedForeground,
                          ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${entry.nombreUsuario ?? 'Sistema'} · '
                      '${formatRelative(entry.fechaHora)}',
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.mutedForeground,
                      ),
                    ),
                    if (entry.detalle != null && entry.detalle!.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        entry.detalle!,
                        style: const TextStyle(fontSize: 13),
                      ),
                    ],
                    if (_expanded) ...[
                      AuditDiffView(cambios: cambios),
                      const SizedBox(height: 6),
                      Text(
                        formatDateTime(entry.fechaHora),
                        style: const TextStyle(
                          fontSize: 11,
                          color: AppColors.mutedForeground,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
