import 'package:flutter/material.dart';

import '../../models/invoice.dart';
import '../../models/customer.dart';


class InvoiceScreen extends StatefulWidget {
  final Customer? customer;
  final Invoice? invoiceToEdit;

  const InvoiceScreen({
    super.key, 
    this.customer,
    this.invoiceToEdit,
  });

  static Future<void> show(BuildContext context, {Customer? customer, Invoice? invoice}) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktop = screenWidth >= 1024;

    if (isDesktop) {
      return showDialog(
        context: context,
        builder: (context) => Dialog(
          backgroundColor: Colors.transparent,
          child: Container(
            width: screenWidth * 0.60,
            height: MediaQuery.of(context).size.height * 0.9,
            clipBehavior: Clip.antiAlias,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: BorderRadius.circular(28),
            ),
            child: const Center(
              child: Text('Invoice Dialog Content'),
            ),
          ),
        ),
      );
    }

    // Full screen for mobile
    return Navigator.of(context).push(
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (context) => const Scaffold(
          body: Center(
            child: Text('Invoice Dialog Content'),
          ),
        ),
      ),
    );
  }

  @override
  State<InvoiceScreen> createState() => _InvoiceScreenState();
}

class _InvoiceScreenState extends State<InvoiceScreen> {
  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Text('Invoice Dialog Content'),
    );
  }
}
