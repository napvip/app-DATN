import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../config/app_colors.dart';
import '../../config/app_routes.dart';
import '../../widgets/app_card.dart';
import '../../widgets/cached_image.dart';
import '../../widgets/status_badge.dart';
import '../../models/hive_model.dart';

class HiveDetailScreen extends StatelessWidget {
  final String hiveId;

  const HiveDetailScreen({super.key, required this.hiveId});

  @override
  Widget build(BuildContext context) {
    // In a real app, fetch hive data based on hiveId
    final hive = HiveModel.mockData.firstWhere(
      (h) => h.id == hiveId,
      orElse: () => HiveModel.mockData.first,
    );

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // App Bar
          SliverAppBar(
            pinned: true,
            expandedHeight: 0,
            backgroundColor: AppColors.background.withValues(alpha: 0.8),
            surfaceTintColor: Colors.transparent,
            leading: IconButton(
              icon: const Icon(LucideIcons.arrowLeft),
              onPressed: () => context.go(AppRoutes.main),
            ),
            title: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  hive.name,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                Text(
                  'Live monitoring',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
            actions: [
              Padding(
                padding: const EdgeInsets.only(right: 16),
                child: StatusBadge(status: hive.status),
              ),
            ],
          ),

          // Content
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  // Live Camera
                  _LiveCameraCard(),
                  const SizedBox(height: 24),

                  // Quick Metrics
                  _QuickMetrics(hive: hive),
                  const SizedBox(height: 24),

                  // AI Prediction
                  _AIPredictionCard(),
                  const SizedBox(height: 24),

                  // Honey Production Chart
                  _HoneyChart(),
                  const SizedBox(height: 24),

                  // Temperature Chart
                  _TemperatureChart(),
                  const SizedBox(height: 24),

                  // Wasp Detections
                  _WaspDetections(),
                  const SizedBox(height: 24),

                  // Device Controls
                  _DeviceControls(),
                  const SizedBox(height: 48),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _LiveCameraCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: EdgeInsets.zero,
      child: Column(
        children: [
          Stack(
            children: [
              AspectRatio(
                aspectRatio: 16 / 9,
                child: CachedImage(
                  imageUrl:
                      'https://images.unsplash.com/photo-1758522966091-4c7b94b5c3de?w=600',
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(24),
                    topRight: Radius.circular(24),
                  ),
                ),
              ),
              Positioned(
                top: 16,
                left: 16,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.destructive,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        'LIVE',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Positioned(
                bottom: 16,
                right: 16,
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.9),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    LucideIcons.video,
                    size: 20,
                    color: AppColors.foreground,
                  ),
                ),
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Live Camera Feed',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 4),
                Text(
                  'High-resolution monitoring with AI detection',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _QuickMetrics extends StatelessWidget {
  final HiveModel hive;

  const _QuickMetrics({required this.hive});

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      childAspectRatio: 1.3,
      crossAxisSpacing: 16,
      mainAxisSpacing: 16,
      children: [
        _MetricTile(
          icon: LucideIcons.scale,
          iconColor: AppColors.primary,
          label: 'Honey Weight',
          value: '14.5 kg',
          change: '+2.1 kg this week',
          changeColor: AppColors.success,
        ),
        _MetricTile(
          icon: LucideIcons.thermometer,
          iconColor: AppColors.warning,
          label: 'Temperature',
          value: '${hive.temperature.toInt()}°C',
          change: 'Optimal range',
          changeColor: AppColors.mutedForeground,
        ),
        _MetricTile(
          icon: LucideIcons.droplets,
          iconColor: AppColors.chart3,
          label: 'Humidity',
          value: '${hive.humidity.toInt()}%',
          change: 'Normal levels',
          changeColor: AppColors.mutedForeground,
        ),
        _MetricTile(
          icon: LucideIcons.battery,
          iconColor: AppColors.success,
          label: 'Device Battery',
          value: '${hive.batteryLevel}%',
          change: '~14 days left',
          changeColor: AppColors.mutedForeground,
        ),
      ],
    );
  }
}

class _MetricTile extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String label;
  final String value;
  final String change;
  final Color changeColor;

  const _MetricTile({
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.value,
    required this.change,
    required this.changeColor,
  });

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: iconColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, size: 20, color: iconColor),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  label,
                  style: Theme.of(context).textTheme.bodySmall,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const Spacer(),
          Text(
            value,
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 4),
          Text(
            change,
            style: TextStyle(
              fontSize: 12,
              color: changeColor,
            ),
          ),
        ],
      ),
    );
  }
}

