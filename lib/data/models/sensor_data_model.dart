/// Model cho dữ liệu cảm biến từ ESP32 (qua Firebase RTDB).
class SensorData {
  final double? temperature;       // °C từ DHT22
  final double? humidity;          // % từ DHT22
  final double? waterDistanceCm;   // cm từ HC-SR05
  final int? updatedAt;            // timestamp ms

  const SensorData({
    this.temperature,
    this.humidity,
    this.waterDistanceCm,
    this.updatedAt,
  });

  factory SensorData.fromMap(Map<dynamic, dynamic> map) {
    return SensorData(
      temperature: _toDouble(map['temperature']),
      humidity: _toDouble(map['humidity']),
      // Hỗ trợ cả snake_case lẫn camelCase từ ESP32
      waterDistanceCm: _toDouble(
          map['water_distance_cm'] ?? map['waterDistanceCm'] ?? map['distance_cm']),
      updatedAt: _toInt(
          map['updated_at'] ?? map['updatedAt'] ?? map['timestamp']),
    );
  }

  static double? _toDouble(dynamic value) {
    if (value == null) return null;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value);
    return null;
  }

  static int? _toInt(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is double) return value.toInt();
    if (value is String) return int.tryParse(value);
    return null;
  }

  /// Tính phần trăm mực nước dựa trên khoảng cách.
  /// [maxDepthCm]: chiều cao tổng bình nước (cm).
  /// Cảm biến ở trên miệng bình, đo xuống mặt nước.
  /// Nước đầy → distance nhỏ, nước cạn → distance lớn.
  double waterLevelPercent({double maxDepthCm = 30.0}) {
    if (waterDistanceCm == null || waterDistanceCm! < 0) return 0;
    final level = ((maxDepthCm - waterDistanceCm!) / maxDepthCm * 100)
        .clamp(0.0, 100.0);
    return level;
  }

  /// Kiểm tra có dữ liệu hợp lệ không.
  bool get hasData => temperature != null || humidity != null || waterDistanceCm != null;

  /// Thời gian cập nhật dạng "vừa xong", "5 giây trước",...
  String get updatedAgo {
    if (updatedAt == null) return 'Chưa có dữ liệu';
    final diff = DateTime.now().millisecondsSinceEpoch - updatedAt!;
    final seconds = diff ~/ 1000;
    if (seconds < 5) return 'Vừa cập nhật';
    if (seconds < 60) return '${seconds}s trước';
    final minutes = seconds ~/ 60;
    if (minutes < 60) return '${minutes} phút trước';
    final hours = minutes ~/ 60;
    return '${hours} giờ trước';
  }
}
