class ParkingPermitModel {
  final String id;
  final String studentId;
  final String studentName;
  final String vehiclePlate;
  final String vehicleModel;
  final String permitTier;
  final int validFrom;
  final int validUntil;
  final bool isActive;
  final String assignedZone;
  final String rfidToken;
  final String barcodePayload;

  const ParkingPermitModel({
    required this.id,
    required this.studentId,
    required this.studentName,
    required this.vehiclePlate,
    required this.vehicleModel,
    required this.permitTier,
    required this.validFrom,
    required this.validUntil,
    required this.isActive,
    required this.assignedZone,
    required this.rfidToken,
    required this.barcodePayload,
  });

  bool get isExpired => DateTime.now().millisecondsSinceEpoch > validUntil;

  int get daysRemaining {
    final diff = validUntil - DateTime.now().millisecondsSinceEpoch;
    return (diff / (1000 * 60 * 60 * 24)).ceil();
  }

  ParkingPermitModel copyWith({
    String? id,
    String? studentId,
    String? studentName,
    String? vehiclePlate,
    String? vehicleModel,
    String? permitTier,
    int? validFrom,
    int? validUntil,
    bool? isActive,
    String? assignedZone,
    String? rfidToken,
    String? barcodePayload,
  }) {
    return ParkingPermitModel(
      id: id ?? this.id,
      studentId: studentId ?? this.studentId,
      studentName: studentName ?? this.studentName,
      vehiclePlate: vehiclePlate ?? this.vehiclePlate,
      vehicleModel: vehicleModel ?? this.vehicleModel,
      permitTier: permitTier ?? this.permitTier,
      validFrom: validFrom ?? this.validFrom,
      validUntil: validUntil ?? this.validUntil,
      isActive: isActive ?? this.isActive,
      assignedZone: assignedZone ?? this.assignedZone,
      rfidToken: rfidToken ?? this.rfidToken,
      barcodePayload: barcodePayload ?? this.barcodePayload,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'student_id': studentId,
      'student_name': studentName,
      'vehicle_plate': vehiclePlate,
      'vehicle_model': vehicleModel,
      'permit_tier': permitTier,
      'valid_from': validFrom,
      'valid_until': validUntil,
      'is_active': isActive ? 1 : 0,
      'assigned_zone': assignedZone,
      'rfid_token': rfidToken,
      'barcode_payload': barcodePayload,
    };
  }

  factory ParkingPermitModel.fromMap(Map<String, dynamic> map) {
    return ParkingPermitModel(
      id: map['id'] as String,
      studentId: map['student_id'] as String,
      studentName: map['student_name'] as String,
      vehiclePlate: map['vehicle_plate'] as String,
      vehicleModel: map['vehicle_model'] as String,
      permitTier: (map['permit_tier'] as String?) ?? 'Standard Semester',
      validFrom: (map['valid_from'] as num?)?.toInt() ?? 0,
      validUntil: (map['valid_until'] as num?)?.toInt() ?? 0,
      isActive: (map['is_active'] as num?)?.toInt() == 1,
      assignedZone: (map['assigned_zone'] as String?) ?? 'All Campus Lots',
      rfidToken: map['rfid_token'] as String,
      barcodePayload: map['barcode_payload'] as String,
    );
  }
}
