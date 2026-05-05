import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../config/app_colors.dart';
import '../../../config/app_routes.dart';

const _kDbUrl =
    'https://doan-hotronuoiong-default-rtdb.asia-southeast1.firebasedatabase.app';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _searchController = TextEditingController();
  String _search = '';

  String get _userName {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null && (user.displayName ?? '').isNotEmpty) {
      return user.displayName!.split(' ').first;
    }
    return 'Beekeeper';
  }

  FirebaseDatabase get _db => FirebaseDatabase.instanceFor(
        app: Firebase.app(),
        databaseURL: _kDbUrl,
      );

  @override
  void initState() {
    super.initState();
    _searchController.addListener(
      () => setState(() => _search = _searchController.text.trim().toLowerCase()),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 48, 24, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Good morning, $_userName',
                      style: Theme.of(context).textTheme.headlineLarge,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Monitor your beehives',
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            color: AppColors.mutedForeground,
                          ),
                    ),
                  ],
                ),
              ),

              // Weather Widget
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: const _WeatherWidget(),
              ),
              const SizedBox(height: 16),

              // Tracking Section
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: _TrackingSection(),
              ),
              const SizedBox(height: 24),

              // Search Bar
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Tìm thùng ong...',
                    prefixIcon: const Padding(
                      padding: EdgeInsets.only(left: 16, right: 12),
                      child: Icon(
                        LucideIcons.search,
                        size: 20,
                        color: AppColors.mutedForeground,
                      ),
                    ),
                    prefixIconConstraints: const BoxConstraints(
                      minWidth: 0,
                      minHeight: 0,
                    ),
                    filled: true,
                    fillColor: AppColors.card,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: const BorderSide(color: AppColors.border),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: const BorderSide(color: AppColors.border),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Hives Grid — real-time from RTDB
              if (uid != null)
                StreamBuilder<DatabaseEvent>(
                  stream: _db
                      .ref('tracking_devices')
                      .orderByChild('owner_uid')
                      .equalTo(uid)
                      .onValue,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Padding(
                        padding: EdgeInsets.all(48),
                        child: Center(
                          child: CircularProgressIndicator(
                              color: AppColors.primary),
                        ),
                      );
                    }

                    final data = snapshot.data?.snapshot.value;
                    List<Map<String, dynamic>> devices = [];

                    if (data != null) {
                      final raw = Map<String, dynamic>.from(data as Map);
                      devices = raw.entries
                          .map((e) => {
                                'device_id': e.key,
                                ...Map<String, dynamic>.from(e.value as Map),
                              })
                          .where((d) =>
                              (d['hive_name'] as String? ?? '').isNotEmpty)
                          .toList()
                        ..sort((a, b) =>
                            ((b['created_at'] as int?) ?? 0)
                                .compareTo((a['created_at'] as int?) ?? 0));

                      if (_search.isNotEmpty) {
                        devices = devices
                            .where((d) =>
                                (d['hive_name'] as String)
                                    .toLowerCase()
                                    .contains(_search) ||
                                (d['device_id'] as String)
                                    .toLowerCase()
                                    .contains(_search))
                            .toList();
                      }
                    }

                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Thùng ong của bạn (${devices.length})',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          const SizedBox(height: 16),
                          if (devices.isEmpty)
                            _EmptyHives()
                          else
                            GridView.builder(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              gridDelegate:
                                  const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 2,
                                childAspectRatio: 0.9,
                                crossAxisSpacing: 16,
                                mainAxisSpacing: 16,
                              ),
                              itemCount: devices.length,
                              itemBuilder: (context, index) =>
                                  _HiveCard(device: devices[index]),
                            ),
                        ],
                      ),
                    );
                  },
                ),

              const SizedBox(height: 100),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.push(AppRoutes.qrScanner),
        backgroundColor: AppColors.primary,
        elevation: 8,
        child: const Icon(
          LucideIcons.qrCode,
          color: AppColors.primaryForeground,
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------

class _EmptyHives extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 24),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          const Icon(LucideIcons.beaker, size: 40, color: AppColors.mutedForeground),
          const SizedBox(height: 12),
          const Text(
            'Chưa có thùng ong nào',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w500,
              color: AppColors.foreground,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Quét mã QR thiết bị để thêm thùng ong',
            style: TextStyle(fontSize: 13, color: AppColors.mutedForeground),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _HiveCard extends StatelessWidget {
  final Map<String, dynamic> device;
  const _HiveCard({required this.device});

  @override
  Widget build(BuildContext context) {
    final hiveName = device['hive_name'] as String? ?? 'Thùng ong';
    final deviceId = device['device_id'] as String? ?? '';
    final status = device['status'] as String? ?? 'unregistered';
    final lastSeen = device['last_seen'] as int? ?? 0;

    final (statusColor, statusLabel, statusBg) = switch (status) {
      'online' => (AppColors.success, 'Hoạt động', const Color(0xFFDCFCE7)),
      'offline' => (AppColors.mutedForeground, 'Ngoại tuyến', AppColors.muted),
      _ => (AppColors.warning, 'Chưa kết nối', const Color(0xFFFEF3C7)),
    };

    return GestureDetector(
      onTap: () => context.push('/hive/$deviceId'),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: AppColors.border),
        ),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(
                    LucideIcons.hexagon,
                    size: 22,
                    color: AppColors.primary,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: statusBg,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    statusLabel,
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w500,
                      color: statusColor,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Text(
              hiveName,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: AppColors.foreground,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            Text(
              deviceId,
              style: const TextStyle(
                fontSize: 10,
                fontFamily: 'monospace',
                color: AppColors.mutedForeground,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const Spacer(),
            Row(
              children: [
                const Icon(LucideIcons.clock, size: 11, color: AppColors.mutedForeground),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    _relativeTime(lastSeen),
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppColors.mutedForeground,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showDetail(BuildContext context) {
    final hiveName = device['hive_name'] as String? ?? 'Thùng ong';
    final deviceId = device['device_id'] as String? ?? '';
    final deviceName = device['device_name'] as String? ?? deviceId;
    final status = device['status'] as String? ?? 'unregistered';
    final createdAt = device['created_at'] as int? ?? 0;
    final lastSeen = device['last_seen'] as int? ?? 0;

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.card,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.55,
        minChildSize: 0.4,
        maxChildSize: 0.85,
        expand: false,
        builder: (_, controller) => SingleChildScrollView(
          controller: controller,
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.border,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                hiveName,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: AppColors.foreground,
                ),
              ),
              const SizedBox(height: 20),
              _DetailRow(label: 'Tên thiết bị', value: deviceName),
              _DetailRow(label: 'Device ID', value: deviceId, mono: true),
              _DetailRow(label: 'Trạng thái', value: _statusLabel(status)),
              _DetailRow(label: 'Lần cuối hoạt động', value: _relativeTime(lastSeen)),
              _DetailRow(
                label: 'Ngày thêm',
                value: createdAt == 0
                    ? 'Không rõ'
                    : DateTime.fromMillisecondsSinceEpoch(createdAt)
                        .toLocal()
                        .toString()
                        .substring(0, 16),
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.destructive,
                    side: const BorderSide(color: AppColors.destructive),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  icon: const Icon(LucideIcons.unlink, size: 18),
                  label: const Text(
                    'Gỡ thiết bị khỏi tài khoản',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                  ),
                  onPressed: () => _confirmDelete(ctx, deviceId),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _confirmDelete(BuildContext ctx, String deviceId) {
    showDialog<void>(
      context: ctx,
      builder: (dialogCtx) => AlertDialog(
        backgroundColor: AppColors.card,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          'Xóa thiết bị?',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
        content: const Text(
          'Thiết bị sẽ bị gỡ khỏi tài khoản của bạn. Thiết bị vẫn còn trong hệ thống.',
          style: TextStyle(fontSize: 14, color: AppColors.mutedForeground),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.destructive,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () async {
              Navigator.pop(dialogCtx);
              Navigator.pop(ctx);
              await _deleteDevice(ctx, deviceId);
            },
            child: const Text('Xóa'),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteDevice(BuildContext ctx, String deviceId) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    final db = FirebaseDatabase.instanceFor(
      app: Firebase.app(),
      databaseURL: _kDbUrl,
    );

    try {
      await Future.wait([
        db.ref('user_devices/$uid/$deviceId').remove(),
        db.ref('tracking_devices/$deviceId').update({
          'owner_uid': '',
          'hive_name': '',
          'status': 'unregistered',
        }),
      ]);
      if (ctx.mounted) {
        ScaffoldMessenger.of(ctx).showSnackBar(
          const SnackBar(
            content: Text('Đã gỡ thiết bị khỏi tài khoản'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (ctx.mounted) {
        ScaffoldMessenger.of(ctx).showSnackBar(
          SnackBar(
            content: Text('Lỗi: $e'),
            backgroundColor: AppColors.destructive,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  String _statusLabel(String status) => switch (status) {
        'online' => 'Đang hoạt động',
        'offline' => 'Ngoại tuyến',
        _ => 'Chưa kết nối',
      };

  String _relativeTime(int ms) {
    if (ms == 0) return 'Chưa kết nối';
    final diff = DateTime.now().millisecondsSinceEpoch - ms;
    if (diff < 60000) return 'Vừa xong';
    if (diff < 3600000) return '${diff ~/ 60000} phút trước';
    if (diff < 86400000) return '${diff ~/ 3600000} giờ trước';
    return '${diff ~/ 86400000} ngày trước';
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;
  final bool mono;
  const _DetailRow({required this.label, required this.value, this.mono = false});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 140,
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 13,
                color: AppColors.mutedForeground,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: AppColors.foreground,
                fontFamily: mono ? 'monospace' : null,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------

class _TrackingSection extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _TrackingCard(
            label: 'Quét mã QR',
            sublabel: 'Thêm thiết bị tracker',
            icon: LucideIcons.qrCode,
            onTap: () => context.push(AppRoutes.qrScanner),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _TrackingCard(
            label: 'Cảnh báo SOS',
            sublabel: 'Xem cảnh báo ong bắp cày',
            icon: LucideIcons.shieldAlert,
            iconColor: AppColors.destructive,
            onTap: () => context.push(AppRoutes.sosAlert),
          ),
        ),
      ],
    );
  }
}

class _TrackingCard extends StatelessWidget {
  final String label;
  final String sublabel;
  final IconData icon;
  final Color? iconColor;
  final VoidCallback onTap;

  const _TrackingCard({
    required this.label,
    required this.sublabel,
    required this.icon,
    required this.onTap,
    this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: [
            Icon(icon, size: 22, color: iconColor ?? AppColors.primary),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.foreground,
                    ),
                  ),
                  Text(
                    sublabel,
                    style: const TextStyle(
                        fontSize: 11, color: AppColors.mutedForeground),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------

class _WeatherWidget extends StatelessWidget {
  const _WeatherWidget();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.primary, AppColors.primary, AppColors.primaryDark],
        ),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(LucideIcons.sun, size: 24,
                      color: AppColors.primaryForeground),
                  const SizedBox(width: 8),
                  Text(
                    'Partly Cloudy',
                    style: TextStyle(
                      color: AppColors.primaryForeground.withValues(alpha: 0.9),
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                '24°C',
                style: TextStyle(
                  color: AppColors.primaryForeground,
                  fontSize: 48,
                  fontWeight: FontWeight.w300,
                ),
              ),
              Text(
                'Perfect weather for bees',
                style: TextStyle(
                  color: AppColors.primaryForeground.withValues(alpha: 0.9),
                  fontSize: 14,
                ),
              ),
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                'Humidity',
                style: TextStyle(
                  color: AppColors.primaryForeground.withValues(alpha: 0.9),
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '58%',
                style: TextStyle(
                  color: AppColors.primaryForeground,
                  fontSize: 24,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
