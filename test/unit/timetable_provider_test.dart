import 'package:flutter_test/flutter_test.dart';
import 'package:cityzens_app/data/repositories/timetable_repository.dart';
import 'package:cityzens_app/presentation/timetable/timetable_provider.dart';

import '../helpers/test_database.dart';

void main() {
  group('TimetableProvider & Repository Business Logic Tests', () {
    late TimetableRepository repository;
    late TimetableProvider provider;

    setUp(() async {
      final db = await createTestDatabase();
      repository = TimetableRepository(database: db);
      provider = TimetableProvider(repository: repository);
    });

    test(
      'Initializes with seeded timetable slots and detects initial conflict',
      () async {
        await provider.loadData();

        expect(provider.allSlots.isNotEmpty, true);
        expect(provider.enrolledCount, greaterThan(0));

        // There should be a conflict between CS-401 Section A and SE-420 Section A on Wednesday
        expect(provider.hasConflicts, true);
        expect(provider.conflictsCount, equals(1));

        final conflict = provider.conflicts.first;
        expect(conflict.dayName, equals('Wednesday'));
        expect(conflict.overlapMinutes, equals(60));
        expect(
          (conflict.slotA.courseCode == 'CS-401' &&
                  conflict.slotB.courseCode == 'SE-420') ||
              (conflict.slotA.courseCode == 'SE-420' &&
                  conflict.slotB.courseCode == 'CS-401'),
          true,
        );
      },
    );

    test(
      'Generates heuristic non-conflicting alternative recommendations',
      () async {
        await provider.loadData();

        final conflict = provider.conflicts.first;
        expect(conflict.suggestedResolutions.isNotEmpty, true);

        // Alternatives should include SE-420 Section B (Afternoon) or CS-401 Section B
        final hasSe420Alt = conflict.suggestedResolutions.any(
          (alt) =>
              alt.courseCode == 'SE-420' &&
              alt.sectionName.contains('Afternoon'),
        );
        expect(hasSe420Alt, true);
      },
    );

    test(
      'Swapping section to suggested alternative eliminates conflict',
      () async {
        await provider.loadData();
        expect(provider.hasConflicts, true);

        final conflict = provider.conflicts.first;
        final se420Alt = conflict.suggestedResolutions.firstWhere(
          (alt) => alt.courseCode == 'SE-420',
        );
        final conflictingSe420Slot = conflict.slotA.courseCode == 'SE-420'
            ? conflict.slotA
            : conflict.slotB;

        final success = await provider.resolveWithAlternative(
          dropSlotId: conflictingSe420Slot.id,
          enrollSlotId: se420Alt.id,
        );

        expect(success, true);
        expect(provider.hasConflicts, false);
        expect(provider.conflictsCount, equals(0));
      },
    );

    test('Toggling slot enrollment adds or drops course section', () async {
      await provider.loadData();

      // Find an unenrolled slot
      final unenrolledSlot = provider.allSlots.firstWhere((s) => !s.isEnrolled);
      final initialEnrolled = provider.enrolledCount;

      final enrollSuccess = await provider.toggleSlotEnrollment(unenrolledSlot);
      expect(enrollSuccess, true);
      expect(provider.enrolledCount, equals(initialEnrolled + 1));

      // Drop it back
      final updatedSlot = provider.allSlots.firstWhere(
        (s) => s.id == unenrolledSlot.id,
      );
      final dropSuccess = await provider.toggleSlotEnrollment(updatedSlot);
      expect(dropSuccess, true);
      expect(provider.enrolledCount, equals(initialEnrolled));
    });

    test('Day selector filters slots by weekday', () async {
      await provider.loadData();

      provider.setSelectedDay(1); // Monday
      for (final slot in provider.slotsForSelectedDay) {
        expect(slot.dayOfWeek, equals(1));
      }

      provider.setSelectedDay(5); // Friday
      for (final slot in provider.slotsForSelectedDay) {
        expect(slot.dayOfWeek, equals(5));
      }
    });

    test('Search query matches course code, title, and instructor', () async {
      await provider.loadData();

      provider.setSelectedDay(1);
      provider.setSearchQuery('CS-401');

      for (final slot in provider.slotsForSelectedDay) {
        expect(slot.courseCode, contains('CS-401'));
      }
    });
  });
}
