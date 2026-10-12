import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../core/providers/providers.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/models/service_center.dart';
import '../../../shared/widgets/common_widgets.dart';

// ── Date range options ────────────────────────────────────────────────────────
enum _DateRange { week, month, quarter }

extension _DateRangeExt on _DateRange {
  String get label => switch (this) {
        _DateRange.week => 'Last 7 Days',
        _DateRange.month => 'Last 30 Days',
        _DateRange.quarter => 'Last 90 Days',
      };

  int get days => switch (this) {
        _DateRange.week => 7,
        _DateRange.month => 30,
        _DateRange.quarter => 90,
      };
}

// ── Providers ─────────────────────────────────────────────────────────────────
final _serviceCentersListProvider =
    FutureProvider<List<ServiceCenter>>((ref) async {
  return ref.watch(serviceRepositoryProvider).getAllServiceCenters();
});

// 'all' represents Campus-wide across all centers, or a specific center's id
final _analyticsCenterIdProvider = StateProvider<String>((ref) => 'all');
final _analyticsDateRangeProvider =
    StateProvider<_DateRange>((ref) => _DateRange.month);

final _analyticsProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  final centerId = ref.watch(_analyticsCenterIdProvider);
  final range = ref.watch(_analyticsDateRangeProvider);
  final now = DateTime.now();
  final from = now.subtract(Duration(days: range.days));
  return ref.watch(queueRepositoryProvider).getAnalytics(
        serviceCenterId: centerId == 'all' ? null : centerId,
        fromDate: from,
        toDate: now,
      );
});

// ── Screen ────────────────────────────────────────────────────────────────────
class AdminAnalyticsScreen extends ConsumerWidget {
  const AdminAnalyticsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedCenterId = ref.watch(_analyticsCenterIdProvider);
    final selectedRange = ref.watch(_analyticsDateRangeProvider);
    final centersAsync = ref.watch(_serviceCentersListProvider);

    final centerName = selectedCenterId == 'all'
        ? 'Campus-Wide (All Service Centers)'
        : (centersAsync.valueOrNull
                ?.firstWhere(
                  (c) => c.id == selectedCenterId,
                  orElse: () => ServiceCenter(
                    id: selectedCenterId,
                    name: 'Selected Center',
                    description: '',
                    isActive: true,
                    createdAt: DateTime.now(),
                  ),
                )
                .name ??
            'Selected Center');

