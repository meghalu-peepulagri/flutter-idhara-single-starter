import 'dart:io' show Platform;

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:i_dhara/app/core/config/env.dart';
import 'package:i_dhara/app/core/services/connectivity_service.dart';
import 'package:i_dhara/app/core/utils/app_loading.dart';
import 'package:i_dhara/app/presentation/modules/user_profile/user_profile_controller.dart';
import 'package:i_dhara/app/presentation/routes/app_routes.dart';
import 'package:i_dhara/app/presentation/widgets/no_internet_view.dart';
import 'package:skeletonizer/skeletonizer.dart';

// ── Palette (unchanged as requested) ─────────────────────────────────────────
const _kBg = Color(0xFFF8FAFF);
const _kPrimary = Color(0xFF004E7E);
const _kGradientEnd = Color(0xFF3686AF);

// ── Extra tokens ──────────────────────────────────────────────────────────────
const _kSurface = Colors.white;
const _kBorder = Color(0xFFEBF2FF);
const _kSubtext = Color(0xFF94A3B8);
const _kText = Color(0xFF1E293B);
const _kDivider = Color(0xFFF1F5F9);
const _kRed = Color(0xFFEF4444);

class ProfileWidget extends StatelessWidget {
  final scaffoldKey = GlobalKey<ScaffoldState>();
  final UserProfileController controller = Get.put(UserProfileController());

  ProfileWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        Get.offAllNamed(Routes.dashboard);
        return false;
      },
      child: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: Scaffold(
          key: scaffoldKey,
          backgroundColor: _kBg,
          body: Obx(() {
            if (controller.isLoading.value) {
              return const Padding(
                padding: EdgeInsets.only(right: 30),
                child: Center(child: AppLottieLoading()),
              );
            } else if (!ConnectivityService.to.isConnected) {
              return const Center(child: NoInternetWidget());
            }
            final profile = controller.userProfile.value;
            return RefreshIndicator(
              onRefresh: controller.onRefresh,
              color: _kPrimary,
              child: CustomScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                slivers: [
                  // ── App Bar ────────────────────────────────────────────
                  SliverAppBar(
                    expandedHeight: 270,
                    pinned: true,
                    elevation: 0,
                    backgroundColor: _kPrimary,
                    automaticallyImplyLeading: false,
                    systemOverlayStyle: const SystemUiOverlayStyle(
                      statusBarColor: Colors.transparent,
                      statusBarIconBrightness: Brightness.light,
                      statusBarBrightness: Brightness.dark,
                    ),
                    flexibleSpace: FlexibleSpaceBar(
                      background: Skeletonizer(
                        enabled: controller.isRefreshing.value,
                        child: _ProfileHeader(profile: profile),
                      ),
                    ),
                    title: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          _CircleButton(
                            icon: Icons.arrow_back_ios_new_rounded,
                            onTap: () => Get.offAllNamed(Routes.dashboard),
                          ),
                          Text(
                            'My Profile',
                            style: GoogleFonts.dmSans(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                              fontSize: 18,
                            ),
                          ),
                          Container(width: 40),
                        ],
                      ),
                    ),
                  ),

                  // ── Body Content ───────────────────────────────────────
                  SliverToBoxAdapter(
                    child: Skeletonizer(
                      enabled: controller.isRefreshing.value,
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(20, 24, 20, 48),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const _SectionLabel(label: 'ACCOUNT SETTINGS'),
                            const SizedBox(height: 12),
                            _ContactCard(profile: profile),
                            const SizedBox(height: 32),
                            const _SectionLabel(label: 'SESSION'),
                            const SizedBox(height: 12),
                            _LogoutButton(
                              onPressed: () async {
                                await controller.fetchFcmToken();
                              },
                            ),
                            if (!kIsWeb && Platform.isIOS) ...[
                              const SizedBox(height: 24),
                              const _SectionLabel(label: 'DANGER ZONE'),
                              const SizedBox(height: 12),
                              _DeleteAccountButton(
                                onPressed: () =>
                                    Get.toNamed(Routes.deleteAccount),
                              ),
                            ],
                            const SizedBox(height: 32),
                            _AppVersionInfo(controller: controller),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Profile Header
// ─────────────────────────────────────────────────────────────────────────────

class _ProfileHeader extends StatelessWidget {
  final dynamic profile;
  const _ProfileHeader({required this.profile});

  /// Returns up to 2 initials from a full name.
  String _initials(String? name) {
    if (name == null || name.trim().isEmpty) return '?';
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.length == 1) return parts[0][0].toUpperCase();
    return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        // Gradient background
        Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [_kGradientEnd, _kPrimary],
            ),
          ),
        ),

        // Decorative circle – top-right
        Positioned(
          top: -30,
          right: -30,
          child: Container(
            width: 170,
            height: 170,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withOpacity(0.07),
            ),
          ),
        ),
        // Decorative circle – mid-left
        Positioned(
          top: 50,
          left: -50,
          child: Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withOpacity(0.04),
            ),
          ),
        ),
        // Decorative circle – bottom-right accent
        Positioned(
          bottom: 20,
          right: 20,
          child: Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withOpacity(0.06),
            ),
          ),
        ),

        // Avatar + name + role
        Positioned(
          bottom: 24,
          left: 0,
          right: 0,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Avatar with outer glow ring
              Stack(
                alignment: Alignment.center,
                children: [
                  // Outer glow ring
                  Container(
                    width: 107,
                    height: 107,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                          color: Colors.white.withOpacity(0.25), width: 2),
                    ),
                  ),
                  // Avatar circle
                  Container(
                    width: 95,
                    height: 95,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        colors: [
                          Colors.white.withOpacity(0.3),
                          Colors.white.withOpacity(0.1),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      border: Border.all(color: Colors.white, width: 2.5),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.2),
                          blurRadius: 16,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: Center(
                      child: Text(
                        _initials(profile?.fullName),
                        style: GoogleFonts.dmSans(
                          color: Colors.white,
                          fontSize: 30,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1,
                        ),
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 14),

              // Full name
              Text(
                profile?.fullName ?? 'Unknown User',
                style: GoogleFonts.dmSans(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                  fontSize: 22,
                  letterSpacing: -0.5,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 8),

              // Role pill
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(25),
                  border: Border.all(
                      color: Colors.white.withOpacity(0.3), width: 1),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      profile?.userType ?? 'Member',
                      style: GoogleFonts.dmSans(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.4,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Contact Card
// ─────────────────────────────────────────────────────────────────────────────

class _ContactCard extends StatelessWidget {
  final dynamic profile;
  const _ContactCard({required this.profile});

  @override
  Widget build(BuildContext context) {
    final UserProfileController controller = Get.find<UserProfileController>();
    return Container(
      decoration: BoxDecoration(
        color: _kSurface,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: _kPrimary.withOpacity(0.08),
            blurRadius: 30,
            offset: const Offset(0, 10),
          ),
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
        border: Border.all(color: _kBorder, width: 1),
      ),
      child: Column(
        children: [
          _ContactRow(
            iconData: Icons.mail_rounded,
            iconColor: const Color(0xFF6366F1),
            iconBg: const Color(0xFFEEF2FF),
            label: 'Email Address',
            value: controller.userProfile.value?.email ?? 'Not available',
            isFirst: true,
            copyable: true,
          ),
          _DividerLine(),
          _ContactRow(
            iconData: Icons.phone_android_rounded,
            iconColor: const Color(0xFF0EA5E9),
            iconBg: const Color(0xFFE0F2FE),
            label: 'Phone Number',
            value: controller.userProfile.value?.phone ?? 'Not available',
            copyable: true,
          ),
          _DividerLine(),
          _ContactRow(
            iconData: Icons.location_on_rounded,
            iconColor: _kPrimary,
            iconBg: const Color(0xFFE0EFF8),
            label: 'Location / Address',
            value:
                controller.userProfile.value?.address ?? 'No address provided',
            isLast: true,
          ),
        ],
      ),
    );
  }
}

class _ContactRow extends StatelessWidget {
  final IconData iconData;
  final Color iconColor;
  final Color iconBg;
  final String label;
  final String value;
  final bool isFirst;
  final bool isLast;
  final bool copyable;

  const _ContactRow({
    required this.iconData,
    required this.iconColor,
    required this.iconBg,
    required this.label,
    required this.value,
    this.isFirst = false,
    this.isLast = false,
    this.copyable = false,
  });

  void _copy(BuildContext context) {
    Clipboard.setData(ClipboardData(text: value));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          '$label copied',
          style: GoogleFonts.dmSans(fontWeight: FontWeight.w600),
        ),
        backgroundColor: _kPrimary,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: copyable ? () => _copy(context) : null,
      borderRadius: BorderRadius.vertical(
        top: isFirst ? const Radius.circular(24) : Radius.zero,
        bottom: isLast ? const Radius.circular(24) : Radius.zero,
      ),
      splashColor: _kPrimary.withOpacity(0.04),
      highlightColor: _kPrimary.withOpacity(0.02),
      child: Padding(
        padding: EdgeInsets.only(
          left: 20,
          right: 16,
          top: isFirst ? 22 : 14,
          bottom: isLast ? 22 : 14,
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Tinted icon container
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: iconBg,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(iconData, color: iconColor, size: 22),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label.toUpperCase(),
                    style: GoogleFonts.dmSans(
                      color: _kSubtext,
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.0,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    value,
                    style: GoogleFonts.dmSans(
                      color: _kText,
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            if (copyable) ...[
              const SizedBox(width: 8),
              const Icon(Icons.copy_rounded, size: 16, color: _kSubtext),
            ],
          ],
        ),
      ),
    );
  }
}

class _DividerLine extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      height: 1,
      margin: const EdgeInsets.symmetric(horizontal: 20),
      color: _kDivider,
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Section Label  (with left accent bar)
// ─────────────────────────────────────────────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  final String label;
  const _SectionLabel({required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 3,
          height: 14,
          margin: const EdgeInsets.only(right: 8),
          decoration: BoxDecoration(
            color: _kPrimary,
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        Text(
          label,
          style: GoogleFonts.dmSans(
            color: const Color(0xFF64748B),
            fontSize: 11,
            fontWeight: FontWeight.w800,
            letterSpacing: 1.4,
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Logout Button  ← updated: disables itself after first tap
// ─────────────────────────────────────────────────────────────────────────────

class _LogoutButton extends StatefulWidget {
  final Future<void> Function() onPressed;
  const _LogoutButton({required this.onPressed});

  @override
  State<_LogoutButton> createState() => _LogoutButtonState();
}

class _LogoutButtonState extends State<_LogoutButton> {
  bool _isLoading = false;

  Future<void> _handlePress() async {
    if (_isLoading) return;
    setState(() => _isLoading = true);
    try {
      await widget.onPressed();
    } catch (_) {
      // Re-enable the button if something goes wrong so the user can retry.
      if (mounted) setState(() => _isLoading = false);
    }
    // If navigation succeeded the widget is unmounted, so nothing more to do.
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: 56,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: (_isLoading ? Colors.grey : _kRed).withOpacity(0.18),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ElevatedButton(
        onPressed: _isLoading ? null : _handlePress,
        style: ElevatedButton.styleFrom(
          backgroundColor: _isLoading ? const Color(0xFFB0BEC5) : _kRed,
          foregroundColor: Colors.white,
          disabledBackgroundColor: const Color(0xFFB0BEC5),
          disabledForegroundColor: Colors.white70,
          elevation: 0,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: _isLoading
                  ? const Padding(
                      padding: EdgeInsets.all(7),
                      child: CircularProgressIndicator(
                        strokeWidth: 2.2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(
                      Icons.logout_rounded,
                      size: 18,
                      color: Colors.white,
                    ),
            ),
            const SizedBox(width: 12),
            Text(
              _isLoading ? 'Signing Out...' : 'Sign Out',
              style: GoogleFonts.dmSans(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.3,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// App Version Info
// ─────────────────────────────────────────────────────────────────────────────

class _AppVersionInfo extends StatelessWidget {
  final UserProfileController controller;
  const _AppVersionInfo({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final version = controller.appVersion.value;
      final build = controller.appBuildNumber.value;
      if (version.isEmpty) return const SizedBox.shrink();

      final env = AppEnvironment.environment;
      final isNonLive = env != Environment.live;
      final envLabel = env == Environment.staging ? 'STAGING' : 'DEV';
      final envColor = env == Environment.staging
          ? const Color(0xFFE65100)
          : const Color(0xFF1B7A34);

      return Center(
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Version $version',
              style: GoogleFonts.dmSans(
                color: _kSubtext,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
            if (isNonLive) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: envColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                      color: envColor.withValues(alpha: 0.4), width: 1),
                ),
                child: Text(
                  envLabel,
                  style: GoogleFonts.dmSans(
                    color: envColor,
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.8,
                  ),
                ),
              ),
            ],
          ],
        ),
      );
    });
  }
}

class _DeleteAccountButton extends StatelessWidget {
  final VoidCallback onPressed;
  const _DeleteAccountButton({required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: _kSurface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _kRed.withOpacity(0.25)),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: onPressed,
          child: Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            child: Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: _kRed.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.delete_forever_rounded,
                      color: _kRed, size: 18),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Delete Account',
                    style: GoogleFonts.dmSans(
                      color: _kRed,
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const Icon(Icons.chevron_right_rounded,
                    color: _kRed, size: 18),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _CircleButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _CircleButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.white.withOpacity(0.18),
          border: Border.all(color: Colors.white.withOpacity(0.35), width: 1.5),
        ),
        child: Icon(icon, color: Colors.white, size: 18),
      ),
    );
  }
}
