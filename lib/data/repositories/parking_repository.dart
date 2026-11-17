import 'package:sqflite/sqflite.dart';

import '../../core/database/app_database.dart';
import '../models/ev_reservation.dart';
import '../models/parking_permit.dart';
import '../models/parking_zone.dart';

class ParkingRepository {
  final AppDatabase database;

  ParkingRepository({required this.database});

  Database get _db => database.db;

  Future<List<ParkingZoneModel>> getParkingZones() async {
    final results = await _db.query('parking_zones', orderBy: 'name ASC');
    return results.map((m) => ParkingZoneModel.fromMap(m)).toList();
  }

  Future<ParkingZoneModel?> getParkingZoneById(String id) async {
    final results = await _db.query(
      'parking_zones',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    if (results.isEmpty) return null;
    return ParkingZoneModel.fromMap(results.first);
  }

  Future<List<ParkingPermitModel>> getStudentPermits(String studentId) async {
    final results = await _db.query(
      'parking_permits',
      where: 'student_id = ?',
      whereArgs: [studentId],
      orderBy: 'valid_until DESC',
    );
    return results.map((m) => ParkingPermitModel.fromMap(m)).toList();
  }

  Future<ParkingPermitModel?> getActivePermit(String studentId) async {
    final results = await _db.query(
      'parking_permits',
      where: 'student_id = ? AND is_active = 1',
      whereArgs: [studentId],
      limit: 1,
    );
    if (results.isEmpty) return null;
    return ParkingPermitModel.fromMap(results.first);
  }

  Future<ParkingPermitModel> savePermit(ParkingPermitModel permit) async {
    // If activating new permit, deactivate others for this student
    if (permit.isActive) {
      await _db.update(
        'parking_permits',
        {'is_active': 0},
        where: 'student_id = ?',
        whereArgs: [permit.studentId],
      );
    }

    await _db.insert(
      'parking_permits',
      permit.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
    return permit;
  }

  Future<List<EvReservationModel>> getEvReservations(String studentId) async {
    final results = await _db.query(
      'ev_charging_reservations',
      where: 'student_id = ?',
      whereArgs: [studentId],
      orderBy: 'created_at DESC',
    );
    return results.map((m) => EvReservationModel.fromMap(m)).toList();
  }

  Future<EvReservationModel> createEvReservation(
    EvReservationModel reservation,
  ) async {
    await _db.insert(
      'ev_charging_reservations',
      reservation.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );

    // Increment occupied EV spot on zone
    final zone = await getParkingZoneById(reservation.zoneId);
    if (zone != null) {
      final updatedEv = (zone.occupiedEvSpots + 1).clamp(0, zone.totalEvSpots);
      await _db.update(
        'parking_zones',
        {'occupied_ev_spots': updatedEv},
        where: 'id = ?',
        whereArgs: [reservation.zoneId],
      );
    }

    return reservation;
  }

  Future<bool> cancelEvReservation(String reservationId) async {
    final results = await _db.query(
      'ev_charging_reservations',
      where: 'id = ?',
      whereArgs: [reservationId],
      limit: 1,
    );

    if (results.isEmpty) return false;

    final reservation = EvReservationModel.fromMap(results.first);
    await _db.update(
      'ev_charging_reservations',
      {'status': 'cancelled'},
      where: 'id = ?',
      whereArgs: [reservationId],
    );

    // Decrement occupied EV spot on zone
    final zone = await getParkingZoneById(reservation.zoneId);
    if (zone != null) {
      final updatedEv = (zone.occupiedEvSpots - 1).clamp(0, zone.totalEvSpots);
      await _db.update(
        'parking_zones',
        {'occupied_ev_spots': updatedEv},
        where: 'id = ?',
        whereArgs: [reservation.zoneId],
      );
    }

    return true;
  }

  Future<void> updateSpotOccupancy(
    String zoneId,
    int occupiedSpots,
    int occupiedEvSpots,
  ) async {
    await _db.update(
      'parking_zones',
      {'occupied_spots': occupiedSpots, 'occupied_ev_spots': occupiedEvSpots},
      where: 'id = ?',
      whereArgs: [zoneId],
    );
  }
}
