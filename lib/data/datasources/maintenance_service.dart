import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

import '../models/service_booking_model.dart';
import 'cloudinary_service.dart';

class MaintenanceService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  static const String _collection = 'service_bookings';

  String? get _currentUserId => _auth.currentUser?.uid;

  // ---------------------------------------------------------------------------
  // Tạo đơn đặt lịch bảo trì
  // ---------------------------------------------------------------------------

  Future<ServiceBookingModel> createBooking({
    required String title,
    required String description,
    required ServiceType serviceType,
    required ServicePriority priority,
    required String customerName,
    required String customerPhone,
    required String customerAddress,
    required DateTime scheduledDate,
    required String scheduledTime,
    List<Uint8List> images = const [],
  }) async {
    final uid = _currentUserId;
    if (uid == null) throw Exception('Chưa đăng nhập');

    // Upload ảnh lên Cloudinary, lưu URL vào Firestore
    final imageUrls = <String>[];
    if (images.isNotEmpty) {
      for (int i = 0; i < images.length; i++) {
        try {
          final url = await CloudinaryService.uploadImage(
            images[i],
            folder: 'service_bookings/$uid',
          );
          imageUrls.add(url);
          debugPrint('✅ Image $i uploaded to Cloudinary');
        } catch (e) {
          debugPrint('⚠️ Image upload $i failed: $e');
          // Bỏ qua lỗi upload, vẫn tạo booking
        }
      }
    }

    final now = DateTime.now();
    final docRef = _firestore.collection(_collection).doc();

    final booking = ServiceBookingModel(
      id: docRef.id,
      userId: uid,
      title: title,
      description: description,
      serviceType: serviceType,
      priority: priority,
      customerName: customerName,
      customerPhone: customerPhone,
      customerAddress: customerAddress,
      scheduledDate: scheduledDate,
      scheduledTime: scheduledTime,
      imageUrls: imageUrls,
      status: ServiceStatus.pending,
      createdAt: now,
      updatedAt: now,
    );

    await docRef.set(booking.toMap());
    return booking;
  }

  // ---------------------------------------------------------------------------
  // Lấy danh sách đơn (upcoming = pending + processing)
  // ---------------------------------------------------------------------------

  Stream<List<ServiceBookingModel>> getUpcomingBookings() {
    final uid = _currentUserId;
    if (uid == null) return Stream.value([]);

    return _firestore
        .collection(_collection)
        .where('userId', isEqualTo: uid)
        .where('status', whereIn: [
          ServiceStatus.pending.code,
          ServiceStatus.processing.code,
        ])
        .snapshots()
        .map((snapshot) {
          final list = snapshot.docs
              .map((doc) => ServiceBookingModel.fromMap(doc.data(), doc.id))
              .toList();
          // Sort client-side (tránh cần composite index)
          list.sort((a, b) => a.scheduledDate.compareTo(b.scheduledDate));
          return list;
        });
  }

  // ---------------------------------------------------------------------------
  // Lấy lịch sử (completed + cancelled)
  // ---------------------------------------------------------------------------

  Stream<List<ServiceBookingModel>> getBookingHistory() {
    final uid = _currentUserId;
    if (uid == null) return Stream.value([]);

    return _firestore
        .collection(_collection)
        .where('userId', isEqualTo: uid)
        .where('status', whereIn: [
          ServiceStatus.completed.code,
          ServiceStatus.cancelled.code,
        ])
        .snapshots()
        .map((snapshot) {
          final list = snapshot.docs
              .map((doc) => ServiceBookingModel.fromMap(doc.data(), doc.id))
              .toList();
          // Sort client-side: mới nhất lên đầu
          list.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
          return list;
        });
  }

  // ---------------------------------------------------------------------------
  // Lấy chi tiết một đơn
  // ---------------------------------------------------------------------------

  Future<ServiceBookingModel?> getBookingById(String bookingId) async {
    final doc =
        await _firestore.collection(_collection).doc(bookingId).get();
    if (!doc.exists) return null;
    return ServiceBookingModel.fromMap(doc.data()!, doc.id);
  }

  // ---------------------------------------------------------------------------
  // Hẹn lại lịch → status reset về 0 (Pending)
  // ---------------------------------------------------------------------------

  Future<void> rescheduleBooking({
    required String bookingId,
    required DateTime newDate,
    required String newTime,
    String? reason,
  }) async {
    final doc =
        await _firestore.collection(_collection).doc(bookingId).get();
    if (!doc.exists) throw Exception('Không tìm thấy đơn');

    final data = doc.data()!;
    final oldDate = (data['scheduledDate'] as Timestamp?)?.toDate();
    final oldTime = data['scheduledTime'] ?? '';

    // Lưu lịch sử hẹn lại
    final history = List<Map<String, dynamic>>.from(
        data['rescheduleHistory'] ?? []);
    history.add({
      'oldDate': oldDate != null ? Timestamp.fromDate(oldDate) : null,
      'oldTime': oldTime,
      'newDate': Timestamp.fromDate(newDate),
      'newTime': newTime,
      'reason': reason ?? '',
      'rescheduledAt': Timestamp.fromDate(DateTime.now()),
    });

    await _firestore.collection(_collection).doc(bookingId).update({
      'scheduledDate': Timestamp.fromDate(newDate),
      'scheduledTime': newTime,
      'status': ServiceStatus.pending.code, // Reset trạng thái về Pending
      'updatedAt': Timestamp.fromDate(DateTime.now()),
      'rescheduleHistory': history,
    });
  }

  // ---------------------------------------------------------------------------
  // Hủy lịch → status = 3 (Cancelled)
  // ---------------------------------------------------------------------------

  Future<void> cancelBooking(String bookingId, {String? reason}) async {
    await _firestore.collection(_collection).doc(bookingId).update({
      'status': ServiceStatus.cancelled.code,
      'adminNote': reason ?? '',
      'updatedAt': Timestamp.fromDate(DateTime.now()),
    });
  }

  // ---------------------------------------------------------------------------
  // Đếm số đơn theo trạng thái (dùng cho thống kê)
  // ---------------------------------------------------------------------------

  Future<Map<ServiceStatus, int>> getBookingStats() async {
    final uid = _currentUserId;
    if (uid == null) return {};

    final snapshot = await _firestore
        .collection(_collection)
        .where('userId', isEqualTo: uid)
        .get();

    final stats = <ServiceStatus, int>{};
    for (final doc in snapshot.docs) {
      final status = ServiceStatus.fromCode(doc.data()['status'] ?? 0);
      stats[status] = (stats[status] ?? 0) + 1;
    }
    return stats;
  }
}
