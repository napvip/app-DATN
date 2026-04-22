import 'dart:convert';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../../../config/app_colors.dart';

const _kDbUrl =
    'https://doan-hotronuoiong-default-rtdb.asia-southeast1.firebasedatabase.app';

class QRScannerScreen extends StatefulWidget {
  const QRScannerScreen({super.key});

  @override
  State<QRScannerScreen> createState() => _QRScannerScreenState();
}

class _QRScannerScreenState extends State<QRScannerScreen> {
  final MobileScannerController _controller = MobileScannerController();
  bool _processing = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onDetect(BarcodeCapture capture) {
    if (_processing) return;
    final raw = capture.barcodes.firstOrNull?.rawValue;
    if (raw == null) return;

    Map<String, dynamic> data;
    try {
      data = json.decode(raw) as Map<String, dynamic>;
    } catch (_) {
      _showError('QR code không hợp lệ');
      return;
    }

    if (data['type'] != 'beeguard_tracker') {
      _showError('QR code không phải thiết bị BeeGuard');
      return;
    }

    setState(() => _processing = true);
    _controller.stop();
    _showAddDialog(
      deviceId: data['device_id'] as String? ?? '',
      deviceName: data['device_name'] as String? ?? '',
    );
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: AppColors.destructive,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showAddDialog({required String deviceId, required String deviceName}) {
    final hiveController = TextEditingController();

    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.card,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Text(
          'Thêm thiết bị tracking',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: AppColors.foreground,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              deviceName,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: AppColors.foreground,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              deviceId,
              style: const TextStyle(
                fontSize: 12,
                fontFamily: 'monospace',
                color: AppColors.mutedForeground,
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: hiveController,
              autofocus: true,
              decoration: const InputDecoration(
                hintText: 'Tên thùng ong',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              setState(() => _processing = false);
              _controller.start();
            },
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: AppColors.primaryForeground,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 0,
            ),
            onPressed: () async {
              final hiveName = hiveController.text.trim();
              Navigator.pop(ctx);
              await _saveDevice(
                deviceId: deviceId,
                deviceName: deviceName,
                hiveName: hiveName,
              );
            },
            child: const Text('Thêm'),
          ),
        ],
      ),
    );
  }

  Future<void> _saveDevice({
    required String deviceId,
    required String deviceName,
    required String hiveName,
  }) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final db = FirebaseDatabase.instanceFor(
      app: Firebase.app(),
      databaseURL: _kDbUrl,
    );
    final now = DateTime.now().millisecondsSinceEpoch;

    try {
      await Future.wait([
        db.ref('tracking_devices/$deviceId').set({
          'device_id': deviceId,
          'device_name': deviceName,
          'owner_uid': user.uid,
          'hive_name': hiveName,
          'status': 'unregistered',
          'created_at': now,
          'last_seen': 0,
        }),
        db.ref('user_devices/${user.uid}/$deviceId').set({
          'device_id': deviceId,
          'hive_name': hiveName,
          'added_at': now,
        }),
      ]);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Đã thêm thiết bị thành công'),
            behavior: SnackBarBehavior.floating,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        _showError('Lỗi khi lưu thiết bị: $e');
        setState(() => _processing = false);
        _controller.start();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: const Text('Quét mã QR'),
      ),
      body: Stack(
        children: [
          MobileScanner(
            controller: _controller,
            onDetect: _onDetect,
          ),
          // Dark overlay with scan frame cutout
          _ScanOverlay(),
          // Guide text
          Positioned(
            bottom: 60,
            left: 32,
            right: 32,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.87),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Text(
                'Đặt mã QR thiết bị BeeGuard vào khung để quét',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white, fontSize: 13),
              ),
            ),
          ),
          // Processing indicator
          if (_processing)
            const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            ),
        ],
      ),
    );
  }
}

class _ScanOverlay extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    const frameSize = 260.0;
    return CustomPaint(
      size: Size.infinite,
      painter: _OverlayPainter(frameSize: frameSize),
    );
  }
}

class _OverlayPainter extends CustomPainter {
  final double frameSize;
  const _OverlayPainter({required this.frameSize});

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    final half = frameSize / 2;

    final overlayPaint = Paint()..color = Colors.black.withOpacity(0.55);
    final framePaint = Paint()
      ..color = AppColors.primary
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;

    final cutout = Rect.fromCenter(
      center: Offset(cx, cy),
      width: frameSize,
      height: frameSize,
    );

    final full = Rect.fromLTWH(0, 0, size.width, size.height);
    final path = Path()
      ..addRect(full)
      ..addRRect(
        RRect.fromRectAndRadius(cutout, const Radius.circular(20)),
      )
      ..fillType = PathFillType.evenOdd;
    canvas.drawPath(path, overlayPaint);

    canvas.drawRRect(
      RRect.fromRectAndRadius(cutout, const Radius.circular(20)),
      framePaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
