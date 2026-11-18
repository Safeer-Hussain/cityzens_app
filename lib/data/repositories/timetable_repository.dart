import 'package:sqflite/sqflite.dart';

import '../../core/database/app_database.dart';
import '../models/timetable_slot.dart';

class TimetableRepository {
  final AppDatabase database;

  TimetableRepository({required this.database});

  Database get _db => database.db;

  Future<List<TimetableSlotModel>> getAllSlots() async {
    final results = await _db.query(
      'timetable_slots',
      orderBy: 'day_of_week ASC, start_time_minutes ASC',
    );
    return results.map((m) => TimetableSlotModel.fromMap(m)).toList();
  }

  Future<List<TimetableSlotModel>> getEnrolledSlots() async {
    final results = await _db.query(
      'timetable_slots',
      where: 'is_enrolled = 1',
      orderBy: 'day_of_week ASC, start_time_minutes ASC',
    );
    return results.map((m) => TimetableSlotModel.fromMap(m)).toList();
  }

  Future<List<TimetableSlotModel>> getSlotsByDay(int dayOfWeek) async {
    final results = await _db.query(
      'timetable_slots',
      where: 'day_of_week = ?',
      whereArgs: [dayOfWeek],
      orderBy: 'start_time_minutes ASC',
    );
    return results.map((m) => TimetableSlotModel.fromMap(m)).toList();
  }

  Future<List<TimetableSlotModel>> getAlternativeSections(
    String courseCode,
    String excludeSection,
  ) async {
    final results = await _db.query(
      'timetable_slots',
      where: 'course_code = ? AND section_name != ?',
      whereArgs: [courseCode, excludeSection],
      orderBy: 'day_of_week ASC, start_time_minutes ASC',
    );
    return results.map((m) => TimetableSlotModel.fromMap(m)).toList();
  }

  Future<void> setEnrollment(String slotId, bool isEnrolled) async {
    await _db.update(
      'timetable_slots',
      {'is_enrolled': isEnrolled ? 1 : 0},
      where: 'id = ?',
      whereArgs: [slotId],
    );
  }

  Future<void> swapSections({
    required String dropSlotId,
    required String enrollSlotId,
  }) async {
    await _db.transaction((txn) async {
      await txn.update(
        'timetable_slots',
        {'is_enrolled': 0},
        where: 'id = ?',
        whereArgs: [dropSlotId],
      );
      await txn.update(
        'timetable_slots',
        {'is_enrolled': 1},
        where: 'id = ?',
        whereArgs: [enrollSlotId],
      );
    });
  }

  Future<void> insertSlot(TimetableSlotModel slot) async {
    await _db.insert(
      'timetable_slots',
      slot.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }
}
