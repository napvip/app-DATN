import 'dart:convert';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:gal/gal.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../../config/app_colors.dart';

/// Màn hình xem mã QR của thiết bị tracking.
///
/// QR encode JSON theo format của BeeGuard tracker:
///   {"type": "beeguard_tracker", "device_id": "...", "device_name": "..."}
/// Cho phép lưu ảnh QR vào thư viện ảnh để in/chia sẻ.
class DeviceQrScreen extends StatefulWidget {
  final String deviceId;
  const DeviceQrScreen({super.key, required this.deviceId});

  @override
  State<DeviceQrScreen> createState() => _DeviceQrScreenState();
}

class _DeviceQrScreenState extends State<DeviceQrScreen> {
  static const _dbUrl =
      'https://doan-hotronuoiong-default-rtdb.asia-southeast1.firebasedatabase.app';

  final GlobalKey _qrKey = GlobalKey();
  bool _saving = false;
  String? _deviceName;
  String? _hiveName;

  @override
  void initState() {
    super.initState();
    _fetchDeviceInfo();
  }

  Future<void> _fetchDeviceInfo() async {
    try {
      final ref = FirebaseDatabase.instanceFor(
        app: Firebase.app(),
        databaseURL: _dbUrl,
      ).ref('tracking_devices/${widget.deviceId}');
      final snap = await ref.get();
      if (!mounted) return;
      if (snap.exists && snap.value is Map) {
        final m = Map<dynamic, dynamic>.from(snap.value as Map);
        setState(() {
          _deviceName = (m['device_name'] ?? '').toString();
          _hiveName = (m['hive_name'] ?? '').toString();
        });
      }
    } catch (_) {
      // ignore — vẫn hiển thị QR với deviceId
    }
  }

  String get _qrPayload {
    return json.encode({
      'type': 'beeguard_tracker',
      'device_id': widget.deviceId,
      'device_name': _deviceName ?? '',
    });
  }

  Future<void> _saveToGallery() async {
    if (_saving) return;
    setState(() => _saving = true);
    try {
      final bytes = await _captureQr();
      if (bytes == null) {
        throw Exception('Không tạo được ảnh từ QR');
      }

      final hasAccess = await Gal.hasAccess();
      if (!hasAccess) {
        final granted = await Gal.requestAccess();
        if (!granted) {
          throw Exception('Không có quyền truy cập thư viện ảnh');
        }
      }

      await Gal.putImageBytes(
        bytes,
        album: 'BeeGuard',
        name: 'QR_${widget.deviceId}',
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Đã lưu ảnh QR vào thư viện ảnh'),
          behavior: SnackBarBehavior.floating,
          backgroundColor: AppColors.success,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Lưu thất bại: $e'),
          backgroundColor: AppColors.destructive,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<Uint8List?> _captureQr() async {
    final boundary =
        _qrKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
    if (boundary == null) return null;
    final image = await boundary.toImage(pixelRatio: 4.0);
    final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    return byteData?.buffer.asUint8List();
  }

  @override
  Widget build(BuildContext context) {
    final name = (_deviceName ?? '').isNotEmpty ? _deviceName! : 'BeeGuard Tracker';

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        title: const Text('Mã QR thiết bị'),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
          child: Column(
            children: [
              Expanded(
                child: Center(
                  child: RepaintBoundary(
                    key: _qrKey,
                    child: Container(
                      padding: const EdgeInsets.all(28),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(28),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          QrImageView(
                            data: _qrPayload,
                            version: QrVersions.auto,
                            size: 260,
                            errorCorrectionLevel: QrErrorCorrectLevel.H,
                            backgroundColor: Colors.white,
                            eyeStyle: const QrEyeStyle(
                              eyeShape: QrEyeShape.square,
                              color: Colors.black,
                            ),
                            dataModuleStyle: const QrDataModuleStyle(
                              dataModuleShape: QrDataModuleShape.square,
                              color: Colors.black,
                            ),
                          ),
                          const SizedBox(height: 18),
                          Text(
                            name,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              color: Colors.black,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            widget.deviceId,
                            style: const TextStyle(
                              fontSize: 13,
                              fontFamily: 'monospace',
                              color: Color(0xFF555555),
                            ),
                          ),
                          if ((_hiveName ?? '').isNotEmpty) ...[
                            const SizedBox(height: 4),
                            Text(
                              'Thùng ong: ${_hiveName!}',
                              style: const TextStyle(
                                fontSize: 12,
                                color: Color(0xFF777777),
                              ),
                            ),
                          ],
                          const SizedBox(height: 8),
                          const Text(
                            'BeeGuard Tracking System',
                            style: TextStyle(
                              fontSize: 11,
                              color: Color(0xFF999999),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              const _HintBar(),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _saving ? null : _saveToGallery,
                  icon: _saving
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(LucideIcons.download, size: 18),
                  label: Text(_saving ? 'Đang lưu...' : 'Lưu ảnh QR'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: AppColors.primaryForeground,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    elevation: 0,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _HintBar extends StatelessWidget {
  const _HintBar();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.accent,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          const Icon(LucideIcons.info, size: 16,
              color: AppColors.accentForeground),
          const SizedBox(width: 8),
          const Expanded(
            child: Text(
              'In ảnh QR rồi dán lên thiết bị để người khác có thể quét '
              'liên kết tới tài khoản của họ.',
              style: TextStyle(
                fontSize: 12,
                color: AppColors.accentForeground,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
