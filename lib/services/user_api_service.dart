import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/user.dart';
import 'base_api_service.dart';

class UserApiService extends BaseApiService {
  UserApiService(super.ref);

  Future<User> getCurrentUser() async {
    final response = await dio.get('/auth/me');
    return User.fromJson(response.data);
  }
}

final userApiServiceProvider = Provider<UserApiService>((ref) {
  return UserApiService(ref);
});
