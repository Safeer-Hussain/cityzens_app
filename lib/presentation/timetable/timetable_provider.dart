import 'package:flutter/foundation.dart';

import '../../data/models/schedule_conflict.dart';
import '../../data/models/timetable_slot.dart';
import '../../data/repositories/timetable_repository.dart';

class TimetableProvider extends ChangeNotifier {
  final TimetableRepository repository;

  bool _isLoading = false;
  String? _errorMessage;

  List<TimetableSlotModel> _allSlots = [];
  int _selectedDay = 1; // 1 = Monday
  String _searchQuery = '';
  String _selectedFilter =
      'All'; // 'All', 'Enrolled Only', 'Labs Only', 'Conflicts'
  List<ScheduleConflictModel> _conflicts = [];

  TimetableProvider({required this.repository});

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  List<TimetableSlotModel> get allSlots => List.unmodifiable(_allSlots);
  int get selectedDay => _selectedDay;
  String get searchQuery => _searchQuery;
  String get selectedFilter => _selectedFilter;
  List<ScheduleConflictModel> get conflicts => List.unmodifiable(_conflicts);

  int get conflictsCount => _conflicts.length;
  bool get hasConflicts => _conflicts.isNotEmpty;

  int get enrolledCount => _allSlots.where((s) => s.isEnrolled).length;

  List<TimetableSlotModel> get slotsForSelectedDay {
    return _allSlots.where((slot) {
      if (slot.dayOfWeek != _selectedDay) return false;

      if (_selectedFilter == 'Enrolled Only' && !slot.isEnrolled) {
        return false;
      }
      if (_selectedFilter == 'Labs Only' && !slot.isLab) {
        return false;
      }
      if (_selectedFilter == 'Conflicts') {
        final isConflicting = _conflicts.any(
          (c) => c.slotA.id == slot.id || c.slotB.id == slot.id,
        );
        if (!isConflicting) return false;
      }

      if (_searchQuery.trim().isNotEmpty) {
        final q = _searchQuery.trim().toLowerCase();
        final matchesCode = slot.courseCode.toLowerCase().contains(q);
        final matchesTitle = slot.courseTitle.toLowerCase().contains(q);
        final matchesInstructor = slot.instructor.toLowerCase().contains(q);
        final matchesRoom = slot.room.toLowerCase().contains(q);
        if (!matchesCode &&
            !matchesTitle &&
            !matchesInstructor &&
            !matchesRoom) {
          return false;
        }
      }

      return true;
    }).toList();
  }

  bool isSlotConflicting(String slotId) {
    return _conflicts.any((c) => c.slotA.id == slotId || c.slotB.id == slotId);
  }

  Future<void> loadData() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _allSlots = await repository.getAllSlots();
      _detectConflicts();
    } catch (e) {
      _errorMessage = 'Failed to load timetable: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void setSelectedDay(int day) {
    if (_selectedDay == day) return;
    _selectedDay = day;
    notifyListeners();
  }

  void setSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  void setFilter(String filter) {
    if (_selectedFilter == filter) return;
    _selectedFilter = filter;
    notifyListeners();
  }

  void _detectConflicts() {
    final enrolled = _allSlots.where((s) => s.isEnrolled).toList();
    final List<ScheduleConflictModel> detected = [];

    for (int i = 0; i < enrolled.length; i++) {
      for (int j = i + 1; j < enrolled.length; j++) {
        final slotA = enrolled[i];
        final slotB = enrolled[j];

        if (slotA.overlapsWith(slotB)) {
          final overlap = slotA.overlapMinutesWith(slotB);

          // Find heuristic non-conflicting alternatives
          final alternatives = _findSuggestedResolutions(
            slotA,
            slotB,
            enrolled,
          );

          detected.add(
            ScheduleConflictModel(
              slotA: slotA,
              slotB: slotB,
              overlapMinutes: overlap,
              suggestedResolutions: alternatives,
            ),
          );
        }
      }
    }

    _conflicts = detected;
  }

  List<TimetableSlotModel> _findSuggestedResolutions(
    TimetableSlotModel slotA,
    TimetableSlotModel slotB,
    List<TimetableSlotModel> currentEnrolled,
  ) {
    final List<TimetableSlotModel> candidates = [];

    // Check alternatives for slotA
    final altsForA = _allSlots.where(
      (s) =>
          s.courseCode == slotA.courseCode && s.id != slotA.id && !s.isEnrolled,
    );

    for (final alt in altsForA) {
      // Check if alt overlaps with any enrolled course EXCEPT slotA
      final overlapsOther = currentEnrolled
          .where((e) => e.id != slotA.id)
          .any((e) => e.overlapsWith(alt));
      if (!overlapsOther) {
        candidates.add(alt);
      }
    }

    // Check alternatives for slotB
    final altsForB = _allSlots.where(
      (s) =>
          s.courseCode == slotB.courseCode && s.id != slotB.id && !s.isEnrolled,
    );

    for (final alt in altsForB) {
      // Check if alt overlaps with any enrolled course EXCEPT slotB
      final overlapsOther = currentEnrolled
          .where((e) => e.id != slotB.id)
          .any((e) => e.overlapsWith(alt));
      if (!overlapsOther) {
        candidates.add(alt);
      }
    }

    return candidates;
  }

  Future<bool> resolveWithAlternative({
    required String dropSlotId,
    required String enrollSlotId,
  }) async {
    try {
      await repository.swapSections(
        dropSlotId: dropSlotId,
        enrollSlotId: enrollSlotId,
      );
      _allSlots = await repository.getAllSlots();
      _detectConflicts();
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = 'Failed to swap course section: $e';
      notifyListeners();
      return false;
    }
  }

  Future<bool> toggleSlotEnrollment(TimetableSlotModel slot) async {
    try {
      final newStatus = !slot.isEnrolled;
      await repository.setEnrollment(slot.id, newStatus);
      _allSlots = await repository.getAllSlots();
      _detectConflicts();
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = 'Failed to update course enrollment: $e';
      notifyListeners();
      return false;
    }
  }
}
