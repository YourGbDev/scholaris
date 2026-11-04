// lib/features/scholarships/presentation/scholarship_qr_scanner_screen.dart
//
// Scholarship QR Scanner screen powered by mobile_scanner.
// Decodes payloads matching `scholaris://scholarships/{scholarship_id}` and
// routes directly to the deep-linked `/scholarship/:id` screen.

import 'package:scholaris/shared/theme/app_typography.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../../../shared/theme/app_motion.dart';

class ScholarshipQrScannerScreen extends StatefulWidget {
  const ScholarshipQrScannerScreen({super.key});

  static Future<void> show(BuildContext context) {
    return Navigator.of(context).push(
      ScholarisPageRoute(builder: (_) => const ScholarshipQrScannerScreen()),
    );
  }

  @override
  State<ScholarshipQrScannerScreen> createState() =>
      _ScholarshipQrScannerScreenState();
}

class _ScholarshipQrScannerScreenState
    extends State<ScholarshipQrScannerScreen> {
  late final MobileScannerController _controller;
  bool _hasScanned = false;
  String? _errorMessage;
  final TextEditingController _manualInputController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _controller = MobileScannerController(
      detectionSpeed: DetectionSpeed.normal,
      facing: CameraFacing.back,
      torchEnabled: false,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    _manualInputController.dispose();
    super.dispose();
  }

  void _handlePayload(String rawPayload) {
    if (_hasScanned) return;

    final trimmed = rawPayload.trim();
    // Validate scheme: scholaris://scholarships/{id} or scholaris://scholarship/{id}
    final uri = Uri.tryParse(trimmed);
    String? scholarshipId;

    if (uri != null && uri.scheme == 'scholaris') {
      if (uri.host == 'scholarships' || uri.host == 'scholarship') {
        final pathSegments = uri.pathSegments;
        if (pathSegments.isNotEmpty) {
          scholarshipId = pathSegments.first;
        } else if (uri.path.isNotEmpty) {
          scholarshipId = uri.path.replaceAll('/', '');
        }
      }
    } else if (trimmed.contains('/scholarship/')) {
      // Tolerate web deep links: https://.../scholarship/{id}
      scholarshipId = trimmed.split('/scholarship/').last.split('?').first;
    }

    if (scholarshipId != null && scholarshipId.isNotEmpty) {
      HapticFeedback.heavyImpact();
      setState(() {
        _hasScanned = true;
        _errorMessage = null;
      });

      // Navigate directly to /scholarship/:id using existing GoRouter deep link
      if (mounted) {
        Navigator.of(context).pop();
        context.push('/scholarship/$scholarshipId');
      }
    } else {
      HapticFeedback.vibrate();
      // Handle invalid/unrecognized payload with clear inline error state
      setState(() {
        _errorMessage =
            'Unrecognized QR Code. Expected format: scholaris://scholarships/{id}.\nPayload: "$trimmed"';
      });
    }
  }

  void _resetScan() {
    HapticFeedback.lightImpact();
    setState(() {
      _hasScanned = false;
      _errorMessage = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Stack(
          children: [
            // 1. MobileScanner Camera View
            MobileScanner(
              controller: _controller,
              onDetect: (capture) {
                if (_hasScanned || _errorMessage != null) return;
                for (final barcode in capture.barcodes) {
                  final raw = barcode.rawValue;
                  if (raw != null && raw.isNotEmpty) {
                    _handlePayload(raw);
                    break;
                  }
                }
              },
              errorBuilder: (context, error) {
                return _buildCameraFallback(error.toString());
              },
            ),

            // 2. Viewfinder Overlay
            _buildViewfinderOverlay(),

            // 3. Top Navigation Bar (Apple HIG translucent LiquidGlass style)
            Positioned(
              top: 12,
              left: 16,
              right: 16,
              child: LiquidGlass(
                blur: 16,
                borderRadius: 20,
                tintColor: Colors.black,
                tintOpacity: 0.50,
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                child: Row(
                  children: [
                    PressableScale(
                      child: IconButton(
                        icon: const Icon(
                          Icons.arrow_back_rounded,
                          color: Colors.white,
                        ),
                        tooltip: 'Back',
                        onPressed: () {
                          HapticFeedback.lightImpact();
                          Navigator.of(context).pop();
                        },
                      ),
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        'Scan Scholarship QR',
                        style: AppTypography.style(
                          AppTextRole.screenTitle,
                          fontSize: 16.5,
                          color: Colors.white,
                          height: 1.25,
                          letterSpacing: -0.15,
                        ),
                      ),
                    ),
                    PressableScale(
                      child: IconButton(
                        icon: ValueListenableBuilder<MobileScannerState>(
                          valueListenable: _controller,
                          builder: (context, state, _) {
                            final isOn = state.torchState == TorchState.on;
                            return Icon(
                              isOn
                                  ? Icons.flash_on_rounded
                                  : Icons.flash_off_rounded,
                              color: isOn ? Colors.amber : Colors.white,
                            );
                          },
                        ),
                        tooltip: 'Toggle Flashlight',
                        onPressed: () {
                          HapticFeedback.lightImpact();
                          _controller.toggleTorch();
                        },
                      ),
                    ),
                    PressableScale(
                      child: IconButton(
                        icon: const Icon(
                          Icons.flip_camera_ios_rounded,
                          color: Colors.white,
                        ),
                        tooltip: 'Switch Camera',
                        onPressed: () {
                          HapticFeedback.lightImpact();
                          _controller.switchCamera();
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // 4. Bottom Controls & Inline Error Banner (LiquidGlass)
            Positioned(
              bottom: 16,
              left: 16,
              right: 16,
              child: LiquidGlass(
                blur: 16,
                borderRadius: 22,
                tintColor: Colors.black,
                tintOpacity: 0.55,
                padding: const EdgeInsets.all(16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (_errorMessage != null) ...[
                      // Inline Error Banner
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFBA1A1A)
                              .withValues(alpha: 0.92),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.white24),
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Row(
                              children: [
                                const Icon(
                                  Icons.error_outline_rounded,
                                  color: Colors.white,
                                  size: 20,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    'Invalid QR Payload',
                                    style: AppTypography.style(
                                      AppTextRole.sectionTitle,
                                      fontSize: 13,
                                      color: Colors.white,
                                      height: 1.25,
                                      letterSpacing: 0,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Text(
                              _errorMessage!,
                              style: AppTypography.style(
                                AppTextRole.body,
                                fontSize: 12,
                                color: Colors.white,
                                height: 1.4,
                                letterSpacing: 0,
                              ),
                            ),
                            const SizedBox(height: 10),
                            PressableScale(
                              child: ElevatedButton.icon(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.white,
                                  foregroundColor: const Color(0xFFBA1A1A),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 8,
                                  ),
                                ),
                                onPressed: _resetScan,
                                icon: const Icon(
                                  Icons.refresh_rounded,
                                  size: 16,
                                ),
                                label: const Text('Scan Again'),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 14),
                    ] else ...[
                      Text(
                        'Align the scholarship QR code within the frame',
                        textAlign: TextAlign.center,
                        style: AppTypography.style(
                          AppTextRole.caption,
                          fontSize: 13,
                          color: Colors.white.withValues(alpha: 0.85),
                          height: 1.4,
                          letterSpacing: 0,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Format: scholaris://scholarships/{id}',
                        textAlign: TextAlign.center,
                        style: AppTypography.style(
                          AppTextRole.caption,
                          fontSize: 11,
                          color: const Color(0xFFB3F1C6),
                          height: 1.25,
                          letterSpacing: 0,
                        ),
                      ),
                      const SizedBox(height: 14),
                    ],

                    // Manual Code Input Trigger (Accessibility & Testing)
                    PressableScale(
                      child: TextButton.icon(
                        style: TextButton.styleFrom(
                          foregroundColor: Colors.white,
                          backgroundColor: Colors.white.withValues(alpha: 0.14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                        ),
                        onPressed: () {
                          HapticFeedback.lightImpact();
                          _showManualInputDialog();
                        },
                        icon: const Icon(Icons.keyboard_alt_outlined, size: 16),
                        label: Text(
                          'Enter Code or URL Manually',
                          style: AppTypography.style(
                            AppTextRole.button,
                            fontSize: 12,
                            height: 1.25,
                            letterSpacing: 0,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildViewfinderOverlay() {
    return Center(
      child: Container(
        width: 240,
        height: 240,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: _errorMessage != null
                ? Colors.redAccent
                : const Color(0xFFB3F1C6),
            width: 2.5,
          ),
          boxShadow: [
            BoxShadow(
              color:
                  (_errorMessage != null ? Colors.red : const Color(0xFF0F4D2E))
                      .withValues(alpha: 0.35),
              blurRadius: 20,
              spreadRadius: 2,
            ),
          ],
        ),
        child: Stack(
          children: [
            // Corner Reticles
            Positioned(
              top: 12,
              left: 12,
              child: Container(
                width: 20,
                height: 20,
                decoration: const BoxDecoration(
                  border: Border(
                    top: BorderSide(color: Colors.white, width: 3),
                    left: BorderSide(color: Colors.white, width: 3),
                  ),
                ),
              ),
            ),
            Positioned(
              top: 12,
              right: 12,
              child: Container(
                width: 20,
                height: 20,
                decoration: const BoxDecoration(
                  border: Border(
                    top: BorderSide(color: Colors.white, width: 3),
                    right: BorderSide(color: Colors.white, width: 3),
                  ),
                ),
              ),
            ),
            Positioned(
              bottom: 12,
              left: 12,
              child: Container(
                width: 20,
                height: 20,
                decoration: const BoxDecoration(
                  border: Border(
                    bottom: BorderSide(color: Colors.white, width: 3),
                    left: BorderSide(color: Colors.white, width: 3),
                  ),
                ),
              ),
            ),
            Positioned(
              bottom: 12,
              right: 12,
              child: Container(
                width: 20,
                height: 20,
                decoration: const BoxDecoration(
                  border: Border(
                    bottom: BorderSide(color: Colors.white, width: 3),
                    right: BorderSide(color: Colors.white, width: 3),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCameraFallback(String error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.videocam_off_outlined,
              size: 48,
              color: Colors.white54,
            ),
            const SizedBox(height: 12),
            Text(
              'Camera Unavailable',
              style: AppTypography.style(
                AppTextRole.sectionTitle,
                fontSize: 17,
                color: Colors.white,
                height: 1.25,
                letterSpacing: -0.15,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Camera hardware or permission is not active. You can still enter or paste a scholarship code directly.',
              textAlign: TextAlign.center,
              style: AppTypography.style(
                AppTextRole.body,
                fontSize: 13,
                color: Colors.white70,
                height: 1.4,
                letterSpacing: 0,
              ),
            ),
            const SizedBox(height: 16),
            PressableScale(
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0F4D2E),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 10,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: _showManualInputDialog,
                icon: const Icon(Icons.edit_note_rounded, size: 18),
                label: const Text('Enter Code Manually'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showManualInputDialog() {
    _manualInputController.clear();
    showDialog<void>(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Enter Scholarship Code',
          style: AppTypography.style(
            AppTextRole.sectionTitle,
            fontSize: 17,
            height: 1.25,
            letterSpacing: -0.15,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Paste a QR payload or enter the scholarship ID directly:',
              style: AppTypography.style(
                AppTextRole.body,
                fontSize: 13,
                color: const Color(0xFF404942),
                height: 1.4,
                letterSpacing: 0,
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _manualInputController,
              decoration: InputDecoration(
                hintText: 'scholaris://scholarships/{id}',
                hintStyle: AppTypography.style(
                  AppTextRole.placeholder,
                  fontSize: 12.5,
                  color: Colors.black38,
                  height: 1.4,
                  letterSpacing: 0,
                ),
                filled: true,
                fillColor: const Color(0xFFF4F3F8),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogCtx).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF0F4D2E),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            onPressed: () {
              final text = _manualInputController.text.trim();
              Navigator.of(dialogCtx).pop();
              if (text.isNotEmpty) {
                _handlePayload(text);
              }
            },
            child: const Text('Submit'),
          ),
        ],
      ),
    );
  }
}
