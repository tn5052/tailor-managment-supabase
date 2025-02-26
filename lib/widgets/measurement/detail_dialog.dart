import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/customer.dart';
import '../../models/measurement.dart';
import '../../services/customer_service.dart';
import '../../utils/fraction_helper.dart';
import '../../services/measurement_service.dart';
import '../invoice/pdf_preview_widget.dart';
import 'measurement_template.dart';

class DetailDialog extends StatefulWidget {
  final Measurement measurement;
  final String customerId;

  const DetailDialog({
    super.key,
    required this.measurement,
    required this.customerId,
  });

  // Add static show method
  static Future<void> show(BuildContext context, {
    required Measurement measurement,
    required String customerId,
  }) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktop = screenWidth >= 1024;

    if (isDesktop) {
      return showDialog(
        context: context,
        builder: (context) => Dialog(
          backgroundColor: Colors.transparent,
          child: Container(
            width: 1000, // Increased from 800 to 1000
            constraints: BoxConstraints(
              maxWidth: 1000, // Increased from 800 to 1000
              maxHeight: MediaQuery.of(context).size.height * 0.9,
            ),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: BorderRadius.circular(28),
            ),
            child: DetailDialog(
              measurement: measurement,
              customerId: customerId,
            ),
          ),
        ),
      );
    }

    // Full screen for mobile
    return Navigator.of(context).push(
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (context) => DetailDialog(
          measurement: measurement,
          customerId: customerId,
        ),
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
    final theme = Theme.of(context);
    final isDesktop = MediaQuery.of(context).size.width >= 1024;

    return isDesktop 
        ? Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(28),
              color: theme.colorScheme.surface,
            ),
            clipBehavior: Clip.antiAlias,
            child: _buildScaffold(theme, isDesktop),
          )
        : _buildScaffold(theme, isDesktop);
  }

  Widget _buildScaffold(ThemeData theme, bool isDesktop) {
    return Scaffold(
      backgroundColor: isDesktop ? Colors.transparent : theme.colorScheme.surface,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: isDesktop ? theme.colorScheme.surface : theme.colorScheme.primaryContainer,
        title: isDesktop 
            ? Row(
                children: [
                  CircleAvatar(
                    backgroundColor: theme.colorScheme.primaryContainer,
                    child: Icon(Icons.straighten, color: theme.colorScheme.primary),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          customer?.name ?? 'Measurement Details',
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.titleLarge?.copyWith(
                            color: theme.colorScheme.onSurface,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          'Bill #${widget.measurement.billNumber}',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurface.withOpacity(0.6),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              )
            : Text(
                'Measurement Details',
                style: theme.textTheme.titleLarge?.copyWith(
                  color: theme.colorScheme.onPrimaryContainer,
                ),
              ),
        leading: !isDesktop
            ? IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.pop(context),
                color: theme.colorScheme.onPrimaryContainer,
              )
            : null,
        actions: [
          FilledButton.tonal(
            onPressed: () => _showMeasurementPreview(context),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.print_outlined, size: 20),
                if (isDesktop) ...[
                  const SizedBox(width: 8),
                  const Text('Generate PDF'),
                ],
              ],
            ),
          ),
          const SizedBox(width: 8),
          if (isDesktop)
            IconButton(
              icon: const Icon(Icons.close),
              onPressed: () => Navigator.pop(context),
            ),
          const SizedBox(width: 8),
        ],
      ),
      body: isDesktop ? _buildDesktopLayout(theme) : _buildMobileLayout(theme),
    );
  }

  Widget _buildMobileLayout(ThemeData theme) {
    return SingleChildScrollView(
      child: Column(
        children: [
          // Customer Info Card with dates
          Container(
            width: double.infinity,
            color: theme.colorScheme.surfaceContainer,
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildInfoCard(
                  theme,
                  title: 'Customer Information',
                  icon: Icons.person_outline,
                  content: [
                    _buildInfoRow('Name', customer?.name ?? 'Unknown'),
                    _buildInfoRow('Phone', customer?.phone ?? 'N/A'),
                    _buildInfoRow('Bill Number', widget.measurement.billNumber),
                  ],
                ),
                const SizedBox(height: 16),
                _buildStyleInfoCard(theme), // Add this line
                const SizedBox(height: 16),
                _buildFabricCard(theme),
                const SizedBox(height: 16),
                _buildDatesSection(theme),
              ],
            ),
          ),

          // Updated Measurements Section
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildMobileMeasurementCard(
                  theme,
                  title: 'All Measurements',
                  icon: Icons.straighten,
                  color: theme.colorScheme.primary,
                  measurements: _buildMeasurementItems(),
                ),

                if (_hasStyleDetails()) ...[
                  const SizedBox(height: 16),
                  _buildMobileMeasurementCard(
                    theme,
                    title: 'Style Details',
                    icon: Icons.design_services_outlined,
                    color: theme.colorScheme.tertiary,
                    measurements: [
                      MeasurementItem('Cap Style', widget.measurement.tarboosh),
                      MeasurementItem(
                        'Sleeve Style',
                        widget.measurement.openSleeve,
                      ),
                      MeasurementItem('Stitching', widget.measurement.stitching),
                      MeasurementItem('Pleats', widget.measurement.pleat),
                      MeasurementItem('Side Pocket', widget.measurement.button),
                      MeasurementItem('Cuff Style', widget.measurement.cuff),
                      MeasurementItem('Embroidery', widget.measurement.embroidery),
                      MeasurementItem('Neck Style', widget.measurement.neckStyle),
                    ],
                  ),
                ],
                if (widget.measurement.notes.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  _buildNotesCard(theme, widget.measurement.notes),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMobileMeasurementCard(
    ThemeData theme, {
    required String title,
    required IconData icon,
    required Color color,
    required List<MeasurementItem> measurements,
  }) {
    return Card(
      elevation: 0,
      color: color.withOpacity(0.05),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: color.withOpacity(0.2)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: color),
                const SizedBox(width: 12),
                Text(
                  title,
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: color,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 2.5,
                crossAxisSpacing: 8,
                mainAxisSpacing: 8,
              ),
              itemCount: measurements.length,
              itemBuilder: (context, index) {
                final item = measurements[index];
                return _buildMobileMeasurementItem(theme, item, color);
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMobileMeasurementItem(
    ThemeData theme,
    MeasurementItem item,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color:
            item.isHighlighted
                ? color.withOpacity(0.1)
                : theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color:
              item.isHighlighted ? color.withOpacity(0.3) : theme.dividerColor,
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            item.label,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurface.withOpacity(0.8),
            ),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          Text(
            item.value,
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w600,
              color: item.isHighlighted ? color : null,
            ),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildCompactDateInfo(ThemeData theme, String label, DateTime date) {
    return Card(
      elevation: 0,
      color: theme.colorScheme.surface,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.primary,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              DateFormat('MMM dd, yyyy\nhh:mm a').format(date),
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDesktopLayout(ThemeData theme) {
    return Row(
      children: [
        // Make left sidebar scrollable
        SizedBox(
          width: 300,
          child: SingleChildScrollView(
            child: Container(
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainer,
                border: Border(right: BorderSide(color: theme.dividerColor)),
              ),
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildInfoCard(
                    theme,
                    title: 'Customer Information',
                    icon: Icons.person_outline,
                    content: [
                      _buildInfoRow('Name', customer?.name ?? 'Unknown'),
                      _buildInfoRow('Phone', customer?.phone ?? 'N/A'),
                      _buildInfoRow('Bill Number', widget.measurement.billNumber),
                    ],
                  ),
                  const SizedBox(height: 24),
                  _buildStyleInfoCard(theme),
                  const SizedBox(height: 24),
                  _buildFabricCard(theme),
                  const SizedBox(height: 24),
                  _buildInfoCard(
                    theme,
                    title: 'Dates',
                    icon: Icons.calendar_today_outlined,
                    content: [
                      _buildInfoRow(
                        'Created',
                        DateFormat('MMM dd, yyyy\nhh:mm a').format(widget.measurement.date),
                      ),
                      _buildInfoRow(
                        'Last Updated',
                        DateFormat('MMM dd, yyyy\nhh:mm a').format(widget.measurement.lastUpdated),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
        // Main content area
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Single Measurements section
                _buildMeasurementCard(
                  theme,
                  title: 'All Measurements',
                  icon: Icons.straighten,
                  color: theme.colorScheme.primary,
                  measurements: _buildMeasurementItems(),
                ),

                const SizedBox(height: 24),

                // Style Details section remains the same
                if (_hasStyleDetails()) ...[
                  const SizedBox(height: 24),
                  _buildMeasurementCard(
                    theme,
                    title: 'Style Details',
                    icon: Icons.design_services_outlined,
                    color: theme.colorScheme.tertiary,
                    measurements: [
                      MeasurementItem('Cap Style', widget.measurement.tarboosh),
                      MeasurementItem(
                        'Sleeve Style',
                        widget.measurement.openSleeve,
                      ),
                      MeasurementItem('Stitching', widget.measurement.stitching),
                      MeasurementItem('Pleats', widget.measurement.pleat),
                      MeasurementItem('Side Pocket', widget.measurement.button),
                      MeasurementItem('Cuff Style', widget.measurement.cuff),
                      MeasurementItem('Embroidery', widget.measurement.embroidery),
                      MeasurementItem('Neck Style', widget.measurement.neckStyle),
                    ],
                  ),
                ],

                if (widget.measurement.notes.isNotEmpty) ...[
                  const SizedBox(height: 24),
                  _buildNotesCard(theme, widget.measurement.notes),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildInfoCard(
    ThemeData theme, {
    required String title,
    required IconData icon,
    required List<Widget> content,
  }) {
    return Card(
      elevation: 0,
      color: theme.colorScheme.surface,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: theme.colorScheme.primary, size: 20),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ...content,
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }

  Widget _buildMeasurementCard(
    ThemeData theme, {
    required String title,
    required IconData icon,
    required Color color,
    required List<MeasurementItem> measurements,
  }) {
    return Card(
      elevation: 0,
      color: color.withOpacity(0.05),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: color.withOpacity(0.2)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min, // Add this to minimize height
          children: [
            Row(
              children: [
                Icon(icon, color: color),
                const SizedBox(width: 12),
                Text(
                  title,
                  style: theme.textTheme.titleLarge?.copyWith(
                    color: color,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16), // Reduced from 24
            LayoutBuilder(
              builder: (context, constraints) {
                return GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    childAspectRatio: constraints.maxWidth > 800 ? 4 : 3, // Adjust based on width
                    mainAxisSpacing: 12, // Reduced from 16
                    crossAxisSpacing: 12, // Reduced from 16
                    mainAxisExtent: 70, // Fixed height for items
                  ),
                  itemCount: measurements.length,
                  itemBuilder: (context, index) {
                    final item = measurements[index];
                    return _buildMeasurementItem(theme, item, color);
                  },
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  // Also update the _buildMeasurementItem to be more compact
  Widget _buildMeasurementItem(
    ThemeData theme,
    MeasurementItem item,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6), // Reduced padding
      decoration: BoxDecoration(
        color:
            item.isHighlighted
                ? color.withOpacity(0.1)
                : theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color:
              item.isHighlighted ? color.withOpacity(0.3) : theme.dividerColor,
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min, // Add this to make column take minimum space
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            item.label,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurface.withOpacity(0.6),
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 2), // Keep minimal spacing
          Text(
            item.value,
            style: theme.textTheme.titleSmall?.copyWith( // Changed from titleMedium to titleSmall
              fontWeight: FontWeight.w600,
              color: item.isHighlighted ? color : null,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildNotesCard(ThemeData theme, String notes) {
    return Card(
      elevation: 0,
      color: theme.colorScheme.surfaceContainerHighest,
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.notes_outlined,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                const SizedBox(width: 12),
                Text(
                  'Notes',
                  style: theme.textTheme.titleLarge?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              notes,
              style: theme.textTheme.bodyLarge?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFabricCard(ThemeData theme) {
    return Card(
      elevation: 0,
      color: theme.colorScheme.primaryContainer.withOpacity(0.3),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: theme.colorScheme.primary.withOpacity(0.2),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.format_color_fill,
                  color: theme.colorScheme.primary,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  'Fabric Details',
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: theme.colorScheme.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: theme.colorScheme.surface,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: theme.colorScheme.outline.withOpacity(0.2),
                ),
              ),
              child: Text(
                widget.measurement.fabricName.isEmpty
                    ? 'No fabric specified'
                    : widget.measurement.fabricName,
                style: theme.textTheme.bodyLarge?.copyWith(
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
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

  Widget _buildDatesSection(ThemeData theme) {
    return Row(
      children: [
        Expanded(
          child: _buildCompactDateInfo(
            theme,
            'Created',
            widget.measurement.date,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildCompactDateInfo(
            theme,
            'Updated',
            widget.measurement.lastUpdated,
          ),
        ),
      ],
    );
  }

  Widget _buildStyleInfoCard(ThemeData theme) {
    return Card(
      elevation: 0,
      color: theme.colorScheme.surfaceContainer,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.style_outlined,
                  color: theme.colorScheme.primary,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  'Style Information',
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: theme.colorScheme.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildStyleInfoItem(
                    theme,
                    'Style Type',
                    widget.measurement.style,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildStyleInfoItem(
                    theme,
                    'Design Type',
                    widget.measurement.designType,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStyleInfoItem(ThemeData theme, String label, String value) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: theme.colorScheme.outline.withOpacity(0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurface.withOpacity(0.7),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: theme.textTheme.bodyLarge?.copyWith(
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  List<MeasurementItem> _buildMeasurementItems() {
    return [
      if (widget.measurement.style == 'Emirati')
        MeasurementItem(
          'Arabic Length',
          FractionHelper.formatFraction(widget.measurement.lengthArabi),
          true,
        )
      else
        MeasurementItem(
          'Kuwaiti Length',
          FractionHelper.formatFraction(widget.measurement.lengthKuwaiti),
          true,
        ),
      MeasurementItem('Chest', FractionHelper.formatFraction(widget.measurement.chest)),
      MeasurementItem('Width', FractionHelper.formatFraction(widget.measurement.width)),
      MeasurementItem('Sleeve', FractionHelper.formatFraction(widget.measurement.sleeve)),
      MeasurementItem('Collar', FractionHelper.formatFraction(widget.measurement.collar)),
      MeasurementItem('Under', FractionHelper.formatFraction(widget.measurement.under)),
      MeasurementItem('Back Length', FractionHelper.formatFraction(widget.measurement.backLength)),
      MeasurementItem('Neck', FractionHelper.formatFraction(widget.measurement.neck)),
      MeasurementItem('Shoulder', FractionHelper.formatFraction(widget.measurement.shoulder)),
      MeasurementItem('Seam', widget.measurement.seam),
      MeasurementItem('Adhesive', widget.measurement.adhesive),
      MeasurementItem('Under Kandura', widget.measurement.underKandura),
    ];
  }

  void _showMeasurementPreview(BuildContext context) async {
    final theme = Theme.of(context);
    final isDesktop = MediaQuery.of(context).size.width >= 1024;
    
    try {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: CircularProgressIndicator(),
        ),
      );

      final pdfBytes = await MeasurementTemplate.generateMeasurement(
        widget.measurement,
        customer?.name ?? 'Unknown Customer',
      );

      if (!context.mounted) return;
      Navigator.pop(context); // Dismiss loading indicator

      if (isDesktop) {
        // Desktop preview dialog
        await showDialog(
          context: context,
          builder: (context) => Dialog(
            backgroundColor: Colors.transparent,
            child: Container(
              width: 800,
              height: MediaQuery.of(context).size.height * 0.9,
              decoration: BoxDecoration(
                color: theme.colorScheme.surface,
                borderRadius: BorderRadius.circular(28),
              ),
              clipBehavior: Clip.antiAlias,
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Measurement Preview',
                          style: theme.textTheme.titleLarge,
                        ),
                        IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: PdfPreviewWidget(pdfBytes: pdfBytes),
                  ),
                  _buildPreviewActions(context, theme, pdfBytes),
                ],
              ),
            ),
          ),
        );
      } else {
        // Mobile preview
        await Navigator.of(context).push(
          MaterialPageRoute(
            fullscreenDialog: true,
            builder: (context) => Scaffold(
              appBar: AppBar(
                backgroundColor: theme.colorScheme.primaryContainer,
                title: Text(
                  'Measurement Preview',
                  style: theme.textTheme.titleLarge?.copyWith(
                    color: theme.colorScheme.onPrimaryContainer,
                  ),
                ),
                actions: [
                  FilledButton.icon(
                    onPressed: () {
                      Navigator.pop(context);
                      _sharePdf(pdfBytes);
                    },
                    icon: const Icon(Icons.ios_share),
                    label: const Text('Share'),
                  ),
                  const SizedBox(width: 8),
                ],
              ),
              body: SafeArea(
                child: PdfPreviewWidget(pdfBytes: pdfBytes),
              ),
            ),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        Navigator.pop(context); // Dismiss loading indicator
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to generate measurement PDF: $e'),
            backgroundColor: theme.colorScheme.error,
          ),
        );
      }
    }
  }

  Widget _buildPreviewActions(BuildContext context, ThemeData theme, List<int> pdfBytes) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          const SizedBox(width: 8),
          FilledButton.icon(
            onPressed: () {
              Navigator.pop(context);
              _sharePdf(pdfBytes);
            },
            icon: const Icon(Icons.ios_share),
            label: const Text('Share PDF'),
            style: FilledButton.styleFrom(
              backgroundColor: theme.colorScheme.primary,
              foregroundColor: theme.colorScheme.onPrimary,
            ),
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
