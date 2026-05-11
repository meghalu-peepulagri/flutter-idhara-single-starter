import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:google_fonts/google_fonts.dart';

const int _kAckTotalSeconds = 23;
const int _kAckTotalAttempts = 3;

int _ackAttemptForElapsed(int elapsed) {
  if (elapsed >= 20) return 3;
  if (elapsed >= 10) return 2;
  return 1;
}

Widget _scheduleAckWaitingView({required int elapsedSeconds}) {
  final clamped = elapsedSeconds.clamp(1, _kAckTotalSeconds);
  final attempt = _ackAttemptForElapsed(clamped);
  final progress = (clamped / _kAckTotalSeconds).clamp(0.0, 1.0);
  return Column(
    mainAxisSize: MainAxisSize.min,
    children: [
      SizedBox(
        width: 64,
        height: 64,
        child: Stack(
          alignment: Alignment.center,
          children: [
            SizedBox.expand(
              child: CircularProgressIndicator(
                value: progress,
                strokeWidth: 4,
                color: const Color(0xFF004E7E),
                backgroundColor: const Color(0xFFE2E8F0),
              ),
            ),
            Text(
              '${clamped}s',
              style: GoogleFonts.dmSans(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF004E7E),
              ),
            ),
          ],
        ),
      ),
      const SizedBox(height: 10),
      const _WaitingForAckText(),
      const SizedBox(height: 4),
      Text(
        'Attempt $attempt of $_kAckTotalAttempts',
        style: GoogleFonts.dmSans(
          fontSize: 12,
          color: const Color(0xFF57636C),
        ),
      ),
    ],
  );
}

Widget _scheduleInlineErrorBanner(String message) {
  return Container(
    width: double.infinity,
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
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
  bool _isFailed = false;
  bool _hasRetried = false;
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
      if (_hasRetried) {
        _close();
        return;
      }
      setState(() {
        _isWaiting = false;
        _isFailed = true;
        _elapsed = 0;
      });
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

  void _onRetryTap() {
    _hasRetried = true;
    _runConfirm();
  }

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
                _scheduleInlineErrorBanner(_errorMessage!),
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
                      const SizedBox(height: 6),
                      _dialogRow('Power Recovery', widget.powerRecovery),
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
                _scheduleAckWaitingView(elapsedSeconds: _elapsed),
            ],
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: SizedBox(
                    height: 44,
                    child: OutlinedButton(
                      onPressed: _onCancelTap,
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Color(0xFF004E7E)),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: Text(
                        'Cancel',
                        style: GoogleFonts.dmSans(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF004E7E),
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
                      onPressed: _isWaiting
                          ? null
                          : (_isFailed ? _onRetryTap : _onConfirmTap),
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
                              _isFailed ? 'Retry' : 'Confirm',
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
  // Same waiting / failed / retry state machine as _ScheduleConfirmDialog.
  bool _isWaiting = false;
  bool _isFailed = false;
  bool _hasRetried = false;
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
      if (_hasRetried) {
        _close();
        return;
      }
      setState(() {
        _isWaiting = false;
        _isFailed = true;
        _elapsed = 0;
      });
      return;
    }
    setState(() {
      _isWaiting = false;
      _isFailed = false;
      _errorMessage = error;
    });
  }

  void _onConfirmTap() => _runConfirm();

  void _onRetryTap() {
    _hasRetried = true;
    _runConfirm();
  }

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
                decoration: const BoxDecoration(
                  color: Color(0xFFEBF3FE),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.schedule_rounded,
                    size: 26, color: Color(0xFF004E7E)),
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
              if (!_isWaiting && !_isFailed) ...[
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
                if (_errorMessage != null) ...[
                  const SizedBox(height: 10),
                  _scheduleInlineErrorBanner(_errorMessage!),
                ],
                const SizedBox(height: 12),
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
                  child: Row(
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
                  _scheduleAckWaitingView(elapsedSeconds: _elapsed),
              ],
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: SizedBox(
                      height: 44,
                      child: OutlinedButton(
                        onPressed: _onCancelTap,
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: Color(0xFF004E7E)),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: Text(
                          'Cancel',
                          style: GoogleFonts.dmSans(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF004E7E),
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
                        onPressed: _isWaiting
                            ? null
                            : (_isFailed ? _onRetryTap : _onConfirmTap),
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
                                _isFailed ? 'Retry' : 'Confirm',
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
      : '${s.duration}${s.powerRecovery == 'ON' ? '  ·  Pwr Recovery' : ''}';

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

  const _ScheduleActionConfirmDialog({
    required this.title,
    required this.description,
    required this.iconAssetPath,
    required this.buttonLabel,
    required this.isActive,
    required this.onConfirm,
    this.onCancelWhileWaiting,
  });

  @override
  State<_ScheduleActionConfirmDialog> createState() =>
      _ScheduleActionConfirmDialogState();
}

class _ScheduleActionConfirmDialogState
    extends State<_ScheduleActionConfirmDialog> {
  bool _isWaiting = false;

  bool _isFailed = false;

  bool _hasRetried = false;
  int _elapsed = 0;
  Timer? _ticker;
  bool _closed = false;

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  void _runPublish() {
    _ticker?.cancel();
    setState(() {
      _isWaiting = true;
      _isFailed = false;

      _elapsed = 1;
    });
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      setState(() {
        _elapsed = (_elapsed + 1).clamp(1, _kAckTotalSeconds);
      });
    });
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
    } else if (_hasRetried) {
      // Retry already burned — auto-close on second failure.
      _close(false);
    } else {
      setState(() {
        _isWaiting = false;
        _isFailed = true;
        _elapsed = 0;
      });
    }
  }

  void _onConfirmTap() => _runPublish();

  void _onRetryTap() {
    _hasRetried = true;
    _runPublish();
  }

  void _onCancelTap() {
    if (_isWaiting) widget.onCancelWhileWaiting?.call();
    _close(false);
  }

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
              if (!_isWaiting && !_isFailed) ...[
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
              ] else if (_isFailed) ...[
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
                _scheduleAckFailedView(),
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
                _scheduleAckWaitingView(elapsedSeconds: _elapsed),
              ],
              const SizedBox(height: 16),
              Padding(
                padding: const EdgeInsets.only(left: 30, bottom: 18, right: 10),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: _closed ? null : _onCancelTap,
                        behavior: HitTestBehavior.opaque,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          child: Text(
                            'Cancel',
                            style: GoogleFonts.inter(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                              color: Colors.grey[700],
                            ),
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      child: SizedBox(
                        height: 45,
                        child: TextButton(
                          onPressed: _isWaiting || _closed
                              ? null
                              : (_isFailed ? _onRetryTap : _onConfirmTap),
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
                                  _isFailed ? 'Retry' : widget.buttonLabel,
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
