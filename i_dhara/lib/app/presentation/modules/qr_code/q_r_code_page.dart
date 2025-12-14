// import 'package:flutter/material.dart';
// import 'package:google_fonts/google_fonts.dart';
// import 'package:mobile_scanner/mobile_scanner.dart';

// import '../../../core/flutter_flow/flutter_flow_theme.dart';
// import '../../../core/flutter_flow/flutter_flow_util.dart';
// import 'q_r_code_controller.dart';

// export 'q_r_code_controller.dart';

// class QRCodeWidget extends StatefulWidget {
//   const QRCodeWidget({super.key});

//   static String routeName = 'QR_Code';
//   static String routePath = '/qRCode';

//   @override
//   State<QRCodeWidget> createState() => _QRCodeWidgetState();
// }

// class _QRCodeWidgetState extends State<QRCodeWidget> {
//   late QRCodeModel _model;
//   final scaffoldKey = GlobalKey<ScaffoldState>();

//   // Mobile Scanner Controller
//   late MobileScannerController cameraController;

//   String? _scannedCode;

//   @override
//   void initState() {
//     super.initState();
//     _model = createModel(context, () => QRCodeModel());

//     // Initialize scanner immediately
//     cameraController = MobileScannerController(
//       detectionSpeed: DetectionSpeed.noDuplicates,
//       facing: CameraFacing.back,
//       torchEnabled: false,
//     );
//   }

//   @override
//   void dispose() {
//     cameraController.dispose();
//     _model.dispose();
//     super.dispose();
//   }

//   void _onDetect(BarcodeCapture capture) {
//     final List<Barcode> barcodes = capture.barcodes;
//     for (final barcode in barcodes) {
//       if (barcode.rawValue != null) {
//         setState(() {
//           _scannedCode = barcode.rawValue;
//         });
//         // Handle the scanned QR code here
//         print('QR Code detected: ${barcode.rawValue}');

//         // Show dialog with scanned code
//         _showScannedDialog(barcode.rawValue!);
//         break;
//       }
//     }
//   }

//   void _showScannedDialog(String code) {
//     showDialog(
//       context: context,
//       builder: (context) => AlertDialog(
//         title: const Text('QR Code Scanned'),
//         content: Text('Code: $code'),
//         actions: [
//           TextButton(
//             onPressed: () {
//               Navigator.pop(context);
//               setState(() {
//                 _scannedCode = null;
//               });
//             },
//             child: const Text('Scan Again'),
//           ),
//           TextButton(
//             onPressed: () {
//               Navigator.pop(context);
//               // Process the scanned code and navigate or perform action
//             },
//             child: const Text('OK'),
//           ),
//         ],
//       ),
//     );
//   }

//   void _toggleFlash() {
//     cameraController.toggleTorch();
//   }

