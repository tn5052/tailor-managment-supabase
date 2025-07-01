import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';
import '../../../theme/inventory_design_config.dart';
import '../../../models/measurement.dart';

class MeasurementSelectorSheet extends StatefulWidget {
  final String customerId;
  final Function(Measurement) onMeasurementSelected;

  const MeasurementSelectorSheet({
    Key? key,
    required this.customerId,
    required this.onMeasurementSelected,
  }) : super(key: key);

  static Future<void> show(
    BuildContext context, {
    required String customerId,
    required Function(Measurement) onMeasurementSelected,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      enableDrag: false,
      isDismissible: false,
      useSafeArea: true,
      builder: (context) => MeasurementSelectorSheet(
        customerId: customerId,
        onMeasurementSelected: onMeasurementSelected,
      ),
    );
  }

  @override
  _MeasurementSelectorSheetState createState() =>
      _MeasurementSelectorSheetState();
}

class _MeasurementSelectorSheetState extends State<MeasurementSelectorSheet>
    with TickerProviderStateMixin {
  final _supabase = Supabase.instance.client;
  final _searchController = TextEditingController();
  List<Measurement> _measurements = [];
  List<Measurement> _filteredMeasurements = [];
  bool _isLoading = true;
  String _searchQuery = '';
  Timer? _debounceTimer;

  // Animation controllers
  late AnimationController _sheetAnimationController;
  late Animation<double> _sheetAnimation;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _fetchMeasurements();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _sheetAnimationController.forward();
    });
  }

  void _initializeAnimations() {
    _sheetAnimationController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _sheetAnimation = CurvedAnimation(
      parent: _sheetAnimationController,
      curve: Curves.easeOutCubic,
    );
  }

  @override
  void dispose() {
    _sheetAnimationController.dispose();
    _searchController.dispose();
    _debounceTimer?.cancel();
    super.dispose();
  }

  Future<void> _fetchMeasurements() async {
    setState(() => _isLoading = true);
    try {
      final response = await _supabase
          .from('measurements')
          .select()
          .eq('customer_id', widget.customerId)
          .order('date', ascending: false);
      
      final measurements = response.map((data) => Measurement.fromMap(data)).toList();
      
      setState(() {
        _measurements = measurements;
        _filteredMeasurements = measurements;
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
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 300), () {
      if (!mounted) return;

      setState(() {
        _searchQuery = query.toLowerCase();
        if (_searchQuery.isEmpty) {
          _filteredMeasurements = _measurements;
        } else {
          _filteredMeasurements = _measurements.where((measurement) {
            return measurement.style.toLowerCase().contains(_searchQuery);
          }).toList();
        }
      });
    });
  }

  Future<void> _handleClose() async {
    HapticFeedback.lightImpact();
    await _sheetAnimationController.reverse();
    if (mounted) {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final screenHeight = mediaQuery.size.height;
    final safeAreaTop = mediaQuery.padding.top;

    return AnimatedBuilder(
      animation: _sheetAnimation,
      builder: (context, child) {
        return Scaffold(
          backgroundColor: Colors.black.withOpacity(0.4 * _sheetAnimation.value),
          resizeToAvoidBottomInset: true,
          body: GestureDetector(
            onTap: () => FocusScope.of(context).unfocus(),
            child: Stack(
              children: [
                Positioned(
                  left: 0,
                  right: 0,
                  top: safeAreaTop + 40,
                  bottom: 0,
                  child: Transform.translate(
                    offset: Offset(
                      0,
                      (screenHeight - safeAreaTop - 40) * (1 - _sheetAnimation.value),
                    ),
                    child: _buildSheetContent(),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildSheetContent() {
    return Container(
      decoration: BoxDecoration(
        color: InventoryDesignConfig.surfaceColor,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(InventoryDesignConfig.radiusXL),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Column(
        children: [
          _buildHeader(),
          _buildSearchBar(),
          Expanded(child: _buildMeasurementList()),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      decoration: const BoxDecoration(
        color: InventoryDesignConfig.surfaceColor,
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(InventoryDesignConfig.radiusXL),
        ),
      ),
      child: Column(
        children: [
          // Handle
          Container(
            margin: const EdgeInsets.only(top: 12, bottom: 8),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: InventoryDesignConfig.borderPrimary,
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // Header content
          Padding(
            padding: const EdgeInsets.fromLTRB(
              InventoryDesignConfig.spacingXL,
              InventoryDesignConfig.spacingS,
              InventoryDesignConfig.spacingXL,
              InventoryDesignConfig.spacingL,
            ),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: InventoryDesignConfig.primaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(InventoryDesignConfig.radiusM),
                    border: Border.all(
                      color: InventoryDesignConfig.primaryColor.withOpacity(0.2),
                    ),
                  ),
                  child: Icon(
                    PhosphorIcons.ruler(),
                    color: InventoryDesignConfig.primaryColor,
                    size: 24,
                  ),
                ),
                const SizedBox(width: InventoryDesignConfig.spacingL),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Select Measurement',
                        style: InventoryDesignConfig.headlineMedium.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: InventoryDesignConfig.spacingXS),
                      Text(
                        '${_filteredMeasurements.length} profiles available',
                        style: InventoryDesignConfig.bodyMedium.copyWith(
                          color: InventoryDesignConfig.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                _buildHeaderActionButton(
                  icon: PhosphorIcons.x(),
                  onTap: _handleClose,
                  semanticLabel: 'Close measurement selector',
                ),
              ],
            ),
          ),

          Container(height: 1, color: InventoryDesignConfig.borderSecondary),
        ],
      ),
    );
  }

  Widget _buildHeaderActionButton({
    required IconData icon,
    required VoidCallback onTap,
    required String semanticLabel,
  }) {
    return Semantics(
      label: semanticLabel,
      button: true,
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(InventoryDesignConfig.radiusM),
        child: InkWell(
          onTap: () {
            HapticFeedback.selectionClick();
            onTap();
          },
          borderRadius: BorderRadius.circular(InventoryDesignConfig.radiusM),
          child: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: InventoryDesignConfig.textSecondary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(InventoryDesignConfig.radiusM),
            ),
            child: Icon(
              icon,
              size: 18,
              color: InventoryDesignConfig.textSecondary,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.all(InventoryDesignConfig.spacingXL),
      child: Container(
        decoration: BoxDecoration(
          color: InventoryDesignConfig.surfaceLight,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: InventoryDesignConfig.borderPrimary),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: TextField(
          controller: _searchController,
          style: InventoryDesignConfig.bodyLarge,
          decoration: InputDecoration(
            hintText: 'Search by style name...',
            hintStyle: InventoryDesignConfig.bodyMedium.copyWith(
              color: InventoryDesignConfig.textTertiary,
            ),
            prefixIcon: Padding(
              padding: const EdgeInsets.all(InventoryDesignConfig.spacingM),
              child: Icon(
                PhosphorIcons.magnifyingGlass(),
                size: 20,
                color: InventoryDesignConfig.primaryColor,
              ),
            ),
            suffixIcon: _searchQuery.isNotEmpty
                ? IconButton(
                    icon: Icon(
                      PhosphorIcons.x(),
                      size: 18,
                      color: InventoryDesignConfig.textSecondary,
                    ),
                    onPressed: () {
                      _searchController.clear();
                      _filterMeasurements('');
                    },
                  )
                : null,
            border: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(
              vertical: InventoryDesignConfig.spacingL,
            ),
          ),
          onChanged: _filterMeasurements,
        ),
      ),
    );
  }

  Widget _buildMeasurementList() {
    if (_isLoading) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(
              color: InventoryDesignConfig.primaryColor,
            ),
            const SizedBox(height: InventoryDesignConfig.spacingL),
            Text(
              'Loading measurements...',
              style: InventoryDesignConfig.bodyMedium.copyWith(
                color: InventoryDesignConfig.textSecondary,
              ),
            ),
          ],
        ),
      );
    }

    if (_filteredMeasurements.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(InventoryDesignConfig.spacingXXL),
              decoration: BoxDecoration(
                color: InventoryDesignConfig.surfaceAccent,
                borderRadius: BorderRadius.circular(
                  InventoryDesignConfig.radiusXL,
                ),
              ),
              child: Icon(
                _searchQuery.isNotEmpty 
                    ? PhosphorIcons.magnifyingGlass()
                    : PhosphorIcons.ruler(),
                size: 48,
                color: InventoryDesignConfig.textTertiary,
              ),
            ),
            const SizedBox(height: InventoryDesignConfig.spacingXL),
            Text(
              'No measurements found',
              style: InventoryDesignConfig.headlineMedium,
            ),
            const SizedBox(height: InventoryDesignConfig.spacingS),
            Text(
              'No measurement profiles found for this customer.',
              style: InventoryDesignConfig.bodyMedium.copyWith(
                color: InventoryDesignConfig.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(
        horizontal: InventoryDesignConfig.spacingXL,
      ),
      itemCount: _filteredMeasurements.length,
      itemBuilder: (context, index) => _buildMeasurementCard(_filteredMeasurements[index]),
    );
  }

  Widget _buildMeasurementCard(Measurement measurement) {
    return Container(
      margin: const EdgeInsets.only(bottom: InventoryDesignConfig.spacingM),
      decoration: BoxDecoration(
        color: InventoryDesignConfig.surfaceColor,
        borderRadius: BorderRadius.circular(InventoryDesignConfig.radiusL),
        border: Border.all(
          color: InventoryDesignConfig.borderSecondary,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(InventoryDesignConfig.radiusL),
        child: InkWell(
          onTap: () {
            HapticFeedback.selectionClick();
            widget.onMeasurementSelected(measurement);
            _handleClose();
          },
          borderRadius: BorderRadius.circular(InventoryDesignConfig.radiusL),
          child: Padding(
            padding: const EdgeInsets.all(InventoryDesignConfig.spacingL),
            child: Row(
              children: [
                // Icon
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: InventoryDesignConfig.primaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Center(
                    child: Icon(
                      PhosphorIcons.ruler(),
                      color: InventoryDesignConfig.primaryColor,
                      size: 24,
                    ),
                  ),
                ),

                const SizedBox(width: InventoryDesignConfig.spacingL),

                // Measurement info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        measurement.style,
                        style: InventoryDesignConfig.titleMedium.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: InventoryDesignConfig.spacingXS),
                      Text(
                        'Last Updated: ${DateFormat.yMMMd().format(measurement.date)}',
                        style: InventoryDesignConfig.bodySmall.copyWith(
                          color: InventoryDesignConfig.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),

                // Arrow
                Icon(
                  PhosphorIcons.caretRight(),
                  size: 20,
                  color: InventoryDesignConfig.textTertiary,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
