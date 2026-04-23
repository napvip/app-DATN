import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import '../../config/app_routes.dart';
import '../../presentation/screens/main/sos_incoming_screen.dart';

const _kDbUrl =
    'https://doan-hotronuoiong-default-rtdb.asia-southeast1.firebasedatabase.app';

// Phải là top-level function — chạy trong isolate riêng khi app bị tắt
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  await NotificationService._showLocalNotification(message.data);
}

class NotificationService {
  NotificationService._();
  static final NotificationService _instance = NotificationService._();
  factory NotificationService() => _instance;

  static final _localNotifs = FlutterLocalNotificationsPlugin();

  static const _channelId = 'sos_channel';
  static const _channelName = 'SOS Cảnh báo ong bắp cày';

  static Future<void> init() async {
    // Local notifications
    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    await _localNotifs.initialize(
      const InitializationSettings(android: androidInit),
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );

    // Tạo notification channel Android
    await _localNotifs
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(
          const AndroidNotificationChannel(
            _channelId,
            _channelName,
            importance: Importance.max,
            enableVibration: true,
            playSound: true,
          ),
        );

    // Đăng ký background handler TRƯỚC — không được nằm trong try-catch
    // vì nếu getToken() lỗi thì handler sẽ không bao giờ được đăng ký
    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

    // Khi foreground: RTDB listener đã lo (SOSRealtimeService) — không xử lý
    // onMessage ở đây để tránh double notification.

    // Khi user tap vào notification để mở app từ background
    FirebaseMessaging.onMessageOpenedApp.listen((message) {
      if (message.data['type'] == 'sos_alert') {
        _showIncomingScreen(message.data);
      }
    });

    // Xin quyền + lấy token — lỗi ở đây không ảnh hưởng background handler
    try {
      await FirebaseMessaging.instance.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );
    } catch (e) {
      debugPrint('[FCM] Xin quyen that bai: $e');
    }

    try {
      final token = await FirebaseMessaging.instance.getToken();
      if (token != null) {
        await _saveToken(token);
        debugPrint('[FCM] Token da luu: ${token.substring(0, 20)}...');
      }
      FirebaseMessaging.instance.onTokenRefresh.listen(_saveToken);
    } catch (e) {
      debugPrint('[FCM] Lay token that bai: $e');
    }

    try {
      final initial = await FirebaseMessaging.instance.getInitialMessage();
      if (initial != null && initial.data['type'] == 'sos_alert') {
        Future.delayed(const Duration(seconds: 2), () {
          _showIncomingScreen(initial.data);
        });
      }
    } catch (e) {
      debugPrint('[FCM] GetInitialMessage that bai: $e');
    }
  }

  static Future<void> _saveToken(String token) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    try {
      await FirebaseDatabase.instanceFor(
        app: Firebase.app(),
        databaseURL: _kDbUrl,
      ).ref('user_fcm_tokens/$uid').set(token);
    } catch (_) {}
  }

  static Future<void> _showLocalNotification(Map<String, dynamic> data) async {
    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    await _localNotifs.initialize(
      const InitializationSettings(android: androidInit),
    );
    await _showSOSNotification(data);
  }

  static Future<void> showSOSNotification(Map<String, dynamic> data) async {
    final hiveName = data['hive_name'] ?? 'Thùng ong';
    final count = data['detection_count'] ?? '?';

    await _localNotifs.show(
      1001,
      '🚨 Cảnh báo ong bắp cày tấn công!',
      'Thùng "$hiveName" phát hiện $count con',
      const NotificationDetails(
        android: AndroidNotificationDetails(
          _channelId,
          _channelName,
          importance: Importance.max,
          priority: Priority.max,
          fullScreenIntent: true,
          category: AndroidNotificationCategory.call,
          visibility: NotificationVisibility.public,
          autoCancel: false,
          ongoing: false,
        ),
      ),
    );
  }

  static Future<void> _showSOSNotification(Map<String, dynamic> data) =>
      showSOSNotification(data);

  static void _onNotificationTapped(NotificationResponse response) {
    // Delay nhỏ để router kịp mount sau khi app được bring to foreground
    Future.delayed(const Duration(milliseconds: 300), () {
      _showIncomingScreen(const {});
    });
  }

  static void _showIncomingScreen(Map<String, dynamic> data) {
    final nav = AppRoutes.rootNavigatorKey.currentState;
    if (nav == null) return;
    nav.push(
      PageRouteBuilder(
        opaque: false,
        barrierColor: Colors.black87,
        pageBuilder: (_, __, ___) => SOSIncomingScreen(alert: {
          'hive_name': data['hive_name'] ?? '',
          'detection_count': int.tryParse(data['detection_count']?.toString() ?? '0') ?? 0,
          'confidence': double.tryParse(data['confidence']?.toString() ?? '0') ?? 0,
          'image_url': data['image_url'] ?? '',
        }),
        transitionsBuilder: (_, anim, __, child) => SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0, 1),
            end: Offset.zero,
          ).animate(CurvedAnimation(parent: anim, curve: Curves.easeOutCubic)),
          child: child,
        ),
      ),
    );
  }
}
