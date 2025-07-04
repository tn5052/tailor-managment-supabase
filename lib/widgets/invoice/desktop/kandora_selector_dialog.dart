import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../theme/inventory_design_config.dart';
import '../../../models/kandora_product.dart';
import '../../../models/kandora_order.dart';

class KandoraSelectorDialog extends StatefulWidget {
  final String invoiceId;
  final Function(KandoraOrder) onKandoraSelected;

  const KandoraSelectorDialog({
    super.key,
    required this.invoiceId,
    required this.onKandoraSelected,
  });

  static Future<void> show(
    BuildContext context, {
    required String invoiceId,
    required Function(KandoraOrder) onKandoraSelected,
  }) async {
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => KandoraSelectorDialog(
        invoiceId: invoiceId,
        onKandoraSelected: onKandoraSelected,
      ),
    );
  }

  @override
  State<KandoraSelectorDialog> createState() => _KandoraSelectorDialogState();
}

class _KandoraSelectorDialogState extends State<KandoraSelectorDialog> {
  final _supabase = Supabase.instance.client;
  final _quantityController = TextEditingController(text: '1');
  final _priceController = TextEditingController();
  
  bool _isLoading = false;
  bool _isSaving = false;
  
  List<KandoraProduct> _kandoraProducts = [];
  List<Map<String, dynamic>> _fabrics = [];
  