    return Scaffold(
      appBar: AppBar(
        title: const Text('Analytics'),
        leading: const BackButton(),
        actions: [
          PopupMenuButton<_DateRange>(
            initialValue: selectedRange,
            tooltip: 'Date range',
            icon: const Icon(Icons.date_range_outlined),
            onSelected: (v) =>
                ref.read(_analyticsDateRangeProvider.notifier).state = v,
            itemBuilder: (_) => _DateRange.values
                .map((r) => PopupMenuItem(
                      value: r,
                      child: Text(r.label),
                    ))
                .toList(),
          ),
        ],
      ),
      body: Column(
        children: [
          _CenterPicker(
            centers: centersAsync,
            selectedId: selectedCenterId,
          ),
          Expanded(
            child: _AnalyticsContent(
              centerName: centerName,
              range: selectedRange,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Center picker ─────────────────────────────────────────────────────────────
class _CenterPicker extends ConsumerWidget {
  final AsyncValue<List<ServiceCenter>> centers;
  final String selectedId;
  const _CenterPicker({required this.centers, required this.selectedId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return centers.when(
      loading: () => const LinearProgressIndicator(color: AppColors.accent),
      error: (_, _) => const SizedBox.shrink(),
      data: (list) {
        final isValid =
            selectedId == 'all' || list.any((c) => c.id == selectedId);
        final currentVal = isValid ? selectedId : 'all';

        return Container(
          margin: const EdgeInsets.all(16),
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.cardBorder),
          ),
          child: DropdownButton<String>(
            value: currentVal,
            isExpanded: true,
            underline: const SizedBox.shrink(),
            dropdownColor: AppColors.surfaceElevated,
            icon: const Icon(Icons.keyboard_arrow_down,
                color: AppColors.accent),
            items: [
              const DropdownMenuItem<String>(
                value: 'all',
                child: Row(
                  children: [
                    Icon(Icons.domain, color: AppColors.accent, size: 20),
                    SizedBox(width: 10),
                    Text(
                      'All Centers (Campus-Wide)',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ),
              ...list.map((c) => DropdownMenuItem<String>(
                    value: c.id,
                    child: Row(
                      children: [
                        const Icon(Icons.storefront_outlined,
                            color: AppColors.textMuted, size: 18),
                        const SizedBox(width: 10),
                        Text(c.name),
                      ],
                    ),
                  )),
            ],
            onChanged: (id) {
              if (id != null) {
                ref.read(_analyticsCenterIdProvider.notifier).state = id;
              }
            },
          ),
        );
      },
    );
  }
}

// ── Analytics content ─────────────────────────────────────────────────────────
class _AnalyticsContent extends ConsumerWidget {
  final String centerName;
  final _DateRange range;
  const _AnalyticsContent({
    required this.centerName,
    required this.range,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final analytics = ref.watch(_analyticsProvider);

    return RefreshIndicator(
      color: AppColors.accent,
      onRefresh: () => ref.refresh(_analyticsProvider.future),
      child: analytics.when(
        loading: () =>
            const AppLoadingWidget(message: 'Computing analytics...'),
        error: (e, _) => AppErrorWidget(
          message: e.toString(),
          onRetry: () => ref.refresh(_analyticsProvider),
        ),
        data: (data) => SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(centerName,
                            style: const TextStyle(
                                fontSize: 18, fontWeight: FontWeight.w700)),
                        Text(range.label,
                            style: const TextStyle(
                                color: AppColors.textMuted, fontSize: 13)),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // ── Summary metrics grid ──────────────────────────────────────
              _MetricsGrid(data: data),
              const SizedBox(height: 20),

              // ── Waiting & service time ────────────────────────────────────
              _WaitTimeSection(data: data),
              const SizedBox(height: 20),

              // ── Rates ─────────────────────────────────────────────────────
              _RateCards(data: data),
              const SizedBox(height: 24),

              // ── Daily bar chart ───────────────────────────────────────────
              _DailyChart(
                dailyTotal: Map<String, int>.from(
                    data['dailyTotal'] as Map? ?? {}),
                dailyCompleted: Map<String, int>.from(
                    data['dailyCompleted'] as Map? ?? {}),
                days: range.days,
              ),
              const SizedBox(height: 24),

              // ── Hourly heatmap ────────────────────────────────────────────
              _HourlyHeatmap(
                  hourlyCount:
                      List<int>.from(data['hourlyCount'] as List? ?? [])),
              const SizedBox(height: 24),

              // ── Per-service breakdown ─────────────────────────────────────
              _PerServiceBreakdown(
                perService: (data['perService'] as Map<String, dynamic>?)
                        ?.map((k, v) =>
                            MapEntry(k, Map<String, dynamic>.from(v as Map))) ??
                    {},
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Summary metrics grid ──────────────────────────────────────────────────────
class _MetricsGrid extends StatelessWidget {
  final Map<String, dynamic> data;
  const _MetricsGrid({required this.data});

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      childAspectRatio: 1.6,
      children: [
        _MetricCard(
          label: 'Total Entries',
          value: '${data['total']}',
          icon: Icons.people_outline,
          color: AppColors.accent,
        ),
        _MetricCard(
          label: 'Completed',
          value: '${data['completed']}',
          icon: Icons.check_circle_outline,
          color: AppColors.completed,
        ),
        _MetricCard(
          label: 'Avg Service',
          value: '${data['avgServiceDurationMinutes']} min',
          icon: Icons.timer_outlined,
          color: AppColors.waiting,
        ),
        _MetricCard(
          label: 'No-Shows',
          value: '${data['noShows']}',
          icon: Icons.person_off_outlined,
          color: AppColors.noShow,
        ),
      ],
    );
  }
}

class _MetricCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _MetricCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Icon(icon, color: color, size: 22),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(value,
                  style: TextStyle(
                      color: color,
                      fontSize: 22,
                      fontWeight: FontWeight.w900)),
              Text(label,
                  style: const TextStyle(
                      color: AppColors.textMuted, fontSize: 11)),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Wait time section ─────────────────────────────────────────────────────────
class _WaitTimeSection extends StatelessWidget {
  final Map<String, dynamic> data;
  const _WaitTimeSection({required this.data});

  @override
  Widget build(BuildContext context) {
    final avgWait = data['avgWaitMinutes'] ?? '0';
    final maxWait = data['maxWaitMinutes'] ?? 0;
    final maxService = data['maxServiceDurationMinutes'] ?? 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Wait & Service Times',
            style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _InfoTile(
                label: 'Avg Wait',
                value: '$avgWait min',
                icon: Icons.hourglass_empty_outlined,
                color: AppColors.called,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _InfoTile(
                label: 'Max Wait',
                value: '$maxWait min',
                icon: Icons.hourglass_full_outlined,
                color: AppColors.noShow,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _InfoTile(
                label: 'Max Service',
                value: '$maxService min',
                icon: Icons.timer_off_outlined,
                color: AppColors.cancelled,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _InfoTile extends StatelessWidget {
  final String label, value;
  final IconData icon;
  final Color color;
  const _InfoTile(
      {required this.label,
      required this.value,
      required this.icon,
      required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(height: 6),
          Text(value,
              style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.w800,
                  fontSize: 15)),
          Text(label,
              style: const TextStyle(
                  color: AppColors.textMuted, fontSize: 10)),
        ],
      ),
    );
  }
}

// ── Rate cards ────────────────────────────────────────────────────────────────
class _RateCards extends StatelessWidget {
  final Map<String, dynamic> data;
  const _RateCards({required this.data});

  @override
  Widget build(BuildContext context) {
    final total = (data['total'] as int? ?? 0);
    final completed = (data['completed'] as int? ?? 0);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Rates',
            style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
        const SizedBox(height: 12),
        _RateRow(
          label: 'Completion Rate',
          value: total > 0
              ? '${(completed / total * 100).toStringAsFixed(1)}%'
              : '0%',
          color: AppColors.completed,
          fraction: total > 0 ? completed / total : 0,
        ),
        const SizedBox(height: 8),
        _RateRow(
          label: 'Cancellation Rate',
          value: '${data['cancellationRate']}%',
          color: AppColors.cancelled,
          fraction: total > 0
              ? (data['cancelled'] as int? ?? 0) / total
              : 0,
        ),
        const SizedBox(height: 8),
        _RateRow(
          label: 'No-Show Rate',
          value: '${data['noShowRate']}%',
          color: AppColors.noShow,
          fraction:
              total > 0 ? (data['noShows'] as int? ?? 0) / total : 0,
        ),
      ],
    );
  }
}

class _RateRow extends StatelessWidget {
  final String label, value;
  final Color color;
  final double fraction;
  const _RateRow(
      {required this.label,
      required this.value,
      required this.color,
      required this.fraction});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surfaceElevated,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(label,
                  style: const TextStyle(color: AppColors.textSecondary)),
              Text(value,
                  style: TextStyle(
                      color: color,
                      fontWeight: FontWeight.w800,
                      fontSize: 16)),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: fraction.clamp(0.0, 1.0),
              backgroundColor: color.withValues(alpha: 0.12),
              valueColor: AlwaysStoppedAnimation(color),
              minHeight: 6,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Daily bar chart ───────────────────────────────────────────────────────────
class _DailyChart extends StatelessWidget {
  final Map<String, int> dailyTotal;
  final Map<String, int> dailyCompleted;
  final int days;
  const _DailyChart(
      {required this.dailyTotal,
      required this.dailyCompleted,
      required this.days});

  @override
  Widget build(BuildContext context) {
    // Build sorted list of dates for the range
    final now = DateTime.now();
    final dates = List.generate(
        days, (i) => now.subtract(Duration(days: days - 1 - i)));

    final barGroups = <BarChartGroupData>[];
    for (var i = 0; i < dates.length; i++) {
      final key = DateFormat('yyyy-MM-dd').format(dates[i]);
      final total = (dailyTotal[key] ?? 0).toDouble();
      final comp = (dailyCompleted[key] ?? 0).toDouble();
      barGroups.add(BarChartGroupData(
        x: i,
        barRods: [
          BarChartRodData(
            toY: total,
            color: AppColors.accent.withValues(alpha: 0.6),
            width: days <= 7 ? 14 : days <= 30 ? 6 : 3,
            borderRadius: BorderRadius.circular(3),
          ),
          BarChartRodData(
            toY: comp,
            color: AppColors.completed,
            width: days <= 7 ? 14 : days <= 30 ? 6 : 3,
            borderRadius: BorderRadius.circular(3),
          ),
        ],
        barsSpace: 2,
      ));
    }

    final maxY = dailyTotal.values.fold<int>(0, (a, b) => a > b ? a : b);

    return _SectionCard(
      title: 'Daily Volume',
      subtitle: 'Cyan = Total  •  Green = Completed',
      child: SizedBox(
        height: 180,
        child: barGroups.isEmpty
            ? const Center(
                child: Text('No data for this period',
                    style: TextStyle(color: AppColors.textMuted)))
            : BarChart(
                BarChartData(
                  maxY: (maxY + 1).toDouble(),
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: false,
                    horizontalInterval: maxY > 4 ? (maxY / 4).ceilToDouble() : 1,
                    getDrawingHorizontalLine: (_) => FlLine(
                        color: AppColors.cardBorder, strokeWidth: 1),
                  ),
                  borderData: FlBorderData(show: false),
                  titlesData: FlTitlesData(
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 28,
                        interval: maxY > 4 ? (maxY / 4).ceilToDouble() : 1,
                        getTitlesWidget: (v, _) => Text(
                          '${v.toInt()}',
                          style: const TextStyle(
                              fontSize: 9, color: AppColors.textMuted),
                        ),
                      ),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: days <= 14,
                        reservedSize: 20,
                        getTitlesWidget: (v, _) {
                          final idx = v.toInt();
                          if (idx < 0 || idx >= dates.length) {
                            return const SizedBox.shrink();
                          }
                          return Text(
                            DateFormat('d').format(dates[idx]),
                            style: const TextStyle(
                                fontSize: 9, color: AppColors.textMuted),
                          );
                        },
                      ),
                    ),
                    topTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false)),
                    rightTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false)),
                  ),
                  barGroups: barGroups,
                  barTouchData: BarTouchData(
                    touchTooltipData: BarTouchTooltipData(
                      getTooltipItem: (group, _, rod, rodIdx) {
                        final date = dates[group.x];
                        final label = rodIdx == 0 ? 'Total' : 'Done';
                        return BarTooltipItem(
                          '${DateFormat('MMM d').format(date)}\n$label: ${rod.toY.toInt()}',
                          const TextStyle(
                              color: Colors.white, fontSize: 11),
                        );
                      },
                    ),
                  ),
                ),
              ),
      ),
    );
  }
}

// ── Hourly heatmap ────────────────────────────────────────────────────────────
class _HourlyHeatmap extends StatelessWidget {
  final List<int> hourlyCount;
  const _HourlyHeatmap({required this.hourlyCount});

  @override
  Widget build(BuildContext context) {
    final maxVal = hourlyCount.isEmpty
        ? 1
        : hourlyCount.reduce((a, b) => a > b ? a : b);

    return _SectionCard(
      title: 'Peak Hours',
      subtitle: 'Entries by hour of day (local time)',
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: List.generate(24, (h) {
              final count = h < hourlyCount.length ? hourlyCount[h] : 0;
              final frac = maxVal > 0 ? count / maxVal : 0.0;
              final isActive = frac > 0.5;
              return Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 1),
                  child: Column(
                    children: [
                      if (count > 0)
                        Text(
                          '$count',
                          style: const TextStyle(
                              fontSize: 7, color: AppColors.textMuted),
                          textAlign: TextAlign.center,
                        ),
                      const SizedBox(height: 2),
                      Container(
                        height: 80 * frac + 4,
                        decoration: BoxDecoration(
                          color: isActive
                              ? AppColors.accent
                              : AppColors.accent.withValues(
                                  alpha: 0.15 + frac * 0.5),
                          borderRadius: BorderRadius.circular(3),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),
          ),
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: ['12a', '6a', '12p', '6p', '11p']
                .map((t) => Text(t,
                    style: const TextStyle(
                        fontSize: 9, color: AppColors.textMuted)))
                .toList(),
          ),
        ],
      ),
    );
  }
}

// ── Per-service breakdown ─────────────────────────────────────────────────────
class _PerServiceBreakdown extends StatelessWidget {
  final Map<String, Map<String, dynamic>> perService;
  const _PerServiceBreakdown({required this.perService});

  @override
  Widget build(BuildContext context) {
    if (perService.isEmpty) return const SizedBox.shrink();

    return _SectionCard(
      title: 'Per-Service Breakdown',
      subtitle: 'Totals per service in this center',
      child: Column(
        children: perService.entries.map((entry) {
          final name = entry.key;
          final s = entry.value;
          final total = (s['total'] as int? ?? 0);
          final completed = (s['completed'] as int? ?? 0);
          final cancelled = (s['cancelled'] as int? ?? 0);
          final noShows = (s['noShows'] as int? ?? 0);
          final compFrac = total > 0 ? completed / total : 0.0;

          return Padding(
            padding: const EdgeInsets.only(bottom: 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(name,
                          style: const TextStyle(
                              fontWeight: FontWeight.w600, fontSize: 13)),
                    ),
                    Text('$total total',
                        style: const TextStyle(
                            color: AppColors.textMuted, fontSize: 12)),
                  ],
                ),
                const SizedBox(height: 6),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: compFrac,
                    backgroundColor:
                        AppColors.completed.withValues(alpha: 0.12),
                    valueColor: const AlwaysStoppedAnimation(
                        AppColors.completed),
                    minHeight: 8,
                  ),
                ),
                const SizedBox(height: 5),
                Row(
                  children: [
                    _Tag('✓ $completed', AppColors.completed),
                    const SizedBox(width: 6),
                    _Tag('✕ $cancelled', AppColors.cancelled),
                    const SizedBox(width: 6),
                    _Tag('⊘ $noShows', AppColors.noShow),
                  ],
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _Tag extends StatelessWidget {
  final String text;
  final Color color;
  const _Tag(this.text, this.color);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(text,
          style:
              TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w600)),
    );
  }
}

// ── Shared section card wrapper ───────────────────────────────────────────────
class _SectionCard extends StatelessWidget {
  final String title, subtitle;
  final Widget child;
  const _SectionCard(
      {required this.title, required this.subtitle, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceElevated,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: const TextStyle(
                  fontWeight: FontWeight.w700, fontSize: 15)),
          Text(subtitle,
              style: const TextStyle(
                  color: AppColors.textMuted, fontSize: 11)),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }
}
