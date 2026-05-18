import 'package:fl_chart/fl_chart.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../config/app_colors.dart';
import '../../../config/app_theme.dart';

const _kDbUrl =
    'https://doan-hotronuoiong-default-rtdb.asia-southeast1.firebasedatabase.app';

enum _Range { d7, d30, d90 }

extension on _Range {
  int get days => switch (this) {
        _Range.d7 => 7,
        _Range.d30 => 30,
        _Range.d90 => 90,
      };
  String get label => switch (this) {
        _Range.d7 => '7 ngày',
        _Range.d30 => '30 ngày',
        _Range.d90 => '90 ngày',
      };
}

class _AlertEvent {
  final DateTime at;
  final String hive;
  final int count;
  final double confidence;
  _AlertEvent({
    required this.at,
    required this.hive,
    required this.count,
    required this.confidence,
  });
}

class InsightsScreen extends StatefulWidget {
  const InsightsScreen({super.key});

  @override
  State<InsightsScreen> createState() => _InsightsScreenState();
}

class _InsightsScreenState extends State<InsightsScreen> {
  _Range _range = _Range.d7;

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: user == null
          ? const Center(child: Text('Chưa đăng nhập'))
          : StreamBuilder<DatabaseEvent>(
              stream: FirebaseDatabase.instanceFor(
                app: Firebase.app(),
                databaseURL: _kDbUrl,
              ).ref('user_sos_alerts/${user.uid}').onValue,
              builder: (context, snap) {
                final all = _parse(snap.data?.snapshot.value);
                final cutoff = DateTime.now()
                    .subtract(Duration(days: _range.days));
                final inRange =
                    all.where((e) => e.at.isAfter(cutoff)).toList();

                return SafeArea(
                  bottom: false,
                  child: CustomScrollView(
                    physics: const BouncingScrollPhysics(),
                    slivers: [
                      const SliverToBoxAdapter(child: _Header()),
                      SliverToBoxAdapter(
                        child: _RangeBar(
                          selected: _range,
                          onChanged: (r) => setState(() => _range = r),
                        ),
                      ),
                      const SliverToBoxAdapter(child: SizedBox(height: 16)),
                      if (snap.connectionState == ConnectionState.waiting &&
                          all.isEmpty)
                        const SliverToBoxAdapter(
                          child: Padding(
                            padding: EdgeInsets.all(48),
                            child: Center(
                                child: CircularProgressIndicator()),
                          ),
                        )
                      else if (inRange.isEmpty)
                        const SliverToBoxAdapter(
                            child: Padding(
                                padding: EdgeInsets.fromLTRB(20, 24, 20, 0),
                                child: _Empty()))
                      else ...[
                        SliverToBoxAdapter(
                          child: Padding(
                            padding:
                                const EdgeInsets.fromLTRB(20, 0, 20, 16),
                            child: _KpiGrid(
                              events: inRange,
                              days: _range.days,
                            ),
                          ),
                        ),
                        SliverToBoxAdapter(
                          child: Padding(
                            padding:
                                const EdgeInsets.fromLTRB(20, 0, 20, 16),
                            child: _DailyChart(
                              events: inRange,
                              days: _range.days,
                            ),
                          ),
                        ),
                        SliverToBoxAdapter(
                          child: Padding(
                            padding:
                                const EdgeInsets.fromLTRB(20, 0, 20, 16),
                            child: _TopHives(events: inRange),
                          ),
                        ),
                        SliverToBoxAdapter(
                          child: Padding(
                            padding:
                                const EdgeInsets.fromLTRB(20, 0, 20, 24),
                            child: _Insight(
                              events: inRange,
                              days: _range.days,
                            ),
                          ),
                        ),
                      ],
                      const SliverToBoxAdapter(child: SizedBox(height: 80)),
                    ],
                  ),
                );
              },
            ),
    );
  }

  // ── data parse ────────────────────────────────────────────────────────────
  List<_AlertEvent> _parse(dynamic raw) {
    if (raw is! Map) return const [];
    final out = <_AlertEvent>[];
    for (final v in raw.values) {
      if (v is! Map) continue;
      final ts = v['created_at'];
      if (ts is! int || ts <= 0) continue;
      out.add(_AlertEvent(
        at: DateTime.fromMillisecondsSinceEpoch(ts),
        hive: (v['hive_name'] as String? ?? '').trim(),
        count: (v['detection_count'] as int?) ?? 0,
        confidence: ((v['confidence'] as num?)?.toDouble() ?? 0.0),
      ));
    }
    out.sort((a, b) => b.at.compareTo(a.at));
    return out;
  }
}

