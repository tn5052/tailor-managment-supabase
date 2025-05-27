import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

class SearchableAddableDropdownItem {
  final String id;
  final String name;

  SearchableAddableDropdownItem({required this.id, required this.name});
}

class SearchableAddableDropdownFormField
    extends FormField<SearchableAddableDropdownItem> {
  SearchableAddableDropdownFormField({
    super.key,
    required String labelText,
    required String hintText,
    required Future<List<SearchableAddableDropdownItem>> Function(
      String? searchText,
    )
    fetchItems,
    required Future<SearchableAddableDropdownItem?> Function(String itemName)
    onAddItem,
    ValueChanged<SearchableAddableDropdownItem?>? onChanged,
    SearchableAddableDropdownItem? initialValue,
    FormFieldSetter<SearchableAddableDropdownItem>? onSaved,
    FormFieldValidator<SearchableAddableDropdownItem>? validator,
    bool required = false,
    IconData? icon,
  }) : super(
         onSaved: onSaved,
         validator: validator,
         initialValue: initialValue,
         builder: (FormFieldState<SearchableAddableDropdownItem> state) {
           final theme = Theme.of(state.context);
           final colorScheme = theme.colorScheme;

           void _showSelectionDialog() async {
             final selected = await showDialog<SearchableAddableDropdownItem>(
               context: state.context,
               builder:
                   (context) => _SearchableAddableDialog(
                     labelText: labelText,
                     fetchItems: fetchItems,
                     onAddItem: onAddItem,
                     currentSelectedItem: state.value, // Pass current value
                   ),
             );
             if (selected != null) {
               state.didChange(selected);
               if (onChanged != null) {
                 onChanged(selected);
               }
             }
           }

           return Column(
             crossAxisAlignment: CrossAxisAlignment.start,
             mainAxisSize: MainAxisSize.min,
             children: [
               Padding(
                 padding: const EdgeInsets.only(left: 2.0, bottom: 6.0),
                 child: Row(
                   children: [
                     if (icon != null) ...[
                       Icon(
                         icon,
                         size: 15,
                         color: colorScheme.onSurfaceVariant,
                       ),
                       const SizedBox(width: 6),
                     ],
                     Text(
                       labelText,
                       style: theme.textTheme.bodyMedium?.copyWith(
                         fontWeight: FontWeight.w500,
                       ),
                     ),
                     if (required)
                       Text(' *', style: TextStyle(color: colorScheme.error)),
                   ],
                 ),
               ),
               InkWell(
                 onTap: _showSelectionDialog,
                 borderRadius: BorderRadius.circular(8),
                 child: InputDecorator(
                   decoration: InputDecoration(
                     // The hintText in InputDecorator is for the label animation,
                     // The actual placeholder text is handled by the child Text widget.
                     // We can keep this or remove it if the child Text handles it sufficiently.
                     // For consistency with TextFormField, let's ensure the child Text shows the hint.
                     hintText:
                         hintText, // This hintText is for the floating label behavior
                     contentPadding: const EdgeInsets.symmetric(
                       horizontal: 16,
                       vertical: 12,
                     ),
                     border: OutlineInputBorder(
                       borderRadius: BorderRadius.circular(8),
                       borderSide: BorderSide(
                         color: colorScheme.outline.withOpacity(0.5),
                       ),
                     ),
                     enabledBorder: OutlineInputBorder(
                       borderRadius: BorderRadius.circular(8),
                       borderSide: BorderSide(
                         color: colorScheme.outline.withOpacity(0.5),
                       ),
                     ),
                     focusedBorder: OutlineInputBorder(
                       borderRadius: BorderRadius.circular(8),
                       borderSide: BorderSide(
                         color: colorScheme.primary,
                         width: 1.5,
                       ),
                     ),
                     errorText: state.hasError ? state.errorText : null,
                     suffixIcon: Icon(PhosphorIcons.caretDown(), size: 16),
                   ),
                   child: Text(
                     state.value?.name ??
                         hintText, // Display hintText if value is null
                     style:
                         state.value == null
                             ? theme.textTheme.bodyMedium?.copyWith(
                               color: colorScheme.onSurfaceVariant.withOpacity(
                                 0.6,
                               ),
                             )
                             : theme.textTheme.bodyMedium,
                   ),
                 ),
               ),
             ],
           );
         },
       );
}

class _SearchableAddableDialog extends StatefulWidget {
  final String labelText;
  final Future<List<SearchableAddableDropdownItem>> Function(String? searchText)
  fetchItems;
  final Future<SearchableAddableDropdownItem?> Function(String itemName)
  onAddItem;
  final SearchableAddableDropdownItem? currentSelectedItem; // Added

  const _SearchableAddableDialog({
    required this.labelText,
    required this.fetchItems,
    required this.onAddItem,
    this.currentSelectedItem, // Added
  });

  @override
  State<_SearchableAddableDialog> createState() =>
      _SearchableAddableDialogState();
}

