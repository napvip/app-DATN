enum HiveStatus { healthy, warning, attack }

class HiveModel {
  final String id;
  final String name;
  final HiveStatus status;
  final String imageUrl;
  final double honeyWeight;
  final double temperature;
  final double humidity;
  final String lastUpdate;
  final int batteryLevel;

  const HiveModel({
    required this.id,
    required this.name,
    required this.status,
    required this.imageUrl,
    required this.honeyWeight,
    required this.temperature,
    required this.humidity,
    required this.lastUpdate,
    this.batteryLevel = 100,
  });

  String get statusText {
    switch (status) {
      case HiveStatus.healthy:
        return 'Healthy';
      case HiveStatus.warning:
        return 'Warning';
      case HiveStatus.attack:
        return 'Wasp Attack!';
    }
  }

  static List<HiveModel> get mockData => [
        const HiveModel(
          id: '1',
          name: 'Hive Alpha',
          status: HiveStatus.healthy,
          imageUrl:
              'https://images.unsplash.com/photo-1713705320964-8b8e7f8de9bd?w=400',
          honeyWeight: 12.4,
          temperature: 35,
          humidity: 65,
          lastUpdate: '5 min ago',
          batteryLevel: 87,
        ),
        const HiveModel(
          id: '2',
          name: 'Hive Beta',
          status: HiveStatus.warning,
          imageUrl:
              'https://images.unsplash.com/photo-1569127971771-15d19a5ba26c?w=400',
          honeyWeight: 8.2,
          temperature: 38,
          humidity: 72,
          lastUpdate: '12 min ago',
          batteryLevel: 45,
        ),
        const HiveModel(
          id: '3',
          name: 'Hive Gamma',
          status: HiveStatus.attack,
          imageUrl:
              'https://images.unsplash.com/photo-1758522964459-403b982fb3c2?w=400',
          honeyWeight: 15.1,
          temperature: 34,
          humidity: 68,
          lastUpdate: '2 min ago',
          batteryLevel: 92,
        ),
        const HiveModel(
          id: '4',
          name: 'Hive Delta',
          status: HiveStatus.healthy,
          imageUrl:
              'https://images.unsplash.com/photo-1758522966019-01e7b9b39766?w=400',
          honeyWeight: 10.8,
          temperature: 36,
          humidity: 63,
          lastUpdate: '8 min ago',
          batteryLevel: 15,
        ),
      ];
}
