import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:google_fonts/google_fonts.dart';

// 23s is still the controller-side ACK deadline (10 + 10 + 3 retry
// budget), so the elapsed-clamp callers below still need it even
// though the dialog no longer renders the countdown.
const int _kAckTotalSeconds = 23;

// Used to drive the ring + countdown + "Attempt X of 3" UI. Removed
// per request — the waiting view is now just a centered spinner.
// The view keeps the "Waiting for response..." caption so the user
// still has context for what's happening; only the timer and attempt
// breadcrumb are gone.
Widget _scheduleAckWaitingView() {
  return Column(
    mainAxisSize: MainAxisSize.min,
    children: const [
      SizedBox(
        width: 40,
        height: 40,
        child: CircularProgressIndicator(
          strokeWidth: 3.5,
          valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF004E7E)),
        ),
      ),
      SizedBox(height: 12),
      _WaitingForAckText(),
    ],
  );
}

Widget _scheduleInlineErrorBanner(String message, {VoidCallback? onClose}) {
  return Container(
    width: double.infinity,
    padding: EdgeInsets.fromLTRB(12, 10, onClose != null ? 6 : 12, 10),
    decoration: BoxDecoration(
      color: const Color(0xFFFFEBEE),
      borderRadius: BorderRadius.circular(8),
      border: Border.all(
        color: const Color(0xFFE53935).withValues(alpha: 0.4),
      ),
    ),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Icon(Icons.error_outline_rounded,
            size: 18, color: Color(0xFFE53935)),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            message,
            style: GoogleFonts.dmSans(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: const Color(0xFFB71C1C),
              height: 1.4,
            ),
          ),
        ),
        if (onClose != null) ...[
          const SizedBox(width: 4),
          InkWell(
            borderRadius: BorderRadius.circular(6),
            onTap: onClose,
            child: Padding(
              padding: const EdgeInsets.all(4),
              child: Icon(
                Icons.close_rounded,
                size: 16,
                color: const Color(0xFFE53935).withValues(alpha: 0.85),
              ),
            ),
          ),
        ],
      ],
    ),
  );
}

Widget _scheduleAckFailedView() {
  return Column(
    mainAxisSize: MainAxisSize.min,
    children: [
      Container(
        width: 64,
        height: 64,
        decoration: const BoxDecoration(
          color: Color(0xFFFFEBEE),
          shape: BoxShape.circle,
        ),
        child: const Icon(
          Icons.error_outline_rounded,
          size: 32,
          color: Color(0xFFE53935),
        ),
      ),
      const SizedBox(height: 10),
      Text(
        'Not responding from device',
        textAlign: TextAlign.center,
        style: GoogleFonts.dmSans(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: const Color(0xFF14181B),
        ),
      ),
      const SizedBox(height: 4),
      Text(
        'Tap Retry to send again',
        textAlign: TextAlign.center,
        style: GoogleFonts.dmSans(
          fontSize: 12,
          color: const Color(0xFF57636C),
        ),
      ),
    ],
  );
}

class _WaitingForAckText extends StatefulWidget {
  const _WaitingForAckText();

  @override
  State<_WaitingForAckText> createState() => _WaitingForAckTextState();
}

class _WaitingForAckTextState extends State<_WaitingForAckText> {
  Timer? _ticker;
  int _dots = 0;

  @override
  void initState() {
    super.initState();
    _ticker = Timer.periodic(const Duration(milliseconds: 400), (_) {
      if (!mounted) return;
      setState(() {
        _dots = (_dots + 1) % 4;
      });
    });
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final baseStyle = GoogleFonts.dmSans(
      fontSize: 13,
      fontWeight: FontWeight.w600,
      color: const Color(0xFF14181B),
    );
    return Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text('Waiting for Device Response', style: baseStyle),
        for (int i = 0; i < 3; i++)
          Text(
            '.',
            style: baseStyle.copyWith(
              color: i < _dots ? baseStyle.color : Colors.transparent,
            ),
          ),
      ],
    );
  }
}

