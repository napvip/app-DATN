import 'package:firebase_auth/firebase_auth.dart' as fb_auth;
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../config/app_colors.dart';
import '../../../config/app_routes.dart';
import '../../../config/app_theme.dart';
import '../../../data/datasources/auth_service.dart';
import '../../../data/datasources/user_settings_service.dart';
import '../../../data/models/user_model.dart';

const _kDbUrl =
    'https://doan-hotronuoiong-default-rtdb.asia-southeast1.firebasedatabase.app';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _authService = AuthService();
  final _settings = UserSettingsService();

  UserModel? _user;
  bool _isLoading = true;
  int _alarmDuration = 30;
  int _alertCooldown = 60;

  @override
  void initState() {
    super.initState();
    _loadUser();
  }

  Future<void> _loadUser() async {
    try {
      final results = await Future.wait([
        _authService.getCurrentUserModel(),
        _settings.getAlarmDuration(),
        _settings.getAlertCooldown(),
      ]);
      if (mounted) {
        setState(() {
          _user = results[0] as UserModel?;
          _alarmDuration = results[1] as int;
          _alertCooldown = results[2] as int;
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // ── Snackbar helpers ──────────────────────────────────────────────────────
  void _showOk(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: AppColors.success,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showErr(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: AppColors.destructive,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  // ── Actions ───────────────────────────────────────────────────────────────
  Future<void> _editName() async {
    final controller = TextEditingController(text: _user?.name ?? '');
    final newName = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Chỉnh sửa tên'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(
            hintText: 'Tên hiển thị của bạn',
          ),
        ),
        actions: [
          TextButton(onPressed: () => ctx.pop(), child: const Text('Hủy')),
          ElevatedButton(
            onPressed: () => ctx.pop(controller.text.trim()),
            child: const Text('Lưu'),
          ),
        ],
      ),
    );
    controller.dispose();

    if (newName == null || newName.isEmpty || newName == _user?.name) return;
    try {
      await _authService.updateUserName(newName);
      if (mounted) {
        setState(() => _user = _user?.copyWith(name: newName));
        _showOk('Đã cập nhật tên');
      }
    } catch (e) {
      _showErr('Cập nhật thất bại: $e');
    }
  }

  Future<void> _pickAvatar() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 512,
      maxHeight: 512,
      imageQuality: 80,
    );
    if (picked == null) return;
    if (!mounted) return;

    final messenger = ScaffoldMessenger.of(context);
    messenger.showSnackBar(const SnackBar(
      content: Text('Đang tải ảnh lên...'),
      duration: Duration(seconds: 10),
    ));

    try {
      final bytes = await picked.readAsBytes();
      final url = await _authService.uploadAvatar(bytes);
      if (mounted) {
        setState(() => _user = _user?.copyWith(photoUrl: url));
        messenger.hideCurrentSnackBar();
        _showOk('Đã cập nhật ảnh đại diện');
      }
    } catch (e) {
      messenger.hideCurrentSnackBar();
      _showErr('Tải ảnh thất bại: $e');
    }
  }

  Future<void> _resetPassword() async {
    final email = (_user?.email ?? '').trim();
    if (email.isEmpty) {
      _showErr('Tài khoản không có email');
      return;
    }
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Đổi mật khẩu'),
        content: Text(
          'Hệ thống sẽ gửi liên kết đặt lại mật khẩu đến email '
          '$email. Bạn chắc chứ?',
        ),
        actions: [
          TextButton(
            onPressed: () => ctx.pop(false),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () => ctx.pop(true),
            child: const Text('Gửi'),
          ),
        ],
      ),
    );
    if (confirm != true) return;
    try {
      await _authService.sendPasswordResetEmail(email);
      _showOk('Đã gửi liên kết đặt lại mật khẩu');
    } catch (e) {
      _showErr('Gửi thất bại: $e');
    }
  }

  Future<void> _signOut() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Đăng xuất?'),
        content: const Text(
          'Bạn sẽ được đưa về màn hình đăng nhập. Dữ liệu trên thiết bị '
          'không bị mất.',
        ),
        actions: [
          TextButton(
            onPressed: () => ctx.pop(false),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.destructive,
              foregroundColor: Colors.white,
            ),
            onPressed: () => ctx.pop(true),
            child: const Text('Đăng xuất'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    await _authService.signOut();
    if (mounted) context.go(AppRoutes.login);
  }

  void _openNotificationSettings() {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.card,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => StatefulBuilder(
        builder: (ctx, setModal) {
          String fmt(int s) {
            if (s < 60) return '${s}s';
            final m = s ~/ 60;
            final rem = s % 60;
            return rem == 0 ? '$m phút' : '${m}p ${rem}s';
          }

          return Padding(
            padding: EdgeInsets.only(
              left: 20,
              right: 20,
              top: 16,
              bottom: MediaQuery.of(ctx).viewPadding.bottom + 24,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Cài đặt thông báo SOS',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppColors.foreground,
                    letterSpacing: -0.2,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Điều chỉnh khi nhận cảnh báo phát hiện ong bắp cày',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.mutedForeground,
                  ),
                ),
                const SizedBox(height: 20),
                _SliderTile(
                  icon: LucideIcons.bell,
                  label: 'Thời gian chuông',
                  valueLabel: '${_alarmDuration}s',
                  min: 5,
                  max: 120,
                  divisions: 23,
                  value: _alarmDuration.toDouble(),
                  onChanged: (v) async {
                    final val = v.round();
                    setModal(() {});
                    setState(() => _alarmDuration = val);
                    await _settings.setAlarmDuration(val);
                  },
                ),
                const SizedBox(height: 16),
                _SliderTile(
                  icon: LucideIcons.timer,
                  label: 'Tần suất cảnh báo',
                  valueLabel: fmt(_alertCooldown),
                  min: 3,
                  max: 600,
                  divisions: 199,
                  value: _alertCooldown.toDouble(),
                  onChanged: (v) async {
                    final val = v.round();
                    setModal(() {});
                    setState(() => _alertCooldown = val);
                    await _settings.setAlertCooldown(val);
                  },
                ),
                const SizedBox(height: 4),
                Text(
                  'Sau ${fmt(_alertCooldown)} kể từ cảnh báo trước, hệ thống mới cảnh báo tiếp.',
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppColors.mutedForeground,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  // ── UI ────────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        bottom: false,
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 96),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const _Header(),
                    const SizedBox(height: 16),
                    _UserCard(
                      user: _user,
                      onEditAvatar: _pickAvatar,
                      onEditName: _editName,
                    ),
                    const SizedBox(height: 24),
                    _SectionLabel('Tài khoản'),
                    const SizedBox(height: 8),
                    _MenuGroup(items: [
                      _MenuItemData(
                        icon: LucideIcons.user,
                        label: 'Tên hiển thị',
                        trailingText: _user?.name ?? '—',
                        onTap: _editName,
                      ),
                      _MenuItemData(
                        icon: LucideIcons.mail,
                        label: 'Email',
                        trailingText: _user?.email ?? '—',
                        readOnly: true,
                      ),
                      _MenuItemData(
                        icon: LucideIcons.key,
                        label: 'Đổi mật khẩu',
                        trailingText: 'Gửi email',
                        onTap: _resetPassword,
                      ),
                    ]),
                    const SizedBox(height: 24),
                    _SectionLabel('Cảnh báo'),
                    const SizedBox(height: 8),
                    _MenuGroup(items: [
                      _MenuItemData(
                        icon: LucideIcons.bellRing,
                        label: 'Cài đặt thông báo SOS',
                        trailingText: '${_alarmDuration}s',
                        onTap: _openNotificationSettings,
                      ),
                    ]),
                    const SizedBox(height: 24),
                    OutlinedButton.icon(
                      onPressed: _signOut,
                      icon: const Icon(LucideIcons.logOut, size: 18),
                      label: const Text('Đăng xuất'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.destructive,
                        side: const BorderSide(color: AppColors.destructive),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                    ),
                    const SizedBox(height: 32),
                    const _AppFooter(),
                  ],
                ),
              ),
      ),
    );
  }
}

