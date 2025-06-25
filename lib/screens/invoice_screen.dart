import 'package:flutter/material.dart';
import '../utils/responsive.dart';
import '../widgets/invoice/invoice_desktop_view.dart';

class InvoiceScreen extends StatelessWidget {
  const InvoiceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Responsive.isDesktop(context)
          ? const InvoiceDesktopView()
          : _buildMobileView(),
    );
  }

  Widget _buildMobileView() {
    return const Center(
      child: Text(
        'Mobile view under development',
        style: TextStyle(fontSize: 16),
      ),
    );
  }
}
