import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:intl/intl.dart';
import '../../../models/measurement.dart';
import '../../../models/customer.dart';
import '../../../services/customer_service.dart';
import '../../../utils/fraction_helper.dart';
import '../../../theme/inventory_design_config.dart';

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
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      useSafeArea: true,
      builder:
          (context) => MeasurementDetailScreenMobile(
            measurement: measurement,
            onMeasurementUpdated: onMeasurementUpdated,
          ),
    );
  }

  @override
  State<MeasurementDetailScreenMobile> createState() =>
      _MeasurementDetailScreenMobileState();
}

class _MeasurementDetailScreenMobileState
    extends State<MeasurementDetailScreenMobile> {
  Customer? customer;
  final SupabaseService _supabaseService = SupabaseService();

  @override
  void initState() {
    super.initState();
    _fetchCustomer();
  }

  Future<void> _fetchCustomer() async {
    try {
      final fetchedCustomer = await _supabaseService.getCustomerById(
        widget.measurement.customerId,
      );
      if (mounted) {
        setState(() => customer = fetchedCustomer);
      }
    } catch (e) {
      debugPrint('Error fetching customer: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.95,
      decoration: BoxDecoration(
        color: InventoryDesignConfig.surfaceColor,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(InventoryDesignConfig.radiusXL),
        ),
      ),
      child: Column(
        children: [_buildHeader(), Expanded(child: _buildContent())],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(InventoryDesignConfig.spacingL),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: InventoryDesignConfig.borderSecondary),
        ),
      ),
      child: Column(
        children: [
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: InventoryDesignConfig.borderPrimary,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: InventoryDesignConfig.spacingL),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(InventoryDesignConfig.spacingM),
                decoration: BoxDecoration(
                  color: InventoryDesignConfig.primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(
                    InventoryDesignConfig.radiusM,
                  ),
                ),
                child: Icon(
                  PhosphorIcons.ruler(),
                  size: 20,
                  color: InventoryDesignConfig.primaryColor,
                ),
              ),
              const SizedBox(width: InventoryDesignConfig.spacingM),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      customer?.name ?? 'Measurement Details',
                      style: InventoryDesignConfig.headlineMedium.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      'Bill #${widget.measurement.billNumber}',
                      style: InventoryDesignConfig.bodySmall.copyWith(
                        color: InventoryDesignConfig.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              Material(
                color: Colors.transparent,
                borderRadius: BorderRadius.circular(
                  InventoryDesignConfig.radiusM,
                ),
                child: InkWell(
                  onTap: () => Navigator.of(context).pop(),
                  borderRadius: BorderRadius.circular(
                    InventoryDesignConfig.radiusM,
                  ),
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: InventoryDesignConfig.surfaceLight,
                      borderRadius: BorderRadius.circular(
                        InventoryDesignConfig.radiusM,
                      ),
                    ),
                    child: Icon(
                      PhosphorIcons.x(),
                      size: 18,
                      color: InventoryDesignConfig.textSecondary,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(InventoryDesignConfig.spacingL),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Customer Information
          _buildInfoCard(
            title: 'Customer Information',
            icon: PhosphorIcons.user(),
            color: InventoryDesignConfig.primaryColor,
            content: [
              _buildInfoRow('Name', customer?.name ?? 'Unknown'),
              _buildInfoRow('Phone', customer?.phone ?? 'N/A'),
              _buildInfoRow('Bill Number', widget.measurement.billNumber),
              _buildInfoRow(
                'Gender',
                customer?.gender.name.toUpperCase() ?? 'N/A',
              ),
            ],
          ),

          const SizedBox(height: InventoryDesignConfig.spacingL),

          // Style Information
          _buildInfoCard(
            title: 'Style Information',
            icon: PhosphorIcons.star(),
            color: InventoryDesignConfig.infoColor,
            content: [
              _buildInfoRow('Style', widget.measurement.style),
              _buildInfoRow('Design Type', widget.measurement.designType),
              _buildInfoRow('Tarboosh Type', widget.measurement.tarbooshType),
            ],
          ),

          const SizedBox(height: InventoryDesignConfig.spacingL),

          // Key Measurements
          _buildMeasurementsCard(
            title: 'Key Measurements',
            icon: PhosphorIcons.ruler(),
            color: InventoryDesignConfig.primaryColor,
            measurements: _getKeyMeasurements(),
          ),

          const SizedBox(height: InventoryDesignConfig.spacingL),

          // Additional Measurements
          if (_getAdditionalMeasurements().isNotEmpty) ...[
            _buildMeasurementsCard(
              title: 'Additional Measurements',
              icon: PhosphorIcons.listDashes(),
              color: InventoryDesignConfig.successColor,
              measurements: _getAdditionalMeasurements(),
            ),
            const SizedBox(height: InventoryDesignConfig.spacingL),
          ],

          // Style Details
          if (_getStyleDetails().isNotEmpty) ...[
            _buildInfoCard(
              title: 'Style Details',
              icon: PhosphorIcons.palette(),
              color: InventoryDesignConfig.warningColor,
              content: _getStyleDetails(),
            ),
            const SizedBox(height: InventoryDesignConfig.spacingL),
          ],

          // Timeline
          _buildInfoCard(
            title: 'Timeline',
            icon: PhosphorIcons.calendar(),
            color: InventoryDesignConfig.infoColor,
            content: [
              _buildInfoRow(
                'Created',
                DateFormat(
                  'MMM dd, yyyy • hh:mm a',
                ).format(widget.measurement.date),
              ),
              _buildInfoRow(
                'Last Updated',
                DateFormat(
                  'MMM dd, yyyy • hh:mm a',
                ).format(widget.measurement.lastUpdated),
              ),
            ],
          ),

          // Notes
          if (widget.measurement.notes.isNotEmpty) ...[
            const SizedBox(height: InventoryDesignConfig.spacingL),
            _buildInfoCard(
              title: 'Notes',
              icon: PhosphorIcons.note(),
              color: InventoryDesignConfig.warningColor,
              content: [
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(InventoryDesignConfig.spacingM),
                  decoration: BoxDecoration(
                    color: InventoryDesignConfig.surfaceAccent,
                    borderRadius: BorderRadius.circular(
                      InventoryDesignConfig.radiusM,
                    ),
                    border: Border.all(
                      color: InventoryDesignConfig.borderPrimary,
                    ),
                  ),
                  child: Text(
                    widget.measurement.notes,
                    style: InventoryDesignConfig.bodyLarge.copyWith(
                      height: 1.5,
                    ),
                  ),
                ),
              ],
            ),
          ],

          const SizedBox(height: InventoryDesignConfig.spacingXXL),
        ],
      ),
    );
  }

  Widget _buildInfoCard({
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
                Text(
                  title,
                  style: InventoryDesignConfig.titleMedium.copyWith(
                    fontWeight: FontWeight.w600,
                    color: color,
                  ),
                ),
              ],
            ),
          ),
          Padding(
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

  Widget _buildMeasurementsCard({
    required String title,
    required IconData icon,
    required Color color,
    required List<MeasurementItem> measurements,
  }) {
    return Container(
      width: double.infinity,
      decoration: InventoryDesignConfig.cardDecoration,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
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
                Text(
                  title,
                  style: InventoryDesignConfig.titleMedium.copyWith(
                    fontWeight: FontWeight.w600,
                    color: color,
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(InventoryDesignConfig.spacingL),
            child: Column(
              children:
                  measurements
                      .map(
                        (measurement) =>
                            _buildMeasurementItem(measurement, color),
                      )
                      .toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Container(
      margin: const EdgeInsets.only(bottom: InventoryDesignConfig.spacingM),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: InventoryDesignConfig.bodyMedium.copyWith(
                color: InventoryDesignConfig.textSecondary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: InventoryDesignConfig.bodyMedium.copyWith(
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMeasurementItem(MeasurementItem item, Color color) {
    return Container(
      margin: const EdgeInsets.only(bottom: InventoryDesignConfig.spacingM),
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
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              item.label,
              style: InventoryDesignConfig.bodyMedium.copyWith(
                color: InventoryDesignConfig.textSecondary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Text(
            item.value,
            style: InventoryDesignConfig.titleMedium.copyWith(
              fontWeight: FontWeight.w700,
              color:
                  item.isHighlighted
                      ? color
                      : InventoryDesignConfig.textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  List<MeasurementItem> _getKeyMeasurements() {
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
    ];
  }

  List<MeasurementItem> _getAdditionalMeasurements() {
    final measurements = <MeasurementItem>[];

    if (widget.measurement.backLength > 0) {
      measurements.add(
        MeasurementItem(
          'Back Length',
          FractionHelper.formatFraction(widget.measurement.backLength),
        ),
      );
    }

    if (widget.measurement.collar > 0) {
      measurements.add(
        MeasurementItem(
          'Neck Size',
          FractionHelper.formatFraction(widget.measurement.collar),
        ),
      );
    }

    if (widget.measurement.shoulder > 0) {
      measurements.add(
        MeasurementItem(
          'Shoulder',
          FractionHelper.formatFraction(widget.measurement.shoulder),
        ),
      );
    }

    if (widget.measurement.sleeve > 0) {
      measurements.add(
        MeasurementItem(
          'Sleeve Length',
          FractionHelper.formatFraction(widget.measurement.sleeve),
        ),
      );
    }

    if (widget.measurement.neck > 0) {
      measurements.add(
        MeasurementItem(
          'Sleeve Fitting',
          FractionHelper.formatFraction(widget.measurement.neck),
        ),
      );
    }

    if (widget.measurement.under > 0) {
      measurements.add(
        MeasurementItem(
          'Under Shoulder',
          FractionHelper.formatFraction(widget.measurement.under),
        ),
      );
    }

    return measurements;
  }

  List<Widget> _getStyleDetails() {
    final details = <Widget>[];

    if (widget.measurement.seam.isNotEmpty) {
      details.add(_buildInfoRow('Side Seam', widget.measurement.seam));
    }

    if (widget.measurement.adhesive.isNotEmpty) {
      details.add(_buildInfoRow('Adhesive', widget.measurement.adhesive));
    }

    if (widget.measurement.underKandura.isNotEmpty) {
      details.add(
        _buildInfoRow('Under Kandura', widget.measurement.underKandura),
      );
    }

    if (widget.measurement.openSleeve.isNotEmpty) {
      details.add(
        _buildInfoRow('Sleeve Opening', widget.measurement.openSleeve),
      );
    }

    if (widget.measurement.stitching.isNotEmpty) {
      details.add(
        _buildInfoRow('Stitching Style', widget.measurement.stitching),
      );
    }

    if (widget.measurement.pleat.isNotEmpty) {
      details.add(_buildInfoRow('Pleat Style', widget.measurement.pleat));
    }

    if (widget.measurement.button.isNotEmpty) {
      details.add(_buildInfoRow('Side Pocket', widget.measurement.button));
    }

    if (widget.measurement.cuff.isNotEmpty) {
      details.add(_buildInfoRow('Cuff Style', widget.measurement.cuff));
    }

    if (widget.measurement.embroidery.isNotEmpty) {
      details.add(_buildInfoRow('Embroidery', widget.measurement.embroidery));
    }

    if (widget.measurement.neckStyle.isNotEmpty) {
      details.add(_buildInfoRow('Neck Style', widget.measurement.neckStyle));
    }

    return details;
  }
}

class MeasurementItem {
  final String label;
  final String value;
  final bool isHighlighted;

  MeasurementItem(this.label, this.value, [this.isHighlighted = false]);
}
