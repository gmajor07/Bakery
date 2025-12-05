class InvalidTokenException implements Exception {
  final String message;
  InvalidTokenException([
    this.message = "Session expired. Please log in again.",
  ]);

  @override
  String toString() => message;
}

class NetworkException implements Exception {
  final String message;
  NetworkException([this.message = "Network error occurred."]);

  @override
  String toString() => message;
}

class AuthException implements Exception {
  final String message;
  AuthException([this.message = "Authentication error occurred."]);

  @override
  String toString() => message;
}

class ServerException implements Exception {
  final String message;
  ServerException([this.message = "Server error occurred."]);

  @override
  String toString() => message;
}
