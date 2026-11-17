import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/utils/app_feedback.dart';
import '../../../data/models/parking_zone.dart';
import '../parking_provider.dart';

class EvReservationSheet extends StatefulWidget {
  final ParkingZoneModel? initialZone;

  const EvReservationSheet({super.key, this.initialZone});

  @override
  State<EvReservationSheet> createState() => _EvReservationSheetState();
}

class _EvReservationSheetState extends State<EvReservationSheet> {
  late String _selectedZoneId;
  String _selectedStation = 'ST-02';
  String _selectedChargerType = 'DC Fast 50kW (CCS)';
  String _selectedTimeSlot = 'Next 30 mins';
  double _targetBatteryPercent = 80.0;

  final List<String> _timeSlots = [
    'Next 30 mins',
    '14:00 - 15:00',
    '15:30 - 16:30',
    '17:00 - 18:00',
  ];

  final List<String> _stations = ['ST-01', 'ST-02', 'ST-03', 'ST-04'];

  @override
  void initState() {
    super.initState();
    final provider = Provider.of<ParkingProvider>(context, listen: false);
    _selectedZoneId =
        widget.initialZone?.id ??
        (provider.zones.isNotEmpty
            ? provider.zones.first.id
            : 'zone_north_deck');
  }

  double get _estimatedKwh {
    return ((_targetBatteryPercent - 20).clamp(10, 80) * 0.45);
  }

  double get _estimatedCost {
    return (_estimatedKwh * 0.14).clamp(1.50, 18.00);
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final provider = context.watch<ParkingProvider>();

    final currentZone = provider.zones.firstWhere(
      (z) => z.id == _selectedZoneId,
      orElse: () => provider.zones.first,
    );

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
                          color: colors.primaryContainer,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(
                          Icons.ev_station_rounded,
                          color: colors.primary,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'EV CHARGING RADAR',
                              style: TextStyle(
                                color: colors.primary,
                                fontSize: 10,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 0.8,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            Text(
                              'Reserve Charging Slot',
                              style: TextStyle(
                                color: colors.onSurface,
                                fontSize: 16,
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

            // Parking Structure Selector
            Text(
              'PARKING STRUCTURE',
              style: TextStyle(
                color: colors.onSurfaceVariant,
                fontSize: 10,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: provider.zones.map((zone) {
                final isSelected = zone.id == _selectedZoneId;
                return ChoiceChip(
                  label: Text(
                    '${zone.name} (${zone.availableEvSpots} EV)',
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
                  onSelected: (val) {
                    if (val) {
                      setState(() {
                        _selectedZoneId = zone.id;
                        if (zone.chargerTypes.isNotEmpty) {
                          _selectedChargerType = zone.chargerTypes.first;
                        }
                      });
                    }
                  },
                );
              }).toList(),
            ),
            const SizedBox(height: 14),

            // Station & Charger Type Row
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'STATION BAY',
                        style: TextStyle(
                          color: colors.onSurfaceVariant,
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Wrap(
                        spacing: 6,
                        children: _stations.map((st) {
                          final isSelected = st == _selectedStation;
                          return ChoiceChip(
                            label: Text(
                              st,
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: isSelected
                                    ? colors.onSecondary
                                    : colors.onSurface,
                              ),
                            ),
                            selected: isSelected,
                            selectedColor: colors.secondary,
                            backgroundColor: colors.surfaceContainer,
                            showCheckmark: false,
                            onSelected: (val) {
                              if (val) setState(() => _selectedStation = st);
                            },
                          );
                        }).toList(),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),

            // Time Slot Chips
            Text(
              'RESERVATION TIME WINDOW',
              style: TextStyle(
                color: colors.onSurfaceVariant,
                fontSize: 10,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 6),
            Wrap(
              spacing: 8,
              runSpacing: 6,
              children: _timeSlots.map((slot) {
                final isSelected = slot == _selectedTimeSlot;
                return ChoiceChip(
                  label: Text(
                    slot,
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
                  onSelected: (val) {
                    if (val) setState(() => _selectedTimeSlot = slot);
                  },
                );
              }).toList(),
            ),
            const SizedBox(height: 16),

            // Battery Target Slider
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'TARGET BATTERY STATE',
                  style: TextStyle(
                    color: colors.onSurfaceVariant,
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.5,
                  ),
                ),
                Text(
                  '${_targetBatteryPercent.toInt()}% SOC',
                  style: TextStyle(
                    color: colors.primary,
                    fontWeight: FontWeight.w800,
                    fontSize: 13,
                    fontFamily: 'monospace',
                  ),
                ),
              ],
            ),
            Slider(
              value: _targetBatteryPercent,
              min: 30.0,
              max: 100.0,
              divisions: 14,
              activeColor: colors.primary,
              inactiveColor: colors.outlineVariant,
              label: '${_targetBatteryPercent.toInt()}%',
              onChanged: (val) => setState(() => _targetBatteryPercent = val),
            ),
            const SizedBox(height: 10),

            // Telemetry & Energy Estimation Card
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: colors.surfaceContainer,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: colors.outlineVariant),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      children: [
                        Text(
                          'EST. ENERGY',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: colors.onSurfaceVariant,
                            fontSize: 9,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${_estimatedKwh.toStringAsFixed(1)} kWh',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: colors.onSurface,
                            fontWeight: FontWeight.w800,
                            fontSize: 12,
                            fontFamily: 'monospace',
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(width: 1, height: 28, color: colors.outlineVariant),
                  Expanded(
                    child: Column(
                      children: [
                        Text(
                          'CHARGER POWER',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: colors.onSurfaceVariant,
                            fontSize: 9,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          _selectedChargerType.contains('150kW')
                              ? '150 kW'
                              : (_selectedChargerType.contains('50kW')
                                    ? '50 kW'
                                    : '7.2 kW'),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: colors.secondary,
                            fontWeight: FontWeight.w800,
                            fontSize: 12,
                            fontFamily: 'monospace',
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(width: 1, height: 28, color: colors.outlineVariant),
                  Expanded(
                    child: Column(
                      children: [
                        Text(
                          'EST. CREDITS',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: colors.onSurfaceVariant,
                            fontSize: 9,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '\$${_estimatedCost.toStringAsFixed(2)}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: colors.primary,
                            fontWeight: FontWeight.w900,
                            fontSize: 13,
                            fontFamily: 'monospace',
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),

            // Submit Button
            FilledButton.icon(
              onPressed: currentZone.availableEvSpots <= 0
                  ? null
                  : () async {
                      final success = await provider.reserveEvSlot(
                        zoneId: currentZone.id,
                        stationId: _selectedStation,
                        chargerType: _selectedChargerType,
                        slotTime: _selectedTimeSlot,
                        targetBatteryPercent: _targetBatteryPercent.toInt(),
                      );

                      if (context.mounted) {
                        Navigator.of(context).pop();
                        if (success) {
                          AppFeedback.showSuccess(
                            context,
                            'EV Charging Queue Token Issued: ${provider.lastConfirmedReservation?.queueToken ?? "EV-QUEUE-#01"}',
                          );
                        } else {
                          AppFeedback.showError(
                            context,
                            provider.errorMessage ??
                                'Failed to reserve EV station.',
                          );
                        }
                      }
                    },
              icon: const Icon(Icons.bolt_rounded, size: 18),
              label: Text(
                currentZone.availableEvSpots <= 0
                    ? 'No EV Bays Available'
                    : 'Confirm EV Slot Reservation',
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
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
}
