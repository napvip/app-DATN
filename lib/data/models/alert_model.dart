import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../config/app_colors.dart';

enum AlertType { attack, temperature, offline, battery }

enum AlertSeverity { high, medium, low }

class AlertModel {
  final int id;
  final AlertType type;
  final String hive;
  final String title;
  final String description;
  final String time;
  final AlertSeverity severity;
  final String? imageUrl;
  final bool isRead;

  const AlertModel({
    required this.id,
    required this.type,
    required this.hive,
    required this.title,
    required this.description,
    required this.time,
    required this.severity,
    this.imageUrl,
    this.isRead = false,
  });

  IconData get icon {
    switch (type) {
      case AlertType.attack:
        return LucideIcons.alertTriangle;
      case AlertType.temperature:
        return LucideIcons.thermometer;
      case AlertType.offline:
        return LucideIcons.wifiOff;
      case AlertType.battery:
        return LucideIcons.batteryLow;
    }
  }

  Color get iconBackgroundColor {
    switch (severity) {
      case AlertSeverity.high:
        return AppColors.destructive.withValues(alpha: 0.1);
      case AlertSeverity.medium:
        return AppColors.warning.withValues(alpha: 0.1);
      case AlertSeverity.low:
        return AppColors.primary.withValues(alpha: 0.1);
    }
  }

  Color get iconColor {
    switch (severity) {
      case AlertSeverity.high:
        return AppColors.destructive;
      case AlertSeverity.medium:
        return AppColors.warning;
      case AlertSeverity.low:
        return AppColors.primary;
    }
  }

  static List<AlertModel> get mockData => [
        const AlertModel(
          id: 1,
          type: AlertType.attack,
          hive: 'Hive Alpha',
          title: 'Wasp Attack Detected',
          description: 'High wasp activity detected near hive entrance',
          time: '2 hours ago',
          severity: AlertSeverity.high,
          imageUrl:
              'https://images.unsplash.com/photo-1751167011495-074cf5f9ca66?w=200',
          isRead: false,
        ),
        const AlertModel(
          id: 2,
          type: AlertType.temperature,
          hive: 'Hive Beta',
          title: 'Temperature Alert',
          description: 'Temperature exceeded optimal range (38°C)',
          time: '5 hours ago',
          severity: AlertSeverity.medium,
          isRead: false,
        ),
        const AlertModel(
          id: 3,
          type: AlertType.offline,
          hive: 'Hive Gamma',
          title: 'Device Offline',
          description: 'Connection lost - last seen 3 hours ago',
          time: '8 hours ago',
          severity: AlertSeverity.high,
          isRead: true,
        ),
        const AlertModel(
          id: 4,
          type: AlertType.battery,
          hive: 'Hive Delta',
          title: 'Low Battery Warning',
          description: 'Device battery at 15% - charge needed',
          time: 'Yesterday',
          severity: AlertSeverity.low,
          isRead: true,
        ),
        const AlertModel(
          id: 5,
          type: AlertType.attack,
          hive: 'Hive Alpha',
          title: 'Wasp Activity',
          description: 'Medium wasp activity detected',
          time: 'Yesterday',
          severity: AlertSeverity.medium,
          imageUrl:
              'https://images.unsplash.com/photo-1751167011495-074cf5f9ca66?w=200',
          isRead: true,
        ),
      ];
}
