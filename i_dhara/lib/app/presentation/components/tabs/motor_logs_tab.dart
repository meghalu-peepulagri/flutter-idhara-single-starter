// import 'package:flutter/material.dart';
// import 'package:get/get.dart';
// import 'package:google_fonts/google_fonts.dart';
// import 'package:i_dhara/app/presentation/components/tabs/motor_logs_controller.dart';
// import 'package:i_dhara/app/presentation/components/tabs/widgets/alerts_list_widget.dart';
// import 'package:i_dhara/app/presentation/components/tabs/widgets/empty_logs_widget.dart';
// import 'package:i_dhara/app/presentation/components/tabs/widgets/faults_list_widget.dart';
// import 'package:i_dhara/app/presentation/components/tabs/widgets/pump_logs_list_widget.dart';

// class MotorLogsTab extends StatefulWidget {
//   const MotorLogsTab({super.key});

//   @override
//   State<MotorLogsTab> createState() => _MotorLogsTabState();
// }

// class _MotorLogsTabState extends State<MotorLogsTab> {
//   String? selectedFilter;
//   final MotorLogsController logsController = Get.put(MotorLogsController());

//   @override
//   void initState() {
//     super.initState();
//     selectedFilter = 'Faults';
//     logsController.currentFilter.value = 'Faults';
//     // logsController.fetchMotorFaults();
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Obx(() {
//       // if (controller.isLoading.value && controller.motorFaultsList.isEmpty) {
//       //   return const Center(child: CircularProgressIndicator());
//       // }
//       return ListView(
//         controller: logsController.scrollController,
//         physics: const AlwaysScrollableScrollPhysics(),
//         padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
//         children: [
//           Row(
//             mainAxisAlignment: MainAxisAlignment.spaceBetween,
//             children: [
//               SizedBox(
//                 height: 36,
//                 child: selectedFilter != null
//                     ? _buildSelectedFilterInlineChip(
//                         _isPumpFilter(selectedFilter!)
//                             ? 'Pump: $selectedFilter'
//                             : selectedFilter!,
//                         _getFilterColor(selectedFilter!),
//                         // Only show cancel button if NOT Faults (default)
//                         selectedFilter != 'Faults'
//                             ? () {
//                                 setState(() {
//                                   selectedFilter =
//                                       'Faults'; // Return to default
//                                   logsController.currentFilter.value = 'Faults';
//                                   logsController.resetPagination();
//                                   logsController.fetchMotorFaults();
//                                 });
//                               }
//                             : null, // No cancel for Faults
//                       )
//                     : const SizedBox(),
//               ),
//               PopupMenuButton<String>(
//                 icon: const Icon(
//                   Icons.filter_list,
//                   color: Color(0xFF004E7E),
//                   size: 26,
//                 ),
//                 shape: RoundedRectangleBorder(
//                   borderRadius: BorderRadius.circular(12),
//                 ),
//                 offset: const Offset(0, 40),
//                 onSelected: (value) {
//                   setState(() {
//                     if (selectedFilter == value) {
//                       // If clicking the same filter, return to default (Faults)
//                       selectedFilter = 'Faults';
//                       logsController.currentFilter.value = 'Faults';
//                       logsController.resetPagination();
//                       logsController.fetchMotorFaults();
//                     } else {
//                       selectedFilter = value;
//                       logsController.currentFilter.value = value;

//                       // Reset pagination and fetch data
//                       logsController.resetPagination();

//                       if (value == 'Alerts') {
//                         logsController.fetchMotorAlerts();
//                       } else if (value == 'Faults') {
//                         logsController.fetchMotorFaults();
//                       } else if (value == 'MODE') {
//                         logsController.fetchMotorLogs('MODE');
//                       } else if (value == 'ON') {
//                         logsController.fetchMotorLogs('ON');
//                       } else if (value == 'OFF') {
//                         logsController.fetchMotorLogs('OFF');
//                       }
//                     }
//                   });
//                 },
//                 itemBuilder: (context) => [
//                   _buildMainMenuItem('Faults', selectedFilter == 'Faults'),
//                   _buildMainMenuItem('Alerts', selectedFilter == 'Alerts'),
//                   PopupMenuItem<String>(
//                     enabled: false,
//                     padding: EdgeInsets.zero,
//                     child: _buildPumpsMenuItemWithSubmenu(context),
//                   ),
//                 ],
//               ),
//             ],
//           ),
//           const SizedBox(height: 16),

//           // Show initial loading
//           if (logsController.isLoading.value &&
//               !logsController.isLoadingMore.value)
//             SizedBox(
//               height: MediaQuery.of(context).size.height * 0.45,
//               child: const Center(
//                 child: CircularProgressIndicator(
//                   color: Color(0xFF004E7E),
//                 ),
//               ),
//             )
//           else
//             _buildLogsContent(),

//           // Show loading more indicator
//           if (logsController.isLoadingMore.value)
//             const Padding(
//               padding: EdgeInsets.symmetric(vertical: 16.0),
//               child: Center(
//                 child: SizedBox(
//                   width: 24,
//                   height: 24,
//                   child: CircularProgressIndicator(
//                     color: Color(0xFF004E7E),
//                     strokeWidth: 2.5,
//                   ),
//                 ),
//               ),
//             ),
//         ],
//       );
//     });
//   }

//   int _getListLength() {
//     if (selectedFilter == 'Faults') {
//       return logsController.motorFaultsList.length;
//     } else if (selectedFilter == 'Alerts') {
//       return logsController.motorAlertsList.length;
//     } else if (_isPumpFilter(selectedFilter ?? '')) {
//       return logsController.motorLogsList.length;
//     }
//     return 0;
//   }

//   Widget _buildLogsContent() {
//     // Always default to Faults if nothing selected
//     if (selectedFilter == null || selectedFilter == 'Faults') {
//       return FaultsListWidget(faults: logsController.motorFaultsList);
//     } else if (selectedFilter == 'Alerts') {
//       return AlertsListWidget(alerts: logsController.motorAlertsList);
//     } else if (_isPumpFilter(selectedFilter!)) {
//       final logs = logsController.motorLogsList;
//       return PumpLogsListWidget(logs: logs, filterType: selectedFilter!);
//     }
//     return const EmptyLogsWidget(message: 'No logs available');
//   }

//   bool _isPumpFilter(String filter) {
//     return filter == 'ON' || filter == 'OFF' || filter == 'MODE';
//   }

//   Widget _buildPumpsMenuItemWithSubmenu(BuildContext context) {
//     bool isPumpSelected =
//         selectedFilter != null && _isPumpFilter(selectedFilter!);

//     return PopupMenuButton<String>(
//       offset: const Offset(-120, 0),
//       shape: RoundedRectangleBorder(
//         borderRadius: BorderRadius.circular(12),
//       ),
//       onSelected: (value) {
//         setState(() {
//           if (selectedFilter == value) {
//             // Return to default (Faults)
//             selectedFilter = 'Faults';
//             logsController.currentFilter.value = 'Faults';
//             logsController.resetPagination();
//             logsController.fetchMotorFaults();
//           } else {
//             selectedFilter = value;
//             logsController.currentFilter.value = value;
//             logsController.resetPagination();
//             logsController.fetchMotorLogs(value);
//           }
//         });
//         Navigator.of(context).pop();
//       },
//       child: Padding(
//         padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
//         child: Row(
//           children: [
//             Container(
//               width: 20,
//               height: 20,
//               decoration: BoxDecoration(
//                 color: isPumpSelected
//                     ? const Color(0xFF3B82F6)
//                     : Colors.transparent,
//                 border: Border.all(
//                   color: isPumpSelected
//                       ? const Color(0xFF3B82F6)
//                       : const Color(0xFFD1D5DB),
//                   width: 2,
//                 ),
//                 borderRadius: BorderRadius.circular(4),
//               ),
//               child: isPumpSelected
//                   ? const Icon(
//                       Icons.check,
//                       size: 14,
//                       color: Colors.white,
//                     )
//                   : null,
//             ),
//             const SizedBox(width: 12),
//             Text(
//               'Pump',
//               style: GoogleFonts.dmSans(
//                 fontSize: 14,
//                 fontWeight: FontWeight.w500,
//                 color: isPumpSelected
//                     ? const Color(0xFF3B82F6)
//                     : const Color(0xFF1F2937),
//               ),
//             ),
//           ],
//         ),
//       ),
//       itemBuilder: (context) => [
//         _buildPumpMenuItem('ON', selectedFilter == 'ON'),
//         _buildPumpMenuItem('OFF', selectedFilter == 'OFF'),
//         _buildPumpMenuItem('MODE', selectedFilter == 'MODE'),
//       ],
//     );
//   }

//   Widget _buildSelectedFilterInlineChip(
//     String label,
//     Color color,
//     VoidCallback? onRemove, // Made nullable
//   ) {
//     return Container(
//       padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
//       decoration: BoxDecoration(
//         color: color.withOpacity(0.1),
//         borderRadius: BorderRadius.circular(8),
//         border: Border.all(
//           color: color.withOpacity(0.3),
//           width: 1,
//         ),
//       ),
//       child: Row(
//         mainAxisSize: MainAxisSize.min,
//         children: [
//           Text(
//             label,
//             style: GoogleFonts.dmSans(
//               fontSize: 14,
//               fontWeight: FontWeight.w500,
//               color: color,
//             ),
//           ),
//           // Only show close icon if onRemove is not null
//           if (onRemove != null) ...[
//             const SizedBox(width: 8),
//             GestureDetector(
//               onTap: onRemove,
//               child: Icon(
//                 Icons.close,
//                 size: 16,
//                 color: color,
//               ),
//             ),
//           ],
//         ],
//       ),
//     );
//   }

//   Color _getFilterColor(String filter) {
//     switch (filter) {
//       case 'Faults':
//         return const Color(0xFFEF4444);
//       case 'Alerts':
//         return const Color(0xFFF59E0B);
//       case 'ON':
//         return const Color(0xFF10B981);
//       case 'OFF':
//         return const Color(0xFFEF4444);
//       case 'MODE':
//         return const Color(0xFF8B5CF6);
//       default:
//         return const Color(0xFF6B7280);
//     }
//   }

//   PopupMenuItem<String> _buildMainMenuItem(String value, bool isSelected) {
//     return PopupMenuItem<String>(
//       value: value,
//       height: 36,
//       padding: const EdgeInsets.symmetric(horizontal: 12.0),
//       child: Row(children: [
//         Container(
//           width: 20,
//           height: 20,
//           decoration: BoxDecoration(
//             color: isSelected ? _getFilterColor(value) : Colors.transparent,
//             border: Border.all(
//               color:
//                   isSelected ? _getFilterColor(value) : const Color(0xFFD1D5DB),
//               width: 2,
//             ),
//             borderRadius: BorderRadius.circular(4),
//           ),
//           child: isSelected
//               ? const Icon(
//                   Icons.check,
//                   size: 14,
//                   color: Colors.white,
//                 )
//               : null,
//         ),
//         const SizedBox(width: 12),
//         Text(
//           value,
//           style: GoogleFonts.dmSans(
//             fontSize: 14,
//             fontWeight: FontWeight.w500,
//             color:
//                 isSelected ? _getFilterColor(value) : const Color(0xFF1F2937),
//           ),
//         ),
//       ]),
//     );
//   }

//   PopupMenuItem<String> _buildPumpMenuItem(String value, bool isSelected) {
//     return PopupMenuItem<String>(
//       value: value,
//       height: 36,
//       padding: const EdgeInsets.symmetric(horizontal: 12.0),
//       child: Row(
//         mainAxisAlignment: MainAxisAlignment.spaceBetween,
//         children: [
//           Text(
//             value,
//             style: GoogleFonts.dmSans(
//               fontSize: 14,
//               fontWeight: FontWeight.w500,
//               color:
//                   isSelected ? _getFilterColor(value) : const Color(0xFF1F2937),
//             ),
//           ),
//           if (isSelected)
//             Icon(
//               Icons.check,
//               size: 18,
//               color: _getFilterColor(value),
//             ),
//         ],
//       ),
//     );
//   }
// }

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:i_dhara/app/presentation/components/tabs/motor_logs_controller.dart';
import 'package:i_dhara/app/presentation/components/tabs/widgets/alerts_list_widget.dart';
import 'package:i_dhara/app/presentation/components/tabs/widgets/empty_logs_widget.dart';
import 'package:i_dhara/app/presentation/components/tabs/widgets/faults_list_widget.dart';
import 'package:i_dhara/app/presentation/components/tabs/widgets/pump_logs_list_widget.dart';
import 'package:skeletonizer/skeletonizer.dart';

class MotorLogsTab extends StatefulWidget {
  const MotorLogsTab({super.key});

  @override
  State<MotorLogsTab> createState() => _MotorLogsTabState();
}

class _MotorLogsTabState extends State<MotorLogsTab> {
  String? selectedFilter;
  final MotorLogsController logsController = Get.put(MotorLogsController());

  @override
  void initState() {
    super.initState();
    selectedFilter = 'Faults';
    logsController.currentFilter.value = 'Faults';
  }

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<MotorLogsController>();

    return Obx(() {
      if (controller.isLoading.value &&
          controller.motorFaultsList.isEmpty &&
          controller.motorAlertsList.isEmpty &&
          controller.motorLogsList.isEmpty) {
        return const Center(child: CircularProgressIndicator());
      }

      return Skeletonizer(
        enabled: controller.isRefreshing.value,
        child: ListView(
          controller: logsController.scrollController,
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                SizedBox(
                  height: 36,
                  child: selectedFilter != null
                      ? _buildSelectedFilterInlineChip(
                          _isPumpFilter(selectedFilter!)
                              ? 'Pump: $selectedFilter'
                              : selectedFilter!,
                          _getFilterColor(selectedFilter!),
                          selectedFilter != 'Faults'
                              ? () {
                                  setState(() {
                                    selectedFilter = 'Faults';
                                    logsController.currentFilter.value =
                                        'Faults';
                                    logsController.resetPagination();
                                    logsController.fetchMotorFaults();
                                  });
                                }
                              : null,
                        )
                      : const SizedBox(),
                ),
                PopupMenuButton<String>(
                  icon: const Icon(
                    Icons.filter_list,
                    color: Color(0xFF004E7E),
                    size: 26,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  offset: const Offset(0, 40),
                  onSelected: (value) {
                    setState(() {
                      if (selectedFilter == value) {
                        selectedFilter = 'Faults';
                        logsController.currentFilter.value = 'Faults';
                        logsController.resetPagination();
                        logsController.fetchMotorFaults();
                      } else {
                        selectedFilter = value;
                        logsController.currentFilter.value = value;
                        logsController.resetPagination();

                        if (value == 'Alerts') {
                          logsController.fetchMotorAlerts();
                        } else if (value == 'Faults') {
                          logsController.fetchMotorFaults();
                        } else if (value == 'MODE') {
                          logsController.fetchMotorLogs('MODE');
                        } else if (value == 'ON') {
                          logsController.fetchMotorLogs('ON');
                        } else if (value == 'OFF') {
                          logsController.fetchMotorLogs('OFF');
                        }
                      }
                    });
                  },
                  itemBuilder: (context) => [
                    _buildMainMenuItem('Faults', selectedFilter == 'Faults'),
                    _buildMainMenuItem('Alerts', selectedFilter == 'Alerts'),
                    PopupMenuItem<String>(
                      enabled: false,
                      padding: EdgeInsets.zero,
                      child: _buildPumpsMenuItemWithSubmenu(context),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Show initial loading
            if (logsController.isLoading.value &&
                !logsController.isLoadingMore.value)
              SizedBox(
                height: MediaQuery.of(context).size.height * 0.45,
                child: const Center(
                  child: CircularProgressIndicator(),
                ),
              )
            else
              _buildLogsContent(),

            // Show loading more indicator
            if (logsController.isLoadingMore.value)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 16.0),
                child: Center(
                  child: SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                    ),
                  ),
                ),
              ),
          ],
        ),
      );
    });
  }

  Widget _buildLogsContent() {
    if (selectedFilter == null || selectedFilter == 'Faults') {
      return FaultsListWidget(faults: logsController.motorFaultsList);
    } else if (selectedFilter == 'Alerts') {
      return AlertsListWidget(alerts: logsController.motorAlertsList);
    } else if (_isPumpFilter(selectedFilter!)) {
      final logs = logsController.motorLogsList;
      return PumpLogsListWidget(logs: logs, filterType: selectedFilter!);
    }
    return const EmptyLogsWidget(message: 'No logs available');
  }

  bool _isPumpFilter(String filter) {
    return filter == 'ON' || filter == 'OFF' || filter == 'MODE';
  }

  Widget _buildPumpsMenuItemWithSubmenu(BuildContext context) {
    bool isPumpSelected =
        selectedFilter != null && _isPumpFilter(selectedFilter!);

    return PopupMenuButton<String>(
      offset: const Offset(-120, 0),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      onSelected: (value) {
        setState(() {
          if (selectedFilter == value) {
            selectedFilter = 'Faults';
            logsController.currentFilter.value = 'Faults';
            logsController.resetPagination();
            logsController.fetchMotorFaults();
          } else {
            selectedFilter = value;
            logsController.currentFilter.value = value;
            logsController.resetPagination();
            logsController.fetchMotorLogs(value);
          }
        });
        Navigator.of(context).pop();
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Row(
          children: [
            Container(
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                color: isPumpSelected
                    ? const Color(0xFF3B82F6)
                    : Colors.transparent,
                border: Border.all(
                  color: isPumpSelected
                      ? const Color(0xFF3B82F6)
                      : const Color(0xFFD1D5DB),
                  width: 2,
                ),
                borderRadius: BorderRadius.circular(4),
              ),
              child: isPumpSelected
                  ? const Icon(
                      Icons.check,
                      size: 14,
                      color: Colors.white,
                    )
                  : null,
            ),
            const SizedBox(width: 12),
            Text(
              'Pump',
              style: GoogleFonts.dmSans(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: isPumpSelected
                    ? const Color(0xFF3B82F6)
                    : const Color(0xFF1F2937),
              ),
            ),
          ],
        ),
      ),
      itemBuilder: (context) => [
        _buildPumpMenuItem('ON', selectedFilter == 'ON'),
        _buildPumpMenuItem('OFF', selectedFilter == 'OFF'),
        _buildPumpMenuItem('MODE', selectedFilter == 'MODE'),
      ],
    );
  }

  Widget _buildSelectedFilterInlineChip(
    String label,
    Color color,
    VoidCallback? onRemove,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: color.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: GoogleFonts.dmSans(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: color,
            ),
          ),
          if (onRemove != null) ...[
            const SizedBox(width: 8),
            GestureDetector(
              onTap: onRemove,
              child: Icon(
                Icons.close,
                size: 16,
                color: color,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Color _getFilterColor(String filter) {
    switch (filter) {
      case 'Faults':
        return const Color(0xFFEF4444);
      case 'Alerts':
        return const Color(0xFFF59E0B);
      case 'ON':
        return const Color(0xFF10B981);
      case 'OFF':
        return const Color(0xFFEF4444);
      case 'MODE':
        return const Color(0xFF8B5CF6);
      default:
        return const Color(0xFF6B7280);
    }
  }

  PopupMenuItem<String> _buildMainMenuItem(String value, bool isSelected) {
    return PopupMenuItem<String>(
      value: value,
      height: 36,
      padding: const EdgeInsets.symmetric(horizontal: 12.0),
      child: Row(children: [
        Container(
          width: 20,
          height: 20,
          decoration: BoxDecoration(
            color: isSelected ? _getFilterColor(value) : Colors.transparent,
            border: Border.all(
              color:
                  isSelected ? _getFilterColor(value) : const Color(0xFFD1D5DB),
              width: 2,
            ),
            borderRadius: BorderRadius.circular(4),
          ),
          child: isSelected
              ? const Icon(
                  Icons.check,
                  size: 14,
                  color: Colors.white,
                )
              : null,
        ),
        const SizedBox(width: 12),
        Text(
          value,
          style: GoogleFonts.dmSans(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color:
                isSelected ? _getFilterColor(value) : const Color(0xFF1F2937),
          ),
        ),
      ]),
    );
  }

  PopupMenuItem<String> _buildPumpMenuItem(String value, bool isSelected) {
    return PopupMenuItem<String>(
      value: value,
      height: 36,
      padding: const EdgeInsets.symmetric(horizontal: 12.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            value,
            style: GoogleFonts.dmSans(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color:
                  isSelected ? _getFilterColor(value) : const Color(0xFF1F2937),
            ),
          ),
          if (isSelected)
            Icon(
              Icons.check,
              size: 18,
              color: _getFilterColor(value),
            ),
        ],
      ),
    );
  }
}
