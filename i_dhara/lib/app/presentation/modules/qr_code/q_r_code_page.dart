import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:i_dhara/app/presentation/routes/app_routes.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../../../core/flutter_flow/flutter_flow_util.dart';
import 'q_r_code_controller.dart';

export 'q_r_code_controller.dart';

class QRCodeWidget extends StatefulWidget {
  const QRCodeWidget({super.key});

  static String routeName = 'QR_Code';
  static String routePath = '/qRCode';

  @override
  State<QRCodeWidget> createState() => _QRCodeWidgetState();
}

class _QRCodeWidgetState extends State<QRCodeWidget> {
  late QRCodeModel _model;
  final scaffoldKey = GlobalKey<ScaffoldState>();

  // Mobile Scanner Controller
  late MobileScannerController cameraController;
  bool isScanCompleted = false;
  bool isTorchOn = false;

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => QRCodeModel());

    // Initialize scanner immediately
    cameraController = MobileScannerController(
      facing: CameraFacing.back,
      detectionSpeed: DetectionSpeed.noDuplicates,
    );
  }

  @override
  void dispose() {
    cameraController.dispose();
    _model.dispose();
    super.dispose();
  }

  void _handleBarcodeDetected(BarcodeCapture capture) async {
    if (isScanCompleted) return;

    setState(() {
      isScanCompleted = true;
    });

    final List<Barcode> barcodes = capture.barcodes;
    for (final barcode in barcodes) {
      final String? code = barcode.rawValue;
      if (code != null && context.mounted) {
        // Handle the scanned QR code here
        print('QR Code detected: $code');

        // Turn off torch before navigating
        if (isTorchOn) {
          await cameraController.toggleTorch();
        }

        cameraController.stop();

        Get.toNamed(Routes.addDevices, arguments: {
          'pcbNumber': code,
        });
        break;
      }
    }
  }

  Future<void> _toggleFlash() async {
    try {
      await cameraController.toggleTorch();
      setState(() {
        isTorchOn = !isTorchOn;
      });
    } catch (e) {
      print('Error toggling torch: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        return false;
      },
      child: GestureDetector(
        onTap: () {
          FocusScope.of(context).unfocus();
          FocusManager.instance.primaryFocus?.unfocus();
        },
        child: Scaffold(
          key: scaffoldKey,
          backgroundColor: Colors.black.withOpacity(0.6),
          body: SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Header
                Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16.0, vertical: 16.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      InkWell(
                        onTap: () {
                          Navigator.pop(context);
                        },
                        child: Container(
                          decoration: const BoxDecoration(),
                          child: const Padding(
                            padding: EdgeInsets.all(6.0),
                            child: Icon(
                              Icons.arrow_back,
                              color: Colors.white,
                              size: 20.0,
                            ),
                          ),
                        ),
                      ),
                      Text(
                        'Scan QR',
                        style: GoogleFonts.dmSans(
                          fontWeight: FontWeight.w500,
                          color: Colors.white,
                          fontSize: 16.0,
                          letterSpacing: 0.0,
                        ),
                      ),
                      InkWell(
                        onTap: _toggleFlash,
                        child: Icon(
                          isTorchOn ? Icons.flash_on : Icons.flash_off,
                          color: isTorchOn ? Colors.yellow : Colors.white,
                          size: 24.0,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 30),
                // Instruction Text
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 30.0),
                  child: Center(
                    child: Text(
                      'Please scan the QR code on the PCB to proceed.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 40),
                // QR Scanner View - Centered
                Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20.0),
                    child: Container(
                      height: 300,
                      width: 300,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12.0),
                        border: Border.all(
                          color: Colors.white,
                          width: 2.0,
                        ),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12.0),
                        child: MobileScanner(
                          controller: cameraController,
                          onDetect: _handleBarcodeDetected,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 40),
                // Manual PCB entry text
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 30.0),
                  child: Center(
                    child: GestureDetector(
                      onTap: () {
                        print('Manual PCB entry tapped');
                        cameraController.dispose();
                        Get.offAllNamed(Routes.addDevices);
                      },
                      child: Text(
                        'Or Enter PCB Number',
                        style: GoogleFonts.dmSans(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w400,
                          decoration: TextDecoration.underline,
                        ),
                      ),
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
