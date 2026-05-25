import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:i_dhara/app/core/utils/snackbars/error_snackbar.dart';
import 'package:i_dhara/app/core/utils/snackbars/success_snackbar.dart';
import 'package:i_dhara/app/data/repository/user_profile/user_profile_repo_impl.dart';
import 'package:i_dhara/app/data/services/mqtt_manager/mqtt_service.dart';
import 'package:i_dhara/app/data/services/storages/shared_preference.dart';
import 'package:i_dhara/app/presentation/routes/app_routes.dart';

const _kBg = Color(0xFFF8FAFF);
const _kPrimary = Color(0xFF004E7E);
const _kGradientEnd = Color(0xFF3686AF);
const _kSurface = Colors.white;
const _kBorder = Color(0xFFEBF2FF);
const _kSubtext = Color(0xFF64748B);
const _kText = Color(0xFF1E293B);
const _kRed = Color(0xFFEF4444);
const _kRedTint = Color(0xFFFEE2E2);

class DeleteAccountPage extends StatefulWidget {
  const DeleteAccountPage({super.key});

  @override
  State<DeleteAccountPage> createState() => _DeleteAccountPageState();
}

class _DeleteAccountPageState extends State<DeleteAccountPage> {
  final TextEditingController _confirmController = TextEditingController();
  bool _ackUnderstand = false;
  bool _isDeleting = false;

  @override
  void dispose() {
    _confirmController.dispose();
    super.dispose();
  }

  bool get _canDelete =>
      _ackUnderstand &&
      _confirmController.text.trim().toUpperCase() == 'DELETE' &&
      !_isDeleting;

  Future<void> _handleDelete() async {
    if (!_canDelete) return;

    final confirmed = await _showFinalConfirmation();
    if (confirmed != true) return;

    setState(() => _isDeleting = true);

    try {
      final userId = SharedPreference.getUserId();
      if (userId == null) {
        if (mounted) errorSnackBar(context, 'User session not found.');
        setState(() => _isDeleting = false);
        return;
      }

      final success = await UserProfileRepoImpl().deleteAccount(userId);

      if (success) {
        MqttService().disconnectOnly();
        await SharedPreference.clear();
        try {
          final token = await FirebaseMessaging.instance.getToken();
          if (token != null) SharedPreference.setFcmToken(token);
        } catch (_) {}

        Get.deleteAll(force: true);
        if (!mounted) return;
        successSnackBar(context, 'Your account has been deleted.');
        Get.offAllNamed(Routes.loginwithmobile);
      } else {
        if (mounted) {
          errorSnackBar(context,
              'Unable to delete account. Please try again later.');
        }
      }
    } catch (e) {
      if (mounted) errorSnackBar(context, 'Something went wrong: $e');
    } finally {
      if (mounted) setState(() => _isDeleting = false);
    }
  }

  Future<bool?> _showFinalConfirmation() {
    return showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: Text(
          'Delete account?',
          style: GoogleFonts.dmSans(
              fontWeight: FontWeight.w700, color: _kText, fontSize: 18),
        ),
        content: Text(
          'This will permanently delete your profile, motor associations, '
          'schedules and history. This action cannot be undone.',
          style: GoogleFonts.dmSans(color: _kSubtext, fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(
              'Cancel',
              style: GoogleFonts.dmSans(
                  color: _kPrimary, fontWeight: FontWeight.w600),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: _kRed,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(
              'Delete',
              style: GoogleFonts.dmSans(fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kBg,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
              colors: [_kPrimary, _kGradientEnd],
            ),
          ),
        ),
        systemOverlayStyle: const SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.light,
          statusBarBrightness: Brightness.dark,
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded,
              color: Colors.white, size: 18),
          onPressed: () => Get.back(),
        ),
        title: Text(
          'Delete Account',
          style: GoogleFonts.dmSans(
            color: Colors.white,
            fontWeight: FontWeight.w700,
            fontSize: 18,
          ),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _WarningBanner(),
              const SizedBox(height: 24),
              Text(
                'What will be deleted',
                style: GoogleFonts.dmSans(
                  color: _kText,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 12),
              _DeleteList(items: const [
                'Your profile and contact details',
                'All motor and starter associations',
                'Saved schedules and run history',
              ]),
              const SizedBox(height: 28),
              CheckboxListTile(
                value: _ackUnderstand,
                onChanged: (v) => setState(() => _ackUnderstand = v ?? false),
                title: Text(
                  'I understand this action is permanent and cannot be undone.',
                  style: GoogleFonts.dmSans(
                    color: _kText,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                controlAffinity: ListTileControlAffinity.leading,
                activeColor: _kRed,
                contentPadding: EdgeInsets.zero,
              ),
              const SizedBox(height: 8),
              Text(
                'Type DELETE to confirm',
                style: GoogleFonts.dmSans(
                  color: _kSubtext,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.6,
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _confirmController,
                onChanged: (_) => setState(() {}),
                textCapitalization: TextCapitalization.characters,
                decoration: InputDecoration(
                  hintText: 'DELETE',
                  filled: true,
                  fillColor: _kSurface,
                  contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 14),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: _kBorder),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: _kBorder),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: _kRed, width: 1.5),
                  ),
                ),
              ),
              const SizedBox(height: 28),
              SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton(
                  onPressed: _canDelete ? _handleDelete : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _kRed,
                    disabledBackgroundColor: const Color(0xFFE5E7EB),
                    foregroundColor: Colors.white,
                    disabledForegroundColor: const Color(0xFF9CA3AF),
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: _isDeleting
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.4,
                            color: Colors.white,
                          ),
                        )
                      : Text(
                          'Delete my account',
                          style: GoogleFonts.dmSans(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.3,
                          ),
                        ),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: OutlinedButton(
                  onPressed: _isDeleting ? null : () => Get.back(),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: _kPrimary,
                    side: const BorderSide(color: _kPrimary, width: 1.2),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: Text(
                    'Cancel',
                    style: GoogleFonts.dmSans(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
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

class _WarningBanner extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _kRedTint,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _kRed.withOpacity(0.25)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: _kRed.withOpacity(0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.warning_amber_rounded,
                color: _kRed, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'This is permanent',
                  style: GoogleFonts.dmSans(
                    color: _kRed,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Once deleted, your account and all related data cannot '
                  'be recovered.',
                  style: GoogleFonts.dmSans(
                    color: const Color(0xFF7F1D1D),
                    fontSize: 13,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _DeleteList extends StatelessWidget {
  final List<String> items;
  const _DeleteList({required this.items});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: _kSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _kBorder),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        children: [
          for (final item in items)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.cancel_rounded, color: _kRed, size: 18),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      item,
                      style: GoogleFonts.dmSans(
                        color: _kText,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
