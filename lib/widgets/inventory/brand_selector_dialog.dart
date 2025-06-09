import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'inventory_design_config.dart';

class BrandSelectorDialog extends StatefulWidget {
  final String? selectedBrandId;
  final Function(String brandId, String brandName) onBrandSelected;

  const BrandSelectorDialog({
    super.key,
    this.selectedBrandId,
    required this.onBrandSelected,
  });

  static Future<void> show(
    BuildContext context, {
    String? selectedBrandId,
    required Function(String brandId, String brandName) onBrandSelected,
  }) {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder:
          (context) => BrandSelectorDialog(
            selectedBrandId: selectedBrandId,
            onBrandSelected: onBrandSelected,
          ),
    );
  }

  @override
  State<BrandSelectorDialog> createState() => _BrandSelectorDialogState();
}

class _BrandSelectorDialogState extends State<BrandSelectorDialog> {
  final _supabase = Supabase.instance.client;
  final _searchController = TextEditingController();
  final _newBrandController = TextEditingController();

  List<Map<String, dynamic>> _brands = [];
  List<Map<String, dynamic>> _filteredBrands = [];
  bool _isLoading = false;
  bool _isAddingNew = false;
  String? _selectedBrandId;

  @override
  void initState() {
    super.initState();
    _selectedBrandId = widget.selectedBrandId;
    _loadBrands();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _newBrandController.dispose();
    super.dispose();
  }

