import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:intl/intl.dart';
import '../../../models/measurement.dart';
import '../../../models/customer.dart';
import '../../../services/customer_service.dart';
import '../../../theme/inventory_design_config.dart';
import 'add_measurement_mobile_sheet.dart';

class MeasurementDetailScreenMobile extends StatefulWidget {
  final Measurement measurement;
  final VoidCallback? onMeasurementUpdated;

  const MeasurementDetailScreenMobile({
    super.key,
    required this.measurement,
    this.onMeasurementUpdated,
  });

  static Future<void> show(
    BuildContext context, {
    required Measurement measurement,
    VoidCallback? onMeasurementUpdated,
  }) {
    return Navigator.of(context).push(
      MaterialPageRoute(
        builder:
            (context) => MeasurementDetailScreenMobile(
              measurement: measurement,
              onMeasurementUpdated: onMeasurementUpdated,
            ),
      ),
    );
  }

  @override
  State<MeasurementDetailScreenMobile> createState() =>
      _MeasurementDetailScreenMobileState();
}

class _MeasurementDetailScreenMobileState
    extends State<MeasurementDetailScreenMobile> {
  Customer? _customer;
  final SupabaseService _supabaseService = SupabaseService();

  @override
  void initState() {
    super.initState();
    _fetchCustomer();
  }

  Future<void> _fetchCustomer() async {
    final customer = await _supabaseService.getCustomerById(
      widget.measurement.customerId,
    );
    if (mounted) {
      setState(() {
        _customer = customer;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_customer?.name ?? 'Measurement Details'),
        actions: [
          IconButton(
            icon: Icon(PhosphorIcons.pencilSimple()),
            onPressed: () {
              AddMeasurementMobileSheet.show(
                context,
                isEditing: true,
                measurement: widget.measurement,
                customer: _customer,
                onMeasurementAdded: () {
                  widget.onMeasurementUpdated?.call();
                  Navigator.of(context).pop(); // Pop detail screen after edit
                },
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(InventoryDesignConfig.spacingL),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildCustomerInfoCard(),
            const SizedBox(height: InventoryDesignConfig.spacingL),
            _buildMeasurementCard(
              'Main Measurements',
              _buildMeasurementItems(),
            ),
            const SizedBox(height: InventoryDesignConfig.spacingL),
            _buildMeasurementCard('Style Details', _buildStyleDetailItems()),
            const SizedBox(height: InventoryDesignConfig.spacingL),
            if (widget.measurement.notes.isNotEmpty) _buildNotesCard(),
          ],
        ),
      ),
    );
  }

  Widget _buildCustomerInfoCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(InventoryDesignConfig.spacingM),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Customer Info', style: InventoryDesignConfig.titleLarge),
            const Divider(),
            ListTile(
              leading: Icon(PhosphorIcons.user()),
              title: Text(_customer?.name ?? 'Loading...'),
              subtitle: Text('Bill #${widget.measurement.billNumber}'),
            ),
            ListTile(
              leading: Icon(PhosphorIcons.phone()),
              title: Text(_customer?.phone ?? 'N/A'),
            ),
            ListTile(
              leading: Icon(PhosphorIcons.calendar()),
              title: Text(
                'Created: ${DateFormat.yMMMd().format(widget.measurement.date)}',
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMeasurementCard(String title, List<Widget> items) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(InventoryDesignConfig.spacingM),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: InventoryDesignConfig.titleLarge),
            const Divider(),
            ...items,
          ],
        ),
      ),
    );
  }

  Widget _buildNotesCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(InventoryDesignConfig.spacingM),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Notes', style: InventoryDesignConfig.titleLarge),
            const Divider(),
            Text(widget.measurement.notes),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildMeasurementItems() {
    final m = widget.measurement;
    return [
      _buildDetailRow(
        m.style == 'Emirati' ? 'Length (Arabic)' : 'Length (Kuwaiti)',
        m.style == 'Emirati' ? m.lengthArabi : m.lengthKuwaiti,
      ),
      _buildDetailRow('Chest', m.chest),
      _buildDetailRow('Width', m.width),
      _buildDetailRow('Back Length', m.backLength),
      _buildDetailRow('Neck Size', m.neck),
      _buildDetailRow('Shoulder', m.shoulder),
      _buildDetailRow('Sleeve Length', m.sleeve),
      _buildDetailRow(
        'Sleeve Fitting',
        'S:${m.collar['start']} C:${m.collar['center']} E:${m.collar['end']}',
      ),
      _buildDetailRow('Under Shoulder', m.under),
      _buildDetailRow('Shoulder Shaib', m.seam),
      _buildDetailRow('Bottom', m.adhesive),
      _buildDetailRow('Bottom Kandura', m.underKandura),
    ];
  }

  List<Widget> _buildStyleDetailItems() {
    final m = widget.measurement;
    return [
      _buildDetailRow('Sleeve Stich', m.openSleeve),
      _buildDetailRow('Stitching Style', m.stitching),
      _buildDetailRow('Pleat Style', m.pleat),
      _buildDetailRow('front Plate', m.button),
      _buildDetailRow('Cuff Style', m.cuff),
      _buildDetailRow('Embroidery', m.embroidery),
      _buildDetailRow('Neck Style', m.neckStyle),
    ];
  }

  Widget _buildDetailRow(String label, String? value) {
    if (value == null || value.isEmpty || value == '0') {
      return const SizedBox.shrink();
    }
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: InventoryDesignConfig.bodyLarge),
          Text(
            value,
            style: InventoryDesignConfig.bodyLarge.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