// ── Header ──────────────────────────────────────────────────────────────────
class _Header extends StatelessWidget {
  const _Header();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.fromLTRB(20, 16, 20, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Phân tích',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: AppColors.foreground,
              letterSpacing: -0.3,
            ),
          ),
          SizedBox(height: 2),
          Text(
            'Tổng quan hoạt động ong bắp cày trên các thùng',
            style: TextStyle(
              fontSize: 12,
              color: AppColors.mutedForeground,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Range filter ────────────────────────────────────────────────────────────
class _RangeBar extends StatelessWidget {
  final _Range selected;
  final ValueChanged<_Range> onChanged;
  const _RangeBar({required this.selected, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          for (final r in _Range.values) ...[
            _Pill(
              label: r.label,
              selected: selected == r,
              onTap: () => onChanged(r),
            ),
            const SizedBox(width: 8),
          ],
        ],
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _Pill({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? AppColors.foreground : AppColors.card,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTheme.radiusFull),
        side: BorderSide(
            color: selected ? AppColors.foreground : AppColors.border),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppTheme.radiusFull),
        onTap: onTap,
        child: Padding(
          padding:
              const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: selected ? Colors.white : AppColors.foreground,
            ),
          ),
        ),
      ),
    );
  }
}

// ── KPIs ────────────────────────────────────────────────────────────────────
class _KpiGrid extends StatelessWidget {
  final List<_AlertEvent> events;
  final int days;
  const _KpiGrid({required this.events, required this.days});

