import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/utils/app_feedback.dart';
import '../../data/models/ev_reservation.dart';
import '../../data/models/parking_zone.dart';
import 'parking_provider.dart';
import 'widgets/ev_reservation_sheet.dart';
import 'widgets/permit_qr_dialog.dart';
import 'widgets/permit_renewal_dialog.dart';
import 'widgets/plate_scanner_sheet.dart';

class ParkingRadarView extends StatefulWidget {
  const ParkingRadarView({super.key});

  @override
  State<ParkingRadarView> createState() => _ParkingRadarViewState();
}

class _ParkingRadarViewState extends State<ParkingRadarView> {
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _masterScrollController = ScrollController();
  final ScrollController _detailScrollController = ScrollController();

  final List<String> _filters = [
    'All Lots',
    'Covered',
    'EV Available',
    'Fast Charging',
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ParkingProvider>().loadData();
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
          'Campus Parking & EV Radar',
          style: TextStyle(
            color: colors.onSurface,
            fontWeight: FontWeight.w800,
            fontSize: isLandscape ? 14 : 18,
          ),
        ),
        actions: [
          IconButton(
            tooltip: 'Camera Plate Scanner',
            onPressed: () => _openPlateScanner(context),
            icon: const Icon(Icons.document_scanner_rounded, size: 20),
          ),
          IconButton(
            tooltip: 'Digital Permit Slip',
            onPressed: () => _openPermitDialog(context),
            icon: const Icon(Icons.badge_rounded, size: 20),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'fab_parking_radar',
        onPressed: () => _openEvReservationSheet(context),
        icon: const Icon(Icons.bolt_rounded, size: 20),
        label: const Text(
          'Reserve EV Slot',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
        backgroundColor: colors.primary,
        foregroundColor: colors.onPrimary,
      ),
      body: Consumer<ParkingProvider>(
        builder: (context, provider, _) {
          if (provider.isLoading && provider.zones.isEmpty) {
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
    ParkingProvider provider,
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
            // Overall Campus Occupancy Gauge
            _buildCampusSummaryCard(provider, colors),
            const SizedBox(height: 12),

            // Active Digital Permit Card
            _buildPermitCard(context, provider, colors),
            const SizedBox(height: 12),

            // Search & Filter Section
            _buildSearchAndFilters(provider, colors),
            const SizedBox(height: 12),

            // Section Header
            _buildSectionHeader('PARKING STRUCTURES & LOTS', colors),
            const SizedBox(height: 8),

            // Parking Structure Cards
            _buildZoneList(context, provider, colors),
            const SizedBox(height: 16),

            // EV Charging Queue Ledger
            _buildSectionHeader('MY EV CHARGING RESERVATIONS', colors),
            const SizedBox(height: 8),
            _buildReservationList(context, provider, colors),
            const SizedBox(height: 80), // Fab clearance
          ],
        ),
      ),
    );
  }

