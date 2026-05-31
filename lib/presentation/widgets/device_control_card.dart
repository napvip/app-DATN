import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../config/app_colors.dart';
import '../../core/widgets/app_card.dart';

/// Card điều khiển từ xa thiết bị tracking.
///
/// - Đọc trạng thái `tracking_devices/{deviceId}/state` realtime từ RTDB.
/// - Gửi lệnh bằng cách `push()` node mới vào `commands/`. Tracker (Python)
///   sẽ poll, thực thi và đánh dấu `status: done|error`.
class DeviceControlCard extends StatefulWidget {
  final String deviceId;
  const DeviceControlCard({super.key, required this.deviceId});

  @override
  State<DeviceControlCard> createState() => _DeviceControlCardState();
}

class _DeviceControlCardState extends State<DeviceControlCard> {
  static const _dbUrl =
      'https://doan-hotronuoiong-default-rtdb.asia-southeast1.firebasedatabase.app';

  late final DatabaseReference _stateRef;
  late final DatabaseReference _commandsRef;
  late final DatabaseReference _deviceRef;
  late final Stream<DatabaseEvent> _stateStream;
  late final Stream<DatabaseEvent> _deviceStream;

  // Local override khi user vừa kéo slider, dùng để hiển thị mượt cho tới khi
  // state mới về. Map theo tên param → giá trị + timestamp set local.
  final Map<String, double> _localOverride = {};
  final Map<String, DateTime> _localOverrideTime = {};

  // Debounce push command cho từng param
  final Map<String, Timer> _debounce = {};

  @override
  void initState() {
    super.initState();
    final db = FirebaseDatabase.instanceFor(
      app: Firebase.app(),
      databaseURL: _dbUrl,
    );
    _stateRef = db.ref('tracking_devices/${widget.deviceId}/state');
    _commandsRef = db.ref('tracking_devices/${widget.deviceId}/commands');
    _deviceRef = db.ref('tracking_devices/${widget.deviceId}');
    _stateStream = _stateRef.onValue;
    _deviceStream = _deviceRef.child('status').onValue;
  }

  @override
  void dispose() {
    for (final t in _debounce.values) {
      t.cancel();
    }
    super.dispose();
  }

  // ── Helpers ────────────────────────────────────────────────────────────────
  static double? _d(dynamic v) {
    if (v is double) return v;
    if (v is int) return v.toDouble();
    if (v is String) return double.tryParse(v);
    return null;
  }

  static bool _b(dynamic v) {
    if (v is bool) return v;
    if (v is num) return v != 0;
    if (v is String) return v.toLowerCase() == 'true' || v == '1';
    return false;
  }

  static List<String> _list(dynamic v) {
    if (v is List) {
      return v.map((e) => e.toString()).toList();
    }
    return const [];
  }

  Future<void> _pushCommand(String type, Map<String, dynamic> payload) async {
    try {
      await _commandsRef.push().set({
        'type': type,
        'payload': payload,
        'created_at': ServerValue.timestamp,
        'status': 'pending',
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Không gửi được lệnh: $e')),
        );
      }
    }
  }

  void _onParamChanged(String key, double value) {
    setState(() {
      _localOverride[key] = value;
      _localOverrideTime[key] = DateTime.now();
    });
    _debounce[key]?.cancel();
    _debounce[key] = Timer(const Duration(milliseconds: 400), () {
      _pushCommand('set_params', {key: value});
    });
  }

  /// Đọc giá trị hiển thị: ưu tiên local override (≤ 3s sau khi user kéo)
  /// rồi mới đến state từ server.
  double _displayValue(String key, double? serverVal, double fallback) {
    final ov = _localOverride[key];
    final ts = _localOverrideTime[key];
    if (ov != null && ts != null &&
        DateTime.now().difference(ts) < const Duration(seconds: 3)) {
      return ov;
    }
    if (serverVal != null) {
      // server đã catch up → xoá override
      if (ov != null && (ov - serverVal).abs() < 0.05) {
        _localOverride.remove(key);
        _localOverrideTime.remove(key);
      }
      return serverVal;
    }
    return fallback;
  }

