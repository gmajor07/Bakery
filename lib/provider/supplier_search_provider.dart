// lib/provider/supplier_search_provider.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';

// StateProvider to hold the text entered in the search field
final supplierSearchQueryProvider = StateProvider<String>((ref) => '');