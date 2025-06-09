import 'package:flutter/material.dart';
import '../widgets/inventory/inventory_mobile_view.dart';
import '../widgets/inventory/inventory_desktop_view.dart';

class InventoryScreen extends StatefulWidget {
  const InventoryScreen({super.key});

  @override
  State<InventoryScreen> createState() => _InventoryScreenState();
}

class _InventoryScreenState extends State<InventoryScreen> {
  String _currentInventoryType = 'fabric'; // Initial type

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 768;

    if (isMobile) {
      // Return mobile view directly
      return InventoryMobileView(
        inventoryType: _currentInventoryType,
        onTypeChanged: (type) {
          setState(() => _currentInventoryType = type);
        },
      );
    } else {
      // Return desktop view without app bar
      return InventoryDesktopView(
        inventoryType: _currentInventoryType,
        onTypeChanged: (type) {
          setState(() => _currentInventoryType = type);
        },
      );
    }
  }
}