  // ── UI ─────────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<DatabaseEvent>(
      stream: _stateStream,
      builder: (context, snap) {
        Map<dynamic, dynamic>? state;
        if (snap.hasData && snap.data?.snapshot.value != null) {
          try {
            state = Map<dynamic, dynamic>.from(snap.data!.snapshot.value as Map);
          } catch (_) {}
        }

        final cameraOn = _b(state?['camera_on']);
        final trackingOn = _b(state?['tracking_on']);
        final esp32On = _b(state?['esp32_connected']);
        final esp32Port = (state?['esp32_port'] ?? '').toString();
        final comPorts = _list(state?['com_ports']);
        final conf = _displayValue('confidence', _d(state?['confidence']), 0.5);
        final smooth = _displayValue('smooth_factor', _d(state?['smooth_factor']), 0.4);
        final deadZone = _displayValue('dead_zone_deg', _d(state?['dead_zone_deg']), 0.8);
        final panOff = _displayValue('cal_pan_offset', _d(state?['cal_pan_offset']), 0.0);
        final tiltOff = _displayValue('cal_tilt_offset', _d(state?['cal_tilt_offset']), 0.0);

        final hasState = state != null;

        return AppCard(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(hasState),
              const SizedBox(height: 16),

              // Bật/tắt camera & tracking
              _SwitchTile(
                icon: LucideIcons.camera,
                label: 'Camera',
                sub: cameraOn ? 'Đang chạy' : 'Đã tắt',
                value: cameraOn,
                color: AppColors.primary,
                onChanged: hasState
                    ? (v) => _pushCommand('set_camera', {'on': v})
                    : null,
              ),
              const SizedBox(height: 10),
              _SwitchTile(
                icon: LucideIcons.target,
                label: 'Tracking',
                sub: trackingOn ? 'Đang theo dõi' : 'Đã tắt',
                value: trackingOn,
                color: AppColors.primary,
                onChanged: hasState
                    ? (v) => _pushCommand('set_tracking', {'on': v})
                    : null,
              ),

              const Divider(height: 28),
              _Esp32Section(
                connected: esp32On,
                currentPort: esp32Port,
                ports: comPorts,
                enabled: hasState,
                onRefresh: () => _pushCommand('refresh_ports', {}),
                onConnect: (port) => _pushCommand(
                  'set_esp32', {'on': true, 'port': port},
                ),
                onDisconnect: () => _pushCommand(
                  'set_esp32', {'on': false},
                ),
              ),

              const Divider(height: 28),
              Text('Thông số phát hiện',
                  style: Theme.of(context).textTheme.titleSmall),
              const SizedBox(height: 8),
              _SliderTile(
                icon: LucideIcons.gauge,
                label: 'Ngưỡng tin cậy',
                value: conf,
                min: 0.1,
                max: 1.0,
                valueLabel: conf.toStringAsFixed(2),
                enabled: hasState,
                onChanged: (v) => _onParamChanged('confidence', v),
              ),

              const Divider(height: 28),
              Text('Tốc độ tracking',
                  style: Theme.of(context).textTheme.titleSmall),
              const SizedBox(height: 8),
              _SliderTile(
                icon: LucideIcons.zap,
                label: 'Tốc độ phản hồi',
                value: smooth,
                min: 0.1,
                max: 1.0,
                valueLabel: smooth.toStringAsFixed(2),
                enabled: hasState,
                onChanged: (v) => _onParamChanged('smooth_factor', v),
              ),
              const SizedBox(height: 6),
              _SliderTile(
                icon: LucideIcons.minimize2,
                label: 'Vùng chết (°)',
                value: deadZone,
                min: 0.0,
                max: 3.0,
                valueLabel: deadZone.toStringAsFixed(2),
                enabled: hasState,
                onChanged: (v) => _onParamChanged('dead_zone_deg', v),
              ),

              const Divider(height: 28),
              Text('Hiệu chỉnh servo',
                  style: Theme.of(context).textTheme.titleSmall),
              const SizedBox(height: 8),
              _SliderTile(
                icon: LucideIcons.moveHorizontal,
                label: 'Pan offset (°)',
                value: panOff,
                min: -15.0,
                max: 15.0,
                valueLabel: '${panOff >= 0 ? '+' : ''}${panOff.toStringAsFixed(1)}°',
                enabled: hasState,
                onChanged: (v) => _onParamChanged('cal_pan_offset', v),
              ),
              const SizedBox(height: 6),
              _SliderTile(
                icon: LucideIcons.moveVertical,
                label: 'Tilt offset (°)',
                value: tiltOff,
                min: -15.0,
                max: 15.0,
                valueLabel: '${tiltOff >= 0 ? '+' : ''}${tiltOff.toStringAsFixed(1)}°',
                enabled: hasState,
                onChanged: (v) => _onParamChanged('cal_tilt_offset', v),
              ),

              if (!hasState) ...[
                const SizedBox(height: 8),
                const _OfflineHint(),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _buildHeader(bool hasState) {
    return Row(
      children: [
        Text('Điều khiển từ xa',
            style: Theme.of(context).textTheme.titleMedium),
        const Spacer(),
        StreamBuilder<DatabaseEvent>(
          stream: _deviceStream,
          builder: (context, snap) {
            final status = (snap.data?.snapshot.value ?? '').toString();
            final online = status == 'online';
            final color = online ? AppColors.success : AppColors.mutedForeground;
            final text = online ? 'ONLINE' : 'OFFLINE';
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(text,
                  style: TextStyle(
                    color: color,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  )),
            );
          },
        ),
      ],
    );
  }
}

// ── Switch tile ──────────────────────────────────────────────────────────────
class _SwitchTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String sub;
  final bool value;
  final Color color;
  final ValueChanged<bool>? onChanged;

  const _SwitchTile({
    required this.icon,
    required this.label,
    required this.sub,
    required this.value,
    required this.color,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final disabled = onChanged == null;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: (value && !disabled ? color : AppColors.mutedForeground)
            .withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: (value && !disabled ? color : AppColors.mutedForeground)
              .withValues(alpha: 0.15),
        ),
      ),
      child: Row(
        children: [
          Icon(icon, size: 20,
              color: disabled ? AppColors.mutedForeground : color),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    )),
                const SizedBox(height: 2),
                Text(sub,
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppColors.mutedForeground,
                    )),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }
}

