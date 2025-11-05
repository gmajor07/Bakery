class InvalidTokenException implements Exception {
  final String message;
  InvalidTokenException([this.message = "Session expired. Please log in again."]);

  @override
  String toString() => message;
}
