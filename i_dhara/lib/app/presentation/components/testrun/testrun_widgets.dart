part of '../testrun_verification_card.dart';

/// Shared low-level widgets used across testrun phase builders.
extension _TestRunWidgets on _ConfirmTestRunScreenState {
  Widget get checkIcon => Container(
        width: 24,
        height: 24,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: const Color(0xFFECFDF5),
          border: Border.all(
            color: const Color(0xFF10B981),
            width: 1.5,
          ),
        ),
        child: const Icon(
          Icons.check_rounded,
          color: Color(0xFF10B981),
          size: 16,
        ),
      );

  Widget get closeIcon => Container(
        width: 24,
        height: 24,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.red.shade100,
          border: Border.all(
            color: Colors.red,
            width: 1.5,
          ),
        ),
        child: const Icon(
          Icons.close_rounded,
          color: Colors.red,
          size: 16,
        ),
      );

  Widget get loadingIcon => const SizedBox(
        width: 24,
        height: 24,
        child: CircularProgressIndicator(
          strokeWidth: 2.5,
          color: Color(0xFF0F6B8A),
        ),
      );

  Widget _buildVerificationCloudConnection(
      String text, bool? signal, String svg) {
    return Row(
      spacing: 10,
      children: [
        SvgPicture.asset('assets/images/network_device.svg'),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
              fontSize: 14,
              color: Color(0xFF334155),
            ),
          ),
        ),
        signal != null
            ? signal
                ? checkIcon
                : closeIcon
            : loadingIcon
      ],
    );
  }

  Widget _buildVerificationInputPower(String text, int? verified) {
    return Row(
      spacing: 10,
      children: [
        SvgPicture.asset('assets/images/bulb_power.svg'),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
              fontSize: 14,
              color: Color(0xFF334155),
            ),
          ),
        ),
        verified != null
            ? verified == 1
                ? checkIcon
                : closeIcon
            : loadingIcon
      ],
    );
  }

  Widget _buildVoltageVerification() {
    final bool hasSignal = widget.motorData?.testrunVoltageRange == true;
    final bool showLoading;
    final bool voltageOk;

    if (hasSignal && _isVoltageInRange) {
      showLoading = false;
      voltageOk = true;
    } else if (hasSignal || _preCheckTimedOut) {
      // Data received but voltage out of range, or timed out without data.
      showLoading = false;
      voltageOk = false;
    } else {
      showLoading = true;
      voltageOk = false;
    }

    final String? error =
        (!showLoading && !voltageOk && hasSignal) ? _voltageError : null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          spacing: 8,
          children: [
            const Icon(Icons.electric_bolt, size: 20, color: Color(0xFF64748B)),
            const Expanded(
              child: Text(
                'Voltage Range (370V - 450V)',
                style: TextStyle(
                  fontSize: 14,
                  color: Color(0xFF334155),
                ),
              ),
            ),
            if (showLoading)
              loadingIcon
            else if (voltageOk)
              checkIcon
            else
              closeIcon,
          ],
        ),
        if (error != null) ...[
          const SizedBox(height: 6),
          Padding(
            padding: const EdgeInsets.only(left: 30),
            child: Text(
              error,
              style: const TextStyle(
                fontSize: 12,
                color: Colors.red,
                fontWeight: FontWeight.w400,
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildCheckboxItem(
    String text,
    bool value,
    ValueChanged<bool?> onChanged,
  ) {
    return GestureDetector(
      onTap: () => onChanged(!value),
      behavior: HitTestBehavior.opaque,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SizedBox(
            width: 20,
            height: 20,
            child: Checkbox(
              value: value,
              onChanged: onChanged,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(4),
              ),
              side: const BorderSide(
                color: Color(0xFFCBD5E1),
                width: 1.5,
              ),
              activeColor: const Color(0xFF0F6B8A),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                fontSize: 14,
                color: Color(0xFF334155),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
