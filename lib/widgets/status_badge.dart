import 'package:flutter/material.dart';
import '../config/app_colors.dart';
import '../models/hive_model.dart';

class StatusBadge extends StatelessWidget {
  final HiveStatus status;

  const StatusBadge({super.key, required this.status});

  Color get backgroundColor {
    switch (status) {
      case HiveStatus.healthy:
        return AppColors.success;
      case HiveStatus.warning:
        return AppColors.warning;
      case HiveStatus.attack:
        return AppColors.destructive;
    }
  }

  String get text {
    switch (status) {
      case HiveStatus.healthy:
        return 'Healthy';
      case HiveStatus.warning:
        return 'Warning';
      case HiveStatus.attack:
        return 'Wasp Attack!';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        text,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}
