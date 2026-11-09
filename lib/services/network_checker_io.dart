import 'dart:io';

Future<bool> checkNetworkConnection() async {
  // During flutter test runs, default to online unless explicitly mocked
  if (Platform.environment.containsKey('FLUTTER_TEST')) {
    return true;
  }

  try {
    final result = await InternetAddress.lookup('example.com')
        .timeout(const Duration(seconds: 2));
    return result.isNotEmpty && result[0].rawAddress.isNotEmpty;
  } catch (_) {
    return false;
  }
}
