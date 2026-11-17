import 'dart:math';

import 'package:flutter/foundation.dart';

import '../../data/models/ev_reservation.dart';
import '../../data/models/parking_permit.dart';
import '../../data/models/parking_zone.dart';
import '../../data/repositories/parking_repository.dart';

class ParkingProvider extends ChangeNotifier {
  final ParkingRepository repository;

  final String studentId = 'CTZ-2026-8842';
  final String studentName = 'Safeer Hussain';

  bool _isLoading = false;
  String? _errorMessage;

  List<ParkingZoneModel> _zones = [];
  ParkingZoneModel? _selectedZone;
  String _selectedFilter = 'All Lots';
  String _searchQuery = '';

  ParkingPermitModel? _activePermit;
  List<ParkingPermitModel> _allPermits = [];
  List<EvReservationModel> _evReservations = [];
  EvReservationModel? _lastConfirmedReservation;

  // Camera License Plate OCR scanner state
  String? _scannedPlate;
  final bool _isScanning = false;
  bool _plateMatchesPermit = false;

  ParkingProvider({required this.repository});

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  List<ParkingZoneModel> get zones => List.unmodifiable(_zones);
  ParkingZoneModel? get selectedZone => _selectedZone;
  String get selectedFilter => _selectedFilter;
  String get searchQuery => _searchQuery;

  ParkingPermitModel? get activePermit => _activePermit;
  List<ParkingPermitModel> get allPermits => List.unmodifiable(_allPermits);
  List<EvReservationModel> get evReservations =>
      List.unmodifiable(_evReservations);
  EvReservationModel? get lastConfirmedReservation => _lastConfirmedReservation;

  String? get scannedPlate => _scannedPlate;
  bool get isScanning => _isScanning;
  bool get plateMatchesPermit => _plateMatchesPermit;

  int get totalCampusSpots =>
      _zones.fold<int>(0, (sum, z) => sum + z.totalSpots);
  int get availableCampusSpots =>
      _zones.fold<int>(0, (sum, z) => sum + z.availableSpots);
  int get totalEvCampusSpots =>
      _zones.fold<int>(0, (sum, z) => sum + z.totalEvSpots);
  int get availableEvCampusSpots =>
      _zones.fold<int>(0, (sum, z) => sum + z.availableEvSpots);

  double get overallOccupancyRate {
    if (totalCampusSpots == 0) return 0.0;
    final occupied = totalCampusSpots - availableCampusSpots;
    return (occupied / totalCampusSpots).clamp(0.0, 1.0);
  }

  double get overallEvOccupancyRate {
    if (totalEvCampusSpots == 0) return 0.0;
    final occupied = totalEvCampusSpots - availableEvCampusSpots;
    return (occupied / totalEvCampusSpots).clamp(0.0, 1.0);
  }

  List<ParkingZoneModel> get filteredZones {
    return _zones.where((zone) {
      if (_selectedFilter == 'Covered' && !zone.isCovered) {
        return false;
      }
      if (_selectedFilter == 'EV Available' && zone.availableEvSpots <= 0) {
        return false;
      }
      if (_selectedFilter == 'Fast Charging' &&
          !zone.chargerTypes.any(
            (c) => c.contains('Fast') || c.contains('150kW'),
          )) {
        return false;
      }

      if (_searchQuery.trim().isNotEmpty) {
        final query = _searchQuery.trim().toLowerCase();
        final matchesName = zone.name.toLowerCase().contains(query);
        final matchesArea = zone.campusArea.toLowerCase().contains(query);
        final matchesCharger = zone.chargerTypes.any(
          (c) => c.toLowerCase().contains(query),
        );
        if (!matchesName && !matchesArea && !matchesCharger) {
          return false;
        }
      }

      return true;
    }).toList();
  }

