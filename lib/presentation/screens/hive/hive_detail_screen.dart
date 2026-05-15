import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import '../../../config/app_colors.dart';
import '../../../config/app_routes.dart';
import '../../../core/widgets/app_card.dart';
import '../../widgets/device_control_card.dart';
import 'device_qr_screen.dart';

class HiveDetailScreen extends StatefulWidget {
  final String hiveId;
  const HiveDetailScreen({super.key, required this.hiveId});

  @override
  State<HiveDetailScreen> createState() => _HiveDetailScreenState();
}

class _HiveDetailScreenState extends State<HiveDetailScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CustomScrollView(
        slivers: [
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
                Text(widget.hiveId,
                    style: Theme.of(context).textTheme.titleMedium),
                Text('Live monitoring',
                    style: Theme.of(context).textTheme.bodySmall),
              ],
            ),
            actions: [
              IconButton(
                icon: const Icon(LucideIcons.qrCode),
                tooltip: 'Xem mã QR thiết bị',
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => DeviceQrScreen(deviceId: widget.hiveId),
                    ),
                  );
                },
              ),
            ],
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 12),
              child: _SensorCard(deviceId: widget.hiveId),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
              child: DeviceControlCard(deviceId: widget.hiveId),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Sensor card ──────────────────────────────────────────────────────────────

class _SensorCard extends StatefulWidget {
  final String deviceId;
  const _SensorCard({required this.deviceId});

  @override
  State<_SensorCard> createState() => _SensorCardState();
}

class _SensorCardState extends State<_SensorCard> {
  static const _dbUrl =
      'https://doan-hotronuoiong-default-rtdb.asia-southeast1.firebasedatabase.app';

  late final Stream<DatabaseEvent> _stream;

  @override
  void initState() {
    super.initState();
    _stream = FirebaseDatabase.instanceFor(app: Firebase.app(), databaseURL: _dbUrl)
        .ref('tracking_devices/${widget.deviceId}/sensors')
        .onValue;
  }

  static double? _d(dynamic v) {
    if (v is double) return v;
    if (v is int) return v.toDouble();
    if (v is String) return double.tryParse(v);
    return null;
  }

  static int? _i(dynamic v) {
    if (v is int) return v;
    if (v is double) return v.toInt();
    if (v is String) return int.tryParse(v);
    return null;
  }

