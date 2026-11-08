import 'network_checker_stub.dart'
    if (dart.library.io) 'network_checker_io.dart'
    if (dart.library.html) 'network_checker_web.dart';

class NetworkService {
  /// Allows unit and widget tests to mock offline mode deterministically
  static bool? mockIsOnline;

  static Future<bool> isOnline() async {
    if (mockIsOnline != null) {
      return mockIsOnline!;
    }
    return checkNetworkConnection();
  }
}
