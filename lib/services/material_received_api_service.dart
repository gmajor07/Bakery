import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/material_received.dart';
import '../auth/auth_provider.dart';
import 'base_api_service.dart';

class MaterialApiService {
  final Ref ref;
  late final Dio _dio;

  MaterialApiService(this.ref) {
    _dio = BaseApiService(ref).dio;
  }

  /// Fetch paginated goods receipts
  Future<List<MaterialReceipt>> fetchReceipts({
    int page = 1,
    int limit = 10,
    String? status,
    String? startDate,
    String? endDate,
    String? search,
  }) async {
    final token = await ref.read(authProvider.notifier).getAccessToken();
    if (token == null) throw Exception('Token not found');

    try {
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
      List<dynamic> list = [];

      if (raw is List) {
        list = raw;
      } else if (raw is Map<String, dynamic>) {
        if (raw['goodsReceipts'] is List) {
          list = raw['goodsReceipts'];
        } else if (raw['data'] is List) {
          list = raw['data'];
        }
      }

      return list.map((e) => MaterialReceipt.fromJson(e)).toList();
    } on DioException catch (e) {
      final msg = e.response?.data?['message'] ?? 'Failed to fetch receipts';
      throw Exception(msg);
    }
  }

  /// Fetch single receipt detail
  Future<MaterialReceipt> fetchReceiptDetail(int receiptId) async {
    final token = await ref.read(authProvider.notifier).getAccessToken();
    if (token == null) throw Exception('Token not found');

    try {
      final response = await _dio.get(
        '/purchases/receiving/$receiptId',
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );

      final data = response.data is Map<String, dynamic>
          ? response.data
          : (response.data['data'] ?? {});

      // ✅ Ensure items array exists
      if (data['items'] == null) {
        data['items'] = [];
      }

      // ✅ Ensure each item has a name (from the API)
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

      return MaterialReceipt.fromJson(data);
    } on DioException catch (e) {
      final msg =
          e.response?.data?['message'] ?? 'Failed to fetch receipt detail';
      throw Exception(msg);
    }
  }
}
