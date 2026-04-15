import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../config/app_colors.dart';
import '../../widgets/app_card.dart';

class MaintenanceScreen extends StatefulWidget {
  const MaintenanceScreen({super.key});

  @override
  State<MaintenanceScreen> createState() => _MaintenanceScreenState();
}

class _MaintenanceScreenState extends State<MaintenanceScreen> {
  String _activeTab = 'upcoming';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 48, 24, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Maintenance',
                      style: Theme.of(context).textTheme.headlineLarge,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Manage device servicing & support',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: AppColors.mutedForeground,
                          ),
                    ),
                  ],
                ),
              ),

              // Quick Actions
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Row(
                  children: [
                    Expanded(
                      child: _QuickActionButton(
                        icon: LucideIcons.calendar,
                        label: 'Book Service',
                        isPrimary: true,
                        onTap: () {},
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _QuickActionButton(
                        icon: LucideIcons.messageCircle,
                        label: 'Live Chat',
                        isPrimary: false,
                        onTap: () {},
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Tabs
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: AppColors.muted,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: _TabButton(
                          label: 'Upcoming',
                          isSelected: _activeTab == 'upcoming',
                          onTap: () => setState(() => _activeTab = 'upcoming'),
                        ),
                      ),
                      Expanded(
                        child: _TabButton(
                          label: 'History',
                          isSelected: _activeTab == 'history',
                          onTap: () => setState(() => _activeTab = 'history'),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Content
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: _activeTab == 'upcoming'
                    ? _UpcomingServices()
                    : _ServiceHistory(),
              ),
              const SizedBox(height: 32),

              // Resources
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: _ResourcesCard(),
              ),
              const SizedBox(height: 100),
            ],
          ),
        ),
      ),
    );
  }
}

class _QuickActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isPrimary;
  final VoidCallback onTap;

  const _QuickActionButton({
    required this.icon,
    required this.label,
    required this.isPrimary,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isPrimary ? AppColors.primary : AppColors.card,
          borderRadius: BorderRadius.circular(16),
          border: isPrimary ? null : Border.all(color: AppColors.border),
          boxShadow: isPrimary
              ? [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.2),
                    blurRadius: 16,
                    offset: const Offset(0, 4),
                  ),
                ]
              : null,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              icon,
              size: 24,
              color: isPrimary ? AppColors.primaryForeground : AppColors.foreground,
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: isPrimary ? AppColors.primaryForeground : AppColors.foreground,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TabButton extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _TabButton({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.card : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              color: isSelected ? AppColors.foreground : AppColors.mutedForeground,
              fontWeight: isSelected ? FontWeight.w500 : FontWeight.w400,
            ),
          ),
        ),
      ),
    );
  }
}

class _UpcomingServices extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final services = [
      _ServiceData(
        hive: 'Hive Beta',
        type: 'Battery Replacement',
        date: 'Apr 12, 2026',
        time: '10:00 AM',
        technician: 'Mike Johnson',
      ),
      _ServiceData(
        hive: 'Hive Delta',
        type: 'Routine Inspection',
        date: 'Apr 15, 2026',
        time: '2:00 PM',
        technician: 'Sarah Williams',
      ),
    ];

    return Column(
      children: services
          .map((service) => Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: _ServiceCard(service: service, isHistory: false),
              ))
          .toList(),
    );
  }
}

class _ServiceHistory extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final services = [
      _ServiceData(
        hive: 'Hive Alpha',
        type: 'Camera Calibration',
        date: 'Apr 5, 2026',
        time: '',
        technician: '',
      ),
      _ServiceData(
        hive: 'Hive Gamma',
        type: 'Sensor Maintenance',
        date: 'Apr 2, 2026',
        time: '',
        technician: '',
      ),
    ];

    return Column(
      children: services
          .map((service) => Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: _ServiceCard(service: service, isHistory: true),
              ))
          .toList(),
    );
  }
}

class _ServiceData {
  final String hive;
  final String type;
  final String date;
  final String time;
  final String technician;

  const _ServiceData({
    required this.hive,
    required this.type,
    required this.date,
    required this.time,
    required this.technician,
  });
}

class _ServiceCard extends StatelessWidget {
  final _ServiceData service;
  final bool isHistory;

  const _ServiceCard({
    required this.service,
    required this.isHistory,
  });

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    service.type,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    service.hive,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
              if (isHistory)
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.success.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    LucideIcons.check,
                    size: 16,
                    color: AppColors.success,
                  ),
                )
              else
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Text(
                    'Scheduled',
                    style: TextStyle(
                      color: AppColors.primary,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              const Icon(
                LucideIcons.calendar,
                size: 16,
                color: AppColors.mutedForeground,
              ),
              const SizedBox(width: 8),
              Text(
                isHistory
                    ? service.date
                    : '${service.date} at ${service.time}',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],
          ),
          if (!isHistory && service.technician.isNotEmpty) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(
                  LucideIcons.shield,
                  size: 16,
                  color: AppColors.mutedForeground,
                ),
                const SizedBox(width: 8),
                Text(
                  'Technician: ${service.technician}',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {},
                    child: const Text('Reschedule'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {},
                    child: const Text('Cancel'),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _ResourcesCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Resources & Support',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 16),
          _ResourceItem(
            icon: LucideIcons.fileText,
            label: 'Troubleshooting Guide',
            onTap: () {},
          ),
          _ResourceItem(
            icon: LucideIcons.shield,
            label: 'Warranty Information',
            onTap: () {},
          ),
          _ResourceItem(
            icon: LucideIcons.messageCircle,
            label: 'Contact Support',
            onTap: () {},
          ),
        ],
      ),
    );
  }
}

class _ResourceItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _ResourceItem({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Row(
          children: [
            Icon(
              icon,
              size: 20,
              color: AppColors.mutedForeground,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ),
            const Icon(
              LucideIcons.chevronRight,
              size: 20,
              color: AppColors.mutedForeground,
            ),
          ],
        ),
      ),
    );
  }
}
