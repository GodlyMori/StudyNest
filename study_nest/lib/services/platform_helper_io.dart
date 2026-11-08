import 'dart:io';

bool isNativeNotificationSupported() {
  try {
    if (Platform.environment.containsKey('FLUTTER_TEST')) return false;
    return Platform.isAndroid || Platform.isIOS || Platform.isMacOS || Platform.isLinux;
  } catch (_) {
    return false;
  }
}
