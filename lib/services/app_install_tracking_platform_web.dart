import 'dart:html' as html;
import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

const String _installIdKey = 'sofrasofra_install_id_v1';
const String _installedKey = 'sofrasofra_pwa_installed_v1';
const String _installedAtKey = 'sofrasofra_pwa_installed_at_v1';

bool _listenerAttached = false;

Future<void> startAppInstallTracking() async {
  try {
    final installId = _getOrCreateInstallId();

    await _writeInstallation(
      installId: installId,
      installDetected: _isInstallDetected(),
      isStandalone: _isStandalone(),
    );

    if (!_listenerAttached) {
      _listenerAttached = true;

      html.window.addEventListener('appinstalled', (_) {
        html.window.localStorage[_installedKey] = 'true';
        html.window.localStorage[_installedAtKey] =
            DateTime.now().toUtc().toIso8601String();

        _writeInstallation(
          installId: installId,
          installDetected: true,
          isStandalone: _isStandalone(),
        );
      });
    }
  } catch (error, stackTrace) {
    debugPrint(
      'APP INSTALL TRACKING ERROR: $error\n$stackTrace',
    );
  }
}

String _getOrCreateInstallId() {
  final existing = (html.window.localStorage[_installIdKey] ?? '').trim();

  if (existing.isNotEmpty) {
    return existing;
  }

  final random = Random.secure();

  final generated = 'sf_${DateTime.now().microsecondsSinceEpoch}_'
      '${random.nextInt(999999999)}';

  html.window.localStorage[_installIdKey] = generated;

  return generated;
}

bool _isStandalone() {
  final displayModeStandalone =
      html.window.matchMedia('(display-mode: standalone)').matches;

  final storedInstalled = html.window.localStorage[_installedKey] == 'true';

  return displayModeStandalone || storedInstalled;
}

bool _isInstallDetected() {
  return html.window.localStorage[_installedKey] == 'true' || _isStandalone();
}

String _deviceType() {
  final userAgent = html.window.navigator.userAgent.toLowerCase();
  final width = html.window.screen?.width ?? 0;

  if (userAgent.contains('ipad') ||
      userAgent.contains('tablet') ||
      (userAgent.contains('android') && !userAgent.contains('mobile'))) {
    return 'tablet';
  }

  if (userAgent.contains('mobile') ||
      userAgent.contains('iphone') ||
      userAgent.contains('android') ||
      width < 700) {
    return 'mobile';
  }

  return 'desktop';
}

String _platform() {
  final userAgent = html.window.navigator.userAgent.toLowerCase();

  if (userAgent.contains('android')) return 'Android';

  if (userAgent.contains('iphone') ||
      userAgent.contains('ipad') ||
      userAgent.contains('ipod')) {
    return 'iOS';
  }

  if (userAgent.contains('windows')) return 'Windows';
  if (userAgent.contains('macintosh')) return 'macOS';
  if (userAgent.contains('linux')) return 'Linux';

  return 'Unknown';
}

String _browser() {
  final userAgent = html.window.navigator.userAgent.toLowerCase();

  if (userAgent.contains('edg/')) return 'Edge';
  if (userAgent.contains('opr/') || userAgent.contains('opera')) {
    return 'Opera';
  }

  if (userAgent.contains('firefox')) return 'Firefox';

  if (userAgent.contains('chrome') || userAgent.contains('crios')) {
    return 'Chrome';
  }

  if (userAgent.contains('safari')) return 'Safari';

  return 'Unknown';
}

Future<void> _writeInstallation({
  required String installId,
  required bool installDetected,
  required bool isStandalone,
}) async {
  final user = FirebaseAuth.instance.currentUser;

  if (user == null) {
    debugPrint(
      'APP INSTALL TRACKING SKIPPED: Firebase user bulunamadı.',
    );
    return;
  }

  final reference =
      FirebaseFirestore.instance.collection('appInstallations').doc(installId);

  final existing = await reference.get();

  final data = <String, dynamic>{
    'installId': installId,
    'deviceType': _deviceType(),
    'platform': _platform(),
    'browser': _browser(),
    'source': 'web_pwa',
    'installDetected': installDetected,
    'isStandalone': isStandalone,
    'installedAt': html.window.localStorage[_installedAtKey] ?? '',
    'userUid': user.uid,
    'isAnonymous': user.isAnonymous,
    'lastSeenAt': FieldValue.serverTimestamp(),
    'launchCount': FieldValue.increment(1),
    'updatedAt': FieldValue.serverTimestamp(),
  };

  if (!existing.exists) {
    data['firstSeenAt'] = FieldValue.serverTimestamp();
    data['createdAt'] = FieldValue.serverTimestamp();
  }

  await reference.set(
    data,
    SetOptions(merge: true),
  );
  debugPrint(
    'APP INSTALL TRACKED '
    'installId=$installId '
    'device=${data['deviceType']} '
    'platform=${data['platform']} '
    'installed=$installDetected '
    'standalone=$isStandalone',
  );
}
