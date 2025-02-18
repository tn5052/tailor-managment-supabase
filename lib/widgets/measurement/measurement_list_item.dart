import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/measurement.dart';
import '../../services/measurement_service.dart';
import '../../services/supabase_service.dart';
import 'measurement_badge.dart';
import 'detail_dialog.dart';
import 'add_measurement_dialog.dart';

class MeasurementListItem extends StatelessWidget {
  final Measurement measurement;
  final int index;
  final bool isDesktop;
  final MeasurementService _measurementService = MeasurementService();
  final SupabaseService _supabaseService = SupabaseService();

  MeasurementListItem({
    super.key,
    required this.measurement,
    required this.index,
    required this.isDesktop,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      margin: const EdgeInsets.only(bottom: 8), // reduced from 12
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: theme.colorScheme.outline.withOpacity(0.1)),
      ),
      color: theme.colorScheme.surface.withOpacity(0.8),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap:
            () => _showDetailsDialog(
              context,
              measurement.customerId,
            ), //customer),
        child: Container(
          padding: const EdgeInsets.all(12.0), // increased from 8.0
          decoration: BoxDecoration(borderRadius: BorderRadius.circular(20)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CircleAvatar(
                    backgroundColor: theme.colorScheme.primary,
                    child: const Icon(Icons.straighten, color: Colors.white),
                  ),
                  const SizedBox(width: 12), // increased from 8
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              flex: 3,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Flexible(
                                        flex: 2,
                                        child: FutureBuilder<String>(
                                          future: _supabaseService.getCustomerName(measurement.customerId),
                                          builder: (context, snapshot) {
                                            return Text(
                                              snapshot.data ?? 'Loading...',
                                              style: const TextStyle(
                                                fontWeight: FontWeight.w600,
                                                fontSize: 16,
                                              ),
                                              overflow: TextOverflow.ellipsis,
                                            );
                                          },
                                        ),
                                      ),
                                      const SizedBox(
                                        width: 12,
                                      ), // increased from 8
                                      Flexible(
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 6,
                                            vertical: 2,
                                          ),
                                          decoration: BoxDecoration(
                                            color: theme.colorScheme.primary
                                                .withOpacity(0.1),
                                            borderRadius: BorderRadius.circular(
                                              6,
                                            ),
                                          ),
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Icon(
                                                Icons.receipt_outlined,
                                                size: 12,
                                                color:
                                                    theme.colorScheme.primary,
                                              ),
                                              const SizedBox(width: 3),
                                              Flexible(
                                                child: Text(
                                                  '#${measurement.billNumber}',
                                                  style: TextStyle(
                                                    color:
                                                        theme
                                                            .colorScheme
                                                            .primary,
                                                    fontSize: 12,
                                                    fontWeight: FontWeight.w500,
                                                  ),
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    measurement.style,
                                    style: TextStyle(
                                      color: theme.textTheme.bodyMedium?.color
                                          ?.withOpacity(0.6),
                                      fontSize: 12,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                            if (isDesktop)
                              _buildDateColumn(theme, measurement)
                            else
                              Expanded(
                                flex: 1,
                                child: _buildDateColumn(theme, measurement),
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  PopupMenuButton<String>(
                    position: PopupMenuPosition.under,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    itemBuilder:
                        (context) => [
                          const PopupMenuItem(
                            value: 'edit',
                            child: Row(
                              children: [
                                Icon(Icons.edit_outlined),
                                SizedBox(width: 8),
                                Text('Edit'),
                              ],
                            ),
                          ),
                          const PopupMenuItem(
                            value: 'delete',
                            child: Row(
                              children: [
                                Icon(Icons.delete_outline, color: Colors.red),
                                SizedBox(width: 8),
                                Text(
                                  'Delete',
                                  style: TextStyle(color: Colors.red),
                                ),
                              ],
                            ),
                          ),
                        ],
                    onSelected: (value) {
                      if (value == 'delete') {
                        _showDeleteDialog(context);
                      } else if (value == 'edit') {
                        _showEditMeasurementDialog(context, measurement, index);
                      }
                    },
                  ),
                ],
              ),
              const SizedBox(height: 12), // reduced from 16
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    MeasurementBadge(
                      text: 'Style: ${measurement.style}',
                      color: theme.colorScheme.primary,
                    ),
                    ...buildStyleDetailBadges(context, theme).map(
                      (badge) => Padding(
                        padding: const EdgeInsets.only(
                          left: 4,
                        ), // reduced from 6
                        child: badge,
                      ),
                    ),
                    if (measurement.notes.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(
                          left: 4,
                        ), // reduced from 6
                        child: MeasurementBadge(
                          text: 'Notes: ${measurement.notes}',
                          color: Colors.grey,
                          maxWidth: 150,
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDateColumn(ThemeData theme, Measurement measurement) {
    return Padding(
      padding: const EdgeInsets.only(left: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(
            'Updated: ${DateFormat('MMM dd, yyyy').format(measurement.lastUpdated)}',
            style: TextStyle(
              fontSize: 12,
              color: theme.textTheme.bodyMedium?.color?.withOpacity(0.6),
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  List<Widget> buildStyleDetailBadges(BuildContext context, ThemeData theme) {
    final badges = <Widget>[];
    final colors = [
      theme.colorScheme.secondary,
      theme.colorScheme.tertiary,
      theme.colorScheme.error,
      theme.colorScheme.primary.withOpacity(0.7),
      theme.colorScheme.secondary.withOpacity(0.7),
      theme.colorScheme.tertiary.withOpacity(0.7),
      theme.colorScheme.error.withOpacity(0.7),
      theme.colorScheme.primary.withOpacity(0.5),
      theme.colorScheme.secondary.withOpacity(0.5),
      theme.colorScheme.tertiary.withOpacity(0.5),
    ];

    void addIfNotEmpty(String label, String value, Color color) {
      if (value.isNotEmpty) {
        badges.add(
          MeasurementBadge(text: '$label: $value', color: color, small: true),
        );
      }
    }

    // Update to use new field names
    addIfNotEmpty('Tarboosh', measurement.tarboosh, colors[0]);
    addIfNotEmpty('Open Sleeve', measurement.openSleeve, colors[1]);
    addIfNotEmpty('Stitching', measurement.stitching, colors[2]);
    addIfNotEmpty('Pleat', measurement.pleat, colors[3]);
    addIfNotEmpty('Button', measurement.button, colors[4]);
    addIfNotEmpty('Cuff', measurement.cuff, colors[5]);
    addIfNotEmpty('Embroidery', measurement.embroidery, colors[6]);
    addIfNotEmpty('Under Kandura', measurement.underKandura, colors[7]);
    addIfNotEmpty('Neck Style', measurement.neckStyle, colors[8]);
    addIfNotEmpty('Seam', measurement.seam, colors[9]);

    return badges;
  }

  void _showDetailsDialog(BuildContext context, String customerId) {
    DetailDialog.show(
      context,
      measurement: measurement,
      customerId: customerId,
    );
  }

  void _showDeleteDialog(BuildContext context) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Delete Measurement'),
            content: const Text(
              'Are you sure you want to delete this measurement?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              FilledButton(
                onPressed: () async {
                  await _measurementService.deleteMeasurement(measurement.id);
                  if (context.mounted) {
                    Navigator.pop(context);
                  }
                },
                style: FilledButton.styleFrom(backgroundColor: Colors.red),
                child: const Text('Delete'),
              ),
            ],
          ),
    );
  }

  void _showEditMeasurementDialog(
    BuildContext context,
    Measurement measurement,
    int index,
  ) {
    AddMeasurementDialog.show(
      context,
      measurement: measurement,
      index: index,
      isEditing: true,
    );
  }
}
