import 'dart:typed_data';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../config/app_colors.dart';
import '../../../data/models/service_booking_model.dart';
import '../../../data/datasources/maintenance_service.dart';
import '../../../core/widgets/app_card.dart';

class BookServiceScreen extends StatefulWidget {
  const BookServiceScreen({super.key});

  @override
  State<BookServiceScreen> createState() => _BookServiceScreenState();
}

class _BookServiceScreenState extends State<BookServiceScreen> {
  final _formKey = GlobalKey<FormState>();
  final _maintenanceService = MaintenanceService();

  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();

  ServiceType _serviceType = ServiceType.maintenance;
  ServicePriority _priority = ServicePriority.medium;
  DateTime? _selectedDate;
  TimeOfDay? _selectedTime;

  final List<Uint8List> _imageBytes = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _prefillUserInfo();
  }

  void _prefillUserInfo() {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      _nameController.text = user.displayName ?? '';
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _nameController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 1)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 90)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppColors.primary,
              onPrimary: AppColors.primaryForeground,
              surface: AppColors.card,
              onSurface: AppColors.foreground,
            ),
          ),
          child: child!,
        );
      },
    );
    if (date != null) {
      setState(() => _selectedDate = date);
    }
  }

  Future<void> _pickTime() async {
    final time = await showTimePicker(
      context: context,
      initialTime: const TimeOfDay(hour: 9, minute: 0),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppColors.primary,
              onPrimary: AppColors.primaryForeground,
              surface: AppColors.card,
              onSurface: AppColors.foreground,
            ),
          ),
          child: child!,
        );
      },
    );
    if (time != null) {
      setState(() => _selectedTime = time);
    }
  }

  Future<void> _pickImages() async {
    if (_imageBytes.length >= 5) {
      _showSnackBar('Tối đa 5 hình ảnh');
      return;
    }

    final picker = ImagePicker();
    final images = await picker.pickMultiImage(
      maxWidth: 1200,
      maxHeight: 1200,
      imageQuality: 80,
    );

    for (final image in images) {
      if (_imageBytes.length >= 5) break;
      final bytes = await image.readAsBytes();
      setState(() => _imageBytes.add(bytes));
    }
  }

  Future<void> _submitBooking() async {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedDate == null) {
      _showSnackBar('Vui lòng chọn ngày bảo trì');
      return;
    }
    if (_selectedTime == null) {
      _showSnackBar('Vui lòng chọn giờ bảo trì');
      return;
    }

    setState(() => _isLoading = true);

    try {
      final timeStr =
          '${_selectedTime!.hour.toString().padLeft(2, '0')}:${_selectedTime!.minute.toString().padLeft(2, '0')}';

      await _maintenanceService.createBooking(
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim(),
        serviceType: _serviceType,
        priority: _priority,
        customerName: _nameController.text.trim(),
        customerPhone: _phoneController.text.trim(),
        customerAddress: _addressController.text.trim(),
        scheduledDate: _selectedDate!,
        scheduledTime: timeStr,
        images: _imageBytes,
      );

      if (mounted) {
        _showSnackBar('Đặt lịch thành công!', isSuccess: true);
        context.pop();
      }
    } catch (e) {
      _showSnackBar('Lỗi: ${e.toString()}');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showSnackBar(String message, {bool isSuccess = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isSuccess ? AppColors.success : AppColors.destructive,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Đặt lịch dịch vụ'),
        leading: IconButton(
          icon: const Icon(LucideIcons.arrowLeft),
          onPressed: () => context.pop(),
        ),
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Service Type Selection
              _SectionTitle(title: 'Loại dịch vụ'),
              const SizedBox(height: 12),
              _ServiceTypeSelector(
                selected: _serviceType,
                onChanged: (type) => setState(() => _serviceType = type),
              ),
              const SizedBox(height: 24),

              // Title
              _SectionTitle(title: 'Chi tiết yêu cầu'),
              const SizedBox(height: 12),
              _buildTextField(
                controller: _titleController,
                label: 'Tiêu đề',
                hint: 'VD: Cảm biến không hoạt động',
                icon: LucideIcons.fileText,
                validator: (v) =>
                    v == null || v.trim().isEmpty ? 'Vui lòng nhập tiêu đề' : null,
              ),
              const SizedBox(height: 16),

              // Description
              _buildTextField(
                controller: _descriptionController,
                label: 'Mô tả vấn đề',
                hint: 'Mô tả chi tiết vấn đề...',
                icon: LucideIcons.alignLeft,
                maxLines: 4,
                validator: (v) =>
                    v == null || v.trim().isEmpty ? 'Vui lòng mô tả vấn đề' : null,
              ),
              const SizedBox(height: 16),

              // Priority
              _SectionTitle(title: 'Mức ưu tiên'),
              const SizedBox(height: 12),
              _PrioritySelector(
                selected: _priority,
                onChanged: (p) => setState(() => _priority = p),
              ),
              const SizedBox(height: 24),

              // Customer Info
              _SectionTitle(title: 'Thông tin liên hệ'),
              const SizedBox(height: 12),
              _buildTextField(
                controller: _nameController,
                label: 'Họ và tên',
                hint: 'Tên của bạn',
                icon: LucideIcons.user,
                validator: (v) =>
                    v == null || v.trim().isEmpty ? 'Vui lòng nhập tên' : null,
              ),
              const SizedBox(height: 16),
              _buildTextField(
                controller: _phoneController,
                label: 'Số điện thoại',
                hint: '0912 345 678',
                icon: LucideIcons.phone,
                keyboardType: TextInputType.phone,
                validator: (v) =>
                    v == null || v.trim().isEmpty ? 'Vui lòng nhập SĐT' : null,
              ),
              const SizedBox(height: 16),
              _buildTextField(
                controller: _addressController,
                label: 'Địa chỉ',
                hint: 'Địa chỉ cần đến',
                icon: LucideIcons.mapPin,
                maxLines: 2,
                validator: (v) =>
                    v == null || v.trim().isEmpty ? 'Vui lòng nhập địa chỉ' : null,
              ),
              const SizedBox(height: 24),

              // Schedule
              _SectionTitle(title: 'Lịch hẹn'),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _DatePickerButton(
                      label: 'Ngày hẹn',
                      value: _selectedDate != null
                          ? DateFormat('dd/MM/yyyy').format(_selectedDate!)
                          : 'Chọn ngày',
                      icon: LucideIcons.calendar,
                      onTap: _pickDate,
                      hasValue: _selectedDate != null,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _DatePickerButton(
                      label: 'Giờ hẹn',
                      value: _selectedTime != null
                          ? '${_selectedTime!.hour.toString().padLeft(2, '0')}:${_selectedTime!.minute.toString().padLeft(2, '0')}'
                          : 'Chọn giờ',
                      icon: LucideIcons.clock,
                      onTap: _pickTime,
                      hasValue: _selectedTime != null,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Images
              _SectionTitle(title: 'Hình ảnh (${_imageBytes.length}/5)'),
              const SizedBox(height: 12),
              _ImagePickerGrid(
                images: _imageBytes,
                onAdd: _pickImages,
                onRemove: (index) =>
                    setState(() => _imageBytes.removeAt(index)),
              ),
              const SizedBox(height: 32),

              // Summary card
              if (_selectedDate != null && _titleController.text.isNotEmpty)
                _BookingSummaryCard(
                  title: _titleController.text,
                  serviceType: _serviceType,
                  priority: _priority,
                  date: _selectedDate,
                  time: _selectedTime,
                  customerName: _nameController.text,
                ),
              const SizedBox(height: 24),

              // Submit Button
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _submitBooking,
                  child: _isLoading
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              AppColors.primaryForeground,
                            ),
                          ),
                        )
                      : Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: const [
                            Icon(LucideIcons.send, size: 20),
                            SizedBox(width: 8),
                            Text('Gửi yêu cầu'),
                          ],
                        ),
                ),
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    int maxLines = 1,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            color: AppColors.mutedForeground,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          maxLines: maxLines,
          keyboardType: keyboardType,
          validator: validator,
          style: const TextStyle(
            fontSize: 16,
            color: AppColors.foreground,
          ),
          decoration: InputDecoration(
            hintText: hint,
            prefixIcon: maxLines == 1
                ? Padding(
                    padding: const EdgeInsets.only(left: 16, right: 12),
                    child: Icon(icon, size: 20, color: AppColors.mutedForeground),
                  )
                : null,
            prefixIconConstraints: const BoxConstraints(
              minWidth: 0,
              minHeight: 0,
            ),
          ),
        ),
      ],
    );
  }
}

