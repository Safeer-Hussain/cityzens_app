import 'dart:math';

class TimetableSlotModel {
  final String id;
  final String courseId;
  final String courseCode;
  final String courseTitle;
  final String sectionName;
  final String instructor;
  final String room;
  final int
  dayOfWeek; // 1 = Monday, 2 = Tuesday, 3 = Wednesday, 4 = Thursday, 5 = Friday
  final int startTimeMinutes; // minutes from midnight (e.g. 9:00 = 540)
  final int endTimeMinutes; // minutes from midnight (e.g. 10:30 = 630)
  final bool isLab;
  final bool isEnrolled;

  const TimetableSlotModel({
    required this.id,
    required this.courseId,
    required this.courseCode,
    required this.courseTitle,
    required this.sectionName,
    required this.instructor,
    required this.room,
    required this.dayOfWeek,
    required this.startTimeMinutes,
    required this.endTimeMinutes,
    required this.isLab,
    required this.isEnrolled,
  });

  int get durationMinutes => endTimeMinutes - startTimeMinutes;

  String get dayName {
    switch (dayOfWeek) {
      case 1:
        return 'Monday';
      case 2:
        return 'Tuesday';
      case 3:
        return 'Wednesday';
      case 4:
        return 'Thursday';
      case 5:
        return 'Friday';
      case 6:
        return 'Saturday';
      default:
        return 'Sunday';
    }
  }

  String get shortDayName {
    switch (dayOfWeek) {
      case 1:
        return 'Mon';
      case 2:
        return 'Tue';
      case 3:
        return 'Wed';
      case 4:
        return 'Thu';
      case 5:
        return 'Fri';
      case 6:
        return 'Sat';
      default:
        return 'Sun';
    }
  }

  String get formattedTime {
    return '${_minutesToTime(startTimeMinutes)} - ${_minutesToTime(endTimeMinutes)}';
  }

  static String _minutesToTime(int totalMinutes) {
    final hours = totalMinutes ~/ 60;
    final minutes = totalMinutes % 60;
    final period = hours >= 12 ? 'PM' : 'AM';
    final displayHours = hours > 12 ? hours - 12 : (hours == 0 ? 12 : hours);
    final displayMinutes = minutes.toString().padLeft(2, '0');
    return '$displayHours:$displayMinutes $period';
  }

  bool overlapsWith(TimetableSlotModel other) {
    if (dayOfWeek != other.dayOfWeek) return false;
    final maxStart = max(startTimeMinutes, other.startTimeMinutes);
    final minEnd = min(endTimeMinutes, other.endTimeMinutes);
    return maxStart < minEnd;
  }

  int overlapMinutesWith(TimetableSlotModel other) {
    if (!overlapsWith(other)) return 0;
    final maxStart = max(startTimeMinutes, other.startTimeMinutes);
    final minEnd = min(endTimeMinutes, other.endTimeMinutes);
    return max(0, minEnd - maxStart);
  }

  TimetableSlotModel copyWith({
    String? id,
    String? courseId,
    String? courseCode,
    String? courseTitle,
    String? sectionName,
    String? instructor,
    String? room,
    int? dayOfWeek,
    int? startTimeMinutes,
    int? endTimeMinutes,
    bool? isLab,
    bool? isEnrolled,
  }) {
    return TimetableSlotModel(
      id: id ?? this.id,
      courseId: courseId ?? this.courseId,
      courseCode: courseCode ?? this.courseCode,
      courseTitle: courseTitle ?? this.courseTitle,
      sectionName: sectionName ?? this.sectionName,
      instructor: instructor ?? this.instructor,
      room: room ?? this.room,
      dayOfWeek: dayOfWeek ?? this.dayOfWeek,
      startTimeMinutes: startTimeMinutes ?? this.startTimeMinutes,
      endTimeMinutes: endTimeMinutes ?? this.endTimeMinutes,
      isLab: isLab ?? this.isLab,
      isEnrolled: isEnrolled ?? this.isEnrolled,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'course_id': courseId,
      'course_code': courseCode,
      'course_title': courseTitle,
      'section_name': sectionName,
      'instructor': instructor,
      'room': room,
      'day_of_week': dayOfWeek,
      'start_time_minutes': startTimeMinutes,
      'end_time_minutes': endTimeMinutes,
      'is_lab': isLab ? 1 : 0,
      'is_enrolled': isEnrolled ? 1 : 0,
    };
  }

  factory TimetableSlotModel.fromMap(Map<String, dynamic> map) {
    return TimetableSlotModel(
      id: map['id'] as String,
      courseId: map['course_id'] as String,
      courseCode: map['course_code'] as String,
      courseTitle: map['course_title'] as String,
      sectionName: map['section_name'] as String,
      instructor: map['instructor'] as String,
      room: map['room'] as String,
      dayOfWeek: (map['day_of_week'] as num?)?.toInt() ?? 1,
      startTimeMinutes: (map['start_time_minutes'] as num?)?.toInt() ?? 540,
      endTimeMinutes: (map['end_time_minutes'] as num?)?.toInt() ?? 630,
      isLab: (map['is_lab'] as num?)?.toInt() == 1,
      isEnrolled: (map['is_enrolled'] as num?)?.toInt() == 1,
    );
  }
}
