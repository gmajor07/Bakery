import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/materials.dart';
import '../services/materials_api_services.dart';

final materialsApiServiceProvider = Provider<MaterialsApiService>((ref) {
  return MaterialsApiService(ref);
});

final materialsPageProvider = StateProvider<int>((ref) => 1);

final materialsProvider = FutureProvider.autoDispose<List<MaterialItem>>((
  ref,
) async {
  final page = ref.watch(materialsPageProvider);
  final service = ref.watch(materialsApiServiceProvider);
  return await service.fetchMaterials(page: page);
});
