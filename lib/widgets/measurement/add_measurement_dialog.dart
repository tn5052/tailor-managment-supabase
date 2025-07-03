import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:uuid/uuid.dart';
import '../../../models/measurement.dart';
import '../../../models/customer.dart';
import '../../../services/measurement_service.dart';
import '../../../services/customer_service.dart';
import '../../../utils/fraction_helper.dart';
import '../../../theme/inventory_design_config.dart';
import '../customer/desktop/customer_selector_dialog.dart';

class AddMeasurementDialog extends StatefulWidget {
  final Measurement? measurement;
  final bool isEditing;
  final Customer? customer;
  final VoidCallback? onMeasurementAdded;

  const AddMeasurementDialog({
    super.key,
    this.measurement,
    this.isEditing = false,
    this.customer,
    this.onMeasurementAdded,
  });

  static Future<void> show(
    BuildContext context, {
    Measurement? measurement,
    bool isEditing = false,
    Customer? customer,
    VoidCallback? onMeasurementAdded,
  }) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktop = screenWidth >= 1024;

    if (isDesktop) {
      return showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder:
            (context) => AddMeasurementDialog(
              measurement: measurement,
              isEditing: isEditing,
              customer: customer,
              onMeasurementAdded: onMeasurementAdded,
            ),
      );
    }

    return showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Desktop Only'),
            content: const Text('This feature is only available on desktop.'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('OK'),
              ),
            ],
          ),
    );
  }

  @override
  State<AddMeasurementDialog> createState() => _AddMeasurementDialogState();
}

class _AddMeasurementDialogState extends State<AddMeasurementDialog> {
  final MeasurementService _measurementService = MeasurementService();
  final SupabaseService _supabaseService = SupabaseService();
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;

  // Controllers
  late final TextEditingController _lengthArabiController;
  late final TextEditingController _lengthKuwaitiController;
  late final TextEditingController _chestController;
  late final TextEditingController _widthController;
  late final TextEditingController _sleeveController;
  late final TextEditingController _collarController;
  late final TextEditingController _underController;
  late final TextEditingController _backLengthController;
  late final TextEditingController _neckController;
  late final TextEditingController _shoulderController;
  late final TextEditingController _seamController;
  late final TextEditingController _adhesiveController;
  late final TextEditingController _underKanduraController;
  late final TextEditingController _openSleeveController;
  late final TextEditingController _stitchingController;
  late final TextEditingController _pleatController;
  late final TextEditingController _buttonController;
  late final TextEditingController _cuffController;
  late final TextEditingController _embroideryController;
  late final TextEditingController _neckStyleController;
  late final TextEditingController _notesController;

  String? _selectedCustomerId;
  String _billNumber = '';
  String? _selectedStyle;
  String _selectedDesignType = 'Aadi';
  String _selectedTarbooshType = 'Fixed';
  String? _selectedCustomerName;

  final List<String> _styleOptions = [
    'Emirati',
    'Kuwaiti',
    'Saudi',
    'Omani',
    'Qatari',
  ];
  final List<String> _designOptions = ['Aadi', 'Baat'];
  final List<String> _tarbooshOptions = ['Fixed', 'Separate'];

  @override
  void initState() {
    super.initState();
    _initializeControllers();
    _initializeData();
  }

  void _initializeControllers() {
    _lengthArabiController = TextEditingController();
    _lengthKuwaitiController = TextEditingController();
    _chestController = TextEditingController();
    _widthController = TextEditingController();
    _sleeveController = TextEditingController();
    _collarController = TextEditingController();
    _underController = TextEditingController();
    _backLengthController = TextEditingController();
    _neckController = TextEditingController();
    _shoulderController = TextEditingController();
    _seamController = TextEditingController();
    _adhesiveController = TextEditingController();
    _underKanduraController = TextEditingController();
    _openSleeveController = TextEditingController();
    _stitchingController = TextEditingController();
    _pleatController = TextEditingController();
    _buttonController = TextEditingController();
    _cuffController = TextEditingController();
    _embroideryController = TextEditingController();
    _neckStyleController = TextEditingController();
    _notesController = TextEditingController();
  }

