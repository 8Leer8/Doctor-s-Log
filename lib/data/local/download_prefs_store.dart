import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Download preferences, plus the "am I on mobile data?" check the download
/// queue uses.
class DownloadPrefsStore {
  static const String _kWifiOnly = 'download_wifi_only_v1';

  /// When true, queued downloads wait while the phone is on mobile data.
  static final ValueNotifier<bool> wifiOnly = ValueNotifier<bool>(false);

  static Future<void> load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      wifiOnly.value = prefs.getBool(_kWifiOnly) ?? false;
    } catch (_) {}
  }

  static Future<void> setWifiOnly(bool value) async {
    wifiOnly.value = value;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_kWifiOnly, value);
    } catch (_) {}
  }

  /// "Mobile data only" = mobile is active and neither Wi-Fi nor Ethernet
  /// is. A VPN on its own is not treated as mobile, so we never block
  /// downloads by mistake when we can't tell what is underneath it.
  static bool _isMobileOnly(List<ConnectivityResult> results) =>
      results.contains(ConnectivityResult.mobile) &&
      !results.contains(ConnectivityResult.wifi) &&
      !results.contains(ConnectivityResult.ethernet);

  static Future<bool> isMobileOnly() async {
    try {
      return _isMobileOnly(await Connectivity().checkConnectivity());
    } catch (_) {
      return false;
    }
  }

  /// Emits whenever the connection type changes.
  static Stream<bool> get mobileOnlyChanges =>
      Connectivity().onConnectivityChanged.map(_isMobileOnly);

  /// False only when "Wi-Fi only" is on AND the phone is on mobile data.
  static Future<bool> canDownloadNow() async {
    if (!wifiOnly.value) return true;
    return !(await isMobileOnly());
  }
}
