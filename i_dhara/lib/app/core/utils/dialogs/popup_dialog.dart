import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../flutter_flow/flutter_flow_widgets.dart';

class PopupDialog extends StatelessWidget {
  final bool isactive;
  final String title;
  final String buttonlable;
  final String description;
  final String iconAssetPath;
  final VoidCallback onDelete;
  final VoidCallback? onCancel;

  const PopupDialog({
    super.key,
    required this.title,
    this.isactive = false,
    required this.buttonlable,
    required this.description,
    required this.iconAssetPath,
    required this.onDelete,
    this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      backgroundColor: Colors.transparent,
      child: Container(
        width: 368,
        height: 260,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.only(left: 0, bottom: 0, right: 0, top: 20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const SizedBox(height: 10),
              // Icon
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: SvgPicture.asset(
                  iconAssetPath,
                  width: 70,
                  height: 70,
                  fit: BoxFit.cover,
                ),
              ),
              const SizedBox(height: 10),
              // Title
              Text(
                title,
                style: GoogleFonts.inter(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Colors.black,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              // Description
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Text(
                    description,
                    textAlign: TextAlign.center,
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      color: Colors.grey[600],
                      height: 1.4,
                    ),
                  ),
                ),
              ),

              // Buttons Row
              Padding(
                padding: const EdgeInsets.only(left: 30, bottom: 10, right: 10),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: onCancel ?? () => Navigator.of(context).pop(),
                        child: Text(
                          "Cancel",
                          style: GoogleFonts.inter(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                            color: Colors.grey[700],
                          ),
                        ),
                      ),
                    ),

                    Expanded(
                      child: FFButtonWidget(
                        showLoadingIndicator: true,
                        onPressed: onDelete,
                        text: buttonlable,
                        options: FFButtonOptions(
                          disabledColor: Colors.transparent,
                          elevation: 0,
                          width: double.infinity,
                          height: 45.0,
                          padding: const EdgeInsetsDirectional.fromSTEB(
                              24.0, 0.0, 20.0, 0.0),
                          color: Colors.white,
                          textStyle: GoogleFonts.inter(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color:
                                isactive ? Colors.green[600] : Colors.red[600],
                          ),
                          borderRadius: BorderRadius.circular(20.0),
                        ),
                      ),
                    )
                    // GestureDetector(
                    //   onTap: () {
                    //     onDelete();
                    //   },
                    //   child: Text(
                    //     "Delete",
                    //     style: GoogleFonts.inter(
                    //       fontSize: 16,
                    //       fontWeight: FontWeight.w600,
                    //       color: Colors.red[600],
                    //     ),
                    //   ),
                    // ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
