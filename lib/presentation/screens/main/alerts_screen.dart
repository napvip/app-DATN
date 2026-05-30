import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../config/app_colors.dart';
import '../../../config/app_theme.dart';
import '../../../core/widgets/cached_image.dart';
import '../../../data/datasources/sos_realtime_service.dart';

const _kDbUrl =
    'https://doan-hotronuoiong-default-rtdb.asia-southeast1.firebasedatabase.app';

// ── Models ──────────────────────────────────────────────────────────────────
class _Alert {
  final String key;
  final String hiveName;
  final String deviceId;
  final int detectionCount;
  final double confidence; // 0..1
  final String? imageUrl;
  final String status; // active | acknowledged | resolved
  final bool isRead;
  final DateTime createdAt;

  _Alert({
    required this.key,
    required this.hiveName,
    required this.deviceId,
    required this.detectionCount,
    required this.confidence,
    required this.imageUrl,
    required this.status,
    required this.isRead,
    required this.createdAt,
  });

  factory _Alert.from(String key, Map<String, dynamic> m) {
    final ts = (m['created_at'] as int?) ?? 0;
    return _Alert(
      key: key,
      hiveName: (m['hive_name'] as String?) ?? 'Thùng ong',
      deviceId: (m['device_id'] as String?) ?? '',
      detectionCount: (m['detection_count'] as int?) ?? 0,
      confidence: ((m['confidence'] as num?)?.toDouble() ?? 0.0),
      imageUrl: ((m['image_url'] as String?) ?? '').isEmpty
          ? null
          : m['image_url'] as String,
      status: (m['status'] as String?) ?? 'active',
      isRead: (m['is_read'] as bool?) ?? false,
      createdAt: ts == 0
          ? DateTime.fromMillisecondsSinceEpoch(0)
          : DateTime.fromMillisecondsSinceEpoch(ts),
    );
  }
}

enum _TimeFilter { today, week, month, all }

// ── Screen ──────────────────────────────────────────────────────────────────
class AlertsScreen extends StatefulWidget {
  const AlertsScreen({super.key});

  @override
  State<AlertsScreen> createState() => _AlertsScreenState();
}

class _AlertsScreenState extends State<AlertsScreen> {
  _TimeFilter _time = _TimeFilter.all;
  bool _onlyUnread = false;
  bool _selectMode = false;
  final Set<String> _selectedKeys = {};

  void _exitSelect() => setState(() {
        _selectMode = false;
        _selectedKeys.clear();
      });

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
                final unreadTotal = all.where((a) => !a.isRead).length;
                final filtered = _applyFilter(all);

