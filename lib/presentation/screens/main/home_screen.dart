import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../config/app_colors.dart';
import '../../../config/app_routes.dart';
import '../../../config/app_theme.dart';

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
  _HiveFilter _filter = _HiveFilter.all;

  FirebaseDatabase get _db => FirebaseDatabase.instanceFor(
        app: Firebase.app(),
        databaseURL: _kDbUrl,
      );

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() => setState(
        () => _search = _searchController.text.trim().toLowerCase()));
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
      backgroundColor: AppColors.background,
      body: SafeArea(
        bottom: false,
        child: uid == null
            ? const Center(child: Text('Chưa đăng nhập'))
            : StreamBuilder<DatabaseEvent>(
                stream: _db
                    .ref('tracking_devices')
                    .orderByChild('owner_uid')
                    .equalTo(uid)
                    .onValue,
                builder: (context, snapshot) {
                  final devices = _parseDevices(snapshot.data?.snapshot.value);
                  final filtered = _applyFilters(devices);

                  return CustomScrollView(
                    physics: const BouncingScrollPhysics(),
                    slivers: [
                      SliverToBoxAdapter(child: _Header(uid: uid)),
                      SliverToBoxAdapter(
                        child: Padding(
                          padding:
                              const EdgeInsets.fromLTRB(20, 0, 20, 16),
                          child: _StatsRow(uid: uid, devices: devices),
                        ),
                      ),
                      SliverToBoxAdapter(
                        child: Padding(
                          padding:
                              const EdgeInsets.fromLTRB(20, 0, 20, 20),
                          child: _PrimaryAction(
                            onTap: () =>
                                context.push(AppRoutes.qrScanner),
                          ),
                        ),
                      ),
                      SliverToBoxAdapter(
                        child: Padding(
                          padding:
                              const EdgeInsets.fromLTRB(20, 4, 20, 12),
                          child: _SectionHeader(
                            title: 'Thùng ong',
                            count: devices.length,
                          ),
                        ),
                      ),
                      SliverToBoxAdapter(
                        child: Padding(
                          padding:
                              const EdgeInsets.fromLTRB(20, 0, 20, 12),
                          child: _SearchField(
                              controller: _searchController),
                        ),
                      ),
                      SliverToBoxAdapter(
                        child: _FilterChips(
                          selected: _filter,
                          onChanged: (f) => setState(() => _filter = f),
                          counts: _countByFilter(devices),
                        ),
                      ),
                      const SliverToBoxAdapter(child: SizedBox(height: 12)),
                      if (snapshot.connectionState ==
                              ConnectionState.waiting &&
                          devices.isEmpty)
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
                          child: Padding(
                            padding:
                                const EdgeInsets.fromLTRB(20, 8, 20, 0),
                            child: _EmptyHives(
                              hasAny: devices.isNotEmpty,
                              onScan: () => context
                                  .push(AppRoutes.qrScanner),
                            ),
                          ),
                        )
                      else
                        SliverPadding(
                          padding: const EdgeInsets.fromLTRB(20, 4, 20, 32),
                          sliver: SliverGrid(
                            gridDelegate:
                                const SliverGridDelegateWithMaxCrossAxisExtent(
                              // Giữ độ rộng card ~220 → 2 cột trên điện thoại,
                              // 3–4 cột trên tablet lớn để chữ cân đối, không bị nhỏ.
                              maxCrossAxisExtent: 220,
                              childAspectRatio: 0.95,
                              crossAxisSpacing: 12,
                              mainAxisSpacing: 12,
                            ),
                            delegate: SliverChildBuilderDelegate(
                              (_, i) => _HiveCard(device: filtered[i]),
                              childCount: filtered.length,
                            ),
                          ),
                        ),
                      const SliverToBoxAdapter(child: SizedBox(height: 88)),
                    ],
                  );
                },
              ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push(AppRoutes.qrScanner),
        backgroundColor: AppColors.gray900,
        foregroundColor: Colors.white,
        elevation: 2,
        icon: const Icon(LucideIcons.qrCode, size: 18),
        label: const Text(
          'Quét QR',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusFull),
        ),
      ),
    );
  }

  // ── parsing + filters ─────────────────────────────────────────────────────
  List<Map<String, dynamic>> _parseDevices(dynamic raw) {
    if (raw == null) return const [];
    try {
      final m = Map<dynamic, dynamic>.from(raw as Map);
      final list = m.entries
          .map((e) => {
                'device_id': e.key.toString(),
                ...Map<String, dynamic>.from(e.value as Map),
              })
          .where((d) =>
              (d['hive_name'] as String? ?? '').isNotEmpty)
          .toList()
        ..sort((a, b) => ((b['created_at'] as int?) ?? 0)
            .compareTo((a['created_at'] as int?) ?? 0));
      return list;
    } catch (_) {
      return const [];
    }
  }

  List<Map<String, dynamic>> _applyFilters(
      List<Map<String, dynamic>> devices) {
    Iterable<Map<String, dynamic>> it = devices;

    switch (_filter) {
      case _HiveFilter.online:
        it = it.where((d) => (d['status'] ?? '') == 'online');
        break;
      case _HiveFilter.offline:
        it = it.where((d) =>
            (d['status'] ?? '') == 'offline' ||
            (d['status'] ?? '') == 'unregistered');
        break;
      case _HiveFilter.all:
        break;
    }

    if (_search.isNotEmpty) {
      it = it.where((d) {
        final name =
            (d['hive_name'] as String? ?? '').toLowerCase();
        final id =
            (d['device_id'] as String? ?? '').toLowerCase();
        return name.contains(_search) || id.contains(_search);
      });
    }

    return it.toList();
  }

  Map<_HiveFilter, int> _countByFilter(List<Map<String, dynamic>> ds) => {
        _HiveFilter.all: ds.length,
        _HiveFilter.online:
            ds.where((d) => (d['status'] ?? '') == 'online').length,
        _HiveFilter.offline: ds
            .where((d) =>
                (d['status'] ?? '') == 'offline' ||
                (d['status'] ?? '') == 'unregistered')
            .length,
      };
}

