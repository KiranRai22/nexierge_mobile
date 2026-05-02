import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_endpoints.dart';
import '../dtos/universal_request_order_dto.dart';

class UniversalRequestService {
  const UniversalRequestService(this._dio);

  final Dio _dio;

  static const String _endpoint =
      '${APIEndpoints.baseUrl}/api:dYUIxfaq/universal_requests/order/create';

  /// Create a universal request order
  Future<UniversalRequestOrderResponseDto> createOrder({
    required String guestStayId,
    required String contactId,
    required String hotelId,
    required List<OrderItemDto> orderItems,
  }) async {
    try {
      print('[UniversalRequestService] Creating order at: $_endpoint');
      
      final orderRequest = UniversalRequestOrderDto(
        guestStayId: guestStayId,
        contactId: contactId,
        hotelId: hotelId,
        orderItems: orderItems,
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

      print('[UniversalRequestService] Response status: ${response.statusCode}');
      print('[UniversalRequestService] Response data: ${response.data}');

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

      Map<String, dynamic> jsonData;
      if (data is String) {
        try {
          jsonData = jsonDecode(data) as Map<String, dynamic>;
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
      print('[UniversalRequestService] DioException: ${e.type}');
      print('[UniversalRequestService] DioException response: ${e.response}');
      print('[UniversalRequestService] DioException data: ${e.response?.data}');
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
final universalRequestServiceProvider = Provider<UniversalRequestService>((ref) {
  final dio = ref.watch(authedDioProvider);
  return UniversalRequestService(dio);
});
