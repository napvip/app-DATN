import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../config/app_colors.dart';
import '../../../core/widgets/cached_image.dart';
import '../../../data/datasources/sos_realtime_service.dart';
import '../../../data/models/alert_model.dart';

const _kDbUrl =
    'https://doan-hotronuoiong-default-rtdb.asia-southeast1.firebasedatabase.app';

// Cặp dữ liệu: model để render UI, raw để thực hiện action
class _AlertEntry {
  final AlertModel model;
  final Map<String, dynamic> raw;
  _AlertEntry(this.model, this.raw);
}

class AlertsScreen extends StatefulWidget {
  const AlertsScreen({super.key});

  @override
  State<AlertsScreen> createState() => _AlertsScreenState();
}

class _AlertsScreenState extends State<AlertsScreen> {
  String _filter = 'all';

  // Map RTDB record → AlertModel để dùng lại design cũ
  _AlertEntry _mapEntry(String key, Map<String, dynamic> data) {
    final count = data['detection_count'] as int? ?? 0;
    final confidence =
        ((data['confidence'] as num?)?.toDouble() ?? 0) * 100;
    final createdAt = data['created_at'] as int? ?? 0;
    final imageUrl = (data['image_url'] as String? ?? '').trim();
    final isRead = data['is_read'] as bool? ?? false;

    final model = AlertModel(
      id: key.hashCode,
      type: AlertType.attack,
      hive: data['hive_name'] as String? ?? 'Thùng ong',
      title: 'Phát hiện ong bắp cày',
      description:
          'Phát hiện $count con · Độ tin cậy ${confidence.toStringAsFixed(0)}%',
      time: _relativeTime(createdAt),
      severity: count >= 3 ? AlertSeverity.high : AlertSeverity.medium,
      imageUrl: imageUrl.isNotEmpty ? imageUrl : null,
      isRead: isRead,
    );
    return _AlertEntry(model, {...data, 'key': key});
  }

  String _relativeTime(int ms) {
    if (ms == 0) return '';
    final diff = DateTime.now().millisecondsSinceEpoch - ms;
    if (diff < 60000) return 'Vừa xong';
    if (diff < 3600000) return '${diff ~/ 60000} phút trước';
    if (diff < 86400000) return '${diff ~/ 3600000} giờ trước';
    return '${diff ~/ 86400000} ngày trước';
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      body: user == null
          ? const Center(child: Text('Chưa đăng nhập'))
          : StreamBuilder<DatabaseEvent>(
              stream: FirebaseDatabase.instanceFor(
                app: Firebase.app(),
                databaseURL: _kDbUrl,
              ).ref('user_sos_alerts/${user.uid}').onValue,
              builder: (context, snapshot) {
                // Map RTDB data → entries
                List<_AlertEntry> entries = [];
                if (snapshot.hasData &&
                    snapshot.data!.snapshot.value != null) {
                  final raw = Map<String, dynamic>.from(
                    snapshot.data!.snapshot.value as Map,
                  );
                  entries = raw.entries
                      .map((e) => _mapEntry(
                            e.key,
                            Map<String, dynamic>.from(e.value as Map),
                          ))
                      .toList()
                    ..sort((a, b) =>
                        ((b.raw['created_at'] as int?) ?? 0).compareTo(
                          (a.raw['created_at'] as int?) ?? 0,
                        ));
                }

                final filtered = _filter == 'unread'
                    ? entries.where((e) => !e.model.isRead).toList()
                    : entries;
                final unreadCount =
                    entries.where((e) => !e.model.isRead).length;

                return SafeArea(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header — giữ nguyên design gốc
                      Padding(
                        padding: const EdgeInsets.fromLTRB(24, 48, 24, 24),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Alerts',
                                  style: Theme.of(context)
                                      .textTheme
                                      .headlineLarge,
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '$unreadCount unread notification${unreadCount != 1 ? 's' : ''}',
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodyMedium
                                      ?.copyWith(
                                        color: AppColors.mutedForeground,
                                      ),
                                ),
                              ],
                            ),
                            IconButton(
                              onPressed: () {},
                              icon: const Icon(
                                LucideIcons.filter,
                                color: AppColors.mutedForeground,
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Filter Tabs — giữ nguyên
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: AppColors.muted,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              _FilterTab(
                                label: 'All',
                                isSelected: _filter == 'all',
                                onTap: () =>
                                    setState(() => _filter = 'all'),
                              ),
                              _FilterTab(
                                label: 'Unread ($unreadCount)',
                                isSelected: _filter == 'unread',
                                onTap: () =>
                                    setState(() => _filter = 'unread'),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Alerts List — giữ nguyên layout
                      Expanded(
                        child: snapshot.connectionState ==
                                ConnectionState.waiting
                            ? const Center(
                                child: CircularProgressIndicator(
                                  color: AppColors.primary,
                                  strokeWidth: 2,
                                ),
                              )
                            : filtered.isEmpty
                                ? _EmptyState()
                                : ListView.separated(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 24),
                                    itemCount: filtered.length,
                                    separatorBuilder: (_, __) =>
                                        const SizedBox(height: 12),
                                    itemBuilder: (context, index) {
                                      return _AlertCard(
                                          entry: filtered[index]);
                                    },
                                  ),
                      ),
                    ],
                  ),
                );
              },
            ),
    );
  }
}

