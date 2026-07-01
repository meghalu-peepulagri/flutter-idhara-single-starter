import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:i_dhara/app/data/models/schedules/schedule_list_model.dart';
import 'package:i_dhara/app/presentation/modules/schedules/schedule_dialogs.dart';
import 'package:intl/intl.dart';

class ScheduleCard extends StatelessWidget {
  final Record record;
  final Future<bool> Function(Record record)? onDelete;
  final Future<bool> Function(Record record, bool enabled)? onToggle;
  final void Function(Record record)? onEdit;
  // Fires when the user taps anywhere on the card surface that's NOT
  // an action pill / checkbox. Used by the manage page + motor schedule
  // tab to open the per-schedule logs bottom sheet. Null disables the
  // card-level tap entirely.
  final void Function(Record record)? onTap;
  // Triggered for PENDING rows when the user taps Resync to republish
  // the schedule to the device over MQTT. Wired by the manage page;
  // per-motor tabs can leave this null to hide the button. Returns
  // true once the device ACKs so the confirm dialog can close itself.
  final Future<bool> Function(Record record)? onSync;
  final Widget? leading;
  final bool showEditAction;
  final bool showDeleteAction;
  final bool showSyncAction;
  // Mirrors the show* flags but renders the pill as inactive instead
  // of hiding it. The manage page flips these on while bulk-select is
  // active so the user can still see the per-card actions but can't
  // accidentally fire one alongside the pending bulk action.
  final bool disableEditAction;
  final bool disableDeleteAction;
  final bool disableSyncAction;
  final bool disableToggle;
  final void Function(Record record)? onCancelAction;
  // Cancel handler specific to the Resync action. Routed to a callback
  // that stops the T:23 (republish) MQTT retry loop, whereas
  // `onCancelAction` stops T:24 (stop / restart / delete) retries.
  // Falls back to `onCancelAction` when null so callers that haven't
  // wired this yet still behave like before.
  final void Function(Record record)? onCancelSync;
  // Optional date label rendered inside the card above the time row.
  // Used by the manage page to show each record's per-date date string
  // ("14 May 2026"). Motor schedule tab passes null since its list is
  // already grouped under a date selector.
  final String? dateLabel;
  // STOPPED rows expose Restart only when the window is still in the
  // future — past stopped rows are read-only (Edit / Delete only).
  // Parent computes this against the record's date.
  final bool isFutureSchedule;
  // True when this PENDING row sits in a future date window that is still
  // locked behind earlier, not-yet-completed dates. The device only holds a
  // rolling 3-day window, so dates beyond it can't be synced until the
  // earlier ones finish. While locked the card shows an advisory note and
  // hides the Resync action. Parent computes this against the schedule list
  // (an earlier date that isn't COMPLETED ⇒ this later date is locked).
  final bool isResyncLocked;
  const ScheduleCard(
      {super.key,
      required this.record,
      this.onDelete,
      this.onToggle,
      this.onEdit,
      this.onTap,
      this.onSync,
      this.leading,
      this.showEditAction = true,
      this.showDeleteAction = true,
      this.showSyncAction = true,
      this.disableEditAction = false,
      this.disableDeleteAction = false,
      this.disableSyncAction = false,
      this.disableToggle = false,
      this.onCancelAction,
      this.onCancelSync,
      this.dateLabel,
      this.isFutureSchedule = true,
      this.isResyncLocked = false});

