import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';
import '../../../theme/inventory_design_config.dart';
import '../../../models/measurement.dart'; // Assuming a Measurement model exists

class MeasurementSelectorDialog extends StatefulWidget {
  final String customerId;
  final String? selectedMeasurementId;
  final Function(Measurement measurement) onMeasurementSelected;

  const MeasurementSelectorDialog({
    super.key,
    required this.customerId,
    this.selectedMeasurementId,
    required this.onMeasurementSelected,
  });

  static Future<void> show(
    BuildContext context, {
    required String customerId,
    String? selectedMeasurementId,
    required Function(Measurement measurement) onMeasurementSelected,
  }) {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (context) => MeasurementSelectorDialog(
        customerId: customerId,
        selectedMeasurementId: selectedMeasurementId,
        onMeasurementSelected: onMeasurementSelected,
      ),
    );
  }

  @override
  State<MeasurementSelectorDialog> createState() =>
      _MeasurementSelectorDialogState();
}

class _MeasurementSelectorDialogState extends State<MeasurementSelectorDialog> {
  final _supabase = Supabase.instance.client;
  final _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  final FocusNode _listFocusNode = FocusNode();

  List<Measurement> _measurements = [];
  List<Measurement> _filteredMeasurements = [];
  bool _isLoading = false;
  String? _currentSelectedMeasurementId;
  int _highlightedIndex = -1;

  @override
  void initState() {
    super.initState();
    _currentSelectedMeasurementId = widget.selectedMeasurementId;
    _loadMeasurements();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      FocusScope.of(context).requestFocus(_searchFocusNode);
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    _listFocusNode.dispose();
    super.dispose();
  }

