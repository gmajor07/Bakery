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
  Future<MaterialReceipt> fetchReceiptDetail(int receiptId) async {
    final token = await ref.read(authProvider.notifier).getAccessToken();
    if (token == null) throw Exception('Token not found');

    try {
      // 1️⃣ Get the goods receipt first
      final receiptResp = await _dio.get(
        '/purchases/receiving',
        queryParameters: {'id': receiptId},
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );

      Map<String, dynamic> receiptData = {};
      if (receiptResp.data is Map<String, dynamic>) {
        if (receiptResp.data['goodsReceipts'] is List &&
            receiptResp.data['goodsReceipts'].isNotEmpty) {
          receiptData = receiptResp.data['goodsReceipts'][0];
        } else if (receiptResp.data['data'] is Map<String, dynamic>) {
          receiptData = receiptResp.data['data'];
        }
      }

      // 2️⃣ Fetch purchase order to get items
      final purchaseOrderId = receiptData['purchaseOrderId'];
      final poResp = await _dio.get(
        '/purchases/orders/$purchaseOrderId',
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );

      Map<String, dynamic> poData = {};
      if (poResp.data is Map<String, dynamic>) {
        poData = poResp.data;
      }

      // Merge purchase order items into receipt
      List<dynamic> rawItems = poData['items'] ?? [];
      // Fetch item names for each item

      List<OrderedItem> items = await Future.wait(
        rawItems.map((e) async {
          final map = Map<String, dynamic>.from(e);
          final item = OrderedItem.fromJson(map);

          final inventoryId = map['inventoryItemId'];
          if (inventoryId == null) return item; // fallback if no ID

          final id = int.tryParse(inventoryId.toString()) ?? 0; // safe parsing
          if (id == 0) return item;

          try {
            final resp = await _dio.get(
              '/inventory/items/$id',
              options: Options(headers: {'Authorization': 'Bearer $token'}),
            );
            final data = resp.data as Map<String, dynamic>? ?? {};
            return OrderedItem(
              id: item.id,
              name: data['name'] ?? '',
              quantity: item.quantity,
              unitPrice: item.unitPrice,
              total: item.total,
              unit: data['unit'] ?? item.unit,
            );
          } catch (_) {
            // fallback if item fetch fails
            return item;
          }
        }),
      );

      receiptData['items'] = items
          .map(
            (e) => {
              'id': e.id,
              'name': e.name,
              'quantity': e.quantity,
              'unitPrice': e.unitPrice,
              'total': e.total,
              'unit': e.unit,
            },
          )
          .toList();

      // Add supplier name if missing
      if (receiptData['supplierName'] == null &&
          poData['supplier'] != null &&
          poData['supplier']['name'] != null) {
        receiptData['supplierName'] = poData['supplier']['name'];
      }

      // Add receivedBy from createdByName
      if (receiptData['receivedBy'] == null &&
          receiptData['createdByName'] != null) {
        receiptData['receivedBy'] = receiptData['createdByName'];
      }

      return MaterialReceipt.fromJson(receiptData);
    } on DioException catch (e) {
      final msg =
          e.response?.data?['message'] ?? 'Failed to fetch receipt detail';
      throw Exception(msg);
    } catch (e) {
      throw Exception('Error fetching receipt detail: $e');
    }
  }
}
