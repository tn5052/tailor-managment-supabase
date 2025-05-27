import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

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
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      width: MediaQuery.of(context).size.width > 600 ? 480 : double.infinity,
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.8,
        maxWidth: 480,
      ),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: colorScheme.surface,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(24),
              ),
            ),
            child: Row(
              children: [
                Icon(PhosphorIcons.palette(), color: colorScheme.primary),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Fabric Color Picker',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: Icon(
                    PhosphorIcons.x(),
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),

          // Color Preview
          Container(
            margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            height: 80,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: colorScheme.outlineVariant),
              color: colorScheme.surface,
            ),
            child: Row(
              children: [
                // Color block
                Container(
                  width: 120,
                  decoration: BoxDecoration(
                    color: _selectedColor,
                    borderRadius: const BorderRadius.horizontal(
                      left: Radius.circular(15),
                    ),
                  ),
                ),
                // Info
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          _colorName,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Text(
                              _hexCode,
                              style: theme.textTheme.bodyMedium?.copyWith(
                                fontFamily: 'monospace',
                                color: colorScheme.primary,
                              ),
                            ),
                            const SizedBox(width: 8),
                            GestureDetector(
                              onTap: () {
                                Clipboard.setData(
                                  ClipboardData(text: _hexCode),
                                );
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                      'Color code copied to clipboard',
                                    ),
                                  ),
                                );
                              },
                              child: Icon(
                                PhosphorIcons.copy(),
                                size: 18,
                                color: colorScheme.onSurfaceVariant,
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

          // Tabs
          TabBar(
            controller: _tabController,
            labelColor: colorScheme.primary,
            unselectedLabelColor: colorScheme.onSurfaceVariant,
            tabs: const [
              Tab(text: 'Fabric Colors'),
              Tab(text: 'Custom'),
              Tab(text: 'Manual'),
            ],
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

          // Action buttons
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                OutlinedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Cancel'),
                ),
                const SizedBox(width: 12),
                FilledButton(
                  onPressed: () {
                    widget.onColorSelected(
                      FabricColorResult(
                        color: _selectedColor,
                        colorName: _colorName,
                        hexCode: _hexCode,
                      ),
                    );
                  },
                  child: const Text('Select Color'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFabricColorsTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children:
          _kandoraColorCategories.entries.map((entry) {
            return ExpansionTile(
              title: Text(
                entry.key,
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              children: [
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  padding: const EdgeInsets.all(12),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    childAspectRatio: 1.2,
                  ),
                  itemCount: entry.value.length,
                  itemBuilder: (context, index) {
                    final color = entry.value[index];
                    final materialColor = Color(color.colorValue);

                    // Check if this color is selected
                    final isSelected =
                        materialColor.value == _selectedColor.value;

                    return GestureDetector(
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
                      child: Container(
                        decoration: BoxDecoration(
                          color: materialColor,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color:
                                isSelected
                                    ? Theme.of(context).colorScheme.primary
                                    : Colors.transparent,
                            width: 2,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            if (isSelected)
                              Container(
                                padding: const EdgeInsets.all(4),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.8),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  PhosphorIcons.check(),
                                  size: 16,
                                  color: Theme.of(context).colorScheme.primary,
                                ),
                              ),
                            const Spacer(),
                            // Name displayed at bottom
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.symmetric(vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.black.withOpacity(0.6),
                                borderRadius: const BorderRadius.vertical(
                                  bottom: Radius.circular(8),
                                ),
                              ),
                              child: Text(
                                color.name,
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ],
            );
          }).toList(),
    );
  }

  Widget _buildCustomColorTab() {
    // Simplified placeholder - could integrate with image color picker in future
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            PhosphorIcons.palette(),
            size: 64,
            color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
          ),
          const SizedBox(height: 16),
          const Text(
            'Custom color picker coming soon',
            style: TextStyle(fontSize: 16),
          ),
          const SizedBox(height: 8),
          const Text(
            'Please use the Fabric Colors or Manual tab',
            style: TextStyle(fontSize: 14),
          ),
        ],
      ),
    );
  }

  Widget _buildManualInputTab() {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Color Name', style: theme.textTheme.titleSmall),
          const SizedBox(height: 8),
          TextField(
            controller: _colorNameController,
            decoration: InputDecoration(
              hintText: 'Enter color name',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            onChanged: (value) {
              setState(() {
                _colorName = value;
              });
            },
          ),
          const SizedBox(height: 24),
          Text('Color Code (Hex)', style: theme.textTheme.titleSmall),
          const SizedBox(height: 8),
          TextField(
            controller: _hexController,
            decoration: InputDecoration(
              hintText: 'FFFFFF',
              prefixText: '# ',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'[0-9a-fA-F]')),
              LengthLimitingTextInputFormatter(6),
            ],
            onChanged: _updateFromHex,
          ),
          const SizedBox(height: 24),
          // Color tip card
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(PhosphorIcons.info(), color: theme.colorScheme.primary),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Common Kandora Colors',
                        style: theme.textTheme.titleSmall,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Traditional white is the most popular color for everyday wear in UAE. Darker colors like navy blue and charcoal are often worn in winter, while lighter pastels may be chosen for special occasions.',
                        style: theme.textTheme.bodySmall,
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
}

class KandoraColor {
  final String name;
  final int colorValue;
  final String description;

  KandoraColor(this.name, this.colorValue, this.description);
}
