import 'package:flutter/material.dart';
import 'inventory_screen.dart';
import 'material_action_screen.dart';
import 'product_screen.dart';

class InventoryActionsScreen extends StatelessWidget {
  const InventoryActionsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isTablet = MediaQuery.of(context).size.width >= 768;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Inventory Management'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        centerTitle: true,
      ),
      body: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Theme.of(context).colorScheme.primaryContainer.withOpacity(0.1),
              Theme.of(context).colorScheme.secondaryContainer.withOpacity(0.1),
            ],
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Section
            const Padding(
              padding: EdgeInsets.only(bottom: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [

                  SizedBox(height: 4),
                  Text(
                    'Manage your inventory items',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
            ),

            // Action Cards - Using ListView for better overflow handling
            Expanded(
              child: isTablet ? _buildTabletLayout(context) : _buildMobileLayout(context),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTabletLayout(BuildContext context) {
    return GridView.count(
      crossAxisCount: 3,
      crossAxisSpacing: 16,
      mainAxisSpacing: 16,
      childAspectRatio: 1.2, // Taller cards for tablet
      children: _buildAllCards(context),
    );
  }

  Widget _buildMobileLayout(BuildContext context) {
    return ListView(
      children: _buildAllCards(context)
          .map((card) => Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: card,
      ))
          .toList(),
    );
  }

  List<Widget> _buildAllCards(BuildContext context) {
    return [
      _buildCard(
        context,
        'Products',
        'Manage finished products',
        Icons.inventory_2_outlined,
        [Colors.green[50]!, Colors.green[100]!],
        Colors.green,
        const ProductsScreen(),
      ),
      _buildCard(
        context,
        'Materials',
        'Manage raw materials',
        Icons.construction_outlined,
        [Colors.blue[50]!, Colors.blue[100]!],
        Colors.blue,
        MaterialActionScreen(),
      ),
      _buildCard(
        context,
        'Supplies',
        'Manage supplies inventory',
        Icons.local_shipping_outlined,
        [Colors.orange[50]!, Colors.orange[100]!],
        Colors.orange,
        const InventoryScreen(),
      ),
    ];
  }

  Widget _buildCard(
      BuildContext context,
      String title,
      String subtitle,
      IconData icon,
      List<Color> gradientColors,
      Color iconColor,
      Widget screen,
      ) {
    return GestureDetector(
      onTap: () {
        Navigator.push(context, MaterialPageRoute(builder: (_) => screen));
      },
      child: Card(
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Container(
          height: 120, // Fixed height to prevent overflow
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: gradientColors,
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // Icon section
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.9),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, size: 28, color: iconColor),
                ),
                const SizedBox(width: 12),
                // Text section
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.blueGrey,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.blueGrey.withOpacity(0.7),
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                // Arrow icon
                Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: 16,
                  color: iconColor,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}