import 'package:flutter/material.dart';
import '../utils/responsive.dart';
import '../widgets/invoice/invoice_desktop_view.dart'; // Import the new desktop view
import '../widgets/invoice/invoice_mobile_view.dart';
class InvoiceScreen extends StatelessWidget {
  const InvoiceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Responsive.isDesktop(context)
          ? const InvoiceDesktopView() // Use the new desktop view
          : _buildMobileView(),
    );
  }

  Widget _buildMobileView() {
    return const InvoiceMobileView();
  }
}