  void _initializeData() {
    if (widget.customer != null) {
      _selectedCustomerId = widget.customer!.id;
      _billNumber = widget.customer!.billNumber;
      _selectedCustomerName = widget.customer!.name;
    }

    if (widget.isEditing && widget.measurement != null) {
      final measurement = widget.measurement!;
      _selectedCustomerId = measurement.customerId;
      _billNumber = measurement.billNumber;
      _selectedStyle = measurement.style;
      _lengthArabiController.text = measurement.lengthArabi.toString();
      _lengthKuwaitiController.text = measurement.lengthKuwaiti.toString();
      _chestController.text = measurement.chest.toString();
      _widthController.text = measurement.width.toString();
      _sleeveController.text = measurement.sleeve.toString();
      _collarController.text = measurement.collar.toString();
      _underController.text = measurement.under.toString();
      _backLengthController.text = measurement.backLength.toString();
      _neckController.text = measurement.neck.toString();
      _shoulderController.text = measurement.shoulder.toString();
      _seamController.text = measurement.seam;
      _adhesiveController.text = measurement.adhesive;
      _underKanduraController.text = measurement.underKandura;
      _openSleeveController.text = measurement.openSleeve;
      _stitchingController.text = measurement.stitching;
      _pleatController.text = measurement.pleat;
      _buttonController.text = measurement.button;
      _cuffController.text = measurement.cuff;
      _embroideryController.text = measurement.embroidery;
      _neckStyleController.text = measurement.neckStyle;
      _notesController.text = measurement.notes;
      _selectedDesignType = measurement.designType;
      _selectedTarbooshType = measurement.tarbooshType;

      _fetchCustomerName();
    } else {
      _selectedStyle = _styleOptions[0];
    }
  }

  Future<void> _fetchCustomerName() async {
    if (_selectedCustomerId != null) {
      final customers = await _supabaseService.getCustomersStream().first;
      final customer = customers.firstWhere(
        (c) => c.id == _selectedCustomerId,
        orElse:
            () => Customer(
              id: '',
              billNumber: '',
              name: 'Unknown Customer',
              phone: '',
              address: '',
              gender: Gender.male,
            ),
      );
      setState(() {
        _selectedCustomerName = customer.name;
      });
    }
  }

