import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../config/app_colors.dart';
import '../../../config/app_routes.dart';
import '../../../data/models/user_model.dart';
import '../../../data/datasources/auth_service.dart';
import '../../../core/widgets/app_card.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _authService = AuthService();
  UserModel? _user;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUser();
  }

  Future<void> _loadUser() async {
    try {
      final user = await _authService.getCurrentUserModel();
      if (mounted) setState(() { _user = user; _isLoading = false; });
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _signOut() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Đăng xuất'),
        content: const Text('Bạn có chắc muốn đăng xuất không?'),
        actions: [
          TextButton(
            onPressed: () => ctx.pop(false),
            child: const Text('Hủy'),
          ),
          TextButton(
            onPressed: () => ctx.pop(true),
            child: const Text(
              'Đăng xuất',
              style: TextStyle(color: AppColors.destructive),
            ),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    await _authService.signOut();
    // Router tự redirect về /login nhờ refreshListenable
    if (mounted) context.go(AppRoutes.login);
  }

  Future<void> _editName() async {
    final controller = TextEditingController(text: _user?.name ?? '');
    final newName = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Chỉnh sửa tên'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(hintText: 'Nhập tên của bạn'),
        ),
        actions: [
          TextButton(onPressed: () => ctx.pop(), child: const Text('Hủy')),
          TextButton(
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
        setState(() { _user = _user?.copyWith(name: newName); });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Cập nhật tên thành công'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Cập nhật thất bại: $e'),
            backgroundColor: AppColors.destructive,
          ),
        );
      }
    }
  }

  Future<void> _pickAndUploadAvatar() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 512,
      maxHeight: 512,
      imageQuality: 80,
    );
    if (picked == null) return;

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Đang tải ảnh lên...'),
          duration: Duration(seconds: 10),
        ),
      );
    }

    try {
      // Dùng readAsBytes() để hoạt động trên cả Mobile lẫn Web
      final bytes = await picked.readAsBytes();
      final url = await _authService.uploadAvatar(bytes);
      if (mounted) {
        setState(() { _user = _user?.copyWith(photoUrl: url); });
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Cập nhật ảnh đại diện thành công'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Tải ảnh thất bại: $e'),
            backgroundColor: AppColors.destructive,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header
                    Padding(
                      padding: const EdgeInsets.fromLTRB(24, 48, 24, 32),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Hồ sơ',
                            style: Theme.of(context).textTheme.headlineLarge,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Quản lý tài khoản và tùy chọn của bạn',
                            style: Theme.of(context)
                                .textTheme
                                .bodyMedium
                                ?.copyWith(color: AppColors.mutedForeground),
                          ),
                        ],
                      ),
                    ),

                    // User Card
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: _UserCard(
                        user: _user,
                        onEditAvatar: _pickAndUploadAvatar,
                      ),
                    ),
                    const SizedBox(height: 32),

                    // Menu Sections
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Column(
                        children: [
                          _MenuSection(
                            title: 'Tài khoản',
                            items: [
                              _MenuItem(
                                icon: LucideIcons.user,
                                label: 'Chỉnh sửa tên',
                                value: _user?.name ?? '',
                                onTap: _editName,
                              ),
                              _MenuItem(
                                icon: LucideIcons.mail,
                                label: 'Email',
                                value: _user?.email ?? '',
                                onTap: () {},
                              ),
                              _MenuItem(
                                icon: LucideIcons.bell,
                                label: 'Cài đặt thông báo',
                                onTap: () {},
                              ),
                            ],
                          ),
                          const SizedBox(height: 24),
                          _MenuSection(
                            title: 'Tùy chọn',
                            items: [
                              _MenuItem(
                                icon: LucideIcons.moon,
                                label: 'Chế độ tối',
                                hasToggle: true,
                                toggleValue: false,
                                onTap: () {},
                              ),
                              _MenuItem(
                                icon: LucideIcons.globe,
                                label: 'Ngôn ngữ',
                                value: 'Tiếng Việt',
                                onTap: () {},
                              ),
                            ],
                          ),
                          const SizedBox(height: 24),
                          _MenuSection(
                            title: 'Dữ liệu',
                            items: [
                              _MenuItem(
                                icon: LucideIcons.download,
                                label: 'Xuất dữ liệu (PDF/CSV)',
                                onTap: () {},
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 32),

                    // Nút đăng xuất
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: GestureDetector(
                        onTap: _signOut,
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: AppColors.card,
                            borderRadius: BorderRadius.circular(24),
                            border: Border.all(color: AppColors.border),
                          ),
                          child: const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                LucideIcons.logOut,
                                size: 20,
                                color: AppColors.destructive,
                              ),
                              SizedBox(width: 12),
                              Text(
                                'Đăng xuất',
                                style: TextStyle(
                                  color: AppColors.destructive,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 32),

                    // App Info
                    Center(
                      child: Column(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: const Icon(
                              LucideIcons.hexagon,
                              size: 32,
                              color: AppColors.primary,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'BeeGuard v1.0.0',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '© 2026 BeeGuard',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                          const SizedBox(height: 16),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              TextButton(
                                onPressed: () {},
                                child: const Text('Chính sách bảo mật'),
                              ),
                              const Text(
                                '|',
                                style: TextStyle(color: AppColors.mutedForeground),
                              ),
                              TextButton(
                                onPressed: () {},
                                child: const Text('Điều khoản dịch vụ'),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 100),
                  ],
                ),
              ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Widgets nội bộ
// ---------------------------------------------------------------------------

class _UserCard extends StatelessWidget {
  final UserModel? user;
  final VoidCallback onEditAvatar;

  const _UserCard({required this.user, required this.onEditAvatar});

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
      child: Column(
        children: [
          Row(
            children: [
              GestureDetector(
                onTap: onEditAvatar,
                child: Stack(
                  children: [
                    Container(
                      width: 64,
                      height: 64,
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.2),
                        shape: BoxShape.circle,
                      ),
                      child: (user?.photoUrl != null &&
                              user!.photoUrl.isNotEmpty)
                          ? ClipOval(
                              child: Image.network(
                                user!.photoUrl,
                                width: 64,
                                height: 64,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) {
                                  return const Center(
                                    child: Icon(
                                      LucideIcons.user,
                                      size: 32,
                                      color: AppColors.primary,
                                    ),
                                  );
                                },
                                loadingBuilder:
                                    (context, child, loadingProgress) {
                                  if (loadingProgress == null) return child;
                                  return const Center(
                                    child: SizedBox(
                                      width: 24,
                                      height: 24,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: AppColors.primary,
                                      ),
                                    ),
                                  );
                                },
                              ),
                            )
                          : const Icon(
                              LucideIcons.user,
                              size: 32,
                              color: AppColors.primary,
                            ),
                    ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(
                          color: AppColors.primary,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          LucideIcons.camera,
                          size: 12,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      user?.name ?? 'Người dùng',
                      style: Theme.of(context).textTheme.titleMedium,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      user?.email ?? '',
                      style: Theme.of(context).textTheme.bodySmall,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.only(top: 16),
            decoration: BoxDecoration(
              border: Border(
                top: BorderSide(
                  color: AppColors.primary.withValues(alpha: 0.1),
                ),
              ),
            ),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _StatItem(value: '0', label: 'Tổ ong'),
                _StatItem(value: '0 kg', label: 'Mật ong'),
                _StatItem(value: '--', label: 'Sức khỏe'),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final String value;
  final String label;

  const _StatItem({required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(value, style: Theme.of(context).textTheme.headlineSmall),
        const SizedBox(height: 4),
        Text(label, style: Theme.of(context).textTheme.bodySmall),
      ],
    );
  }
}

class _MenuSection extends StatelessWidget {
  final String title;
  final List<_MenuItem> items;

  const _MenuSection({required this.title, required this.items});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 8, bottom: 12),
          child: Text(title, style: Theme.of(context).textTheme.bodySmall),
        ),
        AppCard(
          padding: EdgeInsets.zero,
          child: Column(
            children: items.asMap().entries.map((entry) {
              final index = entry.key;
              final item = entry.value;
              return Column(
                children: [
                  item,
                  if (index < items.length - 1)
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 16),
                      child: Divider(height: 1),
                    ),
                ],
              );
            }).toList(),
          ),
        ),
      ],
    );
  }
}

class _MenuItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String? value;
  final bool hasToggle;
  final bool toggleValue;
  final VoidCallback onTap;

  const _MenuItem({
    required this.icon,
    required this.label,
    this.value,
    this.hasToggle = false,
    this.toggleValue = false,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(icon, size: 20, color: AppColors.mutedForeground),
            const SizedBox(width: 12),
            Expanded(
              child: Text(label, style: Theme.of(context).textTheme.bodyLarge),
            ),
            if (hasToggle)
              Switch(value: toggleValue, onChanged: (_) => onTap())
            else
              Row(
                children: [
                  if (value != null)
                    Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 120),
                        child: Text(
                          value!,
                          style: Theme.of(context).textTheme.bodySmall,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ),
                  const Icon(
                    LucideIcons.chevronRight,
                    size: 20,
                    color: AppColors.mutedForeground,
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}
