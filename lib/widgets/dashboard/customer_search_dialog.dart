import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:io';
import '../../models/customer.dart';
import '../../models/invoice.dart';
import '../../models/measurement.dart';
import '../../models/complaint.dart';
import '../../utils/number_formatter.dart';
import '../../widgets/customer/add_customer_dialog.dart';
import '../../widgets/invoice/invoice_details_dialog.dart';
import '../../widgets/complaint/complaint_detail_dialog.dart';
import '../../widgets/measurement/detail_dialog.dart';
import 'desktop_report_component.dart';
import 'mobile_report_component.dart';

class CustomerSearchDialog extends StatelessWidget {
  final Customer customer;
  final List<Measurement> measurements;
  final List<Invoice> invoices;
  final List<Complaint> complaints;
  final bool isFullScreen;

  const CustomerSearchDialog({
    super.key,
    required this.customer,
    required this.measurements,
    required this.invoices,
    required this.complaints,
    this.isFullScreen = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final size = MediaQuery.of(context).size;
    final isMobile = size.width < 600;

    if (isFullScreen && isMobile) {
      return _buildFullScreenMobile(context);
    }

    // Regular dialog for desktop or non-fullscreen mobile
    return Dialog(
      backgroundColor: theme.colorScheme.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        width: isMobile ? size.width * 0.9 : size.width * 0.7,
        height: size.height * 0.8,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              theme.colorScheme.surface,
              theme.brightness == Brightness.dark 
                ? theme.colorScheme.surface.withAlpha((theme.colorScheme.surface.alpha * 0.95).toInt())
                : Color.lerp(theme.colorScheme.surface, theme.colorScheme.background, 0.1)!,
            ],
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with gradient background
            _buildDesktopHeader(context),
            
            // Content
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: SingleChildScrollView(
                  child: _buildContent(context),
                ),
              ),
            ),
            
