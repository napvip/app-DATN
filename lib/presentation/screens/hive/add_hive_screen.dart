import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../config/app_colors.dart';
import '../../../config/app_routes.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_card.dart';

enum AddHiveStep { scan, connecting, success }

class AddHiveScreen extends StatefulWidget {
  const AddHiveScreen({super.key});

  @override
  State<AddHiveScreen> createState() => _AddHiveScreenState();
}

class _AddHiveScreenState extends State<AddHiveScreen>
    with SingleTickerProviderStateMixin {
  AddHiveStep _step = AddHiveStep.scan;
  late AnimationController _scanController;

  @override
  void initState() {
    super.initState();
    _scanController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat();
  }

  @override
  void dispose() {
    _scanController.dispose();
    super.dispose();
  }

  void _simulateScan() {
    setState(() => _step = AddHiveStep.connecting);
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        setState(() => _step = AddHiveStep.success);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(LucideIcons.arrowLeft),
          onPressed: () => context.go(AppRoutes.main),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Add New Hive'),
            Text(
              'Scan QR code on device',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ),
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              child: switch (_step) {
                AddHiveStep.scan => _ScanView(
                    scanController: _scanController,
                    onScan: _simulateScan,
                  ),
                AddHiveStep.connecting => const _ConnectingView(),
                AddHiveStep.success => _SuccessView(
                    onDone: () => context.go(AppRoutes.main),
                  ),
              },
            ),
          ),
        ),
      ),
    );
  }
}

class _ScanView extends StatelessWidget {
  final AnimationController scanController;
  final VoidCallback onScan;

  const _ScanView({
    required this.scanController,
    required this.onScan,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // QR Scanner Frame
        Container(
          constraints: const BoxConstraints(maxWidth: 350),
          child: AspectRatio(
            aspectRatio: 1,
            child: Container(
              decoration: BoxDecoration(
                color: AppColors.muted,
                borderRadius: BorderRadius.circular(24),
              ),
              child: Stack(
                children: [
                  // Scanning line animation
                  AnimatedBuilder(
                    animation: scanController,
                    builder: (context, child) {
                      return Positioned(
                        top: scanController.value *
                            (MediaQuery.of(context).size.width * 0.8),
                        left: 0,
                        right: 0,
                        child: Container(
                          height: 4,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                Colors.transparent,
                                AppColors.primary,
                                Colors.transparent,
                              ],
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.primary.withValues(alpha: 0.5),
                                blurRadius: 8,
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),

                  // Corner markers
                  Positioned(
                    top: 32,
                    left: 32,
                    child: _CornerMarker(isTopLeft: true),
                  ),
                  Positioned(
                    top: 32,
                    right: 32,
                    child: _CornerMarker(isTopRight: true),
                  ),
                  Positioned(
                    bottom: 32,
                    left: 32,
                    child: _CornerMarker(isBottomLeft: true),
                  ),
                  Positioned(
                    bottom: 32,
                    right: 32,
                    child: _CornerMarker(isBottomRight: true),
                  ),

                  // Camera icon
                  const Center(
                    child: Icon(
                      LucideIcons.camera,
                      size: 64,
                      color: AppColors.mutedForeground,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 32),

        Text(
          'Position QR Code',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 8),
        Text(
          'Align the QR code on your BeeGuard device within the frame',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppColors.mutedForeground,
              ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 32),

        AppButton(
          text: 'Simulate Scan',
          onPressed: onScan,
          width: double.infinity,
        ),
      ],
    );
  }
}

class _CornerMarker extends StatelessWidget {
  final bool isTopLeft;
  final bool isTopRight;
  final bool isBottomLeft;
  final bool isBottomRight;

  const _CornerMarker({
    this.isTopLeft = false,
    this.isTopRight = false,
    this.isBottomLeft = false,
    this.isBottomRight = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        border: Border(
          top: isTopLeft || isTopRight
              ? const BorderSide(color: AppColors.primary, width: 4)
              : BorderSide.none,
          bottom: isBottomLeft || isBottomRight
              ? const BorderSide(color: AppColors.primary, width: 4)
              : BorderSide.none,
          left: isTopLeft || isBottomLeft
              ? const BorderSide(color: AppColors.primary, width: 4)
              : BorderSide.none,
          right: isTopRight || isBottomRight
              ? const BorderSide(color: AppColors.primary, width: 4)
              : BorderSide.none,
        ),
        borderRadius: BorderRadius.only(
          topLeft: isTopLeft ? const Radius.circular(16) : Radius.zero,
          topRight: isTopRight ? const Radius.circular(16) : Radius.zero,
          bottomLeft: isBottomLeft ? const Radius.circular(16) : Radius.zero,
          bottomRight: isBottomRight ? const Radius.circular(16) : Radius.zero,
        ),
      ),
    );
  }
}

class _ConnectingView extends StatelessWidget {
  const _ConnectingView();

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          padding: const EdgeInsets.all(32),
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: const SizedBox(
            width: 64,
            height: 64,
            child: CircularProgressIndicator(
              strokeWidth: 3,
              valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
            ),
          ),
        ),
        const SizedBox(height: 32),
        Text(
          'Connecting to Device',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 8),
        Text(
          'Please wait while we establish a secure connection...',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppColors.mutedForeground,
              ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}

class _SuccessView extends StatelessWidget {
  final VoidCallback onDone;

  const _SuccessView({required this.onDone});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        TweenAnimationBuilder<double>(
          tween: Tween(begin: 0.0, end: 1.0),
          duration: const Duration(milliseconds: 500),
          curve: Curves.elasticOut,
          builder: (context, value, child) {
            return Transform.scale(
              scale: value,
              child: Container(
                padding: const EdgeInsets.all(32),
                decoration: BoxDecoration(
                  color: AppColors.success.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  LucideIcons.check,
                  size: 64,
                  color: AppColors.success,
                ),
              ),
            );
          },
        ),
        const SizedBox(height: 32),
        Text(
          'Device Connected!',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 8),
        Text(
          'Your new hive has been successfully added and is now being monitored.',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppColors.mutedForeground,
              ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 32),

        // Device Info Card
        AppCard(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Device Information',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 16),
              _InfoRow(label: 'Device ID', value: 'BG-4521-8932'),
              const SizedBox(height: 12),
              _InfoRow(label: 'Hive Name', value: 'Hive Epsilon'),
              const SizedBox(height: 12),
              _InfoRow(
                label: 'Battery',
                value: '98%',
                valueColor: AppColors.success,
              ),
              const SizedBox(height: 12),
              _InfoRow(
                label: 'Status',
                value: 'Online',
                valueColor: AppColors.success,
              ),
            ],
          ),
        ),
        const SizedBox(height: 32),

        AppButton(
          text: 'Go to Dashboard',
          onPressed: onDone,
          width: double.infinity,
        ),
      ],
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;

  const _InfoRow({
    required this.label,
    required this.value,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall,
        ),
        Text(
          value,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: valueColor,
              ),
        ),
      ],
    );
  }
}
