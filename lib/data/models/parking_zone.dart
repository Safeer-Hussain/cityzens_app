import 'dart:convert';
import 'dart:math';

class ParkingZoneModel {
  final String id;
  final String name;
  final String campusArea;
  final int totalSpots;
  final int occupiedSpots;
  final int totalEvSpots;
  final int occupiedEvSpots;
  final double hourlyRate;
  final String operationalHours;
  final bool isCovered;
  final List<String> chargerTypes;

  const ParkingZoneModel({
    required this.id,
    required this.name,
    required this.campusArea,
    required this.totalSpots,
    required this.occupiedSpots,
    required this.totalEvSpots,
    required this.occupiedEvSpots,
    required this.hourlyRate,
    required this.operationalHours,
    required this.isCovered,
    required this.chargerTypes,
  });

  int get availableSpots => max(0, totalSpots - occupiedSpots);
  int get availableEvSpots => max(0, totalEvSpots - occupiedEvSpots);

  double get occupancyRate =>
      totalSpots == 0 ? 0.0 : (occupiedSpots / totalSpots).clamp(0.0, 1.0);

  double get evOccupancyRate => totalEvSpots == 0
      ? 0.0
      : (occupiedEvSpots / totalEvSpots).clamp(0.0, 1.0);

  bool get isFull => availableSpots <= 0;
  bool get isEvFull => availableEvSpots <= 0;

  ParkingZoneModel copyWith({
    String? id,
    String? name,
    String? campusArea,
    int? totalSpots,
    int? occupiedSpots,
    int? totalEvSpots,
    int? occupiedEvSpots,
    double? hourlyRate,
    String? operationalHours,
    bool? isCovered,
    List<String>? chargerTypes,
  }) {
    return ParkingZoneModel(
      id: id ?? this.id,
      name: name ?? this.name,
      campusArea: campusArea ?? this.campusArea,
      totalSpots: totalSpots ?? this.totalSpots,
      occupiedSpots: occupiedSpots ?? this.occupiedSpots,
      totalEvSpots: totalEvSpots ?? this.totalEvSpots,
      occupiedEvSpots: occupiedEvSpots ?? this.occupiedEvSpots,
      hourlyRate: hourlyRate ?? this.hourlyRate,
      operationalHours: operationalHours ?? this.operationalHours,
      isCovered: isCovered ?? this.isCovered,
      chargerTypes: chargerTypes ?? this.chargerTypes,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'campus_area': campusArea,
      'total_spots': totalSpots,
      'occupied_spots': occupiedSpots,
      'total_ev_spots': totalEvSpots,
      'occupied_ev_spots': occupiedEvSpots,
      'hourly_rate': hourlyRate,
      'operational_hours': operationalHours,
      'is_covered': isCovered ? 1 : 0,
      'charger_types': jsonEncode(chargerTypes),
    };
  }

  factory ParkingZoneModel.fromMap(Map<String, dynamic> map) {
    List<String> parsedChargerTypes = [];
    if (map['charger_types'] != null) {
      if (map['charger_types'] is String) {
        try {
          final decoded = jsonDecode(map['charger_types'] as String);
          if (decoded is List) {
            parsedChargerTypes = decoded.map((e) => e.toString()).toList();
          }
        } catch (_) {
          parsedChargerTypes = [];
        }
      } else if (map['charger_types'] is List) {
        parsedChargerTypes = (map['charger_types'] as List)
            .map((e) => e.toString())
            .toList();
      }
    }

    return ParkingZoneModel(
      id: map['id'] as String,
      name: map['name'] as String,
      campusArea: (map['campus_area'] as String?) ?? 'Campus Main',
      totalSpots: (map['total_spots'] as num?)?.toInt() ?? 0,
      occupiedSpots: (map['occupied_spots'] as num?)?.toInt() ?? 0,
      totalEvSpots: (map['total_ev_spots'] as num?)?.toInt() ?? 0,
      occupiedEvSpots: (map['occupied_ev_spots'] as num?)?.toInt() ?? 0,
      hourlyRate: (map['hourly_rate'] as num?)?.toDouble() ?? 0.0,
      operationalHours:
          (map['operational_hours'] as String?) ?? '06:00 - 23:00',
      isCovered: (map['is_covered'] as num?)?.toInt() == 1,
      chargerTypes: parsedChargerTypes,
    );
  }
}
