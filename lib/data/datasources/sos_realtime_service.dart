import 'dart:async';
import 'dart:convert';

import 'package:audioplayers/audioplayers.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:vibration/vibration.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_overlay_window/flutter_overlay_window.dart';

import '../../config/app_routes.dart';
import '../../presentation/screens/main/sos_incoming_screen.dart';
import 'notification_service.dart';
import 'user_settings_service.dart';

const _kDbUrl =
    'https://doan-hotronuoiong-default-rtdb.asia-southeast1.firebasedatabase.app';

class SOSRealtimeService with WidgetsBindingObserver {
  SOSRealtimeService._();
  static final SOSRealtimeService _instance = SOSRealtimeService._();
  factory SOSRealtimeService() => _instance;

  FirebaseDatabase get _db => FirebaseDatabase.instanceFor(
        app: Firebase.app(),
        databaseURL: _kDbUrl,
      );

  final _player = AudioPlayer();
  StreamSubscription<DatabaseEvent>? _subscription;
  int _lastAlertTime = 0; // ms — cooldown phía Flutter
  int _listenerStartTime = 0; // ms — mốc khi bắt đầu lắng nghe
  Map<String, dynamic>? _pendingAlert; // alert nhận khi app ở background

  Function(Map<String, dynamic>)? onSOSReceived;