  Future<void> _loadMeasurements() async {
    setState(() => _isLoading = true);

    try {
      final response = await _supabase
          .from('measurements')
          .select('*') // Select all fields for now, can be optimized later
          .eq('customer_id', widget.customerId)
          .order('date', ascending: false);

      setState(() {
        _measurements = List<Measurement>.from(response.map((map) => Measurement.fromMap(map)));
        _filteredMeasurements = _measurements;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading measurements: ${e.toString()}'),
            backgroundColor: InventoryDesignConfig.errorColor,
          ),
        );
      }
    }
  }

  void _filterMeasurements(String query) {
    setState(() {
      if (query.isEmpty) {
        _filteredMeasurements = _measurements;
      } else {
        _filteredMeasurements = _measurements
            .where((measurement) =>
                measurement.style.toLowerCase().contains(query.toLowerCase()) ||
                measurement.designType.toLowerCase().contains(query.toLowerCase()))
            .toList();
      }
    });
  }

  void _handleKeyEvent(RawKeyEvent event) {
    if (event is RawKeyDownEvent) {
      if (event.logicalKey == LogicalKeyboardKey.arrowDown) {
        setState(() {
          if (_filteredMeasurements.isNotEmpty) {
            _highlightedIndex =
                (_highlightedIndex + 1) % _filteredMeasurements.length;
          }
        });
      } else if (event.logicalKey == LogicalKeyboardKey.arrowUp) {
        setState(() {
          if (_filteredMeasurements.isNotEmpty) {
            _highlightedIndex =
                (_highlightedIndex - 1 + _filteredMeasurements.length) %
                    _filteredMeasurements.length;
          }
        });
      } else if (event.logicalKey == LogicalKeyboardKey.enter) {
        if (_highlightedIndex != -1 &&
            _highlightedIndex < _filteredMeasurements.length) {
          _selectMeasurement(_filteredMeasurements[_highlightedIndex]);
        } else if (_currentSelectedMeasurementId != null) {
          final selectedMeasurement = _measurements.firstWhere(
            (measurement) => measurement.id == _currentSelectedMeasurementId,
          );
          _selectMeasurement(selectedMeasurement);
        }
      }
    }
  }

  void _selectMeasurement(Measurement measurement) {
    Navigator.of(context).pop();
    widget.onMeasurementSelected(measurement);
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;

    return RawKeyboardListener(
      focusNode: FocusNode(),
      onKey: _handleKeyEvent,
      child: Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: 550,
            maxHeight: screenSize.height * 0.75,
          ),
          child: Container(
            decoration: BoxDecoration(
              color: InventoryDesignConfig.surfaceColor,
              borderRadius: BorderRadius.circular(InventoryDesignConfig.radiusXL),
              border: Border.all(color: InventoryDesignConfig.borderPrimary),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.08),
                  blurRadius: 16,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildHeader(),
                Flexible(child: _buildContent()),
                _buildFooter(),
              ],
            ),
          ),
        ),
      ),
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
              size: 18,
              color: InventoryDesignConfig.primaryColor,
            ),
          ),
          const SizedBox(width: InventoryDesignConfig.spacingL),
          Expanded(
            child: Text(
              'Select Measurement',
              style: InventoryDesignConfig.headlineMedium,
            ),
          ),
          Material(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(InventoryDesignConfig.radiusM),
            child: InkWell(
              onTap: () => Navigator.of(context).pop(),
              borderRadius: BorderRadius.circular(
                InventoryDesignConfig.radiusM,
              ),
              child: Container(
                padding: const EdgeInsets.all(InventoryDesignConfig.spacingS),
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
    );
  }

  Widget _buildContent() {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(InventoryDesignConfig.spacingXXL),
          child: Container(
            decoration: InventoryDesignConfig.inputDecoration,
            child: TextField(
              controller: _searchController,
              focusNode: _searchFocusNode,
              style: InventoryDesignConfig.bodyLarge,
              decoration: InputDecoration(
                hintText: 'Search measurements...',
                hintStyle: InventoryDesignConfig.bodyMedium,
                prefixIcon: Padding(
                  padding: const EdgeInsets.all(
                    InventoryDesignConfig.spacingM,
                  ),
                  child: Icon(
                    PhosphorIcons.magnifyingGlass(),
                    size: 18,
                    color: InventoryDesignConfig.textSecondary,
                  ),
                ),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: InventoryDesignConfig.spacingL,
                  vertical: InventoryDesignConfig.spacingM,
                ),
              ),
              onChanged: (query) {
                _filterMeasurements(query);
                setState(() {
                  _highlightedIndex = _filteredMeasurements.isNotEmpty ? 0 : -1;
                });
              },
              onSubmitted: (_) {
                if (_highlightedIndex != -1 &&
                    _highlightedIndex < _filteredMeasurements.length) {
                  _selectMeasurement(_filteredMeasurements[_highlightedIndex]);
                }
              },
            ),
          ),
        ),
        Expanded(
          child: Container(
            margin: const EdgeInsets.symmetric(
              horizontal: InventoryDesignConfig.spacingXXL,
            ),
            child: _isLoading
                ? Center(
                    child: CircularProgressIndicator(
                      color: InventoryDesignConfig.primaryAccent,
                    ),
                  )
                : _filteredMeasurements.isEmpty
                    ? _buildEmptyState()
                    : _buildMeasurementsList(),
          ),
        ),
        const SizedBox(height: InventoryDesignConfig.spacingL),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(InventoryDesignConfig.spacingXL),
            decoration: BoxDecoration(
              color: InventoryDesignConfig.surfaceAccent,
              borderRadius: BorderRadius.circular(
                InventoryDesignConfig.radiusL,
              ),
            ),
            child: Icon(
              PhosphorIcons.ruler(),
              size: 32,
              color: InventoryDesignConfig.textTertiary,
            ),
          ),
          const SizedBox(height: InventoryDesignConfig.spacingL),
          Text(
            'No measurements found for this customer',
            style: InventoryDesignConfig.titleMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: InventoryDesignConfig.spacingS),
          Text(
            'Ensure the customer has measurements added in their profile.',
            style: InventoryDesignConfig.bodyMedium,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildMeasurementsList() {
    return Focus(
      focusNode: _listFocusNode,
      child: ListView.separated(
        padding: EdgeInsets.zero,
        itemCount: _filteredMeasurements.length,
        separatorBuilder: (context, index) =>
            const SizedBox(height: InventoryDesignConfig.spacingXS),
        itemBuilder: (context, index) {
          final measurement = _filteredMeasurements[index];
          final isSelected = measurement.id == _currentSelectedMeasurementId;
          final isHighlighted = index == _highlightedIndex;

          return Material(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(InventoryDesignConfig.radiusM),
            child: InkWell(
              borderRadius: BorderRadius.circular(InventoryDesignConfig.radiusM),
              onTap: () {
                setState(() {
                  _currentSelectedMeasurementId = measurement.id;
                  _highlightedIndex = index;
                });
              },
              onDoubleTap: () => _selectMeasurement(measurement),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: InventoryDesignConfig.spacingL,
                  vertical: InventoryDesignConfig.spacingM,
                ),
                decoration: BoxDecoration(
                  color: isHighlighted
                      ? InventoryDesignConfig.primaryColor.withOpacity(0.2)
                      : isSelected
                          ? InventoryDesignConfig.primaryColor.withOpacity(0.08)
                          : InventoryDesignConfig.surfaceAccent,
                  borderRadius: BorderRadius.circular(
                    InventoryDesignConfig.radiusM,
                  ),
                  border: Border.all(
                    color: isHighlighted || isSelected
                        ? InventoryDesignConfig.primaryColor
                        : InventoryDesignConfig.borderSecondary,
                    width: isHighlighted || isSelected ? 1.5 : 1,
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: isSelected
                            ? InventoryDesignConfig.primaryColor
                            : InventoryDesignConfig.surfaceColor,
                        borderRadius: BorderRadius.circular(
                          InventoryDesignConfig.radiusS,
                        ),
                        border: Border.all(
                          color: isSelected
                              ? InventoryDesignConfig.primaryColor
                              : InventoryDesignConfig.borderPrimary,
                        ),
                      ),
                      child: Icon(
                        PhosphorIcons.ruler(),
                        size: 18,
                        color: isSelected ? Colors.white : InventoryDesignConfig.primaryColor,
                      ),
                    ),
                    const SizedBox(width: InventoryDesignConfig.spacingM),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Style: ${measurement.style}',
                            style: InventoryDesignConfig.titleMedium.copyWith(
                              color: isSelected
                                  ? InventoryDesignConfig.primaryColor
                                  : InventoryDesignConfig.textPrimary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Text(
                            'Design: ${measurement.designType} • ${DateFormat.yMMMd().format(measurement.date)}',
                            style: InventoryDesignConfig.bodySmall.copyWith(
                              color: isSelected
                                  ? InventoryDesignConfig.primaryColor.withOpacity(0.8)
                                  : InventoryDesignConfig.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (isSelected)
                      Container(
                        padding: const EdgeInsets.all(
                          InventoryDesignConfig.spacingXS,
                        ),
                        decoration: BoxDecoration(
                          color: InventoryDesignConfig.primaryColor,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          PhosphorIcons.check(),
                          size: 12,
                          color: Colors.white,
                        ),
                      ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildFooter() {
    return Container(
      padding: const EdgeInsets.all(InventoryDesignConfig.spacingXXL),
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
          Material(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(InventoryDesignConfig.radiusM),
            child: InkWell(
              onTap: () => Navigator.of(context).pop(),
              borderRadius: BorderRadius.circular(
                InventoryDesignConfig.radiusM,
              ),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: InventoryDesignConfig.spacingXXL,
                  vertical: InventoryDesignConfig.spacingM,
                ),
                decoration: InventoryDesignConfig.buttonSecondaryDecoration,
                child: Text(
                  'Cancel',
                  style: InventoryDesignConfig.bodyMedium.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: InventoryDesignConfig.spacingL),
          Material(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(InventoryDesignConfig.radiusM),
            child: InkWell(
              onTap: _currentSelectedMeasurementId != null
                  ? () {
                      final selectedMeasurement = _measurements.firstWhere(
                        (measurement) => measurement.id == _currentSelectedMeasurementId,
                      );
                      _selectMeasurement(selectedMeasurement);
                    }
                  : null,
              borderRadius: BorderRadius.circular(
                InventoryDesignConfig.radiusM,
              ),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: InventoryDesignConfig.spacingXXL,
                  vertical: InventoryDesignConfig.spacingM,
                ),
                decoration: InventoryDesignConfig.buttonPrimaryDecoration,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(PhosphorIcons.check(), size: 16, color: Colors.white),
                    const SizedBox(width: InventoryDesignConfig.spacingS),
                    Text(
                      'Select Measurement',
                      style: InventoryDesignConfig.bodyMedium.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