// ── Header ──────────────────────────────────────────────────────────────────
class _Header extends StatelessWidget {
  const _Header();

  @override
  Widget build(BuildContext context) {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Hồ sơ',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w700,
            color: AppColors.foreground,
            letterSpacing: -0.3,
          ),
        ),
        SizedBox(height: 2),
        Text(
          'Quản lý tài khoản và cài đặt cảnh báo',
          style: TextStyle(
            fontSize: 12,
            color: AppColors.mutedForeground,
          ),
        ),
      ],
    );
  }
}

// ── User card (avatar + name + stats từ Firebase) ───────────────────────────
class _UserCard extends StatelessWidget {
  final UserModel? user;
  final VoidCallback onEditAvatar;
  final VoidCallback onEditName;

  const _UserCard({
    required this.user,
    required this.onEditAvatar,
    required this.onEditName,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          Row(
            children: [
              GestureDetector(
                onTap: onEditAvatar,
                child: Stack(
                  children: [
                    Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        color: AppColors.secondary,
                        border: Border.all(color: AppColors.border),
                        shape: BoxShape.circle,
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: (user?.photoUrl != null &&
                              user!.photoUrl.isNotEmpty)
                          ? Image.network(
                              user!.photoUrl,
                              width: 56,
                              height: 56,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) =>
                                  _initialFallback(user),
                              loadingBuilder: (_, child, p) =>
                                  p == null ? child : _initialFallback(user),
                            )
                          : _initialFallback(user),
                    ),
                    Positioned(
                      bottom: -2,
                      right: -2,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: AppColors.foreground,
                          shape: BoxShape.circle,
                          border:
                              Border.all(color: AppColors.card, width: 2),
                        ),
                        child: const Icon(LucideIcons.camera,
                            size: 10, color: Colors.white),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      user?.name ?? 'Người dùng',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: AppColors.foreground,
                        letterSpacing: -0.2,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      user?.email ?? '—',
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.mutedForeground,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: onEditName,
                icon: const Icon(LucideIcons.pencil, size: 16),
                style: IconButton.styleFrom(
                  foregroundColor: AppColors.foreground,
                  backgroundColor: AppColors.muted,
                  shape: RoundedRectangleBorder(
                    borderRadius:
                        BorderRadius.circular(AppTheme.radiusFull),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(height: 1, color: AppColors.border),
          const SizedBox(height: 12),
          _Stats(uid: fb_auth.FirebaseAuth.instance.currentUser?.uid),
        ],
      ),
    );
  }

  Widget _initialFallback(UserModel? u) {
    final n = (u?.name ?? u?.email ?? 'B').trim();
    final initial =
        n.isEmpty ? 'B' : n.characters.first.toUpperCase();
    return Container(
      width: 56,
      height: 56,
      alignment: Alignment.center,
      child: Text(
        initial,
        style: const TextStyle(
          fontSize: 22,
          fontWeight: FontWeight.w800,
          color: AppColors.foreground,
        ),
      ),
    );
  }
}

class _Stats extends StatelessWidget {
  final String? uid;
  const _Stats({required this.uid});

  @override
  Widget build(BuildContext context) {
    if (uid == null) {
      return const SizedBox.shrink();
    }
    return Row(
      children: [
        Expanded(child: _HiveCount(uid: uid!)),
        Container(
          width: 1,
          height: 28,
          color: AppColors.border,
        ),
        Expanded(child: _AlertCount(uid: uid!)),
      ],
    );
  }
}

class _HiveCount extends StatelessWidget {
  final String uid;
  const _HiveCount({required this.uid});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<DatabaseEvent>(
      stream: FirebaseDatabase.instanceFor(
        app: Firebase.app(),
        databaseURL: _kDbUrl,
      )
          .ref('tracking_devices')
          .orderByChild('owner_uid')
          .equalTo(uid)
          .onValue,
      builder: (_, snap) {
        int count = 0;
        final v = snap.data?.snapshot.value;
        if (v is Map) {
          count = v.entries
              .where((e) =>
                  e.value is Map &&
                  ((e.value as Map)['hive_name'] as String? ?? '')
                      .isNotEmpty)
              .length;
        }
        return _StatCell(value: '$count', label: 'Thùng ong');
      },
    );
  }
}

class _AlertCount extends StatelessWidget {
  final String uid;
  const _AlertCount({required this.uid});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<DatabaseEvent>(
      stream: FirebaseDatabase.instanceFor(
        app: Firebase.app(),
        databaseURL: _kDbUrl,
      ).ref('user_sos_alerts/$uid').onValue,
      builder: (_, snap) {
        int count = 0;
        final v = snap.data?.snapshot.value;
        if (v is Map) count = v.length;
        return _StatCell(value: '$count', label: 'Cảnh báo');
      },
    );
  }
}

class _StatCell extends StatelessWidget {
  final String value;
  final String label;
  const _StatCell({required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: AppColors.foreground,
            letterSpacing: -0.3,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: const TextStyle(
            fontSize: 11,
            color: AppColors.mutedForeground,
          ),
        ),
      ],
    );
  }
}

