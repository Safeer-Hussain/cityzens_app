import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/utils/app_feedback.dart';
import '../../../data/models/schedule_conflict.dart';
import '../../../data/models/timetable_slot.dart';
import '../timetable_provider.dart';

class ConflictResolutionSheet extends StatelessWidget {
  final ScheduleConflictModel conflict;

  const ConflictResolutionSheet({super.key, required this.conflict});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final provider = context.watch<TimetableProvider>();

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
                          color: colors.errorContainer,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(
                          Icons.warning_amber_rounded,
                          color: colors.onErrorContainer,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'SCHEDULE OVERLAP DETECTED',
                              style: TextStyle(
                                color: colors.error,
                                fontSize: 10,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 0.8,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            Text(
                              '${conflict.overlapMinutes} Min Overlap on ${conflict.dayName}',
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

            // Conflicting Courses Cards
            Row(
              children: [
                Expanded(
                  child: _buildConflictingCourseCard(
                    context,
                    slot: conflict.slotA,
                    colors: colors,
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: colors.error.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.compare_arrows_rounded,
                    size: 16,
                    color: colors.error,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildConflictingCourseCard(
                    context,
                    slot: conflict.slotB,
                    colors: colors,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),

            // Heuristic Suggested Solutions Header
            Text(
              'HEURISTIC RESOLUTION SUGGESTIONS (0 CONFLICTS)',
              style: TextStyle(
                color: colors.onSurfaceVariant,
                fontSize: 10,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 8),

            // Suggested Alternatives List
            if (conflict.suggestedResolutions.isEmpty)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: colors.surfaceContainer,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: colors.outlineVariant),
                ),
                child: Text(
                  'No direct alternative sections found for these course codes. Consider dropping one of the sections or speaking with an academic advisor.',
                  style: TextStyle(
                    color: colors.onSurfaceVariant,
                    fontSize: 11,
                  ),
                ),
              )
            else
              Column(
                children: conflict.suggestedResolutions.map((alt) {
                  // Determine which slot this alt replaces
                  final replacesSlot =
                      alt.courseCode == conflict.slotA.courseCode
                      ? conflict.slotA
                      : conflict.slotB;

                  return Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: colors.surfaceContainer,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: colors.primary.withValues(alpha: 0.4),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 6,
                                      vertical: 2,
                                    ),
                                    decoration: BoxDecoration(
                                      color: colors.primaryContainer,
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      'RECOMMENDED',
                                      style: TextStyle(
                                        color: colors.onPrimaryContainer,
                                        fontSize: 8,
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  Flexible(
                                    child: Text(
                                      '${alt.courseCode} (${alt.sectionName})',
                                      style: TextStyle(
                                        fontWeight: FontWeight.w800,
                                        fontSize: 12,
                                        color: colors.onSurface,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 3),
                              Text(
                                '${alt.dayName} • ${alt.formattedTime}',
                                style: TextStyle(
                                  color: colors.secondary,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                  fontFamily: 'monospace',
                                ),
                              ),
                              Text(
                                '${alt.instructor} • ${alt.room}',
                                style: TextStyle(
                                  color: colors.onSurfaceVariant,
                                  fontSize: 9,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        FilledButton.icon(
                          onPressed: () async {
                            final success = await provider
                                .resolveWithAlternative(
                                  dropSlotId: replacesSlot.id,
                                  enrollSlotId: alt.id,
                                );

                            if (context.mounted) {
                              Navigator.of(context).pop();
                              if (success) {
                                AppFeedback.showSuccess(
                                  context,
                                  'Schedule conflict resolved! Swapped ${replacesSlot.sectionName} for ${alt.sectionName}.',
                                );
                              } else {
                                AppFeedback.showError(
                                  context,
                                  provider.errorMessage ??
                                      'Failed to resolve schedule conflict.',
                                );
                              }
                            }
                          },
                          icon: const Icon(Icons.swap_horiz_rounded, size: 14),
                          label: const Text(
                            'Swap',
                            style: TextStyle(fontSize: 11),
                          ),
                          style: FilledButton.styleFrom(
                            visualDensity: VisualDensity.compact,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 6,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildConflictingCourseCard(
    BuildContext context, {
    required TimetableSlotModel slot,
    required ColorScheme colors,
  }) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: colors.surfaceContainer,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colors.error.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            slot.courseCode,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w900,
              color: colors.error,
              fontFamily: 'monospace',
            ),
          ),
          Text(
            slot.sectionName,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: colors.onSurface,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          Text(
            slot.formattedTime,
            style: TextStyle(
              fontSize: 9,
              fontFamily: 'monospace',
              fontWeight: FontWeight.w600,
              color: colors.onSurfaceVariant,
            ),
          ),
          Text(
            slot.room,
            style: TextStyle(fontSize: 9, color: colors.onSurfaceVariant),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
