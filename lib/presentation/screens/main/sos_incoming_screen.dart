import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../config/app_routes.dart';
import '../../../core/widgets/cached_image.dart';
import '../../../data/datasources/sos_realtime_service.dart';

class SOSIncomingScreen extends StatefulWidget {
  static bool isShowing = false;

  final Map<String, dynamic> alert;
  const SOSIncomingScreen({super.key, required this.alert});

  @override
  State<SOSIncomingScreen> createState() => _SOSIncomingScreenState();
}

class _SOSIncomingScreenState extends State<SOSIncomingScreen>
    with TickerProviderStateMixin {
  late final AnimationController _pulseCtrl;
  late final AnimationController _ringCtrl;

  @override
  void initState() {
    super.initState();
    SOSIncomingScreen.isShowing = true;
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
    SOSIncomingScreen.isShowing = false;
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
    final imageUrl = widget.alert['image_url'] as String? ?? '';
    final hasImage = imageUrl.isNotEmpty;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Container(
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
              const SizedBox(height: 32),

              // Alert badge
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

              const SizedBox(height: 28),

              // Main visual: detection image or pulsing rings
              if (hasImage)
                _DetectionImage(
                  imageUrl: imageUrl,
                  pulseCtrl: _pulseCtrl,
                )
              else
                _PulsingRings(pulseCtrl: _pulseCtrl, ringCtrl: _ringCtrl),

              const SizedBox(height: 24),

              // Hive name
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: Text(
                  hiveName,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 26,
                    fontWeight: FontWeight.w700,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 10),

              // Detection info
              Text(
                'Phát hiện $count con · Độ tin cậy ${confidence.toStringAsFixed(0)}%',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.8),
                  fontSize: 14,
                ),
                textAlign: TextAlign.center,
              ),

              if (hasImage) ...[
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(LucideIcons.camera,
                        size: 13, color: Colors.white.withOpacity(0.5)),
                    const SizedBox(width: 5),
                    Text(
                      'Ảnh từ camera tracking',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.5),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ],

              const Spacer(),

              // Buttons
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 40, vertical: 32),
                child: Row(
                  children: [
                    Expanded(
                      child: _ActionButton(
                        icon: LucideIcons.x,
                        label: 'Bỏ qua',
                        bg: Colors.white.withOpacity(0.15),
                        onTap: () {
                          SOSRealtimeService().stopAlarm();
                          Navigator.of(context).pop();
                        },
                      ),
                    ),
                    const SizedBox(width: 24),
                    Expanded(
                      child: _ActionButton(
                        icon: LucideIcons.shieldAlert,
                        label: 'Xem ngay',
                        bg: const Color(0xFFDC2626),
                        onTap: () {
                          SOSRealtimeService().stopAlarm();
                          Navigator.of(context).pop();
                          final deviceId =
                              (widget.alert['device_id'] as String?)?.trim() ?? '';
                          if (deviceId.isNotEmpty) {
                            context.push('/hive/$deviceId');
                          } else {
                            context.go(AppRoutes.alerts);
                          }
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// --------------------------------------------------------------------------
// Detection Image widget — hiển thị ảnh Cloudinary có badge cảnh báo
// --------------------------------------------------------------------------
class _DetectionImage extends StatelessWidget {
  final String imageUrl;
  final AnimationController pulseCtrl;

  const _DetectionImage({required this.imageUrl, required this.pulseCtrl});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Stack(
        alignment: Alignment.topRight,
        children: [
          // Detection image
          AnimatedBuilder(
            animation: pulseCtrl,
            builder: (_, child) {
              final glow = 8.0 + pulseCtrl.value * 12.0;
              return Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.red.withOpacity(0.4 + pulseCtrl.value * 0.3),
                      blurRadius: glow,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: child,
              );
            },
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: CachedImage(
                imageUrl: imageUrl,
                width: double.infinity,
                height: 200,
              ),
            ),
          ),

          // Animated warning badge
          Positioned(
            top: 10,
            right: 10,
            child: AnimatedBuilder(
              animation: pulseCtrl,
              builder: (_, __) {
                final scale = 0.9 + pulseCtrl.value * 0.15;
                return Transform.scale(
                  scale: scale,
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: const Color(0xFFDC2626),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.red.withOpacity(0.6),
                          blurRadius: 10,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    child: const Icon(
                      LucideIcons.alertTriangle,
                      size: 20,
                      color: Colors.white,
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

// --------------------------------------------------------------------------
// Pulsing Rings widget — hiển thị khi không có ảnh
// --------------------------------------------------------------------------
class _PulsingRings extends StatelessWidget {
  final AnimationController pulseCtrl;
  final AnimationController ringCtrl;

  const _PulsingRings({required this.pulseCtrl, required this.ringCtrl});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 220,
      height: 220,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Outer ring
          AnimatedBuilder(
            animation: ringCtrl,
            builder: (_, __) {
              final scale = 1.0 + ringCtrl.value * 0.6;
              final opacity = (1.0 - ringCtrl.value).clamp(0.0, 1.0);
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
          // Middle ring
          AnimatedBuilder(
            animation: ringCtrl,
            builder: (_, __) {
              final t = (ringCtrl.value + 0.3) % 1.0;
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
          // Icon circle
          AnimatedBuilder(
            animation: pulseCtrl,
            builder: (_, __) {
              final scale = 0.95 + pulseCtrl.value * 0.1;
              return Transform.scale(
                scale: scale,
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
                    LucideIcons.alertTriangle,
                    size: 56,
                    color: Colors.white,
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

// --------------------------------------------------------------------------
// Action Button
// --------------------------------------------------------------------------
class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color bg;
  final VoidCallback onTap;

  const _ActionButton({
    required this.icon,
    required this.label,
    required this.bg,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 18),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          children: [
            Icon(icon, color: Colors.white, size: 26),
            const SizedBox(height: 6),
            Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
