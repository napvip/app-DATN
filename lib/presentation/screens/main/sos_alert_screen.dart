import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';

import '../../../config/app_colors.dart';
import '../../../data/datasources/sos_realtime_service.dart';

const _kDbUrl =
    'https://doan-hotronuoiong-default-rtdb.asia-southeast1.firebasedatabase.app';

class SOSAlertScreen extends StatelessWidget {
  const SOSAlertScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Cảnh báo'),
        actions: [
          TextButton(
            onPressed: SOSRealtimeService().stopAlarm,
            child: const Text('Tắt chuông'),
          ),
        ],
      ),
      body: user == null
          ? const Center(child: Text('Chưa đăng nhập'))
          : StreamBuilder<DatabaseEvent>(
              stream: FirebaseDatabase.instanceFor(
                        app: Firebase.app(),
                        databaseURL: _kDbUrl,
                      )
                      .ref('user_sos_alerts/${user.uid}')
                      .onValue,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(color: AppColors.primary),
                  );
                }

                final data = snapshot.data?.snapshot.value;
                if (data == null) return const _EmptyState();

                final raw = Map<String, dynamic>.from(data as Map);
                final alerts = raw.entries
                    .map((e) => {
                          'key': e.key,
                          ...Map<String, dynamic>.from(e.value as Map),
                        })
                    .toList()
                  ..sort((a, b) =>
                      ((b['created_at'] as int?) ?? 0)
                          .compareTo((a['created_at'] as int?) ?? 0));

                if (alerts.isEmpty) return const _EmptyState();

                return ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: alerts.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (context, i) => _AlertCard(alert: alerts[i]),
                );
              },
            ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Không có cảnh báo nào',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w500,
              color: AppColors.foreground,
            ),
          ),
          SizedBox(height: 4),
          Text(
            'Hệ thống sẽ thông báo khi phát hiện ong bắp cày',
            style: TextStyle(fontSize: 13, color: AppColors.mutedForeground),
          ),
        ],
      ),
    );
  }
}

class _AlertCard extends StatelessWidget {
  final Map<String, dynamic> alert;
  const _AlertCard({required this.alert});

  @override
  Widget build(BuildContext context) {
    final status = alert['status'] as String? ?? 'active';
    final isActive = status == 'active';
    final hiveName = alert['hive_name'] as String? ?? 'Thùng ong không xác định';
    final count = alert['detection_count'] as int? ?? 0;
    final confidence = ((alert['confidence'] as num?)?.toDouble() ?? 0) * 100;
    final deviceId = alert['device_id'] as String? ?? '';
    final createdAt = alert['created_at'] as int? ?? 0;
    final key = alert['key'] as String? ?? '';

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isActive ? const Color(0xFFFEF2F2) : AppColors.card,
        border: Border.all(
          color: isActive
              ? const Color(0xFFFECACA)
              : AppColors.border,
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  hiveName,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: AppColors.foreground,
                  ),
                ),
              ),
              _StatusBadge(status: status),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            'Phát hiện $count ong bắp cày · Độ tin cậy ${confidence.toStringAsFixed(0)}%',
            style: const TextStyle(
              fontSize: 13,
              color: AppColors.mutedForeground,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Text(
                deviceId,
                style: const TextStyle(
                  fontSize: 11,
                  fontFamily: 'monospace',
                  color: AppColors.mutedForeground,
                ),
              ),
              const Spacer(),
              Text(
                _relativeTime(createdAt),
                style: const TextStyle(
                  fontSize: 11,
                  color: AppColors.mutedForeground,
                ),
              ),
            ],
          ),
          if (isActive && key.isNotEmpty) ...[
            const SizedBox(height: 12),
            OutlinedButton(
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.success,
                side: const BorderSide(color: Color(0xFFBBF7D0)),
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                textStyle: const TextStyle(fontSize: 13),
              ),
              onPressed: () => SOSRealtimeService().acknowledgeAlert(key),
              child: const Text('Đã xử lý'),
            ),
          ],
        ],
      ),
    );
  }

  String _relativeTime(int ms) {
    if (ms == 0) return '';
    final diff = DateTime.now().millisecondsSinceEpoch - ms;
    if (diff < 60000) return 'Vừa xong';
    if (diff < 3600000) return '${diff ~/ 60000} phút trước';
    if (diff < 86400000) return '${diff ~/ 3600000} giờ trước';
    return '${diff ~/ 86400000} ngày trước';
  }
}

class _StatusBadge extends StatelessWidget {
  final String status;
  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    final Color bg;
    final Color textColor;
    final String label;

    switch (status) {
      case 'active':
        bg = const Color(0xFFFEE2E2);
        textColor = AppColors.destructive;
        label = 'Đang cảnh báo';
      case 'acknowledged':
        bg = const Color(0xFFFEF3C7);
        textColor = AppColors.warning;
        label = 'Đã xem';
      default:
        bg = const Color(0xFFDCFCE7);
        textColor = AppColors.success;
        label = 'Đã xử lý';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w500,
          color: textColor,
        ),
      ),
    );
  }
}
