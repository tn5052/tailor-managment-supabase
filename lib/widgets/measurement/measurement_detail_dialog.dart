import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../../../models/customer.dart';
import '../../../models/measurement.dart';
import '../../../services/customer_service.dart';
import '../../../utils/fraction_helper.dart';
import '../../../services/measurement_service.dart';
import '../invoice/pdf_preview_widget.dart';
import 'measurement_pdf_template.dart';
import '../../../theme/inventory_design_config.dart';

class DetailDialog extends StatefulWidget {
  final Measurement measurement;
  final String customerId;

  const DetailDialog({
    super.key,
    required this.measurement,
    required this.customerId,
  });

  // Add static show method
  static Future<void> show(
    BuildContext context, {
    required Measurement measurement,
    required String customerId,
  }) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktop = screenWidth >= 1024;

    if (isDesktop) {
      return showDialog(
        context: context,
        builder:
            (context) => Dialog(
              backgroundColor: Colors.transparent,
              child: Container(
                width: 1200, // Increased width to prevent overflow
                constraints: BoxConstraints(
                  maxWidth: 1200,
                  maxHeight: MediaQuery.of(context).size.height * 0.9,
                ),
                decoration: BoxDecoration(
                  color: InventoryDesignConfig.surfaceColor,
                  borderRadius: BorderRadius.circular(
                    InventoryDesignConfig.radiusXL,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                clipBehavior: Clip.antiAlias,
                child: DetailDialog(
                  measurement: measurement,
                  customerId: customerId,
                ),
              ),
            ),
      );
    }

    // For mobile, show a simple message
    return showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Desktop Only'),
            content: const Text('This feature is only available on desktop.'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('OK'),
              ),
            ],
          ),
    );
  }

  @override
  State<DetailDialog> createState() => _DetailDialogState();
}

class _DetailDialogState extends State<DetailDialog> {
  Customer? customer;
  final SupabaseService _supabaseService = SupabaseService();

  @override
  void initState() {
    super.initState();
    _fetchCustomer();
  }

