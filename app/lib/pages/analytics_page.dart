import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:share_plus/share_plus.dart';
import 'package:dose/services/analytics_service.dart';
import 'package:dose/widgets/dose_card.dart';

class AnalyticsPage extends StatefulWidget {
  const AnalyticsPage({super.key});

  @override
  State<AnalyticsPage> createState() => _AnalyticsPageState();
}

class _AnalyticsPageState extends State<AnalyticsPage>
    with TickerProviderStateMixin {
  late Future<AdherenceSummary> _adherenceFuture;
  late Future<List<MonthlyAdherence>> _monthlyFuture;
  late Future<List<MedicineStockTimeline>> _stockFuture;

  int _touchedPieIndex = -1;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  void _loadData() {
    _adherenceFuture = AnalyticsService.instance.getAdherenceSummary();
    _monthlyFuture = AnalyticsService.instance.getMonthlyAdherence(months: 6);
    _stockFuture = AnalyticsService.instance.getStockTimelines();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _shareReport,
        icon: const Icon(Icons.share),
        label: const Text('Export'),
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          setState(() => _loadData());
        },
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          children: [
            _buildAdherencePieCard(context),
            const SizedBox(height: 16),
            _buildAdherenceTrendCard(context),
            const SizedBox(height: 16),
            _buildStockTimelineCard(context),
            const SizedBox(height: 80),
          ],
        ),
      ),
    );
  }

  Future<void> _shareReport() async {
    final adherence = await _adherenceFuture;
    final monthly = await _monthlyFuture;
    final stock = await _stockFuture;

    final buf = StringBuffer();
    buf.writeln('📋 Dose — Medicine Adherence Report');
    buf.writeln('Generated: ${DateTime.now().toString().substring(0, 16)}');
    buf.writeln();
    buf.writeln('── Adherence Overview ──');
    if (adherence.total > 0) {
      final takenPct = ((adherence.taken / adherence.total) * 100)
          .toStringAsFixed(1);
      final latePct = ((adherence.late / adherence.total) * 100)
          .toStringAsFixed(1);
      final skippedPct = ((adherence.skipped / adherence.total) * 100)
          .toStringAsFixed(1);
      buf.writeln('On Time: ${adherence.taken} ($takenPct%)');
      buf.writeln('Late:    ${adherence.late} ($latePct%)');
      buf.writeln('Skipped: ${adherence.skipped} ($skippedPct%)');
      buf.writeln('Total:   ${adherence.total} doses tracked');
    } else {
      buf.writeln('No data recorded yet.');
    }
    buf.writeln();
    buf.writeln('── Monthly Adherence Trend ──');
    if (monthly.isNotEmpty) {
      for (final m in monthly) {
        buf.writeln('${m.month}: ${m.percent.toStringAsFixed(1)}%');
      }
    } else {
      buf.writeln('No monthly data available.');
    }
    buf.writeln();
    buf.writeln('── Current Stock ──');
    if (stock.isNotEmpty) {
      for (final s in stock) {
        final current = s.points.isNotEmpty ? s.points.last.stock : s.initStock;
        buf.writeln(
          '${s.name}: $current remaining (started with ${s.initStock})',
        );
      }
    } else {
      buf.writeln('No stock data available.');
    }
    buf.writeln();
    buf.writeln('— Sent from Dose app');

    await SharePlus.instance.share(ShareParams(text: buf.toString()));
  }

  Widget _buildAdherencePieCard(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return DoseCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.pie_chart_rounded, color: cs.primary, size: 22),
              const SizedBox(width: 8),
              Text(
                'Adherence Overview',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: cs.onSurface,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          FutureBuilder<AdherenceSummary>(
            future: _adherenceFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const SizedBox(
                  height: 200,
                  child: Center(child: CircularProgressIndicator()),
                );
              }
              final data = snapshot.data;
              if (data == null || data.total == 0) {
                return _buildEmptyState('No intake data recorded yet.');
              }
              return _buildPieChart(data, cs);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildPieChart(AdherenceSummary data, ColorScheme cs) {
    return Column(
      children: [
        SizedBox(
          height: 200,
          child: PieChart(
            PieChartData(
              pieTouchData: PieTouchData(
                touchCallback: (FlTouchEvent event, pieTouchResponse) {
                  setState(() {
                    if (!event.isInterestedForInteractions ||
                        pieTouchResponse == null ||
                        pieTouchResponse.touchedSection == null) {
                      _touchedPieIndex = -1;
                      return;
                    }
                    _touchedPieIndex =
                        pieTouchResponse.touchedSection!.touchedSectionIndex;
                  });
                },
              ),
              borderData: FlBorderData(show: false),
              sectionsSpace: 3,
              centerSpaceRadius: 44,
              sections: _buildPieSections(data, cs),
            ),
            duration: const Duration(milliseconds: 600),
            curve: Curves.easeInOutCubic,
          ),
        ),
        const SizedBox(height: 20),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _buildLegendItem(cs.primary, 'On Time', data.taken, data.total),
            _buildLegendItem(cs.tertiary, 'Late', data.late, data.total),
            _buildLegendItem(cs.error, 'Skipped', data.skipped, data.total),
          ],
        ),
      ],
    );
  }

  List<PieChartSectionData> _buildPieSections(
    AdherenceSummary data,
    ColorScheme cs,
  ) {
    final items = [
      _PieItem(
        value: data.taken.toDouble(),
        color: cs.primary,
        label: 'On Time',
      ),
      _PieItem(value: data.late.toDouble(), color: cs.tertiary, label: 'Late'),
      _PieItem(
        value: data.skipped.toDouble(),
        color: cs.error,
        label: 'Skipped',
      ),
    ];

    return List.generate(items.length, (i) {
      final isTouched = i == _touchedPieIndex;
      final radius = isTouched ? 60.0 : 50.0;
      final fontSize = isTouched ? 16.0 : 12.0;
      final item = items[i];

      return PieChartSectionData(
        color: item.color,
        value: item.value,
        title: item.value > 0
            ? '${((item.value / data.total) * 100).toStringAsFixed(0)}%'
            : '',
        radius: radius,
        titleStyle: TextStyle(
          fontSize: fontSize,
          fontWeight: FontWeight.bold,
          color: cs.surface,
        ),
        badgePositionPercentageOffset: isTouched ? 1.2 : null,
      );
    });
  }

  Widget _buildLegendItem(Color color, String label, int count, int total) {
    final pct = total > 0 ? ((count / total) * 100).toStringAsFixed(1) : '0';
    return Column(
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          '$count ($pct%)',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
      ],
    );
  }

  Widget _buildAdherenceTrendCard(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return DoseCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.show_chart_rounded, color: cs.primary, size: 22),
              const SizedBox(width: 8),
              Text(
                'Adherence Trend',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: cs.onSurface,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            'Last 6 months',
            style: TextStyle(fontSize: 13, color: cs.onSurfaceVariant),
          ),
          const SizedBox(height: 20),
          FutureBuilder<List<MonthlyAdherence>>(
            future: _monthlyFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const SizedBox(
                  height: 200,
                  child: Center(child: CircularProgressIndicator()),
                );
              }
              final data = snapshot.data;
              if (data == null || data.isEmpty) {
                return _buildEmptyState('Not enough data to show trends.');
              }
              return _buildLineChart(data, cs);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildLineChart(List<MonthlyAdherence> data, ColorScheme cs) {
    final monthNames = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];

    final spots = <FlSpot>[];
    final labels = <String>[];
    for (int i = 0; i < data.length; i++) {
      spots.add(FlSpot(i.toDouble(), data[i].percent));
      final parts = data[i].month.split('-');
      if (parts.length == 2) {
        final m = int.tryParse(parts[1]) ?? 1;
        labels.add(monthNames[m - 1]);
      } else {
        labels.add('');
      }
    }

    return SizedBox(
      height: 200,
      child: LineChart(
        LineChartData(
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            horizontalInterval: 25,
            getDrawingHorizontalLine: (value) => FlLine(
              color: cs.outlineVariant.withValues(alpha: 0.5),
              strokeWidth: 1,
              dashArray: [5, 5],
            ),
          ),
          titlesData: FlTitlesData(
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 36,
                interval: 25,
                getTitlesWidget: (value, meta) {
                  return Text(
                    '${value.toInt()}%',
                    style: TextStyle(fontSize: 11, color: cs.onSurfaceVariant),
                  );
                },
              ),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 28,
                interval: 1,
                getTitlesWidget: (value, meta) {
                  final i = value.toInt();
                  if (i < 0 || i >= labels.length) return const SizedBox();
                  return Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      labels[i],
                      style: TextStyle(
                        fontSize: 11,
                        color: cs.onSurfaceVariant,
                      ),
                    ),
                  );
                },
              ),
            ),
            topTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            rightTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
          ),
          borderData: FlBorderData(show: false),
          minY: 0,
          maxY: 100,
          lineTouchData: LineTouchData(
            touchTooltipData: LineTouchTooltipData(
              getTooltipColor: (_) => cs.inverseSurface,
              getTooltipItems: (touchedSpots) {
                return touchedSpots.map((spot) {
                  return LineTooltipItem(
                    '${spot.y.toStringAsFixed(1)}%',
                    TextStyle(
                      color: cs.onInverseSurface,
                      fontWeight: FontWeight.w600,
                    ),
                  );
                }).toList();
              },
            ),
          ),
          lineBarsData: [
            LineChartBarData(
              spots: spots,
              isCurved: true,
              curveSmoothness: 0.35,
              color: cs.primary,
              barWidth: 3,
              isStrokeCapRound: true,
              dotData: FlDotData(
                show: true,
                getDotPainter: (spot, percent, barData, index) {
                  return FlDotCirclePainter(
                    radius: 4,
                    color: cs.primary,
                    strokeWidth: 2,
                    strokeColor: cs.surface,
                  );
                },
              ),
              belowBarData: BarAreaData(
                show: true,
                gradient: LinearGradient(
                  colors: [
                    cs.primary.withValues(alpha: 0.3),
                    cs.primary.withValues(alpha: 0.0),
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
            ),
          ],
        ),
        duration: const Duration(milliseconds: 600),
        curve: Curves.easeInOutCubic,
      ),
    );
  }

  Widget _buildStockTimelineCard(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return DoseCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.inventory_2_rounded, color: cs.primary, size: 22),
              const SizedBox(width: 8),
              Text(
                'Stock Timeline',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: cs.onSurface,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            'Remaining stock over time',
            style: TextStyle(fontSize: 13, color: cs.onSurfaceVariant),
          ),
          const SizedBox(height: 20),
          FutureBuilder<List<MedicineStockTimeline>>(
            future: _stockFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const SizedBox(
                  height: 200,
                  child: Center(child: CircularProgressIndicator()),
                );
              }
              final data = snapshot.data;
              if (data == null || data.isEmpty) {
                return _buildEmptyState('No stock data available.');
              }
              return _buildStockChart(data, cs);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildStockChart(List<MedicineStockTimeline> data, ColorScheme cs) {
    final palette = [
      cs.primary,
      cs.tertiary,
      cs.secondary,
      cs.error,
      cs.primaryContainer,
      cs.tertiaryContainer,
    ];
    DateTime? minDate;
    DateTime? maxDate;
    double maxStock = 0;

    for (final med in data) {
      for (final pt in med.points) {
        if (minDate == null || pt.date.isBefore(minDate)) minDate = pt.date;
        if (maxDate == null || pt.date.isAfter(maxDate)) maxDate = pt.date;
        if (pt.stock > maxStock) maxStock = pt.stock.toDouble();
      }
      if (med.initStock > maxStock) maxStock = med.initStock.toDouble();
    }

    if (minDate == null || maxDate == null) {
      return _buildEmptyState('No stock data available.');
    }

    final totalDays = maxDate.difference(minDate).inDays.toDouble();
    if (totalDays <= 0) {
      return _buildEmptyState('Need more data points for timeline.');
    }
    final lineBars = <LineChartBarData>[];
    for (int i = 0; i < data.length; i++) {
      final med = data[i];
      final color = palette[i % palette.length];
      final spots = med.points.map((pt) {
        final x = pt.date.difference(minDate!).inDays.toDouble();
        return FlSpot(x, pt.stock.toDouble());
      }).toList();

      lineBars.add(
        LineChartBarData(
          spots: spots,
          isCurved: true,
          curveSmoothness: 0.2,
          color: color,
          barWidth: 2.5,
          isStrokeCapRound: true,
          dotData: FlDotData(
            show: true,
            getDotPainter: (spot, percent, barData, index) {
              return FlDotCirclePainter(
                radius: 3,
                color: color,
                strokeWidth: 1.5,
                strokeColor: cs.surface,
              );
            },
          ),
          belowBarData: BarAreaData(show: false),
        ),
      );
    }
    final interval = totalDays > 5 ? (totalDays / 5).ceilToDouble() : 1.0;

    return Column(
      children: [
        SizedBox(
          height: 200,
          child: LineChart(
            LineChartData(
              gridData: FlGridData(
                show: true,
                drawVerticalLine: false,
                horizontalInterval: (maxStock / 4).ceilToDouble().clamp(
                  1,
                  double.infinity,
                ),
                getDrawingHorizontalLine: (value) => FlLine(
                  color: cs.outlineVariant.withValues(alpha: 0.5),
                  strokeWidth: 1,
                  dashArray: [5, 5],
                ),
              ),
              titlesData: FlTitlesData(
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 36,
                    interval: (maxStock / 4).ceilToDouble().clamp(
                      1,
                      double.infinity,
                    ),
                    getTitlesWidget: (value, meta) {
                      return Text(
                        value.toInt().toString(),
                        style: TextStyle(
                          fontSize: 11,
                          color: cs.onSurfaceVariant,
                        ),
                      );
                    },
                  ),
                ),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 28,
                    interval: interval,
                    getTitlesWidget: (value, meta) {
                      final d = minDate!.add(Duration(days: value.toInt()));
                      return Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Text(
                          '${d.day}/${d.month}',
                          style: TextStyle(
                            fontSize: 10,
                            color: cs.onSurfaceVariant,
                          ),
                        ),
                      );
                    },
                  ),
                ),
                topTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
                rightTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
              ),
              borderData: FlBorderData(show: false),
              minY: 0,
              maxY: maxStock + 2,
              maxX: totalDays,
              lineTouchData: LineTouchData(
                touchTooltipData: LineTouchTooltipData(
                  getTooltipColor: (_) => cs.inverseSurface,
                  getTooltipItems: (touchedSpots) {
                    return touchedSpots.map((spot) {
                      final medIndex = lineBars.indexOf(spot.bar);
                      final name = medIndex >= 0 && medIndex < data.length
                          ? data[medIndex].name
                          : '';
                      return LineTooltipItem(
                        '$name: ${spot.y.toInt()}',
                        TextStyle(
                          color: cs.onInverseSurface,
                          fontWeight: FontWeight.w600,
                          fontSize: 12,
                        ),
                      );
                    }).toList();
                  },
                ),
              ),
              lineBarsData: lineBars,
            ),
            duration: const Duration(milliseconds: 600),
            curve: Curves.easeInOutCubic,
          ),
        ),
        const SizedBox(height: 16),
        Wrap(
          spacing: 16,
          runSpacing: 8,
          children: List.generate(data.length, (i) {
            final color = palette[i % palette.length];
            return Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  data[i].name,
                  style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant),
                ),
              ],
            );
          }),
        ),
      ],
    );
  }

  Widget _buildEmptyState(String message) {
    final cs = Theme.of(context).colorScheme;
    return SizedBox(
      height: 120,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.bar_chart_rounded, size: 40, color: cs.outlineVariant),
            const SizedBox(height: 8),
            Text(
              message,
              style: TextStyle(fontSize: 14, color: cs.onSurfaceVariant),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _PieItem {
  final double value;
  final Color color;
  final String label;

  _PieItem({required this.value, required this.color, required this.label});
}
