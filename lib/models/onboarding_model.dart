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
          icon: LucideIcons.hexagon,
          title: 'Monitor Your Hives Remotely',
          description:
              'Keep track of all your beehives from anywhere. Get real-time updates on temperature, humidity, and honey production.',
          imageUrl:
              'https://images.unsplash.com/photo-1569127971771-15d19a5ba26c?w=600',
        ),
        const OnboardingModel(
          icon: LucideIcons.camera,
          title: 'AI Wasp Attack Detection',
          description:
              'Advanced AI instantly detects wasp attacks and sends you alerts with captured images, so you can protect your bees immediately.',
          imageUrl:
              'https://images.unsplash.com/photo-1751167011495-074cf5f9ca66?w=600',
        ),
        const OnboardingModel(
          icon: LucideIcons.trendingUp,
          title: 'Smart Honey Production Analytics',
          description:
              'Track honey production trends, analyze hive performance, and get AI-powered predictions for optimal beekeeping.',
          imageUrl:
              'https://images.unsplash.com/photo-1758522964459-403b982fb3c2?w=600',
        ),
      ];
}
