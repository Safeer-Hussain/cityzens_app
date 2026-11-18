import 'timetable_slot.dart';

class ScheduleConflictModel {
  final TimetableSlotModel slotA;
  final TimetableSlotModel slotB;
  final int overlapMinutes;
  final List<TimetableSlotModel> suggestedResolutions;

  const ScheduleConflictModel({
    required this.slotA,
    required this.slotB,
    required this.overlapMinutes,
    this.suggestedResolutions = const [],
  });

  String get dayName => slotA.dayName;
  String get shortDayName => slotA.shortDayName;

  String get conflictDescription {
    return '${slotA.courseCode} (${slotA.sectionName}) overlaps with ${slotB.courseCode} (${slotB.sectionName}) by $overlapMinutes mins on $dayName.';
  }

  ScheduleConflictModel copyWith({
    TimetableSlotModel? slotA,
    TimetableSlotModel? slotB,
    int? overlapMinutes,
    List<TimetableSlotModel>? suggestedResolutions,
  }) {
    return ScheduleConflictModel(
      slotA: slotA ?? this.slotA,
      slotB: slotB ?? this.slotB,
      overlapMinutes: overlapMinutes ?? this.overlapMinutes,
      suggestedResolutions: suggestedResolutions ?? this.suggestedResolutions,
    );
  }
}