// ── Menu ────────────────────────────────────────────────────────────────────
class _SectionLabel extends StatelessWidget {
  final String label;
  const _SectionLabel(this.label);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: Text(
        label.toUpperCase(),
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: AppColors.mutedForeground,
          letterSpacing: 0.6,
        ),
      ),
    );
  }
}

class _MenuItemData {
  final IconData icon;
  final String label;
  final String? trailingText;
  final VoidCallback? onTap;
  final bool readOnly;
  _MenuItemData({
    required this.icon,
    required this.label,
    this.trailingText,
    this.onTap,
    this.readOnly = false,
  });
}

class _MenuGroup extends StatelessWidget {
  final List<_MenuItemData> items;
  const _MenuGroup({required this.items});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        border: Border.all(color: AppColors.border),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          for (var i = 0; i < items.length; i++) ...[
            _MenuRow(item: items[i]),
            if (i < items.length - 1)
              const Padding(
                padding: EdgeInsets.only(left: 52),
                child: Divider(height: 1, color: AppColors.border),
              ),
          ],
        ],
      ),
    );
  }
}

class _MenuRow extends StatelessWidget {
  final _MenuItemData item;
  const _MenuRow({required this.item});

  @override
  Widget build(BuildContext context) {
    final body = Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Row(
        children: [
          Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(
              color: AppColors.muted,
              borderRadius: BorderRadius.circular(AppTheme.radiusSm),
            ),
            alignment: Alignment.center,
            child: Icon(item.icon,
                size: 16, color: AppColors.foreground),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              item.label,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppColors.foreground,
              ),
            ),
          ),
          if (item.trailingText != null)
            Flexible(
              child: Padding(
                padding: const EdgeInsets.only(left: 8),
                child: Text(
                  item.trailingText!,
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppColors.mutedForeground,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.right,
                ),
              ),
            ),
          if (!item.readOnly) ...[
            const SizedBox(width: 6),
            const Icon(LucideIcons.chevronRight,
                size: 16, color: AppColors.gray400),
          ],
        ],
      ),
    );

    if (item.readOnly || item.onTap == null) return body;
    return InkWell(onTap: item.onTap, child: body);
  }
}

