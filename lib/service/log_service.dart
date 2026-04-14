import 'dart:convert';
import 'dart:io';

import 'package:flutter/widgets.dart';
import 'package:niemyetdientu/service/base.dart';

/// Service to send logs to a remote logging endpoint.
///
/// Usage:
/// final ok = await LogService(baseUrl: 'https://your.server.com').sendLog(logMap);
/// This method always returns `true` on error so it cannot block caller logic.
class LogService {
  /// If your app sets a global logging endpoint, assign it here so callers
  /// can use `LogService.send(...)` without passing `baseUrl` each time.
  static String defaultBaseUrl = '';

  /// Instance base URL used when sending logs. Will be resolved from the
  /// constructor parameter, `defaultBaseUrl`, or finally `BaseService.logApi`.
  final String baseUrl;

  LogService({String? baseUrl}) : baseUrl = baseUrl ?? defaultBaseUrl;

  /// Sends [logData] to `/api/logs/{projectId}/create`.
  ///
  /// Guarantees to return `true` even if the network call fails or throws,
  /// so callers can continue their normal flow without depending on logging.
  Future<bool> sendLog(Map<String, dynamic> logData) async {
    try {
      final effectiveBase = baseUrl.isNotEmpty ? baseUrl : BaseService.logApi;
      final uri = Uri.parse(
        '$effectiveBase/logs/${BaseService.projectId}/create',
      );
      debugPrint('LogService.sendLog sending to $uri: $logData');

      final client = HttpClient();
      final request = await client.postUrl(uri);
      request.headers.contentType = ContentType.json;
      request.write(jsonEncode(logData));

      final response = await request.close();

      if (response.statusCode >= 200 && response.statusCode < 300) {
        return true;
      }

      // Non-2xx responses are not fatal for the caller. Log for debugging.
      final body = await response.transform(utf8.decoder).join();
      debugPrint(
        'LogService.sendLog non-2xx: ${response.statusCode} body=$body',
      );
      return true;
    } catch (e, st) {
      // Never throw — always return true so the main flow is unaffected.
      debugPrint('LogService.sendLog error: $e\n$st');
      return true;
    }
  }

  /// Convenience static wrapper when you prefer one-shot usage.
  /// Falls back to `defaultBaseUrl` then `BaseService.logApi`.
  static Future<bool> send(Map<String, dynamic> logData, {String? baseUrl}) {
    final url = baseUrl ?? defaultBaseUrl;
    if (url.isEmpty && BaseService.logApi.isEmpty) {
      // No remote configured — print locally and return true so caller isn't blocked.
      debugPrint(
        'LogService: no baseUrl configured, skip network. Log: $logData',
      );
      return Future.value(true);
    }

    // Construct LogService with resolved base (may be empty, sendLog will fallback to BaseService.logApi)
    return LogService(baseUrl: url).sendLog(logData);
  }
}
