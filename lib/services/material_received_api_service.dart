import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/material_received.dart';
import '../auth/auth_provider.dart';
import 'base_api_service.dart';

// ⭐️ Define a model for the API response to handle pagination metadata
class MaterialReceiptResponse {
  final List<MaterialReceipt> receipts;
  final int totalRecords;

  MaterialReceiptResponse({required this.receipts, required this.totalRecords});
}

class MaterialApiService {
  final Ref ref;
  late final Dio _dio;

  MaterialApiService(this.ref) {
    _dio = BaseApiService(ref).dio;
  }

  /// Fetch paginated materials received
  Future<MaterialReceiptResponse> fetchReceipts({
    int page = 1,
    int limit = 15,
    String? status,
    String? startDate,
    String? endDate,
    String? search,
  }) async {
    final token = await ref.read(authProvider.notifier).getAccessToken();
    if (token == null) throw Exception('Token not found');

    try {
      if (kDebugMode) {
        print(
          'Fetching materials received with page: $page, limit: $limit, search: $search',
        );
      }
      final response = await _dio.get(
        '/purchases/receiving',
        queryParameters: {
          'page': page,
          'limit': limit,
          if (status != null && status.isNotEmpty) 'status': status,
          if (startDate != null) 'startDate': startDate,
          if (endDate != null) 'endDate': endDate,
          if (search != null && search.isNotEmpty) 'search': search,
        },
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );

      final raw = response.data;
      if (kDebugMode) {
        print('Response data type: ${raw.runtimeType}, data: $raw');
      }
      List<dynamic> list = [];
      int totalRecords = 0;

      if (raw is Map<String, dynamic>) {
        // Check for common API response structures - prioritize goodsReceipts
        if (raw['goodsReceipts'] is List) {
          list = raw['goodsReceipts'];
          totalRecords =
              raw['totalCount'] ?? raw['totalRecords'] ?? list.length;
        } else if (raw['materialsReceived'] is List) {
          list = raw['materialsReceived'];
          totalRecords =
              raw['totalCount'] ?? raw['totalRecords'] ?? list.length;
        } else if (raw['data'] is List) {
          list = raw['data'];
          totalRecords =
              raw['totalCount'] ?? raw['totalRecords'] ?? list.length;
        } else if (raw['receipts'] is List) {
          list = raw['receipts'];
          totalRecords =
              raw['totalCount'] ?? raw['totalRecords'] ?? list.length;
        } else {
          // Fallback: assume the entire response is the list
          list = raw.values.whereType<List>().expand((v) => v as List).toList();
          totalRecords = list.length;
        }
      } else if (raw is List) {
        list = raw;
        totalRecords = list.length;
      }

      if (kDebugMode) {
        print('Parsed receipts: ${list.length}, totalRecords: $totalRecords');
      }

      if (list.isEmpty) {
        return MaterialReceiptResponse(receipts: [], totalRecords: 0);
      }

      final receipts = list.map((e) {
        try {
          return MaterialReceipt.fromJson(e as Map<String, dynamic>);
        } catch (e) {
          print('Error parsing receipt: $e, data: $e');
          // Return a fallback receipt if parsing fails
          return MaterialReceipt(
            id: 0,
            purchaseOrderId: 0,
            receivedDate: DateTime.now(),
            receivedQuantity: 0,
            status: 'Unknown',
            supplierName: 'Unknown',
            total: 0,
            receivedBy: 'Unknown',
            items: [],
          );
        }
      }).toList();

      return MaterialReceiptResponse(
        receipts: receipts,
        totalRecords: totalRecords,
      );
    } on DioException catch (e) {
      print('DioException: ${e.message}, response: ${e.response?.data}');
      final msg =
          e.response?.data?['message'] ?? 'Failed to fetch materials received';
      throw Exception(msg);
    } catch (e) {
      print('General exception: $e');
      throw Exception('Failed to fetch materials received: $e');
    }
  }

  /// Fetch single receipt detail
  Future<MaterialReceipt> fetchReceiptDetail(int receiptId) async {
    final token = await ref.read(authProvider.notifier).getAccessToken();
    if (token == null) throw Exception('Token not found');

    try {
      print('Fetching receipt detail for ID: $receiptId');

      // Try multiple endpoint patterns
      List<String> endpoints = [
        '/purchases/receiving/$receiptId',
        '/purchases/materials-received/$receiptId',
        '/goods-receipts/$receiptId',
        '/inventory/materials-received/$receiptId',
      ];

      Exception? lastError;

      for (String endpoint in endpoints) {
        try {
          print('Trying endpoint: $endpoint');
          final response = await _dio.get(
            endpoint,
            options: Options(headers: {'Authorization': 'Bearer $token'}),
          );

          print('Response received from $endpoint: ${response.data}');

          final data = response.data is Map<String, dynamic>
              ? response.data
              : (response.data['data'] ?? {});

          // Ensure items array exists
          if (data['items'] == null) {
            data['items'] = [];
          }

          // Ensure each item has a name (from the API)
          if (data['items'] is List) {
            data['items'] = (data['items'] as List)
                .map(
                  (item) => {
                    'name': item['name'] ?? '',
                    'quantity': item['quantity'] ?? 0,
                    'cost': item['cost'] ?? 0,
                    'total': item['total'] ?? 0,
                  },
                )
                .toList();
          }

          print('Parsed detail data: $data');
          return MaterialReceipt.fromJson(data);
        } on DioException catch (e) {
          print(
            'Endpoint $endpoint failed: ${e.message}, status: ${e.response?.statusCode}',
          );
          lastError = e;
          continue; // Try next endpoint
        }
      }

      // If all endpoints failed, throw the last error
      throw lastError ?? Exception('All detail endpoints failed');
    } on DioException catch (e) {
      print(
        'DioException in fetchReceiptDetail: ${e.message}, response: ${e.response?.data}',
      );
      final msg =
          e.response?.data?['message'] ?? 'Failed to fetch receipt detail';
      throw Exception(msg);
    } catch (e) {
      print('General exception in fetchReceiptDetail: $e');
      throw Exception('Failed to fetch receipt detail: $e');
    }
  }
}
