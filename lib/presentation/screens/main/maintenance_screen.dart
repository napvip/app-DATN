import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../config/app_colors.dart';
import '../../../config/app_routes.dart';
import '../../../data/models/service_booking_model.dart';
import '../../../data/datasources/maintenance_service.dart';
import '../../../core/widgets/app_card.dart';

class MaintenanceScreen extends StatefulWidget {
  const MaintenanceScreen({super.key});

  @override
  State<MaintenanceScreen> createState() => _MaintenanceScreenState();
}

class _MaintenanceScreenState extends State<MaintenanceScreen>
    with SingleTickerProviderStateMixin {
  String _activeTab = 'upcoming';
  final _maintenanceService = MaintenanceService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Bảo trì',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                        color: AppColors.foreground,
                        letterSpacing: -0.3,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Đặt lịch dịch vụ & hỗ trợ kỹ thuật',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: AppColors.mutedForeground,
                            fontSize: 12,
                          ),
                    ),
                  ],
                ),
              ),

              // Quick Actions
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  children: [
                    Expanded(
                      child: _QuickActionButton(
                        icon: LucideIcons.calendar,
                        label: 'Đặt lịch',
                        isPrimary: true,
                        onTap: () =>
                            context.push(AppRoutes.bookService),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _QuickActionButton(
                        icon: LucideIcons.messageCircle,
                        label: 'Hỗ trợ',
                        isPrimary: false,
                        onTap: () => context.push(AppRoutes.chat),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Stats Bar
              _StatsBar(maintenanceService: _maintenanceService),
              const SizedBox(height: 24),

              // Tabs
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: AppColors.muted,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: _TabButton(
                          label: 'Sắp tới',
                          isSelected: _activeTab == 'upcoming',
                          onTap: () =>
                              setState(() => _activeTab = 'upcoming'),
                        ),
                      ),
                      Expanded(
                        child: _TabButton(
                          label: 'Lịch sử',
                          isSelected: _activeTab == 'history',
                          onTap: () =>
                              setState(() => _activeTab = 'history'),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Content
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: _activeTab == 'upcoming'
                    ? _UpcomingBookings(
                        maintenanceService: _maintenanceService,
                        onReschedule: _showRescheduleDialog,
                        onCancel: _showCancelDialog,
                      )
                    : _BookingHistory(
                        maintenanceService: _maintenanceService,
                      ),
              ),
              const SizedBox(height: 100),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _showRescheduleDialog(ServiceBookingModel booking) async {
    DateTime? newDate;
    TimeOfDay? newTime;
    final reasonController = TextEditingController();

    final confirmed = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                left: 24,
                right: 24,
                top: 24,
                bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: AppColors.muted,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'Đổi lịch dịch vụ',
                    style: Theme.of(ctx).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Chọn ngày và giờ mới cho "${booking.title}"',
                    style: Theme.of(ctx).textTheme.bodySmall,
                  ),
                  const SizedBox(height: 24),
                  GestureDetector(
                    onTap: () async {
                      final date = await showDatePicker(
                        context: ctx,
                        initialDate:
                            DateTime.now().add(const Duration(days: 1)),
                        firstDate: DateTime.now(),
                        lastDate:
                            DateTime.now().add(const Duration(days: 90)),
                        builder: (context, child) {
                          return Theme(
                            data: Theme.of(context).copyWith(
                              colorScheme: const ColorScheme.light(
                                primary: AppColors.primary,
                                onPrimary: AppColors.primaryForeground,
                              ),
                            ),
                            child: child!,
                          );
                        },
                      );
                      if (date != null) {
                        setModalState(() => newDate = date);
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.inputBackground,
                        borderRadius: BorderRadius.circular(16),
                        border: newDate != null
                            ? Border.all(color: AppColors.primary, width: 2)
                            : null,
                      ),
                      child: Row(
                        children: [
                          Icon(
                            LucideIcons.calendar,
                            size: 20,
                            color: newDate != null
                                ? AppColors.primary
                                : AppColors.mutedForeground,
                          ),
                          const SizedBox(width: 12),
                          Text(
                            newDate != null
                                ? DateFormat('dd/MM/yyyy').format(newDate!)
                                : 'Chọn ngày mới',
                            style: TextStyle(
                              color: newDate != null
                                  ? AppColors.foreground
                                  : AppColors.mutedForeground,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  GestureDetector(
                    onTap: () async {
                      final time = await showTimePicker(
                        context: ctx,
                        initialTime: const TimeOfDay(hour: 9, minute: 0),
                        builder: (context, child) {
                          return Theme(
                            data: Theme.of(context).copyWith(
                              colorScheme: const ColorScheme.light(
                                primary: AppColors.primary,
                                onPrimary: AppColors.primaryForeground,
                              ),
                            ),
                            child: child!,
                          );
                        },
                      );
                      if (time != null) {
                        setModalState(() => newTime = time);
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.inputBackground,
                        borderRadius: BorderRadius.circular(16),
                        border: newTime != null
                            ? Border.all(color: AppColors.primary, width: 2)
                            : null,
                      ),
                      child: Row(
                        children: [
                          Icon(
                            LucideIcons.clock,
                            size: 20,
                            color: newTime != null
                                ? AppColors.primary
                                : AppColors.mutedForeground,
                          ),
                          const SizedBox(width: 12),
                          Text(
                            newTime != null
                                ? newTime!.format(ctx)
                                : 'Chọn giờ mới',
                            style: TextStyle(
                              color: newTime != null
                                  ? AppColors.foreground
                                  : AppColors.mutedForeground,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: reasonController,
                    maxLines: 2,
                    decoration: const InputDecoration(
                      hintText: 'Lý do đổi lịch (không bắt buộc)',
                    ),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.pop(ctx, false),
                          child: const Text('Hủy'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: newDate != null && newTime != null
                              ? () => Navigator.pop(ctx, true)
                              : null,
                          child: const Text('Xác nhận'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
    );

    if (confirmed == true && newDate != null && newTime != null) {
      try {
        final timeStr =
            '${newTime!.hour.toString().padLeft(2, '0')}:${newTime!.minute.toString().padLeft(2, '0')}';
        await _maintenanceService.rescheduleBooking(
          bookingId: booking.id,
          newDate: newDate!,
          newTime: timeStr,
          reason: reasonController.text.trim(),
        );
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Đổi lịch thành công!'),
              backgroundColor: AppColors.success,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              margin: const EdgeInsets.all(16),
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Lỗi: $e'),
              backgroundColor: AppColors.destructive,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              margin: const EdgeInsets.all(16),
            ),
          );
        }
      }
    }
    reasonController.dispose();
  }

  Future<void> _showCancelDialog(ServiceBookingModel booking) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Text('Hủy lịch đặt'),
        content: Text(
          'Bạn có chắc muốn hủy "${booking.title}"?\nThao tác này không thể hoàn tác.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Không, giữ lại'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.destructive,
              foregroundColor: AppColors.destructiveForeground,
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Hủy lịch'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await _maintenanceService.cancelBooking(booking.id);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Đã hủy lịch đặt'),
              backgroundColor: AppColors.destructive,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              margin: const EdgeInsets.all(16),
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Lỗi: $e'),
              backgroundColor: AppColors.destructive,
            ),
          );
        }
      }
    }
  }
}

// =============================================================================
// Stats Bar - Hiển thị thống kê nhanh
// =============================================================================

class _StatsBar extends StatelessWidget {
  final MaintenanceService maintenanceService;
  const _StatsBar({required this.maintenanceService});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<ServiceStatus, int>>(
      future: maintenanceService.getBookingStats(),
      builder: (ctx, snapshot) {
        final stats = snapshot.data ?? {};
        final pending = stats[ServiceStatus.pending] ?? 0;
        final processing = stats[ServiceStatus.processing] ?? 0;
        final completed = stats[ServiceStatus.completed] ?? 0;

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Row(
            children: [
              Expanded(
                child: _StatChip(
                  label: 'Chờ xử lý',
                  count: pending,
                  color: AppColors.warning,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _StatChip(
                  label: 'Đang xử lý',
                  count: processing,
                  color: AppColors.chart3,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _StatChip(
                  label: 'Hoàn thành',
                  count: completed,
                  color: AppColors.success,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _StatChip extends StatelessWidget {
  final String label;
  final int count;
  final Color color;

  const _StatChip({
    required this.label,
    required this.count,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.15)),
      ),
      child: Column(
        children: [
          Text(
            '$count',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: color.withValues(alpha: 0.8),
            ),
          ),
        ],
      ),
    );
  }
}

// =============================================================================
// Quick Action Button
// =============================================================================

class _QuickActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isPrimary;
  final VoidCallback onTap;

  const _QuickActionButton({
    required this.icon,
    required this.label,
    required this.isPrimary,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isPrimary ? AppColors.primary : AppColors.card,
          borderRadius: BorderRadius.circular(16),
          border: isPrimary ? null : Border.all(color: AppColors.border),
          boxShadow: isPrimary
              ? [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.2),
                    blurRadius: 16,
                    offset: const Offset(0, 4),
                  ),
                ]
              : null,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              icon,
              size: 24,
              color: isPrimary
                  ? AppColors.primaryForeground
                  : AppColors.foreground,
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: isPrimary
                    ? AppColors.primaryForeground
                    : AppColors.foreground,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// =============================================================================
// Tab Button
// =============================================================================

class _TabButton extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _TabButton({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
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
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              color: isSelected
                  ? AppColors.foreground
                  : AppColors.mutedForeground,
              fontWeight: isSelected ? FontWeight.w500 : FontWeight.w400,
            ),
          ),
        ),
      ),
    );
  }
}

// =============================================================================
// Upcoming Bookings (Stream from Firestore)
// =============================================================================

class _UpcomingBookings extends StatelessWidget {
  final MaintenanceService maintenanceService;
  final Future<void> Function(ServiceBookingModel) onReschedule;
  final Future<void> Function(ServiceBookingModel) onCancel;

  const _UpcomingBookings({
    required this.maintenanceService,
    required this.onReschedule,
    required this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<ServiceBookingModel>>(
      stream: maintenanceService.getUpcomingBookings(),
      builder: (ctx, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(40),
              child: CircularProgressIndicator(color: AppColors.primary),
            ),
          );
        }

        if (snapshot.hasError) {
          debugPrint('Upcoming bookings error: ${snapshot.error}');
          return _EmptyState(
            icon: LucideIcons.alertTriangle,
            title: 'Không tải được lịch đặt',
            subtitle: 'Vui lòng thử lại sau',
          );
        }

        final bookings = snapshot.data ?? [];

        if (bookings.isEmpty) {
          return _EmptyState(
            icon: LucideIcons.calendarOff,
            title: 'Chưa có lịch sắp tới',
            subtitle: 'Đặt lịch dịch vụ để bắt đầu',
          );
        }

        return Column(
          children: bookings
              .map((booking) => Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: _BookingCard(
                      booking: booking,
                      isHistory: false,
                      onReschedule: () => onReschedule(booking),
                      onCancel: () => onCancel(booking),
                      onTap: () =>
                          context.push('${AppRoutes.serviceDetail}/${booking.id}'),
                    ),
                  ))
              .toList(),
        );
      },
    );
  }
}

// =============================================================================
// Booking History (Stream from Firestore)
// =============================================================================

class _BookingHistory extends StatelessWidget {
  final MaintenanceService maintenanceService;

  const _BookingHistory({required this.maintenanceService});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<ServiceBookingModel>>(
      stream: maintenanceService.getBookingHistory(),
      builder: (ctx, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(40),
              child: CircularProgressIndicator(color: AppColors.primary),
            ),
          );
        }

        if (snapshot.hasError) {
          debugPrint('Booking history error: ${snapshot.error}');
          return _EmptyState(
            icon: LucideIcons.alertTriangle,
            title: 'Không tải được lịch sử',
            subtitle: 'Vui lòng thử lại sau',
          );
        }

        final bookings = snapshot.data ?? [];

        if (bookings.isEmpty) {
          return _EmptyState(
            icon: LucideIcons.history,
            title: 'Chưa có lịch sử',
            subtitle: 'Các dịch vụ đã hoàn tất sẽ hiển thị ở đây',
          );
        }

        return Column(
          children: bookings
              .map((booking) => Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: _BookingCard(
                      booking: booking,
                      isHistory: true,
                      onTap: () =>
                          context.push('${AppRoutes.serviceDetail}/${booking.id}'),
                    ),
                  ))
              .toList(),
        );
      },
    );
  }
}