  void startListening() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      debugPrint('[SOS] Khong co user, bo qua lang nghe');
      return;
    }

    stopListening();
    WidgetsBinding.instance.addObserver(this);

    // Mốc thời gian start listener — chỉ xử lý alert tạo SAU mốc này.
    // Alert cũ có sẵn trong DB (onChildAdded fire lại khi subscribe) sẽ bị bỏ qua.
    _listenerStartTime = DateTime.now().millisecondsSinceEpoch;

    _subscription = _db
        .ref('user_sos_alerts/${user.uid}')
        .onChildAdded
        .listen((event) async {
      final data = Map<String, dynamic>.from(
        event.snapshot.value as Map? ?? {},
      );

      final status = data['status'] as String? ?? '';
      final createdAt = data['created_at'] as int? ?? 0;

      // Chỉ hiện cảnh báo khi Python phát hiện MỚI lúc app đang mở
      if (status != 'active' || createdAt < _listenerStartTime) return;

      // Cooldown phía Flutter: bỏ qua nếu quá gần lần trước
      final cooldown = await UserSettingsService().getAlertCooldown() * 1000;
      final now = DateTime.now().millisecondsSinceEpoch;
      if (now - _lastAlertTime < cooldown) {
        debugPrint('[SOS] Bo qua: cooldown chua het (${now - _lastAlertTime}ms < ${cooldown}ms)');
        return;
      }
      _lastAlertTime = now;

      _playAlarm();
      final alertData = {...data, 'key': event.snapshot.key};
      onSOSReceived?.call(alertData);

      final appState = SchedulerBinding.instance.lifecycleState;
      debugPrint('[SOS] Hien canh bao, app state: $appState');

      if (appState == AppLifecycleState.resumed) {
        // App đang mở foreground — show màn hình trực tiếp
        _showIncomingScreen(alertData);
      } else {
        // App ở background — lưu lại để hiện khi user mở app
        _pendingAlert = alertData;
        _showOverlay(alertData);
        NotificationService.showSOSNotification(alertData);
      }
    }, onError: (e) {
      debugPrint('[SOS] Loi lang nghe: $e');
    });

    debugPrint('[SOS] Bat dau lang nghe canh bao cho uid=${user.uid}');
  }

  Future<void> _showOverlay(Map<String, dynamic> alert) async {
    try {
      final granted = await FlutterOverlayWindow.isPermissionGranted();
      debugPrint('[SOS] Overlay permission: $granted');
      if (!granted) return;

      await FlutterOverlayWindow.showOverlay(
        enableDrag: false,
        flag: OverlayFlag.defaultFlag,
        alignment: OverlayAlignment.center,
        visibility: NotificationVisibility.visibilityPublic,
        positionGravity: PositionGravity.auto,
        width: WindowSize.matchParent,
        height: WindowSize.matchParent,
      );

      // Chờ overlay engine khởi động xong
      await Future.delayed(const Duration(milliseconds: 600));
      await FlutterOverlayWindow.shareData(jsonEncode(alert));
      debugPrint('[SOS] Overlay hien thanh cong');
    } catch (e) {
      debugPrint('[SOS] Loi hien overlay: $e');
    }
  }

  void _showIncomingScreen(Map<String, dynamic> alert) {
    if (SOSIncomingScreen.isShowing) return;
    final nav = AppRoutes.rootNavigatorKey.currentState;
    if (nav == null) return;
    nav.push(
      PageRouteBuilder(
        opaque: false,
        barrierColor: Colors.black87,
        pageBuilder: (_, __, ___) => SOSIncomingScreen(alert: alert),
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

  Future<void> _playAlarm() async {
    try {
      await _player.setReleaseMode(ReleaseMode.loop);
      await _player.play(AssetSource('audio/v1.mp3'));
      final hasVibrator = await Vibration.hasVibrator() ?? false;
      if (hasVibrator) {
        Vibration.vibrate(pattern: [0, 800, 400, 800], repeat: 0);
      }
    } catch (e) {
      debugPrint('[SOS] Loi phat am thanh: $e');
    }
  }

  Future<void> stopAlarm() async {
    try {
      await _player.stop();
      Vibration.cancel();
    } catch (e) {
      debugPrint('[SOS] Loi dung am thanh: $e');
    }
  }

  Future<void> acknowledgeAlert(String alertKey) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    try {
      await _db.ref('user_sos_alerts/$uid/$alertKey').update({
        'status': 'acknowledged',
        'is_read': true,
      });
    } catch (e) {
      debugPrint('[SOS] Loi xac nhan alert: $e');
    }
  }

  /// Đánh dấu 1 alert đã đọc (không đổi status).
  Future<void> markAsRead(String alertKey) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    try {
      await _db
          .ref('user_sos_alerts/$uid/$alertKey')
          .update({'is_read': true});
    } catch (e) {
      debugPrint('[SOS] Loi mark read: $e');
    }
  }

  /// Đánh dấu toàn bộ alert của user là đã đọc.
  Future<void> markAllAsRead() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    try {
      final ref = _db.ref('user_sos_alerts/$uid');
      final snap = await ref.get();
      if (!snap.exists || snap.value is! Map) return;
      final updates = <String, Object?>{};
      for (final e in (snap.value as Map).entries) {
        if (e.value is Map && (e.value as Map)['is_read'] != true) {
          updates['${e.key}/is_read'] = true;
        }
      }
      if (updates.isNotEmpty) await ref.update(updates);
    } catch (e) {
      debugPrint('[SOS] Loi mark all read: $e');
    }
  }

  /// Xóa 1 alert khỏi user_sos_alerts.
  Future<void> deleteAlert(String alertKey) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    try {
      await _db.ref('user_sos_alerts/$uid/$alertKey').remove();
    } catch (e) {
      debugPrint('[SOS] Loi xoa alert: $e');
    }
  }

  /// Xóa toàn bộ alerts của user.
  Future<void> deleteAllAlerts() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    try {
      await _db.ref('user_sos_alerts/$uid').remove();
    } catch (e) {
      debugPrint('[SOS] Loi xoa tat ca alerts: $e');
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) async {
    if (state == AppLifecycleState.resumed && _pendingAlert != null) {
      final alert = _pendingAlert!;
      _pendingAlert = null;
      // Delay nhỏ để router kịp mount sau khi app resume
      await Future.delayed(const Duration(milliseconds: 400));
      _showIncomingScreen(alert);
      FlutterOverlayWindow.closeOverlay().catchError((_) {});
    }
  }

  void stopListening() {
    _subscription?.cancel();
    _subscription = null;
    _pendingAlert = null;
    WidgetsBinding.instance.removeObserver(this);
    debugPrint('[SOS] Dung lang nghe canh bao');
  }

  void dispose() {
    stopListening();
    _player.dispose();
  }
}
