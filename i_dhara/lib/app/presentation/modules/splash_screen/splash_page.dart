import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:i_dhara/app/core/flutter_flow/flutter_flow_theme.dart';
import 'package:i_dhara/app/core/flutter_flow/flutter_flow_util.dart';
import 'package:i_dhara/app/presentation/routes/app_routes.dart';
import 'package:video_player/video_player.dart';

class SplashCopyWidget extends StatefulWidget {
  const SplashCopyWidget({super.key});

  static String routeName = 'Splash';
  static String routePath = '/splash';

  @override
  State<SplashCopyWidget> createState() => _SplashCopyWidgetState();
}

class _SplashCopyWidgetState extends State<SplashCopyWidget> {
  final scaffoldKey = GlobalKey<ScaffoldState>();
  late VideoPlayerController _videoController;
  bool _isVideoInitialized = false;

  @override
  void initState() {
    super.initState();
    _initializeVideo();
  }

  Future<void> _initializeVideo() async {
    _videoController = VideoPlayerController.asset('assets/videos/splash.mp4');

    await _videoController.initialize();
    _videoController.setLooping(true);
    _videoController.play();

    setState(() {
      _isVideoInitialized = true;
    });
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final shortestSide = size.shortestSide;
    final isTablet = shortestSide >= 600;
    final isLargeTablet = shortestSide >= 900;

    final horizontalPadding = isLargeTablet ? 96.0 : (isTablet ? 64.0 : 36.0);
    final logoMaxWidth = isLargeTablet ? 360.0 : (isTablet ? 300.0 : 240.0);
    final tagFontSize = isLargeTablet ? 28.0 : (isTablet ? 24.0 : 20.0);
    final spacingBetween = isTablet ? 48.0 : 36.0;
    final bottomGap = isTablet ? 96.0 : 64.0;
    final arrowPadding = isTablet ? 28.0 : 20.0;
    final arrowIconSize = isTablet ? 32.0 : 24.0;
    final contentMaxWidth = isLargeTablet ? 560.0 : (isTablet ? 480.0 : 420.0);

    return GestureDetector(
      onTap: () {
        FocusScope.of(context).unfocus();
        FocusManager.instance.primaryFocus?.unfocus();
      },
      child: Scaffold(
        key: scaffoldKey,
        backgroundColor: FlutterFlowTheme.of(context).secondaryBackground,
        body: Stack(
          children: [
            Positioned.fill(
              child: _isVideoInitialized
                  ? FittedBox(
                      fit: BoxFit.cover,
                      child: SizedBox(
                        width: _videoController.value.size.width,
                        height: _videoController.value.size.height,
                        child: VideoPlayer(_videoController),
                      ),
                    )
                  : Container(
                      color: FlutterFlowTheme.of(context).secondaryBackground,
                    ),
            ),
            SafeArea(
              child: Column(
                mainAxisSize: MainAxisSize.max,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Padding(
                      padding: EdgeInsetsDirectional.fromSTEB(
                          horizontalPadding, 0, horizontalPadding, 0),
                      child: Center(
                        child: ConstrainedBox(
                          constraints:
                              BoxConstraints(maxWidth: contentMaxWidth),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              ConstrainedBox(
                                constraints:
                                    BoxConstraints(maxWidth: logoMaxWidth),
                                child: SvgPicture.asset(
                                  'assets/images/idhara_splash_logo.svg',
                                  fit: BoxFit.contain,
                                ),
                              ),
                              Text(
                                'Smart pump control and monitoring, at your fingertips',
                                textAlign: TextAlign.center,
                                style: FlutterFlowTheme.of(context)
                                    .bodyMedium
                                    .override(
                                      font: GoogleFonts.dmSans(
                                        fontWeight: FontWeight.w600,
                                        fontStyle: FlutterFlowTheme.of(context)
                                            .bodyMedium
                                            .fontStyle,
                                      ),
                                      color: Colors.white,
                                      fontSize: tagFontSize,
                                      letterSpacing: 0.0,
                                      fontWeight: FontWeight.w600,
                                      fontStyle: FlutterFlowTheme.of(context)
                                          .bodyMedium
                                          .fontStyle,
                                    ),
                              ),
                            ].divide(SizedBox(height: spacingBetween)),
                          ),
                        ),
                      ),
                    ),
                  ),
                  Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFF004E7E),
                      borderRadius: BorderRadius.circular(40),
                    ),
                    child: GestureDetector(
                      onTap: () {
                        Get.toNamed(Routes.loginwithmobile);
                      },
                      child: Padding(
                        padding: EdgeInsets.all(arrowPadding),
                        child: FaIcon(
                          FontAwesomeIcons.arrowRight,
                          color: Colors.white,
                          size: arrowIconSize,
                        ),
                      ),
                    ),
                  ),
                ].addToEnd(SizedBox(height: bottomGap)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
