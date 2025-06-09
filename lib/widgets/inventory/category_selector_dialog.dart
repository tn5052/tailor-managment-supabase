import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'inventory_design_config.dart';

class CategorySelectorDialog extends StatefulWidget {
  final String inventoryType; // 'fabric' or 'accessory'
  final String? selectedCategoryId;
  final Function(String categoryId, String categoryName) onCategorySelected;

  const CategorySelectorDialog({
    super.key,
    required this.inventoryType,
    this.selectedCategoryId,
    required this.onCategorySelected,
  });

  static Future<void> show(
    BuildContext context, {
    required String inventoryType,
    String? selectedCategoryId,
    required Function(String categoryId, String categoryName)
    onCategorySelected,
  }) {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder:
          (context) => CategorySelectorDialog(
            inventoryType: inventoryType,
            selectedCategoryId: selectedCategoryId,
            onCategorySelected: onCategorySelected,
          ),
    );
  }

  @override
  State<CategorySelectorDialog> createState() => _CategorySelectorDialogState();
}

class _CategorySelectorDialogState extends State<CategorySelectorDialog> {
  final _supabase = Supabase.instance.client;
  final _searchController = TextEditingController();
  final _newCategoryController = TextEditingController();
  final _descriptionController = TextEditingController();

  List<Map<String, dynamic>> _categories = [];
  List<Map<String, dynamic>> _filteredCategories = [];
  bool _isLoading = false;
  bool _isAddingNew = false;
  String? _selectedCategoryId;

  // Predefined categories for each type - simplified list

  @override
  void initState() {
    super.initState();
    _selectedCategoryId = widget.selectedCategoryId;
    _loadCategories();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _newCategoryController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _loadCategories() async {
    setState(() => _isLoading = true);

    try {
      final response = await _supabase
          .from('inventory_categories')
          .select('id, category_name, description, category_type, is_active')
          .eq('category_type', widget.inventoryType)
          .eq('is_active', true)
          .order('category_name');

      setState(() {
        _categories = List<Map<String, dynamic>>.from(response);
        _filteredCategories = _categories;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading categories: ${e.toString()}'),
            backgroundColor: InventoryDesignConfig.errorColor,
          ),
        );
      }
    }
  }

  void _filterCategories(String query) {
    setState(() {
      if (query.isEmpty) {
        _filteredCategories = _categories;
      } else {
        _filteredCategories =
            _categories
                .where(
                  (category) => category['category_name']
                      .toLowerCase()
                      .contains(query.toLowerCase()),
                )
                .toList();
      }
    });
  }

  Future<void> _addNewCategory() async {
    if (_newCategoryController.text.trim().isEmpty) return;

    setState(() => _isAddingNew = true);

    try {
      final response =
          await _supabase
              .from('inventory_categories')
              .insert({
                'category_name': _newCategoryController.text.trim(),
                'description':
                    _descriptionController.text.trim().isEmpty
                        ? null
                        : _descriptionController.text.trim(),
                'category_type': widget.inventoryType,
                'is_active': true,
                'tenant_id': _supabase.auth.currentUser?.id,
                'created_at': DateTime.now().toIso8601String(),
              })
              .select()
              .single();

      if (mounted) {
        Navigator.of(context).pop();
        widget.onCategorySelected(
          response['id'].toString(),
          response['category_name'],
        );

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Category "${response['category_name']}" added successfully',
            ),
            backgroundColor: InventoryDesignConfig.successColor,
          ),
        );
      }
    } catch (e) {
      setState(() => _isAddingNew = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error adding category: ${e.toString()}'),
            backgroundColor: InventoryDesignConfig.errorColor,
          ),
        );
      }
    }
  }

  Future<void> _addPredefinedCategory(String categoryName) async {
    setState(() => _isAddingNew = true);

    try {
      final response =
          await _supabase
              .from('inventory_categories')
              .insert({
                'category_name': categoryName,
                'description': null,
                'category_type': widget.inventoryType,
                'is_active': true,
                'tenant_id': _supabase.auth.currentUser?.id,
                'created_at': DateTime.now().toIso8601String(),
              })
              .select()
              .single();

      if (mounted) {
        Navigator.of(context).pop();
        widget.onCategorySelected(
          response['id'].toString(),
          response['category_name'],
        );

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Category "${response['category_name']}" added successfully',
            ),
            backgroundColor: InventoryDesignConfig.successColor,
          ),
        );
      }
    } catch (e) {
      setState(() => _isAddingNew = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error adding category: ${e.toString()}'),
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
          maxWidth: 480,
          maxHeight: screenSize.height * 0.8,
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
              PhosphorIcons.folder(),
              size: 18,
              color: InventoryDesignConfig.primaryColor,
            ),
          ),
          const SizedBox(width: InventoryDesignConfig.spacingL),
          Expanded(
            child: Text(
              'Select ${widget.inventoryType == 'fabric' ? 'Fabric' : 'Accessory'} Category',
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
        // Search and Add section
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
                    hintText: 'Search categories...',
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
                  onChanged: _filterCategories,
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
                        controller: _newCategoryController,
                        style: InventoryDesignConfig.bodyLarge,
                        decoration: InputDecoration(
                          hintText: 'Add new category...',
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
                      onTap: _isAddingNew ? null : _addNewCategory,
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

        // Categories list
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
                    : _filteredCategories.isEmpty
                    ? _buildEmptyState()
                    : _buildCategoriesList(),
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
              PhosphorIcons.folder(),
              size: 32,
              color: InventoryDesignConfig.textTertiary,
            ),
          ),
          const SizedBox(height: InventoryDesignConfig.spacingL),
          Text('No categories found', style: InventoryDesignConfig.titleMedium),
          const SizedBox(height: InventoryDesignConfig.spacingS),
          Text(
            _searchController.text.isNotEmpty
                ? 'Try a different search or add a new category above'
                : 'Add your first category above to get started',
            style: InventoryDesignConfig.bodyMedium,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildCategoriesList() {
    return ListView.separated(
      padding: EdgeInsets.zero,
      itemCount: _filteredCategories.length,
      separatorBuilder:
          (context, index) =>
              const SizedBox(height: InventoryDesignConfig.spacingXS),
      itemBuilder: (context, index) {
        final category = _filteredCategories[index];
        final isSelected = category['id'].toString() == _selectedCategoryId;

        return Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(InventoryDesignConfig.radiusM),
          child: InkWell(
            borderRadius: BorderRadius.circular(InventoryDesignConfig.radiusM),
            onTap: () {
              setState(() {
                _selectedCategoryId = category['id'].toString();
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
                      PhosphorIcons.folder(),
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
                      category['category_name'],
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
                  _selectedCategoryId != null
                      ? () {
                        final selectedCategory = _filteredCategories.firstWhere(
                          (category) =>
                              category['id'].toString() == _selectedCategoryId,
                        );
                        Navigator.of(context).pop();
                        widget.onCategorySelected(
                          selectedCategory['id'].toString(),
                          selectedCategory['category_name'],
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
                      'Select Category',
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
