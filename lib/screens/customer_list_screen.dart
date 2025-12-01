// customer_list_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../provider/customer_provider.dart';
import 'customer_creation_screen.dart';

class CustomerListScreen extends ConsumerWidget {
  const CustomerListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Watch the main customer list provider
    final customersAsyncValue = ref.watch(customerListProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Customer Management 👥'),
        actions: [
          // Basic search bar integration
          SizedBox(
            width: 150,
            child: Padding(
              padding: const EdgeInsets.only(right: 8.0),
              child: TextFormField(
                initialValue: ref.watch(customerSearchProvider),
                decoration: const InputDecoration(
                  hintText: 'Search...',
                  border: InputBorder.none,
                  prefixIcon: Icon(Icons.search, size: 20),
                ),
                onChanged: (value) {
                  // Update search term, which triggers a list refresh
                  ref.read(customerSearchProvider.notifier).state = value;
                  // Reset to page 1 for new search
                  ref.read(customerPageProvider.notifier).state = 1;
                },
              ),
            ),
          ),
        ],
      ),
      body: customersAsyncValue.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(
          child: Text('Error: ${err.toString()}\n\nPull to retry.'),
        ),
        data: (customers) {
          if (customers.isEmpty) {
            return Center(
                child: Text(
                    'No customers found for "${ref.watch(customerSearchProvider)}".'));
          }

          return RefreshIndicator(
            // Refreshing invalidates the provider, forcing a reload
            onRefresh: () => ref.refresh(customerListProvider.future),
            child: ListView.builder(
              itemCount: customers.length,
              itemBuilder: (context, index) {
                final customer = customers[index];
                return ListTile(
                  title: Text(customer.name),
                  subtitle: Text(
                      '${customer.email} | Phone: ${customer.phone}'),
                  trailing: Text(customer.status),
                );
              },
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        label: const Text('New Customer'),
        icon: const Icon(Icons.person_add),
        onPressed: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => const CustomerCreationScreen(),
            ),
          );
        },
      ),
    );
  }
}