  @override
  void dispose() {
    _lengthArabiController.dispose();
    _lengthKuwaitiController.dispose();
    _chestController.dispose();
    _widthController.dispose();
    _sleeveController.dispose();
    _collarController.dispose();
    _underController.dispose();
    _backLengthController.dispose();
    _neckController.dispose();
    _shoulderController.dispose();
    _seamController.dispose();
    _adhesiveController.dispose();
    _underKanduraController.dispose();
    _openSleeveController.dispose();
    _stitchingController.dispose();
    _pleatController.dispose();
    _buttonController.dispose();
    _cuffController.dispose();
    _embroideryController.dispose();
    _neckStyleController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _saveMeasurement() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final measurement = Measurement(
        id: widget.isEditing ? widget.measurement!.id : const Uuid().v4(),
        customerId: _selectedCustomerId!,
        billNumber: _billNumber,
        style: _selectedStyle!,
        lengthArabi: FractionHelper.parseFraction(_lengthArabiController.text).toString(),
        lengthKuwaiti: FractionHelper.parseFraction(
          _lengthKuwaitiController.text,
        ).toString(),
        chest: FractionHelper.parseFraction(_chestController.text).toString(),
        width: FractionHelper.parseFraction(_widthController.text).toString(),
        sleeve: FractionHelper.parseFraction(_sleeveController.text).toString(),
        collar: {
          'start': FractionHelper.parseFraction(_collarController.text).toString(),
          'center': 0.0.toString(),
          'end': 0.0.toString(),
        },
        under: FractionHelper.parseFraction(_underController.text).toString(),
        backLength: FractionHelper.parseFraction(_backLengthController.text).toString(),
        neck: FractionHelper.parseFraction(_neckController.text).toString(),
        shoulder: FractionHelper.parseFraction(_shoulderController.text).toString(),
        seam: _seamController.text,
        adhesive: _adhesiveController.text,
        underKandura: _underKanduraController.text,
        tarboosh: _selectedTarbooshType,
        openSleeve: _openSleeveController.text,
        stitching: _stitchingController.text,
        pleat: _pleatController.text,
        button: _buttonController.text,
        cuff: _cuffController.text,
        embroidery: _embroideryController.text,
        neckStyle: _neckStyleController.text,
        notes: _notesController.text,
        fabricName:
            '', // Set to empty string or handle as nullable in model if appropriate
        designType: _selectedDesignType,
        tarbooshType: _selectedTarbooshType,
        date: widget.isEditing ? widget.measurement!.date : DateTime.now(),
        lastUpdated: DateTime.now(),
      );

      if (widget.isEditing) {
        await _measurementService.updateMeasurement(measurement);
      } else {
        await _measurementService.addMeasurement(measurement);
      }

      if (mounted) {
        Navigator.of(context).pop();
        widget.onMeasurementAdded?.call();

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              widget.isEditing
                  ? 'Measurement updated successfully'
                  : 'Measurement added successfully',
            ),
            backgroundColor: InventoryDesignConfig.successColor,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: InventoryDesignConfig.errorColor,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Future<void> _openCustomerSelector() async {
    final customers = await _supabaseService.getCustomersStream().first;
    final customer = await CustomerSelectorDialog.show(context, customers);
    if (customer != null) {
      setState(() {
        _selectedCustomerId = customer.id;
        _billNumber = customer.billNumber;
        _selectedCustomerName = customer.name;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final maxHeight = screenSize.height * 0.9;

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: 800, maxHeight: maxHeight),
        child: Container(
          decoration: BoxDecoration(
            color: InventoryDesignConfig.surfaceColor,
            borderRadius: BorderRadius.circular(InventoryDesignConfig.radiusXL),
            border: Border.all(color: InventoryDesignConfig.borderPrimary),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.02),
                blurRadius: 8,
                offset: const Offset(0, 2),
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
      height: 64,
      padding: const EdgeInsets.symmetric(
        horizontal: InventoryDesignConfig.spacingXXL,
      ),
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
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: InventoryDesignConfig.primaryColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(
                InventoryDesignConfig.radiusM,
              ),
            ),
            child: Icon(
              widget.isEditing
                  ? PhosphorIcons.pencilSimple()
                  : PhosphorIcons.ruler(),
              size: 18,
              color: InventoryDesignConfig.primaryColor,
            ),
          ),
          const SizedBox(width: InventoryDesignConfig.spacingL),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.isEditing ? 'Edit Measurement' : 'Add New Measurement',
                  style: InventoryDesignConfig.headlineMedium,
                ),
                Text(
                  widget.isEditing
                      ? 'Update measurement details'
                      : 'Create a new customer measurement',
                  style: InventoryDesignConfig.bodyMedium.copyWith(
                    color: InventoryDesignConfig.textSecondary,
                  ),
                ),
              ],
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
    return SingleChildScrollView(
      padding: const EdgeInsets.all(InventoryDesignConfig.spacingL),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Customer Selection Section
            _buildSection(
              'Customer Selection',
              'اختيار العميل', // Arabic title remains for section header
              PhosphorIcons.user(),
              [_buildCustomerSelector()],
            ),

            const SizedBox(height: InventoryDesignConfig.spacingL),

            // Style & Design Section
            _buildSection(
              'Style & Design',
              'التصميم والستايل', // Arabic title remains for section header
              PhosphorIcons.paintBrush(),
              [
                Row(
                  children: [
                    Expanded(
                      flex: 2,
                      child: _buildDropdown<String>(
                        value: _selectedStyle,
                        label: 'Style',
                        arabicLabel: 'الستايل', // Placeholder
                        icon: PhosphorIcons.star(),
                        items:
                            _styleOptions
                                .map(
                                  (style) => DropdownMenuItem<String>(
                                    value: style,
                                    child: Text(style),
                                  ),
                                )
                                .toList(),
                        onChanged:
                            (value) => setState(() => _selectedStyle = value),
                        validator: (value) => value == null ? 'Required' : null,
                      ),
                    ),
                    const SizedBox(width: InventoryDesignConfig.spacingM),
                    Expanded(
                      child: _buildDropdown<String>(
                        value: _selectedDesignType,
                        label: 'Design',
                        arabicLabel: 'التصميم', // Placeholder
                        icon: PhosphorIcons.palette(),
                        items:
                            _designOptions
                                .map(
                                  (design) => DropdownMenuItem<String>(
                                    value: design,
                                    child: Text(design),
                                  ),
                                )
                                .toList(),
                        onChanged:
                            (value) =>
                                setState(() => _selectedDesignType = value!),
                      ),
                    ),
                    const SizedBox(width: InventoryDesignConfig.spacingM),
                    Expanded(
                      child: _buildDropdown<String>(
                        value: _selectedTarbooshType,
                        label: 'Cap Style',
                        arabicLabel: 'موديل التربوش', // Placeholder
                        icon: PhosphorIcons.crown(),
                        items:
                            _tarbooshOptions
                                .map(
                                  (tarboosh) => DropdownMenuItem<String>(
                                    value: tarboosh,
                                    child: Text(tarboosh),
                                  ),
                                )
                                .toList(),
                        onChanged:
                            (value) =>
                                setState(() => _selectedTarbooshType = value!),
                      ),
                    ),
                  ],
                ),
              ],
            ),

            const SizedBox(height: InventoryDesignConfig.spacingL),

            // Main Measurements Section
            _buildSection(
              'Main Measurements',
              'القياسات الرئيسية', // Arabic title remains for section header
              PhosphorIcons.ruler(),
              [_buildMeasurementsGrid()],
            ),

            const SizedBox(height: InventoryDesignConfig.spacingL),

            // Style Details Section
            _buildSection(
              'Style Details',
              'تفاصيل الستايل', // Arabic title remains for section header
              PhosphorIcons.palette(),
              [_buildStyleDetailsGrid()],
            ),

            const SizedBox(height: InventoryDesignConfig.spacingL),

            // Additional Notes Section
            _buildSection(
              'Additional Notes',
              'ملاحظات إضافية', // Arabic title remains for section header
              PhosphorIcons.note(),
              [
                _buildTextField(
                  controller: _notesController,
                  label: 'Notes (Optional)',
                  arabicLabel: 'ملاحظات (اختياري)', // Placeholder
                  icon: PhosphorIcons.note(),
                  maxLines: 2,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFooter() {
    return Container(
      height: 72,
      padding: const EdgeInsets.symmetric(
        horizontal: InventoryDesignConfig.spacingXXL,
      ),
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
              onTap: _isLoading ? null : () => Navigator.of(context).pop(),
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
              onTap: _isLoading ? null : _saveMeasurement,
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
                    if (_isLoading)
                      const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    else
                      Icon(
                        widget.isEditing
                            ? PhosphorIcons.check()
                            : PhosphorIcons.ruler(),
                        size: 16,
                        color: Colors.white,
                      ),
                    const SizedBox(width: InventoryDesignConfig.spacingS),
                    Text(
                      _isLoading
                          ? (widget.isEditing ? 'Updating...' : 'Adding...')
                          : (widget.isEditing
                              ? 'Update Measurement'
                              : 'Add Measurement'),
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

  Widget _buildSection(
    String title,
    String arabicTitle,
    IconData icon,
    List<Widget> children,
  ) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: InventoryDesignConfig.surfaceAccent.withOpacity(0.3),
        borderRadius: BorderRadius.circular(InventoryDesignConfig.radiusL),
        border: Border.all(color: InventoryDesignConfig.borderSecondary),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(InventoryDesignConfig.spacingL),
            decoration: BoxDecoration(
              color: InventoryDesignConfig.primaryColor.withOpacity(0.05),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(InventoryDesignConfig.radiusL),
                topRight: Radius.circular(InventoryDesignConfig.radiusL),
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
                  padding: const EdgeInsets.all(InventoryDesignConfig.spacingS),
                  decoration: BoxDecoration(
                    color: InventoryDesignConfig.primaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(
                      InventoryDesignConfig.radiusS,
                    ),
                  ),
                  child: Icon(
                    icon,
                    size: 16,
                    color: InventoryDesignConfig.primaryColor,
                  ),
                ),
                const SizedBox(width: InventoryDesignConfig.spacingM),
                Text(
                  title,
                  style: InventoryDesignConfig.titleMedium.copyWith(
                    color: InventoryDesignConfig.primaryColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(width: InventoryDesignConfig.spacingXS),
                Expanded(
                  child: Text(
                    arabicTitle,
                    style: InventoryDesignConfig.bodySmall.copyWith(
                      color: InventoryDesignConfig.primaryColor.withOpacity(
                        0.7,
                      ),
                    ),
                    textAlign: TextAlign.right,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(InventoryDesignConfig.spacingL),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: children,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCustomerSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'Customer',
              style: InventoryDesignConfig.labelLarge.copyWith(
                color: InventoryDesignConfig.textPrimary,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(width: InventoryDesignConfig.spacingXS),
            Expanded(
              child: Text(
                'العميل', // Arabic for Customer
                style: InventoryDesignConfig.bodySmall.copyWith(
                  color: InventoryDesignConfig.textSecondary,
                ),
                textAlign: TextAlign.right,
              ),
            ),
          ],
        ),
        const SizedBox(height: InventoryDesignConfig.spacingS),
        Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: _openCustomerSelector,
            borderRadius: BorderRadius.circular(InventoryDesignConfig.radiusM),
            child: Container(
              padding: const EdgeInsets.all(InventoryDesignConfig.spacingM),
              decoration: BoxDecoration(
                color: InventoryDesignConfig.surfaceLight,
                borderRadius: BorderRadius.circular(
                  InventoryDesignConfig.radiusM,
                ),
                border: Border.all(
                  color:
                      _selectedCustomerId == null
                          ? InventoryDesignConfig.errorColor
                          : InventoryDesignConfig.borderPrimary,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    PhosphorIcons.user(),
                    size: 18,
                    color: InventoryDesignConfig.textSecondary,
                  ),
                  const SizedBox(width: InventoryDesignConfig.spacingM),
                  Expanded(
                    child:
                        _selectedCustomerId == null
                            ? Text(
                              'Select Customer',
                              style: InventoryDesignConfig.bodyMedium.copyWith(
                                color: InventoryDesignConfig.textTertiary,
                              ),
                            )
                            : Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _selectedCustomerName ?? 'Loading...',
                                  style: InventoryDesignConfig.bodyLarge
                                      .copyWith(
                                        color:
                                            InventoryDesignConfig.textPrimary,
                                        fontWeight: FontWeight.w600,
                                      ),
                                ),
                                Text(
                                  'Bill #$_billNumber',
                                  style: InventoryDesignConfig.bodySmall
                                      .copyWith(
                                        color:
                                            InventoryDesignConfig.textSecondary,
                                      ),
                                ),
                              ],
                            ),
                  ),
                  Icon(
                    PhosphorIcons.caretDown(),
                    size: 16,
                    color: InventoryDesignConfig.textSecondary,
                  ),
                ],
              ),
            ),
          ),
        ),
        if (_selectedCustomerId == null)
          Padding(
            padding: const EdgeInsets.only(top: InventoryDesignConfig.spacingS),
            child: Text(
              'Please select a customer',
              style: InventoryDesignConfig.bodySmall.copyWith(
                color: InventoryDesignConfig.errorColor,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildMeasurementsGrid() {
    final measurements = [
      _MeasurementField(
        controller:
            _selectedStyle == 'Emirati'
                ? _lengthArabiController
                : _lengthKuwaitiController,
        label:
            _selectedStyle == 'Emirati'
                ? 'Length (Arabic)'
                : 'Length (Kuwaiti)',
        arabicLabel: _selectedStyle == 'Emirati' ? 'طول عربي' : 'طول كويتي',
        icon: PhosphorIcons.arrowsVertical(),
        required: true,
        isHighlighted: true,
      ),
      _MeasurementField(
        controller: _chestController,
        label: 'Chest',
        arabicLabel: 'صدر',
        icon: PhosphorIcons.circleHalf(),
        isHighlighted: true,
      ),
      _MeasurementField(
        controller: _widthController,
        label: 'Width',
        arabicLabel: 'عرض',
        icon: PhosphorIcons.arrowsHorizontal(),
        isHighlighted: true,
      ),
      _MeasurementField(
        controller: _backLengthController,
        label: 'Back Length',
        arabicLabel: 'طول خلفي',
        icon: PhosphorIcons.arrowUp(),
      ),
      _MeasurementField(
        controller: _collarController,
        label: 'Neck Size',
        arabicLabel: 'رقبہ',
        icon: PhosphorIcons.circle(),
      ),
      _MeasurementField(
        controller: _shoulderController,
        label: 'Shoulder',
        arabicLabel: 'كتف',
        icon: PhosphorIcons.arrowsOutLineHorizontal(),
      ),
      _MeasurementField(
        controller: _sleeveController,
        label: 'Sleeve Length',
        arabicLabel: 'كم',
        icon: PhosphorIcons.arrowLineRight(),
      ),
      _MeasurementField(
        controller: _neckController,
        label: 'Sleeve Fitting',
        arabicLabel: 'فكم',
        icon: PhosphorIcons.circleNotch(),
      ),
      _MeasurementField(
        controller: _underController,
        label: 'Under Shoulder',
        arabicLabel: 'تحت الكتف',
        icon: PhosphorIcons.arrowDown(),
      ),
      _MeasurementField(
        controller: _seamController,
        label: 'Side Seam',
        arabicLabel: 'شيب',
        icon: PhosphorIcons.path(),
        isTextField: true,
      ),
      _MeasurementField(
        controller: _adhesiveController,
        label: 'Adhesive',
        arabicLabel: 'چسبا',
        icon: PhosphorIcons.drop(),
        isTextField: true,
      ),
      _MeasurementField(
        controller: _underKanduraController,
        label: 'Under Kandura',
        arabicLabel: 'تحت كندورة',
        icon: PhosphorIcons.shirtFolded(),
        isTextField: true,
      ),
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        childAspectRatio: 2.8,
        mainAxisSpacing: InventoryDesignConfig.spacingS,
        crossAxisSpacing: InventoryDesignConfig.spacingS,
      ),
      itemCount: measurements.length,
      itemBuilder: (context, index) {
        final field = measurements[index];
        return field.isTextField
            ? _buildCompactTextField(
              controller: field.controller,
              englishLabel: field.label,
              arabicLabel: field.arabicLabel,
              icon: field.icon,
              required: field.required,
            )
            : _buildMeasurementField(
              controller: field.controller,
              englishLabel: field.label,
              arabicLabel: field.arabicLabel,
              icon: field.icon,
              required: field.required,
              isHighlighted: field.isHighlighted,
            );
      },
    );
  }

  Widget _buildStyleDetailsGrid() {
    final styleFields = [
      _StyleField(
        controller: _openSleeveController,
        label: 'Sleeve Opening',
        arabicLabel: 'كم سلائی',
        icon: PhosphorIcons.tShirt(),
      ),
      _StyleField(
        controller: _stitchingController,
        label: 'Stitching Style',
        arabicLabel: 'خياطة',
        icon: PhosphorIcons.needle(),
      ),
      _StyleField(
        controller: _pleatController,
        label: 'Pleat Style',
        arabicLabel: 'كسرة',
        icon: PhosphorIcons.rows(),
      ),
      _StyleField(
        controller: _buttonController,
        label: 'Side Pocket',
        arabicLabel: 'بتى',
        icon: PhosphorIcons.circle(),
      ),
      _StyleField(
        controller: _cuffController,
        label: 'Cuff Style',
        arabicLabel: 'كف',
        icon: PhosphorIcons.circleHalf(),
      ),
      _StyleField(
        controller: _embroideryController,
        label: 'Embroidery',
        arabicLabel: 'تطريز',
        icon: PhosphorIcons.flower(),
      ),
      _StyleField(
        controller: _neckStyleController,
        label: 'Neck Style',
        arabicLabel: 'رقبة',
        icon: PhosphorIcons.moon(),
      ),
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        childAspectRatio: 2.8,
        mainAxisSpacing: InventoryDesignConfig.spacingS,
        crossAxisSpacing: InventoryDesignConfig.spacingS,
      ),
      itemCount: styleFields.length,
      itemBuilder: (context, index) {
        final field = styleFields[index];
        return _buildCompactTextField(
          controller: field.controller,
          englishLabel: field.label,
          arabicLabel: field.arabicLabel,
          icon: field.icon,
        );
      },
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    String? arabicLabel, // This will be the placeholder
    required IconData icon,
    String? Function(String?)? validator,
    TextInputType? keyboardType,
    int maxLines = 1,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: InventoryDesignConfig.labelLarge.copyWith(
            color: InventoryDesignConfig.textPrimary,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: InventoryDesignConfig.spacingS),
        TextFormField(
          controller: controller,
          validator: validator,
          keyboardType: keyboardType,
          maxLines: maxLines,
          style: InventoryDesignConfig.bodyLarge.copyWith(
            color: InventoryDesignConfig.textPrimary,
          ),
          decoration: InputDecoration(
            hintText: arabicLabel,
            hintStyle: InventoryDesignConfig.bodyMedium.copyWith(
              color: InventoryDesignConfig.textTertiary,
            ),
            prefixIcon: Icon(
              icon,
              size: 18,
              color: InventoryDesignConfig.textSecondary,
            ),
            filled: true,
            fillColor: InventoryDesignConfig.surfaceLight,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(
                InventoryDesignConfig.radiusM,
              ),
              borderSide: BorderSide(
                color: InventoryDesignConfig.borderPrimary,
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(
                InventoryDesignConfig.radiusM,
              ),
              borderSide: BorderSide(
                color: InventoryDesignConfig.borderPrimary,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(
                InventoryDesignConfig.radiusM,
              ),
              borderSide: BorderSide(
                color: InventoryDesignConfig.primaryColor,
                width: 2.0,
              ),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(
                InventoryDesignConfig.radiusM,
              ),
              borderSide: BorderSide(
                color: InventoryDesignConfig.errorColor,
                width: 2.0,
              ),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(
                InventoryDesignConfig.radiusM,
              ),
              borderSide: BorderSide(
                color: InventoryDesignConfig.errorColor,
                width: 2.0,
              ),
            ),
            contentPadding: EdgeInsets.symmetric(
              horizontal: InventoryDesignConfig.spacingL,
              vertical:
                  maxLines > 1
                      ? InventoryDesignConfig.spacingL
                      : InventoryDesignConfig.spacingM,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMeasurementField({
    required TextEditingController controller,
    required String englishLabel,
    required String arabicLabel,
    required IconData icon,
    bool required = false,
    bool isHighlighted = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            if (isHighlighted)
              Container(
                width: 4,
                height: 4,
                margin: const EdgeInsets.only(
                  right: InventoryDesignConfig.spacingXS,
                ),
                decoration: BoxDecoration(
                  color: InventoryDesignConfig.primaryColor,
                  shape: BoxShape.circle,
                ),
              ),
            Expanded(
              child: Text(
                englishLabel,
                style: InventoryDesignConfig.labelLarge.copyWith(
                  color:
                      isHighlighted
                          ? InventoryDesignConfig.primaryColor
                          : InventoryDesignConfig.textPrimary,
                  fontWeight: FontWeight.w600,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        const SizedBox(height: InventoryDesignConfig.spacingS),
        TextFormField(
          controller: controller,
          keyboardType: TextInputType.text,
          style: InventoryDesignConfig.bodyLarge.copyWith(
            color: InventoryDesignConfig.textPrimary,
            fontWeight: FontWeight.w600,
          ),
          decoration: InputDecoration(
            prefixIcon: Icon(
              icon,
              size: 18,
              color:
                  isHighlighted
                      ? InventoryDesignConfig.primaryColor.withOpacity(0.7)
                      : InventoryDesignConfig.textSecondary,
            ),
            hintText: arabicLabel,
            hintStyle: InventoryDesignConfig.bodyMedium.copyWith(
              color: InventoryDesignConfig.textTertiary,
            ),
            suffixText: '"',
            suffixStyle: InventoryDesignConfig.bodySmall.copyWith(
              color: InventoryDesignConfig.textSecondary,
            ),
            filled: true,
            fillColor:
                isHighlighted
                    ? InventoryDesignConfig.primaryColor.withOpacity(0.05)
                    : InventoryDesignConfig.surfaceLight,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(
                InventoryDesignConfig.radiusS,
              ),
              borderSide: BorderSide(
                color:
                    isHighlighted
                        ? InventoryDesignConfig.primaryColor.withOpacity(0.3)
                        : InventoryDesignConfig.borderPrimary,
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(
                InventoryDesignConfig.radiusS,
              ),
              borderSide: BorderSide(
                color:
                    isHighlighted
                        ? InventoryDesignConfig.primaryColor.withOpacity(0.3)
                        : InventoryDesignConfig.borderPrimary,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(
                InventoryDesignConfig.radiusS,
              ),
              borderSide: BorderSide(
                color: InventoryDesignConfig.primaryColor,
                width: 2.0,
              ),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(
                InventoryDesignConfig.radiusS,
              ),
              borderSide: BorderSide(
                color: InventoryDesignConfig.errorColor,
                width: 2.0,
              ),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(
                InventoryDesignConfig.radiusS,
              ),
              borderSide: BorderSide(
                color: InventoryDesignConfig.errorColor,
                width: 2.0,
              ),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: InventoryDesignConfig.spacingL,
              vertical: InventoryDesignConfig.spacingM,
            ),
          ),
          validator:
              required
                  ? (value) {
                    if (value == null || value.isEmpty) {
                      return 'Required';
                    }
                    if (!FractionHelper.isValidFraction(value)) {
                      return 'Invalid';
                    }
                    return null;
                  }
                  : null,
          onChanged: (value) {
            if (value.contains('"')) {
              controller.text = value.replaceAll('"', '');
              controller.selection = TextSelection.fromPosition(
                TextPosition(offset: controller.text.length),
              );
            }
          },
        ),
      ],
    );
  }

  Widget _buildCompactTextField({
    required TextEditingController controller,
    required String englishLabel,
    required String arabicLabel,
    required IconData icon,
    bool required = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          englishLabel,
          style: InventoryDesignConfig.labelLarge.copyWith(
            color: InventoryDesignConfig.textPrimary,
            fontWeight: FontWeight.w600,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: InventoryDesignConfig.spacingS),
        TextFormField(
          controller: controller,
          style: InventoryDesignConfig.bodyLarge.copyWith(
            color: InventoryDesignConfig.textPrimary,
          ),
          decoration: InputDecoration(
            prefixIcon: Icon(
              icon,
              size: 18,
              color: InventoryDesignConfig.textSecondary,
            ),
            hintText: arabicLabel,
            hintStyle: InventoryDesignConfig.bodyMedium.copyWith(
              color: InventoryDesignConfig.textTertiary,
            ),
            filled: true,
            fillColor: InventoryDesignConfig.surfaceLight,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(
                InventoryDesignConfig.radiusS,
              ),
              borderSide: BorderSide(
                color: InventoryDesignConfig.borderPrimary,
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(
                InventoryDesignConfig.radiusS,
              ),
              borderSide: BorderSide(
                color: InventoryDesignConfig.borderPrimary,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(
                InventoryDesignConfig.radiusS,
              ),
              borderSide: BorderSide(
                color: InventoryDesignConfig.primaryColor,
                width: 2.0,
              ),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(
                InventoryDesignConfig.radiusS,
              ),
              borderSide: BorderSide(
                color: InventoryDesignConfig.errorColor,
                width: 2.0,
              ),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(
                InventoryDesignConfig.radiusS,
              ),
              borderSide: BorderSide(
                color: InventoryDesignConfig.errorColor,
                width: 2.0,
              ),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: InventoryDesignConfig.spacingL,
              vertical: InventoryDesignConfig.spacingM,
            ),
          ),
          validator:
              required
                  ? (value) => value?.isEmpty ?? true ? 'Required' : null
                  : null,
        ),
      ],
    );
  }

  Widget _buildDropdown<T>({
    required T? value,
    required String label,
    String? arabicLabel,
    required IconData icon,
    required List<DropdownMenuItem<T>> items,
    required ValueChanged<T?> onChanged,
    String? Function(T?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: InventoryDesignConfig.labelLarge.copyWith(
            color: InventoryDesignConfig.textPrimary,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: InventoryDesignConfig.spacingS),
        DropdownButtonFormField<T>(
          value: value,
          validator: validator,
          style: InventoryDesignConfig.bodyLarge.copyWith(
            color: InventoryDesignConfig.textPrimary,
          ),
          dropdownColor: InventoryDesignConfig.surfaceColor,
          decoration: InputDecoration(
            hintText: arabicLabel,
            hintStyle: InventoryDesignConfig.bodyMedium.copyWith(
              color: InventoryDesignConfig.textTertiary,
            ),
            prefixIcon: Icon(
              icon,
              size: 18,
              color: InventoryDesignConfig.textSecondary,
            ),
            filled: true,
            fillColor: InventoryDesignConfig.surfaceLight,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(
                InventoryDesignConfig.radiusM,
              ),
              borderSide: BorderSide(
                color: InventoryDesignConfig.borderPrimary,
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(
                InventoryDesignConfig.radiusM,
              ),
              borderSide: BorderSide(
                color: InventoryDesignConfig.borderPrimary,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(
                InventoryDesignConfig.radiusM,
              ),
              borderSide: BorderSide(
                color: InventoryDesignConfig.primaryColor,
                width: 2.0,
              ),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(
                InventoryDesignConfig.radiusM,
              ),
              borderSide: BorderSide(
                color: InventoryDesignConfig.errorColor,
                width: 2.0,
              ),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(
                InventoryDesignConfig.radiusM,
              ),
              borderSide: BorderSide(
                color: InventoryDesignConfig.errorColor,
                width: 2.0,
              ),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: InventoryDesignConfig.spacingL,
              vertical: InventoryDesignConfig.spacingM,
            ),
          ),
          items:
              items.map((item) {
                return DropdownMenuItem<T>(
                  value: item.value,
                  child: Text(
                    item.child is Text
                        ? (item.child as Text).data ?? ''
                        : item.value.toString(),
                    style: InventoryDesignConfig.bodyLarge,
                  ),
                );
              }).toList(),
          onChanged: onChanged,
          icon: Icon(
            PhosphorIcons.caretDown(),
            size: 16,
            color: InventoryDesignConfig.textSecondary,
          ),
        ),
      ],
    );
  }
}

class _MeasurementField {
  final TextEditingController controller;
  final String label;
  final String arabicLabel; // Added
  final IconData icon;
  final bool required;
  final bool isHighlighted;
  final bool isTextField;

  _MeasurementField({
    required this.controller,
    required this.label,
    required this.arabicLabel, // Added
    required this.icon,
    this.required = false,
    this.isHighlighted = false,
    this.isTextField = false,
  });
}

class _StyleField {
  final TextEditingController controller;
  final String label;
  final String arabicLabel; // Added
  final IconData icon;

  _StyleField({
    required this.controller,
    required this.label,
    required this.arabicLabel, // Added
    required this.icon,
  });
}
