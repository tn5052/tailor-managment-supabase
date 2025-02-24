import 'package:flutter/material.dart';
import 'package:intl/intl.dart'; // Add this import
import '../../models/customer.dart';
import '../../models/customer_filter.dart';
import '../../services/supabase_service.dart';
import '../../services/measurement_service.dart';
import '../../services/invoice_service.dart';  // Add this import
import '../../models/layout_type.dart';
import 'measurement_history_dialog.dart';
import 'invoice_history_dialog.dart';  // Add this import

class CustomerList extends StatelessWidget {
  final String searchQuery;
  final Function(Customer, int) onEdit;
  final Function(Customer) onDelete;
  final CustomerLayoutType layoutType;
  final bool isDesktop;
  final CustomerFilter filter;

  const CustomerList({
    super.key,
    required this.searchQuery,
    required this.onEdit,
    required this.onDelete,
    required this.layoutType,
    required this.isDesktop,
    required this.filter,
  });

  Widget _buildCustomerCard(BuildContext context, Customer customer, {int? referralCount, int? rank}) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 0,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: colorScheme.outline.withOpacity(0.1),
        ),
      ),
      child: InkWell(
        onTap: () => onEdit(customer, 0),
        child: Stack(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Bill number at the top
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          _buildBillNumber(context, customer.billNumber),
                          _buildDateTimeDisplay(context, customer.createdAt),
                        ],
                      ),
                      const SizedBox(height: 12),
                      // Customer info
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildAvatar(context, customer),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  customer.name,
                                  style: theme.textTheme.titleLarge?.copyWith(
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    Icon(
                                      Icons.phone_outlined,
                                      size: 16,
                                      color: colorScheme.primary,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      customer.phone,
                                      style: theme.textTheme.bodyMedium?.copyWith(
                                        color: colorScheme.primary,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          _buildPopupMenu(context, customer),
                        ],
                      ),
                    ],
                  ),
                ),

                // Relationships section
                if (customer.referredBy != null || customer.familyId != null)
                  Container(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                    child: Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        if (customer.referredBy != null)
                          _buildReferralChip(context, customer),
                        if (customer.familyId != null)
                          _buildFamilyChip(context, customer),
                      ],
                    ),
                  ),

                // Footer section
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: colorScheme.surfaceContainerHighest.withOpacity(0.3),
                    border: Border(
                      top: BorderSide(
                        color: colorScheme.outlineVariant.withOpacity(0.5),
                      ),
                    ),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Row(
                          children: [
                            Icon(
                              Icons.location_on_outlined,
                              size: 16,
                              color: colorScheme.secondary,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                customer.address,
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      // Action Buttons Row
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Invoices Button
                          FutureBuilder<bool>(
                            future: _hasInvoices(customer.id),
                            builder: (context, snapshot) {
                              if (snapshot.hasData && snapshot.data == true) {
                                return Padding(
                                  padding: const EdgeInsets.only(right: 8),
                                  child: FilledButton.icon(
                                    onPressed: () => _showInvoices(context, customer),
                                    icon: const Icon(Icons.receipt_outlined, size: 16),
                                    label: const Text(
                                      'Invoices',
                                      style: TextStyle(fontSize: 12),
                                    ),
                                    style: FilledButton.styleFrom(
                                      backgroundColor: colorScheme.tertiaryContainer,
                                      foregroundColor: colorScheme.onTertiaryContainer,
                                      minimumSize: const Size(0, 32),
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 12,
                                        vertical: 0,
                                      ),
                                      visualDensity: VisualDensity.compact,
                                      textStyle: theme.textTheme.labelMedium?.copyWith(
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                );
                              }
                              return const SizedBox.shrink();
                            },
                          ),
                          // Measurements Button
                          FutureBuilder<bool>(
                            future: _hasMeasurements(customer.id),
                            builder: (context, snapshot) {
                              if (snapshot.hasData && snapshot.data == true) {
                                return FilledButton.icon(
                                  onPressed: () => _showMeasurementHistory(context, customer),
                                  icon: const Icon(Icons.straighten, size: 16),
                                  label: const Text(
                                    'Measurements',
                                    style: TextStyle(fontSize: 12),
                                  ),
                                  style: FilledButton.styleFrom(
                                    backgroundColor: colorScheme.primary,
                                    foregroundColor: colorScheme.onPrimary,
                                    minimumSize: const Size(0, 32),
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 0,
                                    ),
                                    visualDensity: VisualDensity.compact,
                                    textStyle: theme.textTheme.labelMedium?.copyWith(
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                );
                              }
                              return const SizedBox.shrink();
                            },
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            if (rank != null && rank <= 3)
              Positioned(
                right: 8,
                top: 8,
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: colorScheme.primaryContainer,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: colorScheme.primary.withOpacity(0.2),
                    ),
                  ),
                  child: Text(
                    '#$rank',
                    style: theme.textTheme.titleSmall?.copyWith(
                      color: colorScheme.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            if (referralCount != null && referralCount > 0)
              Positioned(
                right: 8,
                top: rank != null && rank <= 3 ? 48 : 8,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: colorScheme.secondaryContainer,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: colorScheme.secondary.withOpacity(0.2),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.people_outline,
                        size: 14,
                        color: colorScheme.secondary,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '$referralCount ${referralCount == 1 ? 'referral' : 'referrals'}',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colorScheme.secondary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  void _showMeasurementHistory(BuildContext context, Customer customer) {
    showDialog(
      context: context,
      builder: (context) => MeasurementHistoryDialog(
        customer: customer,
      ),
    );
  }

  // Add this method to check if customer has measurements
  Future<bool> _hasMeasurements(String customerId) async {
    final measurementService = MeasurementService();
    final measurements = await measurementService.getMeasurementsByCustomerId(customerId);
    return measurements.isNotEmpty;
  }

  // Add this method to check for invoices
  Future<bool> _hasInvoices(String customerId) async {
    final invoiceService = InvoiceService();
    final invoices = await invoiceService.getCustomerInvoices(customerId);
    return invoices.isNotEmpty;
  }

  // Add this method to show invoices
  void _showInvoices(BuildContext context, Customer customer) {
    InvoiceHistoryDialog.show(context, customer);
  }

  Widget _buildGridCard(BuildContext context, Customer customer, {int? referralCount, int? rank}) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isLight = theme.brightness == Brightness.light;

    return Card(
      elevation: 0,
      clipBehavior: Clip.antiAlias,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: colorScheme.outline.withOpacity(0.1),
        ),
      ),
      child: InkWell(
        onTap: () => onEdit(customer, 0),
        child: Stack(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Bill number header
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: isLight
                        ? colorScheme.primary.withOpacity(0.1)
                        : colorScheme.primaryContainer.withOpacity(0.4),
                    border: Border(
                      bottom: BorderSide(
                        color: colorScheme.outlineVariant.withOpacity(0.5),
                      ),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.receipt_outlined,
                        size: 18,
                        color: colorScheme.primary,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '#${customer.billNumber}',
                        style: theme.textTheme.titleMedium?.copyWith(
                          color: colorScheme.primary,
                          fontWeight: FontWeight.w600,
                          fontSize: 18,
                        ),
                      ),
                    ],
                  ),
                ),

                // Customer info section
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    children: [
                      // Avatar
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: colorScheme.primary.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Center(
                          child: Text(
                            customer.name[0].toUpperCase(),
                            style: theme.textTheme.titleMedium?.copyWith(
                              color: colorScheme.primary,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      // Name and Phone
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              customer.name,
                              style: theme.textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.w600,
                                fontSize: 16,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 2),
                            Row(
                              children: [
                                Icon(
                                  Icons.phone_outlined,
                                  size: 14,
                                  color: colorScheme.secondary,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  customer.phone,
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    color: colorScheme.secondary,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      _buildPopupMenu(context, customer),
                    ],
                  ),
                ),

                // Relationship chips
                if (customer.referredBy != null || customer.familyId != null)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                    child: Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        if (customer.referredBy != null)
                          _buildRelationshipInfo(
                            context,
                            customer.referredBy!,
                            Icons.person_add_outlined,
                            colorScheme.secondary,
                            'Referred by',
                          ),
                        if (customer.familyId != null)
                          _buildRelationshipInfo(
                            context,
                            customer.familyId!,
                            Icons.family_restroom,
                            colorScheme.tertiary,
                            '${customer.familyRelationDisplay} of',
                          ),
                      ],
                    ),
                  ),

                const Spacer(),

                // Footer with date and measurements
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: colorScheme.surfaceContainerHighest.withOpacity(0.3),
                    border: Border(
                      top: BorderSide(
                        color: colorScheme.outlineVariant.withOpacity(0.3),
                      ),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            DateFormat('MMM d, y').format(customer.createdAt),
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          Text(
                            DateFormat('h:mm a').format(customer.createdAt),
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: colorScheme.onSurfaceVariant.withOpacity(0.8),
                            ),
                          ),
                        ],
                      ),
                      // Add measurements button conditionally
                      FutureBuilder<bool>(
                        future: _hasMeasurements(customer.id),
                        builder: (context, snapshot) {
                          if (snapshot.hasData && snapshot.data == true) {
                            return FilledButton.icon(
                              onPressed: () => _showMeasurementHistory(context, customer),
                              icon: const Icon(Icons.straighten, size: 16),
                              label: const Text(
                                'Measurements',
                                style: TextStyle(fontSize: 12),  // Smaller text
                              ),
                              style: FilledButton.styleFrom(
                                backgroundColor: colorScheme.primary,
                                foregroundColor: colorScheme.onPrimary,
                                minimumSize: const Size(0, 32),  // Reduced height
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,  // Reduced padding
                                  vertical: 0,
                                ),
                                visualDensity: VisualDensity.compact,  // More compact
                                textStyle: theme.textTheme.labelMedium?.copyWith(  // Smaller text style
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            );
                          }
                          return const SizedBox.shrink();
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
            if (rank != null && rank <= 3)
              Positioned(
                right: 8,
                top: 8,
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: colorScheme.primaryContainer,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: colorScheme.primary.withOpacity(0.2),
                    ),
                  ),
                  child: Text(
                    '#$rank',
                    style: theme.textTheme.titleSmall?.copyWith(
                      color: colorScheme.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            if (referralCount != null && referralCount > 0)
              Positioned(
                right: 8,
                top: rank != null && rank <= 3 ? 48 : 8,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: colorScheme.secondaryContainer,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: colorScheme.secondary.withOpacity(0.2),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.people_outline,
                        size: 14,
                        color: colorScheme.secondary,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '$referralCount ${referralCount == 1 ? 'referral' : 'referrals'}',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colorScheme.secondary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }


  Widget _buildAvatar(BuildContext context, Customer customer) {
    final theme = Theme.of(context);
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        color: theme.colorScheme.primary.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Center(
        child: Text(
          customer.name[0].toUpperCase(),
          style: theme.textTheme.titleLarge?.copyWith(
            color: theme.colorScheme.primary,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _buildBillNumber(BuildContext context, String billNumber) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: theme.colorScheme.primaryContainer,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: theme.colorScheme.primary.withOpacity(0.2),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.receipt_outlined,
            size: 16,
            color: theme.colorScheme.primary,
          ),
          const SizedBox(width: 6),
          Text(
            '#$billNumber',
            style: theme.textTheme.titleMedium?.copyWith(
              color: theme.colorScheme.primary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReferralChip(BuildContext context, Customer customer) {
    final theme = Theme.of(context);
    return FutureBuilder<String>(
      future: SupabaseService().getCustomerName(customer.referredBy!),
      builder: (context, snapshot) {
        final referrerName = snapshot.data ?? 'Loading...';
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: theme.colorScheme.secondary.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: theme.colorScheme.secondary.withOpacity(0.2),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.person_add_outlined,
                size: 14,
                color: theme.colorScheme.secondary,
              ),
              const SizedBox(width: 4),
              Text(
                'Referred by $referrerName',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.secondary,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildFamilyChip(BuildContext context, Customer customer) {
    final theme = Theme.of(context);
    return FutureBuilder<String>(
      future: SupabaseService().getCustomerName(customer.familyId!),
      builder: (context, snapshot) {
        final familyMemberName = snapshot.data ?? 'Loading...';
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: theme.colorScheme.tertiary.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: theme.colorScheme.tertiary.withOpacity(0.2),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.family_restroom,
                size: 14,
                color: theme.colorScheme.tertiary,
              ),
              const SizedBox(width: 4),
              Text(
                '${customer.familyRelationDisplay} of $familyMemberName',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.tertiary,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildPopupMenu(BuildContext context, Customer customer) {
    return PopupMenuButton<String>(
      icon: Icon(
        Icons.more_vert,
        color: Theme.of(context).colorScheme.onSurfaceVariant,
      ),
      itemBuilder: (context) => [
        PopupMenuItem(
          value: 'edit',
          child: Row(
            children: [
              Icon(
                Icons.edit_outlined,
                size: 20,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(width: 8),
              const Text('Edit'),
            ],
          ),
        ),
        PopupMenuItem(
          value: 'delete',
          child: Row(
            children: [
              Icon(
                Icons.delete_outline,
                size: 20,
                color: Theme.of(context).colorScheme.error,
              ),
              const SizedBox(width: 8),
              Text(
                'Delete',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.error,
                ),
              ),
            ],
          ),
        ),
      ],
      onSelected: (value) {
        if (value == 'edit') {
          onEdit(customer, 0);
        } else if (value == 'delete') {
          onDelete(customer);
        }
      },
    );
  }

  String _formatDateTime(DateTime dateTime) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final date = DateTime(dateTime.year, dateTime.month, dateTime.day);

    if (date == today) {
      return 'Today at ${DateFormat('h:mm a').format(dateTime)}';
    } else if (date == today.subtract(const Duration(days: 1))) {
      return 'Yesterday at ${DateFormat('h:mm a').format(dateTime)}';
    } else if (date.isAfter(today.subtract(const Duration(days: 7)))) {
      return '${DateFormat('EEEE').format(dateTime)} at ${DateFormat('h:mm a').format(dateTime)}';
    } else if (date.year == today.year) {
      return DateFormat('MMM d').format(dateTime);
    } else {
      return DateFormat('MMM d, y').format(dateTime);
    }
  }

  Widget _buildDateTimeDisplay(BuildContext context, DateTime dateTime) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withOpacity(0.5),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.access_time,
            size: 14,
            color: theme.colorScheme.onSurfaceVariant,
          ),
          const SizedBox(width: 4),
          Text(
            _formatDateTime(dateTime),
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRelationshipInfo(
    BuildContext context,
    String customerId,
    IconData icon,
    Color color,
    String prefix,
  ) {
    final theme = Theme.of(context);
    
    return FutureBuilder<String>(
      future: SupabaseService().getCustomerName(customerId),
      builder: (context, snapshot) {
        final name = snapshot.data ?? 'Loading...';
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: color.withOpacity(0.2)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 14, color: color),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  '$prefix $name',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: color,
                    fontWeight: FontWeight.w500,
                    fontSize: 13,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildGroupedList(List<Customer> customers, BuildContext context) {
    switch (filter.groupBy) {
      case CustomerGroupBy.none:
        return _buildRegularList(customers);
      case CustomerGroupBy.gender:
        return _buildGenderGroups(customers, context);
      case CustomerGroupBy.family:
        return _buildFamilyGroups(customers, context);
      case CustomerGroupBy.referrals:
        return _buildReferralGroups(customers, context);
      case CustomerGroupBy.dateAdded:
        return _buildDateGroups(customers, context);
    }
  }


  Widget _buildGenderGroups(List<Customer> customers, BuildContext context) {
    final maleCustomers = customers.where((c) => c.gender == Gender.male).toList();
    final femaleCustomers = customers.where((c) => c.gender == Gender.female).toList();
    final theme = Theme.of(context);

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      children: [
        if (maleCustomers.isNotEmpty)
          _buildExpandableGroup(
            context: context,
            title: 'Male',
            count: maleCustomers.length,
            color: theme.colorScheme.primary.withOpacity(0.1),
            children: maleCustomers,
          ),
        if (femaleCustomers.isNotEmpty)
          _buildExpandableGroup(
            context: context,
            title: 'Female',
            count: femaleCustomers.length,
            color: theme.colorScheme.secondary.withOpacity(0.1),
            children: femaleCustomers,
          ),
      ],
    );
  }

  Widget _buildReferralGroups(List<Customer> customers, BuildContext context) {
    final referredCustomers = customers.where((c) => c.referredBy != null).toList();
    final referrers = customers.where((c) => customers.any((other) => other.referredBy == c.id)).toList();
    final others = customers.where((c) => c.referredBy == null && !referrers.any((r) => r.id == c.id)).toList();

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      children: [
        if (referrers.isNotEmpty)
          _buildExpandableGroup(
            context: context,
            title: 'Referrers',
            count: referrers.length,
            color: Theme.of(context).colorScheme.secondary.withOpacity(0.1),
            children: referrers,
          ),
        if (referredCustomers.isNotEmpty)
          _buildExpandableGroup(
            context: context,
            title: 'Referred Customers',
            count: referredCustomers.length,
            color: Theme.of(context).colorScheme.tertiary.withOpacity(0.1),
            children: referredCustomers,
          ),
        if (others.isNotEmpty)
          _buildExpandableGroup(
            context: context,
            title: 'Others',
            count: others.length,
            color: Theme.of(context).colorScheme.surfaceVariant,
            children: others,
          ),
      ],
    );
  }

  Widget _buildFamilyGroups(List<Customer> customers, BuildContext context) {
    final familyMembers = customers.where((c) => c.familyId != null).toList();
    final independentCustomers = customers.where((c) => c.familyId == null).toList();

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      children: [
        if (familyMembers.isNotEmpty)
          _buildExpandableGroup(
            context: context,
            title: 'Family Members',
            count: familyMembers.length,
            color: Theme.of(context).colorScheme.tertiary.withOpacity(0.1),
            children: familyMembers,
          ),
        if (independentCustomers.isNotEmpty)
          _buildExpandableGroup(
            context: context,
            title: 'Independent',
            count: independentCustomers.length,
            color: Theme.of(context).colorScheme.surfaceVariant,
            children: independentCustomers,
          ),
      ],
    );
  }

  Widget _buildDateGroups(List<Customer> customers, BuildContext context) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final lastWeek = today.subtract(const Duration(days: 7));
    final lastMonth = today.subtract(const Duration(days: 30));

    final todayCustomers = customers.where((c) {
      final date = DateTime(c.createdAt.year, c.createdAt.month, c.createdAt.day);
      return date == today;
    }).toList();

    final yesterdayCustomers = customers.where((c) {
      final date = DateTime(c.createdAt.year, c.createdAt.month, c.createdAt.day);
      return date == yesterday;
    }).toList();

    final lastWeekCustomers = customers.where((c) {
      final date = DateTime(c.createdAt.year, c.createdAt.month, c.createdAt.day);
      return date.isAfter(lastWeek) && date.isBefore(yesterday);
    }).toList();

    final lastMonthCustomers = customers.where((c) {
      final date = DateTime(c.createdAt.year, c.createdAt.month, c.createdAt.day);
      return date.isAfter(lastMonth) && date.isBefore(lastWeek);
    }).toList();

    final olderCustomers = customers.where((c) {
      final date = DateTime(c.createdAt.year, c.createdAt.month, c.createdAt.day);
      return date.isBefore(lastMonth);
    }).toList();

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      children: [
        if (todayCustomers.isNotEmpty)
          _buildExpandableGroup(
            context: context,
            title: 'Today',
            count: todayCustomers.length,
            color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
            children: todayCustomers,
          ),
        if (yesterdayCustomers.isNotEmpty)
          _buildExpandableGroup(
            context: context,
            title: 'Yesterday',
            count: yesterdayCustomers.length,
            color: Theme.of(context).colorScheme.secondary.withOpacity(0.1),
            children: yesterdayCustomers,
          ),
        if (lastWeekCustomers.isNotEmpty)
          _buildExpandableGroup(
            context: context,
            title: 'Last Week',
            count: lastWeekCustomers.length,
            color: Theme.of(context).colorScheme.tertiary.withOpacity(0.1),
            children: lastWeekCustomers,
          ),
        if (lastMonthCustomers.isNotEmpty)
          _buildExpandableGroup(
            context: context,
            title: 'Last Month',
            count: lastMonthCustomers.length,
            color: Theme.of(context).colorScheme.surfaceVariant,
            children: lastMonthCustomers,
          ),
        if (olderCustomers.isNotEmpty)
          _buildExpandableGroup(
            context: context,
            title: 'Older',
            count: olderCustomers.length,
            color: Theme.of(context).colorScheme.surfaceVariant,
            children: olderCustomers,
          ),
      ],
    );
  }

  Widget _buildExpandableGroup({
    required BuildContext context,
    required String title,
    required int count,
    required List<Customer> children,
    Color? color,
  }) {
    final theme = Theme.of(context);
    
    // Calculate referral counts if needed
    final referralCounts = filter.showTopReferrers ? Map.fromEntries(
      children.map((customer) => MapEntry(
        customer.id,
        children.where((c) => c.referredBy == customer.id).length,
      )),
    ) : null;
    
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      margin: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: theme.colorScheme.shadow.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Theme(
        data: theme.copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          initiallyExpanded: false, // Changed to false to start collapsed
          maintainState: true,
          tilePadding: EdgeInsets.zero,
          title: Container(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: color ?? theme.colorScheme.surfaceVariant,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    _getGroupIcon(title),
                    size: 20,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      '$count ${count == 1 ? 'customer' : 'customers'}',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          trailing: Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Icon(
              Icons.chevron_right,
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          children: [
            const Divider(height: 1),
            AnimatedSize(
              duration: const Duration(milliseconds: 200),
              child: Container(
                padding: const EdgeInsets.all(16),
                child: layoutType == CustomerLayoutType.grid && isDesktop
                    ? GridView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          childAspectRatio: 1.2,
                          mainAxisSpacing: 12,
                          crossAxisSpacing: 12,
                        ),
                        itemCount: children.length,
                        itemBuilder: (context, index) => 
                            _buildGridCard(
                              context, 
                              children[index],
                              referralCount: referralCounts?[children[index].id] ?? 0, // Always pass the count
                              rank: filter.showTopReferrers ? index + 1 : null,
                            ),
                      )
                    : ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: children.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 12),
                        itemBuilder: (context, index) =>
                            _buildCustomerCard(
                              context, 
                              children[index],
                              referralCount: referralCounts?[children[index].id] ?? 0, // Always pass the count
                              rank: filter.showTopReferrers ? index + 1 : null,
                            ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  IconData _getGroupIcon(String title) {
    switch (title.toLowerCase()) {
      case 'male':
        return Icons.male;
      case 'female':
        return Icons.female;
      case 'today':
        return Icons.today;
      case 'yesterday':
        return Icons.history;
      case 'last week':
        return Icons.calendar_today;
      case 'last month':
        return Icons.calendar_month;
      case 'older':
        return Icons.calendar_view_month;
      case 'referrers':
        return Icons.people;
      case 'referred customers':
        return Icons.person_add;
      case 'family members':
        return Icons.family_restroom;
      case 'independent':
        return Icons.person_outline;
      case 'others':
        return Icons.group_outlined;
      default:
        return Icons.group;
    }
  }

  Widget _buildRegularList(List<Customer> customers) {
    // Calculate referral counts for all customers
    final referralCounts = Map.fromEntries(
      customers.map((customer) => MapEntry(
        customer.id,
        customers.where((c) => c.referredBy == customer.id).length,
      )),
    );

    if (layoutType == CustomerLayoutType.grid && isDesktop) {
      return GridView.builder(
        padding: const EdgeInsets.all(12),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 4,
          childAspectRatio: 1.2,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
        ),
        itemCount: customers.length,
        itemBuilder: (context, index) => _buildGridCard(
          context, 
          customers[index],
          referralCount: referralCounts[customers[index].id] ?? 0, // Always pass the count
          rank: filter.showTopReferrers ? index + 1 : null,
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: customers.length,
      itemBuilder: (context, index) => _buildCustomerCard(
        context, 
        customers[index],
        referralCount: referralCounts[customers[index].id] ?? 0, // Always pass the count
        rank: filter.showTopReferrers ? index + 1 : null,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<Customer>>(
      stream: SupabaseService().getCustomersStream(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return _buildErrorState(context, snapshot.error.toString());
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final customers = snapshot.data ?? [];
        var filteredCustomers = customers
            .where((customer) => _filterCustomer(customer, searchQuery, customers))
            .toList();

        // Calculate referral counts for all customers
        final referralCounts = Map.fromEntries(
          customers.map((customer) => MapEntry(
            customer.id,
            customers.where((c) => c.referredBy == customer.id).length,
          )),
        );

        // Sort by referral count if needed
        if (filter.showTopReferrers) {
          filteredCustomers.sort((a, b) {
            final aCount = referralCounts[a.id] ?? 0;
            final bCount = referralCounts[b.id] ?? 0;
            return bCount.compareTo(aCount);
          });
        }

        if (customers.isEmpty) {
          return _buildEmptyState(context);
        }

        if (filteredCustomers.isEmpty) {
          return _buildNoResultsState(context);
        }

        return _buildGroupedList(filteredCustomers, context);
      },
    );
  }

  bool _filterCustomer(Customer customer, String query, List<Customer> allCustomers) {
    if (!filter.hasActiveFilters && query.isEmpty) return true;

    bool matches = true;

    // Search query filter
    if (query.isNotEmpty) {
      final queryLower = query.toLowerCase();
      matches = matches && (
        customer.name.toLowerCase().contains(queryLower) ||
        customer.phone.toLowerCase().contains(queryLower) ||
        customer.billNumber.toLowerCase().contains(queryLower)
      );
    }

    // Gender filter
    if (filter.selectedGenders.isNotEmpty) {
      matches = matches && filter.selectedGenders.contains(customer.gender);
    }

    // Date range filter
    if (filter.dateRange != null) {
      matches = matches && (
        customer.createdAt.isAfter(filter.dateRange!.start.subtract(const Duration(days: 1))) &&
        customer.createdAt.isBefore(filter.dateRange!.end.add(const Duration(days: 1)))
      );
    }

    // WhatsApp filter
    if (filter.hasWhatsapp) {
      matches = matches && customer.whatsapp.isNotEmpty;
    }

    // Address filter
    if (filter.hasAddress) {
      matches = matches && customer.address.isNotEmpty;
    }

    // Family filter
    if (filter.hasFamilyMembers) {
      matches = matches && customer.familyId != null;
    }

    // Referrer filter
    if (filter.isReferrer) {
      matches = matches && customer.referredBy != null;
    }

    // Top referrers filter
    if (filter.showTopReferrers) {
      // Get the count of referrals for this customer
      final referralCount = allCustomers.where((c) => c.referredBy == customer.id).length;
      matches = matches && referralCount > 0;
    }

    return matches;
  }


  Widget _buildErrorState(BuildContext context, String error) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            size: 64,
            color: Theme.of(context).colorScheme.error,
          ),
          const SizedBox(height: 16),
          Text(
            'Something went wrong',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          Text(
            error,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.error,
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.group_outlined,
            size: 64,
            color: theme.colorScheme.outline,
          ),
          const SizedBox(height: 16),
          Text(
            'No customers yet',
            style: theme.textTheme.titleLarge?.copyWith(
              color: theme.colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Add your first customer to get started',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNoResultsState(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.search_off_outlined,
            size: 64,
            color: theme.colorScheme.outline,
          ),
          const SizedBox(height: 16),
          Text(
            'No results found',
            style: theme.textTheme.titleLarge?.copyWith(
              color: theme.colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Try adjusting your search',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}