// ---------------------------------------------------------------------------
// Filter Tab — giữ nguyên 100%
// ---------------------------------------------------------------------------
class _FilterTab extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _FilterTab({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.card : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected
                ? AppColors.foreground
                : AppColors.mutedForeground,
            fontWeight:
                isSelected ? FontWeight.w500 : FontWeight.w400,
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Alert Card — giữ nguyên layout gốc, thêm "Xem chi tiết" ở dưới
// ---------------------------------------------------------------------------
class _AlertCard extends StatelessWidget {
  final _AlertEntry entry;

  const _AlertCard({required this.entry});

  @override
  Widget build(BuildContext context) {
    final alert = entry.model;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: alert.isRead
              ? AppColors.border
              : AppColors.primary.withValues(alpha: 0.3),
        ),
        boxShadow: alert.isRead
            ? null
            : [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  blurRadius: 16,
                  offset: const Offset(0, 4),
                ),
              ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Icon or Image — giữ nguyên
          if (alert.imageUrl != null)
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: CachedImage(
                imageUrl: alert.imageUrl!,
                width: 64,
                height: 64,
              ),
            )
          else
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: alert.iconBackgroundColor,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(
                alert.icon,
                size: 28,
                color: alert.iconColor,
              ),
            ),
          const SizedBox(width: 16),

          // Content — giữ nguyên + thêm "Xem chi tiết"
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        alert.title,
                        style:
                            Theme.of(context).textTheme.titleMedium,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (!alert.isRead)
                      Container(
                        width: 8,
                        height: 8,
                        decoration: const BoxDecoration(
                          color: AppColors.primary,
                          shape: BoxShape.circle,
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  alert.description,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppColors.mutedForeground,
                      ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Text(
                      alert.hive,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '•',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      alert.time,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),

                // "Xem chi tiết" link
                const SizedBox(height: 8),
                GestureDetector(
                  onTap: () => _showDetail(context),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Xem chi tiết',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: AppColors.primary,
                        ),
                      ),
                      const SizedBox(width: 3),
                      const Icon(
                        LucideIcons.chevronRight,
                        size: 12,
                        color: AppColors.primary,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showDetail(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _DetailSheet(entry: entry),
    );
  }
}

// ---------------------------------------------------------------------------
// Detail Bottom Sheet — cùng style với card (bo tròn 24, màu AppColors)
// ---------------------------------------------------------------------------
class _DetailSheet extends StatelessWidget {
  final _AlertEntry entry;
  const _DetailSheet({required this.entry});

  @override
  Widget build(BuildContext context) {
    final alert = entry.model;
    final raw = entry.raw;
    final status = raw['status'] as String? ?? 'active';
    final isActive = status == 'active';
    final alertKey = raw['key'] as String? ?? '';
    final deviceId = raw['device_id'] as String? ?? '';
    final createdAt = raw['created_at'] as int? ?? 0;
    final confidence =
        ((raw['confidence'] as num?)?.toDouble() ?? 0) * 100;
    final count = raw['detection_count'] as int? ?? 0;

    final dt = createdAt > 0
        ? DateTime.fromMillisecondsSinceEpoch(createdAt)
        : null;
    final timeStr = dt != null
        ? '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year}  '
            '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}'
        : '—';

    return Container(
      decoration: const BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle
          Container(
            margin: const EdgeInsets.only(top: 12, bottom: 4),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.border,
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title row
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          alert.title,
                          style:
                              Theme.of(context).textTheme.titleLarge,
                        ),
                      ),
                      _StatusChip(status: status),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    alert.hive,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppColors.mutedForeground,
                        ),
                  ),

                  const SizedBox(height: 20),

                  // Detection image — cùng style bo tròn
                  if (alert.imageUrl != null) ...[
                    ClipRRect(
                      borderRadius: BorderRadius.circular(20),
                      child: CachedImage(
                        imageUrl: alert.imageUrl!,
                        width: double.infinity,
                        height: 200,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(LucideIcons.camera,
                            size: 11,
                            color: AppColors.mutedForeground),
                        const SizedBox(width: 4),
                        Text(
                          'Ảnh ghi nhận từ camera tracking',
                          style: Theme.of(context)
                              .textTheme
                              .bodySmall
                              ?.copyWith(
                                  color: AppColors.mutedForeground),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                  ],

                  // Info grid — cùng màu card
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.card,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Column(
                      children: [
                        _InfoRow(
                          icon: LucideIcons.alertTriangle,
                          label: 'Số lượng phát hiện',
                          value: '$count ong bắp cày',
                          iconColor: AppColors.destructive,
                        ),
                        const Divider(height: 20, color: AppColors.border),
                        _InfoRow(
                          icon: LucideIcons.target,
                          label: 'Độ tin cậy',
                          value: '${confidence.toStringAsFixed(0)}%',
                          iconColor: AppColors.success,
                        ),
                        const Divider(height: 20, color: AppColors.border),
                        _InfoRow(
                          icon: LucideIcons.clock,
                          label: 'Thời gian',
                          value: timeStr,
                          iconColor: AppColors.primary,
                        ),
                        const Divider(height: 20, color: AppColors.border),
                        _InfoRow(
                          icon: LucideIcons.cpu,
                          label: 'Thiết bị',
                          value: deviceId,
                          iconColor: AppColors.mutedForeground,
                          mono: true,
                        ),
                      ],
                    ),
                  ),

                  if (isActive && alertKey.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton.icon(
                        onPressed: () {
                          SOSRealtimeService()
                              .acknowledgeAlert(alertKey);
                          Navigator.pop(context);
                        },
                        icon: const Icon(LucideIcons.checkCircle,
                            size: 16),
                        label: const Text('Đánh dấu đã xử lý'),
                        style: FilledButton.styleFrom(
                          backgroundColor: AppColors.success,
                          padding:
                              const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16)),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color iconColor;
  final bool mono;

  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
    required this.iconColor,
    this.mono = false,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 15, color: iconColor),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            label,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.mutedForeground,
                ),
          ),
        ),
        Text(
          value,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
                fontFamily: mono ? 'monospace' : null,
              ),
        ),
      ],
    );
  }
}

class _StatusChip extends StatelessWidget {
  final String status;
  const _StatusChip({required this.status});

  @override
  Widget build(BuildContext context) {
    final Color bg;
    final Color fg;
    final String label;

    switch (status) {
      case 'active':
        bg = AppColors.destructive.withValues(alpha: 0.1);
        fg = AppColors.destructive;
        label = 'Đang cảnh báo';
      case 'acknowledged':
        bg = AppColors.warning.withValues(alpha: 0.1);
        fg = AppColors.warning;
        label = 'Đã xem';
      default:
        bg = AppColors.success.withValues(alpha: 0.1);
        fg = AppColors.success;
        label = 'Đã xử lý';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: fg,
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Empty State — giữ nguyên 100%
// ---------------------------------------------------------------------------
class _EmptyState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppColors.muted.withValues(alpha: 0.5),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              LucideIcons.bell,
              size: 48,
              color: AppColors.mutedForeground,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'No unread alerts',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          Text(
            "You're all caught up! We'll notify you\nof any new activity.",
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.mutedForeground,
                ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