// ── Slider tile ──────────────────────────────────────────────────────────────
class _SliderTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final double value;
  final double min;
  final double max;
  final String valueLabel;
  final bool enabled;
  final ValueChanged<double> onChanged;

  const _SliderTile({
    required this.icon,
    required this.label,
    required this.value,
    required this.min,
    required this.max,
    required this.valueLabel,
    required this.enabled,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final clamped = value.clamp(min, max);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 14, color: AppColors.mutedForeground),
            const SizedBox(width: 6),
            Text(label,
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.mutedForeground,
                  fontWeight: FontWeight.w500,
                )),
            const Spacer(),
            Text(valueLabel,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  fontFamily: 'monospace',
                )),
          ],
        ),
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            trackHeight: 3,
            overlayShape: const RoundSliderOverlayShape(overlayRadius: 14),
          ),
          child: Slider(
            value: clamped,
            min: min,
            max: max,
            onChanged: enabled ? onChanged : null,
            activeColor: AppColors.primary,
          ),
        ),
      ],
    );
  }
}

// ── ESP32 connection section ─────────────────────────────────────────────────
class _Esp32Section extends StatefulWidget {
  final bool connected;
  final String currentPort;
  final List<String> ports;
  final bool enabled;
  final VoidCallback onRefresh;
  final ValueChanged<String> onConnect;
  final VoidCallback onDisconnect;

