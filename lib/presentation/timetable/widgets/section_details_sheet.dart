import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/utils/app_feedback.dart';
import '../../../data/models/timetable_slot.dart';
import '../timetable_provider.dart';

class SectionDetailsSheet extends StatelessWidget {
  final TimetableSlotModel slot;

  const SectionDetailsSheet({super.key, required this.slot});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final provider = context.watch<TimetableProvider>();
    final isConflicting = provider.isSlotConflicting(slot.id);

    return Container(
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.only(
        top: 16,
        left: 20,
        right: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Drag Handle
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: colors.outlineVariant,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),

            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: slot.isLab
                              ? colors.tertiaryContainer
                              : colors.primaryContainer,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(
                          slot.isLab
                              ? Icons.science_outlined
                              : Icons.school_outlined,
                          color: slot.isLab
                              ? colors.onTertiaryContainer
                              : colors.onPrimaryContainer,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              slot.courseCode,
                              style: TextStyle(
                                color: colors.primary,
                                fontSize: 11,
                                fontWeight: FontWeight.w800,
                                fontFamily: 'monospace',
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            Text(
                              slot.courseTitle,
                              style: TextStyle(
                                color: colors.onSurface,
                                fontSize: 15,
                                fontWeight: FontWeight.w800,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: Icon(
                    Icons.close_rounded,
                    color: colors.onSurfaceVariant,
                    size: 20,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Conflict Alert Banner if conflicting
            if (isConflicting)
              Container(
                margin: const EdgeInsets.only(bottom: 14),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: colors.errorContainer.withValues(alpha: 0.4),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: colors.error),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.warning_amber_rounded,
                      color: colors.error,
                      size: 20,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'This course section overlaps with another course in your active schedule.',
                        style: TextStyle(
                          color: colors.onErrorContainer,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

            // Detail Tiles
            _buildDetailTile(
              context,
              title: 'Section & Type',
              value:
                  '${slot.sectionName} • ${slot.isLab ? "Laboratory Block" : "Lecture Section"}',
              icon: Icons.layers_outlined,
              colors: colors,
            ),
            const SizedBox(height: 8),

            _buildDetailTile(
              context,
              title: 'Day & Schedule',
              value:
                  '${slot.dayName} • ${slot.formattedTime} (${slot.durationMinutes} mins)',
              icon: Icons.access_time_rounded,
              colors: colors,
            ),
            const SizedBox(height: 8),

            _buildDetailTile(
              context,
              title: 'Faculty Instructor',
              value: slot.instructor,
              icon: Icons.person_outline_rounded,
              colors: colors,
            ),
            const SizedBox(height: 8),

            _buildDetailTile(
              context,
              title: 'Campus Facility / Room',
              value: slot.room,
              icon: Icons.location_on_outlined,
              colors: colors,
            ),
            const SizedBox(height: 18),

            // Toggle Enrollment Action Button
            FilledButton.icon(
              onPressed: () async {
                final success = await provider.toggleSlotEnrollment(slot);
                if (context.mounted) {
                  Navigator.of(context).pop();
                  if (success) {
                    AppFeedback.showSuccess(
                      context,
                      slot.isEnrolled
                          ? 'Dropped ${slot.courseCode} (${slot.sectionName}).'
                          : 'Enrolled in ${slot.courseCode} (${slot.sectionName}).',
                    );
                  } else {
                    AppFeedback.showError(
                      context,
                      provider.errorMessage ??
                          'Failed to update course section.',
                    );
                  }
                }
              },
              icon: Icon(
                slot.isEnrolled
                    ? Icons.remove_circle_outline_rounded
                    : Icons.check_circle_outline_rounded,
                size: 18,
              ),
              label: Text(
                slot.isEnrolled
                    ? 'Drop Course Section'
                    : 'Enroll in This Section',
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
              style: FilledButton.styleFrom(
                backgroundColor: slot.isEnrolled
                    ? colors.error
                    : colors.primary,
                foregroundColor: slot.isEnrolled
                    ? colors.onError
                    : colors.onPrimary,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailTile(
    BuildContext context, {
    required String title,
    required String value,
    required IconData icon,
    required ColorScheme colors,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: colors.surfaceContainer,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: colors.outlineVariant.withValues(alpha: 0.5)),
      ),
      child: Row(
        children: [
          Icon(icon, size: 16, color: colors.primary),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title.toUpperCase(),
                  style: TextStyle(
                    fontSize: 8,
                    color: colors.onSurfaceVariant,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.5,
                  ),
                ),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: colors.onSurface,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