enum _HiveFilter { all, online, offline }

// ── Header ───────────────────────────────────────────────────────────────────
class _Header extends StatelessWidget {
  final String uid;
  const _Header({required this.uid});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
      child: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
        // Lấy tên + ảnh từ Firestore users (nguồn chính) — tránh bug userChanges() của firebase_auth
        stream: FirebaseFirestore.instance.collection('users').doc(uid).snapshots(),
        builder: (context, snap) {
          final data = snap.data?.data();
          final cu = FirebaseAuth.instance.currentUser;
          final fsName = (data?['name'] as String?)?.trim() ?? '';
          final displayName =
              fsName.isNotEmpty ? fsName : (cu?.displayName ?? '').trim();
          final firstName = displayName.isEmpty
              ? 'bạn'
              : displayName.split(' ').last;
          final fsPhoto = (data?['photoUrl'] as String?)?.trim() ?? '';
          final photoUrl =
              fsPhoto.isNotEmpty ? fsPhoto : (cu?.photoURL ?? '').trim();

          return Row(
            children: [
              _Avatar(
                photoUrl: photoUrl,
                name: displayName.isEmpty ? (cu?.email ?? '') : displayName,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Xin chào, $firstName',
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                        color: AppColors.foreground,
                        letterSpacing: -0.2,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    const Text(
                      'Tổng quan đàn ong của bạn',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.mutedForeground,
                      ),
                    ),
                  ],
                ),
              ),
              _BellButton(uid: uid),
            ],
          );
        },
      ),
    );
  }
}

class _Avatar extends StatelessWidget {
  final String photoUrl;
  final String name;
  const _Avatar({required this.photoUrl, required this.name});

  String get _initial {
    final n = name.trim();
    if (n.isNotEmpty) return n.characters.first.toUpperCase();
    return 'B';
  }

  Widget _fallback() => Container(
        color: AppColors.secondary,
        alignment: Alignment.center,
        child: Text(
          _initial,
          style: const TextStyle(
            fontWeight: FontWeight.w700,
            color: AppColors.foreground,
            fontSize: 15,
          ),
        ),
      );

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: AppColors.secondary,
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(AppTheme.radiusFull),
      ),
      clipBehavior: Clip.antiAlias,
      child: photoUrl.isEmpty
          ? _fallback()
          : Image.network(
              photoUrl,
              fit: BoxFit.cover,
              gaplessPlayback: true,
              errorBuilder: (_, __, ___) => _fallback(),
              loadingBuilder: (context, child, progress) {
                if (progress == null) return child;
                return _fallback();
              },
            ),
    );
  }
}