Future<void> showScheduleConfirmDialog({
  required BuildContext context,
  required String typeLabel,
  required String startDate,
  required String endDate,
  required String startTime,
  required String endTime,
  required String duration,
  required String powerRecovery,
  required Future<String?> Function() onConfirm,
  VoidCallback? onCancelWhileWaiting,
  bool isCyclic = false,
  int cyclicOnMinutes = 0,
  int cyclicOffMinutes = 0,
}) {
  return showDialog(
    context: context,
    barrierDismissible: false,
    builder: (ctx) => _ScheduleConfirmDialog(
      typeLabel: typeLabel,
      startDate: startDate,
      endDate: endDate,
      startTime: startTime,
      endTime: endTime,
      duration: duration,
      powerRecovery: powerRecovery,
      onConfirm: onConfirm,
      onCancelWhileWaiting: onCancelWhileWaiting,
      isCyclic: isCyclic,
      cyclicOnMinutes: cyclicOnMinutes,
      cyclicOffMinutes: cyclicOffMinutes,
    ),
  );
}

class _ScheduleConfirmDialog extends StatefulWidget {
  final String typeLabel;
  final String startDate;
  final String endDate;
  final String startTime;
  final String endTime;
  final String duration;
  final String powerRecovery;
  final Future<String?> Function() onConfirm;
  final VoidCallback? onCancelWhileWaiting;
  final bool isCyclic;
  final int cyclicOnMinutes;
  final int cyclicOffMinutes;

  const _ScheduleConfirmDialog({
    required this.typeLabel,
    required this.startDate,
    required this.endDate,
    required this.startTime,
    required this.endTime,
    required this.duration,
    required this.powerRecovery,
    required this.onConfirm,
    this.onCancelWhileWaiting,
    required this.isCyclic,
    required this.cyclicOnMinutes,
    required this.cyclicOffMinutes,
  });

  @override
  State<_ScheduleConfirmDialog> createState() => _ScheduleConfirmDialogState();
}

