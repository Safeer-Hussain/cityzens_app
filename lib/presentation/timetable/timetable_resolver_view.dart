import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../data/models/schedule_conflict.dart';
import '../../data/models/timetable_slot.dart';
import 'timetable_provider.dart';
import 'widgets/conflict_resolution_sheet.dart';
import 'widgets/section_details_sheet.dart';

class TimetableResolverView extends StatefulWidget {
  const TimetableResolverView({super.key});

  @override
  State<TimetableResolverView> createState() => _TimetableResolverViewState();
}

class _TimetableResolverViewState extends State<TimetableResolverView> {
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _masterScrollController = ScrollController();
  final ScrollController _detailScrollController = ScrollController();

  final List<String> _filters = [
    'All',
    'Enrolled Only',
    'Labs Only',
    'Conflicts',
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<TimetableProvider>().loadData();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _masterScrollController.dispose();
    _detailScrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final isLandscape =
        MediaQuery.of(context).orientation == Orientation.landscape;

    return Scaffold(
      backgroundColor: colors.surface,
      appBar: AppBar(
        toolbarHeight: isLandscape ? 36 : 56,
        backgroundColor: colors.surface,
        elevation: 0,
        title: Text(
          'Academic Timetable & Conflict Resolver',
          style: TextStyle(
            color: colors.onSurface,
            fontWeight: FontWeight.w800,
            fontSize: isLandscape ? 14 : 17,
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'fab_timetable_resolver',
        onPressed: () {
          final provider = context.read<TimetableProvider>();
          if (provider.hasConflicts) {
            _openConflictSheet(context, provider.conflicts.first);
          } else {
            provider.setFilter('All');
          }
        },
        icon: Consumer<TimetableProvider>(
          builder: (_, p, _) => Icon(
            p.hasConflicts
                ? Icons.warning_amber_rounded
                : Icons.check_circle_rounded,
            size: 20,
          ),
        ),
        label: Consumer<TimetableProvider>(
          builder: (_, p, _) => Text(
            p.hasConflicts
                ? 'Resolve ${p.conflictsCount} Conflict'
                : 'Schedule Conflict-Free',
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
        ),
        backgroundColor: colors.primary,
        foregroundColor: colors.onPrimary,
      ),
      body: Consumer<TimetableProvider>(
        builder: (context, provider, _) {
          if (provider.isLoading && provider.allSlots.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }

          if (isLandscape) {
            return _buildLandscapeLayout(context, provider, colors);
          }
          return _buildPortraitLayout(context, provider, colors);
        },
      ),
    );
  }

  // Portrait Layout
  Widget _buildPortraitLayout(
    BuildContext context,
    TimetableProvider provider,
    ColorScheme colors,
  ) {
    return RefreshIndicator(
      onRefresh: provider.loadData,
      child: SingleChildScrollView(
        controller: _masterScrollController,
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Conflict Radar Summary Banner
            _buildConflictSummaryCard(context, provider, colors),
            const SizedBox(height: 12),

            // Day Selector Tabs (Mon - Fri)
            _buildDaySelector(provider, colors),
            const SizedBox(height: 10),

            // Search & Filter Row
            _buildSearchAndFilters(provider, colors),
            const SizedBox(height: 12),

            // Section Header
            _buildSectionHeader(
              'COURSE SCHEDULE FOR ${_getDayName(provider.selectedDay).toUpperCase()}',
              colors,
            ),
            const SizedBox(height: 8),

            // Timetable Slots List
            _buildSlotsList(context, provider, colors),
            const SizedBox(height: 16),

            // Active Conflicts Section
            if (provider.hasConflicts) ...[
              _buildSectionHeader('ACTIVE SCHEDULE OVERLAPS', colors),
              const SizedBox(height: 8),
              _buildConflictList(context, provider, colors),
            ],

            const SizedBox(height: 80), // Fab clearance
          ],
        ),
      ),
    );
  }

  // 360dp Landscape Master-Detail Layout
  Widget _buildLandscapeLayout(
    BuildContext context,
    TimetableProvider provider,
    ColorScheme colors,
  ) {
    return Row(
      children: [
        // Master Pane: Summary, Day Selector & Timetable Grid
        Expanded(
          flex: 5,
          child: SingleChildScrollView(
            controller: _masterScrollController,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildConflictSummaryCard(context, provider, colors),
                const SizedBox(height: 8),
                _buildDaySelector(provider, colors),
                const SizedBox(height: 8),
                _buildSearchAndFilters(provider, colors),
                const SizedBox(height: 8),
                _buildSectionHeader('TIMETABLE SCHEDULE', colors),
                const SizedBox(height: 6),
                _buildSlotsList(context, provider, colors),
              ],
            ),
          ),
        ),

        // Vertical Divider
        VerticalDivider(width: 1, color: colors.outlineVariant),

        // Detail Pane: Conflicts Radar & Resolution Actions
        Expanded(
          flex: 5,
          child: SingleChildScrollView(
            controller: _detailScrollController,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildSectionHeader('CONFLICT RADAR & HEURISTICS', colors),
                const SizedBox(height: 6),
                _buildConflictList(context, provider, colors),
                const SizedBox(height: 60), // Fab clearance
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildConflictSummaryCard(
    BuildContext context,
    TimetableProvider provider,
    ColorScheme colors,
  ) {
    final hasConflicts = provider.hasConflicts;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: hasConflicts
            ? colors.errorContainer.withValues(alpha: 0.3)
            : colors.surfaceContainer,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: hasConflicts ? colors.error : colors.outlineVariant,
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: hasConflicts
                        ? colors.error
                        : colors.primaryContainer,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    hasConflicts
                        ? Icons.warning_amber_rounded
                        : Icons.verified_rounded,
                    color: hasConflicts
                        ? colors.onError
                        : colors.onPrimaryContainer,
                    size: 18,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        hasConflicts
                            ? '${provider.conflictsCount} TIMETABLE CONFLICT(S)'
                            : 'SCHEDULE OPTIMAL & CLEAR',
                        style: TextStyle(
                          color: hasConflicts ? colors.error : colors.primary,
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.5,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        hasConflicts
                            ? 'Overlapping course lecture/lab slots detected'
                            : '${provider.enrolledCount} enrolled sections with zero overlaps',
                        style: TextStyle(
                          color: colors.onSurface,
                          fontWeight: FontWeight.w700,
                          fontSize: 11,
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
          if (hasConflicts)
            FilledButton.tonal(
              onPressed: () =>
                  _openConflictSheet(context, provider.conflicts.first),
              style: FilledButton.styleFrom(
                visualDensity: VisualDensity.compact,
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
              ),
              child: const Text('Resolve', style: TextStyle(fontSize: 11)),
            ),
        ],
      ),
    );
  }

  Widget _buildDaySelector(TimetableProvider provider, ColorScheme colors) {
    final days = [
      {'day': 1, 'name': 'Mon'},
      {'day': 2, 'name': 'Tue'},
      {'day': 3, 'name': 'Wed'},
      {'day': 4, 'name': 'Thu'},
      {'day': 5, 'name': 'Fri'},
    ];

    return Row(
      children: days.map((d) {
        final dayNum = d['day'] as int;
        final isSelected = provider.selectedDay == dayNum;

        // Check if this day has any conflict
        final dayHasConflict = provider.conflicts.any(
          (c) => c.slotA.dayOfWeek == dayNum || c.slotB.dayOfWeek == dayNum,
        );

        return Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 2),
            child: InkWell(
              onTap: () => provider.setSelectedDay(dayNum),
              borderRadius: BorderRadius.circular(10),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  color: isSelected
                      ? colors.primary
                      : (dayHasConflict
                            ? colors.errorContainer.withValues(alpha: 0.25)
                            : colors.surfaceContainer),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: isSelected
                        ? colors.primary
                        : (dayHasConflict
                              ? colors.error
                              : colors.outlineVariant),
                  ),
                ),
                child: Column(
                  children: [
                    Text(
                      d['name'] as String,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        color: isSelected
                            ? colors.onPrimary
                            : (dayHasConflict
                                  ? colors.error
                                  : colors.onSurface),
                      ),
                    ),
                    if (dayHasConflict)
                      Container(
                        margin: const EdgeInsets.only(top: 2),
                        width: 4,
                        height: 4,
                        decoration: BoxDecoration(
                          color: isSelected ? colors.onPrimary : colors.error,
                          shape: BoxShape.circle,
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildSearchAndFilters(
    TimetableProvider provider,
    ColorScheme colors,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          controller: _searchController,
          onChanged: provider.setSearchQuery,
          decoration: InputDecoration(
            hintText: 'Search CS-401, Turing Hall, Dr. Thorne...',
            hintStyle: TextStyle(color: colors.onSurfaceVariant, fontSize: 11),
            prefixIcon: const Icon(Icons.search_rounded, size: 16),
            suffixIcon: _searchController.text.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.clear_rounded, size: 16),
                    onPressed: () {
                      _searchController.clear();
                      provider.setSearchQuery('');
                    },
                  )
                : null,
            filled: true,
            fillColor: colors.surfaceContainer,
            isDense: true,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 10,
              vertical: 6,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: colors.outlineVariant),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: colors.outlineVariant),
            ),
          ),
        ),
        const SizedBox(height: 6),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: _filters.map((f) {
              final isSelected = provider.selectedFilter == f;
              return Padding(
                padding: const EdgeInsets.only(right: 6),
                child: ChoiceChip(
                  label: Text(
                    f,
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: isSelected
                          ? FontWeight.w700
                          : FontWeight.w500,
                      color: isSelected ? colors.onPrimary : colors.onSurface,
                    ),
                  ),
                  selected: isSelected,
                  selectedColor: colors.primary,
                  backgroundColor: colors.surfaceContainer,
                  showCheckmark: false,
                  visualDensity: VisualDensity.compact,
                  onSelected: (_) => provider.setFilter(f),
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildSectionHeader(String title, ColorScheme colors) {
    return Text(
      title,
      style: TextStyle(
        fontSize: 9,
        fontWeight: FontWeight.w800,
        color: colors.onSurfaceVariant,
        letterSpacing: 0.8,
      ),
    );
  }

  Widget _buildSlotsList(
    BuildContext context,
    TimetableProvider provider,
    ColorScheme colors,
  ) {
    final slots = provider.slotsForSelectedDay;

    if (slots.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(20),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: colors.surfaceContainer,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: colors.outlineVariant),
        ),
        child: Column(
          children: [
            Icon(
              Icons.event_busy_rounded,
              size: 26,
              color: colors.onSurfaceVariant,
            ),
            const SizedBox(height: 4),
            Text(
              'No course sessions for this filter',
              style: TextStyle(
                color: colors.onSurface,
                fontWeight: FontWeight.w700,
                fontSize: 11,
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      children: slots.map((slot) {
        return _buildSlotCard(context, slot, provider, colors);
      }).toList(),
    );
  }

  Widget _buildSlotCard(
    BuildContext context,
    TimetableSlotModel slot,
    TimetableProvider provider,
    ColorScheme colors,
  ) {
    final isConflicting = provider.isSlotConflicting(slot.id);

    return InkWell(
      onTap: () => _openSectionDetails(context, slot),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: colors.surfaceContainer,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isConflicting
                ? colors.error
                : (slot.isEnrolled
                      ? colors.primary.withValues(alpha: 0.4)
                      : colors.outlineVariant),
            width: isConflicting ? 1.5 : 1.0,
          ),
        ),
        child: Row(
          children: [
            // Time Badge
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
              decoration: BoxDecoration(
                color: isConflicting
                    ? colors.errorContainer
                    : (slot.isEnrolled
                          ? colors.primaryContainer
                          : colors.surfaceContainerHighest),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                children: [
                  Text(
                    slot.formattedTime.split(' - ').first,
                    style: TextStyle(
                      fontFamily: 'monospace',
                      fontWeight: FontWeight.w800,
                      fontSize: 10,
                      color: isConflicting
                          ? colors.onErrorContainer
                          : (slot.isEnrolled
                                ? colors.onPrimaryContainer
                                : colors.onSurfaceVariant),
                    ),
                  ),
                  Text(
                    '${slot.durationMinutes}m',
                    style: TextStyle(
                      fontSize: 8,
                      fontWeight: FontWeight.w700,
                      color: isConflicting
                          ? colors.error
                          : colors.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),

            // Course Details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        slot.courseCode,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          fontFamily: 'monospace',
                          color: isConflicting ? colors.error : colors.primary,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Flexible(
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 4,
                            vertical: 1,
                          ),
                          decoration: BoxDecoration(
                            color: colors.surfaceContainerHighest,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            slot.sectionName,
                            style: TextStyle(
                              fontSize: 8,
                              fontWeight: FontWeight.w700,
                              color: colors.onSurface,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ),
                      if (slot.isLab) ...[
                        const SizedBox(width: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 4,
                            vertical: 1,
                          ),
                          decoration: BoxDecoration(
                            color: colors.tertiaryContainer,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            'LAB',
                            style: TextStyle(
                              fontSize: 8,
                              fontWeight: FontWeight.w800,
                              color: colors.onTertiaryContainer,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  Text(
                    slot.courseTitle,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: colors.onSurface,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    '${slot.instructor} • ${slot.room}',
                    style: TextStyle(
                      fontSize: 9,
                      color: colors.onSurfaceVariant,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),

            // Enrolled / Conflict Indicator
            if (isConflicting)
              Icon(Icons.warning_amber_rounded, color: colors.error, size: 20)
            else if (slot.isEnrolled)
              Icon(Icons.check_circle_rounded, color: colors.primary, size: 18)
            else
              Icon(
                Icons.chevron_right_rounded,
                color: colors.onSurfaceVariant,
                size: 18,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildConflictList(
    BuildContext context,
    TimetableProvider provider,
    ColorScheme colors,
  ) {
    final conflicts = provider.conflicts;

    if (conflicts.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(16),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: colors.surfaceContainer,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: colors.outlineVariant),
        ),
        child: Column(
          children: [
            Icon(
              Icons.check_circle_outline_rounded,
              size: 24,
              color: colors.primary,
            ),
            const SizedBox(height: 4),
            Text(
              'No active schedule conflicts',
              style: TextStyle(
                color: colors.onSurface,
                fontWeight: FontWeight.w700,
                fontSize: 11,
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      children: conflicts.map((c) {
        return Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: colors.surfaceContainer,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: colors.error.withValues(alpha: 0.4)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      '${c.slotA.courseCode} vs ${c.slotB.courseCode}',
                      style: TextStyle(
                        fontFamily: 'monospace',
                        fontWeight: FontWeight.w800,
                        fontSize: 12,
                        color: colors.error,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: colors.errorContainer,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      '${c.overlapMinutes}m Overlap',
                      style: TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.w800,
                        color: colors.onErrorContainer,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 3),
              Text(
                '${c.dayName} • ${c.slotA.formattedTime} & ${c.slotB.formattedTime}',
                style: TextStyle(color: colors.onSurfaceVariant, fontSize: 10),
              ),
              const SizedBox(height: 6),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  OutlinedButton.icon(
                    onPressed: () => _openConflictSheet(context, c),
                    icon: const Icon(Icons.auto_fix_high_rounded, size: 14),
                    label: Text(
                      'Smart Resolve (${c.suggestedResolutions.length} Alts)',
                      style: const TextStyle(fontSize: 10),
                    ),
                    style: OutlinedButton.styleFrom(
                      visualDensity: VisualDensity.compact,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  void _openConflictSheet(
    BuildContext context,
    ScheduleConflictModel conflict,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => ConflictResolutionSheet(conflict: conflict),
    );
  }

  void _openSectionDetails(BuildContext context, TimetableSlotModel slot) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => SectionDetailsSheet(slot: slot),
    );
  }

  String _getDayName(int day) {
    switch (day) {
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
      default:
        return 'Day';
    }
  }
}
