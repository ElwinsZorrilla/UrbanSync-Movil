import 'dart:math';

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme.dart';
import '../../../core/network/api_exception.dart';
import '../../../shared/widgets/app_card.dart';
import '../../../shared/widgets/state_views.dart';
import '../domain/report_summary.dart';
import 'reports_providers.dart';

class DashboardPage extends ConsumerWidget {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(reportSummaryProvider);

    return async.when(
      loading: () => const LoadingView(),
      error: (error, _) => ErrorView(
        message: error is ApiException
            ? error.message
            : 'No se pudo cargar el resumen.',
        onRetry: () => ref.invalidate(reportSummaryProvider),
      ),
      data: (summary) => RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(reportSummaryProvider);
          await ref.read(reportSummaryProvider.future);
        },
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Row(
              children: [
                _StatTile(
                  label: 'Incidencias',
                  value: summary.total.toString(),
                  color: AppColors.primary,
                ),
                const SizedBox(width: 12),
                _StatTile(
                  label: 'Cerradas',
                  value: _countFor(summary.porEstado, 'Cerrada').toString(),
                  color: AppColors.secondary,
                ),
              ],
            ),
            const SizedBox(height: 20),
            _ChartCard(
              title: 'Incidencias por estado',
              items: summary.porEstado,
            ),
            const SizedBox(height: 16),
            _BreakdownCard(title: 'Por tipo', items: summary.porTipo),
            const SizedBox(height: 16),
            _BreakdownCard(title: 'Por prioridad', items: summary.porPrioridad),
          ],
        ),
      ),
    );
  }

  int _countFor(List<CountItem> items, String key) =>
      items.where((e) => e.clave == key).fold(0, (sum, e) => sum + e.total);
}

class _StatTile extends StatelessWidget {
  const _StatTile({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: AppCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              value,
              style: TextStyle(
                fontSize: 30,
                fontWeight: FontWeight.w700,
                color: color,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: const TextStyle(color: AppColors.mutedForeground),
            ),
          ],
        ),
      ),
    );
  }
}

class _ChartCard extends StatelessWidget {
  const _ChartCard({required this.title, required this.items});

  final String title;
  final List<CountItem> items;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 16),
          if (items.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 24),
              child: Center(
                child: Text(
                  'Sin datos',
                  style: TextStyle(color: AppColors.mutedForeground),
                ),
              ),
            )
          else
            SizedBox(height: 200, child: BarChart(_chartData())),
        ],
      ),
    );
  }

  BarChartData _chartData() {
    final maxValue = items.map((e) => e.total).reduce(max).toDouble();
    final step = max(1, (maxValue / 4).ceil()).toDouble();

    return BarChartData(
      alignment: BarChartAlignment.spaceAround,
      maxY: maxValue + step,
      gridData: const FlGridData(show: true, drawVerticalLine: false),
      borderData: FlBorderData(show: false),
      titlesData: FlTitlesData(
        leftTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            reservedSize: 28,
            interval: step,
          ),
        ),
        rightTitles: const AxisTitles(
          sideTitles: SideTitles(showTitles: false),
        ),
        topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        bottomTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            reservedSize: 34,
            getTitlesWidget: (value, meta) {
              final index = value.toInt();
              if (index < 0 || index >= items.length)
                return const SizedBox.shrink();
              return Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Text(
                  _abbr(items[index].clave),
                  style: const TextStyle(fontSize: 10),
                ),
              );
            },
          ),
        ),
      ),
      barGroups: [
        for (var i = 0; i < items.length; i++)
          BarChartGroupData(
            x: i,
            barRods: [
              BarChartRodData(
                toY: items[i].total.toDouble(),
                color: AppColors.chart[i % AppColors.chart.length],
                width: 18,
                borderRadius: BorderRadius.circular(4),
              ),
            ],
          ),
      ],
    );
  }

  static String _abbr(String value) =>
      value.length <= 8 ? value : '${value.substring(0, 7)}…';
}

class _BreakdownCard extends StatelessWidget {
  const _BreakdownCard({required this.title, required this.items});

  final String title;
  final List<CountItem> items;

  @override
  Widget build(BuildContext context) {
    final total = items.fold<int>(0, (sum, e) => sum + e.total);

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 12),
          if (items.isEmpty)
            const Text(
              'Sin datos',
              style: TextStyle(color: AppColors.mutedForeground),
            )
          else
            for (var i = 0; i < items.length; i++) ...[
              _row(
                items[i],
                total,
                AppColors.chart[i % AppColors.chart.length],
              ),
              if (i != items.length - 1) const SizedBox(height: 12),
            ],
        ],
      ),
    );
  }

  Widget _row(CountItem item, int total, Color color) {
    final fraction = total == 0 ? 0.0 : item.total / total;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(child: Text(item.clave)),
            Text(
              item.total.toString(),
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ],
        ),
        const SizedBox(height: 4),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: fraction,
            minHeight: 8,
            backgroundColor: AppColors.muted,
            valueColor: AlwaysStoppedAnimation<Color>(color),
          ),
        ),
      ],
    );
  }
}