// ── Slider tile (cho bottom sheet) ──────────────────────────────────────────
class _SliderTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String valueLabel;
  final double value;
  final double min;
  final double max;
  final int divisions;
  final ValueChanged<double> onChanged;

  const _SliderTile({
    required this.icon,
    required this.label,
    required this.valueLabel,
    required this.value,
    required this.min,
    required this.max,
    required this.divisions,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 14, color: AppColors.mutedForeground),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                label,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.mutedForeground,
                ),
              ),
            ),
            Text(
              valueLabel,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: AppColors.foreground,
                fontFamily: 'monospace',
              ),
            ),
          ],
        ),
        Slider(
          value: value.clamp(min, max),
          min: min,
          max: max,
          divisions: divisions,
          activeColor: AppColors.primary,
          onChanged: onChanged,
        ),
      ],
    );
  }
}

// ── App footer ──────────────────────────────────────────────────────────────
class _AppFooter extends StatelessWidget {
  const _AppFooter();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: AppColors.secondary,
            borderRadius: BorderRadius.circular(AppTheme.radiusMd),
            border: Border.all(color: AppColors.border),
          ),
          child: Image.asset(
            'assets/images/beeguard_logo.png',
            width: 28,
            height: 28,
          ),
        ),
        const SizedBox(height: 10),
        const Text(
          'BeeGuard',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w800,
            color: AppColors.foreground,
            letterSpacing: -0.2,
          ),
        ),
        const SizedBox(height: 2),
        const Text(
          'Phiên bản 1.0.0',
          style: TextStyle(
            fontSize: 11,
            color: AppColors.mutedForeground,
          ),
        ),
        const SizedBox(height: 2),
        const Text(
          '© 2026 BeeGuard',
          style: TextStyle(
            fontSize: 11,
            color: AppColors.mutedForeground,
          ),
        ),
      ],
    );
  }
}
