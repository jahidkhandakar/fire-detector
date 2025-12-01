import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:get_storage/get_storage.dart';
import 'package:http/http.dart' as http;
import '/others/utils/api.dart';
import '/others/errors/app_error_handler.dart';
import 'subscription_model.dart';
import 'subscription_charge_model.dart';
import 'subscription_topup_model.dart';

class SubscriptionService {
  final client = http.Client();
  final GetStorage _box = GetStorage();

  Map<String, String> _headers() {
    final token = _box.read<String>('access');
    final headers = <String, String>{
      'Content-Type': 'application/json',
      if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token',
    };
    debugPrint('🧩 SubscriptionService._headers => $headers');
    return headers;
  }

  // 🔹 GET /subscriptions/me
  Future<List<SubscriptionModel>> fetchSubscriptions() async {
    final uri = Uri.parse('${Api.subscriptionsMe}/');
    debugPrint('➡️ GET $uri');

    try {
      final res = await AppHttp.get(uri, headers: _headers());

      debugPrint(
        '🟢 GET /subscriptions/me → ${res.statusCode}\nBODY: ${res.body}',
      );

      final decoded = jsonDecode(res.body);

      if (decoded is Map<String, dynamic>) {
        final list = (decoded['results'] as List? ?? []);
        return list
            .map((e) => SubscriptionModel.fromJson(
                  Map<String, dynamic>.from(e as Map),
                ))
            .toList();
      } else if (decoded is List) {
        // fallback in case backend returns bare array
        return decoded
            .map((e) => SubscriptionModel.fromJson(
                  Map<String, dynamic>.from(e as Map),
                ))
            .toList();
      }

      return [];
    } on AppException {
      rethrow;
    } catch (e, st) {
      debugPrint('❌ fetchSubscriptions error: $e\n$st');
      throw AppException.from(e, st);
    }
  }

  // 🔹 GET /subscriptions/me/<id>
  Future<SubscriptionModel> fetchSubscriptionDetail(int subscriptionId) async {
    final uri = Uri.parse('${Api.subscriptionsMe}/$subscriptionId/');
    debugPrint('➡️ GET $uri');

    try {
      final res = await AppHttp.get(uri, headers: _headers());

      debugPrint(
        '🟢 GET /subscriptions/me/$subscriptionId → ${res.statusCode}\nBODY: ${res.body}',
      );

      final decoded = jsonDecode(res.body) as Map<String, dynamic>;
      return SubscriptionModel.fromJson(decoded);
    } on AppException {
      rethrow;
    } catch (e, st) {
      debugPrint('❌ fetchSubscriptionDetail error: $e\n$st');
      throw AppException.from(e, st);
    }
  }

  // 🔹 GET /subscriptions/me/<id>/charges/
  Future<List<SubscriptionChargeModel>> fetchCharges(int subscriptionId) async {
    final uri = Uri.parse('${Api.subscriptionsMe}/$subscriptionId/charges/');
    debugPrint('➡️ GET $uri');

    try {
      final res = await AppHttp.get(uri, headers: _headers());

      debugPrint(
        '🟢 GET /subscriptions/me/$subscriptionId/charges/ → ${res.statusCode}\nBODY: ${res.body}',
      );

      final decoded = jsonDecode(res.body) as List;
      return decoded
          .map((e) => SubscriptionChargeModel.fromJson(
                Map<String, dynamic>.from(e as Map),
              ))
          .toList();
    } on AppException {
      rethrow;
    } catch (e, st) {
      debugPrint('❌ fetchCharges error: $e\n$st');
      throw AppException.from(e, st);
    }
  }

  // 🔹 POST /subscriptions/me/<id>/topup/
  Future<SubscriptionTopupResult> topupSubscription({
    required int subscriptionId,
    required int months,
  }) async {
    final uri = Uri.parse('${Api.subscriptionsMe}/$subscriptionId/topup/');
    final body = {'months': months};

    debugPrint('➡️ POST $uri (topup, months=$months)');
    debugPrint('   BODY: ${jsonEncode(body)}');

    http.Response res;
    try {
      res = await client
          .post(
            uri,
            headers: _headers(),
            body: jsonEncode(body),
          )
          .timeout(const Duration(seconds: 20));
    } on SocketException catch (e, st) {
      debugPrint('❌ Network error while POST topup: $e\n$st');
      throw AppException.from(e, st);
    } on TimeoutException catch (e, st) {
      debugPrint('❌ Timeout while POST topup: $e\n$st');
      throw AppException.from(e, st);
    } catch (e, st) {
      debugPrint('❌ Unknown error while POST topup: $e\n$st');
      throw AppException.from(e, st);
    }

    debugPrint(
      '🟢 POST /subscriptions/me/$subscriptionId/topup/ → ${res.statusCode}\nBODY: ${res.body}',
    );

    if (res.statusCode == 200 || res.statusCode == 201) {
      final decoded = jsonDecode(res.body) as Map<String, dynamic>;
      return SubscriptionTopupResult.fromJson(decoded);
    }

    throw _mapStatusToAppException(
      res,
      context: 'Topup failed',
    );
  }

  // 🔧 Map HTTP status → AppException with proper type
  AppException _mapStatusToAppException(
    http.Response res, {
    required String context,
  }) {
    final code = res.statusCode;
    final body = res.body;

    debugPrint('❌ HTTP error $code for "$context": $body');

    if (code == 401) {
      return AppException(
        type: AppErrorType.unauthorized,
        message: '$context (unauthorized): $body',
        raw: res,
      );
    }

    if (code == 404) {
      return AppException(
        type: AppErrorType.notFound,
        message: '$context (not found): $body',
        raw: res,
      );
    }

    if (code >= 500) {
      return AppException(
        type: AppErrorType.server,
        message: '$context (server error $code): $body',
        raw: res,
      );
    }

    return AppException(
      type: AppErrorType.unknown,
      message: '$context (HTTP $code): $body',
      raw: res,
    );
  }
}
