import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:collection/collection.dart'; // Import collection package
import '../../models/measurement.dart';
import '../../services/measurement_service.dart';
import '../../services/customer_service.dart';
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
    final screenWidth = MediaQuery.of(context).size.width;
    final defaultTextSize = screenWidth < 360 ? 12.0 : 14.0;

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      elevation: 2, // Added elevation
      shadowColor: theme.colorScheme.shadow.withOpacity(0.2), // Subtle shadow
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: theme.colorScheme.outline.withOpacity(0.1)),
      ),
      color: theme.colorScheme.surface,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => _showDetailsDialog(context, measurement.customerId),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Leading section with avatar and main info
                  Expanded(
                    child: Row(
                      children: [
                        Hero(
                          tag: 'measurement_avatar_${measurement.id}',
                          child: CircleAvatar(
                            radius: screenWidth < 360 ? 18 : 22,
                            backgroundColor: theme.colorScheme.primary,
                            child: Icon(
                              Icons.straighten,
                              color: Colors.white,
                              size: screenWidth < 360 ? 18 : 22,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Customer name and bill number row
                              Row(
                                children: [
                                  Flexible(
                                    child: FutureBuilder<String>(
                                      future: _supabaseService.getCustomerName(measurement.customerId),
                                      builder: (context, snapshot) {
                                        final name = snapshot.data ?? 'Loading...';
                                        return Text(
                                          name.length > 7 ? '${name.substring(0, 7)}...' : name,
                                          style: TextStyle(
                                            fontWeight: FontWeight.w600,
                                            fontSize: defaultTextSize + 2,
                                          ),
                                        );
                                      },
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 6,
                                      vertical: 2,
                                    ),
                                    decoration: BoxDecoration(
                                      color: theme.colorScheme.primary.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      '#${measurement.billNumber}',
                                      style: TextStyle(
                                        color: theme.colorScheme.primary,
                                        fontSize: defaultTextSize - 2,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              // Date and style info
                              Row(
                                children: [
                                  Text(
                                    DateFormat('MMM dd, yyyy').format(measurement.lastUpdated),
                                    style: TextStyle(
                                      fontSize: defaultTextSize - 2,
                                      color: theme.colorScheme.onSurfaceVariant,
                                    ),
                                  ),
                                  Container(
                                    margin: const EdgeInsets.symmetric(horizontal: 4),
                                    width: 3,
                                    height: 3,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: theme.colorScheme.onSurfaceVariant,
                                    ),
                                  ),
                                  Expanded(
                                    child: Text(
                                      measurement.style,
                                      style: TextStyle(
                                        fontSize: defaultTextSize - 2,
                                        color: theme.colorScheme.onSurfaceVariant,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Actions menu
                  PopupMenuButton<String>(
                    position: PopupMenuPosition.under,
                    icon: Icon(
                      Icons.more_vert,
                      size: screenWidth < 360 ? 20 : 24,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    itemBuilder: (context) => [
                      PopupMenuItem(
                        value: 'edit',
                        child: Row(
                          children: [
                            Icon(
                              Icons.edit_outlined,
                              size: screenWidth < 360 ? 18 : 20,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Edit',
                              style: TextStyle(fontSize: defaultTextSize),
                            ),
                          ],
                        ),
                      ),
                      PopupMenuItem(
                        value: 'delete',
                        child: Row(
                          children: [
                            Icon(
                              Icons.delete_outline,
                              color: Colors.red,
                              size: screenWidth < 360 ? 18 : 20,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Delete',
                              style: TextStyle(
                                color: Colors.red,
                                fontSize: defaultTextSize,
                              ),
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
              const SizedBox(height: 12),
              // Style Details Badges
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    // Show only the first 3 style details
                    ...buildStyleDetailBadges(context, theme).take(3).mapIndexed(
                      (index, badge) => Padding(
                        padding: EdgeInsets.only(left: index > 0 ? 4 : 0),
                        child: badge,
                      ),
                    ),
                    // Show "More" badge if there are more than 3 style details
                    if (buildStyleDetailBadges(context, theme).length > 3)
                      Padding(
                        padding: const EdgeInsets.only(left: 4),
                        child: MeasurementBadge(
                          text: '+${buildStyleDetailBadges(context, theme).length - 3} more',
                          color: theme.colorScheme.outline,
                          small: true,
                        ),
                      ),
                    // Show notes badge if available
                    if (measurement.notes.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(left: 4),
                        child: MeasurementBadge(
                          text: 'Notes: ${measurement.notes}',
                          color: Colors.grey,
                          maxWidth: 150,
                          small: true,
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
