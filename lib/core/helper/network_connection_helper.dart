import 'dart:developer';
import 'dart:io';

class NetworkUtils {
  /// Checks both connectivity & actual internet access
  static Future<bool> hasInternet() async {
    try {
      final result = await InternetAddress.lookup('google.com')
          .timeout(const Duration(seconds: 3));
      if (result.isNotEmpty && result[0].rawAddress.isNotEmpty) {

        log('connected to the internet');
        return true; // ✅ internet works
      }
    } catch (_) {
      log('no internet connection');
      return false;
    }
    return false;
  }
}
          