                return SafeArea(
                  bottom: false,
                  child: CustomScrollView(
                    physics: const BouncingScrollPhysics(),
                    slivers: [
                      if (_selectMode)
                        SliverToBoxAdapter(
                          child: _SelectionBar(
                            count: _selectedKeys.length,
                            allSelected: filtered.isNotEmpty &&
                                _selectedKeys.length == filtered.length,
                            onCancel: _exitSelect,
                            onToggleAll: () => setState(() {
                              if (_selectedKeys.length == filtered.length) {
                                _selectedKeys.clear();
                              } else {
                                _selectedKeys
                                  ..clear()
                                  ..addAll(filtered.map((a) => a.key));
                              }
                            }),
                            onDelete: _selectedKeys.isEmpty
                                ? null
                                : () => _confirmDeleteSelected(all),
                          ),
                        )
                      else ...[
                        SliverToBoxAdapter(
                          child: _Header(
                            totalUnread: unreadTotal,
                            hasItems: all.isNotEmpty,
                            onMarkAll: () => SOSRealtimeService().markAllAsRead(),
                            onDeleteAll: () => _confirmDeleteAll(context),
                            onSelect: () => setState(() => _selectMode = true),
                          ),
                        ),
                        SliverToBoxAdapter(
                          child: _TimeFilterBar(
                            selected: _time,
                            counts: _countByTime(all),
                            onChanged: (t) => setState(() => _time = t),
                          ),
                        ),
                        SliverToBoxAdapter(
                          child: Padding(
                            padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
                            child: _StatusToggle(
                              onlyUnread: _onlyUnread,
                              onChanged: (v) =>
                                  setState(() => _onlyUnread = v),
                            ),
                          ),
                        ),
                      ],
                      if (snap.connectionState ==
                              ConnectionState.waiting &&
                          all.isEmpty)
                        const SliverToBoxAdapter(
                          child: Padding(
                            padding: EdgeInsets.all(48),
                            child: Center(
                              child: CircularProgressIndicator(),
                            ),
                          ),
                        )
                      else if (filtered.isEmpty)
                        SliverToBoxAdapter(
                          child: _EmptyState(
                            hasAny: all.isNotEmpty,
                          ),
                        )
                      else
                        ..._buildGroupedSlivers(filtered),
                      const SliverToBoxAdapter(child: SizedBox(height: 48)),
                    ],
                  ),
                );
              },
            ),
    );
  }

  // ── data ──────────────────────────────────────────────────────────────────
  List<_Alert> _parse(dynamic raw) {
    if (raw is! Map) return const [];
    try {
      return raw.entries
          .map<_Alert>((e) => _Alert.from(
                e.key.toString(),
                Map<String, dynamic>.from(e.value as Map),
              ))
          .toList()
        ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    } catch (_) {
      return const [];
    }
  }

  List<_Alert> _applyFilter(List<_Alert> all) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    Iterable<_Alert> it = all;

    switch (_time) {
      case _TimeFilter.today:
        it = it.where((a) =>
            a.createdAt.isAfter(today.subtract(const Duration(seconds: 1))));
        break;
      case _TimeFilter.week:
        it = it.where((a) =>
            a.createdAt.isAfter(today.subtract(const Duration(days: 7))));
        break;
      case _TimeFilter.month:
        it = it.where((a) =>
            a.createdAt.isAfter(today.subtract(const Duration(days: 30))));
        break;
      case _TimeFilter.all:
        break;
    }

    if (_onlyUnread) {
      it = it.where((a) => !a.isRead);
    }

    return it.toList();
  }

  Map<_TimeFilter, int> _countByTime(List<_Alert> all) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    int t = 0, w = 0, m = 0;
    for (final a in all) {
      if (a.createdAt.isAfter(today.subtract(const Duration(seconds: 1)))) {
        t++;
      }
      if (a.createdAt.isAfter(today.subtract(const Duration(days: 7)))) {
        w++;
      }
      if (a.createdAt.isAfter(today.subtract(const Duration(days: 30)))) {
        m++;
      }
    }
    return {
      _TimeFilter.today: t,
      _TimeFilter.week: w,
      _TimeFilter.month: m,
      _TimeFilter.all: all.length,
    };
  }

  // ── grouping by date ──────────────────────────────────────────────────────
  List<Widget> _buildGroupedSlivers(List<_Alert> alerts) {
    final groups = <String, List<_Alert>>{};
    for (final a in alerts) {
      final key = _dateGroupKey(a.createdAt);
      groups.putIfAbsent(key, () => []).add(a);
    }

    final slivers = <Widget>[];
    for (final entry in groups.entries) {
      slivers.add(SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
          child: Text(
            entry.key,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.6,
              color: AppColors.mutedForeground,
            ),
          ),
        ),
      ));
      slivers.add(SliverList(
        delegate: SliverChildBuilderDelegate(
          (_, i) => Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 10),
            child: _AlertCard(
              alert: entry.value[i],
              selectMode: _selectMode,
              selected: _selectedKeys.contains(entry.value[i].key),
              onTap: () => _openDetail(entry.value[i]),
              onToggleSelect: () => setState(() {
                final k = entry.value[i].key;
                if (_selectedKeys.contains(k)) {
                  _selectedKeys.remove(k);
                } else {
                  _selectedKeys.add(k);
                }
              }),
              onLongPress: () => setState(() {
                _selectMode = true;
                _selectedKeys.add(entry.value[i].key);
              }),
              onDelete: () => _confirmDelete(entry.value[i]),
            ),
          ),
          childCount: entry.value.length,
        ),
      ));
    }
    return slivers;
  }

  String _dateGroupKey(DateTime d) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final dDay = DateTime(d.year, d.month, d.day);
    final diff = today.difference(dDay).inDays;
    if (diff == 0) return 'HÔM NAY';
    if (diff == 1) return 'HÔM QUA';
    if (diff < 7) return DateFormat('EEEE', 'vi').format(d).toUpperCase();
    return DateFormat("d 'tháng' M, yyyy", 'vi').format(d).toUpperCase();
  }

  // ── actions ───────────────────────────────────────────────────────────────
  void _openDetail(_Alert a) {
    // Đánh dấu đã đọc khi mở
    if (!a.isRead) {
      SOSRealtimeService().markAsRead(a.key);
    }
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _DetailSheet(
        alert: a,
        onAcknowledge: () => SOSRealtimeService().acknowledgeAlert(a.key),
        onDelete: () => _confirmDelete(a, fromSheet: true),
      ),
    );
  }

  void _confirmDelete(_Alert a, {bool fromSheet = false}) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Xóa cảnh báo?'),
        content: Text(
          'Cảnh báo "${a.hiveName}" ngày ${DateFormat('d/M/y HH:mm').format(a.createdAt)} '
          'sẽ bị xóa vĩnh viễn khỏi tài khoản của bạn.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.destructive,
              foregroundColor: Colors.white,
            ),
            onPressed: () async {
              Navigator.pop(ctx);
              if (fromSheet && mounted) Navigator.pop(context);
              await SOSRealtimeService().deleteAlert(
                a.key,
                imageUrl: a.imageUrl,
                deviceId: a.deviceId,
                createdAt: a.createdAt.millisecondsSinceEpoch,
              );
            },
            child: const Text('Xóa'),
          ),
        ],
      ),
    );
  }

  void _confirmDeleteAll(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Xóa tất cả cảnh báo?'),
        content: const Text(
          'Toàn bộ cảnh báo sẽ bị xóa vĩnh viễn khỏi tài khoản. '
          'Thao tác này không thể hoàn tác.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.destructive,
              foregroundColor: Colors.white,
            ),
            onPressed: () async {
              Navigator.pop(ctx);
              await SOSRealtimeService().deleteAllAlerts();
            },
            child: const Text('Xóa tất cả'),
          ),
        ],
      ),
    );
  }

  void _confirmDeleteSelected(List<_Alert> all) {
    final targets = all.where((a) => _selectedKeys.contains(a.key)).toList();
    if (targets.isEmpty) return;
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Xóa ${targets.length} cảnh báo?'),
        content: const Text(
          'Các cảnh báo đã chọn (kèm ảnh) sẽ bị xóa vĩnh viễn. '
          'Thao tác này không thể hoàn tác.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.destructive,
              foregroundColor: Colors.white,
            ),
            onPressed: () async {
              Navigator.pop(ctx);
              final svc = SOSRealtimeService();
              for (final a in targets) {
                await svc.deleteAlert(
                  a.key,
                  imageUrl: a.imageUrl,
                  deviceId: a.deviceId,
                  createdAt: a.createdAt.millisecondsSinceEpoch,
                );
              }
              if (mounted) _exitSelect();
            },
            child: const Text('Xóa'),
          ),
        ],
      ),
    );
  }
}

