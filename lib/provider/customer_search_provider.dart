import 'package:flutter_riverpod/flutter_riverpod.dart';

// Holds the search query text for products
final customerSearchQueryProvider = StateProvider<String>((ref) => '');