  static String _ago(int ts) {
    final s = (DateTime.now().millisecondsSinceEpoch - ts) ~/ 1000;
    if (s < 5) return 'Vừa cập nhật';
    if (s < 60) return '${s}s trước';
    return '${s ~/ 60} phút trước';
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<DatabaseEvent>(
      stream: _stream,
      builder: (context, snap) {
        Map<dynamic, dynamic>? map;
        if (snap.hasData && snap.data?.snapshot.value != null) {
          try {
            map = Map<dynamic, dynamic>.from(snap.data!.snapshot.value as Map);
          } catch (_) {}
        }

        final temp = _d(map?['temperature']);
        final hum  = _d(map?['humidity']);
        final dist = _d(map?['water_distance_cm']);
        final ts   = _i(map?['updated_at']);
        final waterPct = dist == null
            ? 0.0
            : ((30.0 - dist) / 30.0 * 100).clamp(0.0, 100.0);

        return AppCard(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  Text('Cảm biến',
                      style: Theme.of(context).textTheme.titleMedium),
                  const Spacer(),
                  if (map != null) ...[
                    if (ts != null)
                      Text(_ago(ts),
                          style: Theme.of(context).textTheme.bodySmall),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: AppColors.success.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Text('LIVE',
                          style: TextStyle(
                              color: AppColors.success,
                              fontSize: 11,
                              fontWeight: FontWeight.w700)),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 16),

              // Body
              if (snap.hasError)
                _status(LucideIcons.wifiOff, AppColors.destructive,
                    'Lỗi kết nối', '${snap.error}')
              else if (snap.connectionState == ConnectionState.waiting)
                _status(LucideIcons.loader, AppColors.mutedForeground,
                    'Đang kết nối...', '')
              else if (map == null)
                _status(LucideIcons.wifiOff, AppColors.warning,
                    'Chưa có dữ liệu', '')
              else ...[
                Row(children: [
                  Expanded(child: _Tile(
                    icon: LucideIcons.thermometer,
                    label: 'Nhiệt độ',
                    value: temp != null ? '${temp.toStringAsFixed(1)}°C' : '--',
                    sub: _tempSub(temp),
                    color: _tempColor(temp),
                  )),
                  const SizedBox(width: 12),
                  Expanded(child: _Tile(
                    icon: LucideIcons.droplets,
                    label: 'Độ ẩm',
                    value: hum != null ? '${hum.toStringAsFixed(1)}%' : '--',
                    sub: _humSub(hum),
                    color: AppColors.chart3,
                  )),
                ]),
                const SizedBox(height: 12),
                _WaterTile(distanceCm: dist, levelPercent: waterPct),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _status(IconData icon, Color color, String title, String sub) =>
      Padding(
        padding: const EdgeInsets.symmetric(vertical: 24),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 20, color: color),
            const SizedBox(width: 8),
            Text(title,
                style: TextStyle(
                    color: color,
                    fontSize: 13,
                    fontWeight: FontWeight.w500)),
            if (sub.isNotEmpty) ...[
              const SizedBox(width: 6),
              Flexible(
                  child: Text(sub,
                      style: const TextStyle(
                          fontSize: 11,
                          color: AppColors.mutedForeground))),
            ],
          ],
        ),
      );

  Color _tempColor(double? t) {
    if (t == null) return AppColors.mutedForeground;
    if (t > 80) return AppColors.mutedForeground;
    if (t >= 33 && t <= 36) return AppColors.success;
    if (t > 37) return AppColors.destructive;
    if (t < 30) return AppColors.chart3;
    return AppColors.warning;
  }

  String _tempSub(double? t) {
    if (t == null) return 'Không có dữ liệu';
    if (t > 80) return 'Lỗi cảm biến';
    if (t >= 33 && t <= 36) return 'Tối ưu cho ong';
    if (t > 37) return 'Quá nóng!';
    if (t < 30) return 'Hơi lạnh';
    return 'Bình thường';
  }

  String _humSub(double? h) {
    if (h == null) return 'Không có dữ liệu';
    if (h >= 100) return 'Lỗi cảm biến';
    if (h >= 50 && h <= 75) return 'Lý tưởng';
    if (h < 40) return 'Hơi khô';
    return 'Quá ẩm';
  }
}

// ── Tile nhiệt độ / độ ẩm ───────────────────────────────────────────────────

class _Tile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final String sub;
  final Color color;

  const _Tile({
    required this.icon,
    required this.label,
    required this.value,
    required this.sub,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.15)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Icon(icon, size: 16, color: color),
            const SizedBox(width: 6),
            Text(label,
                style: TextStyle(
                    fontSize: 12,
                    color: AppColors.mutedForeground,
                    fontWeight: FontWeight.w500)),
          ]),
          const SizedBox(height: 10),
          Text(value,
              style: Theme.of(context)
                  .textTheme
                  .headlineSmall
                  ?.copyWith(fontWeight: FontWeight.w700)),
          const SizedBox(height: 3),
          Text(sub,
              style: const TextStyle(
                  fontSize: 11, color: AppColors.mutedForeground)),
        ],
      ),
    );
  }
}

// ── Tile mực nước ────────────────────────────────────────────────────────────

class _WaterTile extends StatelessWidget {
  final double? distanceCm;
  final double levelPercent;

  const _WaterTile({required this.distanceCm, required this.levelPercent});

  Color get _color {
    if (distanceCm == null) return AppColors.mutedForeground;
    if (levelPercent > 60) return AppColors.chart3;
    if (levelPercent > 30) return AppColors.warning;
    return AppColors.destructive;
  }

  String get _sub {
    if (distanceCm == null) return 'Không có dữ liệu';
    if (levelPercent > 60) return 'Đầy đủ';
    if (levelPercent > 30) return 'Cần kiểm tra';
    return 'Sắp hết nước!';
  }

  @override
  Widget build(BuildContext context) {
    final c = _color;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: c.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: c.withValues(alpha: 0.15)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Icon(LucideIcons.droplet, size: 16, color: c),
            const SizedBox(width: 6),
            Text('Mực nước',
                style: TextStyle(
                    fontSize: 12,
                    color: AppColors.mutedForeground,
                    fontWeight: FontWeight.w500)),
            const Spacer(),
            if (distanceCm != null)
              Text('${distanceCm!.toStringAsFixed(1)} cm',
                  style: const TextStyle(
                      fontSize: 11, color: AppColors.mutedForeground)),
          ]),
          const SizedBox(height: 10),
          Row(children: [
            Text(
              distanceCm != null
                  ? '${levelPercent.toStringAsFixed(0)}%'
                  : '--',
              style: Theme.of(context)
                  .textTheme
                  .headlineSmall
                  ?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: LinearProgressIndicator(
                      value: levelPercent / 100,
                      minHeight: 10,
                      backgroundColor: c.withValues(alpha: 0.15),
                      valueColor: AlwaysStoppedAnimation(c),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(_sub,
                      style: const TextStyle(
                          fontSize: 11, color: AppColors.mutedForeground)),
                ],
              ),
            ),
          ]),
        ],
      ),
    );
  }
}
