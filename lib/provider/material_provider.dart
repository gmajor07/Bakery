import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/materials.dart';
import '../services/materials_api_services.dart';

/// Provides access to the Material API service
final materialsApiServiceProvider = Provider<MaterialApiService>((ref) {
  return MaterialApiService(ref);
});

/// A notifier that handles creating and fetching materials
class MaterialsNotifier extends StateNotifier<AsyncValue<List<MaterialItem>>> {
  final Ref ref;
  int _page = 1;

  MaterialsNotifier(this.ref) : super(const AsyncValue.loading()) {
    fetchMaterials(); // Load immediately when created
  }

  Future<void> fetchMaterials({int page = 1}) async {
    _page = page;
    final service = ref.read(materialsApiServiceProvider);

    try {
      state = const AsyncValue.loading();
      final materials = await service.fetchMaterial(page: _page);
      state = AsyncValue.data(materials);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> createMaterial({
    required String name,
    required String type,
    required String unit,
    required double currentQuantity,
    required int minLevel,
    // ⭐ NEW: maxLevel parameter is now explicitly required in the notifier
    required int maxLevel,
    required double cost,
  }) async {
    final service = ref.read(materialsApiServiceProvider);

    try {
      final newMaterial = await service.createMaterial(
        name: name,
        type: type,
        unit: unit,
        currentQuantity: currentQuantity,
        minLevel: minLevel,
        // ⭐ UPDATED: Pass maxLevel to the service method
        maxLevel: maxLevel,
        cost: cost,
      );

      // ✅ Append to the current list without refetching
      state.whenData((materials) {
        final updatedList = [...materials, newMaterial];
        state = AsyncValue.data(updatedList);
      });
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }
}

/// Riverpod provider for the materials notifier
final materialsProvider =
    StateNotifierProvider<MaterialsNotifier, AsyncValue<List<MaterialItem>>>(
      (ref) => MaterialsNotifier(ref),
    );