// ── Header ──────────────────────────────────────────────────────────────────
class _Header extends StatelessWidget {
  final int totalUnread;
  final bool hasItems;
  final VoidCallback onMarkAll;
  final VoidCallback onDeleteAll;
  final VoidCallback onSelect;
  const _Header({
    required this.totalUnread,
    required this.hasItems,
    required this.onMarkAll,
    required this.onDeleteAll,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 12, 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Cảnh báo',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: AppColors.foreground,
                    letterSpacing: -0.3,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  totalUnread == 0
                      ? 'Tất cả đã được đọc'
                      : '$totalUnread cảnh báo chưa đọc',
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.mutedForeground,
                  ),
                ),
              ],
            ),
          ),
          if (hasItems)
            PopupMenuButton<String>(
              position: PopupMenuPosition.under,
              icon: const Icon(LucideIcons.moreVertical,
                  color: AppColors.foreground),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                side: const BorderSide(color: AppColors.border),
              ),
              color: AppColors.card,
              onSelected: (v) {
                if (v == 'read_all') onMarkAll();
                if (v == 'delete_all') onDeleteAll();
                if (v == 'select') onSelect();
              },
              itemBuilder: (_) => [
                PopupMenuItem(
                  value: 'read_all',
                  enabled: totalUnread > 0,
                  child: const Row(
                    children: [
                      Icon(LucideIcons.checkCheck,
                          size: 16, color: AppColors.foreground),
                      SizedBox(width: 10),
                      Text('Đánh dấu tất cả đã đọc'),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'select',
                  child: Row(
                    children: [
                      Icon(Icons.checklist,
                          size: 16, color: AppColors.foreground),
                      SizedBox(width: 10),
                      Text('Chọn để xóa'),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'delete_all',
                  child: Row(
                    children: [
                      Icon(LucideIcons.trash2,
                          size: 16, color: AppColors.destructive),
                      SizedBox(width: 10),
                      Text(
                        'Xóa tất cả',
                        style: TextStyle(color: AppColors.destructive),
                      ),
                    ],
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }
}

// ── Selection bar (chế độ chọn nhiều để xóa) ─────────────────────────────────
class _SelectionBar extends StatelessWidget {
  final int count;
  final bool allSelected;
  final VoidCallback onCancel;
  final VoidCallback onToggleAll;
  final VoidCallback? onDelete;
  const _SelectionBar({
    required this.count,
    required this.allSelected,
    required this.onCancel,
    required this.onToggleAll,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(6, 12, 12, 8),
      child: Row(
        children: [
          IconButton(
            onPressed: onCancel,
            icon: const Icon(Icons.close, color: AppColors.foreground),
            tooltip: 'Hủy',
          ),
          Expanded(
            child: Text(
              count == 0 ? 'Chọn cảnh báo' : 'Đã chọn $count',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: AppColors.foreground,
              ),
            ),
          ),
          TextButton(
            onPressed: onToggleAll,
            child: Text(allSelected ? 'Bỏ chọn' : 'Chọn tất cả'),
          ),
          const SizedBox(width: 4),
          ElevatedButton.icon(
            onPressed: onDelete,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.destructive,
              foregroundColor: Colors.white,
              disabledBackgroundColor: AppColors.destructiveSoft,
            ),
            icon: const Icon(LucideIcons.trash2, size: 16),
            label: const Text('Xóa'),
          ),
        ],
      ),
    );
  }
}

// ── Time filter ─────────────────────────────────────────────────────────────
class _TimeFilterBar extends StatelessWidget {
  final _TimeFilter selected;
  final Map<_TimeFilter, int> counts;
  final ValueChanged<_TimeFilter> onChanged;
  const _TimeFilterBar({
    required this.selected,
    required this.counts,
    required this.onChanged,
  });

  static const _items = [
    (_TimeFilter.today, 'Hôm nay'),
    (_TimeFilter.week, '7 ngày'),
    (_TimeFilter.month, '30 ngày'),
    (_TimeFilter.all, 'Tất cả'),
  ];

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          for (final item in _items) ...[
            _TimePill(
              label: item.$2,
              count: counts[item.$1] ?? 0,
              selected: selected == item.$1,
              onTap: () => onChanged(item.$1),
            ),
            const SizedBox(width: 8),
          ],
        ],
      ),
    );
  }
}

