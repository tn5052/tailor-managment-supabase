import 'package:flutter/material.dart';
import '../widgets/responsive_layout.dart';
import 'customer_screen.dart';
import 'measurement_screen.dart';
import 'invoice_screen.dart';
import 'settings_screen.dart';
import 'complaints_screen.dart';
import 'inventory_screen.dart'; // Add new import

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;

  final _screens = [
    // const DashboardScreen(),
    const InventoryScreen(),
    const CustomerListScreen(),
    const MeasurementListScreen(),
    InvoiceListScreen(),
    const ComplaintsScreen(),
    const InventoryScreen(), // Add inventory screen
    const SettingsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return ResponsiveLayout(
      mobileBody: _buildMobileLayout(),
      desktopBody: _buildDesktopLayout(),
    );
  }

  Widget _buildMobileLayout() {
    return Scaffold(
      body: _screens[_selectedIndex],
      bottomNavigationBar: MobileBottomNav(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
      ),
    );
  }

  Widget _buildDesktopLayout() {
    return Scaffold(
      body: Row(
        children: [
          SideMenu(
            selectedIndex: _selectedIndex,
            onDestinationSelected: (index) {
              setState(() {
                _selectedIndex = index;
              });
            },
          ),
          // Removing the VerticalDivider
          Expanded(child: _screens[_selectedIndex]),
        ],
      ),
    );
  }
}