class _BellButton extends StatelessWidget {
  final String uid;
  const _BellButton({required this.uid});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<DatabaseEvent>(
      stream: FirebaseDatabase.instanceFor(
        app: Firebase.app(),
        databaseURL: _kDbUrl,
      ).ref('user_sos_alerts/$uid').onValue,
      builder: (context, snap) {
        int unread = 0;
        final v = snap.data?.snapshot.value;
        if (v is Map) {
          for (final e in v.values) {
            if (e is Map && e['is_read'] != true) unread++;
          }
        }

        return Stack(
          clipBehavior: Clip.none,
          children: [
            Material(
              color: AppColors.card,
              shape: RoundedRectangleBorder(
                borderRadius:
                    BorderRadius.circular(AppTheme.radiusFull),
                side: const BorderSide(color: AppColors.border),
              ),
              child: InkWell(
                customBorder: const CircleBorder(),
                onTap: () => context.go(AppRoutes.alerts),
                child: const Padding(
                  padding: EdgeInsets.all(9),
                  child: Icon(LucideIcons.bell,
                      size: 20, color: AppColors.foreground),
                ),
              ),
            ),
            if (unread > 0)
              Positioned(
                right: -2,
                top: -2,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 5, vertical: 1),
                  constraints:
                      const BoxConstraints(minWidth: 18, minHeight: 18),
                  decoration: BoxDecoration(
                    color: AppColors.destructive,
                    borderRadius: BorderRadius.circular(99),
                    border: Border.all(
                        color: AppColors.background, width: 2),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    unread > 99 ? '99+' : '$unread',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      height: 1,
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}

// ── Stats ────────────────────────────────────────────────────────────────────
class _StatsRow extends StatelessWidget {
  final String uid;
  final List<Map<String, dynamic>> devices;
  const _StatsRow({required this.uid, required this.devices});

  @override
  Widget build(BuildContext context) {
    final total = devices.length;
    final online =
        devices.where((d) => (d['status'] ?? '') == 'online').length;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          _StatCell(
            label: 'Tổng thùng',
            value: total.toString(),
            color: AppColors.foreground,
          ),
          const _StatDivider(),
          _StatCell(
            label: 'Đang chạy',
            value: online.toString(),
            color: AppColors.success,
          ),
          const _StatDivider(),
          _AlertStatCell(uid: uid),
        ],
      ),
    );
  }
}

class _StatDivider extends StatelessWidget {
  const _StatDivider();

  @override
  Widget build(BuildContext context) => Container(
        width: 1,
        height: 32,
        color: AppColors.border,
      );
}

class _StatCell extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  const _StatCell({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
        child: Column(
          children: [
            Text(
              value,
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: color,
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color: AppColors.mutedForeground,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AlertStatCell extends StatelessWidget {
  final String uid;
  const _AlertStatCell({required this.uid});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: StreamBuilder<DatabaseEvent>(
        stream: FirebaseDatabase.instanceFor(
          app: Firebase.app(),
          databaseURL: _kDbUrl,
        ).ref('user_sos_alerts/$uid').onValue,
        builder: (context, snap) {
          // Tổng số cảnh báo đã nhận (đồng nhất với trang Tài khoản).
          // Số chưa đọc vẫn hiển thị ở chấm đỏ trên chuông (_BellButton).
          int total = 0;
          final v = snap.data?.snapshot.value;
          if (v is Map) total = v.length;
          return _StatCell(
            label: 'Cảnh báo',
            value: total.toString(),
            color: AppColors.foreground,
          );
        },
      ),
    );
  }
}

// ── Primary action ───────────────────────────────────────────────────────────
class _PrimaryAction extends StatelessWidget {
  final VoidCallback onTap;
  const _PrimaryAction({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.primary,
      borderRadius: BorderRadius.circular(AppTheme.radiusLg),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.25),
                  borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                ),
                alignment: Alignment.center,
                child: const Icon(LucideIcons.qrCode,
                    size: 18, color: AppColors.primaryForeground),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Thêm thiết bị mới',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: AppColors.primaryForeground,
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'Quét mã QR trên tracker BeeGuard để liên kết',
                      style: TextStyle(
                        fontSize: 12,
                        color: Color(0xCC1A1306),
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(LucideIcons.chevronRight,
                  size: 18, color: AppColors.primaryForeground),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Section header ───────────────────────────────────────────────────────────
class _SectionHeader extends StatelessWidget {
  final String title;
  final int count;
  const _SectionHeader({required this.title, required this.count});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: AppColors.foreground,
            letterSpacing: -0.2,
          ),
        ),
        const SizedBox(width: 6),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
          decoration: BoxDecoration(
            color: AppColors.muted,
            borderRadius: BorderRadius.circular(AppTheme.radiusFull),
          ),
          child: Text(
            '$count',
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: AppColors.mutedForeground,
            ),
          ),
        ),
      ],
    );
  }
}

// ── Search ───────────────────────────────────────────────────────────────────
class _SearchField extends StatelessWidget {
  final TextEditingController controller;
  const _SearchField({required this.controller});

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      textInputAction: TextInputAction.search,
      decoration: InputDecoration(
        hintText: 'Tìm theo tên thùng hoặc mã thiết bị',
        prefixIcon: const Icon(LucideIcons.search,
            size: 18, color: AppColors.gray400),
        prefixIconConstraints:
            const BoxConstraints(minWidth: 40, minHeight: 0),
        suffixIcon: controller.text.isEmpty
            ? null
            : IconButton(
                icon: const Icon(LucideIcons.x,
                    size: 16, color: AppColors.gray500),
                onPressed: () => controller.clear(),
              ),
        isDense: true,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
      ),
    );
  }
}

