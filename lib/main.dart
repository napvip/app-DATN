import 'dart:convert';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_overlay_window/flutter_overlay_window.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'firebase_options.dart';
import 'config/app_theme.dart';
import 'config/app_routes.dart';
import 'data/datasources/sos_realtime_service.dart';
import 'data/datasources/notification_service.dart';
import 'presentation/screens/main/sos_incoming_screen.dart';

// Entry point riêng cho overlay window (chạy trong isolate khác)
@pragma('vm:entry-point')
void overlayMain() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const _SOSOverlayApp());
}

class _SOSOverlayApp extends StatefulWidget {
  const _SOSOverlayApp();

  @override
  State<_SOSOverlayApp> createState() => _SOSOverlayAppState();
}

class _SOSOverlayAppState extends State<_SOSOverlayApp> {
  Map<String, dynamic> _alert = {};

  @override
  void initState() {
    super.initState();
    FlutterOverlayWindow.overlayListener.listen((data) {
      if (data != null) {
        try {
          setState(() => _alert = Map<String, dynamic>.from(
              jsonDecode(data.toString()) as Map));
        } catch (_) {}
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        backgroundColor: Colors.transparent,
        body: _SOSOverlayBody(
          alert: _alert,
          onDismiss: () => FlutterOverlayWindow.closeOverlay(),
        ),
      ),
    );
  }
}

class _SOSOverlayBody extends StatefulWidget {
  final Map<String, dynamic> alert;
  final VoidCallback onDismiss;
  const _SOSOverlayBody({required this.alert, required this.onDismiss});

  @override
  State<_SOSOverlayBody> createState() => _SOSOverlayBodyState();
}

class _SOSOverlayBodyState extends State<_SOSOverlayBody>
    with TickerProviderStateMixin {
  late final AnimationController _pulseCtrl;
  late final AnimationController _ringCtrl;

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat(reverse: true);
    _ringCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat();
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    _ringCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final hiveName = widget.alert['hive_name'] as String? ?? 'Thùng ong';
    final count = widget.alert['detection_count'] as int? ?? 0;
    final confidence =
        ((widget.alert['confidence'] as num?)?.toDouble() ?? 0) * 100;

    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF7F0000), Color(0xFF1A0000)],
        ),
      ),
      child: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 48),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.15),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Text(
                'CẢNH BÁO ONG BẮP CÀY',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.5,
                ),
              ),
            ),
            const SizedBox(height: 48),
            SizedBox(
              width: 220,
              height: 220,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  AnimatedBuilder(
                    animation: _ringCtrl,
                    builder: (_, __) {
                      final scale = 1.0 + _ringCtrl.value * 0.6;
                      final opacity =
                          (1.0 - _ringCtrl.value).clamp(0.0, 1.0);
                      return Transform.scale(
                        scale: scale,
                        child: Container(
                          width: 160,
                          height: 160,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: Colors.red.withOpacity(opacity * 0.6),
                              width: 2,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                  AnimatedBuilder(
                    animation: _ringCtrl,
                    builder: (_, __) {
                      final t = (_ringCtrl.value + 0.3) % 1.0;
                      final scale = 1.0 + t * 0.6;
                      final opacity = (1.0 - t).clamp(0.0, 1.0);
                      return Transform.scale(
                        scale: scale,
                        child: Container(
                          width: 160,
                          height: 160,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: Colors.red.withOpacity(opacity * 0.6),
                              width: 2,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                  AnimatedBuilder(
                    animation: _pulseCtrl,
                    builder: (_, __) => Transform.scale(
                      scale: 0.95 + _pulseCtrl.value * 0.1,
                      child: Container(
                        width: 130,
                        height: 130,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: const Color(0xFFDC2626),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.red.withOpacity(0.5),
                              blurRadius: 24,
                              spreadRadius: 4,
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.warning_amber_rounded,
                          size: 56,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 40),
            Text(
              hiveName,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 28,
                fontWeight: FontWeight.w700,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              'Phát hiện $count con · Độ tin cậy ${confidence.toStringAsFixed(0)}%',
              style: TextStyle(
                color: Colors.white.withOpacity(0.8),
                fontSize: 15,
              ),
              textAlign: TextAlign.center,
            ),
            const Spacer(),
            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 40, vertical: 32),
              child: Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: widget.onDismiss,
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 18),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Column(
                          children: [
                            Icon(Icons.close, color: Colors.white, size: 26),
                            SizedBox(height: 6),
                            Text('Bỏ qua',
                                style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600)),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 24),
                  Expanded(
                    child: GestureDetector(
                      onTap: widget.onDismiss,
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 18),
                        decoration: BoxDecoration(
                          color: const Color(0xFFDC2626),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Column(
                          children: [
                            Icon(Icons.shield, color: Colors.white, size: 26),
                            SizedBox(height: 6),
                            Text('Xem ngay',
                                style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600)),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await dotenv.load(fileName: '.env');

  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } on FirebaseException catch (e) {
    if (e.code != 'duplicate-app') rethrow;
  }

  // Đăng ký background handler ngay sau Firebase init, trước mọi thứ khác
  FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

  await NotificationService.init();

  FirebaseAuth.instance.authStateChanges().listen((user) {
    if (user != null) {
      SOSRealtimeService().startListening();
    } else {
      SOSRealtimeService().stopListening();
    }
  });

  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      systemNavigationBarColor: Colors.white,
      systemNavigationBarIconBrightness: Brightness.dark,
    ),
  );

  runApp(
    const ProviderScope(
      child: BeeGuardApp(),
    ),
  );

  // Xin quyền overlay sau khi app đã chạy — không block main thread
  WidgetsBinding.instance.addPostFrameCallback((_) async {
    if (!await FlutterOverlayWindow.isPermissionGranted()) {
      await FlutterOverlayWindow.requestPermission();
    }
  });
}

class BeeGuardApp extends StatelessWidget {
  const BeeGuardApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'BeeGuard',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      routerConfig: AppRoutes.router,
    );
  }
}
