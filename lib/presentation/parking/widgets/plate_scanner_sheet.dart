import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/utils/app_feedback.dart';
import '../parking_provider.dart';

class PlateScannerSheet extends StatefulWidget {
  const PlateScannerSheet({super.key});

  @override
  State<PlateScannerSheet> createState() => _PlateScannerSheetState();
}

class _PlateScannerSheetState extends State<PlateScannerSheet> {
  final TextEditingController _plateController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isOcrSimulating = false;
  double _ocrConfidence = 0.98;

  @override
  void initState() {
    super.initState();
    final provider = Provider.of<ParkingProvider>(context, listen: false);
    if (provider.activePermit != null) {
      _plateController.text = provider.activePermit!.vehiclePlate;
    }
  }

  @override
  void dispose() {
    _plateController.dispose();
    super.dispose();
  }

  void _triggerOcrCapture(String testPlate) {
    setState(() {
      _isOcrSimulating = true;
      _plateController.text = testPlate;
    });

    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted) {
        setState(() {
          _isOcrSimulating = false;
          _ocrConfidence = 0.99;
        });
        final provider = Provider.of<ParkingProvider>(context, listen: false);
        provider.simulatePlateScan(testPlate);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final provider = context.watch<ParkingProvider>();
    final activePermit = provider.activePermit;

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
        child: Form(
          key: _formKey,
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
                            Icons.camera_alt_rounded,
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
                                'NATIVE CAMERA OCR BRIDGE',
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
                                'License Plate Scanner',
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

              // Simulated Optical Viewfinder
              Container(
                height: 160,
                decoration: BoxDecoration(
                  color: colors.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: colors.outlineVariant),
                ),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    // Corner Reticle Guides
                    Positioned.fill(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: CustomPaint(
                          painter: _ViewfinderReticlePainter(
                            color: colors.primary,
                          ),
                        ),
                      ),
                    ),

                    // Optical Plate Bounding Box
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: colors.surface.withValues(alpha: 0.9),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: provider.plateMatchesPermit
                              ? colors.primary
                              : colors.outlineVariant,
                          width: 2,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.directions_car_rounded,
                            size: 18,
                            color: colors.onSurfaceVariant,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            _plateController.text.isNotEmpty
                                ? _plateController.text
                                : 'SCANNING...',
                            style: TextStyle(
                              fontFamily: 'monospace',
                              fontWeight: FontWeight.w900,
                              fontSize: 18,
                              letterSpacing: 2.0,
                              color: colors.onSurface,
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Scanning line animation indicator
                    if (_isOcrSimulating)
                      Positioned(
                        top: 20,
                        left: 30,
                        right: 30,
                        child: LinearProgressIndicator(
                          color: colors.primary,
                          backgroundColor: Colors.transparent,
                        ),
                      ),

                    // Status pill at bottom
                    Positioned(
                      bottom: 10,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: colors.surface,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: colors.outlineVariant),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.verified_rounded,
                              size: 12,
                              color: colors.secondary,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'OCR Confidence: ${(_ocrConfidence * 100).toInt()}% • ML Kit Vision',
                              style: TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.w700,
                                color: colors.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Match Status Card
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: provider.plateMatchesPermit
                      ? colors.primaryContainer.withValues(alpha: 0.35)
                      : colors.surfaceContainer,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: provider.plateMatchesPermit
                        ? colors.primary
                        : colors.outlineVariant,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      provider.plateMatchesPermit
                          ? Icons.check_circle_rounded
                          : Icons.info_outline_rounded,
                      color: provider.plateMatchesPermit
                          ? colors.primary
                          : colors.onSurfaceVariant,
                      size: 20,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            provider.plateMatchesPermit
                                ? 'ACTIVE DIGITAL PERMIT VERIFIED'
                                : 'UNREGISTERED OR EXTERNAL VEHICLE',
                            style: TextStyle(
                              color: provider.plateMatchesPermit
                                  ? colors.primary
                                  : colors.onSurface,
                              fontWeight: FontWeight.w800,
                              fontSize: 11,
                              letterSpacing: 0.5,
                            ),
                          ),
                          Text(
                            provider.plateMatchesPermit
                                ? 'Pass: ${activePermit?.permitTier ?? "All-Access"} • Gate barrier auto-open enabled'
                                : 'Plate does not match student permit. Standard hourly meter applies.',
                            style: TextStyle(
                              color: colors.onSurfaceVariant,
                              fontSize: 10,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Manual Entry / Test Presets
              Text(
                'TEST OCR OPTICAL PRESETS',
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
                children: [
                  ActionChip(
                    label: const Text('ABC-8842 (Tesla M3)'),
                    avatar: const Icon(Icons.flash_on_rounded, size: 14),
                    onPressed: () => _triggerOcrCapture('ABC-8842'),
                  ),
                  ActionChip(
                    label: const Text('KPK-9120 (Guest)'),
                    avatar: const Icon(Icons.directions_car_rounded, size: 14),
                    onPressed: () => _triggerOcrCapture('KPK-9120'),
                  ),
                  ActionChip(
                    label: const Text('LHR-4040 (Faculty)'),
                    avatar: const Icon(Icons.school_rounded, size: 14),
                    onPressed: () => _triggerOcrCapture('LHR-4040'),
                  ),
                ],
              ),
              const SizedBox(height: 14),

              // Form Field for Manual Plate
              TextFormField(
                controller: _plateController,
                textCapitalization: TextCapitalization.characters,
                decoration: InputDecoration(
                  labelText: 'Manual Vehicle License Plate',
                  hintText: 'e.g. ABC-8842',
                  prefixIcon: const Icon(Icons.badge_outlined, size: 20),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  isDense: true,
                ),
                validator: (val) {
                  if (val == null || val.trim().isEmpty) {
                    return 'Please enter a valid license plate string.';
                  }
                  final clean = val.replaceAll(' ', '').toUpperCase().trim();
                  if (!RegExp(r'^[A-Z0-9]{3,4}-?[A-Z0-9]{3,4}$')
                      .hasMatch(clean)) {
                    return 'Invalid plate format (e.g. ABC-8842 or LHR4040).';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 18),

              // Action Buttons
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () {
                        provider.clearScannedPlate();
                        setState(() => _plateController.clear());
                      },
                      style: OutlinedButton.styleFrom(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      child: const Text('Reset Scanner'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: () {
                        if (_formKey.currentState!.validate()) {
                          provider.simulatePlateScan(_plateController.text);
                          AppFeedback.showSuccess(
                            context,
                            'OCR Plate Verified: ${_plateController.text.toUpperCase()}',
                          );
                        }
                      },
                      icon: const Icon(
                        Icons.document_scanner_rounded,
                        size: 18,
                      ),
                      label: const Text('Verify Plate'),
                      style: FilledButton.styleFrom(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ViewfinderReticlePainter extends CustomPainter {
  final Color color;

  _ViewfinderReticlePainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke;

    const cornerLength = 20.0;

    // Top-Left
    canvas.drawLine(const Offset(0, 0), const Offset(cornerLength, 0), paint);
    canvas.drawLine(const Offset(0, 0), const Offset(0, cornerLength), paint);

    // Top-Right
    canvas.drawLine(
      Offset(size.width, 0),
      Offset(size.width - cornerLength, 0),
      paint,
    );
    canvas.drawLine(
      Offset(size.width, 0),
      Offset(size.width, cornerLength),
      paint,
    );

    // Bottom-Left
    canvas.drawLine(
      Offset(0, size.height),
      Offset(cornerLength, size.height),
      paint,
    );
    canvas.drawLine(
      Offset(0, size.height),
      Offset(0, size.height - cornerLength),
      paint,
    );

    // Bottom-Right
    canvas.drawLine(
      Offset(size.width, size.height),
      Offset(size.width - cornerLength, size.height),
      paint,
    );
    canvas.drawLine(
      Offset(size.width, size.height),
      Offset(size.width, size.height - cornerLength),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
