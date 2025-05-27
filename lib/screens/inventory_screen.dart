import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

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
      // Return desktop view with appropriate scaffolding
      return Scaffold(
        backgroundColor: const Color(0xFF1A1C1E),
        appBar: AppBar(
          backgroundColor: const Color(0xFF1A1C1E),
          elevation: 0,
          leading: BackButton(color: Colors.white),
          title: Text(
            'Inventory Management',
            style: GoogleFonts.inter(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
        ),
        body: InventoryDesktopView(
          inventoryType: _currentInventoryType,
          onTypeChanged: (type) {
            setState(() => _currentInventoryType = type);
          },
        ),
      );
    }
  }
}
