import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../auth/auth_provider.dart';
import 'base_api_service.dart';

final receivingApiServiceProvider = Provider<ReceivingApiService>((ref) {
  return ReceivingApiService(ref);
});

class ReceivingApiService {
  final Ref ref;
  late final Dio _dio;

  ReceivingApiService(this.ref) {
    final baseService = BaseApiService(ref);
    _dio = baseService.dio;
  }

  Future<void> approveOrder(int orderId) async {
    final token = await ref.read(authProvider.notifier).getAccessToken();
    await _dio.post(
      '/purchases/orders/$orderId/approve',
      options: Options(headers: {'Authorization': 'Bearer $token'}),
    );
  }

  Future<void> cancelOrder(int orderId) async {
    final token = await ref.read(authProvider.notifier).getAccessToken();
    await _dio.post(
      '/purchases/orders/$orderId/cancel',
      options: Options(headers: {'Authorization': 'Bearer $token'}),
    );
  }

  Future<void> receiveGoods({
    required int orderId,
    required List<Map<String, dynamic>> items,
    String? notes,
  }) async {
    final token = await ref.read(authProvider.notifier).getAccessToken();
    await _dio.post(
      '/purchases/receiving',
      options: Options(headers: {'Authorization': 'Bearer $token'}),
      data: {
        "purchaseOrderId": orderId,
        "notes": notes ?? '',
        "items": items,
      },
    );
  }
}
