import 'package:cloud_firestore/cloud_firestore.dart';

/// Trạng thái đơn bảo trì – dùng int code để admin web dễ xử lý.
/// 0 = Pending  |  1 = Processing  |  2 = Completed  |  3 = Cancelled
enum ServiceStatus {
  pending(0, 'Pending'),
  processing(1, 'Processing'),
  completed(2, 'Completed'),
  cancelled(3, 'Cancelled');

  final int code;
  final String label;
  const ServiceStatus(this.code, this.label);

  static ServiceStatus fromCode(int code) {
    return ServiceStatus.values.firstWhere(
      (e) => e.code == code,
      orElse: () => ServiceStatus.pending,
    );
  }
}

/// Loại dịch vụ: Bảo trì / Sửa chữa
enum ServiceType {
  maintenance(0, 'Maintenance'),
  repair(1, 'Repair');

  final int code;
  final String label;
  const ServiceType(this.code, this.label);

  static ServiceType fromCode(int code) {
    return ServiceType.values.firstWhere(
      (e) => e.code == code,
      orElse: () => ServiceType.maintenance,
    );
  }
}

/// Mức độ ưu tiên
enum ServicePriority {
  low(0, 'Low'),
  medium(1, 'Medium'),
  high(2, 'High'),
  urgent(3, 'Urgent');

  final int code;
  final String label;
  const ServicePriority(this.code, this.label);

  static ServicePriority fromCode(int code) {
    return ServicePriority.values.firstWhere(
      (e) => e.code == code,
      orElse: () => ServicePriority.medium,
    );
  }
}

class ServiceBookingModel {
  final String id;
  final String userId;

  // Thông tin đơn
  final String title;
  final String description;
  final ServiceType serviceType;
  final ServicePriority priority;

  // Thông tin khách hàng
  final String customerName;
  final String customerPhone;
  final String customerAddress;

  // Lịch hẹn
  final DateTime scheduledDate;
  final String scheduledTime;

  // Nhân viên phụ trách
  final String technicianName;
  final String technicianId;
  final String technicianPhone;
  final String technicianEmail;
  final String technicianPhoto;

  // Hình ảnh đính kèm
  final List<String> imageUrls;

  // Trạng thái
  final ServiceStatus status;

  // Ghi chú admin
  final String adminNote;

  // Timestamps
  final DateTime createdAt;
  final DateTime updatedAt;

  // Lịch sử hẹn lại (danh sách các ngày đã reschedule)
  final List<Map<String, dynamic>> rescheduleHistory;

  ServiceBookingModel({
    required this.id,
    required this.userId,
    required this.title,
    required this.description,
    required this.serviceType,
    this.priority = ServicePriority.medium,
    required this.customerName,
    required this.customerPhone,
    required this.customerAddress,
    required this.scheduledDate,
    required this.scheduledTime,
    this.technicianName = '',
    this.technicianId = '',
    this.technicianPhone = '',
    this.technicianEmail = '',
    this.technicianPhoto = '',
    this.imageUrls = const [],
    this.status = ServiceStatus.pending,
    this.adminNote = '',
    required this.createdAt,
    required this.updatedAt,
    this.rescheduleHistory = const [],
  });

  factory ServiceBookingModel.fromMap(Map<String, dynamic> map, String docId) {
    return ServiceBookingModel(
      id: docId,
      userId: map['userId'] ?? '',
      title: map['title'] ?? '',
      description: map['description'] ?? '',
      serviceType: ServiceType.fromCode(map['serviceType'] ?? 0),
      priority: ServicePriority.fromCode(map['priority'] ?? 1),
      customerName: map['customerName'] ?? '',
      customerPhone: map['customerPhone'] ?? '',
      customerAddress: map['customerAddress'] ?? '',
      scheduledDate:
          (map['scheduledDate'] as Timestamp?)?.toDate() ?? DateTime.now(),
      scheduledTime: map['scheduledTime'] ?? '',
      technicianName: map['technicianName'] ?? '',
      technicianId: map['technicianId'] ?? '',
      technicianPhone: map['technicianPhone'] ?? '',
      technicianEmail: map['technicianEmail'] ?? '',
      technicianPhoto: map['technicianPhoto'] ?? '',
      imageUrls: List<String>.from(map['imageUrls'] ?? []),
      status: ServiceStatus.fromCode(map['status'] ?? 0),
      adminNote: map['adminNote'] ?? '',
      createdAt:
          (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt:
          (map['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      rescheduleHistory: List<Map<String, dynamic>>.from(
          map['rescheduleHistory'] ?? []),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'title': title,
      'description': description,
      'serviceType': serviceType.code,
      'priority': priority.code,
      'customerName': customerName,
      'customerPhone': customerPhone,
      'customerAddress': customerAddress,
      'scheduledDate': Timestamp.fromDate(scheduledDate),
      'scheduledTime': scheduledTime,
      'technicianName': technicianName,
      'technicianId': technicianId,
      'technicianPhone': technicianPhone,
      'technicianEmail': technicianEmail,
      'technicianPhoto': technicianPhoto,
      'imageUrls': imageUrls,
      'status': status.code,
      'adminNote': adminNote,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'rescheduleHistory': rescheduleHistory,
    };
  }

  ServiceBookingModel copyWith({
    String? id,
    String? userId,
    String? title,
    String? description,
    ServiceType? serviceType,
    ServicePriority? priority,
    String? customerName,
    String? customerPhone,
    String? customerAddress,
    DateTime? scheduledDate,
    String? scheduledTime,
    String? technicianName,
    String? technicianId,
    String? technicianPhone,
    String? technicianEmail,
    String? technicianPhoto,
    List<String>? imageUrls,
    ServiceStatus? status,
    String? adminNote,
    DateTime? createdAt,
    DateTime? updatedAt,
    List<Map<String, dynamic>>? rescheduleHistory,
  }) {
    return ServiceBookingModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      title: title ?? this.title,
      description: description ?? this.description,
      serviceType: serviceType ?? this.serviceType,
      priority: priority ?? this.priority,
      customerName: customerName ?? this.customerName,
      customerPhone: customerPhone ?? this.customerPhone,
      customerAddress: customerAddress ?? this.customerAddress,
      scheduledDate: scheduledDate ?? this.scheduledDate,
      scheduledTime: scheduledTime ?? this.scheduledTime,
      technicianName: technicianName ?? this.technicianName,
      technicianId: technicianId ?? this.technicianId,
      technicianPhone: technicianPhone ?? this.technicianPhone,
      technicianEmail: technicianEmail ?? this.technicianEmail,
      technicianPhoto: technicianPhoto ?? this.technicianPhoto,
      imageUrls: imageUrls ?? this.imageUrls,
      status: status ?? this.status,
      adminNote: adminNote ?? this.adminNote,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      rescheduleHistory: rescheduleHistory ?? this.rescheduleHistory,
    );
  }

  /// Kiểm tra xem đơn có thể hẹn lại không
  bool get canReschedule =>
      status == ServiceStatus.pending || status == ServiceStatus.processing;

  /// Kiểm tra xem đơn có thể hủy không
  bool get canCancel =>
      status == ServiceStatus.pending || status == ServiceStatus.processing;

  /// Kiểm tra đơn đã hoàn thành / thuộc lịch sử chưa
  bool get isHistory =>
      status == ServiceStatus.completed || status == ServiceStatus.cancelled;
}
