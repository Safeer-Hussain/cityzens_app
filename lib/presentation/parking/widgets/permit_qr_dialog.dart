import 'package:flutter/material.dart';

import '../../../data/models/parking_permit.dart';

class PermitQrDialog extends StatelessWidget {
  final ParkingPermitModel permit;

  const PermitQrDialog({super.key, required this.permit});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final validFromDate = DateTime.fromMillisecondsSinceEpoch(permit.validFrom);
    final validUntilDate = DateTime.fromMillisecondsSinceEpoch(
      permit.validUntil,
    );

    return Dialog(
      backgroundColor: colors.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
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
                            Icons.nfc_rounded,
                            size: 20,
                            color: colors.primary,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'DIGITAL PARKING PERMIT',
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
                                permit.permitTier,
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
                      size: 20,
                      color: colors.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Optical Barcode / RFID Token Representation
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: colors.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: colors.outlineVariant),
                ),
                child: Column(
                  children: [
                    Icon(
                      Icons.qr_code_2_rounded,
                      size: 110,
                      color: colors.onSurface,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      permit.rfidToken,
                      style: TextStyle(
                        fontFamily: 'monospace',
                        fontWeight: FontWeight.w800,
                        fontSize: 12,
                        letterSpacing: 1.2,
                        color: colors.secondary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Optical Scan & Gate RFID Transponder',
                      style: TextStyle(
                        color: colors.onSurfaceVariant,
                        fontSize: 10,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Vehicle & Permit Details
              _buildDetailTile(
                context,
                title: 'Registered Vehicle',
                value: permit.vehicleModel,
                subtitle: permit.vehiclePlate,
                icon: Icons.directions_car_rounded,
                colors: colors,
              ),
              const SizedBox(height: 8),

              _buildDetailTile(
                context,
                title: 'Authorized Zone',
                value: permit.assignedZone,
                subtitle: 'Gate Sensor Verified',
                icon: Icons.local_parking_rounded,
                colors: colors,
              ),
              const SizedBox(height: 8),

              _buildDetailTile(
                context,
                title: 'Validity Term',
                value:
                    '${validFromDate.month}/${validFromDate.day} - ${validUntilDate.month}/${validUntilDate.day}/${validUntilDate.year}',
                subtitle: '${permit.daysRemaining} days remaining',
                icon: Icons.calendar_today_rounded,
                colors: colors,
              ),
              const SizedBox(height: 18),

              // Close Button
              FilledButton.tonal(
                onPressed: () => Navigator.of(context).pop(),
                style: FilledButton.styleFrom(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
                child: const Text('Dismiss Permit Slip'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailTile(
    BuildContext context, {
    required String title,
    required String value,
    required String subtitle,
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
          Icon(icon, size: 18, color: colors.primary),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title.toUpperCase(),
                  style: TextStyle(
                    fontSize: 9,
                    color: colors.onSurfaceVariant,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.5,
                  ),
                ),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: colors.onSurface,
                  ),
                ),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 10,
                    color: colors.secondary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