// =============================================================================
// Booking Card
// =============================================================================

class _BookingCard extends StatelessWidget {
  final ServiceBookingModel booking;
  final bool isHistory;
  final VoidCallback? onReschedule;
  final VoidCallback? onCancel;
  final VoidCallback? onTap;

  const _BookingCard({
    required this.booking,
    required this.isHistory,
    this.onReschedule,
    this.onCancel,
    this.onTap,
  });

  Color _getStatusColor(ServiceStatus status) {
    switch (status) {
      case ServiceStatus.pending:
        return AppColors.warning;
      case ServiceStatus.processing:
        return AppColors.chart3;
      case ServiceStatus.completed:
        return AppColors.success;
      case ServiceStatus.cancelled:
        return AppColors.destructive;
    }
  }

  IconData _getStatusIcon(ServiceStatus status) {
    switch (status) {
      case ServiceStatus.pending:
        return LucideIcons.clock;
      case ServiceStatus.processing:
        return LucideIcons.loader;
      case ServiceStatus.completed:
        return LucideIcons.checkCircle;
      case ServiceStatus.cancelled:
        return LucideIcons.xCircle;
    }
  }

  @override
  Widget build(BuildContext context) {
    final statusColor = _getStatusColor(booking.status);

    return AppCard(
      onTap: onTap,
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      booking.title,
                      style: Theme.of(context).textTheme.titleMedium,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      booking.customerName,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      _getStatusIcon(booking.status),
                      size: 14,
                      color: statusColor,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      booking.status.label,
                      style: TextStyle(
                        color: statusColor,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              const Icon(
                LucideIcons.calendar,
                size: 16,
                color: AppColors.mutedForeground,
              ),
              const SizedBox(width: 8),
              Text(
                '${DateFormat('dd/MM/yyyy').format(booking.scheduledDate)} lúc ${booking.scheduledTime}',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],
          ),
          if (booking.technicianName.isNotEmpty) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(
                  LucideIcons.shield,
                  size: 16,
                  color: AppColors.mutedForeground,
                ),
                const SizedBox(width: 8),
                Text(
                  'Kỹ thuật viên: ${booking.technicianName}',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
            ),
          ],
          // Service type badge
          const SizedBox(height: 12),
          Row(
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  booking.serviceType.label,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: AppColors.primary,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              if (booking.rescheduleHistory.isNotEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppColors.chart5.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    'Đã đổi lịch ×${booking.rescheduleHistory.length}',
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      color: AppColors.chart5,
                    ),
                  ),
                ),
            ],
          ),
          if (!isHistory && (booking.canReschedule || booking.canCancel)) ...[
            const SizedBox(height: 16),
            Row(
              children: [
                if (booking.canReschedule)
                  Expanded(
                    child: OutlinedButton(
                      onPressed: onReschedule,
                      child: const Text('Đổi lịch'),
                    ),
                  ),
                if (booking.canReschedule && booking.canCancel)
                  const SizedBox(width: 12),
                if (booking.canCancel)
                  Expanded(
                    child: OutlinedButton(
                      onPressed: onCancel,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.destructive,
                        side: const BorderSide(
                            color: AppColors.destructive, width: 1),
                      ),
                      child: const Text('Hủy'),
                    ),
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

// =============================================================================
// Empty State
// =============================================================================

class _EmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;

  const _EmptyState({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 48),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.muted,
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 40, color: AppColors.mutedForeground),
            ),
            const SizedBox(height: 16),
            Text(
              title,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }
}