  Future<void> loadData() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _zones = await repository.getParkingZones();
      _activePermit = await repository.getActivePermit(studentId);
      _allPermits = await repository.getStudentPermits(studentId);
      _evReservations = await repository.getEvReservations(studentId);
      if (_selectedZone == null && _zones.isNotEmpty) {
        _selectedZone = _zones.first;
      }
    } catch (e) {
      _errorMessage = 'Failed to load parking radar data: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void selectZone(ParkingZoneModel? zone) {
    _selectedZone = zone;
    notifyListeners();
  }

  void setFilter(String filter) {
    if (_selectedFilter == filter) return;
    _selectedFilter = filter;
    notifyListeners();
  }

  void setSearchQuery(String q) {
    _searchQuery = q;
    notifyListeners();
  }

  Future<bool> reserveEvSlot({
    required String zoneId,
    required String stationId,
    required String chargerType,
    required String slotTime,
    required int targetBatteryPercent,
  }) async {
    final zone = _zones.firstWhere(
      (z) => z.id == zoneId,
      orElse: () => _zones.first,
    );

    if (zone.availableEvSpots <= 0) {
      _errorMessage = 'No available EV charging spots in ${zone.name}.';
      notifyListeners();
      return false;
    }

    try {
      final now = DateTime.now();
      final energyKwh = double.parse(
        ((targetBatteryPercent - 20) * 0.45).toStringAsFixed(1),
      );
      final cost = double.parse((energyKwh * 0.14).toStringAsFixed(2))
          .clamp(1.50, 20.0);
      final queueNumber = Random().nextInt(90) + 10;
      final queueToken = 'EV-QUEUE-#$queueNumber';

      final reservation = EvReservationModel(
        id: 'ev_res_${now.microsecondsSinceEpoch}',
        studentId: studentId,
        studentName: studentName,
        zoneId: zone.id,
        zoneName: zone.name,
        stationId: stationId,
        chargerType: chargerType,
        slotTime: slotTime,
        targetBatteryPercent: targetBatteryPercent,
        estimatedEnergyKwh: energyKwh,
        costCredits: cost,
        queueToken: queueToken,
        status: 'confirmed',
        createdAt: now.millisecondsSinceEpoch,
      );

      final saved = await repository.createEvReservation(reservation);
      _lastConfirmedReservation = saved;

      // Refresh data
      _zones = await repository.getParkingZones();
      _evReservations = await repository.getEvReservations(studentId);
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = 'Failed to create EV charging reservation: $e';
      notifyListeners();
      return false;
    }
  }

  Future<bool> cancelReservation(String reservationId) async {
    try {
      final success = await repository.cancelEvReservation(reservationId);
      if (success) {
        _zones = await repository.getParkingZones();
        _evReservations = await repository.getEvReservations(studentId);
        notifyListeners();
      }
      return success;
    } catch (e) {
      _errorMessage = 'Failed to cancel EV reservation: $e';
      notifyListeners();
      return false;
    }
  }

  void simulatePlateScan(String rawPlate) {
    final clean = rawPlate.replaceAll(' ', '').toUpperCase().trim();
    _scannedPlate = clean;

    final activePlate = _activePermit?.vehiclePlate
        .replaceAll(' ', '')
        .toUpperCase()
        .trim();
    _plateMatchesPermit = activePlate != null && activePlate == clean;
    notifyListeners();
  }

  void clearScannedPlate() {
    _scannedPlate = null;
    _plateMatchesPermit = false;
    notifyListeners();
  }

  Future<bool> renewPermit({
    required String vehiclePlate,
    required String vehicleModel,
    required String permitTier,
    required String assignedZone,
    int durationDays = 120,
  }) async {
    try {
      final now = DateTime.now();
      final validFrom = now.millisecondsSinceEpoch;
      final validUntil = now
          .add(Duration(days: durationDays))
          .millisecondsSinceEpoch;
      final rfidToken =
          'RFID-PK-8842-${now.millisecondsSinceEpoch.toRadixString(16).toUpperCase().substring(4)}';
      final barcode = 'CTZ-PRK-8842-${vehiclePlate.replaceAll('-', '')}';

      final permit = ParkingPermitModel(
        id: 'pmt_${now.microsecondsSinceEpoch}',
        studentId: studentId,
        studentName: studentName,
        vehiclePlate: vehiclePlate.trim().toUpperCase(),
        vehicleModel: vehicleModel.trim(),
        permitTier: permitTier,
        validFrom: validFrom,
        validUntil: validUntil,
        isActive: true,
        assignedZone: assignedZone,
        rfidToken: rfidToken,
        barcodePayload: barcode,
      );

      final saved = await repository.savePermit(permit);
      _activePermit = saved;
      _allPermits = await repository.getStudentPermits(studentId);
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = 'Failed to issue student parking permit: $e';
      notifyListeners();
      return false;
    }
  }
}
