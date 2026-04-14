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
                      padding:
                          const EdgeInsetsDirectional.fromSTEB(36, 0, 36, 0),
                      child: Container(
                        decoration: const BoxDecoration(),
                        child: Column(
                          mainAxisSize: MainAxisSize.max,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(0),
                              child: SvgPicture.asset(
                                'assets/images/idhara_splash_logo.svg',
                                fit: BoxFit.cover,
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
                                    fontSize: 20,
                                    letterSpacing: 0.0,
                                    fontWeight: FontWeight.w600,
                                    fontStyle: FlutterFlowTheme.of(context)
                                        .bodyMedium
                                        .fontStyle,
                                  ),
                            ),
                          ].divide(const SizedBox(height: 36)),
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
                      child: const Padding(
                        padding: EdgeInsets.all(20),
                        child: FaIcon(
                          FontAwesomeIcons.arrowRight,
                          color: Colors.white,
                          size: 24,
                        ),
                      ),
                    ),
                  ),
                ].addToEnd(const SizedBox(height: 64)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
