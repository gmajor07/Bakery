import 'package:flutter_riverpod/flutter_riverpod.dart';

// Holds the search query text for materials
final materialSearchQueryProvider = StateProvider<String>((ref) => '');
