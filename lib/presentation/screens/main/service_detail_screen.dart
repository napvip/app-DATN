import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../config/app_colors.dart';
import '../../../data/models/service_booking_model.dart';
import '../../../data/datasources/maintenance_service.dart';
import '../../../core/widgets/app_card.dart';

class ServiceDetailScreen extends StatefulWidget {
  final String bookingId;
  const ServiceDetailScreen({super.key, required this.bookingId});

  @override
  State<ServiceDetailScreen> createState() => _ServiceDetailScreenState();
}

class _ServiceDetailScreenState extends State<ServiceDetailScreen> {
  final _maintenanceService = MaintenanceService();
  ServiceBookingModel? _booking;
  Map<String, dynamic>? _technician; // dữ liệu KTV mới nhất từ collection technicians
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadBooking();
  }

  Future<void> _loadBooking() async {
    setState(() => _isLoading = true);
    try {
      final booking =
          await _maintenanceService.getBookingById(widget.bookingId);
      // Lấy thông tin KTV mới nhất (nếu đơn đã được gán)
      Map<String, dynamic>? tech;
      if (booking != null && booking.technicianId.isNotEmpty) {
        tech =
            await _maintenanceService.getTechnicianById(booking.technicianId);
      }
      setState(() {
        _booking = booking;
        _technician = tech;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  // Nhãn chuyên môn KTV (đồng bộ với admin: 0=Bảo trì, 1=Sửa chữa, 2=cả hai)
  static String _specialtyLabel(dynamic v) {
    final code = v is num ? v.toInt() : int.tryParse('${v ?? ''}');
    switch (code) {
      case 0:
        return 'Bảo trì';
      case 1:
        return 'Sửa chữa';
      default:
        return 'Bảo trì & Sửa chữa';
    }
  }

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

  Color _getPriorityColor(ServicePriority priority) {
    switch (priority) {
      case ServicePriority.low:
        return AppColors.success;
      case ServicePriority.medium:
        return AppColors.primary;
      case ServicePriority.high:
        return AppColors.warning;
      case ServicePriority.urgent:
        return AppColors.destructive;
    }
  }

  Future<void> _showRescheduleDialog() async {
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
                    'Chọn ngày và giờ mới cho dịch vụ của bạn',
                    style: Theme.of(ctx).textTheme.bodySmall,
                  ),
                  const SizedBox(height: 24),

                  // Date picker
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

                  // Time picker
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

                  // Reason
                  TextFormField(
                    controller: reasonController,
                    maxLines: 2,
                    decoration: const InputDecoration(
                      hintText: 'Lý do đổi lịch (không bắt buộc)',
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Buttons
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
          bookingId: widget.bookingId,
          newDate: newDate!,
          newTime: timeStr,
          reason: reasonController.text.trim(),
        );
        _loadBooking();
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

  Future<void> _showCancelDialog() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Text('Hủy lịch đặt'),
        content: const Text(
          'Bạn có chắc muốn hủy lịch đặt dịch vụ này? Thao tác này không thể hoàn tác.',
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
        await _maintenanceService.cancelBooking(widget.bookingId);
        _loadBooking();
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Chi tiết dịch vụ'),
        leading: IconButton(
          icon: const Icon(LucideIcons.arrowLeft),
          onPressed: () => context.pop(),
        ),
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            )
          : _booking == null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(LucideIcons.fileQuestion,
                          size: 48, color: AppColors.mutedForeground),
                      const SizedBox(height: 16),
                      Text(
                        'Không tìm thấy lịch đặt',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                    ],
                  ),
                )
              : _buildContent(),
    );
  }

  Widget _buildContent() {
    final booking = _booking!;
    final statusColor = _getStatusColor(booking.status);

    // Ưu tiên dữ liệu KTV mới nhất từ collection `technicians`, fallback snapshot
    // lưu trên đơn (giống cách admin hiển thị).
    final t = _technician;
    final techName =
        ((t?['name'] as String?)?.trim().isNotEmpty ?? false)
            ? (t!['name'] as String).trim()
            : booking.technicianName;
    final techPhone =
        ((t?['phone'] as String?)?.trim().isNotEmpty ?? false)
            ? (t!['phone'] as String).trim()
            : booking.technicianPhone;
    final techEmail =
        ((t?['email'] as String?)?.trim().isNotEmpty ?? false)
            ? (t!['email'] as String).trim()
            : booking.technicianEmail;
    final techPhoto =
        ((t?['photoUrl'] as String?)?.trim().isNotEmpty ?? false)
            ? (t!['photoUrl'] as String).trim()
            : booking.technicianPhoto;
    final techAddress = (t?['address'] as String?)?.trim() ?? '';
    final techSpecialty =
        t?['specialty'] != null ? _specialtyLabel(t!['specialty']) : '';

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Status Banner
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: statusColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: statusColor.withValues(alpha: 0.3)),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    _getStatusIcon(booking.status),
                    color: statusColor,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        booking.status.label,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: statusColor,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _getStatusDescription(booking.status),
                        style: TextStyle(
                          fontSize: 13,
                          color: statusColor.withValues(alpha: 0.8),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Title & Type
          AppCard(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      booking.serviceType == ServiceType.maintenance
                          ? LucideIcons.wrench
                          : LucideIcons.hammer,
                      size: 20,
                      color: AppColors.primary,
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        booking.serviceType.label,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: _getPriorityColor(booking.priority)
                            .withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        booking.priority.label,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: _getPriorityColor(booking.priority),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  booking.title,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 8),
                Text(
                  booking.description,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppColors.mutedForeground,
                      ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Schedule Info
          AppCard(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Lịch hẹn',
                    style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 16),
                _DetailRow(
                  icon: LucideIcons.calendar,
                  label: 'Ngày',
                  value: DateFormat('EEEE, dd MMMM yyyy', 'vi')
                      .format(booking.scheduledDate),
                ),
                const SizedBox(height: 12),
                _DetailRow(
                  icon: LucideIcons.clock,
                  label: 'Giờ',
                  value: booking.scheduledTime,
                ),
                // Thẻ kỹ thuật viên (hiện khi đơn đã được gán)
                if (techName.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.chart3.withValues(alpha: 0.06),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: AppColors.chart3.withValues(alpha: 0.2),
                      ),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Avatar
                        ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: techPhoto.isNotEmpty
                              ? CachedNetworkImage(
                                  imageUrl: techPhoto,
                                  width: 44,
                                  height: 44,
                                  fit: BoxFit.cover,
                                  errorWidget: (_, __, ___) =>
                                      _TechAvatar(techName),
                                )
                              : _TechAvatar(techName),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                techName,
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.foreground,
                                ),
                              ),
                              if (techSpecialty.isNotEmpty) ...[
                                const SizedBox(height: 2),
                                Text(
                                  techSpecialty,
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: AppColors.chart3,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                              if (techPhone.isNotEmpty) ...[
                                const SizedBox(height: 4),
                                _TechInfoLine(
                                  icon: LucideIcons.phone,
                                  text: techPhone,
                                ),
                              ],
                              if (techEmail.isNotEmpty) ...[
                                const SizedBox(height: 2),
                                _TechInfoLine(
                                  icon: LucideIcons.mail,
                                  text: techEmail,
                                ),
                              ],
                              if (techAddress.isNotEmpty) ...[
                                const SizedBox(height: 2),
                                _TechInfoLine(
                                  icon: LucideIcons.mapPin,
                                  text: techAddress,
                                ),
                              ],
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Customer Info
          AppCard(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Liên hệ',
                    style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 16),
                _DetailRow(
                  icon: LucideIcons.user,
                  label: 'Tên',
                  value: booking.customerName,
                ),
                const SizedBox(height: 12),
                _DetailRow(
                  icon: LucideIcons.phone,
                  label: 'Điện thoại',
                  value: booking.customerPhone,
                ),
                const SizedBox(height: 12),
                _DetailRow(
                  icon: LucideIcons.mapPin,
                  label: 'Địa chỉ',
                  value: booking.customerAddress,
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Images
          if (booking.imageUrls.isNotEmpty) ...[
            AppCard(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Hình ảnh (${booking.imageUrls.length})',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    height: 120,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: booking.imageUrls.length,
                      itemBuilder: (ctx, i) {
                        return GestureDetector(
                          onTap: () => _showFullImage(booking.imageUrls[i]),
                          child: Container(
                            width: 120,
                            margin: const EdgeInsets.only(right: 12),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(16),
                              child: CachedNetworkImage(
                                imageUrl: booking.imageUrls[i],
                                fit: BoxFit.cover,
                                placeholder: (ctx, url) => Container(
                                  color: AppColors.muted,
                                  child: const Center(
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: AppColors.primary,
                                    ),
                                  ),
                                ),
                                errorWidget: (ctx, url, error) => Container(
                                  color: AppColors.muted,
                                  child: const Icon(LucideIcons.imageOff,
                                      color: AppColors.mutedForeground),
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],

          // Reschedule History
          if (booking.rescheduleHistory.isNotEmpty) ...[
            AppCard(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(LucideIcons.history,
                          size: 20, color: AppColors.mutedForeground),
                      const SizedBox(width: 8),
                      Text(
                        'Lịch sử đổi lịch',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  ...booking.rescheduleHistory.asMap().entries.map((entry) {
                    final item = entry.value;
                    final oldDate =
                        (item['oldDate'] as dynamic)?.toDate();
                    final newDate =
                        (item['newDate'] as dynamic)?.toDate();
                    final reason = item['reason'] ?? '';
                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.muted,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Lần đổi #${entry.key + 1}',
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 8),
                          if (oldDate != null)
                            Text(
                              'Từ: ${DateFormat('dd/MM/yyyy').format(oldDate)} lúc ${item['oldTime']}',
                              style: const TextStyle(
                                fontSize: 12,
                                color: AppColors.mutedForeground,
                              ),
                            ),
                          if (newDate != null)
                            Text(
                              'Đến: ${DateFormat('dd/MM/yyyy').format(newDate)} lúc ${item['newTime']}',
                              style: const TextStyle(
                                fontSize: 12,
                                color: AppColors.foreground,
                              ),
                            ),
                          if (reason.isNotEmpty) ...[
                            const SizedBox(height: 4),
                            Text(
                              'Lý do: $reason',
                              style: const TextStyle(
                                fontSize: 12,
                                fontStyle: FontStyle.italic,
                                color: AppColors.mutedForeground,
                              ),
                            ),
                          ],
                        ],
                      ),
                    );
                  }),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],

          // Admin Note
          if (booking.adminNote.isNotEmpty) ...[
            AppCard(
              padding: const EdgeInsets.all(20),
              backgroundColor: AppColors.chart3.withValues(alpha: 0.05),
              border: Border.all(color: AppColors.chart3.withValues(alpha: 0.2)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: const [
                      Icon(LucideIcons.messageSquare,
                          size: 20, color: AppColors.chart3),
                      SizedBox(width: 8),
                      Text(
                        'Ghi chú từ quản trị',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          color: AppColors.chart3,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    booking.adminNote,
                    style: const TextStyle(
                      fontSize: 14,
                      color: AppColors.foreground,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],

          // Timestamps
          AppCard(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _DetailRow(
                  icon: LucideIcons.calendarPlus,
                  label: 'Tạo lúc',
                  value: DateFormat('dd/MM/yyyy HH:mm').format(booking.createdAt),
                ),
                const SizedBox(height: 12),
                _DetailRow(
                  icon: LucideIcons.refreshCw,
                  label: 'Cập nhật',
                  value: DateFormat('dd/MM/yyyy HH:mm').format(booking.updatedAt),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Action Buttons
          if (booking.canReschedule || booking.canCancel) ...[
            Row(
              children: [
                if (booking.canReschedule)
                  Expanded(
                    child: SizedBox(
                      height: 52,
                      child: OutlinedButton.icon(
                        onPressed: _showRescheduleDialog,
                        icon: const Icon(LucideIcons.calendarClock, size: 18),
                        label: const Text('Đổi lịch'),
                      ),
                    ),
                  ),
                if (booking.canReschedule && booking.canCancel)
                  const SizedBox(width: 12),
                if (booking.canCancel)
                  Expanded(
                    child: SizedBox(
                      height: 52,
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.destructive,
                          foregroundColor: AppColors.destructiveForeground,
                        ),
                        onPressed: _showCancelDialog,
                        icon: const Icon(LucideIcons.x, size: 18),
                        label: const Text('Hủy lịch'),
                      ),
                    ),
                  ),
              ],
            ),
          ],
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  String _getStatusDescription(ServiceStatus status) {
    switch (status) {
      case ServiceStatus.pending:
        return 'Lịch đặt đang chờ xác nhận';
      case ServiceStatus.processing:
        return 'Đã phân công kỹ thuật viên';
      case ServiceStatus.completed:
        return 'Dịch vụ đã hoàn thành';
      case ServiceStatus.cancelled:
        return 'Lịch đặt đã bị hủy';
    }
  }

  void _showFullImage(String url) {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        child: GestureDetector(
          onTap: () => Navigator.pop(ctx),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: CachedNetworkImage(
              imageUrl: url,
              fit: BoxFit.contain,
            ),
          ),
        ),
      ),
    );
  }
}

// =============================================================================
// Technician Avatar fallback
// =============================================================================

class _TechInfoLine extends StatelessWidget {
  final IconData icon;
  final String text;
  const _TechInfoLine({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 13, color: AppColors.mutedForeground),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
              fontSize: 12,
              color: AppColors.mutedForeground,
            ),
          ),
        ),
      ],
    );
  }
}

class _TechAvatar extends StatelessWidget {
  final String name;
  const _TechAvatar(this.name);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 44,
      height: 44,
      color: AppColors.chart3.withValues(alpha: 0.15),
      child: Center(
        child: Text(
          name.isNotEmpty ? name[0].toUpperCase() : '?',
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: AppColors.chart3,
          ),
        ),
      ),
    );
  }
}

// =============================================================================
// Detail Row widget
// =============================================================================

class _DetailRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _DetailRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: AppColors.mutedForeground),
        const SizedBox(width: 12),
        SizedBox(
          width: 80,
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
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: AppColors.foreground,
            ),
          ),
        ),
      ],
    );
  }
}