  @override
  Widget build(BuildContext context) {
    final startTime = record.startTime ?? '--:--';
    final endTime = record.endTime ?? '--:--';
    final durationMin = record.runtimeMinutes ?? 0;
    final dH = durationMin ~/ 60;
    final dM = durationMin % 60;
    final status = record.scheduleStatus ?? 'unknown';

    final isActive = record.enabled ?? false;

    final normalizedStatus = status.toLowerCase();
    final isPending = normalizedStatus == 'pending';
    final isScheduled = normalizedStatus == 'scheduled';
    final isRunning = normalizedStatus == 'running';
    final isPartial = normalizedStatus == 'partial';
    final isMissed = normalizedStatus == 'missed';
    final isStopped = normalizedStatus == 'stopped';
    final isCompleted = normalizedStatus == 'completed';
    final isFailed = normalizedStatus == 'failed';
    // Per-status action eligibility:
    //   PENDING   → Sync, Delete (advisory note)
    //   SCHEDULED → Stop (toggle), Edit, Delete
    //   RUNNING   → Stop (toggle) only
    //   STOPPED   → Restart (toggle, only if future), Edit, Delete
    //   PARTIAL   → no actions (act window still shown if present)
    //   COMPLETED → no actions (act window still shown if present)
    //   MISSED    → no actions, advisory note only
    //   FAILED    → Delete only, advisory note
    // Status eligibility only. `disableToggle` (selection mode) no longer
    // hides the Stop/Restart button — it renders it dimmed + non-tappable
    // (handled where the button is built below).
    final toggleDisabled =
        !(isScheduled || isRunning || (isStopped && isFutureSchedule));
    final editDisabled = !(isScheduled || isStopped);
    final deleteDisabled = !(isPending || isScheduled || isStopped || isFailed);

    // Advisory note shown below the time row for statuses that need to
    // explain why nothing is happening on the device side.
    String? noticeMessage;
    IconData? noticeIcon = Icons.info_outline;
    Color noticeBg = const Color(0xFFF3F4F6);
    Color noticeFg = const Color(0xFF374151);
    if (isPending && isResyncLocked) {
      // Future window still locked behind earlier dates that haven't
      // completed yet — the device only holds a rolling 3-day window.
      noticeMessage = 'Sync the previous dates before this one.';
      noticeIcon = null;
      noticeBg = const Color(0xFFF1F5F9); // slate-100
      noticeFg = const Color(0xFF475569); // slate-600
    } else if (isPending) {
      noticeMessage = 'Not yet synced to device · tap Resync to send';
      noticeBg = const Color(0xFFFFF7ED);
      noticeFg = const Color(0xFFC2410C);
    } else if (isMissed) {
      noticeMessage =
          'Schedule didn\'t reach the device in time — it was missed';
      noticeBg = const Color(0xFFFEF3C7);
      noticeFg = const Color(0xFFB45309);
    } else if (isFailed) {
      noticeMessage = 'Not synced to device';
      noticeBg = const Color(0xFFFFE4E6);
      noticeFg = const Color(0xFFBE123C);
    } else if (record.deviceScheduleStatus == 0) {
      noticeMessage = 'Schedule window expired';
      noticeBg = const Color(0xFFF1F5F9);
      noticeFg = const Color(0xFF475569);
    }

    final isCyclic = record.scheduleType == ScheduleType.CYCLIC;
    final onMin = isCyclic ? (record.cycleOnMinutes as num?)?.toInt() ?? 0 : 0;
    final offMin =
        isCyclic ? (record.cycleOffMinutes as num?)?.toInt() ?? 0 : 0;
    // Act window / run time only make sense once the device has
    // actually interacted with the schedule — running, stopped
    // mid-run, partial, or completed. Pending / scheduled / missed /
    // failed never carry act data.
    final canHaveActual = isRunning || isPartial || isCompleted || isStopped;
    final actualRunMin = record.actualRunTime ?? 0;
    final showRunTime = canHaveActual && actualRunMin > 0;
    // ── "Act" actual-window display commented out per requirement. The
    // logic is preserved (just disabled) so it can be re-enabled later. ──
    // End may still be null while the schedule is running — render an
    // em dash for it.
    // final actualStartRaw = record.actualStartTime?.trim() ?? '';
    // final actualEndRaw = record.actualEndTime?.trim() ?? '';
    // final showActualWindow = canHaveActual && actualStartRaw.isNotEmpty;

    // Overnight schedules span two dates (start_date != end_date) — show the
    // date range ("16-17 Jun") on the card. Same-day rows fall back to the
    // single-date label the parent passed (dateLabel), unchanged.
    final overnightRange = _overnightDateRange();
    final dateText = overnightRange ??
        ((dateLabel != null && dateLabel!.isNotEmpty) ? dateLabel : null);

    final cardBorder =
        isActive ? const Color(0xFFE0E8F0) : const Color(0xFFE8E8E8);
    final timeIconColor =
        isActive ? const Color(0xFF004E7E) : const Color(0xFF9E9E9E);
    const timeTextColor = Color(0XFF1A1A2E);
    const infoBoxBg = Color(0xFFF8FAFC);

    // Status-colored left rail. Every status that has a defined tone
    // gets its own rail color so the user can scan the card list and
    // read status at a glance:
    //   • PENDING                       → orange
    //   • SCHEDULED                     → blue
    //   • RUNNING                       → green
    //   • PARTIAL                       → yellow
    //   • COMPLETED                     → grey
    //   • STOPPED / MISSED / FAILED     → red
    Color? alertRailColor;
    if (isPending) {
      alertRailColor = const Color(0xFFF97316); // orange-500
    } else if (isScheduled) {
      alertRailColor = const Color(0xFF3B82F6); // blue-500
    } else if (isRunning) {
      alertRailColor = const Color(0xFF22C55E); // green-500
    } else if (isPartial) {
      alertRailColor = const Color(0xFFFACC15); // yellow-400
    } else if (isStopped || isMissed || isFailed) {
      alertRailColor = const Color(0xFFEF4444); // red-500
    } else if (isCompleted) {
      alertRailColor = const Color(0xFF9CA3AF); // gray-400
    }

    final cardBody = Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: cardBorder),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Row 1: Time range + status
          Row(
            children: [
              if (leading != null) ...[
                leading!,
                const SizedBox(width: 2),
              ],
              Icon(Icons.schedule_rounded, size: 16, color: timeIconColor),
              const SizedBox(width: 6),
              Expanded(
                child: Row(
                  children: [
                    // Time keeps its full intrinsic width — no Flexible/
                    // ellipsis on it, since the user always needs to read
                    // the exact start → end window. Date takes the
                    // leftover space and truncates instead if the row is
                    // narrow.
                    Text(
                      '${_formatTo12h(startTime)} → ${_formatTo12h(endTime)}',
                      style: GoogleFonts.dmSans(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: timeTextColor,
                      ),
                    ),
                    if (dateText != null && dateText.isNotEmpty) ...[
                      const SizedBox(width: 8),
                      Container(
                        width: 3,
                        height: 3,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: Color(0xFF94A3B8),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Flexible(
                        child: Text(
                          dateText,
                          style: GoogleFonts.dmSans(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: const Color(0xFF64748B),
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              if (record.powerLossRecovery == true) ...[
                const _BlinkingPowerIcon(),
                const SizedBox(width: 6),
              ],
              _statusDot(status, isActive),
            ],
          ),

          // ── "Act" actual-window row commented out per requirement ──
          // if (showActualWindow) ...[
          //   const SizedBox(height: 4),
          //   Padding(
          //     // Indent under the schedule icon so the "Act" row reads as a
          //     // sub-detail of the planned time range above it.
          //     padding: const EdgeInsets.only(left: 22),
          //     child: Row(
          //       children: [
          //         Container(
          //           padding:
          //               const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
          //           decoration: BoxDecoration(
          //             color: const Color(0xFFEBF3FE),
          //             borderRadius: BorderRadius.circular(4),
          //           ),
          //           child: Text(
          //             'Act',
          //             style: GoogleFonts.dmSans(
          //               fontSize: 10,
          //               fontWeight: FontWeight.w700,
          //               color: const Color(0xFF004E7E),
          //               height: 1.2,
          //             ),
          //           ),
          //         ),
          //         const SizedBox(width: 6),
          //         Text(
          //           '${_formatTo12h(actualStartRaw)} → ${actualEndRaw.isEmpty ? '—' : _formatTo12h(actualEndRaw)}',
          //           style: GoogleFonts.dmSans(
          //             fontSize: 12,
          //             fontWeight: FontWeight.w500,
          //             color: const Color(0xFF475569),
          //           ),
          //         ),
          //       ],
          //     ),
          //   ),
          // ],

          Padding(
            padding: const EdgeInsets.symmetric(vertical: 10),
            child: isCyclic
                ? _buildCyclicInfo(dH, dM, durationMin, onMin, offMin,
                    showRunTime, actualRunMin, infoBoxBg)
                : _buildTimeBasedInfo(
                    dH, dM, showRunTime, actualRunMin, infoBoxBg),
          ),
          if (noticeMessage != null) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: noticeBg,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Row(
                children: [
                  if (noticeIcon != null) ...[
                    Icon(noticeIcon, size: 14, color: noticeFg),
                    const SizedBox(width: 6),
                  ],
                  Expanded(
                    child: Text(
                      noticeMessage,
                      style: GoogleFonts.dmSans(
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        color: noticeFg,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
          ],
          // Visibility flags: a button is rendered only when it's enabled
          // for this record's current status. Disabled actions are
          // hidden rather than greyed out so the card surface stays
          // clean — e.g. a FAILED row shows only the Delete button (so
          // the user can clean it up); a PENDING row shows no actions
          // at all until the device ACK lands.
          () {
            final showToggle = !toggleDisabled;
            final showEdit = showEditAction && !editDisabled;
            final showDelete = showDeleteAction && !deleteDisabled;
            final showSync = showSyncAction && isPending && onSync != null;
            if (!showToggle && !showEdit && !showDelete && !showSync) {
              return const SizedBox.shrink();
            }
            // Absorb taps that land on the action row (or the empty
            // space around its pills) so the outer card-level `onTap`
            // doesn't fire — otherwise tapping just outside an Edit /
            // Delete / Resync pill would pop the logs sheet while the
            // user was reaching for an action.
            return GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () {},
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Divider(
                      height: 0, thickness: 1.0, color: Color(0xFFECECEC)),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      // Stop / Restart is the primary status action for
                      // SCHEDULED / RUNNING / STOPPED rows, so it's
                      // rendered as a filled button (solid bg, white
                      // text + icon, ripple on tap) rather than a soft
                      // pastel pill — the secondary actions (Edit /
                      // Delete / Resync) stay as pastel pills further
                      // right. That visual hierarchy is what makes the
                      // button read as actionable; users were asking
                      // "is this clickable?" on the previous pastel
                      // version. Same dialog flow, same onToggle, same
                      // status eligibility — only the widget changed.
                      if (showToggle) ...[
                        // In selection mode (disableToggle) the button is
                        // dimmed and non-tappable, matching the Edit / Delete /
                        // Resync pills, so a bulk pick can't fire a per-row
                        // Stop / Restart by accident.
                        Opacity(
                          opacity: disableToggle ? 0.4 : 1.0,
                          child: Material(
                          color: isActive
                              ? const Color(0xFFEA580C) // orange-600 Stop
                              : const Color(0xFF059669), // emerald-600 Restart
                          borderRadius: BorderRadius.circular(8),
                          clipBehavior: Clip.antiAlias,
                          child: InkWell(
                            onTap: disableToggle
                                ? null
                                : () async {
                              final newValue = !isActive;
                              await showScheduleActionConfirmDialog(
                                context: context,
                                title: newValue
                                    ? 'Restart Schedule'
                                    : 'Stop Schedule',
                                description: newValue
                                    ? 'Are you sure you want to restart this schedule?'
                                    : 'Are you sure you want to stop this schedule?',
                                iconAssetPath: 'assets/images/schedule.svg',
                                buttonLabel: newValue ? 'Restart' : 'Stop',
                                isActive: newValue,
                                onConfirm: () async =>
                                    await onToggle?.call(record, newValue) ??
                                    false,
                                onCancelWhileWaiting: () =>
                                    onCancelAction?.call(record),
                              );
                            },
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    isActive
                                        ? Icons.stop_circle_outlined
                                        : Icons.play_circle_outline_rounded,
                                    size: 14,
                                    color: Colors.white,
                                  ),
                                  const SizedBox(width: 5),
                                  Text(
                                    isActive ? 'Stop' : 'Restart',
                                    style: GoogleFonts.dmSans(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.white,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        ),
                      ],
                      const Spacer(),
                      if (showSync)
                        _ActionPill(
                          icon: Icons.refresh_rounded,
                          label: 'Resync',
                          bg: const Color(0xFFFFF7ED),
                          fg: const Color(0xFFC2410C),
                          // Locked future dates show the pill greyed out and
                          // non-tappable until the earlier window completes.
                          disabled: disableSyncAction || isResyncLocked,
                          onTap: () async {
                            await showScheduleActionConfirmDialog(
                              context: context,
                              title: 'Resync Schedule',
                              description:
                                  'Republish this pending schedule to the device?',
                              iconAssetPath: 'assets/images/schedule.svg',
                              buttonLabel: 'Resync',
                              isActive: true,
                              // Resync goes through the backend's
                              // bulk/republish API (server owns the device
                              // publish + ACK), so the dialog just awaits the
                              // call — no 23s "waiting for device" MQTT timer.
                              skipDeviceAck: true,
                              onConfirm: () async =>
                                  await onSync?.call(record) ?? false,
                              // Resync uses a dedicated cancel handler so
                              // the T:23 republish retry loop is what
                              // gets cancelled, not the T:24 action loop
                              // that the Stop/Restart/Delete pills use.
                              onCancelWhileWaiting: () =>
                                  (onCancelSync ?? onCancelAction)
                                      ?.call(record),
                            );
                          },
                        ),
                      if (showSync && (showEdit || showDelete))
                        const SizedBox(width: 8),
                      if (showEdit)
                        _ActionPill(
                          icon: Icons.edit_outlined,
                          label: 'Edit',
                          bg: const Color(0xFFEBF3FE),
                          fg: const Color(0xFF004E7E),
                          disabled: disableEditAction,
                          onTap: () => onEdit?.call(record),
                        ),
                      if (showEdit && showDelete) const SizedBox(width: 8),
                      if (showDelete)
                        _ActionPill(
                          icon: Icons.delete_outline_rounded,
                          label: 'Delete',
                          bg: const Color(0xFFFFEBEE),
                          fg: const Color(0xFFE53935),
                          disabled: disableDeleteAction,
                          onTap: () async {
                            await showScheduleActionConfirmDialog(
                              context: context,
                              title: 'Delete Schedule',
                              description:
                                  'This schedule will be deleted permanently. Do you wish to go ahead?',
                              iconAssetPath: 'assets/images/schedule.svg',
                              buttonLabel: 'Delete',
                              // PENDING / FAILED rows never reached the
                              // device, so the delete is a pure backend
                              // call — no MQTT, no 23s elapsed counter.
                              skipDeviceAck: isPending || isFailed,
                              onConfirm: () async =>
                                  await onDelete?.call(record) ?? false,
                              onCancelWhileWaiting: () =>
                                  onCancelAction?.call(record),
                            );
                          },
                        ),
                    ],
                  ),
                ],
              ),
            );
          }(),
        ],
      ),
    );

    // Wrap the body in an InkWell only when a card-level tap handler
    // is provided. Inner taps on action pills / checkbox still win
    // because Flutter's gesture arena picks the deepest handler — the
    // outer InkWell only fires for taps on inert surface area.
    Widget content = cardBody;
    if (onTap != null) {
      content = Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () => onTap!(record),
          child: cardBody,
        ),
      );
    }

    if (alertRailColor == null) return content;
    // Overlay the colored rail on the left edge. Clipping the whole
    // Stack to the card's rounded shape makes the rail follow the
    // card's curve at the top-left and bottom-left corners — without
    // this the rail's straight right edge cuts a 90° step across the
    // card's rounded corner region. The shadow is moved to an outer
    // DecoratedBox so ClipRRect doesn't trim it.
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Stack(
          children: [
            content,
            Positioned(
              left: 0,
              top: 0,
              bottom: 0,
              child: Container(width: 5, color: alertRailColor),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTimeBasedInfo(
      int dH, int dM, bool showRunTime, int actualRunMin, Color bg) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: const BorderRadius.all(Radius.circular(8)),
      ),
      child: Row(
        children: [
          _infoItem('Duration', '${dH}h ${dM.toString().padLeft(2, '0')}m'),
          if (showRunTime) ...[
            const SizedBox(width: 12),
            _infoItem('Run Time', _formatRunTime(actualRunMin)),
          ],
        ],
      ),
    );
  }

  Widget _buildCyclicInfo(int dH, int dM, int durationMin, int onMin,
      int offMin, bool showRunTime, int actualRunMin, Color bg) {
    final cycles = onMin > 0 ? actualRunMin ~/ onMin : 0;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Duration + Run Time in one decoration
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(8),
            // border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: Row(
            children: [
              _infoItem('Duration', '${dH}h ${dM.toString().padLeft(2, '0')}m'),
              if (showRunTime) ...[
                const SizedBox(width: 12),
                _infoItem(
                    'Run Time',
                    cycles > 0
                        ? '${_formatRunTime(actualRunMin)} · $cycles ${cycles == 1 ? 'cycle' : 'cycles'}'
                        : _formatRunTime(actualRunMin)),
              ],
            ],
          ),
        ),
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: const Color(0xFFFFF8F0),
            borderRadius: BorderRadius.circular(8),
            // border: Border.all(color: const Color(0xFFFFE0B2)),
          ),
          child: IntrinsicHeight(
            child: Row(
              children: [
                // ON side
                Expanded(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text('ON',
                          style: GoogleFonts.dmSans(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFF34C759))),
                      const SizedBox(width: 4),
                      Text('$onMin min',
                          style: GoogleFonts.dmSans(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFF34C759))),
                    ],
                  ),
                ),
                // Center vertical divider
                const VerticalDivider(
                    width: 1, thickness: 1, color: Color(0xFFFFE0B2)),
                // OFF side
                Expanded(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text('OFF',
                          style: GoogleFonts.dmSans(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFFEF4444))),
                      const SizedBox(width: 4),
                      Text('$offMin min',
                          style: GoogleFonts.dmSans(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFFEF4444))),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _infoItem(String label, String value) {
    return RichText(
      text: TextSpan(
        children: [
          TextSpan(
            text: '$label : ',
            style: GoogleFonts.dmSans(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: const Color(0xFF94A3B8),
            ),
          ),
          TextSpan(
            text: value,
            style: GoogleFonts.dmSans(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF1A1A2E),
            ),
          ),
        ],
      ),
    );
  }