// ── Filter chips ─────────────────────────────────────────────────────────────
class _FilterChips extends StatelessWidget {
  final _HiveFilter selected;
  final ValueChanged<_HiveFilter> onChanged;
  final Map<_HiveFilter, int> counts;

  const _FilterChips({
    required this.selected,
    required this.onChanged,
    required this.counts,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          _Chip(
            label: 'Tất cả',
            count: counts[_HiveFilter.all] ?? 0,
            selected: selected == _HiveFilter.all,
            onTap: () => onChanged(_HiveFilter.all),
          ),
          const SizedBox(width: 8),
          _Chip(
            label: 'Đang chạy',
            count: counts[_HiveFilter.online] ?? 0,
            selected: selected == _HiveFilter.online,
            dotColor: AppColors.success,
            onTap: () => onChanged(_HiveFilter.online),
          ),
          const SizedBox(width: 8),
          _Chip(
            label: 'Chưa kết nối',
            count: counts[_HiveFilter.offline] ?? 0,
            selected: selected == _HiveFilter.offline,
            dotColor: AppColors.gray400,
            onTap: () => onChanged(_HiveFilter.offline),
          ),
        ],
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  final String label;
  final int count;
  final bool selected;
  final Color? dotColor;
  final VoidCallback onTap;

  const _Chip({
    required this.label,
    required this.count,
    required this.selected,
    required this.onTap,
    this.dotColor,
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
              const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (dotColor != null) ...[
                Container(
                  width: 6,
                  height: 6,
                  decoration: BoxDecoration(
                    color: dotColor,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 6),
              ],
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

// ── Empty state ──────────────────────────────────────────────────────────────
class _EmptyHives extends StatelessWidget {
  final bool hasAny;
  final VoidCallback onScan;
  const _EmptyHives({required this.hasAny, required this.onScan});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppColors.muted,
              borderRadius: BorderRadius.circular(AppTheme.radiusFull),
            ),
            alignment: Alignment.center,
            child: const Icon(LucideIcons.search,
                size: 20, color: AppColors.gray500),
          ),
          const SizedBox(height: 14),
          Text(
            hasAny
                ? 'Không có thùng nào khớp bộ lọc'
                : 'Chưa có thùng ong nào',
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppColors.foreground,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            hasAny
                ? 'Thử bỏ filter hoặc xoá ô tìm kiếm'
                : 'Quét mã QR thiết bị để bắt đầu theo dõi',
            style: const TextStyle(
              fontSize: 12,
              color: AppColors.mutedForeground,
            ),
            textAlign: TextAlign.center,
          ),
          if (!hasAny) ...[
            const SizedBox(height: 16),
            OutlinedButton.icon(
              onPressed: onScan,
              icon: const Icon(LucideIcons.qrCode, size: 16),
              label: const Text('Quét QR ngay'),
            ),
          ],
        ],
      ),
    );
  }
}

// ── Hive card ────────────────────────────────────────────────────────────────
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
      'online' => (AppColors.success, 'Online', AppColors.successSoft),
      'offline' => (AppColors.gray500, 'Offline', AppColors.muted),
      _ => (AppColors.warning, 'Chưa kết nối', AppColors.warningSoft),
    };

    return Material(
      color: AppColors.card,
      borderRadius: BorderRadius.circular(AppTheme.radiusLg),
      child: InkWell(
        onTap: () => context.push('/hive/$deviceId'),
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppTheme.radiusLg),
            border: Border.all(color: AppColors.border),
          ),
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: AppColors.secondary,
                      borderRadius:
                          BorderRadius.circular(AppTheme.radiusMd),
                    ),
                    alignment: Alignment.center,
                    child: Image.asset(
                      'assets/images/beeguard_logo.png',
                      width: 20,
                      height: 20,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 7, vertical: 2),
                    decoration: BoxDecoration(
                      color: statusBg,
                      borderRadius:
                          BorderRadius.circular(AppTheme.radiusFull),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 5,
                          height: 5,
                          decoration: BoxDecoration(
                            color: statusColor,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          statusLabel,
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: statusColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                hiveName,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: AppColors.foreground,
                  letterSpacing: -0.1,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 2),
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
                  const Icon(LucideIcons.clock,
                      size: 11, color: AppColors.gray400),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      _relativeTime(lastSeen),
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppColors.mutedForeground,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _relativeTime(int ms) {
    if (ms == 0) return 'Chưa kết nối';
    final diff = DateTime.now().millisecondsSinceEpoch - ms;
    if (diff < 60000) return 'Vừa xong';
    if (diff < 3600000) return '${diff ~/ 60000} phút trước';
    if (diff < 86400000) return '${diff ~/ 3600000} giờ trước';
    return '${diff ~/ 86400000} ngày trước';
  }
}