  const _Esp32Section({
    required this.connected,
    required this.currentPort,
    required this.ports,
    required this.enabled,
    required this.onRefresh,
    required this.onConnect,
    required this.onDisconnect,
  });

  @override
  State<_Esp32Section> createState() => _Esp32SectionState();
}

class _Esp32SectionState extends State<_Esp32Section> {
  String? _selectedPort;

  String? _resolveSelected() {
    final ports = widget.ports;
    if (_selectedPort != null && ports.contains(_selectedPort)) {
      return _selectedPort;
    }
    if (widget.currentPort.isNotEmpty && ports.contains(widget.currentPort)) {
      return widget.currentPort;
    }
    if (ports.isNotEmpty) return ports.first;
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final selected = _resolveSelected();
    final canConnect = widget.enabled && !widget.connected && selected != null;
    final canDisconnect = widget.enabled && widget.connected;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(LucideIcons.plug,
                size: 16,
                color: widget.connected ? AppColors.success : AppColors.mutedForeground),
            const SizedBox(width: 6),
            Text('ESP32',
                style: Theme.of(context).textTheme.titleSmall),
            const Spacer(),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: (widget.connected
                        ? AppColors.success
                        : AppColors.mutedForeground)
                    .withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                widget.connected
                    ? 'CONNECTED${widget.currentPort.isNotEmpty ? ' • ${widget.currentPort}' : ''}'
                    : 'DISCONNECTED',
                style: TextStyle(
                  color: widget.connected
                      ? AppColors.success
                      : AppColors.mutedForeground,
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),

        Row(
          children: [
            Expanded(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.inputBackground,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.border),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: selected,
                    isExpanded: true,
                    hint: const Text('Không có cổng COM',
                        style: TextStyle(
                            fontSize: 13, color: AppColors.mutedForeground)),
                    items: widget.ports
                        .map((p) => DropdownMenuItem(
                              value: p,
                              child: Text(p,
                                  style: const TextStyle(
                                    fontSize: 13,
                                    fontFamily: 'monospace',
                                  )),
                            ))
                        .toList(),
                    onChanged: widget.enabled && !widget.connected
                        ? (v) => setState(() => _selectedPort = v)
                        : null,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            _IconBtn(
              icon: LucideIcons.refreshCcw,
              onTap: widget.enabled ? widget.onRefresh : null,
              tooltip: 'Quét lại cổng',
            ),
          ],
        ),
        const SizedBox(height: 10),

        SizedBox(
          width: double.infinity,
          child: widget.connected
              ? OutlinedButton(
                  onPressed: canDisconnect ? widget.onDisconnect : null,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.destructive,
                    side: const BorderSide(color: AppColors.destructive),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text('Ngắt kết nối'),
                )
              : ElevatedButton(
                  onPressed: canConnect
                      ? () => widget.onConnect(selected)
                      : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.success,
                    foregroundColor: AppColors.successForeground,
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text('Kết nối'),
                ),
        ),
      ],
    );
  }
}

class _IconBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onTap;
  final String? tooltip;

  const _IconBtn({required this.icon, required this.onTap, this.tooltip});

  @override
  Widget build(BuildContext context) {
    final btn = Material(
      color: AppColors.muted,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Icon(icon, size: 18,
              color: onTap == null
                  ? AppColors.mutedForeground
                  : AppColors.foreground),
        ),
      ),
    );
    return tooltip != null ? Tooltip(message: tooltip!, child: btn) : btn;
  }
}

class _OfflineHint extends StatelessWidget {
  const _OfflineHint();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: AppColors.warning.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(10),
      ),
      child: const Row(
        children: [
          Icon(LucideIcons.wifiOff, size: 14, color: AppColors.warning),
          SizedBox(width: 8),
          Expanded(
            child: Text(
              'Chưa nhận được trạng thái từ thiết bị. Mọi thay đổi sẽ chờ '
              'khi thiết bị online trở lại.',
              style: TextStyle(fontSize: 11, color: AppColors.warning),
            ),
          ),
        ],
      ),
    );
  }
}