class _SearchableAddableDialogState extends State<_SearchableAddableDialog> {
  List<SearchableAddableDropdownItem> _items = [];
  bool _isLoading = true; // Start with loading true
  String _searchText = '';
  final _searchController = TextEditingController();
  final _newItemNameController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadItems();
    _searchController.addListener(() {
      setState(() {
        _searchText = _searchController.text;
      });
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _newItemNameController.dispose();
    super.dispose();
  }

  Future<void> _loadItems({String? query}) async {
    if (!mounted) return;
    setState(() => _isLoading = true);
    try {
      _items = await widget.fetchItems(query ?? _searchText);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading items: ${e.toString()}')),
        );
      }
    }
    if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  void _handleAddNewItem() async {
    String itemTypeName = widget.labelText;
    if (itemTypeName.toLowerCase().startsWith('select ')) {
      itemTypeName = itemTypeName.substring('select '.length);
    }
    // Further refine itemTypeName if needed, e.g., "Accessory Type" -> "Type Name"
    String fieldLabel = '$itemTypeName Name';
    String hintText = 'Enter $itemTypeName name';

    final itemName = await showDialog<String>(
      context: context,
      builder: (context) {
        final theme = Theme.of(context);
        final colorScheme = theme.colorScheme;
        return AlertDialog(
          title: Text('Add New $itemTypeName'),
          content: Column(
            mainAxisSize: MainAxisSize.min, // Important for AlertDialog content
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '$fieldLabel *', // Adding asterisk for required
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _newItemNameController,
                autofocus: true,
                decoration: InputDecoration(
                  hintText: hintText,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(
                      color: colorScheme.outline.withOpacity(0.5),
                    ),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(
                      color: colorScheme.outline.withOpacity(0.5),
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(
                      color: colorScheme.primary,
                      width: 1.5,
                    ),
                  ),
                ),
                // Basic validation can be added here if needed
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return '$fieldLabel is required';
                  }
                  return null;
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                // Simple check, can be integrated with Form validation if a FormKey is used
                if (_newItemNameController.text.trim().isNotEmpty) {
                  Navigator.pop(context, _newItemNameController.text.trim());
                }
              },
              child: const Text('Add'),
            ),
          ],
        );
      },
    );

    _newItemNameController.clear();

    if (itemName != null && itemName.isNotEmpty) {
      setState(() => _isLoading = true);
      final newItem = await widget.onAddItem(itemName);
      setState(() => _isLoading = false);
      if (newItem != null && mounted) {
        Navigator.pop(context, newItem);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final filteredItems =
        _searchText.isEmpty
            ? _items
            : _items
                .where(
                  (item) => item.name.toLowerCase().contains(
                    _searchText.toLowerCase(),
                  ),
                )
                .toList();

    // Determine the title for the "Add New" button
    String itemTypeNameForButton = widget.labelText;
    // Remove "Select " prefix if it exists for a cleaner button label
    if (itemTypeNameForButton.toLowerCase().startsWith('select ')) {
      itemTypeNameForButton = itemTypeNameForButton.substring('select '.length);
    }

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.0)),
      elevation: 4,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 400, maxHeight: 550),
        decoration: BoxDecoration(
          color: colorScheme.surface,
          borderRadius: BorderRadius.circular(16.0),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 8, 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    // Use widget.labelText directly as it's already "Select Type", "Select Brand"
                    widget.labelText,
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  IconButton(
                    icon: Icon(PhosphorIcons.x(), size: 20),
                    onPressed: () => Navigator.of(context).pop(),
                    tooltip: 'Close',
                    splashRadius: 20,
                  ),
                ],
              ),
            ),
            Divider(height: 1, color: colorScheme.outline.withOpacity(0.2)),

            // Search Bar
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Search...',
                  prefixIcon: Icon(PhosphorIcons.magnifyingGlass(), size: 20),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(
                      color: colorScheme.outline.withOpacity(0.5),
                    ),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(
                      color: colorScheme.outline.withOpacity(0.5),
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(
                      color: colorScheme.primary,
                      width: 1.5,
                    ),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                ),
                // onChanged: (value) => _loadItems(query: value), // Optionally reload on change
              ),
            ),

            // List of items
            Expanded(
              child:
                  _isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : filteredItems.isEmpty
                      ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Text(
                            _searchText.isNotEmpty
                                ? 'No items found for "$_searchText".'
                                : 'No items available.',
                            textAlign: TextAlign.center,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ),
                      )
                      : ListView.separated(
                        shrinkWrap: true,
                        itemCount: filteredItems.length,
                        separatorBuilder:
                            (context, index) => Divider(
                              height: 1,
                              indent: 16,
                              endIndent: 16,
                              color: colorScheme.outline.withOpacity(0.1),
                            ),
                        itemBuilder: (context, index) {
                          final item = filteredItems[index];
                          final isSelected =
                              item.id == widget.currentSelectedItem?.id;
                          return Material(
                            color: Colors.transparent,
                            child: InkWell(
                              onTap: () => Navigator.pop(context, item),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 20,
                                  vertical: 14,
                                ),
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Expanded(
                                      child: Text(
                                        item.name,
                                        style: theme.textTheme.bodyLarge
                                            ?.copyWith(
                                              fontWeight:
                                                  isSelected
                                                      ? FontWeight.w600
                                                      : FontWeight.normal,
                                              color:
                                                  isSelected
                                                      ? colorScheme.primary
                                                      : colorScheme.onSurface,
                                            ),
                                      ),
                                    ),
                                    if (isSelected)
                                      PhosphorIcon(
                                        PhosphorIcons.checkCircle(
                                          PhosphorIconsStyle.fill,
                                        ),
                                        color: colorScheme.primary,
                                        size: 22,
                                      ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      ),
            ),

            // Add New Button
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: FilledButton.icon(
                icon: Icon(PhosphorIcons.plus(), size: 18),
                label: Text('Add New $itemTypeNameForButton'),
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  textStyle: theme.textTheme.labelLarge,
                ),
                onPressed: _handleAddNewItem,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