  Widget _statusDot(String status, bool isActive) {
    // Tailwind-aligned palette: (badge bg, text, dot). Each status uses
    // a distinct hue with three shades — light bg, dark-700 text, mid
    // dot — for legibility against the white card.
    final (Color bg, Color fg, Color dot) = switch (status.toLowerCase()) {
      'running' => (
          const Color(0xFFDCFCE7), // green-100
          const Color(0xFF15803D), // green-700
          const Color(0xFF22C55E), // green-500
        ),
      'scheduled' => (
          const Color(0xFFDBEAFE), // blue-100
          const Color(0xFF1D4ED8), // blue-700
          const Color(0xFF3B82F6), // blue-500
        ),
      'pending' => (
          const Color(0xFFFFEDD5), // orange-100
          const Color(0xFFC2410C), // orange-700
          const Color(0xFFF97316), // orange-500
        ),
      'stopped' => (
          const Color(0xFFFEE2E2), // red-100
          const Color(0xFFB91C1C), // red-700
          const Color(0xFFEF4444), // red-500
        ),
      'completed' => (
          const Color(0xFFF3F4F6), // gray-100
          const Color(0xFF374151), // gray-700
          const Color(0xFF9CA3AF), // gray-400
        ),
      'missed' => (
          const Color(0xFFFEF3C7), // amber-100
          const Color(0xFFB45309), // amber-700
          const Color(0xFFF59E0B), // amber-500
        ),
      'partial' => (
          const Color(0xFFFEF9C3), // yellow-100
          const Color(0xFFA16207), // yellow-700
          const Color(0xFFFACC15), // yellow-400
        ),
      'failed' => (
          const Color(0xFFFFE4E6), // rose-100
          const Color(0xFFBE123C), // rose-700
          const Color(0xFFE11D48), // rose-600
        ),
      // Unknown status → fall back to neutral / active-aware grey-green.
      _ => isActive
          ? (
              const Color(0xFFDCFCE7),
              const Color(0xFF15803D),
              const Color(0xFF22C55E),
            )
          : (
              const Color(0xFFF3F4F6),
              const Color(0xFF6B7280),
              const Color(0xFF9CA3AF),
            ),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(shape: BoxShape.circle, color: dot),
          ),
          const SizedBox(width: 4),
          Text(
            status.toLowerCase() == 'completed'
                ? 'ENDED'
                : _capitalize(status),
            style: GoogleFonts.dmSans(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: fg,
            ),
          ),
        ],
      ),
    );
  }

  String _formatTo12h(String raw) {
    String h, m;
    if (raw.contains(':')) {
      final parts = raw.split(':');
      if (parts.length < 2) return raw;
      h = parts[0].padLeft(2, '0');
      m = parts[1].length >= 2
          ? parts[1].substring(0, 2)
          : parts[1].padLeft(2, '0');
    } else if (raw.length >= 3) {
      m = raw.substring(raw.length - 2);
      h = raw.substring(0, raw.length - 2).padLeft(2, '0');
    } else {
      return raw;
    }
    return '$h:$m';
  }

  String _capitalize(String s) =>
      s.isEmpty ? s : '${s[0].toUpperCase()}${s.substring(1)}';

  /// For overnight schedules (schedule_start_date != schedule_end_date)
  /// returns a compact date range like "16-17 Jun" (or "30 Jun - 1 Jul"
  /// across months). Same-day schedules return null so the single-date
  /// [dateLabel] passed by the parent is used instead.
  String? _overnightDateRange() {
    final s = record.scheduleStartDate;
    final e = record.scheduleEndDate;
    if (s == null || e == null || s <= 0 || e <= 0 || s == e) return null;
    DateTime? toDate(int v) {
      final yy = v ~/ 10000;
      final mm = (v % 10000) ~/ 100;
      final dd = v % 100;
      if (mm < 1 || mm > 12 || dd < 1 || dd > 31) return null;
      return DateTime(2000 + yy, mm, dd);
    }

    final sd = toDate(s);
    final ed = toDate(e);
    if (sd == null || ed == null) return null;
    if (sd.year == ed.year && sd.month == ed.month) {
      return '${sd.day}-${ed.day} ${DateFormat('MMM').format(sd)}';
    }
    return '${DateFormat('d MMM').format(sd)} - ${DateFormat('d MMM').format(ed)}';
  }

  /// Renders [actual_run_time] (in minutes) as either `13m` (under an hour)
  /// or `1h 13m` (one hour or more) so short runs read naturally without a
  /// noisy `0h` prefix.
  String _formatRunTime(int totalMinutes) {
    if (totalMinutes < 60) return '${totalMinutes}m';
    final h = totalMinutes ~/ 60;
    final m = totalMinutes % 60;
    return '${h}h ${m.toString().padLeft(2, '0')}m';
  }
}