class _TimePill extends StatelessWidget {
  final String label;
  final int count;
  final bool selected;
  final VoidCallback onTap;
  const _TimePill({
    required this.label,
    required this.count,
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
              const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: selected
                      ? Colors.white
                      : AppColors.foreground,
                ),
              ),
              const SizedBox(width: 5),
              Text(
                '$count',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: selected
                      ? Colors.white.withValues(alpha: 0.7)
                      : AppColors.gray400,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Status toggle ───────────────────────────────────────────────────────────
class _StatusToggle extends StatelessWidget {
  final bool onlyUnread;
  final ValueChanged<bool> onChanged;
  const _StatusToggle(
      {required this.onlyUnread, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Material(
          color: onlyUnread ? AppColors.secondary : Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppTheme.radiusFull),
            side: BorderSide(
                color: onlyUnread
                    ? AppColors.primary
                    : AppColors.border),
          ),
          child: InkWell(
            borderRadius: BorderRadius.circular(AppTheme.radiusFull),
            onTap: () => onChanged(!onlyUnread),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                  horizontal: 10, vertical: 6),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    onlyUnread
                        ? LucideIcons.checkSquare
                        : LucideIcons.square,
                    size: 14,
                    color: onlyUnread
                        ? AppColors.primary
                        : AppColors.mutedForeground,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'Chỉ hiển thị chưa đọc',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: onlyUnread
                          ? AppColors.primary
                          : AppColors.mutedForeground,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// ── Alert card ──────────────────────────────────────────────────────────────
class _AlertCard extends StatelessWidget {
  final _Alert alert;
  final bool selectMode;
  final bool selected;
  final VoidCallback onTap;
  final VoidCallback onToggleSelect;
  final VoidCallback onLongPress;
  final VoidCallback onDelete;

  const _AlertCard({
    required this.alert,
    required this.onTap,
    required this.onDelete,
    required this.onToggleSelect,
    required this.onLongPress,
    this.selectMode = false,
    this.selected = false,
  });

  @override
  Widget build(BuildContext context) {
    final card = Material(
      color: selected
          ? AppColors.primary.withValues(alpha: 0.06)
          : AppColors.card,
      borderRadius: BorderRadius.circular(AppTheme.radiusLg),
      child: InkWell(
        onTap: selectMode ? onToggleSelect : onTap,
        onLongPress: selectMode ? null : onLongPress,
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppTheme.radiusLg),
            border: Border.all(
              color: selected ? AppColors.primary : AppColors.border,
              width: selected ? 1.5 : 1.0,
            ),
          ),
          padding: const EdgeInsets.all(12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (selectMode) ...[
                Icon(
                  selected
                      ? Icons.check_circle
                      : Icons.radio_button_unchecked,
                  color:
                      selected ? AppColors.primary : AppColors.mutedForeground,
                  size: 22,
                ),
                const SizedBox(width: 10),
              ],
              _Thumbnail(alert: alert),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Text(
                              alert.hiveName,
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: AppColors.foreground,
                                letterSpacing: -0.1,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            DateFormat('HH:mm').format(alert.createdAt),
                            style: const TextStyle(
                              fontSize: 11,
                              color: AppColors.mutedForeground,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          if (!alert.isRead) ...[
                            const SizedBox(width: 6),
                            Container(
                              margin: const EdgeInsets.only(top: 5),
                              width: 7,
                              height: 7,
                              decoration: const BoxDecoration(
                                color: AppColors.primary,
                                shape: BoxShape.circle,
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Phát hiện ${alert.detectionCount} con ong bắp cày '
                        '· Độ tin cậy ${(alert.confidence * 100).toStringAsFixed(0)}%',
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.mutedForeground,
                          height: 1.4,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          _StatusChip(status: alert.status),
                          if (alert.detectionCount >= 3) ...[
                            const SizedBox(width: 6),
                            _SeverityChip(),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      );

    if (selectMode) return card;

    return Dismissible(
      key: ValueKey('alert-${alert.key}'),
      direction: DismissDirection.endToStart,
      confirmDismiss: (_) async {
        onDelete();
        return false; // chính xóa qua dialog confirm; không tự dismiss
      },
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        decoration: BoxDecoration(
          color: AppColors.destructiveSoft,
          borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        ),
        child: const Icon(LucideIcons.trash2,
            color: AppColors.destructive, size: 22),
      ),
      child: card,
    );
  }
}

class _Thumbnail extends StatelessWidget {
  final _Alert alert;
  const _Thumbnail({required this.alert});

  @override
  Widget build(BuildContext context) {
    if (alert.imageUrl != null) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        child: CachedImage(
          imageUrl: alert.imageUrl!,
          width: 56,
          height: 56,
        ),
      );
    }
    return Container(
      width: 56,
      height: 56,
      decoration: BoxDecoration(
        color: AppColors.destructiveSoft,
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
      ),
      alignment: Alignment.center,
      child: const Icon(LucideIcons.shieldAlert,
          size: 22, color: AppColors.destructive),
    );
  }
}

class _StatusChip extends StatelessWidget {
  final String status;
  const _StatusChip({required this.status});

  @override
  Widget build(BuildContext context) {
    final (bg, fg, label) = switch (status) {
      'active' => (AppColors.destructiveSoft, AppColors.destructive,
            'Đang cảnh báo'),
      'acknowledged' => (AppColors.warningSoft, AppColors.warning, 'Đã xem'),
      _ => (AppColors.successSoft, AppColors.success, 'Đã xử lý'),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(AppTheme.radiusFull),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          color: fg,
        ),
      ),
    );
  }
}

class _SeverityChip extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: AppColors.gray100,
        borderRadius: BorderRadius.circular(AppTheme.radiusFull),
      ),
      child: const Text(
        'Nghiêm trọng',
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w600,
          color: AppColors.gray700,
        ),
      ),
    );
  }
}