  KandoraProduct? _selectedKandora;
  Map<String, dynamic>? _selectedFabric;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _quantityController.dispose();
    _priceController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    
    try {
      // Load kandora products
      final kandoraResponse = await _supabase
          .from('kandora_products')
          .select()
          .eq('is_active', true)
          .order('name');

      // Load available fabrics
      final fabricResponse = await _supabase
          .from('fabric_inventory')
          .select('id, fabric_item_name, shade_color, fabric_code, quantity_available, selling_price_per_unit')
          .eq('is_active', true)
          .gt('quantity_available', 0)
          .order('fabric_item_name');

      setState(() {
        _kandoraProducts = kandoraResponse
            .map<KandoraProduct>((json) => KandoraProduct.fromJson(json))
            .toList();
        _fabrics = List<Map<String, dynamic>>.from(fabricResponse);
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading data: ${e.toString()}'),
            backgroundColor: InventoryDesignConfig.errorColor,
          ),
        );
      }
    }
  }

  void _onKandoraSelected(KandoraProduct kandora) {
    setState(() {
      _selectedKandora = kandora;
      // Set a default price (you can modify this logic)
      _priceController.text = '150.00'; // Default kandora price
    });
  }

  Future<void> _saveKandoraOrder() async {
    if (_selectedKandora == null || _selectedFabric == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select both kandora type and fabric'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    final quantity = int.tryParse(_quantityController.text) ?? 0;
    final pricePerUnit = double.tryParse(_priceController.text) ?? 0.0;

    if (quantity <= 0 || pricePerUnit <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter valid quantity and price'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    // Check if enough fabric is available
    final fabricNeeded = _selectedKandora!.fabricYardsRequired * quantity;
    final availableFabric = (_selectedFabric!['quantity_available'] as num).toDouble();
    
    if (fabricNeeded > availableFabric) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Not enough fabric available. Need: ${fabricNeeded.toStringAsFixed(1)} yards, Available: ${availableFabric.toStringAsFixed(1)} yards'
          ),
          backgroundColor: InventoryDesignConfig.errorColor,
        ),
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      final kandoraOrder = KandoraOrder(
        id: '', // Will be generated by database
        invoiceId: widget.invoiceId,
        kandoraProductId: _selectedKandora!.id,
        fabricInventoryId: _selectedFabric!['id'],
        fabricYardsConsumed: fabricNeeded,
        quantity: quantity,
        pricePerUnit: pricePerUnit,
        totalPrice: quantity * pricePerUnit,
        tenantId: _supabase.auth.currentUser!.id,
        createdAt: DateTime.now(),
        kandoraName: _selectedKandora!.name,
        fabricItemName: _selectedFabric!['fabric_item_name'],
        shadeColor: _selectedFabric!['shade_color'],
        fabricCode: _selectedFabric!['fabric_code'],
      );

      // Insert the kandora order (triggers will handle fabric deduction)
      final response = await _supabase
          .from('kandora_orders')
          .insert(kandoraOrder.toInsertJson())
          .select()
          .single();

      final savedOrder = KandoraOrder.fromJson(response).copyWith(
        kandoraName: _selectedKandora!.name,
        fabricItemName: _selectedFabric!['fabric_item_name'],
        shadeColor: _selectedFabric!['shade_color'],
        fabricCode: _selectedFabric!['fabric_code'],
      );

      widget.onKandoraSelected(savedOrder);
      
      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${_selectedKandora!.name} added to invoice'),
            backgroundColor: InventoryDesignConfig.successColor,
          ),
        );
      }
    } catch (e) {
      setState(() => _isSaving = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error adding kandora: ${e.toString()}'),
            backgroundColor: InventoryDesignConfig.errorColor,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(InventoryDesignConfig.radiusL),
      ),
      child: Container(
        width: 600,
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(),
            const SizedBox(height: 24),
            if (_isLoading) 
              const Center(child: CircularProgressIndicator())
            else ...[
              _buildKandoraSelection(),
              const SizedBox(height: 20),
              _buildFabricSelection(),
              const SizedBox(height: 20),
              _buildQuantityAndPrice(),
              const SizedBox(height: 24),
              _buildButtons(),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: InventoryDesignConfig.primaryColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            PhosphorIcons.tShirt(),
            color: InventoryDesignConfig.primaryColor,
            size: 24,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Add Kandora to Invoice',
                style: GoogleFonts.inter(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: InventoryDesignConfig.textPrimary,
                ),
              ),
              Text(
                'Select kandora type and fabric',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  color: InventoryDesignConfig.textSecondary,
                ),
              ),
            ],
          ),
        ),
        IconButton(
          onPressed: () => Navigator.of(context).pop(),
          icon: Icon(
            PhosphorIcons.x(),
            color: InventoryDesignConfig.textSecondary,
          ),
        ),
      ],
    );
  }

  Widget _buildKandoraSelection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Select Kandora Type',
          style: GoogleFonts.inter(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: InventoryDesignConfig.textPrimary,
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: _kandoraProducts.map((kandora) => _buildKandoraCard(kandora)).toList(),
        ),
      ],
    );
  }

  Widget _buildKandoraCard(KandoraProduct kandora) {
    final isSelected = _selectedKandora?.id == kandora.id;
    
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _onKandoraSelected(kandora),
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isSelected 
                ? InventoryDesignConfig.primaryColor.withOpacity(0.1)
                : InventoryDesignConfig.surfaceAccent,
            border: Border.all(
              color: isSelected 
                  ? InventoryDesignConfig.primaryColor
                  : InventoryDesignConfig.borderPrimary,
              width: isSelected ? 2 : 1,
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    PhosphorIcons.tShirt(),
                    color: isSelected 
                        ? InventoryDesignConfig.primaryColor
                        : InventoryDesignConfig.textSecondary,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    kandora.name,
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: isSelected 
                          ? InventoryDesignConfig.primaryColor
                          : InventoryDesignConfig.textPrimary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                '${kandora.fabricYardsRequired} yards fabric required',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  color: InventoryDesignConfig.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFabricSelection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Select Fabric',
          style: GoogleFonts.inter(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: InventoryDesignConfig.textPrimary,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          height: 200,
          decoration: BoxDecoration(
            border: Border.all(color: InventoryDesignConfig.borderPrimary),
            borderRadius: BorderRadius.circular(12),
          ),
          child: ListView.builder(
            padding: const EdgeInsets.all(8),
            itemCount: _fabrics.length,
            itemBuilder: (context, index) => _buildFabricItem(_fabrics[index]),
          ),
        ),
      ],
    );
  }

  Widget _buildFabricItem(Map<String, dynamic> fabric) {
    final isSelected = _selectedFabric?['id'] == fabric['id'];
    
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => setState(() => _selectedFabric = fabric),
        borderRadius: BorderRadius.circular(8),
        child: Container(
          margin: const EdgeInsets.symmetric(vertical: 2),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: isSelected 
                ? InventoryDesignConfig.primaryColor.withOpacity(0.1)
                : Colors.transparent,
            border: Border.all(
              color: isSelected 
                  ? InventoryDesignConfig.primaryColor
                  : Colors.transparent,
            ),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              Icon(
                PhosphorIcons.scissors(),
                color: isSelected 
                    ? InventoryDesignConfig.primaryColor
                    : InventoryDesignConfig.textSecondary,
                size: 16,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      fabric['fabric_item_name'] ?? '',
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: InventoryDesignConfig.textPrimary,
                      ),
                    ),
                    Text(
                      '${fabric['shade_color']} • ${fabric['quantity_available']} yards available',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: InventoryDesignConfig.textSecondary,
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

  Widget _buildQuantityAndPrice() {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Quantity',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: InventoryDesignConfig.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _quantityController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Price per Kandora (AED)',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: InventoryDesignConfig.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _priceController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildButtons() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        TextButton(
          onPressed: _isSaving ? null : () => Navigator.of(context).pop(),
          child: Text(
            'Cancel',
            style: GoogleFonts.inter(
              color: InventoryDesignConfig.textSecondary,
            ),
          ),
        ),
        const SizedBox(width: 16),
        ElevatedButton.icon(
          onPressed: _isSaving ? null : _saveKandoraOrder,
          icon: _isSaving
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Icon(PhosphorIcons.plus()),
          label: Text(_isSaving ? 'Adding...' : 'Add Kandora'),
          style: ElevatedButton.styleFrom(
            backgroundColor: InventoryDesignConfig.primaryColor,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          ),
        ),
      ],
    );
  }
}
