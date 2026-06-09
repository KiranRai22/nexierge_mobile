import 'package:flutter/foundation.dart';

import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_endpoints.dart';
import '../../domain/models/catalog.dart';
import '../dtos/universal_request_order_dto.dart';

class UniversalRequestService {
  const UniversalRequestService(this._dio);

  final Dio _dio;

  static const String _endpoint =
      '${APIEndpoints.baseUrl}/api:dYUIxfaq/universal_requests/order/create';

  static const String _allByHotelEndpoint =
      '${APIEndpoints.baseUrl}/api:dYUIxfaq/universal_requests/all';

  /// Fetch the full universal catalog (departments + their requests) for
  /// the given hotel. Returns the raw decoded list straight from the API
  /// so the cache can persist the canonical payload — locale resolution
  /// happens later in the provider.
  Future<List<dynamic>> fetchCatalogByHotel(String hotelId) async {
    final url = '$_allByHotelEndpoint/$hotelId';
    try {
      final response = await _dio.get(
        url,
        options: Options(headers: {'accept': 'application/json'}),
      );
      final status = response.statusCode ?? 0;
      if (status < 200 || status >= 300) {
        throw Exception('Catalog fetch failed: $status');
      }
      final data = response.data;
      if (data is List) return data;
      if (data is String) {
        final decoded = jsonDecode(data);
        if (decoded is List) return decoded;
      }
      throw Exception('Unexpected catalog response format');
    } on DioException catch (e) {
      throw _mapDioError(e);
    }
  }

  /// Create a universal request order. Takes a domain
  /// [UniversalOrderSubmission] — the wire DTOs are built here so the
  /// presentation controller never has to reach for `OrderItemDto`.
  Future<UniversalRequestOrderResponseDto> createOrder({
    required UniversalOrderSubmission submission,
  }) async {
    try {
      debugPrint('[UniversalRequestService] Creating order at: $_endpoint');

      final orderItems = submission.items
          .map(
            (i) => OrderItemDto(
              activeUniversalRequestId: i.itemId,
              guestNotes: submission.notes.trim(),
              price: 0.0,
              quantity: i.quantity,
              itemName: i.itemName,
            ),
          )
          .toList(growable: false);

      final orderRequest = UniversalRequestOrderDto(
        guestStayId: submission.guestStayId,
        contactId: submission.contactId,
        hotelId: submission.hotelId,
        orderItems: orderItems,
      );

      debugPrint(
        '[UniversalRequestService] Payload: ${jsonEncode(orderRequest.toJson())}',
      );

      final response = await _dio.post(
        _endpoint,
        data: orderRequest.toJson(),
        options: Options(
          headers: {
            'accept': 'application/json',
            'Content-Type': 'application/json',
          },
        ),
      );

      debugPrint(
        '[UniversalRequestService] Response status: ${response.statusCode}',
      );
      debugPrint('[UniversalRequestService] Response data: ${response.data}');

      final data = response.data;
      final status = response.statusCode ?? 0;

      if (status < 200 || status >= 300) {
        final serverMessage = data is Map
            ? (data['message'] ?? data['error'])?.toString()
            : null;
        throw Exception(
          'Request failed: $status ${serverMessage ?? ''}'.trim(),
        );
      }

      if (data == null) {
        throw Exception(
          'API returned null response (status: ${response.statusCode})',
        );
      }

      // API can return either:
      // 1. List of ticket IDs: ["ticket-id-1", "ticket-id-2", ...]
      // 2. Map with ticket details: {id: "...", status: "...", created_at: "..."}
      if (data is List && data.isNotEmpty) {
        // List response - treat first ID as the main ticket ID
        final ticketId = data.first.toString();
        debugPrint('[UniversalRequestService] List response with ${data.length} ticket(s), using first: $ticketId');
        return UniversalRequestOrderResponseDto(
          id: ticketId,
          status: 'created',
          createdAt: DateTime.now(),
        );
      }

      Map<String, dynamic> jsonData;
      if (data is String) {
        try {
          final decoded = jsonDecode(data);
          if (decoded is List && decoded.isNotEmpty) {
            return UniversalRequestOrderResponseDto(
              id: decoded.first.toString(),
              status: 'created',
              createdAt: DateTime.now(),
            );
          }
          jsonData = decoded as Map<String, dynamic>;
        } catch (e) {
          throw Exception('Failed to parse JSON response: $e');
        }
      } else if (data is Map<String, dynamic>) {
        jsonData = data;
      } else {
        throw Exception('Unexpected response format: ${data.runtimeType}');
      }

      return UniversalRequestOrderResponseDto.fromJson(jsonData);
    } on DioException catch (e) {
      debugPrint('[UniversalRequestService] DioException: ${e.type}');
      debugPrint('[UniversalRequestService] DioException response: ${e.response}');
      debugPrint('[UniversalRequestService] DioException data: ${e.response?.data}');
      throw _mapDioError(e);
    }
  }

  Exception _mapDioError(DioException e) {
    switch (e.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return Exception('Request timeout');
      case DioExceptionType.badResponse:
        final statusCode = e.response?.statusCode;
        if (statusCode == 401) {
          return Exception('Unauthorized - token expired');
        } else if (statusCode == 403) {
          return Exception('Forbidden - insufficient permissions');
        } else if (statusCode == 404) {
          return Exception('Endpoint not found');
        } else if (statusCode != null && statusCode >= 500) {
          return Exception('Server error');
        }
        return Exception('Request failed: ${statusCode ?? 'unknown'}');
      case DioExceptionType.cancel:
        return Exception('Request cancelled');
      case DioExceptionType.unknown:
        if (e.error?.toString().contains('SocketException') == true) {
          return Exception('No internet connection');
        }
        return Exception('Unknown error occurred');
      default:
        return Exception('Unexpected error');
    }
  }
}

/// Riverpod provider for UniversalRequestService
final universalRequestServiceProvider = Provider<UniversalRequestService>((
  ref,
) {
  final dio = ref.watch(authedDioProvider);
  return UniversalRequestService(dio);
});