// ── Detail bottom sheet ─────────────────────────────────────────────────────
class _DetailSheet extends StatelessWidget {
  final _Alert alert;
  final VoidCallback onAcknowledge;
  final VoidCallback onDelete;

  const _DetailSheet({
    required this.alert,
    required this.onAcknowledge,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final timeStr =
        DateFormat("d/M/yyyy '·' HH:mm", 'vi').format(alert.createdAt);
    final isActive = alert.status == 'active';

    return Container(
      decoration: const BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            margin: const EdgeInsets.only(top: 10, bottom: 4),
            width: 36,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.gray300,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Phát hiện ong bắp cày',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                                color: AppColors.foreground,
                                letterSpacing: -0.2,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              alert.hiveName,
                              style: const TextStyle(
                                fontSize: 13,
                                color: AppColors.mutedForeground,
                              ),
                            ),
                          ],
                        ),
                      ),
                      _StatusChip(status: alert.status),
                    ],
                  ),
                  const SizedBox(height: 16),
                  if (alert.imageUrl != null) ...[
                    ClipRRect(
                      borderRadius:
                          BorderRadius.circular(AppTheme.radiusLg),
                      child: AspectRatio(
                        aspectRatio: 16 / 10,
                        child: CachedImage(
                          imageUrl: alert.imageUrl!,
                          width: double.infinity,
                          height: double.infinity,
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                  ],
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppColors.background,
                      borderRadius:
                          BorderRadius.circular(AppTheme.radiusLg),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Column(
                      children: [
                        _InfoRow(
                          icon: LucideIcons.alertTriangle,
                          label: 'Số lượng phát hiện',
                          value:
                              '${alert.detectionCount} con ong bắp cày',
                          color: AppColors.destructive,
                        ),
                        const Divider(
                            height: 18, color: AppColors.border),
                        _InfoRow(
                          icon: LucideIcons.target,
                          label: 'Độ tin cậy',
                          value:
                              '${(alert.confidence * 100).toStringAsFixed(0)}%',
                          color: AppColors.success,
                        ),
                        const Divider(
                            height: 18, color: AppColors.border),
                        _InfoRow(
                          icon: LucideIcons.clock,
                          label: 'Thời gian',
                          value: timeStr,
                          color: AppColors.primary,
                        ),
                        const Divider(
                            height: 18, color: AppColors.border),
                        _InfoRow(
                          icon: LucideIcons.cpu,
                          label: 'Thiết bị',
                          value: alert.deviceId,
                          color: AppColors.mutedForeground,
                          mono: true,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () {
                            onDelete();
                          },
                          icon: const Icon(LucideIcons.trash2, size: 16),
                          label: const Text('Xóa'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppColors.destructive,
                            side: const BorderSide(
                                color: AppColors.destructive),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        flex: 2,
                        child: FilledButton.icon(
                          onPressed: isActive
                              ? () {
                                  onAcknowledge();
                                  Navigator.pop(context);
                                }
                              : null,
                          icon:
                              const Icon(LucideIcons.checkCircle, size: 16),
                          label: Text(
                            isActive ? 'Đánh dấu đã xử lý' : 'Đã xử lý',
                          ),
                          style: FilledButton.styleFrom(
                            backgroundColor: AppColors.success,
                            disabledBackgroundColor: AppColors.gray200,
                          ),
                        ),
                      ),
                    ],
                  ),
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
  final Color color;
  final bool mono;
  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
    this.mono = false,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 15, color: color),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 13,
              color: AppColors.mutedForeground,
            ),
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: AppColors.foreground,
            fontFamily: mono ? 'monospace' : null,
          ),
        ),
      ],
    );
  }
}

// ── Empty state ─────────────────────────────────────────────────────────────
class _EmptyState extends StatelessWidget {
  final bool hasAny;
  const _EmptyState({required this.hasAny});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 24),
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(AppTheme.radiusLg),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: AppColors.muted,
                borderRadius: BorderRadius.circular(AppTheme.radiusFull),
              ),
              alignment: Alignment.center,
              child: const Icon(LucideIcons.bellOff,
                  size: 22, color: AppColors.gray500),
            ),
            const SizedBox(height: 14),
            Text(
              hasAny
                  ? 'Không có cảnh báo nào khớp bộ lọc'
                  : 'Chưa có cảnh báo nào',
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppColors.foreground,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              hasAny
                  ? 'Thử đổi khoảng thời gian hoặc tắt bộ lọc'
                  : 'Hệ thống sẽ thông báo khi phát hiện ong bắp cày',
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.mutedForeground,
                height: 1.4,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
