import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../../../theme/inventory_design_config.dart';

class FabricColorResult {
  final Color color;
  final String colorName;
  final String hexCode;

  FabricColorResult({
    required this.color,
    required this.colorName,
    required this.hexCode,
  });
}

class FabricColorPicker extends StatefulWidget {
  final Color? initialColor;
  final String? initialColorName;
  final Function(FabricColorResult) onColorSelected;

  const FabricColorPicker({
    super.key,
    this.initialColor,
    this.initialColorName,
    required this.onColorSelected,
  });

  static Future<FabricColorResult?> show(
    BuildContext context, {
    Color? initialColor,
    String? initialColorName,
  }) async {
    return showDialog<FabricColorResult>(
      context: context,
      builder:
          (context) => Dialog(
            backgroundColor: Colors.transparent,
            insetPadding: const EdgeInsets.symmetric(horizontal: 16),
            child: FabricColorPicker(
              initialColor: initialColor,
              initialColorName: initialColorName,
              onColorSelected: (result) => Navigator.of(context).pop(result),
            ),
          ),
    );
  }

  @override
  State<FabricColorPicker> createState() => _FabricColorPickerState();
}

class _FabricColorPickerState extends State<FabricColorPicker>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  Color _selectedColor = const Color(0xFFFFFFFF); // Default white
  String _colorName = 'White';
  String _hexCode = '#FFFFFF';
  final _colorNameController = TextEditingController();
  final _hexController = TextEditingController();

  // Kandora-specific fabric colors based on research
  // These are traditional and popular colors used in UAE for kandoras
  final Map<String, List<KandoraColor>> _kandoraColorCategories = {
    'Traditional': [
      KandoraColor('Pure White', 0xFFFFFFFF, 'Most popular traditional color'),
      KandoraColor('Off-White', 0xFFF5F5F0, 'Subtle cream-white shade'),
      KandoraColor('Winter White', 0xFFF8F9F8, 'Slightly cooler white tone'),
      KandoraColor('Ivory', 0xFFFFFFF0, 'Warm creamy white'),
      KandoraColor('Pearl White', 0xFFF5F5EB, 'Gentle lustre white'),
    ],
    'Classic Colors': [
      KandoraColor('Light Beige', 0xFFF5F5DC, 'Natural light beige'),
      KandoraColor(
        'Ecru',
        0xFFCDC5BF,
        'Grayish-pale yellow like unbleached linen',
      ),
      KandoraColor('Sand Beige', 0xFFE0CCAB, 'Desert sand color'),
      KandoraColor('Pale Khaki', 0xFFBDB76B, 'Light dusty brown'),
      KandoraColor('Soft Gray', 0xFFD3D3D3, 'Neutral light gray'),
      KandoraColor('Ash Gray', 0xFFB2BEB5, 'Medium light gray'),
    ],
    'Winter Colors': [
      KandoraColor('Navy Blue', 0xFF000080, 'Deep conservative blue'),
      KandoraColor(
        'Charcoal Gray',
        0xFF36454F,
        'Deep gray with blue undertone',
      ),
      KandoraColor('Dark Brown', 0xFF654321, 'Rich earthy brown'),
      KandoraColor('Burgundy', 0xFF800020, 'Deep red wine color'),
      KandoraColor('Forest Green', 0xFF228B22, 'Deep natural green'),
      KandoraColor('Coffee', 0xFF6F4E37, 'Dark brown with reddish tones'),
    ],
    'Summer Colors': [
      KandoraColor('Sky Blue', 0xFF87CEEB, 'Light refreshing blue'),
      KandoraColor('Mint Green', 0xFF98FB98, 'Light cool green'),
      KandoraColor('Lavender', 0xFFE6E6FA, 'Light purple'),
      KandoraColor('Salmon', 0xFFFA8072, 'Light pinkish-orange'),
      KandoraColor('Light Yellow', 0xFFFFFFE0, 'Soft pale yellow'),
      KandoraColor('Peach', 0xFFFFE5B4, 'Soft orange-pink'),
    ],
    'Royal & Premium': [
      KandoraColor('Royal Blue', 0xFF4169E1, 'Bright rich blue'),
      KandoraColor('Gold', 0xFFFFD700, 'Metallic yellow'),
      KandoraColor('Silver Gray', 0xFFC0C0C0, 'Metallic gray'),
      KandoraColor('Emerald Green', 0xFF50C878, 'Bright green like emerald'),
      KandoraColor('Deep Purple', 0xFF301934, 'Rich royal purple'),
      KandoraColor('Maroon', 0xFF800000, 'Deep red'),
    ],
  };

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);

    if (widget.initialColor != null) {
      _selectedColor = widget.initialColor!;
      _hexCode =
          '#${_selectedColor.value.toRadixString(16).substring(2).toUpperCase()}';
      _hexController.text = _hexCode.substring(1); // Without #
    }

    if (widget.initialColorName != null &&
        widget.initialColorName!.isNotEmpty) {
      _colorName = widget.initialColorName!;
      _colorNameController.text = _colorName;
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    _colorNameController.dispose();
    _hexController.dispose();
    super.dispose();
  }

  void _updateFromHex(String hex) {
    if (hex.isEmpty) return;

    try {
      hex = hex.replaceAll('#', '').toUpperCase();
      if (hex.length == 6) {
        final color = Color(int.parse('FF$hex', radix: 16));
        setState(() {
          _selectedColor = color;
          _hexCode = '#$hex';
        });
      }
    } catch (e) {
      // Invalid hex
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: MediaQuery.of(context).size.width > 600 ? 500 : double.infinity,
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.85,
        maxWidth: 500,
      ),
      decoration: BoxDecoration(
        color: InventoryDesignConfig.surfaceColor,
        borderRadius: BorderRadius.circular(InventoryDesignConfig.radiusXL),
        border: Border.all(color: InventoryDesignConfig.borderPrimary),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header with app theme styling
          Container(
            padding: const EdgeInsets.all(InventoryDesignConfig.spacingXXL),
            decoration: BoxDecoration(
              color: InventoryDesignConfig.surfaceAccent,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(InventoryDesignConfig.radiusXL),
              ),
              border: Border(
                bottom: BorderSide(
                  color: InventoryDesignConfig.borderSecondary,
                ),
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
                    PhosphorIcons.palette(),
                    color: InventoryDesignConfig.primaryColor,
                    size: 20,
                  ),
                ),
                const SizedBox(width: InventoryDesignConfig.spacingM),
                Expanded(
                  child: Text(
                    'Fabric Color Picker',
                    style: InventoryDesignConfig.headlineMedium,
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
                      padding: const EdgeInsets.all(
                        InventoryDesignConfig.spacingS,
                      ),
                      child: Icon(
                        PhosphorIcons.x(),
                        color: InventoryDesignConfig.textSecondary,
                        size: 20,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Color Preview with enhanced styling
          Container(
            margin: const EdgeInsets.all(InventoryDesignConfig.spacingXXL),
            height: 90,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(
                InventoryDesignConfig.radiusL,
              ),
              border: Border.all(color: InventoryDesignConfig.borderPrimary),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              children: [
                // Color block with better styling
                Container(
                  width: 120,
                  decoration: BoxDecoration(
                    color: _selectedColor,
                    borderRadius: const BorderRadius.horizontal(
                      left: Radius.circular(InventoryDesignConfig.radiusL),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: _selectedColor.withOpacity(0.3),
                        blurRadius: 8,
                        offset: const Offset(2, 0),
                      ),
                    ],
                  ),
                  child: Center(
                    child: Icon(
                      PhosphorIcons.eyedropper(),
                      size: 32,
                      color: Colors.white.withOpacity(0.9),
                    ),
                  ),
                ),
                // Info section with better typography
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(
                      InventoryDesignConfig.spacingL,
                    ),
                    decoration: BoxDecoration(
                      color: InventoryDesignConfig.surfaceColor,
                      borderRadius: const BorderRadius.horizontal(
                        right: Radius.circular(InventoryDesignConfig.radiusL),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          _colorName,
                          style: InventoryDesignConfig.titleMedium,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: InventoryDesignConfig.spacingS),
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: InventoryDesignConfig.spacingS,
                                vertical: InventoryDesignConfig.spacingXS,
                              ),
                              decoration: BoxDecoration(
                                color: InventoryDesignConfig.primaryColor
                                    .withOpacity(0.08),
                                borderRadius: BorderRadius.circular(
                                  InventoryDesignConfig.radiusS,
                                ),
                              ),
                              child: Text(
                                _hexCode,
                                style: InventoryDesignConfig.code.copyWith(
                                  color: InventoryDesignConfig.primaryColor,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            const SizedBox(
                              width: InventoryDesignConfig.spacingS,
                            ),
                            Material(
                              color: Colors.transparent,
                              borderRadius: BorderRadius.circular(
                                InventoryDesignConfig.radiusS,
                              ),
                              child: InkWell(
                                onTap: () {
                                  Clipboard.setData(
                                    ClipboardData(text: _hexCode),
                                  );
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: const Text(
                                        'Color code copied to clipboard',
                                      ),
                                      backgroundColor:
                                          InventoryDesignConfig.successColor,
                                      behavior: SnackBarBehavior.floating,
                                    ),
                                  );
                                },
                                borderRadius: BorderRadius.circular(
                                  InventoryDesignConfig.radiusS,
                                ),
                                child: Container(
                                  padding: const EdgeInsets.all(
                                    InventoryDesignConfig.spacingXS,
                                  ),
                                  decoration: BoxDecoration(
                                    color: InventoryDesignConfig.surfaceAccent,
                                    borderRadius: BorderRadius.circular(
                                      InventoryDesignConfig.radiusS,
                                    ),
                                  ),
                                  child: Icon(
                                    PhosphorIcons.copy(),
                                    size: 16,
                                    color: InventoryDesignConfig.textSecondary,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Tabs with app theme styling
          Container(
            margin: const EdgeInsets.symmetric(
              horizontal: InventoryDesignConfig.spacingXXL,
            ),
            padding: const EdgeInsets.all(InventoryDesignConfig.spacingXS),
            decoration: BoxDecoration(
              color: InventoryDesignConfig.surfaceAccent,
              borderRadius: BorderRadius.circular(
                InventoryDesignConfig.radiusL,
              ),
            ),
            child: TabBar(
              controller: _tabController,
              labelColor: InventoryDesignConfig.primaryColor,
              unselectedLabelColor: InventoryDesignConfig.textSecondary,
              labelStyle: InventoryDesignConfig.bodyMedium.copyWith(
                fontWeight: FontWeight.w600,
              ),
              unselectedLabelStyle: InventoryDesignConfig.bodyMedium,
              indicator: BoxDecoration(
                color: InventoryDesignConfig.primaryColor.withOpacity(0.08),
                borderRadius: BorderRadius.circular(
                  InventoryDesignConfig.radiusM,
                ),
              ),
              indicatorSize: TabBarIndicatorSize.tab,
              dividerColor: Colors.transparent,
              tabs: const [
                Tab(text: 'Fabric Colors'),
                Tab(text: 'Custom'),
                Tab(text: 'Manual'),
              ],
            ),
          ),

          // Tab content
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildFabricColorsTab(),
                _buildCustomColorTab(),
                _buildManualInputTab(),
              ],
            ),
          ),

          // Action buttons with consistent app theme styling
          Container(
            padding: const EdgeInsets.all(InventoryDesignConfig.spacingXXL),
            decoration: BoxDecoration(
              color: InventoryDesignConfig.surfaceAccent,
              borderRadius: const BorderRadius.vertical(
                bottom: Radius.circular(InventoryDesignConfig.radiusXL),
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
                  borderRadius: BorderRadius.circular(
                    InventoryDesignConfig.radiusM,
                  ),
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
                      decoration:
                          InventoryDesignConfig.buttonSecondaryDecoration,
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
                  borderRadius: BorderRadius.circular(
                    InventoryDesignConfig.radiusM,
                  ),
                  child: InkWell(
                    onTap: () {
                      widget.onColorSelected(
                        FabricColorResult(
                          color: _selectedColor,
                          colorName: _colorName,
                          hexCode: _hexCode,
                        ),
                      );
                    },
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
                          Icon(
                            PhosphorIcons.check(),
                            size: 16,
                            color: Colors.white,
                          ),
                          const SizedBox(width: InventoryDesignConfig.spacingS),
                          Text(
                            'Select Color',
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
          ),
        ],
      ),
    );
  }

  Widget _buildFabricColorsTab() {
    return Container(
      padding: const EdgeInsets.all(InventoryDesignConfig.spacingL),
      child: ListView(
        children:
            _kandoraColorCategories.entries.map((entry) {
              return Container(
                margin: const EdgeInsets.only(
                  bottom: InventoryDesignConfig.spacingL,
                ),
                decoration: BoxDecoration(
                  color: InventoryDesignConfig.surfaceAccent,
                  borderRadius: BorderRadius.circular(
                    InventoryDesignConfig.radiusL,
                  ),
                  border: Border.all(
                    color: InventoryDesignConfig.borderSecondary,
                  ),
                ),
                child: Theme(
                  data: Theme.of(context).copyWith(
                    dividerColor: Colors.transparent,
                    expansionTileTheme: ExpansionTileThemeData(
                      backgroundColor: Colors.transparent,
                      collapsedBackgroundColor: Colors.transparent,
                      iconColor: InventoryDesignConfig.primaryColor,
                      collapsedIconColor: InventoryDesignConfig.textSecondary,
                      textColor: InventoryDesignConfig.textPrimary,
                      collapsedTextColor: InventoryDesignConfig.textPrimary,
                    ),
                  ),
                  child: ExpansionTile(
                    tilePadding: const EdgeInsets.symmetric(
                      horizontal: InventoryDesignConfig.spacingL,
                      vertical: InventoryDesignConfig.spacingS,
                    ),
                    childrenPadding: const EdgeInsets.only(
                      left: InventoryDesignConfig.spacingL,
                      right: InventoryDesignConfig.spacingL,
                      bottom: InventoryDesignConfig.spacingL,
                    ),
                    leading: Container(
                      padding: const EdgeInsets.all(
                        InventoryDesignConfig.spacingS,
                      ),
                      decoration: BoxDecoration(
                        color: InventoryDesignConfig.primaryColor.withOpacity(
                          0.1,
                        ),
                        borderRadius: BorderRadius.circular(
                          InventoryDesignConfig.radiusS,
                        ),
                      ),
                      child: Icon(
                        PhosphorIcons.palette(),
                        size: 16,
                        color: InventoryDesignConfig.primaryColor,
                      ),
                    ),
                    title: Text(
                      entry.key,
                      style: InventoryDesignConfig.titleMedium.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    subtitle: Text(
                      '${entry.value.length} colors available',
                      style: InventoryDesignConfig.bodySmall,
                    ),
                    children: [
                      GridView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 3,
                              crossAxisSpacing: InventoryDesignConfig.spacingM,
                              mainAxisSpacing: InventoryDesignConfig.spacingM,
                              childAspectRatio: 1.0,
                            ),
                        itemCount: entry.value.length,
                        itemBuilder: (context, index) {
                          final color = entry.value[index];
                          final materialColor = Color(color.colorValue);
                          final isSelected =
                              materialColor.value == _selectedColor.value;

                          return Material(
                            color: Colors.transparent,
                            borderRadius: BorderRadius.circular(
                              InventoryDesignConfig.radiusM,
                            ),
                            child: InkWell(
                              onTap: () {
                                setState(() {
                                  _selectedColor = materialColor;
                                  _colorName = color.name;
                                  _hexCode =
                                      '#${materialColor.value.toRadixString(16).substring(2).toUpperCase()}';
                                  _colorNameController.text = _colorName;
                                  _hexController.text = _hexCode.substring(1);
                                });
                              },
                              borderRadius: BorderRadius.circular(
                                InventoryDesignConfig.radiusM,
                              ),
                              child: Container(
                                decoration: BoxDecoration(
                                  color: materialColor,
                                  borderRadius: BorderRadius.circular(
                                    InventoryDesignConfig.radiusM,
                                  ),
                                  border: Border.all(
                                    color:
                                        isSelected
                                            ? InventoryDesignConfig.primaryColor
                                            : InventoryDesignConfig
                                                .borderPrimary,
                                    width: isSelected ? 2.5 : 1,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: materialColor.withOpacity(0.3),
                                      blurRadius: isSelected ? 8 : 4,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: Stack(
                                  children: [
                                    // Color swatch with icon
                                    Center(
                                      child: Icon(
                                        PhosphorIcons.eyedropper(),
                                        size: 20,
                                        color: Colors.white.withOpacity(0.8),
                                      ),
                                    ),

                                    // Selected indicator
                                    if (isSelected)
                                      Positioned(
                                        top: InventoryDesignConfig.spacingS,
                                        right: InventoryDesignConfig.spacingS,
                                        child: Container(
                                          padding: const EdgeInsets.all(
                                            InventoryDesignConfig.spacingXS,
                                          ),
                                          decoration: BoxDecoration(
                                            color:
                                                InventoryDesignConfig
                                                    .primaryColor,
                                            shape: BoxShape.circle,
                                            boxShadow: [
                                              BoxShadow(
                                                color: Colors.black.withOpacity(
                                                  0.2,
                                                ),
                                                blurRadius: 4,
                                                offset: const Offset(0, 2),
                                              ),
                                            ],
                                          ),
                                          child: Icon(
                                            PhosphorIcons.check(),
                                            size: 12,
                                            color: Colors.white,
                                          ),
                                        ),
                                      ),

                                    // Color name at bottom
                                    Positioned(
                                      bottom: 0,
                                      left: 0,
                                      right: 0,
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal:
                                              InventoryDesignConfig.spacingXS,
                                          vertical:
                                              InventoryDesignConfig.spacingXS,
                                        ),
                                        decoration: BoxDecoration(
                                          color: Colors.black.withOpacity(0.7),
                                          borderRadius:
                                              const BorderRadius.vertical(
                                                bottom: Radius.circular(
                                                  InventoryDesignConfig.radiusM,
                                                ),
                                              ),
                                        ),
                                        child: Text(
                                          color.name,
                                          textAlign: TextAlign.center,
                                          style: InventoryDesignConfig.bodySmall
                                              .copyWith(
                                                color: Colors.white,
                                                fontSize: 10,
                                                fontWeight: FontWeight.w600,
                                              ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
      ),
    );
  }

  Widget _buildCustomColorTab() {
    return Container(
      padding: const EdgeInsets.all(InventoryDesignConfig.spacingXXL),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(InventoryDesignConfig.spacingXXL),
              decoration: BoxDecoration(
                color: InventoryDesignConfig.surfaceAccent,
                borderRadius: BorderRadius.circular(
                  InventoryDesignConfig.radiusL,
                ),
                border: Border.all(
                  color: InventoryDesignConfig.borderSecondary,
                ),
              ),
              child: Column(
                children: [
                  Icon(
                    PhosphorIcons.palette(),
                    size: 48,
                    color: InventoryDesignConfig.textTertiary,
                  ),
                  const SizedBox(height: InventoryDesignConfig.spacingL),
                  Text(
                    'Custom Color Picker',
                    style: InventoryDesignConfig.titleLarge,
                  ),
                  const SizedBox(height: InventoryDesignConfig.spacingS),
                  Text(
                    'Advanced color picker coming soon',
                    style: InventoryDesignConfig.bodyMedium,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: InventoryDesignConfig.spacingXS),
                  Text(
                    'Please use the Fabric Colors or Manual tab for now',
                    style: InventoryDesignConfig.bodySmall,
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildManualInputTab() {
    return Container(
      padding: const EdgeInsets.all(InventoryDesignConfig.spacingXXL),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Color Name Input
          Text('Color Name', style: InventoryDesignConfig.labelLarge),
          const SizedBox(height: InventoryDesignConfig.spacingS),
          Container(
            decoration: InventoryDesignConfig.inputDecoration,
            child: TextField(
              controller: _colorNameController,
              style: InventoryDesignConfig.bodyLarge,
              decoration: InputDecoration(
                hintText: 'Enter color name (e.g., Pure White)',
                hintStyle: InventoryDesignConfig.bodyMedium,
                prefixIcon: Padding(
                  padding: const EdgeInsets.all(InventoryDesignConfig.spacingM),
                  child: Icon(
                    PhosphorIcons.textT(),
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
              onChanged: (value) {
                setState(() {
                  _colorName = value.isNotEmpty ? value : 'Custom Color';
                });
              },
            ),
          ),

          const SizedBox(height: InventoryDesignConfig.spacingXXL),

          // Hex Color Input
          Text('Color Code (Hex)', style: InventoryDesignConfig.labelLarge),
          const SizedBox(height: InventoryDesignConfig.spacingS),
          Container(
            decoration: InventoryDesignConfig.inputDecoration,
            child: TextField(
              controller: _hexController,
              style: InventoryDesignConfig.bodyLarge,
              decoration: InputDecoration(
                hintText: 'Enter hex code (e.g., FFFFFF)',
                hintStyle: InventoryDesignConfig.bodyMedium,
                prefixIcon: Padding(
                  padding: const EdgeInsets.all(InventoryDesignConfig.spacingM),
                  child: Text(
                    '#',
                    style: InventoryDesignConfig.titleMedium.copyWith(
                      color: InventoryDesignConfig.textSecondary,
                    ),
                  ),
                ),
                suffixIcon: Padding(
                  padding: const EdgeInsets.all(InventoryDesignConfig.spacingM),
                  child: Icon(
                    PhosphorIcons.hash(),
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
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'[0-9a-fA-F]')),
                LengthLimitingTextInputFormatter(6),
              ],
              onChanged: _updateFromHex,
            ),
          ),

          const SizedBox(height: InventoryDesignConfig.spacingXXL),

          // Quick color swatches
          Text('Quick Colors', style: InventoryDesignConfig.labelLarge),
          const SizedBox(height: InventoryDesignConfig.spacingM),
          Wrap(
            spacing: InventoryDesignConfig.spacingM,
            runSpacing: InventoryDesignConfig.spacingM,
            children:
                [
                  Colors.white,
                  Colors.black,
                  Colors.red,
                  Colors.blue,
                  Colors.green,
                  Colors.yellow,
                  Colors.purple,
                  Colors.orange,
                  Colors.pink,
                  Colors.brown,
                  Colors.grey,
                  Colors.teal,
                ].map((color) {
                  final isSelected = color.value == _selectedColor.value;
                  return Material(
                    color: Colors.transparent,
                    borderRadius: BorderRadius.circular(
                      InventoryDesignConfig.radiusS,
                    ),
                    child: InkWell(
                      onTap: () {
                        setState(() {
                          _selectedColor = color;
                          _hexCode =
                              '#${color.value.toRadixString(16).substring(2).toUpperCase()}';
                          _hexController.text = _hexCode.substring(1);
                          if (_colorNameController.text.isEmpty) {
                            _colorName = _getColorName(color);
                            _colorNameController.text = _colorName;
                          }
                        });
                      },
                      borderRadius: BorderRadius.circular(
                        InventoryDesignConfig.radiusS,
                      ),
                      child: Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: color,
                          borderRadius: BorderRadius.circular(
                            InventoryDesignConfig.radiusS,
                          ),
                          border: Border.all(
                            color:
                                isSelected
                                    ? InventoryDesignConfig.primaryColor
                                    : InventoryDesignConfig.borderPrimary,
                            width: isSelected ? 2 : 1,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 2,
                              offset: const Offset(0, 1),
                            ),
                          ],
                        ),
                        child:
                            isSelected
                                ? Icon(
                                  PhosphorIcons.check(),
                                  size: 16,
                                  color:
                                      color == Colors.white ||
                                              color == Colors.yellow
                                          ? Colors.black
                                          : Colors.white,
                                )
                                : null,
                      ),
                    ),
                  );
                }).toList(),
          ),

          const SizedBox(height: InventoryDesignConfig.spacingXXL),

          // Info card about kandora colors
          Container(
            padding: const EdgeInsets.all(InventoryDesignConfig.spacingL),
            decoration: BoxDecoration(
              color: InventoryDesignConfig.primaryColor.withOpacity(0.05),
              borderRadius: BorderRadius.circular(
                InventoryDesignConfig.radiusL,
              ),
              border: Border.all(
                color: InventoryDesignConfig.primaryColor.withOpacity(0.15),
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(InventoryDesignConfig.spacingS),
                  decoration: BoxDecoration(
                    color: InventoryDesignConfig.primaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(
                      InventoryDesignConfig.radiusS,
                    ),
                  ),
                  child: Icon(
                    PhosphorIcons.info(),
                    size: 16,
                    color: InventoryDesignConfig.primaryColor,
                  ),
                ),
                const SizedBox(width: InventoryDesignConfig.spacingM),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Traditional Kandora Colors',
                        style: InventoryDesignConfig.titleMedium.copyWith(
                          color: InventoryDesignConfig.primaryColor,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: InventoryDesignConfig.spacingXS),
                      Text(
                        'White is the most popular color for everyday wear in UAE. Darker colors like navy blue and charcoal are preferred in winter, while lighter pastels are chosen for special occasions and summer wear.',
                        style: InventoryDesignConfig.bodySmall.copyWith(
                          color: InventoryDesignConfig.primaryColor.withOpacity(
                            0.8,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _getColorName(Color color) {
    if (color == Colors.white) return 'White';
    if (color == Colors.black) return 'Black';
    if (color == Colors.red) return 'Red';
    if (color == Colors.blue) return 'Blue';
    if (color == Colors.green) return 'Green';
    if (color == Colors.yellow) return 'Yellow';
    if (color == Colors.purple) return 'Purple';
    if (color == Colors.orange) return 'Orange';
    if (color == Colors.pink) return 'Pink';
    if (color == Colors.brown) return 'Brown';
    if (color == Colors.grey) return 'Grey';
    if (color == Colors.teal) return 'Teal';
    return 'Custom Color';
  }
}

class KandoraColor {
  final String name;
  final int colorValue;
  final String description;

  KandoraColor(this.name, this.colorValue, this.description);
}