  // 360dp Landscape Master-Detail Layout
  Widget _buildLandscapeLayout(
    BuildContext context,
    ParkingProvider provider,
    ColorScheme colors,
  ) {
    return Row(
      children: [
        // Left Master Pane: Radar Summary, Filters & Zone List
        Expanded(
          flex: 5,
          child: SingleChildScrollView(
            controller: _masterScrollController,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildCampusSummaryCard(provider, colors),
                const SizedBox(height: 8),
                _buildSearchAndFilters(provider, colors),
                const SizedBox(height: 8),
                _buildSectionHeader('CAMPUS PARKING RADAR', colors),
                const SizedBox(height: 6),
                _buildZoneList(context, provider, colors),
              ],
            ),
          ),
        ),

        // Vertical Divider
        VerticalDivider(width: 1, color: colors.outlineVariant),

        // Right Detail Pane: Digital Permit, Active EV Reservations
        Expanded(
          flex: 5,
          child: SingleChildScrollView(
            controller: _detailScrollController,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildPermitCard(context, provider, colors),
                const SizedBox(height: 10),
                _buildSectionHeader('ACTIVE EV CHARGING QUEUE', colors),
                const SizedBox(height: 6),
                _buildReservationList(context, provider, colors),
                const SizedBox(height: 60), // Space
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCampusSummaryCard(ParkingProvider provider, ColorScheme colors) {
    final occupancy = provider.overallOccupancyRate;
    final isHigh = occupancy > 0.85;
    final isMedium = occupancy > 0.60;
    final gaugeColor = isHigh
        ? colors.error
        : (isMedium ? colors.tertiary : colors.primary);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: colors.surfaceContainer,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: colors.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.radar_rounded, color: colors.primary, size: 18),
                    const SizedBox(width: 6),
                    Flexible(
                      child: Text(
                        'CAMPUS LOT OCCUPANCY',
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: colors.primary,
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.8,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: gaugeColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  '${(occupancy * 100).toInt()}% OCCUPIED',
                  style: TextStyle(
                    color: gaugeColor,
                    fontSize: 9,
                    fontWeight: FontWeight.w800,
                    fontFamily: 'monospace',
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Linear Occupancy Gauge Bar
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: occupancy,
              minHeight: 8,
              backgroundColor: colors.surfaceContainerHighest,
              color: gaugeColor,
            ),
          ),
          const SizedBox(height: 10),

          // Metrics Row
          Row(
            children: [
              _buildMetricItem(
                label: 'Available Spots',
                value:
                    '${provider.availableCampusSpots}/${provider.totalCampusSpots}',
                colors: colors,
              ),
              Container(width: 1, height: 22, color: colors.outlineVariant),
              _buildMetricItem(
                label: 'EV Chargers',
                value:
                    '${provider.availableEvCampusSpots}/${provider.totalEvCampusSpots}',
                colors: colors,
                valueColor: colors.secondary,
              ),
              Container(width: 1, height: 22, color: colors.outlineVariant),
              _buildMetricItem(
                label: 'Structures',
                value: '${provider.zones.length} Lots',
                colors: colors,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMetricItem({
    required String label,
    required String value,
    required ColorScheme colors,
    Color? valueColor,
  }) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label.toUpperCase(),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 9,
                fontWeight: FontWeight.w700,
                color: colors.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w800,
                fontFamily: 'monospace',
                color: valueColor ?? colors.onSurface,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPermitCard(
    BuildContext context,
    ParkingProvider provider,
    ColorScheme colors,
  ) {
    final permit = provider.activePermit;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colors.surfaceContainer,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: colors.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: colors.primaryContainer,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        Icons.nfc_rounded,
                        size: 16,
                        color: colors.primary,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            permit != null
                                ? permit.permitTier.toUpperCase()
                                : 'NO ACTIVE PERMIT',
                            style: TextStyle(
                              color: colors.primary,
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.5,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            permit != null
                                ? '${permit.vehiclePlate} • ${permit.vehicleModel}'
                                : 'Register vehicle for RFID gate transponder',
                            style: TextStyle(
                              color: colors.onSurface,
                              fontWeight: FontWeight.w700,
                              fontSize: 12,
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
              const SizedBox(width: 8),
              OutlinedButton.icon(
                onPressed: () => _openPermitRenewal(context),
                icon: const Icon(Icons.edit_note_rounded, size: 14),
                label: const Text('Manage', style: TextStyle(fontSize: 11)),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  visualDensity: VisualDensity.compact,
                ),
              ),
            ],
          ),
          if (permit != null) ...[
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    'RFID: ${permit.rfidToken}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 10,
                      color: colors.onSurfaceVariant,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  '${permit.daysRemaining}d left',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: colors.secondary,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSearchAndFilters(ParkingProvider provider, ColorScheme colors) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Search Field
        TextField(
          controller: _searchController,
          onChanged: provider.setSearchQuery,
          decoration: InputDecoration(
            hintText: 'Search lots, engineering deck, DC fast...',
            hintStyle: TextStyle(color: colors.onSurfaceVariant, fontSize: 12),
            prefixIcon: const Icon(Icons.search_rounded, size: 18),
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
              horizontal: 12,
              vertical: 8,
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
        const SizedBox(height: 8),

        // Filter Choice Chips
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
                      fontSize: 11,
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
        fontSize: 10,
        fontWeight: FontWeight.w800,
        color: colors.onSurfaceVariant,
        letterSpacing: 0.8,
      ),
    );
  }

  Widget _buildZoneList(
    BuildContext context,
    ParkingProvider provider,
    ColorScheme colors,
  ) {
    final zones = provider.filteredZones;

    if (zones.isEmpty) {
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
              Icons.no_crash_rounded,
              size: 28,
              color: colors.onSurfaceVariant,
            ),
            const SizedBox(height: 6),
            Text(
              'No parking lots match filter',
              style: TextStyle(
                color: colors.onSurface,
                fontWeight: FontWeight.w700,
                fontSize: 12,
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      children: zones.map((zone) {
        return _buildZoneCard(context, zone, colors);
      }).toList(),
    );
  }

  Widget _buildZoneCard(
    BuildContext context,
    ParkingZoneModel zone,
    ColorScheme colors,
  ) {
    final occupancy = zone.occupancyRate;
    final isHigh = occupancy > 0.85;
    final isMedium = occupancy > 0.60;
    final statusColor = isHigh
        ? colors.error
        : (isMedium ? colors.tertiary : colors.primary);

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colors.surfaceContainer,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: colors.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top Row: Zone Name & Rate
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Row(
                  children: [
                    Icon(
                      zone.isCovered
                          ? Icons.roofing_rounded
                          : Icons.directions_car_filled_rounded,
                      size: 16,
                      color: colors.primary,
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        zone.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: colors.onSurface,
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '\$${zone.hourlyRate.toStringAsFixed(2)}/hr',
                style: TextStyle(
                  color: colors.secondary,
                  fontWeight: FontWeight.w900,
                  fontSize: 12,
                  fontFamily: 'monospace',
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),

          // Campus Area & Hours
          Text(
            '${zone.campusArea} • Hours: ${zone.operationalHours}',
            style: TextStyle(color: colors.onSurfaceVariant, fontSize: 10),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 8),

          // Occupancy Bar
          Row(
            children: [
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: occupancy,
                    minHeight: 6,
                    backgroundColor: colors.surfaceContainerHighest,
                    color: statusColor,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '${zone.availableSpots} Free',
                style: TextStyle(
                  color: statusColor,
                  fontWeight: FontWeight.w800,
                  fontSize: 10,
                  fontFamily: 'monospace',
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // EV Charger Pill Tags & Reservation Button
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Wrap(
                  spacing: 4,
                  runSpacing: 4,
                  children: zone.chargerTypes.map((type) {
                    return Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 5,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: colors.secondaryContainer.withValues(alpha: 0.4),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        type,
                        style: TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.w700,
                          color: colors.onSecondaryContainer,
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(width: 8),
              FilledButton.tonalIcon(
                onPressed: () => _openEvReservationSheet(context, zone: zone),
                icon: const Icon(Icons.bolt_rounded, size: 14),
                label: Text(
                  '${zone.availableEvSpots} EV Bays',
                  style: const TextStyle(fontSize: 10),
                ),
                style: FilledButton.styleFrom(
                  visualDensity: VisualDensity.compact,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildReservationList(
    BuildContext context,
    ParkingProvider provider,
    ColorScheme colors,
  ) {
    final reservations = provider.evReservations;

    if (reservations.isEmpty) {
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
              Icons.ev_station_outlined,
              size: 24,
              color: colors.onSurfaceVariant,
            ),
            const SizedBox(height: 4),
            Text(
              'No active EV charging reservations',
              style: TextStyle(
                color: colors.onSurface,
                fontWeight: FontWeight.w600,
                fontSize: 11,
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      children: reservations.map((res) {
        return _buildReservationCard(context, res, provider, colors);
      }).toList(),
    );
  }

  Widget _buildReservationCard(
    BuildContext context,
    EvReservationModel res,
    ParkingProvider provider,
    ColorScheme colors,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: colors.surfaceContainer,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colors.outlineVariant),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: res.isCancelled
                        ? colors.surfaceContainerHighest
                        : colors.primaryContainer,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.ev_station_rounded,
                    size: 16,
                    color: res.isCancelled
                        ? colors.onSurfaceVariant
                        : colors.primary,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            res.queueToken,
                            style: TextStyle(
                              fontFamily: 'monospace',
                              fontWeight: FontWeight.w800,
                              fontSize: 11,
                              color: res.isCancelled
                                  ? colors.onSurfaceVariant
                                  : colors.primary,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 4,
                              vertical: 1,
                            ),
                            decoration: BoxDecoration(
                              color: res.isCancelled
                                  ? colors.surfaceContainerHighest
                                  : colors.secondaryContainer,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              res.status.toUpperCase(),
                              style: TextStyle(
                                fontSize: 8,
                                fontWeight: FontWeight.w800,
                                color: res.isCancelled
                                    ? colors.onSurfaceVariant
                                    : colors.onSecondaryContainer,
                              ),
                            ),
                          ),
                        ],
                      ),
                      Text(
                        '${res.zoneName} (${res.stationId}) • ${res.slotTime}',
                        style: TextStyle(
                          color: colors.onSurfaceVariant,
                          fontSize: 10,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        'Target: ${res.targetBatteryPercent}% SOC • ${res.estimatedEnergyKwh} kWh (\$${res.costCredits.toStringAsFixed(2)})',
                        style: TextStyle(
                          color: colors.onSurface,
                          fontWeight: FontWeight.w600,
                          fontSize: 9,
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
          if (!res.isCancelled && !res.isCompleted)
            IconButton(
              icon: Icon(Icons.cancel_outlined, size: 18, color: colors.error),
              tooltip: 'Cancel Slot',
              onPressed: () async {
                final success = await provider.cancelReservation(res.id);
                if (context.mounted && success) {
                  AppFeedback.showSuccess(
                    context,
                    'Cancelled EV charging slot ${res.queueToken}',
                  );
                }
              },
            ),
        ],
      ),
    );
  }

  void _openEvReservationSheet(BuildContext context, {ParkingZoneModel? zone}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => EvReservationSheet(initialZone: zone),
    );
  }

  void _openPlateScanner(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const PlateScannerSheet(),
    );
  }

  void _openPermitDialog(BuildContext context) {
    final provider = context.read<ParkingProvider>();
    final permit = provider.activePermit;

    if (permit == null) {
      _openPermitRenewal(context);
      return;
    }

    showDialog(
      context: context,
      builder: (_) => PermitQrDialog(permit: permit),
    );
  }

  void _openPermitRenewal(BuildContext context) {
    showDialog(context: context, builder: (_) => const PermitRenewalDialog());
  }
}
