import 'dart:math';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../config/app_routes.dart';

class SOSIncomingScreen extends StatefulWidget {
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
              const SizedBox(height: 48),

              // Label
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

              // Pulsing rings + icon
              SizedBox(
                width: 220,
                height: 220,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    // Outer ring
                    AnimatedBuilder(
                      animation: _ringCtrl,
                      builder: (_, __) {
                        final scale = 1.0 + _ringCtrl.value * 0.6;
                        final opacity = (1.0 - _ringCtrl.value).clamp(0.0, 1.0);
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
                    // Icon circle
                    AnimatedBuilder(
                      animation: _pulseCtrl,
                      builder: (_, __) {
                        final scale = 0.95 + _pulseCtrl.value * 0.1;
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
              ),

              const SizedBox(height: 40),

              // Hive name
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

              // Detection info
              Text(
                'Phát hiện $count con · Độ tin cậy ${confidence.toStringAsFixed(0)}%',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.8),
                  fontSize: 15,
                ),
                textAlign: TextAlign.center,
              ),

              const Spacer(),

              // Buttons
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 40, vertical: 32),
                child: Row(
                  children: [
                    // Dismiss
                    Expanded(
                      child: _ActionButton(
                        icon: LucideIcons.x,
                        label: 'Bỏ qua',
                        bg: Colors.white.withOpacity(0.15),
                        onTap: () => Navigator.of(context).pop(),
                      ),
                    ),
                    const SizedBox(width: 24),
                    // View detail
                    Expanded(
                      child: _ActionButton(
                        icon: LucideIcons.shieldAlert,
                        label: 'Xem ngay',
                        bg: const Color(0xFFDC2626),
                        onTap: () {
                          Navigator.of(context).pop();
                          context.push(AppRoutes.sosAlert);
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
