import 'package:flutter/material.dart';
import '../widgets/responsive_layout.dart';
import 'customer_list_screen.dart';
import 'measurement_list_screen.dart';
import 'invoice_list_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;

  final _screens = [
    const CustomerListScreen(),
    const MeasurementListScreen(),
    InvoiceListScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return ResponsiveLayout(
      mobileBody: Scaffold(
        body: _screens[_selectedIndex],
        bottomNavigationBar: MobileBottomNav(
          selectedIndex: _selectedIndex,
          onDestinationSelected: (index) {
            setState(() {
              _selectedIndex = index;
            });
          },
        ),
      ),
      desktopBody: Scaffold(
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
            const VerticalDivider(thickness: 1, width: 1),
            Expanded(
              child: _screens[_selectedIndex],
            ),
          ],
        ),
      ),
    );
  }
}
