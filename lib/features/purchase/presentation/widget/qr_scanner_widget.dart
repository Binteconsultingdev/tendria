import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:tendria/common/settings/language_controller.dart';
import 'package:tendria/common/theme/App_Theme.dart';
import 'package:tendria/features/purchase/presentation/controller/purchase_controller.dart';

mixin QRScannerMixin {
  Rx<MobileScannerController?> get qrScannerController;
  RxBool get isTorchOn;
  void onQRCodeDetected(String qrData);
  void detenerEscaneoQR();
  void iniciarEscaneoQR();
  void toggleTorch();
  void switchCamera();
}

class QRScannerWidget extends StatelessWidget {
  final dynamic controller;
  final String? title;
  final String? description;

  const QRScannerWidget({
    super.key,
    this.controller,
    this.title,
    this.description,
  });

  LanguageController get _l => Get.find<LanguageController>();

  dynamic get _controller {
    if (controller != null) return controller;
    try {
      return Get.find<PurchaseController>();
    } catch (_) {}
    throw Exception('No se encontró un controlador compatible con QRScannerMixin');
  }

  @override
  Widget build(BuildContext context) {
    final scannerController = _controller;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: ThemeColor.surfaceColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 10,
            spreadRadius: 5,
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [ 
          Center(
            child: Container(
              width: 40,
              height: 5,
              decoration: BoxDecoration(
                color: ThemeColor.textSecondaryColor.withOpacity(0.5),
                borderRadius: BorderRadius.circular(3),
              ),
            ),
          ),
          const SizedBox(height: 20),
 
          Text(
            _getTitle(scannerController, title),
            style: ThemeColor.subtitleLarge.copyWith(
              color: ThemeColor.colorAccionButtons,
              fontWeight: FontWeight.bold,
              fontSize: 20,
              letterSpacing: 1.5,
            ),
            textAlign: TextAlign.center,
            overflow: TextOverflow.ellipsis,  
          ),
          const SizedBox(height: 12),
 
          Text(
            _getDescription(scannerController, description),
            style: ThemeColor.bodyMedium.copyWith(
              color: ThemeColor.textSecondaryColor,
              fontSize: 14,
            ),
            textAlign: TextAlign.center,
            maxLines: 2,            
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 20),
 
          SizedBox(
            height: 300,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Obx(() {
                    final scannerCtrl = _getQRScannerController(scannerController);
                    if (scannerCtrl == null || scannerCtrl.value == null) {
                      return Container(
                        color: Colors.black,
                        child: Center(
                          child: CircularProgressIndicator(
                            color: ThemeColor.colorAccionButtons,
                          ),
                        ),
                      );
                    }
                    return MobileScanner(
                      controller: scannerCtrl.value!,
                      onDetect: (capture) {
                        final barcodes = capture.barcodes;
                        if (barcodes.isNotEmpty && barcodes.first.rawValue != null) {
                          scannerController.onQRCodeDetected(barcodes.first.rawValue!);
                        }
                      },
                      errorBuilder: (context, error) {
                        return Container(
                          color: Colors.black,
                          child: Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.error, color: Colors.white, size: 64),
                                const SizedBox(height: 16),
                                Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 16),
                                  child: Text(
                                    '${_l.t('qr_scan_camera_error')}: ${error.errorCode}',
                                    style: ThemeColor.bodyMedium.copyWith(color: Colors.white),
                                    textAlign: TextAlign.center,
                                    overflow: TextOverflow.ellipsis, 
                                    maxLines: 2,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                ElevatedButton(
                                  onPressed: () {
                                    scannerController.detenerEscaneoQR();
                                    scannerController.iniciarEscaneoQR();
                                  },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: ThemeColor.colorAccionButtons,
                                  ),
                                  child: Text(_l.t('qr_scan_restart_camera')),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    );
                  }),

                  Container(
                    decoration: BoxDecoration(
                      border: Border.all(color: ThemeColor.primaryColor, width: 2),
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),

                  Container(
                    height: 200,
                    width: 200,
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.white, width: 2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),

                  ScannerAnimation(
                    width: 180,
                    color: ThemeColor.colorAccionButtons,
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 20),
 
          Text(
            _l.t('qr_scan_instruction'),
            style: ThemeColor.caption.copyWith(
              color: ThemeColor.textSecondaryColor,
              fontStyle: FontStyle.italic,
            ),
            textAlign: TextAlign.center,
            maxLines: 2,             
            overflow: TextOverflow.ellipsis,
          ),

          const SizedBox(height: 20),
 
          Row(
            children: [
              Expanded(
                child: Obx(() => ElevatedButton.icon(
                      onPressed: scannerController.toggleTorch,
                      icon: Icon(
                        _getTorchState(scannerController)
                            ? Icons.flashlight_off
                            : Icons.flashlight_on,
                        color: Colors.white,
                      ),
                      label: Text(
                        _getTorchState(scannerController)
                            ? _l.t('qr_scan_torch_off')
                            : _l.t('qr_scan_torch_on'),
                        overflow: TextOverflow.ellipsis, 
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: ThemeColor.primaryColor,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                      ),
                    )),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: scannerController.switchCamera,
                  icon: const Icon(Icons.cameraswitch, color: Colors.white),
                  label: Text(
                    _l.t('qr_scan_switch_camera'),
                    overflow: TextOverflow.ellipsis, 
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: ThemeColor.primaryColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),
 
          TextButton(
            onPressed: scannerController.detenerEscaneoQR,
            child: Text(
              _l.t('qr_scan_cancel'),
              style: ThemeColor.bodyMedium.copyWith(
                color: ThemeColor.colorAccionButtons,
                fontWeight: FontWeight.bold,
              ),
              overflow: TextOverflow.ellipsis,  
            ),
          ),
        ],
      ),
    );
  }

  String _getTitle(dynamic controller, String? customTitle) {
    if (customTitle != null) return customTitle;
    if (controller is PurchaseController) return _l.t('qr_scan_title');
    return _l.t('qr_scan_default_title');
  }

  String _getDescription(dynamic controller, String? customDescription) {
    if (customDescription != null) return customDescription;
    if (controller is PurchaseController) return _l.t('qr_scan_description');
    return _l.t('qr_scan_default_description');
  }

  bool _getTorchState(dynamic controller) {
    try {
      final v = controller.isTorchOn;
      if (v is RxBool) return v.value;
      if (v is bool) return v;
      return false;
    } catch (_) {
      return false;
    }
  }

  Rx<MobileScannerController?>? _getQRScannerController(dynamic controller) {
    try {
      return controller.qrScannerController as Rx<MobileScannerController?>;
    } catch (_) {
      return null;
    }
  }
}

class ScannerAnimation extends StatefulWidget {
  final double width;
  final Color color;

  const ScannerAnimation({
    super.key,
    required this.width,
    required this.color,
  });

  @override
  State<ScannerAnimation> createState() => _ScannerAnimationState();
}

class _ScannerAnimationState extends State<ScannerAnimation>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);

    _animation = Tween<double>(begin: -100, end: 100).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (_, __) => Positioned(
        top: 150 + _animation.value,
        child: Container(
          height: 2,
          width: widget.width,
          decoration: BoxDecoration(
            color: widget.color,
            boxShadow: [
              BoxShadow(
                color: widget.color.withOpacity(0.7),
                blurRadius: 12,
                spreadRadius: 2,
              ),
            ],
          ),
        ),
      ),
    );
  }
}