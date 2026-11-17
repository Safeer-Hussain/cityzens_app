class EvReservationModel {
  final String id;
  final String studentId;
  final String studentName;
  final String zoneId;
  final String zoneName;
  final String stationId;
  final String chargerType;
  final String slotTime;
  final int targetBatteryPercent;
  final double estimatedEnergyKwh;
  final double costCredits;
  final String queueToken;
  final String status;
  final int createdAt;

  const EvReservationModel({
    required this.id,
    required this.studentId,
    required this.studentName,
    required this.zoneId,
    required this.zoneName,
    required this.stationId,
    required this.chargerType,
    required this.slotTime,
    required this.targetBatteryPercent,
    required this.estimatedEnergyKwh,
    required this.costCredits,
    required this.queueToken,
    required this.status,
    required this.createdAt,
  });

  bool get isConfirmed => status == 'confirmed';
  bool get isCharging => status == 'charging';
  bool get isCompleted => status == 'completed';
  bool get isCancelled => status == 'cancelled';

  EvReservationModel copyWith({
    String? id,
    String? studentId,
    String? studentName,
    String? zoneId,
    String? zoneName,
    String? stationId,
    String? chargerType,
    String? slotTime,
    int? targetBatteryPercent,
    double? estimatedEnergyKwh,
    double? costCredits,
    String? queueToken,
    String? status,
    int? createdAt,
  }) {
    return EvReservationModel(
      id: id ?? this.id,
      studentId: studentId ?? this.studentId,
      studentName: studentName ?? this.studentName,
      zoneId: zoneId ?? this.zoneId,
      zoneName: zoneName ?? this.zoneName,
      stationId: stationId ?? this.stationId,
      chargerType: chargerType ?? this.chargerType,
      slotTime: slotTime ?? this.slotTime,
      targetBatteryPercent: targetBatteryPercent ?? this.targetBatteryPercent,
      estimatedEnergyKwh: estimatedEnergyKwh ?? this.estimatedEnergyKwh,
      costCredits: costCredits ?? this.costCredits,
      queueToken: queueToken ?? this.queueToken,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'student_id': studentId,
      'student_name': studentName,
      'zone_id': zoneId,
      'zone_name': zoneName,
      'station_id': stationId,
      'charger_type': chargerType,
      'slot_time': slotTime,
      'target_battery_percent': targetBatteryPercent,
      'estimated_energy_kwh': estimatedEnergyKwh,
      'cost_credits': costCredits,
      'queue_token': queueToken,
      'status': status,
      'created_at': createdAt,
    };
  }

  factory EvReservationModel.fromMap(Map<String, dynamic> map) {
    return EvReservationModel(
      id: map['id'] as String,
      studentId: map['student_id'] as String,
      studentName: map['student_name'] as String,
      zoneId: map['zone_id'] as String,
      zoneName: map['zone_name'] as String,
      stationId: map['station_id'] as String,
      chargerType: map['charger_type'] as String,
      slotTime: map['slot_time'] as String,
      targetBatteryPercent:
          (map['target_battery_percent'] as num?)?.toInt() ?? 80,
      estimatedEnergyKwh:
          (map['estimated_energy_kwh'] as num?)?.toDouble() ?? 0.0,
      costCredits: (map['cost_credits'] as num?)?.toDouble() ?? 0.0,
      queueToken: map['queue_token'] as String,
      status: (map['status'] as String?) ?? 'confirmed',
      createdAt: (map['created_at'] as num?)?.toInt() ?? 0,
    );
  }
}
