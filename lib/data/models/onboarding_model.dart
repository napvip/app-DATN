import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

class OnboardingModel {
  final IconData icon;
  final String title;
  final String description;
  final String imageUrl;

  const OnboardingModel({
    required this.icon,
    required this.title,
    required this.description,
    required this.imageUrl,
  });

  static List<OnboardingModel> get slides => [
        const OnboardingModel(
          icon: LucideIcons.shield,
          title: 'Bảo vệ đàn ong 24/7',
          description:
              'Cảm biến và camera tracker giám sát thùng ong liên tục, '
              'phát hiện và cảnh báo ong bắp cày ngay khi xuất hiện.',
          imageUrl:
              'https://images.unsplash.com/photo-1569127971771-15d19a5ba26c?w=600',
        ),
        const OnboardingModel(
          icon: LucideIcons.camera,
          title: 'Phát hiện ong bắp cày bằng AI',
          description:
              'Mô hình YOLOv11 nhận diện ong bắp cày theo thời gian thực, '
              'gửi cảnh báo SOS kèm ảnh tới điện thoại của bạn.',
          imageUrl:
              'https://images.unsplash.com/photo-1751167011495-074cf5f9ca66?w=600',
        ),
        const OnboardingModel(
          icon: LucideIcons.settings2,
          title: 'Điều khiển từ xa qua điện thoại',
          description:
              'Bật/tắt camera, tracking, kết nối ESP32 và hiệu chỉnh thông '
              'số mọi lúc — không cần đến tận nơi đặt thiết bị.',
          imageUrl:
              'https://images.unsplash.com/photo-1758522964459-403b982fb3c2?w=600',
        ),
      ];
}