class _AIPredictionCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.primary.withValues(alpha: 0.1),
            AppColors.primary.withValues(alpha: 0.05),
            Colors.transparent,
          ],
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(
              LucideIcons.activity,
              size: 24,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'AI Prediction',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                RichText(
                  text: TextSpan(
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppColors.mutedForeground,
                        ),
                    children: const [
                      TextSpan(
                          text:
                              'Based on current trends, this hive will produce approximately '),
                      TextSpan(
                        text: '18-22 kg',
                        style: TextStyle(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      TextSpan(text: ' of honey this month.'),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        color: AppColors.success,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '95% confidence',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _HoneyChart extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Honey Production Trend',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 24),
          SizedBox(
            height: 200,
            child: LineChart(
              LineChartData(
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  getDrawingHorizontalLine: (value) {
                    return FlLine(
                      color: AppColors.border,
                      strokeWidth: 1,
                    );
                  },
                ),
                titlesData: FlTitlesData(
                  show: true,
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        const dates = ['Apr 1', 'Apr 2', 'Apr 3', 'Apr 4', 'Apr 5', 'Apr 6', 'Apr 7'];
                        if (value.toInt() < dates.length) {
                          return Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Text(
                              dates[value.toInt()],
                              style: const TextStyle(
                                color: AppColors.mutedForeground,
                                fontSize: 10,
                              ),
                            ),
                          );
                        }
                        return const Text('');
                      },
                    ),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 32,
                      getTitlesWidget: (value, meta) {
                        return Text(
                          '${value.toInt()}',
                          style: const TextStyle(
                            color: AppColors.mutedForeground,
                            fontSize: 12,
                          ),
                        );
                      },
                    ),
                  ),
                ),
                borderData: FlBorderData(show: false),
                lineBarsData: [
                  LineChartBarData(
                    spots: const [
                      FlSpot(0, 8.2),
                      FlSpot(1, 9.1),
                      FlSpot(2, 10.3),
                      FlSpot(3, 11.2),
                      FlSpot(4, 12.4),
                      FlSpot(5, 13.1),
                      FlSpot(6, 14.5),
                    ],
                    isCurved: true,
                    color: AppColors.primary,
                    barWidth: 3,
                    dotData: const FlDotData(show: false),
                    belowBarData: BarAreaData(
                      show: true,
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          AppColors.primary.withValues(alpha: 0.3),
                          AppColors.primary.withValues(alpha: 0),
                        ],
                      ),
                    ),
                  ),
                ],
                minY: 6,
                maxY: 16,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TemperatureChart extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Temperature (24h)',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 24),
          SizedBox(
            height: 180,
            child: LineChart(
              LineChartData(
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  getDrawingHorizontalLine: (value) {
                    return FlLine(
                      color: AppColors.border,
                      strokeWidth: 1,
                    );
                  },
                ),
                titlesData: FlTitlesData(
                  show: true,
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        const times = ['00:00', '04:00', '08:00', '12:00', '16:00', '20:00'];
                        if (value.toInt() < times.length) {
                          return Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Text(
                              times[value.toInt()],
                              style: const TextStyle(
                                color: AppColors.mutedForeground,
                                fontSize: 10,
                              ),
                            ),
                          );
                        }
                        return const Text('');
                      },
                    ),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 32,
                      getTitlesWidget: (value, meta) {
                        return Text(
                          '${value.toInt()}',
                          style: const TextStyle(
                            color: AppColors.mutedForeground,
                            fontSize: 12,
                          ),
                        );
                      },
                    ),
                  ),
                ),
                borderData: FlBorderData(show: false),
                lineBarsData: [
                  LineChartBarData(
                    spots: const [
                      FlSpot(0, 32),
                      FlSpot(1, 31),
                      FlSpot(2, 33),
                      FlSpot(3, 35),
                      FlSpot(4, 36),
                      FlSpot(5, 34),
                    ],
                    isCurved: true,
                    color: AppColors.warning,
                    barWidth: 3,
                    dotData: FlDotData(
                      show: true,
                      getDotPainter: (spot, percent, barData, index) {
                        return FlDotCirclePainter(
                          radius: 4,
                          color: AppColors.warning,
                          strokeWidth: 0,
                        );
                      },
                    ),
                    belowBarData: BarAreaData(show: false),
                  ),
                ],
                minY: 28,
                maxY: 40,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _WaspDetections extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                LucideIcons.alertTriangle,
                size: 20,
                color: AppColors.destructive,
              ),
              const SizedBox(width: 8),
              Text(
                'Recent Wasp Detections',
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ],
          ),
          const SizedBox(height: 16),
          _WaspDetectionItem(
            time: '2 hours ago',
            severity: 'High',
            imageUrl:
                'https://images.unsplash.com/photo-1751167011495-074cf5f9ca66?w=200',
          ),
          const SizedBox(height: 12),
          _WaspDetectionItem(
            time: 'Yesterday at 3:24 PM',
            severity: 'Medium',
            imageUrl:
                'https://images.unsplash.com/photo-1751167011495-074cf5f9ca66?w=200',
          ),
        ],
      ),
    );
  }
}

class _WaspDetectionItem extends StatelessWidget {
  final String time;
  final String severity;
  final String imageUrl;

  const _WaspDetectionItem({
    required this.time,
    required this.severity,
    required this.imageUrl,
  });

  @override
  Widget build(BuildContext context) {
    final isHigh = severity == 'High';
    return Row(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: CachedImage(
            imageUrl: imageUrl,
            width: 80,
            height: 80,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: isHigh ? AppColors.destructive : AppColors.warning,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '$severity Risk',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                time,
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(height: 4),
              Text(
                'AI detected wasp activity near entrance',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _DeviceControls extends StatefulWidget {
  @override
  State<_DeviceControls> createState() => _DeviceControlsState();
}

class _DeviceControlsState extends State<_DeviceControls> {
  bool _cameraEnabled = true;
  double _sensitivity = 0.75;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Device Controls',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Camera',
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Live feed streaming',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
              Switch(
                value: _cameraEnabled,
                onChanged: (value) => setState(() => _cameraEnabled = value),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Alert Sensitivity',
                style: Theme.of(context).textTheme.bodyLarge,
              ),
              Text(
                'High',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
          const SizedBox(height: 8),
          Slider(
            value: _sensitivity,
            onChanged: (value) => setState(() => _sensitivity = value),
          ),
          Text(
            'Higher sensitivity means more frequent alerts for potential threats',
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    );
  }
}
