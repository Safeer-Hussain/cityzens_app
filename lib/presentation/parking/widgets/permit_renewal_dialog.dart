import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/utils/app_feedback.dart';
import '../parking_provider.dart';

class PermitRenewalDialog extends StatefulWidget {
  const PermitRenewalDialog({super.key});

  @override
  State<PermitRenewalDialog> createState() => _PermitRenewalDialogState();
}

class _PermitRenewalDialogState extends State<PermitRenewalDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _plateController;
  late TextEditingController _modelController;

  String _selectedTier = 'EV All-Access Pass';
  String _selectedZone = 'All Campus Lots';

  final List<String> _tiers = [
    'EV All-Access Pass',
    'Standard Semester Pass',
    'Commuter Daily Pass',
  ];

  final List<String> _zones = [
    'All Campus Lots',
    'North Structure Multilevel Deck',
    'South STEM Surface Lot',
    'Innovation Hub EV Supercharging Plaza',
  ];

  @override
  void initState() {
    super.initState();
    final provider = Provider.of<ParkingProvider>(context, listen: false);
    _plateController = TextEditingController(
      text: provider.activePermit?.vehiclePlate ?? 'ABC-8842',
    );
    _modelController = TextEditingController(
      text: provider.activePermit?.vehicleModel ?? 'Tesla Model 3 / White',
    );
  }

  @override
  void dispose() {
    _plateController.dispose();
    _modelController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final provider = context.watch<ParkingProvider>();

    return Dialog(
      backgroundColor: colors.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 440),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Form(
            key: _formKey,
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
                              Icons.card_membership_rounded,
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
                                  'STUDENT CREDENTIALS',
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
                                  'Renew Parking Permit',
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
                        size: 20,
                        color: colors.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Permit Tier Selector
                Text(
                  'PERMIT TIER',
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
                  runSpacing: 6,
                  children: _tiers.map((t) {
                    final isSelected = t == _selectedTier;
                    return ChoiceChip(
                      label: Text(
                        t,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: isSelected
                              ? FontWeight.w700
                              : FontWeight.w500,
                          color: isSelected
                              ? colors.onPrimary
                              : colors.onSurface,
                        ),
                      ),
                      selected: isSelected,
                      selectedColor: colors.primary,
                      backgroundColor: colors.surfaceContainer,
                      showCheckmark: false,
                      onSelected: (val) {
                        if (val) setState(() => _selectedTier = t);
                      },
                    );
                  }).toList(),
                ),
                const SizedBox(height: 12),

                // Vehicle Plate
                TextFormField(
                  controller: _plateController,
                  textCapitalization: TextCapitalization.characters,
                  decoration: InputDecoration(
                    labelText: 'Vehicle License Plate',
                    hintText: 'e.g. ABC-8842',
                    prefixIcon: const Icon(Icons.badge_outlined, size: 20),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    isDense: true,
                  ),
                  validator: (val) {
                    if (val == null || val.trim().isEmpty) {
                      return 'Enter a valid license plate string.';
                    }
                    final clean = val.replaceAll(' ', '').toUpperCase().trim();
                    if (!RegExp(r'^[A-Z0-9]{3,4}-?[A-Z0-9]{3,4}$')
                        .hasMatch(clean)) {
                      return 'Invalid plate format (e.g. ABC-8842).';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 12),

                // Vehicle Model
                TextFormField(
                  controller: _modelController,
                  decoration: InputDecoration(
                    labelText: 'Vehicle Make & Model',
                    hintText: 'e.g. Tesla Model 3 / Pearl White',
                    prefixIcon: const Icon(
                      Icons.directions_car_rounded,
                      size: 20,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    isDense: true,
                  ),
                  validator: (val) {
                    if (val == null || val.trim().isEmpty) {
                      return 'Enter vehicle make and model description.';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 12),

                // Assigned Zone Dropdown
                DropdownButtonFormField<String>(
                  initialValue: _selectedZone,
                  decoration: InputDecoration(
                    labelText: 'Authorized Parking Structure',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    isDense: true,
                  ),
                  items: _zones.map((z) {
                    return DropdownMenuItem(
                      value: z,
                      child: Text(z, style: const TextStyle(fontSize: 12)),
                    );
                  }).toList(),
                  onChanged: (val) {
                    if (val != null) setState(() => _selectedZone = val);
                  },
                ),
                const SizedBox(height: 18),

                // Submit Button
                FilledButton.icon(
                  onPressed: () async {
                    if (_formKey.currentState!.validate()) {
                      final success = await provider.renewPermit(
                        vehiclePlate: _plateController.text,
                        vehicleModel: _modelController.text,
                        permitTier: _selectedTier,
                        assignedZone: _selectedZone,
                      );

                      if (context.mounted) {
                        Navigator.of(context).pop();
                        if (success) {
                          AppFeedback.showSuccess(
                            context,
                            'Digital Parking Permit renewed successfully for ${_plateController.text.toUpperCase()}',
                          );
                        } else {
                          AppFeedback.showError(
                            context,
                            provider.errorMessage ??
                                'Failed to renew parking permit.',
                          );
                        }
                      }
                    }
                  },
                  icon: const Icon(Icons.verified_rounded, size: 18),
                  label: const Text('Issue Digital Permit Pass'),
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