  Future<void> _loadBrands() async {
    setState(() => _isLoading = true);

    try {
      final response = await _supabase
          .from('brands')
          .select('id, name, brand_type')
          .order('name');

      setState(() {
        _brands = List<Map<String, dynamic>>.from(response);
        _filteredBrands = _brands;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading brands: ${e.toString()}'),
            backgroundColor: InventoryDesignConfig.errorColor,
          ),
        );
      }
    }
  }

  void _filterBrands(String query) {
    setState(() {
      if (query.isEmpty) {
        _filteredBrands = _brands;
      } else {
        _filteredBrands =
            _brands
                .where(
                  (brand) =>
                      brand['name'].toLowerCase().contains(query.toLowerCase()),
                )
                .toList();
      }
    });
  }

  Future<void> _addNewBrand() async {
    if (_newBrandController.text.trim().isEmpty) return;

    setState(() => _isAddingNew = true);

    try {
      final response =
          await _supabase
              .from('brands')
              .insert({
                'name': _newBrandController.text.trim(),
                'brand_type': 'general',
                'tenant_id': _supabase.auth.currentUser?.id,
                'created_at': DateTime.now().toIso8601String(),
                'updated_at': DateTime.now().toIso8601String(),
              })
              .select()
              .single();

      if (mounted) {
        Navigator.of(context).pop();
        widget.onBrandSelected(response['id'].toString(), response['name']);

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Brand "${response['name']}" added successfully'),
            backgroundColor: InventoryDesignConfig.successColor,
          ),
        );
      }
    } catch (e) {
      setState(() => _isAddingNew = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error adding brand: ${e.toString()}'),
            backgroundColor: InventoryDesignConfig.errorColor,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: 450,
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
              PhosphorIcons.tag(),
              size: 18,
              color: InventoryDesignConfig.primaryColor,
            ),
          ),
          const SizedBox(width: InventoryDesignConfig.spacingL),
          Expanded(
            child: Text(
              'Select Brand',
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
        // Search and Add section combined
        Container(
          padding: const EdgeInsets.all(InventoryDesignConfig.spacingXXL),
          child: Column(
            children: [
              // Search bar
              Container(
                decoration: InventoryDesignConfig.inputDecoration,
                child: TextField(
                  controller: _searchController,
                  style: InventoryDesignConfig.bodyLarge,
                  decoration: InputDecoration(
                    hintText: 'Search brands...',
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
                  onChanged: _filterBrands,
                ),
              ),

              const SizedBox(height: InventoryDesignConfig.spacingL),

              // Quick Add Row
              Row(
                children: [
                  Expanded(
                    child: Container(
                      decoration: InventoryDesignConfig.inputDecoration,
                      child: TextField(
                        controller: _newBrandController,
                        style: InventoryDesignConfig.bodyLarge,
                        decoration: InputDecoration(
                          hintText: 'Add new brand...',
                          hintStyle: InventoryDesignConfig.bodyMedium,
                          prefixIcon: Padding(
                            padding: const EdgeInsets.all(
                              InventoryDesignConfig.spacingM,
                            ),
                            child: Icon(
                              PhosphorIcons.plus(),
                              size: 16,
                              color: InventoryDesignConfig.primaryColor,
                            ),
                          ),
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: InventoryDesignConfig.spacingL,
                            vertical: InventoryDesignConfig.spacingM,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: InventoryDesignConfig.spacingM),
                  Material(
                    color: Colors.transparent,
                    borderRadius: BorderRadius.circular(
                      InventoryDesignConfig.radiusM,
                    ),
                    child: InkWell(
                      onTap: _isAddingNew ? null : _addNewBrand,
                      borderRadius: BorderRadius.circular(
                        InventoryDesignConfig.radiusM,
                      ),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: InventoryDesignConfig.spacingL,
                          vertical: InventoryDesignConfig.spacingM,
                        ),
                        decoration:
                            InventoryDesignConfig.buttonPrimaryDecoration,
                        child:
                            _isAddingNew
                                ? SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                                : Icon(
                                  PhosphorIcons.plus(),
                                  size: 16,
                                  color: Colors.white,
                                ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),

        // Brands list with improved layout
        Expanded(
          child: Container(
            margin: const EdgeInsets.symmetric(
              horizontal: InventoryDesignConfig.spacingXXL,
            ),
            child:
                _isLoading
                    ? Center(
                      child: CircularProgressIndicator(
                        color: InventoryDesignConfig.primaryAccent,
                      ),
                    )
                    : _filteredBrands.isEmpty
                    ? _buildEmptyState()
                    : _buildBrandsList(),
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
              PhosphorIcons.tag(),
              size: 32,
              color: InventoryDesignConfig.textTertiary,
            ),
          ),
          const SizedBox(height: InventoryDesignConfig.spacingL),
          Text('No brands found', style: InventoryDesignConfig.titleMedium),
          const SizedBox(height: InventoryDesignConfig.spacingS),
          Text(
            _searchController.text.isNotEmpty
                ? 'Try a different search or add a new brand above'
                : 'Add your first brand above to get started',
            style: InventoryDesignConfig.bodyMedium,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildBrandsList() {
    return ListView.separated(
      padding: EdgeInsets.zero,
      itemCount: _filteredBrands.length,
      separatorBuilder:
          (context, index) =>
              const SizedBox(height: InventoryDesignConfig.spacingXS),
      itemBuilder: (context, index) {
        final brand = _filteredBrands[index];
        final isSelected = brand['id'].toString() == _selectedBrandId;

        return Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(InventoryDesignConfig.radiusM),
          child: InkWell(
            borderRadius: BorderRadius.circular(InventoryDesignConfig.radiusM),
            onTap: () {
              setState(() {
                _selectedBrandId = brand['id'].toString();
              });
            },
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: InventoryDesignConfig.spacingL,
                vertical: InventoryDesignConfig.spacingM,
              ),
              decoration: BoxDecoration(
                color:
                    isSelected
                        ? InventoryDesignConfig.primaryColor.withOpacity(0.08)
                        : InventoryDesignConfig.surfaceAccent,
                borderRadius: BorderRadius.circular(
                  InventoryDesignConfig.radiusM,
                ),
                border: Border.all(
                  color:
                      isSelected
                          ? InventoryDesignConfig.primaryColor
                          : InventoryDesignConfig.borderSecondary,
                  width: isSelected ? 1.5 : 1,
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color:
                          isSelected
                              ? InventoryDesignConfig.primaryColor
                              : InventoryDesignConfig.surfaceColor,
                      borderRadius: BorderRadius.circular(
                        InventoryDesignConfig.radiusS,
                      ),
                      border: Border.all(
                        color:
                            isSelected
                                ? InventoryDesignConfig.primaryColor
                                : InventoryDesignConfig.borderPrimary,
                      ),
                    ),
                    child: Icon(
                      PhosphorIcons.tag(),
                      size: 16,
                      color:
                          isSelected
                              ? Colors.white
                              : InventoryDesignConfig.primaryColor,
                    ),
                  ),
                  const SizedBox(width: InventoryDesignConfig.spacingM),
                  Expanded(
                    child: Text(
                      brand['name'],
                      style: InventoryDesignConfig.titleMedium.copyWith(
                        color:
                            isSelected
                                ? InventoryDesignConfig.primaryColor
                                : InventoryDesignConfig.textPrimary,
                        fontWeight: FontWeight.w600,
                      ),
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
              onTap:
                  _selectedBrandId != null
                      ? () {
                        final selectedBrand = _filteredBrands.firstWhere(
                          (brand) => brand['id'].toString() == _selectedBrandId,
                        );
                        Navigator.of(context).pop();
                        widget.onBrandSelected(
                          selectedBrand['id'].toString(),
                          selectedBrand['name'],
                        );
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
                      'Select Brand',
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