// =============================================================================
// Section Title
// =============================================================================

class _SectionTitle extends StatelessWidget {
  final String title;
  const _SectionTitle({required this.title});

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: Theme.of(context).textTheme.titleMedium,
    );
  }
}

// =============================================================================
// Service Type Selector
// =============================================================================

class _ServiceTypeSelector extends StatelessWidget {
  final ServiceType selected;
  final ValueChanged<ServiceType> onChanged;

  const _ServiceTypeSelector({
    required this.selected,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: ServiceType.values.map((type) {
        final isSelected = type == selected;
        return Expanded(
          child: GestureDetector(
            onTap: () => onChanged(type),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: EdgeInsets.only(
                right: type == ServiceType.maintenance ? 8 : 0,
                left: type == ServiceType.repair ? 8 : 0,
              ),
              padding: const EdgeInsets.symmetric(vertical: 16),
              decoration: BoxDecoration(
                color: isSelected ? AppColors.primary : AppColors.card,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isSelected ? AppColors.primary : AppColors.border,
                  width: isSelected ? 2 : 1,
                ),
                boxShadow: isSelected
                    ? [
                        BoxShadow(
                          color: AppColors.primary.withValues(alpha: 0.2),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ]
                    : null,
              ),
              child: Column(
                children: [
                  Icon(
                    type == ServiceType.maintenance
                        ? LucideIcons.wrench
                        : LucideIcons.hammer,
                    size: 28,
                    color: isSelected
                        ? AppColors.primaryForeground
                        : AppColors.mutedForeground,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    type.label,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: isSelected
                          ? AppColors.primaryForeground
                          : AppColors.foreground,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}

// =============================================================================
// Priority Selector
// =============================================================================

class _PrioritySelector extends StatelessWidget {
  final ServicePriority selected;
  final ValueChanged<ServicePriority> onChanged;

  const _PrioritySelector({
    required this.selected,
    required this.onChanged,
  });

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

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      children: ServicePriority.values.map((priority) {
        final isSelected = priority == selected;
        final color = _getPriorityColor(priority);
        return GestureDetector(
          onTap: () => onChanged(priority),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: isSelected ? color.withValues(alpha: 0.15) : AppColors.card,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isSelected ? color : AppColors.border,
                width: isSelected ? 2 : 1,
              ),
            ),
            child: Text(
              priority.label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: isSelected ? color : AppColors.mutedForeground,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}

// =============================================================================
// Date/Time Picker Button
// =============================================================================

class _DatePickerButton extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final VoidCallback onTap;
  final bool hasValue;

  const _DatePickerButton({
    required this.label,
    required this.value,
    required this.icon,
    required this.onTap,
    required this.hasValue,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            color: AppColors.mutedForeground,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.inputBackground,
              borderRadius: BorderRadius.circular(16),
              border: hasValue
                  ? Border.all(color: AppColors.primary, width: 2)
                  : null,
            ),
            child: Row(
              children: [
                Icon(
                  icon,
                  size: 20,
                  color: hasValue ? AppColors.primary : AppColors.mutedForeground,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    value,
                    style: TextStyle(
                      fontSize: 14,
                      color: hasValue
                          ? AppColors.foreground
                          : AppColors.mutedForeground,
                      fontWeight: hasValue ? FontWeight.w500 : FontWeight.w400,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

// =============================================================================
// Image Picker Grid
// =============================================================================

class _ImagePickerGrid extends StatelessWidget {
  final List<Uint8List> images;
  final VoidCallback onAdd;
  final ValueChanged<int> onRemove;

  const _ImagePickerGrid({
    required this.images,
    required this.onAdd,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 100,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          // Add button
          if (images.length < 5)
            GestureDetector(
              onTap: onAdd,
              child: Container(
                width: 100,
                height: 100,
                margin: const EdgeInsets.only(right: 12),
                decoration: BoxDecoration(
                  color: AppColors.inputBackground,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: AppColors.border,
                    style: BorderStyle.solid,
                  ),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: const [
                    Icon(
                      LucideIcons.camera,
                      size: 28,
                      color: AppColors.mutedForeground,
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Thêm ảnh',
                      style: TextStyle(
                        fontSize: 11,
                        color: AppColors.mutedForeground,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          // Image previews
          ...images.asMap().entries.map((entry) {
            return Container(
              width: 100,
              height: 100,
              margin: const EdgeInsets.only(right: 12),
              child: Stack(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: Image.memory(
                      entry.value,
                      width: 100,
                      height: 100,
                      fit: BoxFit.cover,
                    ),
                  ),
                  Positioned(
                    top: 4,
                    right: 4,
                    child: GestureDetector(
                      onTap: () => onRemove(entry.key),
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(
                          color: AppColors.destructive,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          LucideIcons.x,
                          size: 14,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}

// =============================================================================
// Booking Summary Card
// =============================================================================

class _BookingSummaryCard extends StatelessWidget {
  final String title;
  final ServiceType serviceType;
  final ServicePriority priority;
  final DateTime? date;
  final TimeOfDay? time;
  final String customerName;

  const _BookingSummaryCard({
    required this.title,
    required this.serviceType,
    required this.priority,
    this.date,
    this.time,
    required this.customerName,
  });

  @override
  Widget build(BuildContext context) {
    return AppCard(
      backgroundColor: AppColors.primary.withValues(alpha: 0.06),
      border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: const [
              Icon(LucideIcons.clipboardList, size: 20, color: AppColors.primary),
              SizedBox(width: 8),
              Text(
                'Tóm tắt đặt lịch',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _SummaryRow(label: 'Tiêu đề', value: title),
          _SummaryRow(label: 'Loại dịch vụ', value: serviceType.label),
          _SummaryRow(label: 'Mức ưu tiên', value: priority.label),
          if (date != null)
            _SummaryRow(
              label: 'Ngày hẹn',
              value: DateFormat('dd/MM/yyyy').format(date!),
            ),
          if (time != null)
            _SummaryRow(
              label: 'Giờ hẹn',
              value:
                  '${time!.hour.toString().padLeft(2, '0')}:${time!.minute.toString().padLeft(2, '0')}',
            ),
          if (customerName.isNotEmpty)
            _SummaryRow(label: 'Tên khách', value: customerName),
        ],
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  final String label;
  final String value;
  const _SummaryRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
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
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: AppColors.foreground,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
