import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:intl/intl.dart';
import '../../../models/invoice.dart';
import '../../../services/invoice_service.dart';
import '../../../theme/inventory_design_config.dart';
import '../pdf_preview_widget.dart';
import '../../measurement/desktop/measurement_detail_dialog.dart';
import '../../../services/measurement_service.dart';
import 'add_invoice_desktop_dialog.dart';

class InvoiceDetailsDialogDesktop extends StatefulWidget {
  final Invoice invoice;
  final VoidCallback? onUpdated;

  const InvoiceDetailsDialogDesktop({
    super.key,
    required this.invoice,
    this.onUpdated,
  });

  static Future<void> show(
    BuildContext context,
    Invoice invoice, {
    VoidCallback? onUpdated,
  }) {
    return showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (context) => InvoiceDetailsDialogDesktop(
        invoice: invoice,
        onUpdated: onUpdated,
      ),
    );
  }

  @override
  State<InvoiceDetailsDialogDesktop> createState() =>
      _InvoiceDetailsDialogDesktopState();
}

class _InvoiceDetailsDialogDesktopState
    extends State<InvoiceDetailsDialogDesktop> {
  final InvoiceService _invoiceService = InvoiceService();
  final _noteController = TextEditingController();
  final MeasurementService _measurementService = MeasurementService();
  late Invoice _invoice;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _invoice = widget.invoice;
  }

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  String _enumValueToSnakeCase(String value) {
    if (value == 'inProgress') {
      return 'in_progress';
    }
    return value.toLowerCase();
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final maxHeight = screenSize.height * 0.9;
    final maxWidth = screenSize.width * 0.8;

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: maxWidth > 1200 ? 1200 : maxWidth,
          maxHeight: maxHeight,
        ),
        child: Container(
          decoration: BoxDecoration(
            color: InventoryDesignConfig.surfaceColor,
            borderRadius: BorderRadius.circular(InventoryDesignConfig.radiusXL),
            border: Border.all(color: InventoryDesignConfig.borderPrimary),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.08),
                blurRadius: 24,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: _isLoading ? _buildLoadingState() : _buildContent(),
        ),
      ),
    );
  }

  Widget _buildLoadingState() {
    return Container(
      height: 400,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(InventoryDesignConfig.spacingXXL),
              decoration: BoxDecoration(
                color: InventoryDesignConfig.surfaceAccent,
                borderRadius: BorderRadius.circular(
                  InventoryDesignConfig.radiusL,
                ),
              ),
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(
                  InventoryDesignConfig.primaryColor,
                ),
              ),
            ),
            const SizedBox(height: InventoryDesignConfig.spacingXXL),
            Text(
              'Loading invoice details...',
              style: InventoryDesignConfig.titleMedium,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent() {
    return Column(
      children: [
        _buildHeader(),
        Expanded(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Left Panel - Fixed width with consistent spacing
              Container(
                width: 320,
                decoration: BoxDecoration(
                  color: InventoryDesignConfig.surfaceLight,
                  border: Border(
                    right: BorderSide(
                      color: InventoryDesignConfig.borderSecondary,
                    ),
                  ),
                ),
                child: _buildLeftPanel(),
              ),
              // Main Content - Flexible width with consistent padding
              Expanded(child: _buildMainContent()),
            ],
          ),
        ),
        _buildFooter(),
      ],
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(InventoryDesignConfig.spacingXXL),
      decoration: BoxDecoration(
        color: InventoryDesignConfig.surfaceAccent,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(InventoryDesignConfig.radiusXL),
          topRight: Radius.circular(InventoryDesignConfig.radiusXL),
        ),
        border: Border(
          bottom: BorderSide(color: InventoryDesignConfig.borderSecondary),
        ),
      ),
      child: Row(
        children: [
          // Avatar and basic info
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: InventoryDesignConfig.primaryColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(
                InventoryDesignConfig.radiusM,
              ),
            ),
            child: Icon(
              PhosphorIcons.receipt(PhosphorIconsStyle.fill),
              size: 20,
              color: InventoryDesignConfig.primaryColor,
            ),
          ),
          const SizedBox(width: InventoryDesignConfig.spacingL),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Invoice #${_invoice.invoiceNumber}',
                  style: InventoryDesignConfig.headlineMedium.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: InventoryDesignConfig.spacingXS),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: InventoryDesignConfig.spacingS,
                        vertical: InventoryDesignConfig.spacingXS,
                      ),
                      decoration: BoxDecoration(
                        color: InventoryDesignConfig.primaryColor
                            .withOpacity(0.1),
                        borderRadius: BorderRadius.circular(
                          InventoryDesignConfig.radiusS,
                        ),
                      ),
                      child: Text(
                        'Bill #${_invoice.customerBillNumber}',
                        style: InventoryDesignConfig.bodySmall.copyWith(
                          color: InventoryDesignConfig.primaryColor,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const SizedBox(width: InventoryDesignConfig.spacingS),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: InventoryDesignConfig.spacingS,
                        vertical: InventoryDesignConfig.spacingXS,
                      ),
                      decoration: BoxDecoration(
                        color: _getPaymentStatusColor(_invoice.paymentStatus)
                            .withOpacity(0.12),
                        borderRadius: BorderRadius.circular(
                          InventoryDesignConfig.radiusS,
                        ),
                      ),
                      child: Text(
                        _invoice.paymentStatus.name.toUpperCase(),
                        style: InventoryDesignConfig.bodySmall.copyWith(
                          color: _getPaymentStatusColor(_invoice.paymentStatus),
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.6,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          // Action buttons
          Row(
            children: [
              _buildHeaderActionButton(
                icon: PhosphorIcons.pencilSimple(PhosphorIconsStyle.regular),
                label: 'Edit',
                onPressed: _editInvoice,
                isPrimary: false,
              ),
              const SizedBox(width: InventoryDesignConfig.spacingM),
              _buildHeaderActionButton(
                icon: PhosphorIcons.filePdf(PhosphorIconsStyle.fill),
                label: 'Generate PDF',
                onPressed: () => _showInvoicePreview(context),
                isPrimary: true,
              ),
              const SizedBox(width: InventoryDesignConfig.spacingM),
              _buildHeaderActionButton(
                icon: PhosphorIcons.x(PhosphorIconsStyle.regular),
                label: 'Close',
                onPressed: () => Navigator.of(context).pop(),
                isPrimary: false,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildHeaderActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onPressed,
    required bool isPrimary,
  }) {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(InventoryDesignConfig.radiusM),
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(InventoryDesignConfig.radiusM),
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: InventoryDesignConfig.spacingL,
            vertical: InventoryDesignConfig.spacingM,
          ),
          decoration:
              isPrimary
                  ? InventoryDesignConfig.buttonPrimaryDecoration
                  : InventoryDesignConfig.buttonSecondaryDecoration,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 16,
                color:
                    isPrimary
                        ? Colors.white
                        : InventoryDesignConfig.textSecondary,
              ),
              const SizedBox(width: InventoryDesignConfig.spacingXS),
              Text(
                label,
                style: InventoryDesignConfig.bodyMedium.copyWith(
                  color:
                      isPrimary
                          ? Colors.white
                          : InventoryDesignConfig.textSecondary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLeftPanel() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(InventoryDesignConfig.spacingXL),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildModernInfoCard(
            title: 'Customer Information',
            icon: PhosphorIcons.user(PhosphorIconsStyle.fill),
            color: InventoryDesignConfig.primaryColor,
            content: [
              _buildModernInfoRow('Name', _invoice.customerName),
              _buildModernInfoRow('Phone', _invoice.customerPhone),
              _buildModernInfoRow('Bill Number', _invoice.customerBillNumber),
            ],
          ),
          const SizedBox(height: InventoryDesignConfig.spacingXL),
          _buildModernDateCard(),
          const SizedBox(height: InventoryDesignConfig.spacingXL),
          if (_invoice.measurementName != null) ...[
            _buildModernMeasurementCard(),
            const SizedBox(height: InventoryDesignConfig.spacingXL),
          ],
          _buildModernFinancialSummaryCard(),
        ],
      ),
    );
  }

  Widget _buildMainContent() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(InventoryDesignConfig.spacingXXL),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Products Section
          _buildModernSection(
            title: 'Products & Services',
            icon: PhosphorIcons.package(PhosphorIconsStyle.fill),
            color: InventoryDesignConfig.successColor,
            child: _buildProductsList(),
          ),
          const SizedBox(height: InventoryDesignConfig.spacingXXL),
          
          // Payment Management Section
          _buildModernSection(
            title: 'Payment Management',
            icon: PhosphorIcons.creditCard(PhosphorIconsStyle.fill),
            color: InventoryDesignConfig.infoColor,
            child: _buildPaymentManagement(),
          ),
          const SizedBox(height: InventoryDesignConfig.spacingXXL),
          
          // Status Management Section
          _buildModernSection(
            title: 'Status Management',
            icon: PhosphorIcons.gear(PhosphorIconsStyle.fill),
            color: InventoryDesignConfig.warningColor,
            child: _buildStatusManagement(),
          ),
          const SizedBox(height: InventoryDesignConfig.spacingXXL),
          
          // Notes Section
          _buildModernSection(
            title: 'Notes & Comments',
            icon: PhosphorIcons.notepad(PhosphorIconsStyle.fill),
            color: InventoryDesignConfig.primaryColor,
            child: _buildNotesSection(),
          ),
        ],
      ),
    );
  }

  Widget _buildModernInfoCard({
    required String title,
    required IconData icon,
    required Color color,
    required List<Widget> content,
  }) {
    return Container(
      width: double.infinity,
      decoration: InventoryDesignConfig.cardDecoration,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(InventoryDesignConfig.spacingL),
            decoration: BoxDecoration(
              color: color.withOpacity(0.05),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(InventoryDesignConfig.radiusL),
                topRight: Radius.circular(InventoryDesignConfig.radiusL),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(InventoryDesignConfig.spacingS),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(
                      InventoryDesignConfig.radiusS,
                    ),
                  ),
                  child: Icon(icon, size: 16, color: color),
                ),
                const SizedBox(width: InventoryDesignConfig.spacingM),
                Expanded(
                  child: Text(
                    title,
                    style: InventoryDesignConfig.titleMedium.copyWith(
                      fontWeight: FontWeight.w600,
                      color: color,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(InventoryDesignConfig.spacingL),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: content,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModernInfoRow(String label, String value) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: InventoryDesignConfig.spacingM),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: InventoryDesignConfig.bodySmall.copyWith(
              color: InventoryDesignConfig.textSecondary,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: InventoryDesignConfig.spacingXS),
          Text(
            value,
            style: InventoryDesignConfig.bodyLarge.copyWith(
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModernDateCard() {
    return _buildModernInfoCard(
      title: 'Timeline',
      icon: PhosphorIcons.calendar(PhosphorIconsStyle.fill),
      color: InventoryDesignConfig.warningColor,
      content: [
        _buildModernInfoRow(
          'Invoice Date',
          DateFormat('MMM dd, yyyy • hh:mm a').format(_invoice.date),
        ),
        _buildModernInfoRow(
          'Delivery Date',
          DateFormat('MMM dd, yyyy').format(_invoice.deliveryDate),
        ),
        if (_invoice.deliveredAt != null)
          _buildModernInfoRow(
            'Delivered On',
            DateFormat('MMM dd, yyyy • hh:mm a').format(_invoice.deliveredAt!),
          ),
      ],
    );
  }

  Widget _buildModernMeasurementCard() {
    return _buildModernInfoCard(
      title: 'Measurement Details',
      icon: PhosphorIcons.ruler(PhosphorIconsStyle.fill),
      color: InventoryDesignConfig.successColor,
      content: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(InventoryDesignConfig.spacingM),
          decoration: BoxDecoration(
            color: InventoryDesignConfig.surfaceAccent,
            borderRadius: BorderRadius.circular(InventoryDesignConfig.radiusS),
            border: Border.all(color: InventoryDesignConfig.borderPrimary),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _invoice.measurementName!,
                style: InventoryDesignConfig.bodyLarge.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: InventoryDesignConfig.spacingS),
              FilledButton.icon(
                onPressed: _viewMeasurementDetails,
                icon: Icon(PhosphorIcons.eye(PhosphorIconsStyle.regular), size: 14),
                label: const Text('View Details'),
                style: FilledButton.styleFrom(
                  backgroundColor: InventoryDesignConfig.successColor,
                  foregroundColor: Colors.white,
                  minimumSize: const Size(double.infinity, 36),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(InventoryDesignConfig.radiusS),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildModernFinancialSummaryCard() {
    final totalPaid = _invoice.netTotal - _invoice.balance;

    List<Widget> financialDetails = [
      _buildSummaryRow('Subtotal', _invoice.amount),
      _buildSummaryRow('VAT', _invoice.vat),
      _buildSummaryRow('Net Total', _invoice.netTotal),
      const Divider(color: InventoryDesignConfig.borderSecondary),
      _buildSummaryRow('Total Paid', totalPaid, color: InventoryDesignConfig.successColor),
      const Divider(color: InventoryDesignConfig.borderSecondary),
    ];

    if (_invoice.paymentStatus == PaymentStatus.paid) {
      financialDetails.add(_buildPaidSummary());
      if (_invoice.balance < 0) {
        financialDetails.add(
          Padding(
            padding: const EdgeInsets.only(top: InventoryDesignConfig.spacingS),
            child: _buildSummaryRow(
              'Overpaid',
              _invoice.balance.abs(),
              isHighlight: true,
              color: InventoryDesignConfig.warningColor,
            ),
          )
        );
      }
    } else {
      financialDetails.add(_buildSummaryRow(
        'Balance Due',
        _invoice.balance,
        isHighlight: true,
        color: InventoryDesignConfig.errorColor,
      ));
    }

    return _buildModernInfoCard(
      title: 'Financial Summary',
      icon: PhosphorIcons.currencyDollar(PhosphorIconsStyle.fill),
      color: InventoryDesignConfig.infoColor,
      content: financialDetails,
    );
  }

  Widget _buildPaidSummary() {
    return Container(
      padding: const EdgeInsets.all(InventoryDesignConfig.spacingM),
      decoration: BoxDecoration(
        color: InventoryDesignConfig.successColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(InventoryDesignConfig.radiusM),
      ),
      child: Row(
        children: [
          Icon(
            PhosphorIcons.checkCircle(PhosphorIconsStyle.fill),
            color: InventoryDesignConfig.successColor,
            size: 24,
          ),
          const SizedBox(width: InventoryDesignConfig.spacingM),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Fully Paid',
                  style: InventoryDesignConfig.titleMedium.copyWith(
                    fontWeight: FontWeight.w700,
                    color: InventoryDesignConfig.successColor,
                  ),
                ),
                if (_invoice.paidAt != null)
                  Text(
                    'on ${DateFormat('MMM dd, yyyy').format(_invoice.paidAt!)}',
                    style: InventoryDesignConfig.bodySmall.copyWith(
                      color: InventoryDesignConfig.successColor,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryRow(
    String label,
    double amount, {
    bool isHighlight = false,
    Color? color,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: InventoryDesignConfig.spacingXS),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: InventoryDesignConfig.bodyMedium.copyWith(
              fontWeight: isHighlight ? FontWeight.w600 : FontWeight.normal,
              color: color,
            ),
          ),
          Text(
            NumberFormat.currency(symbol: 'AED ').format(amount),
            style: InventoryDesignConfig.bodyMedium.copyWith(
              fontWeight: isHighlight ? FontWeight.w700 : FontWeight.w500,
              color: color ?? InventoryDesignConfig.textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModernSection({
    required String title,
    required IconData icon,
    required Color color,
    required Widget child,
  }) {
    return Container(
      width: double.infinity,
      decoration: InventoryDesignConfig.cardDecoration,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(InventoryDesignConfig.spacingXL),
            decoration: BoxDecoration(
              color: color.withOpacity(0.05),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(InventoryDesignConfig.radiusL),
                topRight: Radius.circular(InventoryDesignConfig.radiusL),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(InventoryDesignConfig.spacingM),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(
                      InventoryDesignConfig.radiusM,
                    ),
                  ),
                  child: Icon(icon, size: 20, color: color),
                ),
                const SizedBox(width: InventoryDesignConfig.spacingL),
                Text(
                  title,
                  style: InventoryDesignConfig.headlineMedium.copyWith(
                    color: color,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(InventoryDesignConfig.spacingXL),
            child: child,
          ),
        ],
      ),
    );
  }

  Widget _buildProductsList() {
    if (_invoice.products.isEmpty) {
      return _buildEmptyState(
        icon: PhosphorIcons.package(),
        title: 'No Products',
        description: 'No products have been added to this invoice.',
      );
    }

    return Column(
      children: _invoice.products.map((product) {
        return Container(
          margin: const EdgeInsets.only(bottom: InventoryDesignConfig.spacingM),
          padding: const EdgeInsets.all(InventoryDesignConfig.spacingL),
          decoration: BoxDecoration(
            color: InventoryDesignConfig.surfaceLight,
            borderRadius: BorderRadius.circular(InventoryDesignConfig.radiusM),
            border: Border.all(color: InventoryDesignConfig.borderPrimary),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(InventoryDesignConfig.spacingS),
                decoration: BoxDecoration(
                  color: InventoryDesignConfig.successColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(InventoryDesignConfig.radiusS),
                ),
                child: Icon(
                  PhosphorIcons.package(),
                  size: 16,
                  color: InventoryDesignConfig.successColor,
                ),
              ),
              const SizedBox(width: InventoryDesignConfig.spacingM),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      product.name,
                      style: InventoryDesignConfig.titleMedium.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: InventoryDesignConfig.spacingXS),
                    Text(
                      'Price: ${NumberFormat.currency(symbol: 'AED ').format(product.price)}',
                      style: InventoryDesignConfig.bodyMedium.copyWith(
                        color: InventoryDesignConfig.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildPaymentManagement() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Payment Actions
        if (_invoice.remainingBalance > 0 && _invoice.paymentStatus != PaymentStatus.paid) ...[
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: _handlePayment,
              icon: Icon(PhosphorIcons.creditCard(), size: 16),
              label: Text('Add Payment (${NumberFormat.currency(symbol: 'AED ').format(_invoice.remainingBalance)} remaining)'),
              style: FilledButton.styleFrom(
                backgroundColor: InventoryDesignConfig.successColor,
                foregroundColor: Colors.white,
                minimumSize: const Size(double.infinity, 48),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(InventoryDesignConfig.radiusM),
                ),
              ),
            ),
          ),
          const SizedBox(height: InventoryDesignConfig.spacingM),
        ],
        
        if (_invoice.paymentStatus == PaymentStatus.paid && !_invoice.isRefunded) ...[
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: _handleRefund,
              icon: Icon(PhosphorIcons.arrowCounterClockwise(), size: 16),
              label: const Text('Process Refund'),
              style: FilledButton.styleFrom(
                backgroundColor: InventoryDesignConfig.errorColor,
                foregroundColor: Colors.white,
                minimumSize: const Size(double.infinity, 48),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(InventoryDesignConfig.radiusM),
                ),
              ),
            ),
          ),
          const SizedBox(height: InventoryDesignConfig.spacingM),
        ],

        // Payment History
        if (_invoice.payments.isNotEmpty) ...[
          const SizedBox(height: InventoryDesignConfig.spacingL),
          Text(
            'Payment History',
            style: InventoryDesignConfig.titleLarge.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: InventoryDesignConfig.spacingM),
          ..._invoice.payments.map((payment) {
            return Container(
              margin: const EdgeInsets.only(bottom: InventoryDesignConfig.spacingS),
              padding: const EdgeInsets.all(InventoryDesignConfig.spacingM),
              decoration: BoxDecoration(
                color: InventoryDesignConfig.surfaceLight,
                borderRadius: BorderRadius.circular(InventoryDesignConfig.radiusM),
                border: Border.all(color: InventoryDesignConfig.borderPrimary),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(InventoryDesignConfig.spacingS),
                    decoration: BoxDecoration(
                      color: payment.amount > 0 
                        ? InventoryDesignConfig.successColor.withOpacity(0.1)
                        : InventoryDesignConfig.errorColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(InventoryDesignConfig.radiusS),
                    ),
                    child: Icon(
                      payment.amount > 0 
                        ? PhosphorIcons.arrowUp()
                        : PhosphorIcons.arrowDown(),
                      size: 14,
                      color: payment.amount > 0 
                        ? InventoryDesignConfig.successColor
                        : InventoryDesignConfig.errorColor,
                    ),
                  ),
                  const SizedBox(width: InventoryDesignConfig.spacingM),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          NumberFormat.currency(symbol: 'AED ').format(payment.amount.abs()),
                          style: InventoryDesignConfig.titleMedium.copyWith(
                            fontWeight: FontWeight.w600,
                            color: payment.amount > 0 
                              ? InventoryDesignConfig.successColor
                              : InventoryDesignConfig.errorColor,
                          ),
                        ),
                        ...[
                        const SizedBox(height: InventoryDesignConfig.spacingXS),
                        Text(
                          payment.note,
                          style: InventoryDesignConfig.bodySmall.copyWith(
                            color: InventoryDesignConfig.textSecondary,
                          ),
                        ),
                      ],
                      ],
                    ),
                  ),
                  Text(
                    DateFormat('MMM dd, yyyy').format(payment.date),
                    style: InventoryDesignConfig.bodySmall.copyWith(
                      color: InventoryDesignConfig.textSecondary,
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        ] else ...[
          _buildEmptyState(
            icon: PhosphorIcons.creditCard(),
            title: 'No Payments',
            description: 'No payments have been recorded for this invoice.',
          ),
        ],
      ],
    );
  }

  Widget _buildStatusManagement() {
    return Column(
      children: [
        _buildModernStatusDropdown(
          'Delivery Status',
          _enumValueToSnakeCase(_invoice.deliveryStatus.name),
          InvoiceStatus.values.map((e) => _enumValueToSnakeCase(e.name)).toList(),
          (value) => _updateDeliveryStatus(value),
          PhosphorIcons.truck(),
        ),
        const SizedBox(height: InventoryDesignConfig.spacingL),
        _buildModernStatusDropdown(
          'Payment Status',
          _invoice.paymentStatus.name,
          PaymentStatus.values.map((e) => e.name).toList(),
          (value) => _updatePaymentStatus(value),
          PhosphorIcons.creditCard(),
        ),
      ],
    );
  }

  Widget _buildModernStatusDropdown(
    String label,
    String currentValue,
    List<String> options,
    Function(String) onChanged,
    IconData icon,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 16, color: InventoryDesignConfig.primaryColor),
            const SizedBox(width: InventoryDesignConfig.spacingS),
            Text(
              label,
              style: InventoryDesignConfig.titleMedium.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        const SizedBox(height: InventoryDesignConfig.spacingM),
        Container(
          decoration: BoxDecoration(
            color: InventoryDesignConfig.surfaceLight,
            borderRadius: BorderRadius.circular(InventoryDesignConfig.radiusM),
            border: Border.all(color: InventoryDesignConfig.borderPrimary),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: currentValue,
              isExpanded: true,
              padding: const EdgeInsets.symmetric(horizontal: InventoryDesignConfig.spacingL),
              borderRadius: BorderRadius.circular(InventoryDesignConfig.radiusM),
              items: options.map((option) {
                final isSelected = option == currentValue;
                return DropdownMenuItem(
                  value: option,
                  child: Row(
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: _getStatusColor(option),
                        ),
                      ),
                      const SizedBox(width: InventoryDesignConfig.spacingM),
                      Text(
                        option.replaceAll('_', ' ').toUpperCase(),
                        style: InventoryDesignConfig.bodyLarge.copyWith(
                          color: isSelected 
                              ? InventoryDesignConfig.primaryColor
                              : InventoryDesignConfig.textPrimary,
                          fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
              onChanged: (value) => value != null ? onChanged(value) : null,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildNotesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Add Note Input
        Container(
          decoration: BoxDecoration(
            color: InventoryDesignConfig.surfaceLight,
            borderRadius: BorderRadius.circular(InventoryDesignConfig.radiusM),
            border: Border.all(color: InventoryDesignConfig.borderPrimary),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _noteController,
                maxLines: 3,
                style: InventoryDesignConfig.bodyLarge,
                decoration: InputDecoration(
                  hintText: 'Add a note or comment...',
                  hintStyle: InventoryDesignConfig.bodyMedium.copyWith(
                    color: InventoryDesignConfig.textTertiary,
                  ),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.all(InventoryDesignConfig.spacingL),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(InventoryDesignConfig.spacingM),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    FilledButton.icon(
                      onPressed: _addNote,
                      icon: Icon(PhosphorIcons.plus(), size: 16),
                      label: const Text('Add Note'),
                      style: FilledButton.styleFrom(
                        backgroundColor: InventoryDesignConfig.primaryColor,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(InventoryDesignConfig.radiusM),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        // Notes List
        if (_invoice.notes.isNotEmpty) ...[
          const SizedBox(height: InventoryDesignConfig.spacingXL),
          Text(
            'Previous Notes (${_invoice.notes.length})',
            style: InventoryDesignConfig.titleLarge.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: InventoryDesignConfig.spacingM),
          ..._invoice.notes.asMap().entries.map((entry) {
            final index = entry.key;
            final note = entry.value;
            return Container(
              margin: const EdgeInsets.only(bottom: InventoryDesignConfig.spacingM),
              padding: const EdgeInsets.all(InventoryDesignConfig.spacingL),
              decoration: BoxDecoration(
                color: InventoryDesignConfig.surfaceLight,
                borderRadius: BorderRadius.circular(InventoryDesignConfig.radiusM),
                border: Border.all(color: InventoryDesignConfig.borderPrimary),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(InventoryDesignConfig.spacingS),
                    decoration: BoxDecoration(
                      color: InventoryDesignConfig.primaryColor.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      PhosphorIcons.note(),
                      size: 14,
                      color: InventoryDesignConfig.primaryColor,
                    ),
                  ),
                  const SizedBox(width: InventoryDesignConfig.spacingM),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          note,
                          style: InventoryDesignConfig.bodyLarge.copyWith(
                            height: 1.5,
                          ),
                        ),
                        const SizedBox(height: InventoryDesignConfig.spacingS),
                        Text(
                          DateFormat('MMM dd, yyyy • hh:mm a').format(DateTime.now()),
                          style: InventoryDesignConfig.bodySmall.copyWith(
                            color: InventoryDesignConfig.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => _deleteNote(index),
                    icon: Icon(
                      PhosphorIcons.trash(),
                      size: 16,
                      color: InventoryDesignConfig.errorColor,
                    ),
                    tooltip: 'Delete Note',
                  ),
                ],
              ),
            );
          }).toList(),
        ] else ...[
          const SizedBox(height: InventoryDesignConfig.spacingXL),
          _buildEmptyState(
            icon: PhosphorIcons.note(),
            title: 'No Notes',
            description: 'Add your first note or comment above.',
          ),
        ],
      ],
    );
  }

  Widget _buildEmptyState({
    required IconData icon,
    required String title,
    required String description,
  }) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(InventoryDesignConfig.spacingXXL),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(InventoryDesignConfig.spacingXL),
              decoration: BoxDecoration(
                color: InventoryDesignConfig.surfaceAccent,
                borderRadius: BorderRadius.circular(InventoryDesignConfig.radiusL),
              ),
              child: Icon(
                icon,
                size: 48,
                color: InventoryDesignConfig.textTertiary,
              ),
            ),
            const SizedBox(height: InventoryDesignConfig.spacingL),
            Text(
              title,
              style: InventoryDesignConfig.titleLarge.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: InventoryDesignConfig.spacingS),
            Text(
              description,
              style: InventoryDesignConfig.bodyMedium.copyWith(
                color: InventoryDesignConfig.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFooter() {
    return Container(
      padding: const EdgeInsets.all(InventoryDesignConfig.spacingXL),
      decoration: BoxDecoration(
        color: InventoryDesignConfig.surfaceAccent,
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(InventoryDesignConfig.radiusXL),
          bottomRight: Radius.circular(InventoryDesignConfig.radiusXL),
        ),
        border: Border(
          top: BorderSide(color: InventoryDesignConfig.borderSecondary),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Text(
            'Last updated: ${DateFormat('MMM dd, yyyy • hh:mm a').format(DateTime.now())}',
            style: InventoryDesignConfig.bodySmall.copyWith(
              color: InventoryDesignConfig.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  // Helper methods for colors
  Color _getPaymentStatusColor(PaymentStatus status) {
    switch (status) {
      case PaymentStatus.paid:
        return InventoryDesignConfig.successColor;
      case PaymentStatus.partial:
        return InventoryDesignConfig.warningColor;
      case PaymentStatus.unpaid:
        return InventoryDesignConfig.errorColor;
      case PaymentStatus.refunded:
        return InventoryDesignConfig.textSecondary;
    }
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'delivered':
      case 'paid':
        return InventoryDesignConfig.successColor;
      case 'in_progress':
      case 'partial':
        return InventoryDesignConfig.warningColor;
      case 'pending':
      case 'unpaid':
        return InventoryDesignConfig.errorColor;
      case 'cancelled':
      case 'refunded':
        return InventoryDesignConfig.textSecondary;
      default:
        return InventoryDesignConfig.primaryColor;
    }
  }

  // Action methods
  Future<void> _updateDeliveryStatus(String status) async {
    setState(() {
      _invoice.deliveryStatus = InvoiceStatus.values.firstWhere(
          (e) => _enumValueToSnakeCase(e.name) == status,
          orElse: () => _invoice.deliveryStatus);
      if (_invoice.deliveryStatus == InvoiceStatus.delivered) {
        _invoice.deliveredAt = DateTime.now();
      }
    });
    await _invoiceService.updateInvoice(_invoice);
    widget.onUpdated?.call();
  }

  Future<void> _updatePaymentStatus(String status) async {
    setState(() {
      _invoice.paymentStatus = PaymentStatus.values.firstWhere(
          (e) => e.name == status,
          orElse: () => _invoice.paymentStatus);
      if (_invoice.paymentStatus == PaymentStatus.paid) {
        _invoice.paidAt = DateTime.now();
      }
    });
    await _invoiceService.updateInvoice(_invoice);
    widget.onUpdated?.call();
  }

  void _updateInternalPaymentStatus() {
    setState(() {
      if (_invoice.balance <= 0) {
        _invoice.paymentStatus = PaymentStatus.paid;
        _invoice.paidAt = DateTime.now();
      } else if (_invoice.payments.isNotEmpty) {
        _invoice.paymentStatus = PaymentStatus.partial;
      } else {
        _invoice.paymentStatus = PaymentStatus.unpaid;
      }
    });
  }

  void _handlePayment() async {
    final controller = TextEditingController();
    final isRefund = _invoice.remainingBalance <= 0;

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(InventoryDesignConfig.radiusL),
        ),
        title: Row(
          children: [
            Icon(
              PhosphorIcons.creditCard(),
              color: InventoryDesignConfig.primaryColor,
            ),
            const SizedBox(width: InventoryDesignConfig.spacingM),
            Text(isRefund ? 'Process Refund' : 'Add Payment'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: controller,
              decoration: InputDecoration(
                labelText: 'Amount',
                prefixText: 'AED ',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(InventoryDesignConfig.radiusM),
                ),
              ),
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
            ),
            const SizedBox(height: InventoryDesignConfig.spacingL),
            Container(
              padding: const EdgeInsets.all(InventoryDesignConfig.spacingM),
              decoration: BoxDecoration(
                color: isRefund 
                  ? InventoryDesignConfig.successColor.withOpacity(0.1)
                  : InventoryDesignConfig.errorColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(InventoryDesignConfig.radiusM),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    isRefund ? 'Overpaid:' : 'Remaining:',
                    style: InventoryDesignConfig.bodyMedium,
                  ),
                  Text(
                    NumberFormat.currency(symbol: 'AED ').format(_invoice.remainingBalance.abs()),
                    style: InventoryDesignConfig.titleMedium.copyWith(
                      fontWeight: FontWeight.w700,
                      color: isRefund 
                        ? InventoryDesignConfig.successColor
                        : InventoryDesignConfig.errorColor,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: InventoryDesignConfig.spacingL),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: () {
                  controller.text = _invoice.remainingBalance.abs().toString();
                },
                icon: Icon(isRefund ? PhosphorIcons.arrowCounterClockwise() : PhosphorIcons.checkCircle()),
                label: Text(isRefund ? 'Full Refund' : 'Complete Balance'),
                style: FilledButton.styleFrom(
                  backgroundColor: isRefund 
                    ? InventoryDesignConfig.errorColor
                    : InventoryDesignConfig.successColor,
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('CANCEL'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(
              backgroundColor: InventoryDesignConfig.primaryColor,
            ),
            child: Text(isRefund ? 'PROCESS REFUND' : 'ADD PAYMENT'),
          ),
        ],
      ),
    );

    if (result == true && controller.text.isNotEmpty) {
      final amount = double.tryParse(controller.text) ?? 0;
      if (amount > 0) {
        final paymentAmount = isRefund ? -amount : amount;
        final note = isRefund
            ? 'Refund processed: ${NumberFormat.currency(symbol: 'AED ').format(amount)}'
            : 'Payment received: ${NumberFormat.currency(symbol: 'AED ').format(amount)}';

        setState(() {
          _invoice.addPayment(paymentAmount, note);
          _updateInternalPaymentStatus();
        });

        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(note),
            backgroundColor: isRefund 
              ? InventoryDesignConfig.errorColor
              : InventoryDesignConfig.successColor,
          ),
        );

        await _invoiceService.updateInvoice(_invoice);
        widget.onUpdated?.call();
      }
    }
    controller.dispose();
  }

  Future<void> _handleRefund() async {
    final controller = TextEditingController();
    final reasonController = TextEditingController();

    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(InventoryDesignConfig.radiusL),
        ),
        title: Row(
          children: [
            Icon(
              PhosphorIcons.arrowCounterClockwise(),
              color: InventoryDesignConfig.errorColor,
            ),
            const SizedBox(width: InventoryDesignConfig.spacingM),
            const Text('Process Refund'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: controller,
              decoration: InputDecoration(
                labelText: 'Refund Amount',
                prefixText: 'AED ',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(InventoryDesignConfig.radiusM),
                ),
              ),
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
            ),
            const SizedBox(height: InventoryDesignConfig.spacingL),
            TextField(
              controller: reasonController,
              decoration: InputDecoration(
                labelText: 'Refund Reason',
                hintText: 'Enter reason for refund',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(InventoryDesignConfig.radiusM),
                ),
              ),
              maxLines: 2,
            ),
            const SizedBox(height: InventoryDesignConfig.spacingL),
            Container(
              padding: const EdgeInsets.all(InventoryDesignConfig.spacingM),
              decoration: BoxDecoration(
                color: InventoryDesignConfig.infoColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(InventoryDesignConfig.radiusM),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Total Paid:',
                    style: InventoryDesignConfig.bodyMedium,
                  ),
                  Text(
                    NumberFormat.currency(symbol: 'AED ').format(_invoice.amountIncludingVat),
                    style: InventoryDesignConfig.titleMedium.copyWith(
                      fontWeight: FontWeight.w700,
                      color: InventoryDesignConfig.infoColor,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('CANCEL'),
          ),
          FilledButton(
            onPressed: () {
              if (controller.text.isEmpty || reasonController.text.isEmpty) {
                return;
              }
              Navigator.pop(context, {
                'amount': double.parse(controller.text),
                'reason': reasonController.text,
              });
            },
            style: FilledButton.styleFrom(
              backgroundColor: InventoryDesignConfig.errorColor,
            ),
            child: const Text('PROCESS REFUND'),
          ),
        ],
      ),
    );

    if (result != null && mounted) {
      try {
        await _invoiceService.processRefund(
          _invoice.id,
          result['amount'],
          result['reason'],
        );

        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Refund processed successfully'),
            backgroundColor: InventoryDesignConfig.successColor,
          ),
        );
        widget.onUpdated?.call();
        setState(() {});
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to process refund: $e'),
            backgroundColor: InventoryDesignConfig.errorColor,
          ),
        );
      }
    }
  }

  void _addNote() async {
    if (_noteController.text.isNotEmpty) {
      setState(() {
        _invoice.addNote(_noteController.text);
        _noteController.clear();
      });
      await _invoiceService.updateInvoice(_invoice);
    }
  }

  void _deleteNote(int index) async {
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(InventoryDesignConfig.radiusL),
        ),
        title: Row(
          children: [
            Icon(
              PhosphorIcons.warning(),
              color: InventoryDesignConfig.errorColor,
            ),
            const SizedBox(width: InventoryDesignConfig.spacingM),
            const Text('Delete Note'),
          ],
        ),
        content: const Text('Are you sure you want to delete this note? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('CANCEL'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(
              backgroundColor: InventoryDesignConfig.errorColor,
            ),
            child: const Text('DELETE'),
          ),
        ],
      ),
    );

    if (shouldDelete == true) {
      setState(() {
        _invoice.deleteNote(index);
      });
      if (!mounted) return;
      await _invoiceService.updateInvoice(_invoice);
    }
  }

  void _showInvoicePreview(BuildContext context) async {
    try {
      final pdfBytes = await _invoiceService.generatePdfBytes(_invoice);
      if (!mounted) return;
      await showDialog(
        context: context,
        builder: (context) => Dialog(
          backgroundColor: Colors.transparent,
          child: Container(
            width: 900,
            height: MediaQuery.of(context).size.height * 0.9,
            decoration: BoxDecoration(
              color: InventoryDesignConfig.surfaceColor,
              borderRadius: BorderRadius.circular(InventoryDesignConfig.radiusXL),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            clipBehavior: Clip.antiAlias,
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(InventoryDesignConfig.spacingL),
                  decoration: BoxDecoration(
                    color: InventoryDesignConfig.surfaceAccent,
                    border: Border(
                      bottom: BorderSide(color: InventoryDesignConfig.borderSecondary),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        PhosphorIcons.filePdf(PhosphorIconsStyle.fill),
                        color: InventoryDesignConfig.primaryColor,
                      ),
                      const SizedBox(width: InventoryDesignConfig.spacingM),
                      Text(
                        'Invoice Preview',
                        style: InventoryDesignConfig.titleLarge.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const Spacer(),
                      IconButton(
                        icon: Icon(PhosphorIcons.x()),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                ),
                Expanded(child: PdfPreviewWidget(pdfBytes: pdfBytes)),
              ],
            ),
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to generate invoice: $e'),
          backgroundColor: InventoryDesignConfig.errorColor,
        ),
      );
    }
  }

  Future<void> _viewMeasurementDetails() async {
    if (_invoice.measurementId == null) return;
    final measurement = await _measurementService.getMeasurement(_invoice.measurementId!);
    if (measurement != null && mounted) {
      await DetailDialog.show(
        context,
        measurement: measurement,
        customerId: _invoice.customerId,
      );
    }
  }

  void _editInvoice() async {
    final updatedInvoice = await AddInvoiceDesktopDialog.show(
      context,
      invoice: _invoice,
    );

    if (updatedInvoice != null && mounted) {
      setState(() {
        _invoice = updatedInvoice;
      });
      widget.onUpdated?.call();
    }
  }
}
