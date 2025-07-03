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

  String _colorSearchQuery = '';

  // Kandora-specific fabric colors based on research
  // These are traditional and popular colors used in UAE for kandoras
  final Map<String, List<KandoraColor>> _kandoraColorCategories = {
    'Classic': [
      KandoraColor('White', 0xFFFFFFFF, 'Classic white for everyday wear'),
      KandoraColor('Black', 0xFF222222, 'Traditional black'),
      KandoraColor('Navy Blue', 0xFF1A237E, 'Deep navy blue'),
      KandoraColor('Royal Blue', 0xFF1976D2, 'Rich royal blue'),
      KandoraColor('Sky Blue', 0xFF81D4FA, 'Light sky blue'),
      KandoraColor('Golden', 0xFFFFD700, 'Golden yellow'),
      KandoraColor('Beige', 0xFFF5F5DC, 'Classic beige'),
      KandoraColor('Cream', 0xFFFFFDD0, 'Soft cream'),
      KandoraColor('Grey', 0xFFB0B0B0, 'Standard grey'),
      KandoraColor('Charcoal', 0xFF444444, 'Charcoal grey'),
      KandoraColor('Brown', 0xFF795548, 'Classic brown'),
      KandoraColor('Olive', 0xFF808000, 'Olive green'),
      KandoraColor('Maroon', 0xFF800000, 'Deep maroon'),
      KandoraColor('Silver', 0xFFC0C0C0, 'Metallic silver'),
      KandoraColor('Ivory', 0xFFFFFFF0, 'Ivory white'),
      KandoraColor('Sand', 0xFFF4E2D8, 'Sand color'),
      KandoraColor('Stone', 0xFFDDD6CE, 'Stone color'),
      KandoraColor('Khaki', 0xFFF0E68C, 'Khaki'),
      KandoraColor('Taupe', 0xFF483C32, 'Taupe'),
      KandoraColor('Camel', 0xFFC19A6B, 'Camel brown'),
      KandoraColor('Coffee', 0xFF6F4E37, 'Coffee brown'),
      KandoraColor('Ash', 0xFFD6D6D6, 'Ash grey'),
      KandoraColor('Steel Blue', 0xFF4682B4, 'Steel blue'),
      KandoraColor('Light Grey', 0xFFE0E0E0, 'Light grey'),
      KandoraColor('Dark Grey', 0xFF616161, 'Dark grey'),
    ],
    'Modern': [
      KandoraColor('Midnight Blue', 0xFF191970, 'Modern midnight blue'),
      KandoraColor('Cobalt', 0xFF0047AB, 'Cobalt blue'),
      KandoraColor('Turquoise', 0xFF40E0D0, 'Turquoise'),
      KandoraColor('Teal', 0xFF008080, 'Teal'),
      KandoraColor('Aqua', 0xFF00FFFF, 'Aqua'),
      KandoraColor('Mint', 0xFF98FF98, 'Mint green'),
      KandoraColor('Emerald', 0xFF50C878, 'Emerald green'),
      KandoraColor('Forest Green', 0xFF228B22, 'Forest green'),
      KandoraColor('Olive Drab', 0xFF6B8E23, 'Olive drab'),
      KandoraColor('Mustard', 0xFFFFDB58, 'Mustard yellow'),
      KandoraColor('Sunflower', 0xFFFFD300, 'Sunflower yellow'),
      KandoraColor('Orange', 0xFFFF9800, 'Bright orange'),
      KandoraColor('Coral', 0xFFFF7F50, 'Coral'),
      KandoraColor('Peach', 0xFFFFE5B4, 'Peach'),
      KandoraColor('Blush', 0xFFFFC0CB, 'Blush pink'),
      KandoraColor('Rose', 0xFFFF007F, 'Rose pink'),
      KandoraColor('Burgundy', 0xFF800020, 'Burgundy'),
      KandoraColor('Plum', 0xFF8E4585, 'Plum'),
      KandoraColor('Purple', 0xFF800080, 'Classic purple'),
      KandoraColor('Violet', 0xFF8F00FF, 'Violet'),
      KandoraColor('Lavender', 0xFFE6E6FA, 'Lavender'),
      KandoraColor('Lilac', 0xFFC8A2C8, 'Lilac'),
      KandoraColor('Mauve', 0xFFE0B0FF, 'Mauve'),
      KandoraColor('Denim', 0xFF1560BD, 'Denim blue'),
      KandoraColor('Slate', 0xFF708090, 'Slate grey'),
      KandoraColor('Graphite', 0xFF383838, 'Graphite'),
      KandoraColor('Pearl', 0xFFEAE0C8, 'Pearl'),
      KandoraColor('Champagne', 0xFFF7E7CE, 'Champagne'),
      KandoraColor('Copper', 0xFFB87333, 'Copper'),
      KandoraColor('Bronze', 0xFFCD7F32, 'Bronze'),
      KandoraColor('Ruby', 0xFFE0115F, 'Ruby red'),
      KandoraColor('Sapphire', 0xFF0F52BA, 'Sapphire blue'),
      KandoraColor('Emerald Green', 0xFF046307, 'Emerald green'),
      KandoraColor('Mint Green', 0xFFAAF0D1, 'Mint green'),
      KandoraColor('Seafoam', 0xFF93E9BE, 'Seafoam green'),
      KandoraColor('Ice Blue', 0xFFB3FFFF, 'Ice blue'),
      KandoraColor('Powder Blue', 0xFFB0E0E6, 'Powder blue'),
      KandoraColor('Baby Blue', 0xFF89CFF0, 'Baby blue'),
      KandoraColor('Azure', 0xFF007FFF, 'Azure blue'),
      KandoraColor('Indigo', 0xFF4B0082, 'Indigo'),
      KandoraColor('Magenta', 0xFFFF00FF, 'Magenta'),
      KandoraColor('Pink', 0xFFFF69B4, 'Pink'),
      KandoraColor('Red', 0xFFFF0000, 'Red'),
      KandoraColor('Crimson', 0xFFDC143C, 'Crimson'),
      KandoraColor('Sunset', 0xFFFFCC99, 'Sunset orange'),
      KandoraColor('Sandstone', 0xFF786D5F, 'Sandstone'),
      KandoraColor('Mocha', 0xFF967969, 'Mocha brown'),
      KandoraColor('Espresso', 0xFF4B3832, 'Espresso brown'),
      KandoraColor('Charcoal Grey', 0xFF36454F, 'Charcoal grey'),
      KandoraColor('Jet Black', 0xFF343434, 'Jet black'),
      KandoraColor('Snow', 0xFFFFFAFA, 'Snow white'),
      KandoraColor('Off White', 0xFFFAF9F6, 'Off white'),
      KandoraColor('Eggshell', 0xFFF0EAD6, 'Eggshell'),
      KandoraColor('Linen', 0xFFFAF0E6, 'Linen'),
      KandoraColor('Mint Cream', 0xFFF5FFFA, 'Mint cream'),
      KandoraColor('Honey', 0xFFFFC30B, 'Honey yellow'),
      KandoraColor('Lemon', 0xFFFFF700, 'Lemon yellow'),
      KandoraColor('Amber', 0xFFFFBF00, 'Amber'),
      KandoraColor('Apricot', 0xFFFFB16D, 'Apricot'),
      KandoraColor('Copper Rose', 0xFF996666, 'Copper rose'),
      KandoraColor('Rose Gold', 0xFFB76E79, 'Rose gold'),
      KandoraColor('Pearl White', 0xFFF8F6F0, 'Pearl white'),
      KandoraColor('Ivory White', 0xFFFFF8E7, 'Ivory white'),
      KandoraColor('Cloud', 0xFFE5E5E5, 'Cloud grey'),
      KandoraColor('Shadow', 0xFF8A8A8A, 'Shadow grey'),
      KandoraColor('Slate Blue', 0xFF6A5ACD, 'Slate blue'),
      KandoraColor('Royal Purple', 0xFF7851A9, 'Royal purple'),
      KandoraColor('Deep Green', 0xFF013220, 'Deep green'),
      KandoraColor('Deep Blue', 0xFF001F54, 'Deep blue'),
      KandoraColor('Deep Red', 0xFF850101, 'Deep red'),
      KandoraColor('Deep Brown', 0xFF381819, 'Deep brown'),
      KandoraColor('Deep Grey', 0xFF232B2B, 'Deep grey'),
      KandoraColor('Deep Gold', 0xFFB8860B, 'Deep gold'),
      KandoraColor('Deep Silver', 0xFF757575, 'Deep silver'),
      KandoraColor('Deep Bronze', 0xFF8C7853, 'Deep bronze'),
      KandoraColor('Deep Copper', 0xFF7C482B, 'Deep copper'),
      KandoraColor('Deep Orange', 0xFFFF8C00, 'Deep orange'),
      KandoraColor('Deep Yellow', 0xFFFFD700, 'Deep yellow'),
      KandoraColor('Deep Pink', 0xFFFF1493, 'Deep pink'),
      KandoraColor('Deep Violet', 0xFF9400D3, 'Deep violet'),
      KandoraColor('Deep Indigo', 0xFF2E0854, 'Deep indigo'),
      KandoraColor('Deep Blue Grey', 0xFF37474F, 'Deep blue grey'),
      KandoraColor('Deep Teal', 0xFF004D40, 'Deep teal'),
      KandoraColor('Deep Aqua', 0xFF008B8B, 'Deep aqua'),
      KandoraColor('Deep Mint', 0xFF3EB489, 'Deep mint'),
      KandoraColor('Deep Pearl', 0xFFEAE0C8, 'Deep pearl'),
      KandoraColor('Deep Champagne', 0xFFF7E7CE, 'Deep champagne'),
      KandoraColor('Deep Rose', 0xFFC72C48, 'Deep rose'),
      KandoraColor('Deep Ruby', 0xFF9B111E, 'Deep ruby'),
      KandoraColor('Deep Sapphire', 0xFF082567, 'Deep sapphire'),
      KandoraColor('Deep Emerald', 0xFF046307, 'Deep emerald'),
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
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
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
                    padding: const EdgeInsets.all(
                      InventoryDesignConfig.spacingM,
                    ),
                    decoration: BoxDecoration(
                      color: InventoryDesignConfig.primaryColor.withOpacity(
                        0.1,
                      ),
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
                          const SizedBox(
                            height: InventoryDesignConfig.spacingS,
                          ),
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
                                      color:
                                          InventoryDesignConfig.surfaceAccent,
                                      borderRadius: BorderRadius.circular(
                                        InventoryDesignConfig.radiusS,
                                      ),
                                    ),
                                    child: Icon(
                                      PhosphorIcons.copy(),
                                      size: 16,
                                      color:
                                          InventoryDesignConfig.textSecondary,
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

            // Search field for colors
            _buildColorSearchField(),
            const SizedBox(height: 8),

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
                        decoration:
                            InventoryDesignConfig.buttonPrimaryDecoration,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              PhosphorIcons.check(),
                              size: 16,
                              color: Colors.white,
                            ),
                            const SizedBox(
                              width: InventoryDesignConfig.spacingS,
                            ),
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
      ),
    );
  }

  Widget _buildColorSearchField() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: TextField(
        decoration: InputDecoration(
          hintText: 'Search color name or hex...',
          prefixIcon: Icon(Icons.search, size: 18),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
          isDense: true,
          contentPadding: const EdgeInsets.symmetric(
            vertical: 10,
            horizontal: 12,
          ),
        ),
        onChanged: (value) {
          setState(() {
            _colorSearchQuery = value.trim().toLowerCase();
          });
        },
      ),
    );
  }

  Widget _buildFabricColorsTab() {
    final filteredCategories = <String, List<KandoraColor>>{};
    _kandoraColorCategories.forEach((category, colors) {
      final filtered =
          colors.where((color) {
            if (_colorSearchQuery.isEmpty) return true;
            return color.name.toLowerCase().contains(_colorSearchQuery) ||
                color.hex.toLowerCase().contains(_colorSearchQuery);
          }).toList();
      if (filtered.isNotEmpty) {
        filteredCategories[category] = filtered;
      }
    });

    return SingleChildScrollView(
      child: Column(
        children:
            filteredCategories.entries.map((entry) {
              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                child: Theme(
                  data: Theme.of(
                    context,
                  ).copyWith(dividerColor: Colors.transparent),
                  child: ExpansionTile(
                    tilePadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 4,
                    ),
                    childrenPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    leading: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: InventoryDesignConfig.primaryColor.withOpacity(
                          0.1,
                        ),
                        borderRadius: BorderRadius.circular(8),
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
                      LayoutBuilder(
                        builder: (context, constraints) {
                          final crossAxisCount = (constraints.maxWidth / 80)
                              .floor()
                              .clamp(2, 6);
                          return GridView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            gridDelegate:
                                SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: crossAxisCount,
                                  crossAxisSpacing: 12,
                                  mainAxisSpacing: 12,
                                  childAspectRatio: 1.2,
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
                                      _hexCode = color.hex;
                                      _colorNameController.text = _colorName;
                                      _hexController.text = _hexCode.substring(
                                        1,
                                      );
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
                                                ? InventoryDesignConfig
                                                    .primaryColor
                                                : Colors.transparent,
                                        width: isSelected ? 2 : 1,
                                      ),
                                    ),
                                    child: Stack(
                                      children: [
                                        if (isSelected)
                                          Align(
                                            alignment: Alignment.topRight,
                                            child: Padding(
                                              padding: const EdgeInsets.all(4),
                                              child: Icon(
                                                Icons.check_circle,
                                                color:
                                                    InventoryDesignConfig
                                                        .primaryColor,
                                                size: 18,
                                              ),
                                            ),
                                          ),
                                        Center(
                                          child: Text(
                                            color.name,
                                            style: InventoryDesignConfig
                                                .bodySmall
                                                .copyWith(
                                                  color:
                                                      materialColor
                                                                  .computeLuminance() >
                                                              0.5
                                                          ? Colors.black
                                                          : Colors.white,
                                                  fontWeight: FontWeight.w600,
                                                  shadows: [
                                                    Shadow(
                                                      color: Colors.black
                                                          .withOpacity(0.1),
                                                      blurRadius: 2,
                                                    ),
                                                  ],
                                                ),
                                            textAlign: TextAlign.center,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              );
                            },
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

  String get hex =>
      '#${colorValue.toRadixString(16).padLeft(8, '0').substring(2).toUpperCase()}';
}
