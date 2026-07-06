import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../state/stats_provider.dart';
import '../../utils/formatters.dart';
import '../../widgets/section_card.dart';

class StatsScreen extends StatefulWidget {
  const StatsScreen({super.key});

  @override
  State<StatsScreen> createState() => _StatsScreenState();
}

class _StatsScreenState extends State<StatsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => context.read<StatsProvider>().load());
  }

  @override
  Widget build(BuildContext context) {
    final stats = context.watch<StatsProvider>();

    return Scaffold(
      appBar: AppBar(title: const Text('Thống kê')),
      body: stats.loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                SegmentedButton<StatsPeriod>(
                  segments: const [
                    ButtonSegment(value: StatsPeriod.week, label: Text('Tuần')),
                    ButtonSegment(value: StatsPeriod.month, label: Text('Tháng')),
                    ButtonSegment(value: StatsPeriod.year, label: Text('Năm')),
                  ],
                  selected: {stats.period},
                  onSelectionChanged: (s) => stats.setPeriod(s.first),
                ),
                const SizedBox(height: 16),
                SectionCard(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _OverviewStat(label: 'Tổng km', value: stats.stats.totalKm.toStringAsFixed(1)),
                      _OverviewStat(
                          label: 'Tổng thời gian', value: Formatters.duration(stats.stats.totalDurationSeconds)),
                      _OverviewStat(label: 'Số buổi', value: '${stats.stats.runCount}'),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                SectionCard(
                  child: Row(
                    children: [
                      Icon(
                        stats.comparisonPercent >= 0 ? Icons.trending_up : Icons.trending_down,
                        color: stats.comparisonPercent >= 0 ? Colors.green : Colors.red,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'So với kỳ trước: ${stats.comparisonPercent >= 0 ? '+' : ''}${stats.comparisonPercent.toStringAsFixed(0)}%',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: stats.comparisonPercent >= 0 ? Colors.green : Colors.red,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                Text('Quãng đường theo ngày', style: Theme.of(context).textTheme.titleSmall),
                const SizedBox(height: 12),
                SizedBox(height: 180, child: _DailyLineChart(stats: stats)),
                if (stats.period == StatsPeriod.month) ...[
                  const SizedBox(height: 24),
                  Text('So sánh km theo tuần', style: Theme.of(context).textTheme.titleSmall),
                  const SizedBox(height: 12),
                  SizedBox(height: 160, child: _WeeklyBarChart(weeklyTotals: stats.weeklyTotalsInMonth)),
                ],
                const SizedBox(height: 24),
                Text('Kỷ lục cá nhân', style: Theme.of(context).textTheme.titleSmall),
                const SizedBox(height: 12),
                SectionCard(
                  child: Column(
                    children: [
                      _RecordRow(
                        icon: Icons.speed,
                        label: 'Pace nhanh nhất',
                        value: stats.bestPace != null ? Formatters.pace(stats.bestPace!) : '--',
                      ),
                      const Divider(height: 24),
                      _RecordRow(
                        icon: Icons.straighten,
                        label: 'Quãng đường dài nhất',
                        value: stats.longestByDistance != null
                            ? Formatters.distanceKm(stats.longestByDistance!.distanceKm)
                            : '--',
                      ),
                      const Divider(height: 24),
                      _RecordRow(
                        icon: Icons.timer_outlined,
                        label: 'Buổi chạy dài nhất',
                        value: stats.longestByDuration != null
                            ? Formatters.duration(stats.longestByDuration!.durationSeconds)
                            : '--',
                      ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }
}

class _OverviewStat extends StatelessWidget {
  final String label;
  final String value;
  const _OverviewStat({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(value, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
        Text(label, style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant, fontSize: 12)),
      ],
    );
  }
}

class _RecordRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  const _RecordRow({required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Row(
      children: [
        Icon(icon, color: scheme.primary),
        const SizedBox(width: 12),
        Expanded(child: Text(label)),
        Text(value, style: const TextStyle(fontWeight: FontWeight.w700)),
      ],
    );
  }
}

class _DailyLineChart extends StatelessWidget {
  final StatsProvider stats;
  const _DailyLineChart({required this.stats});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final fmt = DateFormat('yyyy-MM-dd');
    final entries = stats.dailyDistance.entries.toList()..sort((a, b) => a.key.compareTo(b.key));

    if (entries.isEmpty) {
      return Center(child: Text('Chưa có dữ liệu', style: TextStyle(color: scheme.onSurfaceVariant)));
    }

    final spots = <FlSpot>[
      for (var i = 0; i < entries.length; i++) FlSpot(i.toDouble(), entries[i].value),
    ];

    return LineChart(
      LineChartData(
        gridData: const FlGridData(show: false),
        borderData: FlBorderData(show: false),
        titlesData: FlTitlesData(
          leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              interval: (entries.length / 5).clamp(1, entries.length).toDouble(),
              getTitlesWidget: (value, meta) {
                final idx = value.toInt();
                if (idx < 0 || idx >= entries.length) return const SizedBox.shrink();
                final date = fmt.parse(entries[idx].key);
                return Text(DateFormat('d/M').format(date), style: const TextStyle(fontSize: 10));
              },
            ),
          ),
        ),
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: true,
            color: scheme.primary,
            barWidth: 3,
            dotData: const FlDotData(show: false),
            belowBarData: BarAreaData(show: true, color: scheme.primary.withValues(alpha: 0.15)),
          ),
        ],
      ),
    );
  }
}

class _WeeklyBarChart extends StatelessWidget {
  final List<double> weeklyTotals;
  const _WeeklyBarChart({required this.weeklyTotals});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return BarChart(
      BarChartData(
        gridData: const FlGridData(show: false),
        borderData: FlBorderData(show: false),
        titlesData: FlTitlesData(
          leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) => Text('Tuần ${value.toInt() + 1}', style: const TextStyle(fontSize: 10)),
            ),
          ),
        ),
        barGroups: [
          for (var i = 0; i < weeklyTotals.length; i++)
            BarChartGroupData(x: i, barRods: [
              BarChartRodData(toY: weeklyTotals[i], color: scheme.secondary, width: 22),
            ]),
        ],
      ),
    );
  }
}