class _ScheduleConfirmDialogState extends State<_ScheduleConfirmDialog> {
  bool _isWaiting = false;
  // `_isFailed` is retained only so the existing `_scheduleAckFailedView`
  // branch in build() doesn't get reached — ACK failure now closes the
  // dialog immediately via `_onResult`, so this stays `false` for the
  // lifetime of the dialog.
  bool _isFailed = false;
  int _elapsed = 0;
  Timer? _ticker;
  String? _errorMessage;
  bool _closed = false;

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  void _runConfirm() {
    _ticker?.cancel();
    setState(() {
      _isWaiting = true;
      _isFailed = false;
      _errorMessage = null;
      _elapsed = 1;
    });
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      setState(() {
        _elapsed = (_elapsed + 1).clamp(1, _kAckTotalSeconds);
      });
    });
    widget.onConfirm().then(_onResult).catchError((_) => _onResult(''));
  }

  void _onResult(String? error) {
    if (!mounted || _closed) return;
    _ticker?.cancel();
    if (error == null) {
      _close();
      return;
    }
    if (error.isEmpty) {
      // MQTT ACK failed / retry cycle exhausted. The controller has
      // already surfaced the device error via snackbar, so close the
      // dialog immediately and let the user land back on the schedule
      // page instead of staring at a Failed/Retry view with a stuck
      // confirm button.
      _close();
      return;
    }
    // Backend validation error — show inline banner, return to idle.
    setState(() {
      _isWaiting = false;
      _isFailed = false;
      _errorMessage = error;
    });
  }

  void _onConfirmTap() => _runConfirm();

  void _onCancelTap() {
    if (_isWaiting) widget.onCancelWhileWaiting?.call();
    _close();
  }

  void _close() {
    if (_closed) return;
    _closed = true;
    _ticker?.cancel();
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      backgroundColor: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (!_isWaiting && !_isFailed) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: const BoxDecoration(
                  color: Color(0xFFEBF3FE),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.schedule_rounded,
                    size: 32, color: Color(0xFF004E7E)),
              ),
              const SizedBox(height: 16),
              Text(
                'Confirm Schedule',
                style: GoogleFonts.dmSans(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF14181B),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Are you sure you want to create this schedule?',
                textAlign: TextAlign.center,
                style: GoogleFonts.dmSans(
                  fontSize: 13,
                  color: const Color(0xFF57636C),
                ),
              ),
              if (_errorMessage != null) ...[
                const SizedBox(height: 12),
                _scheduleInlineErrorBanner(
                  _errorMessage!,
                  onClose: () => setState(() => _errorMessage = null),
                ),
              ],
              const SizedBox(height: 16),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: const Color(0xFF004E7E).withValues(alpha: 0.15),
                  ),
                ),
                child: Column(
                  children: [
                    _dialogRow('Type', widget.typeLabel),
                    const SizedBox(height: 6),
                    _dialogRow('Start', widget.startTime),
                    const SizedBox(height: 6),
                    _dialogRow('End', widget.endTime),
                    const SizedBox(height: 6),
                    _dialogRow('Duration', widget.duration),
                    if (widget.isCyclic) ...[
                      const SizedBox(height: 6),
                      _dialogRow('Cyclic ON', '${widget.cyclicOnMinutes} min'),
                      const SizedBox(height: 6),
                      _dialogRow(
                          'Cyclic OFF', '${widget.cyclicOffMinutes} min'),
                    ] else ...[
                      // Power Loss Recovery row — commented out per requirement.
                      // const SizedBox(height: 6),
                      // _dialogRow('Power Recovery', widget.powerRecovery),
                    ],
                  ],
                ),
              ),
            ] else ...[
              Text(
                'Confirm Schedule',
                textAlign: TextAlign.center,
                style: GoogleFonts.dmSans(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF14181B),
                ),
              ),
              const SizedBox(height: 12),
              if (_isFailed)
                _scheduleAckFailedView()
              else
                _scheduleAckWaitingView(),
            ],
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: SizedBox(
                    height: 44,
                    child: OutlinedButton(
                      // Cancel disabled while the publish is in
                      // flight — user can only abort before tapping
                      // Confirm. Border + text dim to 30% to signal
                      // the disabled state.
                      onPressed: _isWaiting ? null : _onCancelTap,
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(
                          color: _isWaiting
                              ? const Color(0xFF004E7E).withValues(alpha: 0.3)
                              : const Color(0xFF004E7E),
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: Text(
                        'Cancel',
                        style: GoogleFonts.dmSans(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: _isWaiting
                              ? const Color(0xFF004E7E).withValues(alpha: 0.3)
                              : const Color(0xFF004E7E),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: SizedBox(
                    height: 44,
                    child: ElevatedButton(
                      onPressed: _isWaiting ? null : _onConfirmTap,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF004E7E),
                        disabledBackgroundColor: const Color(0xFF004E7E),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        elevation: 0,
                      ),
                      child: _isWaiting
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                          : Text(
                              'Confirm',
                              style: GoogleFonts.dmSans(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                            ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class MultiScheduleDialogItem {
  final String typeLabel;
  final String startTime;
  final String endTime;
  final String duration;
  final String powerRecovery;
  final bool isCyclic;
  final int cyclicOnMinutes;
  final int cyclicOffMinutes;

  const MultiScheduleDialogItem({
    required this.typeLabel,
    required this.startTime,
    required this.endTime,
    required this.duration,
    required this.powerRecovery,
    this.isCyclic = false,
    this.cyclicOnMinutes = 0,
    this.cyclicOffMinutes = 0,
  });
}

Future<void> showMultiScheduleConfirmDialog({
  required BuildContext context,
  required String startDate,
  required String endDate,
  required List<MultiScheduleDialogItem> schedules,
  required Future<String?> Function() onConfirm,
  VoidCallback? onCancelWhileWaiting,
  List<int>? selectedDays,
  Map<int, int>? dayCounts,
  String? title,
  String? description,
}) {
  const dayLabels = ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];
  final hasDays = selectedDays != null && selectedDays.isNotEmpty;
  final selectedDayEntries = hasDays
      ? [
          for (final i in (List<int>.from(selectedDays)..sort()))
            if (i >= 0 && i < 7)
              (label: dayLabels[i], count: dayCounts?[i] ?? 1),
        ]
      : const <({String label, int count})>[];
  return showDialog(
    context: context,
    barrierDismissible: false,
    builder: (ctx) => _MultiScheduleConfirmDialog(
      startDate: startDate,
      endDate: endDate,
      schedules: schedules,
      onConfirm: onConfirm,
      onCancelWhileWaiting: onCancelWhileWaiting,
      selectedDayEntries: selectedDayEntries,
      title: title,
      description: description,
    ),
  );
}

class _MultiScheduleConfirmDialog extends StatefulWidget {
  final String startDate;
  final String endDate;
  final List<MultiScheduleDialogItem> schedules;
  final Future<String?> Function() onConfirm;
  final VoidCallback? onCancelWhileWaiting;
  final List<({String label, int count})> selectedDayEntries;
  // Optional copy overrides used by the edit-schedule flow.
  final String? title;
  final String? description;

  const _MultiScheduleConfirmDialog({
    required this.startDate,
    required this.endDate,
    required this.schedules,
    required this.onConfirm,
    this.onCancelWhileWaiting,
    required this.selectedDayEntries,
    this.title,
    this.description,
  });

  @override
  State<_MultiScheduleConfirmDialog> createState() =>
      _MultiScheduleConfirmDialogState();
}

class _MultiScheduleConfirmDialogState
    extends State<_MultiScheduleConfirmDialog> {
  // Mirrors _ScheduleConfirmDialog. ACK failure closes the dialog
  // immediately (see _onResult), so `_isFailed` stays `false` for the
  // lifetime of the dialog and the Failed/Retry view is never reached.
  bool _isWaiting = false;
  bool _isFailed = false;
  int _elapsed = 0;
  Timer? _ticker;
  String? _errorMessage;
  bool _closed = false;

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  void _runConfirm() {
    _ticker?.cancel();
    setState(() {
      _isWaiting = true;
      _isFailed = false;
      _errorMessage = null;
      _elapsed = 1;
    });
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      setState(() {
        _elapsed = (_elapsed + 1).clamp(1, _kAckTotalSeconds);
      });
    });
    widget.onConfirm().then(_onResult).catchError((_) => _onResult(''));
  }

  void _onResult(String? error) {
    if (!mounted || _closed) return;
    _ticker?.cancel();
    if (error == null) {
      _close();
      return;
    }
    // Both empty (MQTT retry cycle exhausted with no message) and
    // non-empty errors flip the dialog into the failure view with an
    // OK button. Empty falls back to the standard "No response" copy.
    setState(() {
      _isWaiting = false;
      _isFailed = false;
      _errorMessage =
          error.isEmpty ? 'No response from device. Please try again.' : error;
    });
  }

  void _onConfirmTap() => _runConfirm();

  void _onCancelTap() {
    if (_isWaiting) widget.onCancelWhileWaiting?.call();
    _close();
  }

  void _onOkTap() => _close();

  void _close() {
    if (_closed) return;
    _closed = true;
    _ticker?.cancel();
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      backgroundColor: Colors.white,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
      child: ConstrainedBox(
        // Cap dialog height — shrinks when less content, scrolls when more
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.58,
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  // Failure mode swaps the header into a red error
                  // chip so the user immediately reads the state.
                  color: _errorMessage != null
                      ? Colors.red.shade50
                      : const Color(0xFFEBF3FE),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  _errorMessage != null
                      ? Icons.error_outline_rounded
                      : Icons.schedule_rounded,
                  size: 26,
                  color: _errorMessage != null
                      ? Colors.red[600]
                      : const Color(0xFF004E7E),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                widget.title ?? 'Create Schedules',
                textAlign: TextAlign.center,
                style: GoogleFonts.dmSans(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF14181B),
                ),
              ),
              if (_errorMessage != null) ...[
                const SizedBox(height: 10),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 6),
                  child: Text(
                    _errorMessage!,
                    textAlign: TextAlign.center,
                    style: GoogleFonts.dmSans(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: const Color(0xFF475569),
                      height: 1.4,
                    ),
                  ),
                ),
              ] else if (!_isWaiting && !_isFailed) ...[
                const SizedBox(height: 6),
                Text(
                  widget.description ??
                      'Are you sure you want to create these ${widget.schedules.length} schedule(s)?',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.dmSans(
                    fontSize: 12,
                    color: const Color(0xFF57636C),
                  ),
                ),
                const SizedBox(height: 12),
                // When start == end the record covers a single date —
                // collapse the "Start → End" row into a centred single
                // date pill so the edit-confirm flow doesn't look like
                // a range edit.
                Container(
                  width: double.infinity,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: const Color(0xFF004E7E).withValues(alpha: 0.15),
                    ),
                  ),
                  child: widget.startDate == widget.endDate
                      ? Center(
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.calendar_today_rounded,
                                  size: 13, color: Color(0xFF004E7E)),
                              const SizedBox(width: 8),
                              Text(
                                widget.startDate,
                                style: GoogleFonts.dmSans(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: const Color(0xFF0F172A),
                                ),
                              ),
                            ],
                          ),
                        )
                      : Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(widget.startDate,
                                style: GoogleFonts.dmSans(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: const Color(0xFF0F172A))),
                            const Icon(Icons.arrow_forward_rounded,
                                size: 14, color: Color(0xFF94A3B8)),
                            Text(widget.endDate,
                                style: GoogleFonts.dmSans(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: const Color(0xFF0F172A))),
                          ],
                        ),
                ),
                const SizedBox(height: 10),
                // Flexible: shrinks when few cards, scrolls when many
                Flexible(
                  child: SingleChildScrollView(
                    child: Column(
                      children: [
                        for (int i = 0; i < widget.schedules.length; i++) ...[
                          if (i > 0) const SizedBox(height: 8),
                          _multiScheduleCard(
                            i + 1,
                            widget.schedules[i],
                            dayEntries: widget.selectedDayEntries,
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ] else ...[
                const SizedBox(height: 12),
                if (_isFailed)
                  _scheduleAckFailedView()
                else
                  _scheduleAckWaitingView(),
              ],
              const SizedBox(height: 16),
              if (_errorMessage != null)
                // Failure footer: a single full-width gradient OK
                // button replaces Cancel / Confirm so the user has to
                // explicitly dismiss the error. No Retry — the user
                // can re-open the schedule and try again from the
                // form if they want another attempt.
                SizedBox(
                  height: 44,
                  width: double.infinity,
                  child: Material(
                    color: Colors.transparent,
                    borderRadius: BorderRadius.circular(8),
                    clipBehavior: Clip.antiAlias,
                    child: Ink(
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            Color(0xFF004E7E),
                            Color(0xFF3686AF),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: InkWell(
                        onTap: _closed ? null : _onOkTap,
                        borderRadius: BorderRadius.circular(8),
                        child: Center(
                          child: Text(
                            'OK',
                            style: GoogleFonts.dmSans(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                )
              else
                Row(
                  children: [
                    Expanded(
                      child: SizedBox(
                        height: 44,
                        child: OutlinedButton(
                          // Cancel disabled while the publish is in
                          // flight — same pattern as the first
                          // dialog above.
                          onPressed: _isWaiting ? null : _onCancelTap,
                          style: OutlinedButton.styleFrom(
                            side: BorderSide(
                              color: _isWaiting
                                  ? const Color(0xFF004E7E)
                                      .withValues(alpha: 0.3)
                                  : const Color(0xFF004E7E),
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: Text(
                            'Cancel',
                            style: GoogleFonts.dmSans(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: _isWaiting
                                  ? const Color(0xFF004E7E)
                                      .withValues(alpha: 0.3)
                                  : const Color(0xFF004E7E),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: SizedBox(
                        height: 44,
                        child: ElevatedButton(
                          onPressed: _isWaiting ? null : _onConfirmTap,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF004E7E),
                            disabledBackgroundColor: const Color(0xFF004E7E),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            elevation: 0,
                          ),
                          child: _isWaiting
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2,
                                  ),
                                )
                              : Text(
                                  'Confirm',
                                  style: GoogleFonts.dmSans(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.white,
                                  ),
                                ),
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

Widget _multiScheduleCard(
  int idx,
  MultiScheduleDialogItem s, {
  List<({String label, int count})> dayEntries = const [],
}) {
  final String detail = s.isCyclic
      ? 'Cyclic  ·  ON ${s.cyclicOnMinutes}m / OFF ${s.cyclicOffMinutes}m'
      // Power Loss Recovery suffix — commented out per requirement.
      // : '${s.duration}${s.powerRecovery == 'ON' ? '  ·  Pwr Recovery' : ''}';
      : s.duration;

  return Container(
    width: double.infinity,
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
    decoration: BoxDecoration(
      color: const Color(0xFFF8FAFC),
      borderRadius: BorderRadius.circular(10),
      border: Border.all(
        color: const Color(0xFF004E7E).withValues(alpha: 0.15),
      ),
    ),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // Index badge
        Container(
          width: 24,
          height: 24,
          decoration: const BoxDecoration(
            color: Color(0xFFEBF3FE),
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Text(
              '$idx',
              style: GoogleFonts.dmSans(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF004E7E),
              ),
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${s.startTime}  →  ${s.endTime}',
                style: GoogleFonts.dmSans(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF0F172A),
                ),
              ),
              const SizedBox(height: 2),
              Text(
                detail,
                style: GoogleFonts.dmSans(
                  fontSize: 11,
                  fontWeight: FontWeight.w400,
                  color: const Color(0xFF64748B),
                ),
              ),
            ],
          ),
        ),
        if (dayEntries.isNotEmpty) ...[
          const SizedBox(width: 8),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 130),
            child: Padding(
              padding: const EdgeInsets.only(top: 6, right: 4),
              child: Wrap(
                spacing: 6,
                runSpacing: 8,
                alignment: WrapAlignment.end,
                children: [
                  for (final entry in dayEntries)
                    Stack(
                      clipBehavior: Clip.none,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: const Color(0xFFEBF3FE),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(
                              color: const Color(0xFF3686AF),
                              width: 1,
                            ),
                          ),
                          child: Text(
                            entry.label,
                            style: GoogleFonts.dmSans(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFF004E7E),
                            ),
                          ),
                        ),
                        if (entry.count > 1)
                          Positioned(
                            top: -7,
                            right: -6,
                            child: Container(
                              constraints: const BoxConstraints(minWidth: 14),
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 3, vertical: 1),
                              decoration: BoxDecoration(
                                color: const Color(0xFF004E7E),
                                borderRadius: BorderRadius.circular(8),
                                border:
                                    Border.all(color: Colors.white, width: 1),
                              ),
                              child: Text(
                                '${entry.count}',
                                textAlign: TextAlign.center,
                                style: GoogleFonts.dmSans(
                                  fontSize: 9,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white,
                                  height: 1.0,
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                ],
              ),
            ),
          ),
        ],
      ],
    ),
  );
}

Widget _dialogRow(String label, String value) {
  return Row(
    mainAxisAlignment: MainAxisAlignment.spaceBetween,
    children: [
      Text(label,
          style:
              GoogleFonts.dmSans(fontSize: 12, color: const Color(0xFF57636C))),
      Text(value,
          style: GoogleFonts.dmSans(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF14181B))),
    ],
  );
}

Future<bool> showScheduleActionConfirmDialog({
  required BuildContext context,
  required String title,
  required String description,
  required String iconAssetPath,
  required String buttonLabel,
  required Future<bool> Function() onConfirm,
  VoidCallback? onCancelWhileWaiting,
  bool isActive = false,
  // PENDING / FAILED deletes never publish MQTT, so the 23s elapsed
  // ticker + "Waiting for device" view is misleading. Set this to true
  // for those callers — the dialog keeps the normal confirm body
  // visible and only spins the Delete button while the API runs.
  bool skipDeviceAck = false,
  // Optional builder used to compute the failure message shown in the
  // dialog when `onConfirm` returns false. Lets bulk callers surface
  // partial-result info (e.g. "2 of 3 schedules didn't respond") that
  // the dialog itself can't derive. Return `null` (or throw) to fall
  // back to the generic "No response from device" copy.
  Future<String?> Function()? failureMessageBuilder,
}) async {
  final result = await showDialog<bool>(
    context: context,
    barrierDismissible: false,
    builder: (ctx) => _ScheduleActionConfirmDialog(
      title: title,
      description: description,
      iconAssetPath: iconAssetPath,
      buttonLabel: buttonLabel,
      isActive: isActive,
      onConfirm: onConfirm,
      onCancelWhileWaiting: onCancelWhileWaiting,
      skipDeviceAck: skipDeviceAck,
      failureMessageBuilder: failureMessageBuilder,
    ),
  );
  return result ?? false;
}

class _ScheduleActionConfirmDialog extends StatefulWidget {
  final String title;
  final String description;
  final String iconAssetPath;
  final String buttonLabel;
  final bool isActive;
  final Future<bool> Function() onConfirm;
  final VoidCallback? onCancelWhileWaiting;
  final bool skipDeviceAck;
  final Future<String?> Function()? failureMessageBuilder;

  const _ScheduleActionConfirmDialog({
    required this.title,
    required this.description,
    required this.iconAssetPath,
    required this.buttonLabel,
    required this.isActive,
    required this.onConfirm,
    this.onCancelWhileWaiting,
    this.skipDeviceAck = false,
    this.failureMessageBuilder,
  });

  @override
  State<_ScheduleActionConfirmDialog> createState() =>
      _ScheduleActionConfirmDialogState();
}

class _ScheduleActionConfirmDialogState
    extends State<_ScheduleActionConfirmDialog> {
  bool _isWaiting = false;
  int _elapsed = 0;
  Timer? _ticker;
  bool _closed = false;
  // When the publish/ACK round-trip resolves with false (and the user
  // didn't cancel), we switch into a failure view that reads the
  // cause and exposes a single OK button. This is the source of
  // truth for "render the error state".
  String? _errorMessage;

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  void _runPublish() {
    _ticker?.cancel();
    setState(() {
      _isWaiting = true;
      _elapsed = 1;
      _errorMessage = null;
    });
    // API-only callers (PENDING / FAILED deletes) skip the elapsed
    // ticker — there's no MQTT round-trip to count up to, and the body
    // stays on the normal confirm view so only the button spinner
    // signals progress.
    if (!widget.skipDeviceAck) {
      _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
        if (!mounted) return;
        setState(() {
          _elapsed = (_elapsed + 1).clamp(1, _kAckTotalSeconds);
        });
      });
    }
    widget.onConfirm().then((success) {
      _onPublishResult(success);
    }).catchError((_) {
      _onPublishResult(false);
    });
  }

  void _onPublishResult(bool success) {
    if (!mounted || _closed) return;
    _ticker?.cancel();
    if (success) {
      _close(true);
      return;
    }
    // ACK failed (and not a user-cancel — that path sets `_closed = true`
    // before this fires). Keep the dialog open with a clear error view
    // and an OK button so the user has to acknowledge the failure
    // instead of having the dialog vanish silently. Bulk callers can
    // override the message via failureMessageBuilder to surface partial
    // counts; without that, fall back to the generic copy.
    const fallback = 'No response from device. Please try again.';
    final builder = widget.failureMessageBuilder;
    if (builder == null) {
      setState(() {
        _isWaiting = false;
        _errorMessage = fallback;
      });
      return;
    }
    // Show a transient "checking…" message while the builder runs so
    // the user sees the dialog has moved past the spinner.
    setState(() {
      _isWaiting = false;
      _errorMessage = fallback;
    });
    builder().then((custom) {
      if (!mounted || _closed) return;
      if (custom == null || custom.isEmpty) return;
      setState(() => _errorMessage = custom);
    }).catchError((_) {
      // builder failed → fallback message already shown above.
    });
  }

  void _onConfirmTap() => _runPublish();

  void _onCancelTap() {
    if (_isWaiting) widget.onCancelWhileWaiting?.call();
    _close(false);
  }

  void _onOkTap() => _close(false);

  void _close(bool success) {
    if (_closed) return;
    _closed = true;
    _ticker?.cancel();
    if (mounted) Navigator.of(context).pop(success);
  }

  @override
  Widget build(BuildContext context) {
    final Color confirmColor =
        widget.isActive ? Colors.green[600]! : Colors.red[600]!;
    final hasError = _errorMessage != null;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      backgroundColor: Colors.transparent,
      child: Container(
        width: 368,
        constraints: const BoxConstraints(minHeight: 260),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(0, 20, 0, 0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const SizedBox(height: 4),
              if (hasError) ...[
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.error_outline_rounded,
                    size: 38,
                    color: Colors.red[600],
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  widget.title,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Colors.black,
                  ),
                ),
                const SizedBox(height: 8),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Text(
                    _errorMessage!,
                    textAlign: TextAlign.center,
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      color: Colors.grey[700],
                      height: 1.4,
                    ),
                  ),
                ),
              ] else if (!_isWaiting || widget.skipDeviceAck) ...[
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: SvgPicture.asset(
                    widget.iconAssetPath,
                    width: 70,
                    height: 70,
                    fit: BoxFit.cover,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  widget.title,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Colors.black,
                  ),
                ),
                const SizedBox(height: 8),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Text(
                    widget.description,
                    textAlign: TextAlign.center,
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      color: Colors.grey[600],
                      height: 1.4,
                    ),
                  ),
                ),
              ] else ...[
                Text(
                  widget.title,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.black,
                  ),
                ),
                const SizedBox(height: 12),
                _scheduleAckWaitingView(),
              ],
              const SizedBox(height: 16),
              Padding(
                padding: const EdgeInsets.only(left: 30, bottom: 18, right: 10),
                child: hasError
                    // Error state: a single OK button replaces Cancel /
                    // Confirm so the user can read the failure message
                    // and dismiss it explicitly. The dialog returns
                    // `false` so the caller doesn't navigate / refresh
                    // as if the action succeeded.
                    ? Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Expanded(
                            child: Material(
                              color: Colors.transparent,
                              borderRadius: BorderRadius.circular(10),
                              clipBehavior: Clip.antiAlias,
                              child: Ink(
                                height: 45,
                                decoration: BoxDecoration(
                                  // Same brand gradient the schedule FAB
                                  // uses (004E7E → 3686AF) so the
                                  // confirmation button stays visually
                                  // anchored to the rest of the app.
                                  gradient: const LinearGradient(
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                    colors: [
                                      Color(0xFF004E7E),
                                      Color(0xFF3686AF),
                                    ],
                                  ),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: InkWell(
                                  onTap: _closed ? null : _onOkTap,
                                  borderRadius: BorderRadius.circular(10),
                                  child: Center(
                                    child: Text(
                                      'OK',
                                      style: GoogleFonts.inter(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      )
                    : Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: GestureDetector(
                              // Cancel disabled while the publish is
                              // in flight (matches the first two
                              // dialogs in this file). `_closed`
                              // gate still applies for the route-
                              // teardown edge case.
                              onTap: (_isWaiting || _closed)
                                  ? null
                                  : _onCancelTap,
                              behavior: HitTestBehavior.opaque,
                              child: Padding(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 10),
                                child: Text(
                                  'Cancel',
                                  style: GoogleFonts.inter(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w500,
                                    color: _isWaiting
                                        ? Colors.grey.withValues(alpha: 0.4)
                                        : Colors.grey[700],
                                  ),
                                ),
                              ),
                            ),
                          ),
                          Expanded(
                            child: SizedBox(
                              height: 45,
                              child: TextButton(
                                onPressed:
                                    _isWaiting || _closed ? null : _onConfirmTap,
                                style: TextButton.styleFrom(
                                  backgroundColor: Colors.white,
                                  disabledBackgroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                ),
                                child: _isWaiting
                                    ? SizedBox(
                                        width: 20,
                                        height: 20,
                                        child: CircularProgressIndicator(
                                          color: confirmColor,
                                          strokeWidth: 2,
                                        ),
                                      )
                                    : Text(
                                        widget.buttonLabel,
                                        style: GoogleFonts.inter(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w600,
                                          color: confirmColor,
                                        ),
                                      ),
                              ),
                            ),
                          ),
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
