import 'dart:async';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import '../models/sensor_data_model.dart';

/// Service lắng nghe dữ liệu cảm biến realtime từ Firebase RTDB.
///
/// Dữ liệu nằm tại: tracking_devices/{deviceId}/sensors
class HiveSensorService {
  HiveSensorService._();
  static final HiveSensorService _instance = HiveSensorService._();
  factory HiveSensorService() => _instance;

  static const _kDbUrl =
      'https://doan-hotronuoiong-default-rtdb.asia-southeast1.firebasedatabase.app';

  FirebaseDatabase get _db => FirebaseDatabase.instanceFor(
        app: Firebase.app(),
        databaseURL: _kDbUrl,
      );

  /// Lắng nghe dữ liệu sensor realtime cho một device.
  /// Trả về Stream<SensorData> cập nhật mỗi khi có thay đổi trên RTDB.
  Stream<SensorData> streamSensorData(String deviceId) {
    final ref = _db.ref('tracking_devices/$deviceId/sensors');
    return ref.onValue.map((event) {
      final data = event.snapshot.value;
      if (data == null) return const SensorData();
      try {
        return SensorData.fromMap(Map<dynamic, dynamic>.from(data as Map));
      } catch (e) {
        debugPrint('[HiveSensor] Parse error: $e | data=$data');
        return const SensorData();
      }
    }).handleError((e) {
      debugPrint('[HiveSensor] Stream error: $e');
    });
  }

  /// Đọc sensor data một lần (không realtime).
  Future<SensorData> getSensorData(String deviceId) async {
    final ref = _db.ref('tracking_devices/$deviceId/sensors');
    try {
      final snapshot = await ref.get();
      if (snapshot.exists && snapshot.value != null) {
        return SensorData.fromMap(snapshot.value as Map<dynamic, dynamic>);
      }
    } catch (e) {
      debugPrint('[HiveSensor] Loi doc sensor: $e');
    }
    return const SensorData();
  }
}