  Future<void> _fetchCustomer() async {
    final customers = await _supabaseService.getCustomersStream().first;
    setState(() {
      customer = customers.firstWhere(
        (c) => c.id == widget.customerId,
        orElse:
            () => Customer(
              id: '',
              billNumber: '',
              name: 'Unknown Customer',
              phone: '',
              address: '',
              gender: Gender.male,
            ),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    // Only desktop layout
    return _buildDesktopLayout();
  }

  Widget _buildDesktopLayout() {
    return Column(
      children: [
        // Header Section
        Container(
          padding: const EdgeInsets.all(InventoryDesignConfig.spacingXL),
          decoration: BoxDecoration(
            color: InventoryDesignConfig.surfaceAccent,
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
                  PhosphorIcons.ruler(PhosphorIconsStyle.fill),
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
                      customer?.name ?? 'Measurement Details',
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
                            'Bill #${widget.measurement.billNumber}',
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
                            color:
                                widget.measurement.style == 'Emirati'
                                    ? InventoryDesignConfig.infoColor
                                        .withOpacity(0.1)
                                    : InventoryDesignConfig.successColor
                                        .withOpacity(0.1),
                            borderRadius: BorderRadius.circular(
                              InventoryDesignConfig.radiusS,
                            ),
                          ),
                          child: Text(
                            widget.measurement.style,
                            style: InventoryDesignConfig.bodySmall.copyWith(
                              color:
                                  widget.measurement.style == 'Emirati'
                                      ? InventoryDesignConfig.infoColor
                                      : InventoryDesignConfig.successColor,
                              fontWeight: FontWeight.w600,
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
                    icon: PhosphorIcons.filePdf(PhosphorIconsStyle.fill),
                    label: 'Generate PDF',
                    onPressed: () => _showMeasurementPreview(context),
                    isPrimary: true,
                  ),
                  const SizedBox(width: InventoryDesignConfig.spacingM),
                  _buildHeaderActionButton(
                    icon: PhosphorIcons.x(PhosphorIconsStyle.regular),
                    label: 'Close',
                    onPressed: () => Navigator.pop(context),
                    isPrimary: false,
                  ),
                ],
              ),
            ],
          ),
        ),

        // Main Content Area
        Expanded(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Left Sidebar - Fixed width with consistent spacing
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
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(
                    InventoryDesignConfig.spacingXL,
                  ),
                  child: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment.stretch, // Ensure full width
                    children: [
                      _buildModernInfoCard(
                        title: 'Customer Information',
                        icon: PhosphorIcons.user(PhosphorIconsStyle.fill),
                        color: InventoryDesignConfig.primaryColor,
                        content: [
                          _buildModernInfoRow(
                            'Name',
                            customer?.name ?? 'Unknown',
                          ),
                          _buildModernInfoRow(
                            'Phone',
                            customer?.phone ?? 'N/A',
                          ),
                          _buildModernInfoRow(
                            'Bill Number',
                            widget.measurement.billNumber,
                          ),
                        ],
                      ),
                      const SizedBox(height: InventoryDesignConfig.spacingXL),
                      _buildModernStyleCard(),
                      const SizedBox(height: InventoryDesignConfig.spacingXL),
                      _buildModernFabricCard(),
                      const SizedBox(height: InventoryDesignConfig.spacingXL),
                      _buildModernDateCard(),
                    ],
                  ),
                ),
              ),

              // Main Content - Flexible width with consistent padding
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(
                    InventoryDesignConfig.spacingXXL,
                  ),
                  child: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment.stretch, // Ensure full width
                    children: [
                      // Measurements Grid
                      _buildModernMeasurementCard(
                        title: 'All Measurements',
                        icon: PhosphorIcons.ruler(PhosphorIconsStyle.fill),
                        color: InventoryDesignConfig.primaryColor,
                        measurements: _buildMeasurementItems(),
                      ),

                      // Style Details
                      if (_hasStyleDetails()) ...[
                        const SizedBox(
                          height: InventoryDesignConfig.spacingXXL,
                        ),
                        _buildModernMeasurementCard(
                          title: 'Style Details',
                          icon: PhosphorIcons.palette(PhosphorIconsStyle.fill),
                          color: InventoryDesignConfig.successColor,
                          measurements: _buildStyleDetailItems(),
                        ),
                      ],

                      // Notes
                      if (widget.measurement.notes.isNotEmpty) ...[
                        const SizedBox(
                          height: InventoryDesignConfig.spacingXXL,
                        ),
                        _buildModernNotesCard(widget.measurement.notes),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // Desktop Helper Methods
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
            width: double.infinity, // Ensure full width
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
            width: double.infinity, // Ensure full width
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
      width: double.infinity, // Ensure full width
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

  Widget _buildModernStyleCard() {
    return _buildModernInfoCard(
      title: 'Style Information',
      icon: PhosphorIcons.paintBrush(PhosphorIconsStyle.fill),
      color: InventoryDesignConfig.infoColor,
      content: [
        _buildModernInfoRow('Style Type', widget.measurement.style),
        _buildModernInfoRow('Design Type', widget.measurement.designType),
        if (widget.measurement.tarbooshType.isNotEmpty)
          _buildModernInfoRow('Tarboosh Type', widget.measurement.tarbooshType),
      ],
    );
  }

  Widget _buildModernFabricCard() {
    return _buildModernInfoCard(
      title: 'Fabric Details',
      icon: PhosphorIcons.scissors(PhosphorIconsStyle.fill),
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
          child: Text(
            widget.measurement.fabricName.isEmpty
                ? 'No fabric specified'
                : widget.measurement.fabricName,
            style: InventoryDesignConfig.bodyLarge.copyWith(
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildModernDateCard() {
    return _buildModernInfoCard(
      title: 'Timeline',
      icon: PhosphorIcons.calendar(PhosphorIconsStyle.fill),
      color: InventoryDesignConfig.warningColor,
      content: [
        _buildModernInfoRow(
          'Created',
          DateFormat('MMM dd, yyyy • hh:mm a').format(widget.measurement.date),
        ),
        _buildModernInfoRow(
          'Last Updated',
          DateFormat(
            'MMM dd, yyyy • hh:mm a',
          ).format(widget.measurement.lastUpdated),
        ),
      ],
    );
  }

  Widget _buildModernMeasurementCard({
    required String title,
    required IconData icon,
    required Color color,
    required List<MeasurementItem> measurements,
  }) {
    // Filter out empty measurements
    final validMeasurements =
        measurements
            .where(
              (m) =>
                  m.value.isNotEmpty &&
                  m.value != '0' &&
                  m.value != '0.0' &&
                  m.value != '-',
            )
            .toList();

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
          if (validMeasurements.isNotEmpty)
            Padding(
              padding: const EdgeInsets.all(InventoryDesignConfig.spacingXL),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  // Calculate optimal grid layout
                  final availableWidth = constraints.maxWidth;
                  final itemMinWidth = 180.0;
                  final crossAxisCount = (availableWidth / itemMinWidth)
                      .floor()
                      .clamp(2, 6);

                  return GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: crossAxisCount,
                      childAspectRatio: 2.2,
                      mainAxisSpacing: InventoryDesignConfig.spacingM,
                      crossAxisSpacing: InventoryDesignConfig.spacingM,
                    ),
                    itemCount: validMeasurements.length,
                    itemBuilder: (context, index) {
                      return _buildModernMeasurementItem(
                        validMeasurements[index],
                        color,
                      );
                    },
                  );
                },
              ),
            )
          else
            Padding(
              padding: const EdgeInsets.all(InventoryDesignConfig.spacingXL),
              child: Center(
                child: Text(
                  'No measurements available',
                  style: InventoryDesignConfig.bodyMedium.copyWith(
                    color: InventoryDesignConfig.textSecondary,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildModernMeasurementItem(MeasurementItem item, Color color) {
    return Container(
      padding: const EdgeInsets.all(InventoryDesignConfig.spacingM),
      decoration: BoxDecoration(
        color:
            item.isHighlighted
                ? color.withOpacity(0.1)
                : InventoryDesignConfig.surfaceAccent,
        borderRadius: BorderRadius.circular(InventoryDesignConfig.radiusM),
        border: Border.all(
          color:
              item.isHighlighted
                  ? color.withOpacity(0.3)
                  : InventoryDesignConfig.borderPrimary,
          width: item.isHighlighted ? 1.5 : 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            item.label,
            style: InventoryDesignConfig.bodySmall.copyWith(
              color: InventoryDesignConfig.textSecondary,
              fontWeight: FontWeight.w600,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: InventoryDesignConfig.spacingXS),
          Text(
            item.value,
            style: InventoryDesignConfig.titleMedium.copyWith(
              fontWeight: FontWeight.w700,
              color:
                  item.isHighlighted
                      ? color
                      : InventoryDesignConfig.textPrimary,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildModernNotesCard(String notes) {
    return Container(
      width: double.infinity,
      decoration: InventoryDesignConfig.cardDecoration,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(InventoryDesignConfig.spacingXL),
            decoration: BoxDecoration(
              color: InventoryDesignConfig.warningColor.withOpacity(0.05),
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
                    color: InventoryDesignConfig.warningColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(
                      InventoryDesignConfig.radiusM,
                    ),
                  ),
                  child: Icon(
                    PhosphorIcons.notepad(PhosphorIconsStyle.fill),
                    size: 20,
                    color: InventoryDesignConfig.warningColor,
                  ),
                ),
                const SizedBox(width: InventoryDesignConfig.spacingL),
                Text(
                  'Notes',
                  style: InventoryDesignConfig.headlineMedium.copyWith(
                    color: InventoryDesignConfig.warningColor,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(InventoryDesignConfig.spacingXL),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(InventoryDesignConfig.spacingL),
              decoration: BoxDecoration(
                color: InventoryDesignConfig.surfaceAccent,
                borderRadius: BorderRadius.circular(
                  InventoryDesignConfig.radiusM,
                ),
                border: Border.all(color: InventoryDesignConfig.borderPrimary),
              ),
              child: Text(
                notes,
                style: InventoryDesignConfig.bodyLarge.copyWith(height: 1.5),
              ),
            ),
          ),
        ],
      ),
    );
  }

  bool _hasStyleDetails() {
    return widget.measurement.tarboosh.isNotEmpty ||
        widget.measurement.openSleeve.isNotEmpty ||
        widget.measurement.stitching.isNotEmpty ||
        widget.measurement.pleat.isNotEmpty ||
        widget.measurement.button.isNotEmpty ||
        widget.measurement.cuff.isNotEmpty ||
        widget.measurement.embroidery.isNotEmpty ||
        widget.measurement.neckStyle.isNotEmpty;
  }

  List<MeasurementItem> _buildMeasurementItems() {
    return [
      if (widget.measurement.style == 'Emirati')
        MeasurementItem(
          'Length (Arabic)',
          FractionHelper.formatFraction(widget.measurement.lengthArabi),
          true,
        )
      else
        MeasurementItem(
          'Length (Kuwaiti)',
          FractionHelper.formatFraction(widget.measurement.lengthKuwaiti),
          true,
        ),
      MeasurementItem(
        'Chest',
        FractionHelper.formatFraction(widget.measurement.chest),
        true,
      ),
      MeasurementItem(
        'Width',
        FractionHelper.formatFraction(widget.measurement.width),
        true,
      ),
      MeasurementItem(
        'Back Length',
        FractionHelper.formatFraction(widget.measurement.backLength),
      ),
      MeasurementItem(
        'Neck Size',
        'S: ${FractionHelper.formatFraction(widget.measurement.collar['start'] ?? 0)} C: ${FractionHelper.formatFraction(widget.measurement.collar['center'] ?? 0)} E: ${FractionHelper.formatFraction(widget.measurement.collar['end'] ?? 0)}',
      ),
      MeasurementItem(
        'Shoulder',
        FractionHelper.formatFraction(widget.measurement.shoulder),
      ),
      MeasurementItem(
        'Sleeve Length',
        FractionHelper.formatFraction(widget.measurement.sleeve),
      ),
      MeasurementItem(
        'Sleeve Fitting',
        FractionHelper.formatFraction(widget.measurement.neck),
      ),
      MeasurementItem(
        'Under Shoulder',
        FractionHelper.formatFraction(widget.measurement.under),
      ),
      if (widget.measurement.seam.isNotEmpty)
        MeasurementItem('Side Seam', widget.measurement.seam),
      if (widget.measurement.adhesive.isNotEmpty)
        MeasurementItem('Adhesive', widget.measurement.adhesive),
      if (widget.measurement.underKandura.isNotEmpty)
        MeasurementItem('Under Kandura', widget.measurement.underKandura),
    ];
  }

  List<MeasurementItem> _buildStyleDetailItems() {
    return [
      if (widget.measurement.tarboosh.isNotEmpty)
        MeasurementItem('Cap Style', widget.measurement.tarboosh),
      if (widget.measurement.openSleeve.isNotEmpty)
        MeasurementItem('Sleeve Opening', widget.measurement.openSleeve),
      if (widget.measurement.stitching.isNotEmpty)
        MeasurementItem('Stitching Style', widget.measurement.stitching),
      if (widget.measurement.pleat.isNotEmpty)
        MeasurementItem('Pleat Style', widget.measurement.pleat),
      if (widget.measurement.button.isNotEmpty)
        MeasurementItem('Side Pocket', widget.measurement.button),
      if (widget.measurement.cuff.isNotEmpty)
        MeasurementItem('Cuff Style', widget.measurement.cuff),
      if (widget.measurement.embroidery.isNotEmpty)
        MeasurementItem('Embroidery', widget.measurement.embroidery),
      if (widget.measurement.neckStyle.isNotEmpty)
        MeasurementItem('Neck Style', widget.measurement.neckStyle),
    ];
  }

  void _showMeasurementPreview(BuildContext context) async {
    try {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder:
            (context) => Center(
              child: Container(
                padding: const EdgeInsets.all(InventoryDesignConfig.spacingXL),
                decoration: BoxDecoration(
                  color: InventoryDesignConfig.surfaceColor,
                  borderRadius: BorderRadius.circular(
                    InventoryDesignConfig.radiusL,
                  ),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(
                      color: InventoryDesignConfig.primaryColor,
                    ),
                    const SizedBox(height: InventoryDesignConfig.spacingL),
                    Text(
                      'Generating PDF...',
                      style: InventoryDesignConfig.bodyLarge,
                    ),
                  ],
                ),
              ),
            ),
      );

      final pdfBytes = await MeasurementTemplate.generateMeasurement(
        widget.measurement,
        customer?.name ?? 'Unknown Customer',
      );

      if (!context.mounted) return;
      Navigator.pop(context);

      // Desktop preview dialog
      await showDialog(
        context: context,
        builder:
            (context) => Dialog(
              backgroundColor: Colors.transparent,
              child: Container(
                width: 900,
                height: MediaQuery.of(context).size.height * 0.9,
                decoration: BoxDecoration(
                  color: InventoryDesignConfig.surfaceColor,
                  borderRadius: BorderRadius.circular(
                    InventoryDesignConfig.radiusXL,
                  ),
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
                      padding: const EdgeInsets.all(
                        InventoryDesignConfig.spacingL,
                      ),
                      decoration: BoxDecoration(
                        color: InventoryDesignConfig.surfaceAccent,
                        border: Border(
                          bottom: BorderSide(
                            color: InventoryDesignConfig.borderSecondary,
                          ),
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
                            'Measurement Preview',
                            style: InventoryDesignConfig.titleLarge.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const Spacer(),
                          _buildHeaderActionButton(
                            icon: PhosphorIcons.x(),
                            label: 'Close',
                            onPressed: () => Navigator.pop(context),
                            isPrimary: false,
                          ),
                        ],
                      ),
                    ),
                    Expanded(child: PdfPreviewWidget(pdfBytes: pdfBytes)),
                    _buildPreviewActions(context, pdfBytes),
                  ],
                ),
              ),
            ),
      );
    } catch (e) {
      if (context.mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to generate measurement PDF: $e'),
            backgroundColor: InventoryDesignConfig.errorColor,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Widget _buildPreviewActions(BuildContext context, List<int> pdfBytes) {
    return Container(
      padding: const EdgeInsets.all(InventoryDesignConfig.spacingL),
      decoration: BoxDecoration(
        color: InventoryDesignConfig.surfaceAccent,
        border: Border(
          top: BorderSide(color: InventoryDesignConfig.borderSecondary),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            style: TextButton.styleFrom(
              foregroundColor: InventoryDesignConfig.textSecondary,
            ),
            child: const Text('Cancel'),
          ),
          const SizedBox(width: InventoryDesignConfig.spacingS),
          _buildHeaderActionButton(
            icon: PhosphorIcons.export(),
            label: 'Share PDF',
            onPressed: () {
              Navigator.pop(context);
              _sharePdf(pdfBytes);
            },
            isPrimary: true,
          ),
        ],
      ),
    );
  }

  void _sharePdf(List<int> pdfBytes) async {
    final measurementService = MeasurementService();
    await measurementService.sharePdf(
      pdfBytes,
      'measurement_${widget.measurement.billNumber}.pdf',
    );
  }
}

class MeasurementItem {
  final String label;
  final String value;
  final bool isHighlighted;

  MeasurementItem(this.label, this.value, [this.isHighlighted = false]);
}