  @override
  Widget build(BuildContext context) {
    final total = events.length;
    final byDay = _groupByDay(events);
    final peakEntry = byDay.entries.fold<MapEntry<DateTime, int>?>(
        null,
        (best, e) =>
            best == null || e.value > best.value ? e : best);
    final avgPerDay = (total / days);
    final avgConf = events.isEmpty
        ? 0.0
        : events.map((e) => e.confidence).reduce((a, b) => a + b) /
            events.length;

    final peakLabel = peakEntry == null
        ? '—'
        : DateFormat('d/M', 'vi').format(peakEntry.key);
    final peakSub = peakEntry == null
        ? '—'
        : '${peakEntry.value} cảnh báo';

    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _KpiCard(
                label: 'Tổng cảnh báo',
                value: total.toString(),
                hint: '$days ngày gần nhất',
                icon: LucideIcons.shieldAlert,
                accent: AppColors.destructive,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _KpiCard(
                label: 'Ngày đỉnh',
                value: peakLabel,
                hint: peakSub,
                icon: LucideIcons.trendingUp,
                accent: AppColors.primary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _KpiCard(
                label: 'Trung bình / ngày',
                value: avgPerDay.toStringAsFixed(1),
                hint: 'cảnh báo / ngày',
                icon: LucideIcons.activity,
                accent: AppColors.info,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _KpiCard(
                label: 'Độ tin cậy TB',
                value: '${(avgConf * 100).toStringAsFixed(0)}%',
                hint: 'của model detection',
                icon: LucideIcons.target,
                accent: AppColors.success,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Map<DateTime, int> _groupByDay(List<_AlertEvent> events) {
    final m = <DateTime, int>{};
    for (final e in events) {
      final d = DateTime(e.at.year, e.at.month, e.at.day);
      m[d] = (m[d] ?? 0) + 1;
    }
    return m;
  }
}

class _KpiCard extends StatelessWidget {
  final String label;
  final String value;
  final String hint;
  final IconData icon;
  final Color accent;

  const _KpiCard({
    required this.label,
    required this.value,
    required this.hint,
    required this.icon,
    required this.accent,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 26,
                height: 26,
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                ),
                alignment: Alignment.center,
                child: Icon(icon, size: 14, color: accent),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  label,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: AppColors.mutedForeground,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            value,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: AppColors.foreground,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            hint,
            style: const TextStyle(
              fontSize: 11,
              color: AppColors.mutedForeground,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Daily chart ─────────────────────────────────────────────────────────────
class _DailyChart extends StatelessWidget {
  final List<_AlertEvent> events;
  final int days;
  const _DailyChart({required this.events, required this.days});

  @override
  Widget build(BuildContext context) {
    // Build buckets cho từng ngày trong range (gồm ngày 0 cảnh báo)
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final buckets = List.generate(days, (i) {
      final d = today.subtract(Duration(days: days - 1 - i));
      return d;
    });

    final counts = <DateTime, int>{for (final d in buckets) d: 0};
    for (final e in events) {
      final d = DateTime(e.at.year, e.at.month, e.at.day);
      if (counts.containsKey(d)) counts[d] = counts[d]! + 1;
    }

    final maxY = counts.values.isEmpty
        ? 1.0
        : (counts.values.reduce((a, b) => a > b ? a : b) * 1.25)
            .clamp(1.0, 9999.0);

    final showEveryN = days <= 7
        ? 1
        : days <= 30
            ? 5
            : 10;
    final barWidth = days <= 7 ? 22.0 : (days <= 30 ? 8.0 : 3.5);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _ChartTitle(
            title: 'Cảnh báo theo ngày',
            sub: 'Số lần phát hiện ong bắp cày mỗi ngày',
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 200,
            child: BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceBetween,
                maxY: maxY,
                barTouchData: BarTouchData(
                  touchTooltipData: BarTouchTooltipData(
                    getTooltipColor: (_) => AppColors.gray900,
                    tooltipRoundedRadius: 8,
                    tooltipPadding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 6),
                    getTooltipItem: (g, _, rod, __) {
                      final d = buckets[g.x];
                      return BarTooltipItem(
                        '${DateFormat('d/M', 'vi').format(d)}\n${rod.toY.toInt()} cảnh báo',
                        const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      );
                    },
                  ),
                ),
                titlesData: FlTitlesData(
                  topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 28,
                      getTitlesWidget: (value, _) {
                        final i = value.toInt();
                        if (i < 0 || i >= buckets.length) {
                          return const SizedBox.shrink();
                        }
                        // Hiển thị label thưa khi nhiều ngày
                        if (i % showEveryN != 0 &&
                            i != buckets.length - 1) {
                          return const SizedBox.shrink();
                        }
                        return Padding(
                          padding: const EdgeInsets.only(top: 6),
                          child: Text(
                            DateFormat('d/M').format(buckets[i]),
                            style: const TextStyle(
                              fontSize: 10,
                              color: AppColors.mutedForeground,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 28,
                      interval: maxY > 4 ? (maxY / 4).ceilToDouble() : 1,
                      getTitlesWidget: (value, _) {
                        if (value == 0) return const SizedBox.shrink();
                        return Text(
                          value.toInt().toString(),
                          style: const TextStyle(
                            fontSize: 10,
                            color: AppColors.mutedForeground,
                          ),
                        );
                      },
                    ),
                  ),
                ),
                borderData: FlBorderData(show: false),
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval:
                      maxY > 4 ? (maxY / 4).ceilToDouble() : 1,
                  getDrawingHorizontalLine: (_) => const FlLine(
                    color: AppColors.gray100,
                    strokeWidth: 1,
                  ),
                ),
                barGroups: [
                  for (var i = 0; i < buckets.length; i++)
                    BarChartGroupData(x: i, barRods: [
                      BarChartRodData(
                        toY: counts[buckets[i]]!.toDouble(),
                        color: AppColors.primary,
                        width: barWidth,
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(4),
                          topRight: Radius.circular(4),
                        ),
                        backDrawRodData: BackgroundBarChartRodData(
                          show: true,
                          toY: maxY,
                          color: AppColors.gray100,
                        ),
                      ),
                    ]),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Top hives ───────────────────────────────────────────────────────────────
class _TopHives extends StatelessWidget {
  final List<_AlertEvent> events;
  const _TopHives({required this.events});

  @override
  Widget build(BuildContext context) {
    // group by hive name
    final m = <String, int>{};
    for (final e in events) {
      final k = e.hive.isEmpty ? 'Không rõ' : e.hive;
      m[k] = (m[k] ?? 0) + 1;
    }
    final sorted = m.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final top = sorted.take(5).toList();
    final maxV = top.isEmpty
        ? 1
        : top.map((e) => e.value).reduce((a, b) => a > b ? a : b);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _ChartTitle(
            title: 'Thùng bị tấn công nhiều nhất',
            sub: 'Top 5 thùng có nhiều cảnh báo nhất',
          ),
          const SizedBox(height: 14),
          if (top.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 12),
              child: Text(
                'Chưa có dữ liệu',
                style: TextStyle(
                    fontSize: 13, color: AppColors.mutedForeground),
              ),
            )
          else
            for (var i = 0; i < top.length; i++) ...[
              _RankRow(
                rank: i + 1,
                hive: top[i].key,
                count: top[i].value,
                fraction: top[i].value / maxV,
              ),
              if (i < top.length - 1) const SizedBox(height: 10),
            ],
        ],
      ),
    );
  }
}

class _RankRow extends StatelessWidget {
  final int rank;
  final String hive;
  final int count;
  final double fraction;
  const _RankRow({
    required this.rank,
    required this.hive,
    required this.count,
    required this.fraction,
  });

  Color get _rankBg => switch (rank) {
        1 => AppColors.destructiveSoft,
        2 => AppColors.warningSoft,
        _ => AppColors.gray100,
      };
  Color get _rankFg => switch (rank) {
        1 => AppColors.destructive,
        2 => AppColors.warning,
        _ => AppColors.gray600,
      };

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 22,
          height: 22,
          decoration: BoxDecoration(
            color: _rankBg,
            borderRadius: BorderRadius.circular(AppTheme.radiusFull),
          ),
          alignment: Alignment.center,
          child: Text(
            '$rank',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w800,
              color: _rankFg,
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      hive,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppColors.foreground,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '$count',
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: AppColors.foreground,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              ClipRRect(
                borderRadius: BorderRadius.circular(AppTheme.radiusFull),
                child: LinearProgressIndicator(
                  value: fraction,
                  minHeight: 6,
                  backgroundColor: AppColors.gray100,
                  valueColor:
                      const AlwaysStoppedAnimation(AppColors.primary),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ── Insight box ─────────────────────────────────────────────────────────────
class _Insight extends StatelessWidget {
  final List<_AlertEvent> events;
  final int days;
  const _Insight({required this.events, required this.days});

  @override
  Widget build(BuildContext context) {
    // Rule-based: tìm giờ trong ngày bị tấn công nhiều nhất
    final perHour = List<int>.filled(24, 0);
    for (final e in events) {
      perHour[e.at.hour]++;
    }
    int peakHour = 0;
    int peakHourCount = 0;
    for (var h = 0; h < 24; h++) {
      if (perHour[h] > peakHourCount) {
        peakHourCount = perHour[h];
        peakHour = h;
      }
    }

    // % thùng bị attack ≥3 con
    final severe =
        events.where((e) => e.count >= 3).length;
    final severeRatio = events.isEmpty ? 0.0 : severe / events.length;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.secondary,
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(LucideIcons.lightbulb,
                  size: 16, color: AppColors.primary),
              const SizedBox(width: 8),
              const Text(
                'Quan sát',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: AppColors.foreground,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          _Bullet(
            text: peakHourCount > 0
                ? 'Khung giờ bị tấn công nhiều nhất: '
                    '${peakHour.toString().padLeft(2, '0')}:00–'
                    '${((peakHour + 1) % 24).toString().padLeft(2, '0')}:00 '
                    '($peakHourCount lần / $days ngày)'
                : 'Chưa đủ dữ liệu xác định khung giờ nguy hiểm',
          ),
          const SizedBox(height: 6),
          _Bullet(
            text: events.isEmpty
                ? 'Chưa có cảnh báo nào trong khoảng thời gian này'
                : 'Tỷ lệ tấn công nghiêm trọng (≥3 con): '
                    '${(severeRatio * 100).toStringAsFixed(0)}% '
                    '($severe / ${events.length} lần)',
          ),
        ],
      ),
    );
  }
}

class _Bullet extends StatelessWidget {
  final String text;
  const _Bullet({required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.only(top: 6),
          child: Icon(Icons.circle, size: 4, color: AppColors.foreground),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
              fontSize: 12,
              color: AppColors.foreground,
              height: 1.5,
            ),
          ),
        ),
      ],
    );
  }
}

// ── Shared ──────────────────────────────────────────────────────────────────
class _ChartTitle extends StatelessWidget {
  final String title;
  final String sub;
  const _ChartTitle({required this.title, required this.sub});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: AppColors.foreground,
            letterSpacing: -0.1,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          sub,
          style: const TextStyle(
            fontSize: 11,
            color: AppColors.mutedForeground,
          ),
        ),
      ],
    );
  }
}

class _Empty extends StatelessWidget {
  const _Empty();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 24),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        border: Border.all(color: AppColors.border),
      ),
      child: const Column(
        children: [
          Icon(LucideIcons.barChart3,
              size: 28, color: AppColors.gray400),
          SizedBox(height: 12),
          Text(
            'Chưa có dữ liệu phân tích',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppColors.foreground,
            ),
          ),
          SizedBox(height: 4),
          Text(
            'Phân tích sẽ xuất hiện khi hệ thống ghi nhận\ncảnh báo từ tracker',
            style: TextStyle(
              fontSize: 12,
              color: AppColors.mutedForeground,
              height: 1.4,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
