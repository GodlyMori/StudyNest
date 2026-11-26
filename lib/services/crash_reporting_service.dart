import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

/// Crash reporting service backed by Sentry (free tier).
///
/// CRITICAL: SENTRY_DSN must NEVER be hardcoded, stored in repo, or logged.
/// It is passed exclusively at build/run time via:
/// `--dart-define=SENTRY_DSN=https://...@...ingest.sentry.io/...`
class CrashReportingService {
  CrashReportingService._();

  static const String sentryDsn = String.fromEnvironment('SENTRY_DSN', defaultValue: '');

  static bool _isEnabled = false;
  static bool get isEnabled => _isEnabled;

  /// Initialize Sentry crash reporting and capture uncaught Flutter/Dart errors.
  ///
  /// If [dsn] (or SENTRY_DSN) is absent or blank, Sentry runs in disabled / no-op mode
  /// and invokes [appRunner] directly so app startup is never blocked or broken.
  static Future<void> initialize({
    String? dsn,
    FutureOr<void> Function()? appRunner,
  }) async {
    final effectiveDsn = (dsn ?? sentryDsn).trim();

    if (effectiveDsn.isEmpty) {
      debugPrint('SENTRY_DSN not provided via --dart-define. Crash reporting running in no-op mode.');
      _isEnabled = false;
      if (appRunner != null) {
        await appRunner();
      }
      return;
    }

    try {
      await SentryFlutter.init(
        (options) {
          options.dsn = effectiveDsn;
          // Capture 100% of uncaught errors and sample performance traces
          options.tracesSampleRate = 1.0;
          // Report environment context
          options.environment = kReleaseMode ? 'production' : 'development';
        },
        appRunner: appRunner,
      );
      _isEnabled = true;
      debugPrint('Sentry initialized successfully.');
    } catch (e) {
      debugPrint('Failed to initialize Sentry: $e');
      _isEnabled = false;
      if (appRunner != null) {
        await appRunner();
      }
    }
  }

  /// Manually capture handled or caught exceptions to Sentry when active.
  static Future<void> captureException(
    dynamic throwable, {
    dynamic stackTrace,
    dynamic hint,
  }) async {
    if (_isEnabled) {
      await Sentry.captureException(
        throwable,
        stackTrace: stackTrace,
        hint: hint,
      );
    } else {
      debugPrint('CrashReportingService (no-op capture): $throwable');
    }
  }

  /// Close or reset Sentry client (primarily for testing).
  @visibleForTesting
  static Future<void> closeForTesting() async {
    _isEnabled = false;
    await Sentry.close();
  }
}
