import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../auth/auth_provider.dart';
import '../services/settings_api_service.dart';

final settingsProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  final auth = ref.read(authProvider.notifier);
  final token = await auth.getAccessToken();

  if (token == null || token.isEmpty) {
    throw Exception('Token missing or expired');
  }

  try {
    final api = SettingsApiService(ref);
    return await api.fetchSettings();
  } catch (e) {
    final message = e.toString().toLowerCase();

    if (message.contains('401') ||
        message.contains('unauthorized') ||
        message.contains('token') ||
        message.contains('expired')) {
      // Force logout but keep saved credentials for user to retry
      await auth.logout(clearCredentials: false);
      throw Exception('Token expired or unauthorized');
    }

    rethrow;
  }
});

/// Provider to extract bakery information from settings
final bakeryInfoProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  final settings = await ref.watch(settingsProvider.future);
  return settings['information'] ?? {};
});

/// Provider to extract configuration from settings
final bakeryConfigurationProvider = FutureProvider<Map<String, dynamic>>((
  ref,
) async {
  final settings = await ref.watch(settingsProvider.future);
  return settings['configuration'] ?? {};
});
