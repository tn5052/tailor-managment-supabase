import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/customer.dart';
import '../../models/measurement.dart';
import '../../services/supabase_service.dart';

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
            width: 800,
            constraints: BoxConstraints(
              maxWidth: 800,
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
      backgroundColor: isDesktop ? Colors.transparent : theme.colorScheme.background,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: isDesktop ? theme.colorScheme.surface : theme.colorScheme.primaryContainer,
        title: Row(
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
                      color: isDesktop 
                          ? theme.colorScheme.onSurface
                          : theme.colorScheme.onPrimaryContainer,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    'Bill #${widget.measurement.billNumber}',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: isDesktop 
                          ? theme.colorScheme.onSurface.withOpacity(0.6)
                          : theme.colorScheme.onPrimaryContainer.withOpacity(0.8),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          FilledButton.tonal(
            onPressed: () {
              /* TODO: Add print functionality */
            },
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.print_outlined, size: 20),
                if (isDesktop) ...[
                  const SizedBox(width: 8),
                  const Text('PRINT'),
                ],
              ],
            ),
          ),
          const SizedBox(width: 8),
          if (!isDesktop)
            TextButton.icon(
              onPressed: () => Navigator.pop(context),
              icon: const Icon(Icons.close),
              label: const Text('Close'),
              style: TextButton.styleFrom(
                foregroundColor: theme.colorScheme.onPrimaryContainer,
              ),
            )
          else
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
                _buildFabricCard(theme),
                const SizedBox(height: 16),
                Row(
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
                ),
              ],
            ),
          ),

          // Measurements Section
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (widget.measurement.style == 'Arabic')
                  _buildMobileMeasurementCard(
                    theme,
                    title: 'Arabic Measurements',
                    icon: Icons.straighten,
                    color: theme.colorScheme.primary,
                    measurements: [
                      MeasurementItem(
                        'Arabic Length',
                        '${widget.measurement.toolArabi} cm',
                        true,
                      ),
                      MeasurementItem(
                        'Chest',
                        '${widget.measurement.sadur} cm',
                      ),
                      MeasurementItem('Width', '${widget.measurement.ard} cm'),
                      MeasurementItem(
                        'Under Kandura',
                        widget.measurement.tahtKandura,
                      ),
                    ],
                  )
                else
                  _buildMobileMeasurementCard(
                    theme,
                    title: '${widget.measurement.style} Measurements',
                    icon: Icons.straighten,
                    color: theme.colorScheme.primary,
                    measurements: [
                      MeasurementItem(
                        'Kuwaiti Length',
                        '${widget.measurement.toolKuwaiti} cm',
                        true,
                      ),
                      MeasurementItem(
                        'Shoulder',
                        '${widget.measurement.katf} cm',
                      ),
                      MeasurementItem('Under', '${widget.measurement.taht} cm'),
                    ],
                  ),
                const SizedBox(height: 16),
                _buildMobileMeasurementCard(
                  theme,
                  title: 'Common Measurements',
                  icon: Icons.straighten,
                  color: theme.colorScheme.secondary,
                  measurements: [
                    MeasurementItem(
                      'Back Length',
                      '${widget.measurement.toolKhalfi} cm',
                    ),
                    MeasurementItem('Sleeve', '${widget.measurement.kum} cm'),
                    MeasurementItem('Cuff', '${widget.measurement.fkm} cm'),
                    MeasurementItem('Neck', '${widget.measurement.raqba} cm'),
                    MeasurementItem('Hesba', widget.measurement.hesba),
                    MeasurementItem('Sheeb', widget.measurement.sheeb),
                  ],
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
                        widget.measurement.kumSalai,
                      ),
                      MeasurementItem('Stitching', widget.measurement.khayata),
                      MeasurementItem('Pleats', widget.measurement.kisra),
                      MeasurementItem('Side Pocket', widget.measurement.bati),
                      MeasurementItem('Cuff Style', widget.measurement.kaf),
                      MeasurementItem('Embroidery', widget.measurement.tatreez),
                      MeasurementItem('Side Slit', widget.measurement.jasba),
                      MeasurementItem('Shaib Style', widget.measurement.shaib),
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
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: measurements.length,
              separatorBuilder: (context, index) => const SizedBox(height: 8),
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
      child: Row(
        children: [
          Expanded(
            child: Text(
              item.label,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface.withOpacity(0.8),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Text(
            item.value,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
              color: item.isHighlighted ? color : null,
            ),
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
        // Left sidebar with customer info and dates
        Container(
          width: 300,
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
              _buildFabricCard(theme),
              const SizedBox(height: 24),
              _buildInfoCard(
                theme,
                title: 'Dates',
                icon: Icons.calendar_today_outlined,
                content: [
                  _buildInfoRow(
                    'Created',
                    DateFormat(
                      'MMM dd, yyyy\nhh:mm a',
                    ).format(widget.measurement.date),
                  ),
                  _buildInfoRow(
                    'Last Updated',
                    DateFormat(
                      'MMM dd, yyyy\nhh:mm a',
                    ).format(widget.measurement.lastUpdated),
                  ),
                ],
              ),
            ],
          ),
        ),
        // Main content area
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Style-specific measurements with modern card design
                if (widget.measurement.style == 'Arabic')
                  _buildMeasurementCard(
                    theme,
                    title: 'Arabic Measurements',
                    icon: Icons.straighten,
                    color: theme.colorScheme.primary,
                    measurements: [
                      MeasurementItem(
                        'Arabic Length',
                        '${widget.measurement.toolArabi} cm',
                        true,
                      ),
                      MeasurementItem(
                        'Chest',
                        '${widget.measurement.sadur} cm',
                      ),
                      MeasurementItem('Width', '${widget.measurement.ard} cm'),
                      MeasurementItem(
                        'Under Kandura',
                        widget.measurement.tahtKandura,
                      ),
                    ],
                  )
                else
                  _buildMeasurementCard(
                    theme,
                    title: '${widget.measurement.style} Measurements',
                    icon: Icons.straighten,
                    color: theme.colorScheme.primary,
                    measurements: [
                      MeasurementItem(
                        'Kuwaiti Length',
                        '${widget.measurement.toolKuwaiti} cm',
                        true,
                      ),
                      MeasurementItem(
                        'Shoulder',
                        '${widget.measurement.katf} cm',
                      ),
                      MeasurementItem('Under', '${widget.measurement.taht} cm'),
                    ],
                  ),

                const SizedBox(height: 24),

                // Common measurements
                _buildMeasurementCard(
                  theme,
                  title: 'Common Measurements',
                  icon: Icons.straighten,
                  color: theme.colorScheme.secondary,
                  measurements: [
                    MeasurementItem(
                      'Back Length',
                      '${widget.measurement.toolKhalfi} cm',
                    ),
                    MeasurementItem('Sleeve', '${widget.measurement.kum} cm'),
                    MeasurementItem('Cuff', '${widget.measurement.fkm} cm'),
                    MeasurementItem('Neck', '${widget.measurement.raqba} cm'),
                    MeasurementItem('Hesba', widget.measurement.hesba),
                    MeasurementItem('Sheeb', widget.measurement.sheeb),
                  ],
                ),

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
                        widget.measurement.kumSalai,
                      ),
                      MeasurementItem('Stitching', widget.measurement.khayata),
                      MeasurementItem('Pleats', widget.measurement.kisra),
                      MeasurementItem('Side Pocket', widget.measurement.bati),
                      MeasurementItem('Cuff Style', widget.measurement.kaf),
                      MeasurementItem('Embroidery', widget.measurement.tatreez),
                      MeasurementItem('Side Slit', widget.measurement.jasba),
                      MeasurementItem('Shaib Style', widget.measurement.shaib),
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
            const SizedBox(height: 24),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                childAspectRatio: 3,
                mainAxisSpacing: 16,
                crossAxisSpacing: 16,
              ),
              itemCount: measurements.length,
              itemBuilder: (context, index) {
                final item = measurements[index];
                return _buildMeasurementItem(theme, item, color);
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMeasurementItem(
    ThemeData theme,
    MeasurementItem item,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
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
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            item.label,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurface.withOpacity(0.6),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            item.value,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
              color: item.isHighlighted ? color : null,
            ),
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
        widget.measurement.kumSalai.isNotEmpty ||
        widget.measurement.khayata.isNotEmpty ||
        widget.measurement.kisra.isNotEmpty ||
        widget.measurement.bati.isNotEmpty ||
        widget.measurement.kaf.isNotEmpty ||
        widget.measurement.tatreez.isNotEmpty ||
        widget.measurement.jasba.isNotEmpty ||
        widget.measurement.tahtKandura.isNotEmpty ||
        widget.measurement.shaib.isNotEmpty;
  }
}

class MeasurementItem {
  final String label;
  final String value;
  final bool isHighlighted;

  MeasurementItem(this.label, this.value, [this.isHighlighted = false]);
}
