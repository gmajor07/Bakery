import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/material_receipt.dart';
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
      // normalize to a list
      List<dynamic> list = [];
      if (raw is List) {
        list = raw;
      } else if (raw is Map<String, dynamic>) {
        if (raw['goodsReceipts'] is List) {
          list = raw['goodsReceipts'];
        } else if (raw['data'] is List) {
          list = raw['data'];
        } else if (raw['goods_receipts'] is List) {
          list = raw['goods_receipts'];
        }
      }

      return list.map((e) {
        if (e is Map<String, dynamic>) return MaterialReceipt.fromJson(e);
        if (e is Map) {
          return MaterialReceipt.fromJson(Map<String, dynamic>.from(e));
        }
        return MaterialReceipt.fromJson({});
      }).toList();
    } on DioException catch (e) {
      final msg = e.response?.data?['message'] ?? 'Failed to fetch receipts';
      throw Exception(msg);
    } catch (e) {
      throw Exception('Error fetching receipts: $e');
    }
  }

  /// Fetch single receipt detail (preferred if items are not returned in list)
  Future<MaterialReceipt> fetchReceiptDetail(int id) async {
    final token = await ref.read(authProvider.notifier).getAccessToken();
    if (token == null) throw Exception('Token not found');

    try {
      final response = await _dio.get(
        '/purchases/receiving/$id',
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );

      final raw = response.data;
      if (raw is Map<String, dynamic>) {
        // raw might have { goodsReceipt: {...} } or { data: {...} } or {...}
        final record = raw['goodsReceipt'] ?? raw['data'] ?? raw;
        if (record is Map<String, dynamic>) {
          return MaterialReceipt.fromJson(record);
        } else {
          throw Exception('Unexpected receipt detail format');
        }
      } else {
        throw Exception('Unexpected receipt detail format');
      }
    } on DioException catch (e) {
      final msg =
          e.response?.data?['message'] ?? 'Failed to fetch receipt detail';
      throw Exception(msg);
    } catch (e) {
      throw Exception('Error fetching receipt detail: $e');
    }
  }
}
