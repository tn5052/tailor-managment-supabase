import 'package:flutter/material.dart';
import '../models/customer_filter.dart';
import '../widgets/customer/customer_mobile_view.dart';
import '../widgets/customer/customer_desktop_view.dart';

class CustomerListScreen extends StatefulWidget {
  const CustomerListScreen({super.key});

  @override
  State<CustomerListScreen> createState() => _CustomerListScreenState();
}

class _CustomerListScreenState extends State<CustomerListScreen> {
  CustomerFilter _filter = const CustomerFilter();

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final bool isDesktop = constraints.maxWidth >= 1024;

        if (isDesktop) {
          return CustomerDesktopView(
            filter: _filter,
            onFilterChanged: (newFilter) {
              if (mounted) {
                setState(() => _filter = newFilter);
              }
            },
          );
        } else {
          return CustomerMobileView(
            filter: _filter,
            onFilterChanged: (newFilter) {
              if (mounted) {
                setState(() => _filter = newFilter);
              }
            },
          );
        }
      },
    );
  }
}