            // Footer actions
            _buildDesktopFooter(context),
          ],
        ),
      ),
    );
  }

  Widget _buildDesktopHeader(BuildContext context) {
    final theme = Theme.of(context);
    
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 16, 16, 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            theme.colorScheme.primary,
            theme.colorScheme.primary.withAlpha((theme.colorScheme.primary.alpha * 0.8).toInt()),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 28,
            backgroundColor: Colors.white24,
            child: Text(
              customer.name.isNotEmpty ? customer.name[0].toUpperCase() : '',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  customer.name,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                Text(
                  'Bill #${customer.billNumber} | ${customer.phone}',
                  style: const TextStyle(
                    fontSize: 14,
                    color: Colors.white70,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () => Navigator.of(context).pop(),
            icon: const Icon(Icons.close, color: Colors.white),
          ),
        ],
      ),
    );
  }

  Widget _buildDesktopFooter(BuildContext context) {
    final theme = Theme.of(context);
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      decoration: BoxDecoration(
        color: theme.brightness == Brightness.dark 
            ? theme.colorScheme.surface.withAlpha((theme.colorScheme.surface.alpha * 0.9).toInt())
            : theme.colorScheme.surface,
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(20),
          bottomRight: Radius.circular(20),
        ),
        border: Border(
          top: BorderSide(
            color: theme.colorScheme.onSurface.withAlpha((theme.colorScheme.onSurface.alpha * 0.1).toInt()),
          ),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          _buildActionButton(
            context,
            label: 'Details',
            icon: Icons.person,
            color: theme.colorScheme.primary,
            onPressed: () => _showCustomerDetails(context),
          ),
          const SizedBox(width: 12),
          _buildActionButton(
            context,
            label: 'Measurements',
            icon: Icons.straighten,
            color: Colors.purple,
            onPressed: () => _showMeasurements(context),
          ),
          const SizedBox(width: 12),
          _buildActionButton(
            context,
            label: 'Invoices',
            icon: Icons.receipt_long,
            color: Colors.amber.shade700,
            onPressed: () => _showInvoices(context),
          ),
          const SizedBox(width: 12),
          _buildActionButton(
            context,
            label: 'Complaints',
            icon: Icons.warning_amber,
            color: Colors.red.shade700,
            onPressed: () => _showComplaints(context),
          ),
          const SizedBox(width: 12),
          _buildActionButton(
            context,
            label: 'Full Report',
            icon: Icons.analytics,
            color: Colors.green.shade600,
            onPressed: () => _showFullCustomerReport(context),
          ),
          const Spacer(),
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton(
    BuildContext context, {
    required String label,
    required IconData icon,
    required Color color,
    required VoidCallback onPressed,
  }) {
    final theme = Theme.of(context);
    
    return ElevatedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: 18),
      label: Text(label),
      style: ElevatedButton.styleFrom(
        backgroundColor: theme.brightness == Brightness.dark 
            ? color.withAlpha((color.alpha * 0.2).toInt())
            : color.withAlpha((color.alpha * 0.1).toInt()),
        foregroundColor: color,
        elevation: 0,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      ),
    );
  }

  Widget _buildFullScreenMobile(BuildContext context) {
    final theme = Theme.of(context);
    final mediaQuery = MediaQuery.of(context);
    final bottomPadding = mediaQuery.padding.bottom;
    
    // Define UI colors based on theme
    final backgroundColor = theme.scaffoldBackgroundColor;
    final appBarColor = theme.brightness == Brightness.dark
        ? theme.appBarTheme.backgroundColor ?? theme.colorScheme.surface
        : theme.colorScheme.primary;
    final navBarColor = theme.brightness == Brightness.dark
        ? theme.colorScheme.surface 
        : Colors.white;
    
    // Setup system UI overlay style
    final overlayStyle = theme.brightness == Brightness.dark
        ? SystemUiOverlayStyle.light
        : SystemUiOverlayStyle(
            statusBarColor: Colors.transparent,
            statusBarIconBrightness: Brightness.light,
            systemNavigationBarColor: navBarColor,
            systemNavigationBarIconBrightness: Brightness.dark,
          );

    // Calculate total spent amount for customer summary


    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: overlayStyle,
      child: Scaffold(
        backgroundColor: backgroundColor,
        body: NestedScrollView(
          headerSliverBuilder: (context, innerBoxIsScrolled) => [
            // Collapsing App Bar
            SliverAppBar(
              expandedHeight: 200.0,
              floating: false,
              pinned: true,
              elevation: 0,
              backgroundColor: appBarColor,
              leading: IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.white),
                onPressed: () => Navigator.of(context).pop(),
              ),
              actions: [
                IconButton(
                  icon: const Icon(Icons.edit, color: Colors.white),
                  onPressed: () => _editCustomer(context),
                ),
                IconButton(
                  icon: const Icon(Icons.more_vert, color: Colors.white),
                  onPressed: () => _showMoreOptions(context),
                ),
              ],
              flexibleSpace: FlexibleSpaceBar(
                title: AnimatedOpacity(
                  opacity: innerBoxIsScrolled ? 1.0 : 0.0,
                  duration: const Duration(milliseconds: 200),
                  child: Text(
                    customer.name,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
                background: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        appBarColor,
                        appBarColor.withOpacity(0.8),
                      ],
                    ),
                  ),
                  child: SafeArea(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 40), // Space for app bar
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              CircleAvatar(
                                radius: 30,
                                backgroundColor: Colors.white24,
                                child: Text(
                                  customer.name.isNotEmpty ? customer.name[0].toUpperCase() : '',
                                  style: const TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      customer.name,
                                      style: const TextStyle(
                                        fontSize: 24,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 4,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Colors.white.withOpacity(0.2),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Text(
                                        'Bill #${customer.billNumber}',
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const Spacer(),
                          // Quick action buttons
                          Row(
                            children: [
                              Expanded(
                                child: InkWell(
                                  onTap: () => _makePhoneCall(customer.phone),
                                  child: Row(
                                    children: [
                                      const Icon(
                                        Icons.phone,
                                        color: Colors.white70,
                                        size: 16,
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          customer.phone,
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.w500,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              if (customer.whatsapp.isNotEmpty)
                                IconButton(
                                  icon: const Icon(
                                    FontAwesomeIcons.whatsapp,
                                    color: Colors.white70,
                                    size: 20,
                                  ),
                                  onPressed: () => _openWhatsApp(customer.whatsapp),
                                  visualDensity: VisualDensity.compact,
                                  padding: EdgeInsets.zero,
                                ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              const Icon(
                                Icons.location_on,
                                color: Colors.white70,
                                size: 16,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  customer.address,
                                  style: const TextStyle(
                                    color: Colors.white70,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
          // Content area
          body: CustomScrollView(
            slivers: [
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    _buildCustomerInsights(context), // Add insights here
                    _buildContent(context, isMobileFull: true),
                  ]),
                ),
              ),
              // Bottom padding
              SliverToBoxAdapter(
                child: SizedBox(height: bottomPadding > 0 ? 80 : 64),
              ),
            ],
          ),
        ),
        bottomNavigationBar: _buildMobileBottomNav(context),
      ),
    );
  }

  Widget _buildCustomerInsights(BuildContext context) {
    final theme = Theme.of(context);
    final totalSpent = invoices.fold(0.0, (sum, invoice) => sum + invoice.amountIncludingVat);
    final pendingOrders = invoices.where((inv) => inv.deliveryStatus == InvoiceStatus.pending).length;
    final avgInvoiceAmount = invoices.isNotEmpty ? totalSpent / invoices.length : 0.0;
    final lastOrderDate = invoices.isNotEmpty ? invoices.last.date : null;

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Customer Insights',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.primary,
              ),
            ),
            const Divider(height: 20),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _buildInsightItem(context, 'Total Spent', NumberFormatter.formatCurrency(totalSpent), Icons.monetization_on, Colors.green),
                _buildInsightItem(context, 'Pending Orders', '$pendingOrders', Icons.pending_actions, Colors.orange),
                _buildInsightItem(context, 'Avg. Invoice', NumberFormatter.formatCurrency(avgInvoiceAmount), Icons.receipt, Colors.blue),
                if (lastOrderDate != null)
                  _buildInsightItem(context, 'Last Order', _formatDate(lastOrderDate), Icons.calendar_today, Colors.grey),
                _buildInsightItem(context, 'Measurements', '${measurements.length}', Icons.straighten, Colors.purple),
                _buildInsightItem(context, 'Complaints', '${complaints.length}', Icons.warning, Colors.red),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInsightItem(BuildContext context, String label, String value, IconData icon, Color color) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 16),
          const SizedBox(width: 8),
          Text(
            '$label: $value',
            style: theme.textTheme.bodySmall?.copyWith(fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Widget _buildMobileBottomNav(BuildContext context) {
    final theme = Theme.of(context);
    final navBarColor = theme.brightness == Brightness.dark
        ? theme.colorScheme.surface
        : Colors.white;

    return Container(
      decoration: BoxDecoration(
        color: navBarColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            offset: const Offset(0, -1),
            blurRadius: 4,
          ),
        ],
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildMobileNavButton(
                context,
                Icons.person,
                'Profile',
                theme.colorScheme.primary,
                onTap: () => _showCustomerDetails(context),
              ),
              _buildMobileNavButton(
                context,
                Icons.straighten,
                'Measurements',
                Colors.purple,
                onTap: () => _showMeasurements(context),
              ),
              _buildMobileNavButton(
                context,
                Icons.receipt_long,
                'Invoices',
                Colors.amber.shade700,
                onTap: () => _showInvoices(context),
              ),
              _buildMobileNavButton(
                context,
                Icons.warning_amber,
                'Complaints',
                Colors.red.shade700,
                onTap: () => _showComplaints(context),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Optimized mobile navigation button with ripple effect
  Widget _buildMobileNavButton(
    BuildContext context, 
    IconData icon, 
    String label,
    Color color,
    {required VoidCallback onTap}
  ) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: color, size: 24),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  color: color,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Show more options menu with sharing functionality
  void _showMoreOptions(BuildContext context) {
    final theme = Theme.of(context);
    
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(16),
            topRight: Radius.circular(16),
          ),
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                margin: const EdgeInsets.only(top: 8),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: theme.colorScheme.onSurface.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              ListTile(
                leading: Icon(Icons.share, color: theme.colorScheme.primary),
                title: Text('Share Customer Info'),
                onTap: () {
                  Navigator.pop(context);
                  _shareCustomerInfo();
                },
              ),
              ListTile(
                leading: Icon(Icons.add_call, color: theme.colorScheme.primary),
                title: Text('Call Customer'),
                onTap: () {
                  Navigator.pop(context);
                  _makePhoneCall(customer.phone);
                },
              ),
              if (customer.whatsapp.isNotEmpty)
                ListTile(
                  leading: Icon(FontAwesomeIcons.whatsapp, color: Colors.green),
                  title: Text('WhatsApp Message'),
                  onTap: () {
                    Navigator.pop(context);
                    _openWhatsApp(customer.whatsapp);
                  },
                ),
              ListTile(
                leading: Icon(Icons.map, color: theme.colorScheme.primary),
                title: Text('Open in Maps'),
                onTap: () {
                  Navigator.pop(context);
                  _openInMaps(customer.address);
                },
              ),
              ListTile(
                leading: Icon(Icons.analytics, color: Colors.green),
                title: Text('View Full Report'),
                onTap: () {
                  Navigator.pop(context);
                  _showFullCustomerReport(context);
                },
              ),
              const Divider(),
              ListTile(
                leading: Icon(Icons.delete_outline, color: Colors.red),
                title: Text('Delete Customer'),
                onTap: () {
                  Navigator.pop(context);
                  _showDeleteConfirmation(context);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Share customer information
  void _shareCustomerInfo() {
    // Format text for sharing
    final ordersCount = invoices.length;
    final measurementsCount = measurements.length;
    final complaintsCount = complaints.length;
    final totalSpent = invoices.fold(0.0, (sum, inv) => sum + inv.amountIncludingVat);
    
    final text = '''
Customer Information:
Name: ${customer.name}
Bill Number: ${customer.billNumber}
Phone: ${customer.phone}
${customer.whatsapp.isNotEmpty ? 'WhatsApp: ${customer.whatsapp}' : ''}
Address: ${customer.address}

Summary:
Total Orders: $ordersCount
Total Spent: ${NumberFormatter.formatCurrency(totalSpent)}
Measurements: $measurementsCount
Complaints: $complaintsCount
''';

    // Share text using share_plus package
    Share.share(text, subject: 'Customer: ${customer.name}');
  }

  // Open phone dialer
  void _makePhoneCall(String phoneNumber) async {
    final Uri uri = Uri.parse('tel:$phoneNumber');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  // Open WhatsApp chat
  void _openWhatsApp(String phoneNumber) async {
    // Format phone number (remove any non-digit characters)
    final cleanPhone = phoneNumber.replaceAll(RegExp(r'\D'), '');
    
    // Different URL schemes for iOS and Android
    String url;
    if (Platform.isAndroid) {
      url = "whatsapp://send?phone=$cleanPhone";
    } else {
      url = "https://api.whatsapp.com/send?phone=$cleanPhone";
    }

    final Uri uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  // Open address in maps app
  void _openInMaps(String address) async {
    final encodedAddress = Uri.encodeComponent(address);
    
    // Different URL schemes for iOS and Android
    String url;
    if (Platform.isIOS) {
      url = "maps://?q=$encodedAddress";
    } else {
      url = "https://www.google.com/maps/search/?api=1&query=$encodedAddress";
    }

    final Uri uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  void _showDeleteConfirmation(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Delete Customer'),
        content: Text('Are you sure you want to delete ${customer.name}? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              // Handle delete action
              Navigator.pop(context); // Close dialog
              Navigator.pop(context); // Go back to previous screen
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _editCustomer(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AddCustomerDialog(customer: customer),
    );
  }


  Widget _buildContent(BuildContext context, {bool isMobileFull = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (!isMobileFull) _buildCustomerDetails(context),
        const SizedBox(height: 24),
        _buildRecentActivity(context, isMobileFull: isMobileFull),
        const SizedBox(height: 20),
      ],
    );
  }

  Widget _buildCustomerDetails(BuildContext context) {
    final theme = Theme.of(context);
    
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: theme.brightness == Brightness.dark
              ? theme.colorScheme.surface.withAlpha((theme.colorScheme.surface.alpha * 0.4).toInt())
              : theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: theme.brightness == Brightness.dark
                ? theme.colorScheme.onSurface.withAlpha((theme.colorScheme.onSurface.alpha * 0.1).toInt())
                : theme.colorScheme.primary.withAlpha((theme.colorScheme.primary.alpha * 0.1).toInt()),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Customer Details',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.primary,
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.edit, color: theme.colorScheme.primary),
                  onPressed: () => _editCustomer(context),
                  tooltip: 'Edit Customer',
                ),
              ],
            ),
            const Divider(),
            const SizedBox(height: 8),
            _buildInfoRow(
              context, 
              Icons.phone, 
              customer.phone,
              iconColor: Colors.blue,
            ),
            const SizedBox(height: 12),
            _buildInfoRow(
              context, 
              FontAwesomeIcons.whatsapp, 
              customer.whatsapp.isNotEmpty == true ? customer.whatsapp : 'Not provided',
              iconColor: Colors.green,
            ),
            const SizedBox(height: 12),
            _buildInfoRow(
              context, 
              Icons.location_on, 
              customer.address,
              iconColor: Colors.red,
            ),
            const SizedBox(height: 12),
            _buildInfoRow(
              context, 
              Icons.person, 
              customer.gender.toString().split('.').last,
              iconColor: Colors.purple,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(
    BuildContext context, 
    IconData icon, 
    String text, {
    Color? textColor,
    Color? iconColor,
  }) {
    final theme = Theme.of(context);
    
    return Row(
      children: [
        Icon(
          icon, 
          size: 16, 
          color: iconColor ?? theme.colorScheme.primary
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              color: textColor ?? theme.colorScheme.onSurface,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildRecentActivity(BuildContext context, {bool isMobileFull = false}) {
    final theme = Theme.of(context);
    
    // Sort invoices by date (newest first)
    final sortedInvoices = [...invoices]
      ..sort((a, b) => b.date.compareTo(a.date));
    
    // Get the most recent invoice
    final recentInvoices = sortedInvoices.take(2).toList();
    
    // Sort complaints by creation date (newest first)
    final sortedComplaints = [...complaints]
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    
    // Get the most recent complaint
    final recentComplaints = sortedComplaints.take(1).toList();
    
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      color: theme.cardColor,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.history, size: 20, color: theme.colorScheme.primary),
                const SizedBox(width: 8),
                Text(
                  'Recent Activity',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.primary,
                  ),
                ),
              ],
            ),
            const Divider(),
            const SizedBox(height: 8),
            if (recentInvoices.isNotEmpty) ...[
              ...recentInvoices.map((invoice) => _buildActivityItem(
                    context,
                    title: 'Invoice #${invoice.invoiceNumber}',
                    subtitle: 'Amount: ${NumberFormatter.formatCurrency(invoice.amountIncludingVat)}',
                    date: invoice.date,
                    icon: Icons.receipt,
                    color: Colors.blue.shade600,
                    onTap: () => _showInvoiceDetails(context, invoice),
                  )),
            ] else
              _buildEmptyActivityItem(context, 'No recent invoices'),
            
            if (recentComplaints.isNotEmpty) ...[
              ...recentComplaints.map((complaint) => _buildActivityItem(
                    context,
                    title: complaint.title,
                    subtitle: 'Status: ${complaint.status}',
                    date: complaint.createdAt,
                    icon: Icons.warning_amber,
                    color: Colors.red.shade700,
                    onTap: () => _showComplaintDetails(context, complaint),
                  )),
            ] else
              _buildEmptyActivityItem(context, 'No recent complaints'),
            
            if (isMobileFull && measurements.isNotEmpty) ...[
              _buildActivityItem(
                context,
                title: 'Latest Measurement',
                subtitle: 'Style: ${measurements.first.style}',
                date: measurements.first.date,
                icon: Icons.straighten,
                color: Colors.purple,
                onTap: () => _showMeasurementDetails(context, measurements.first),
              ),
            ] else if (isMobileFull && measurements.isEmpty)
              _buildEmptyActivityItem(context, 'No measurements available'),
            
            const SizedBox(height: 8),
            if (!isMobileFull)
              Align(
                alignment: Alignment.centerRight,
                child: TextButton.icon(
                  onPressed: () {
                    // View all activity - show a more comprehensive view
                    _showFullActivityHistory(context);
                  },
                  icon: const Icon(Icons.arrow_forward),
                  label: const Text('View All'),
                  style: TextButton.styleFrom(
                    foregroundColor: theme.colorScheme.primary,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyActivityItem(BuildContext context, String message) {
    final theme = Theme.of(context);
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.brightness == Brightness.dark
            ? theme.colorScheme.surface.withAlpha((theme.colorScheme.surface.alpha * 0.3).toInt())
            : theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: theme.colorScheme.onSurface.withAlpha((theme.colorScheme.onSurface.alpha * 0.1).toInt()),
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.info_outline, 
            color: theme.colorScheme.onSurface.withAlpha((theme.colorScheme.onSurface.alpha * 0.5).toInt()), 
            size: 24
          ),
          const SizedBox(width: 16),
          Text(
            message,
            style: TextStyle(
              color: theme.colorScheme.onSurface.withAlpha((theme.colorScheme.onSurface.alpha * 0.7).toInt()),
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActivityItem(
    BuildContext context, {
    required String title,
    required String subtitle,
    required DateTime date,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    final theme = Theme.of(context);
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: theme.brightness == Brightness.dark
            ? theme.cardColor.withAlpha((theme.cardColor.alpha * 0.2).toInt())
            : theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: color.withAlpha((color.alpha * 0.2).toInt()),
        ),
        boxShadow: theme.brightness == Brightness.dark
            ? null
            : [
                BoxShadow(
                  color: Colors.black.withAlpha(10),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: color.withAlpha((color.alpha * 0.1).toInt()),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, color: color, size: 24),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w500,
                          color: theme.colorScheme.onSurface,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurface.withAlpha(
                            (theme.colorScheme.onSurface.alpha * 0.7).toInt()
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      _formatDate(date),
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurface.withAlpha(
                          (theme.colorScheme.onSurface.alpha * 0.5).toInt()
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Icon(
                      Icons.arrow_forward_ios,
                      size: 12,
                      color: theme.colorScheme.onSurface.withAlpha(
                        (theme.colorScheme.onSurface.alpha * 0.3).toInt()
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);
    
    if (difference.inDays < 1) {
      return 'Today';
    } else if (difference.inDays < 2) {
      return 'Yesterday';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }

  void _showCustomerDetails(BuildContext context) {
    final isDesktop = _isDesktop(context);
    final dimensions = _getDialogDimensions(context);
    
    if (isDesktop) {
      showDialog(
        context: context,
        builder: (context) => Dialog(
          backgroundColor: Colors.transparent,
          child: Container(
            width: dimensions.width,
            height: dimensions.height,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: BorderRadius.circular(28),
            ),
            child: AddCustomerDialog(customer: customer),
          ),
        ),
      );
    } else {
      showDialog(
        context: context,
        builder: (context) => AddCustomerDialog(customer: customer),
      );
    }
  }

  void _showMeasurements(BuildContext context) {
    if (measurements.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No measurements found for this customer'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }
    
    final theme = Theme.of(context);
    final size = MediaQuery.of(context).size;
    final isMobile = size.width < 600;
    
    if (isMobile) {
      // Better mobile UI with full screen dialog
      Navigator.of(context).push(
        MaterialPageRoute(
          fullscreenDialog: true,
          builder: (context) => Scaffold(
            appBar: AppBar(
              title: Text('Measurements'),
              centerTitle: true,
              backgroundColor: theme.brightness == Brightness.dark 
                  ? theme.appBarTheme.backgroundColor 
                  : Colors.purple,
              foregroundColor: Colors.white,
            ),
            body: SafeArea(
              child: ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: measurements.length,
                separatorBuilder: (context, index) => const Divider(),
                itemBuilder: (context, index) {
                  final measurement = measurements[index];
                  return ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    leading: CircleAvatar(
                      backgroundColor: Colors.purple.withAlpha(40),
                      child: Icon(Icons.straighten, color: Colors.purple),
                    ),
                    title: Text(
                      '${measurement.style}',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 4),
                        Text('Date: ${_formatDate(measurement.date)}'),
                        Text('Design: ${measurement.designType}'),
                      ],
                    ),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => _showMeasurementDetails(context, measurement),
                  );
                },
              ),
            ),
          ),
        ),
      );
    } else {
      // Desktop view
      showDialog(
        context: context,
        builder: (context) => Dialog(
          child: Container(
            width: MediaQuery.of(context).size.width * 0.8,
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Measurements',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 16),
                Flexible(
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: measurements.length,
                    itemBuilder: (context, index) {
                      final measurement = measurements[index];
                      return ListTile(
                        title: Text('Style: ${measurement.style}'),
                        subtitle: Text('Date: ${_formatDate(measurement.date)}'),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () => _showMeasurementDetails(context, measurement),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 8),
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Close'),
                ),
              ],
            ),
          ),
        ),
      );
    }
  }

  void _showInvoices(BuildContext context) {
    // Similar to _showMeasurements, but with invoice-specific UI
    if (invoices.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No invoices found for this customer'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }
    
    final theme = Theme.of(context);
    final size = MediaQuery.of(context).size;
    final isMobile = size.width < 600;
    
    if (isMobile) {
      Navigator.of(context).push(
        MaterialPageRoute(
          fullscreenDialog: true,
          builder: (context) => Scaffold(
            appBar: AppBar(
              title: Text('Invoices'),
              centerTitle: true,
              backgroundColor: theme.brightness == Brightness.dark 
                  ? theme.appBarTheme.backgroundColor 
                  : Colors.amber.shade700,
              foregroundColor: Colors.white,
            ),
            body: SafeArea(
              child: ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: invoices.length,
                separatorBuilder: (context, index) => const Divider(),
                itemBuilder: (context, index) {
                  final invoice = invoices[index];
                  return ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    leading: CircleAvatar(
                      backgroundColor: Colors.amber.shade700.withAlpha(40),
                      child: Icon(Icons.receipt_long, color: Colors.amber.shade700),
                    ),
                    title: Text(
                      'Invoice #${invoice.invoiceNumber}',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 4),
                        Text('Date: ${_formatDate(invoice.date)}'),
                        Text('Amount: ${NumberFormatter.formatCurrency(invoice.amountIncludingVat)}'),
                        Text('Status: ${invoice.deliveryStatus}'),
                      ],
                    ),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => _showInvoiceDetails(context, invoice),
                  );
                },
              ),
            ),
          ),
        ),
      );
    } else {
      // Desktop view (similar to the original implementation)
      showDialog(
        context: context,
        builder: (context) => Dialog(
          child: Container(
            width: MediaQuery.of(context).size.width * 0.8,
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Invoices',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 16),
                Flexible(
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: invoices.length,
                    itemBuilder: (context, index) {
                      final invoice = invoices[index];
                      return ListTile(
                        title: Text('Invoice #${invoice.invoiceNumber}'),
                        subtitle: Text('Amount: ${NumberFormatter.formatCurrency(invoice.amountIncludingVat)}'),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () => _showInvoiceDetails(context, invoice),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 8),
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Close'),
                ),
              ],
            ),
          ),
        ),
      );
    }
  }

  void _showComplaints(BuildContext context) {
    // Similar pattern as _showInvoices and _showMeasurements
    if (complaints.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No complaints found for this customer'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }
    
    final theme = Theme.of(context);
    final size = MediaQuery.of(context).size;
    final isMobile = size.width < 600;
    
    if (isMobile) {
      Navigator.of(context).push(
        MaterialPageRoute(
          fullscreenDialog: true,
          builder: (context) => Scaffold(
            appBar: AppBar(
              title: Text('Complaints'),
              centerTitle: true,
              backgroundColor: theme.brightness == Brightness.dark 
                  ? theme.appBarTheme.backgroundColor 
                  : Colors.red.shade700,
              foregroundColor: Colors.white,
            ),
            body: SafeArea(
              child: ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: complaints.length,
                separatorBuilder: (context, index) => const Divider(),
                itemBuilder: (context, index) {
                  final complaint = complaints[index];
                  return ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    leading: CircleAvatar(
                      backgroundColor: Colors.red.shade700.withAlpha(40),
                      child: Icon(Icons.warning_amber, color: Colors.red.shade700),
                    ),
                    title: Text(
                      complaint.title,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 4),
                        Text('Status: ${complaint.status}'),
                        Text('Created: ${_formatDate(complaint.createdAt)}'),
                      ],
                    ),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => _showComplaintDetails(context, complaint),
                  );
                },
              ),
            ),
          ),
        ),
      );
    } else {
      // Desktop view (original implementation)
      showDialog(
        context: context,
        builder: (context) => Dialog(
          child: Container(
            width: MediaQuery.of(context).size.width * 0.8,
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Complaints',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 16),
                Flexible(
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: complaints.length,
                    itemBuilder: (context, index) {
                      final complaint = complaints[index];
                      return ListTile(
                        title: Text(complaint.title),
                        subtitle: Text('Status: ${complaint.status}'),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () => _showComplaintDetails(context, complaint),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 8),
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Close'),
                ),
              ],
            ),
          ),
        ),
      );
    }
  }

  // Add helper method to check if we're on desktop
  bool _isDesktop(BuildContext context) {
    return MediaQuery.of(context).size.width >= 1024;
  }

  void _showMeasurementDetails(BuildContext context, Measurement measurement) {
    final isDesktop = _isDesktop(context);
    final dimensions = _getDialogDimensions(context);
    
    if (isDesktop) {
      showDialog(
        context: context,
        builder: (context) => Dialog(
          backgroundColor: Colors.transparent,
          child: Container(
            width: dimensions.width,
            height: dimensions.height,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: BorderRadius.circular(28),
            ),
            child: DetailDialog(
              measurement: measurement,
              customerId: customer.id,
            ),
          ),
        ),
      );
    } else {
      // Mobile view
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => DetailDialog(
            measurement: measurement,
            customerId: customer.id,
          ),
        ),
      );
    }
  }

  void _showInvoiceDetails(BuildContext context, Invoice invoice) {
    final isDesktop = _isDesktop(context);
    final dimensions = _getDialogDimensions(context);
    
    if (isDesktop) {
      showDialog(
        context: context,
        builder: (context) => Dialog(
          backgroundColor: Colors.transparent,
          child: Container(
            width: dimensions.width,
            height: dimensions.height,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: BorderRadius.circular(28),
            ),
            child: InvoiceDetailsDialog(invoice: invoice),
          ),
        ),
      );
    } else {
      showDialog(
        context: context,
        builder: (context) => InvoiceDetailsDialog(invoice: invoice),
      );
    }
  }

  void _showComplaintDetails(BuildContext context, Complaint complaint) {
    final isDesktop = _isDesktop(context);
    final dimensions = _getDialogDimensions(context);
    
    if (isDesktop) {
      showDialog(
        context: context,
        builder: (context) => Dialog(
          backgroundColor: Colors.transparent,
          child: Container(
            width: dimensions.width,
            height: dimensions.height,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: BorderRadius.circular(28),
            ),
            child: ComplaintDetailDialog(complaint: complaint),
          ),
        ),
      );
    } else {
      showDialog(
        context: context,
        builder: (context) => ComplaintDetailDialog(complaint: complaint),
      );
    }
  }
  
  void _showFullActivityHistory(BuildContext context) {
    final sortedInvoices = [...invoices]..sort((a, b) => b.date.compareTo(a.date));
    final sortedComplaints = [...complaints]..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    
    showDialog(
      context: context,
      builder: (context) => Dialog(
        child: Container(
          width: MediaQuery.of(context).size.width * 0.8,
          height: MediaQuery.of(context).size.height * 0.7,
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Activity History',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 16),
              Expanded(
                child: DefaultTabController(
                  length: 3,
                  child: Column(
                    children: [
                      TabBar(
                        tabs: const [
                          Tab(text: 'Invoices'),
                          Tab(text: 'Complaints'),
                          Tab(text: 'Measurements'),
                        ],
                        labelColor: Theme.of(context).colorScheme.primary,
                      ),
                      const SizedBox(height: 8),
                      Expanded(
                        child: TabBarView(
                          children: [
                            // Invoices tab
                            sortedInvoices.isEmpty
                                ? Center(child: Text('No invoices found'))
                                : ListView.builder(
                                    itemCount: sortedInvoices.length,
                                    itemBuilder: (context, index) {
                                      final invoice = sortedInvoices[index];
                                      return _buildActivityItem(
                                        context,
                                        title: 'Invoice #${invoice.invoiceNumber}',
                                        subtitle: 'Amount: ${NumberFormatter.formatCurrency(invoice.amountIncludingVat)}',
                                        date: invoice.date,
                                        icon: Icons.receipt,
                                        color: Colors.blue.shade600,
                                        onTap: () => _showInvoiceDetails(context, invoice),
                                      );
                                    },
                                  ),
                            
                            // Complaints tab
                            sortedComplaints.isEmpty
                                ? Center(child: Text('No complaints found'))
                                : ListView.builder(
                                    itemCount: sortedComplaints.length,
                                    itemBuilder: (context, index) {
                                      final complaint = sortedComplaints[index];
                                      return _buildActivityItem(
                                        context,
                                        title: complaint.title,
                                        subtitle: 'Status: ${complaint.status}',
                                        date: complaint.createdAt,
                                        icon: Icons.warning_amber,
                                        color: Colors.red.shade700,
                                        onTap: () => _showComplaintDetails(context, complaint),
                                      );
                                    },
                                  ),
                            
                            // Measurements tab
                            measurements.isEmpty
                                ? Center(child: Text('No measurements found'))
                                : ListView.builder(
                                    itemCount: measurements.length,
                                    itemBuilder: (context, index) {
                                      final measurement = measurements[index];
                                      return _buildActivityItem(
                                        context,
                                        title: 'Style: ${measurement.style}',
                                        subtitle: 'Date: ${_formatDate(measurement.date)}',
                                        date: measurement.date,
                                        icon: Icons.straighten,
                                        color: Colors.purple,
                                        onTap: () => _showMeasurementDetails(context, measurement),
                                      );
                                    },
                                  ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Close'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showFullCustomerReport(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isMobile = size.width < 600;
    
    if (isMobile) {
      Navigator.of(context).push(
        MaterialPageRoute(
          fullscreenDialog: true,
          builder: (context) => CustomerFullReportScreen( // Remove underscore
            customer: customer,
            measurements: measurements,
            invoices: invoices,
            complaints: complaints,
          ),
        ),
      );
    } else {
      showDialog(
        context: context,
        builder: (context) => CustomerInsightsReport(
          customer: customer,
          measurements: measurements,
          invoices: invoices,
          complaints: complaints,
        ),
      );
    }
  }

  // Add helper method for dialog dimensions
  DialogDimensions _getDialogDimensions(BuildContext context) {
    final size = MediaQuery.of(context).size;
    return DialogDimensions(
      width: size.width * 0.75,
      height: size.height * 0.85,
    );
  }
}

// Helper class for dialog dimensions
class DialogDimensions {
  final double width;
  final double height;
  
  DialogDimensions({
    required this.width,
    required this.height,
  });
}