//   @override
//   Widget build(BuildContext context) {
//     return GestureDetector(
//       onTap: () {
//         FocusScope.of(context).unfocus();
//         FocusManager.instance.primaryFocus?.unfocus();
//       },
//       child: Scaffold(
//         key: scaffoldKey,
//         body: Container(
//           decoration: BoxDecoration(
//             image: DecorationImage(
//               fit: BoxFit.cover,
//               image: Image.asset(
//                 'assets/images/QR_Code.png',
//               ).image,
//             ),
//           ),
//           child: Padding(
//             padding: const EdgeInsetsDirectional.fromSTEB(16.0, 0.0, 16.0, 0.0),
//             child: Column(
//               mainAxisSize: MainAxisSize.max,
//               mainAxisAlignment: MainAxisAlignment.start,
//               children: [
//                 Padding(
//                   padding: const EdgeInsetsDirectional.fromSTEB(
//                       16.0, 0.0, 16.0, 0.0),
//                   child: Row(
//                     mainAxisSize: MainAxisSize.max,
//                     mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                     children: [
//                       InkWell(
//                         onTap: () {
//                           Navigator.pop(context);
//                         },
//                         child: Container(
//                           decoration: const BoxDecoration(),
//                           child: const Padding(
//                             padding: EdgeInsets.all(6.0),
//                             child: Icon(
//                               Icons.arrow_back,
//                               color: Color(0xFF004E7E),
//                               size: 20.0,
//                             ),
//                           ),
//                         ),
//                       ),
//                       Text(
//                         'Scan QR',
//                         style: FlutterFlowTheme.of(context).bodyMedium.override(
//                               font: GoogleFonts.dmSans(
//                                 fontWeight: FontWeight.w500,
//                               ),
//                               color: const Color(0xFF004E7E),
//                               fontSize: 16.0,
//                               letterSpacing: 0.0,
//                               fontWeight: FontWeight.w500,
//                             ),
//                       ),
//                       InkWell(
//                         onTap: _toggleFlash,
//                         child: const Icon(
//                           Icons.flash_on,
//                           color: Color(0xFF004E7E),
//                           size: 24.0,
//                         ),
//                       ),
//                     ],
//                   ),
//                 ),
//                 Expanded(
//                   child: Column(
//                     mainAxisSize: MainAxisSize.max,
//                     mainAxisAlignment: MainAxisAlignment.center,
//                     children: [
//                       // QR Scanner View - Always visible
//                       Container(
//                         width: 300,
//                         height: 300,
//                         decoration: BoxDecoration(
//                           borderRadius: BorderRadius.circular(12.0),
//                           border: Border.all(
//                             color: const Color(0xFF004E7E),
//                             width: 2.0,
//                           ),
//                         ),
//                         child: ClipRRect(
//                           borderRadius: BorderRadius.circular(12.0),
//                           child: MobileScanner(
//                             controller: cameraController,
//                             onDetect: _onDetect,
//                           ),
//                         ),
//                       ),

//                       const SizedBox(height: 24.0),

//                       // Manual PCB entry text
//                       InkWell(
//                         onTap: () {
//                           // Navigate to manual PCB entry screen
//                           print('Manual PCB entry tapped');
//                         },
//                         child: Text(
//                           'Or Enter PCB Number',
//                           style:
//                               FlutterFlowTheme.of(context).bodyMedium.override(
//                                     font: GoogleFonts.dmSans(),
//                                     color: const Color(0xFF101828),
//                                     fontSize: 16.0,
//                                     letterSpacing: 0.0,
//                                     decoration: TextDecoration.underline,
//                                   ),
//                         ),
//                       ),
//                     ],
//                   ),
//                 ),
//               ]
//                   .divide(const SizedBox(height: 0.0))
//                   .addToStart(const SizedBox(height: 56.0)),
//             ),
//           ),
//         ),
//       ),
//     );
//   }
// }

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
    await Future.delayed(const Duration(seconds: 1)).then((value) {
      if (isScanCompleted) return;
      isScanCompleted = true;

      final List<Barcode> barcodes = capture.barcodes;
      for (final barcode in barcodes) {
        final String? code = barcode.rawValue;
        if (code != null && context.mounted) {
          cameraController.stop();

          // Handle the scanned QR code here
          print('QR Code detected: $code');
          Get.toNamed(Routes.addDevices, arguments: {
            'pcbNumber': code,
          });
          break;
        }
      }
    });
  }

  // void _showScannedDialog(String code) {
  //   showDialog(
  //     context: context,
  //     barrierDismissible: false,
  //     builder: (context) => AlertDialog(
  //       title: const Text('QR Code Scanned'),
  //       content: Text('Code: $code'),
  //       actions: [
  //         TextButton(
  //           onPressed: () {
  //             Navigator.pop(context);
  //             setState(() {
  //               isScanCompleted = false;
  //             });
  //             cameraController.start();
  //           },
  //           child: const Text('Scan Again'),
  //         ),
  //         TextButton(
  //           onPressed: () {
  //             Navigator.pop(context);
  //             // TODO: Navigate to next screen or process the code
  //             // Example: context.pushNamed('/nextScreen', extra: {'code': code});
  //             Navigator.pop(context); // Go back to previous screen
  //           },
  //           child: const Text('OK'),
  //         ),
  //       ],
  //     ),
  //   );
  // }

  void _toggleFlash() {
    cameraController.toggleTorch();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
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
                      child: const Icon(
                        Icons.flash_on,
                        color: Colors.white,
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
                        key: UniqueKey(),
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
    );
  }
}