class _ActionPill extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color bg;
  final Color fg;
  final VoidCallback onTap;
  // Selection mode in the manage page wants these pills visible but
  // inactive, so we dim them and skip the tap callback rather than
  // hiding the chip entirely.
  final bool disabled;

  const _ActionPill({
    required this.icon,
    required this.label,
    required this.bg,
    required this.fg,
    required this.onTap,
    this.disabled = false,
  });

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: disabled ? 0.4 : 1.0,
      child: InkWell(
        borderRadius: BorderRadius.circular(6),
        onTap: disabled ? null : onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(6),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 14, color: fg),
              const SizedBox(width: 4),
              Text(
                label,
                style: GoogleFonts.dmSans(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: fg,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BlinkingPowerIcon extends StatefulWidget {
  const _BlinkingPowerIcon();

  @override
  State<_BlinkingPowerIcon> createState() => _BlinkingPowerIconState();
}

class _BlinkingPowerIconState extends State<_BlinkingPowerIcon>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _opacity;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..repeat(reverse: true);
    _opacity = Tween<double>(begin: 0.6, end: 1.0).animate(
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
    return FadeTransition(
      opacity: _opacity,
      child: SvgPicture.asset(
        'assets/images/power.svg',
        width: 16,
        height: 16,
        colorFilter: const ColorFilter.mode(
          Color(0xFFFF9800),
          BlendMode.srcIn,
        ),
      ),
    );
  }
}
