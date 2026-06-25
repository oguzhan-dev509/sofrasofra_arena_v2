import 'app_install_tracking_platform_stub.dart'
    if (dart.library.html) 'app_install_tracking_platform_web.dart' as platform;

class AppInstallTrackingService {
  const AppInstallTrackingService._();

  static bool _started = false;

  static Future<void> start() async {
    if (_started) return;
    _started = true;

    await platform.startAppInstallTracking();
  }
}
