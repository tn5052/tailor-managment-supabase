import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:uuid/uuid.dart';
import '../../../models/measurement.dart';
import '../../../models/customer.dart';
import '../../../services/measurement_service.dart';
import '../../../services/customer_service.dart';
import '../../../utils/fraction_helper.dart';
import '../../../theme/inventory_design_config.dart';
import '../../customer/mobile/customer_selector_mobile.dart';

class AddMeasurementMobileSheet extends StatefulWidget {
  final VoidCallback? onMeasurementAdded;

  const AddMeasurementMobileSheet({super.key, this.onMeasurementAdded});

  static Future<void> show(
    BuildContext context, {
    VoidCallback? onMeasurementAdded,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      useSafeArea: true,
      builder:
          (context) =>
              AddMeasurementMobileSheet(onMeasurementAdded: onMeasurementAdded),
    );
  }

  @override
  State<AddMeasurementMobileSheet> createState() =>
      _AddMeasurementMobileSheetState();
}

class _AddMeasurementMobileSheetState extends State<AddMeasurementMobileSheet> {
  final MeasurementService _measurementService = MeasurementService();
  final SupabaseService _supabaseService = SupabaseService();
  final _formKey = GlobalKey<FormState>();
  final _pageController = PageController();

  bool _isLoading = false;
  int _currentPage = 0;

  // All Controllers from desktop version
  late final TextEditingController _lengthArabiController;
  late final TextEditingController _lengthKuwaitiController;
  late final TextEditingController _chestController;
  late final TextEditingController _widthController;
  late final TextEditingController _sleeveController;
  late final TextEditingController _collarStartController;
  late final TextEditingController _collarCenterController;
  late final TextEditingController _collarEndController;
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
  late final TextEditingController _fabricNameController;

  Customer? _selectedCustomer;
  String? _selectedStyle;
  String _selectedDesignType = 'Aadi';
  String _selectedTarbooshType = 'Fixed';

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
    _selectedStyle = _styleOptions[0];
  }

  void _initializeControllers() {
    _lengthArabiController = TextEditingController();
    _lengthKuwaitiController = TextEditingController();
    _chestController = TextEditingController();
    _widthController = TextEditingController();
    _sleeveController = TextEditingController();
    _collarStartController = TextEditingController();
    _collarCenterController = TextEditingController();
    _collarEndController = TextEditingController();
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
    _fabricNameController = TextEditingController();
  }

  @override
  void dispose() {
    _lengthArabiController.dispose();
    _lengthKuwaitiController.dispose();
    _chestController.dispose();
    _widthController.dispose();
    _sleeveController.dispose();
    _collarStartController.dispose();
    _collarCenterController.dispose();
    _collarEndController.dispose();
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
    _fabricNameController.dispose();
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _selectCustomer() async {
    final customers = await _supabaseService.getAllCustomers();
    final customer = await CustomerSelectorMobile.show(context, customers);
    if (customer != null) {
      setState(() => _selectedCustomer = customer);
    }
  }

  void _nextPage() {
    if (_canProceedToNextPage()) {
      if (_currentPage < 4) {
        _pageController.nextPage(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
      }
    }
  }

  void _previousPage() {
    if (_currentPage > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  bool _canProceedToNextPage() {
    switch (_currentPage) {
      case 0: // Customer & Style
        return _selectedCustomer != null && _selectedStyle != null;
      case 1: // Key Measurements
        return _chestController.text.isNotEmpty &&
            _widthController.text.isNotEmpty &&
            ((_selectedStyle == 'Emirati' &&
                    _lengthArabiController.text.isNotEmpty) ||
                (_selectedStyle != 'Emirati' &&
                    _lengthKuwaitiController.text.isNotEmpty));
      default:
        return true;
    }
  }

  Future<void> _saveMeasurement() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedCustomer == null) {
      _showError('Please select a customer');
      return;
    }

    setState(() => _isLoading = true);

    try {
      final measurement = Measurement(
        id: const Uuid().v4(),
        customerId: _selectedCustomer!.id,
        billNumber: _selectedCustomer!.billNumber,
        style: _selectedStyle!,
        lengthArabi: FractionHelper.parseFraction(_lengthArabiController.text),
        lengthKuwaiti: FractionHelper.parseFraction(
          _lengthKuwaitiController.text,
        ),
        chest: FractionHelper.parseFraction(_chestController.text),
        width: FractionHelper.parseFraction(_widthController.text),
        sleeve: FractionHelper.parseFraction(_sleeveController.text),
        collar: {
          'start': FractionHelper.parseFraction(_collarStartController.text),
          'center': FractionHelper.parseFraction(_collarCenterController.text),
          'end': FractionHelper.parseFraction(_collarEndController.text),
        },
        under: FractionHelper.parseFraction(_underController.text),
        backLength: FractionHelper.parseFraction(_backLengthController.text),
        neck: FractionHelper.parseFraction(_neckController.text),
        shoulder: FractionHelper.parseFraction(_shoulderController.text),
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
        fabricName: _fabricNameController.text,
        designType: _selectedDesignType,
        tarbooshType: _selectedTarbooshType,
        date: DateTime.now(),
        lastUpdated: DateTime.now(),
      );

      await _measurementService.addMeasurement(measurement);

      if (mounted) {
        Navigator.of(context).pop();
        widget.onMeasurementAdded?.call();

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Measurement added successfully'),
            backgroundColor: InventoryDesignConfig.successColor,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        _showError('Error: $e');
      }
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: InventoryDesignConfig.errorColor,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.95,
      decoration: BoxDecoration(
        color: InventoryDesignConfig.surfaceColor,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(InventoryDesignConfig.radiusXL),
        ),
      ),
      child: Column(
        children: [
          _buildHeader(),
          _buildProgressIndicator(),
          Expanded(child: _buildContent()),
          _buildFooter(),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(InventoryDesignConfig.spacingL),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: InventoryDesignConfig.borderSecondary),
        ),
      ),
      child: Column(
        children: [
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: InventoryDesignConfig.borderPrimary,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: InventoryDesignConfig.spacingL),
          Row(
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
                  size: 20,
                  color: InventoryDesignConfig.primaryColor,
                ),
              ),
              const SizedBox(width: InventoryDesignConfig.spacingM),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Add Measurement',
                      style: InventoryDesignConfig.headlineMedium.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      _getStepTitle(),
                      style: InventoryDesignConfig.bodySmall.copyWith(
                        color: InventoryDesignConfig.textSecondary,
                      ),
                    ),
                  ],
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
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: InventoryDesignConfig.surfaceLight,
                      borderRadius: BorderRadius.circular(
                        InventoryDesignConfig.radiusM,
                      ),
                    ),
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
        ],
      ),
    );
  }

  String _getStepTitle() {
    switch (_currentPage) {
      case 0:
        return 'Step 1: Customer & Style';
      case 1:
        return 'Step 2: Key Measurements';
      case 2:
        return 'Step 3: Additional Measurements';
      case 3:
        return 'Step 4: Style Details';
      case 4:
        return 'Step 5: Review & Save';
      default:
        return 'Add new measurement';
    }
  }

  Widget _buildProgressIndicator() {
    return Container(
      padding: const EdgeInsets.all(InventoryDesignConfig.spacingL),
      child: Row(
        children: List.generate(5, (index) {
          final isActive = index <= _currentPage;
          final isCompleted = index < _currentPage;

          return Expanded(
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    height: 4,
                    decoration: BoxDecoration(
                      color:
                          isActive
                              ? InventoryDesignConfig.primaryColor
                              : InventoryDesignConfig.borderPrimary,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                if (index < 4)
                  const SizedBox(width: InventoryDesignConfig.spacingS),
              ],
            ),
          );
        }),
      ),
    );
  }

  Widget _buildContent() {
    return Form(
      key: _formKey,
      child: PageView(
        controller: _pageController,
        onPageChanged: (page) => setState(() => _currentPage = page),
        children: [
          _buildCustomerSelectionPage(),
          _buildKeyMeasurementsPage(),
          _buildAdditionalMeasurementsPage(),
          _buildStyleDetailsPage(),
          _buildReviewPage(),
        ],
      ),
    );
  }

  Widget _buildCustomerSelectionPage() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(InventoryDesignConfig.spacingL),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Customer & Style Information',
            style: InventoryDesignConfig.titleLarge.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: InventoryDesignConfig.spacingL),

          // Customer Selection
          _buildSectionCard(
            title: 'Customer',
            icon: PhosphorIcons.user(),
            child:
                _selectedCustomer != null
                    ? _buildSelectedCustomerCard()
                    : _buildCustomerSelectorButton(),
          ),

          const SizedBox(height: InventoryDesignConfig.spacingL),

          // Style Selection
          _buildSectionCard(
            title: 'Style',
            icon: PhosphorIcons.star(),
            child: _buildStyleSelector(),
          ),

          const SizedBox(height: InventoryDesignConfig.spacingL),

          // Design Type
          _buildSectionCard(
            title: 'Design Type',
            icon: PhosphorIcons.palette(),
            child: _buildDesignTypeSelector(),
          ),

          const SizedBox(height: InventoryDesignConfig.spacingL),

          // Tarboosh Type
          _buildSectionCard(
            title: 'Tarboosh Type',
            icon: PhosphorIcons.crown(),
            child: _buildTarbooshTypeSelector(),
          ),

          const SizedBox(height: InventoryDesignConfig.spacingL),

          // Fabric Name
          _buildSectionCard(
            title: 'Fabric Details',
            icon: PhosphorIcons.scissors(),
            child: _buildTextField(
              controller: _fabricNameController,
              label: 'Fabric Name (Optional)',
              hint: 'Enter fabric name or type',
              arabicHint: 'اسم القماش',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildKeyMeasurementsPage() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(InventoryDesignConfig.spacingL),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Key Measurements',
            style: InventoryDesignConfig.titleLarge.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          Text(
            'Essential measurements required for ${_selectedStyle ?? 'the garment'}',
            style: InventoryDesignConfig.bodyMedium.copyWith(
              color: InventoryDesignConfig.textSecondary,
            ),
          ),
          const SizedBox(height: InventoryDesignConfig.spacingL),

          _buildSectionCard(
            title: 'Primary Measurements',
            icon: PhosphorIcons.ruler(),
            child: Column(
              children: [
                // Length based on style
                _buildMeasurementField(
                  controller:
                      _selectedStyle == 'Emirati'
                          ? _lengthArabiController
                          : _lengthKuwaitiController,
                  label:
                      _selectedStyle == 'Emirati'
                          ? 'Length (Arabic)'
                          : 'Length (Kuwaiti)',
                  arabicLabel:
                      _selectedStyle == 'Emirati' ? 'طول عربي' : 'طول كويتي',
                  icon: PhosphorIcons.arrowsVertical(),
                  required: true,
                  isHighlighted: true,
                ),
                const SizedBox(height: InventoryDesignConfig.spacingM),
                _buildMeasurementField(
                  controller: _chestController,
                  label: 'Chest',
                  arabicLabel: 'صدر',
                  icon: PhosphorIcons.circleHalf(),
                  required: true,
                  isHighlighted: true,
                ),
                const SizedBox(height: InventoryDesignConfig.spacingM),
                _buildMeasurementField(
                  controller: _widthController,
                  label: 'Width',
                  arabicLabel: 'عرض',
                  icon: PhosphorIcons.arrowsHorizontal(),
                  required: true,
                  isHighlighted: true,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAdditionalMeasurementsPage() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(InventoryDesignConfig.spacingL),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Additional Measurements',
            style: InventoryDesignConfig.titleLarge.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          Text(
            'Optional measurements for better fitting',
            style: InventoryDesignConfig.bodyMedium.copyWith(
              color: InventoryDesignConfig.textSecondary,
            ),
          ),
          const SizedBox(height: InventoryDesignConfig.spacingL),

          _buildSectionCard(
            title: 'Body Measurements',
            icon: PhosphorIcons.person(),
            child: Column(
              children: [
                _buildMeasurementField(
                  controller: _backLengthController,
                  label: 'Back Length',
                  arabicLabel: 'طول خلفي',
                  icon: PhosphorIcons.arrowUp(),
                ),
                const SizedBox(height: InventoryDesignConfig.spacingM),
                _buildCollarInput(),
                const SizedBox(height: InventoryDesignConfig.spacingM),
                _buildMeasurementField(
                  controller: _shoulderController,
                  label: 'Shoulder',
                  arabicLabel: 'كتف',
                  icon: PhosphorIcons.arrowsOutLineHorizontal(),
                ),
              ],
            ),
          ),

          const SizedBox(height: InventoryDesignConfig.spacingL),

          _buildSectionCard(
            title: 'Sleeve Measurements',
            icon: PhosphorIcons.tShirt(),
            child: Column(
              children: [
                _buildMeasurementField(
                  controller: _sleeveController,
                  label: 'Sleeve Length',
                  arabicLabel: 'كم',
                  icon: PhosphorIcons.arrowLineRight(),
                ),
                const SizedBox(height: InventoryDesignConfig.spacingM),
                _buildMeasurementField(
                  controller: _neckController,
                  label: 'Sleeve Fitting',
                  arabicLabel: 'فكم',
                  icon: PhosphorIcons.circleNotch(),
                ),
                const SizedBox(height: InventoryDesignConfig.spacingM),
                _buildMeasurementField(
                  controller: _underController,
                  label: 'Under Shoulder',
                  arabicLabel: 'تحت الكتف',
                  icon: PhosphorIcons.arrowDown(),
                ),
              ],
            ),
          ),

          const SizedBox(height: InventoryDesignConfig.spacingL),

          _buildSectionCard(
            title: 'Construction Details',
            icon: PhosphorIcons.gear(),
            child: Column(
              children: [
                _buildTextField(
                  controller: _seamController,
                  label: 'Side Seam',
                  hint: 'Side seam details',
                  arabicHint: 'شيب',
                ),
                const SizedBox(height: InventoryDesignConfig.spacingM),
                _buildTextField(
                  controller: _adhesiveController,
                  label: 'Adhesive',
                  hint: 'Adhesive details',
                  arabicHint: 'چسبا',
                ),
                const SizedBox(height: InventoryDesignConfig.spacingM),
                _buildTextField(
                  controller: _underKanduraController,
                  label: 'Under Kandura',
                  hint: 'Under kandura details',
                  arabicHint: 'تحت كندورة',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStyleDetailsPage() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(InventoryDesignConfig.spacingL),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Style Details',
            style: InventoryDesignConfig.titleLarge.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          Text(
            'Customize the finishing and style elements',
            style: InventoryDesignConfig.bodyMedium.copyWith(
              color: InventoryDesignConfig.textSecondary,
            ),
          ),
          const SizedBox(height: InventoryDesignConfig.spacingL),

          _buildSectionCard(
            title: 'Finishing Details',
            icon: PhosphorIcons.paintBrush(),
            child: Column(
              children: [
                _buildTextField(
                  controller: _openSleeveController,
                  label: 'Sleeve Opening',
                  hint: 'Sleeve opening style',
                  arabicHint: 'كم سلائی',
                ),
                const SizedBox(height: InventoryDesignConfig.spacingM),
                _buildTextField(
                  controller: _stitchingController,
                  label: 'Stitching Style',
                  hint: 'Stitching details',
                  arabicHint: 'خياطة',
                ),
                const SizedBox(height: InventoryDesignConfig.spacingM),
                _buildTextField(
                  controller: _pleatController,
                  label: 'Pleat Style',
                  hint: 'Pleat details',
                  arabicHint: 'كسرة',
                ),
              ],
            ),
          ),

          const SizedBox(height: InventoryDesignConfig.spacingL),

          _buildSectionCard(
            title: 'Decorative Elements',
            icon: PhosphorIcons.flower(),
            child: Column(
              children: [
                _buildTextField(
                  controller: _buttonController,
                  label: 'Side Pocket',
                  hint: 'Pocket details',
                  arabicHint: 'بتى',
                ),
                const SizedBox(height: InventoryDesignConfig.spacingM),
                _buildTextField(
                  controller: _cuffController,
                  label: 'Cuff Style',
                  hint: 'Cuff details',
                  arabicHint: 'كف',
                ),
                const SizedBox(height: InventoryDesignConfig.spacingM),
                _buildTextField(
                  controller: _embroideryController,
                  label: 'Embroidery',
                  hint: 'Embroidery details',
                  arabicHint: 'تطريز',
                ),
                const SizedBox(height: InventoryDesignConfig.spacingM),
                _buildTextField(
                  controller: _neckStyleController,
                  label: 'Neck Style',
                  hint: 'Neck style details',
                  arabicHint: 'رقبة',
                ),
              ],
            ),
          ),

          const SizedBox(height: InventoryDesignConfig.spacingL),

          _buildSectionCard(
            title: 'Additional Notes',
            icon: PhosphorIcons.note(),
            child: TextFormField(
              controller: _notesController,
              maxLines: 4,
              style: InventoryDesignConfig.bodyLarge,
              decoration: InputDecoration(
                hintText: 'Add any special instructions or notes...',
                hintStyle: InventoryDesignConfig.bodyMedium.copyWith(
                  color: InventoryDesignConfig.textTertiary,
                ),
                border: InputBorder.none,
                contentPadding: EdgeInsets.zero,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReviewPage() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(InventoryDesignConfig.spacingL),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Review & Confirm',
            style: InventoryDesignConfig.titleLarge.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          Text(
            'Please review all information before saving',
            style: InventoryDesignConfig.bodyMedium.copyWith(
              color: InventoryDesignConfig.textSecondary,
            ),
          ),
          const SizedBox(height: InventoryDesignConfig.spacingL),

          if (_selectedCustomer != null) ...[
            _buildReviewSection(
              title: 'Customer',
              icon: PhosphorIcons.user(),
              content: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _selectedCustomer!.name,
                    style: InventoryDesignConfig.titleMedium,
                  ),
                  Text(
                    'Bill #${_selectedCustomer!.billNumber}',
                    style: InventoryDesignConfig.bodySmall.copyWith(
                      color: InventoryDesignConfig.textSecondary,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: InventoryDesignConfig.spacingL),
          ],

          _buildReviewSection(
            title: 'Style Information',
            icon: PhosphorIcons.star(),
            content: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Style: $_selectedStyle',
                  style: InventoryDesignConfig.bodyMedium,
                ),
                Text(
                  'Design: $_selectedDesignType',
                  style: InventoryDesignConfig.bodyMedium,
                ),
                Text(
                  'Tarboosh: $_selectedTarbooshType',
                  style: InventoryDesignConfig.bodyMedium,
                ),
                if (_fabricNameController.text.isNotEmpty)
                  Text(
                    'Fabric: ${_fabricNameController.text}',
                    style: InventoryDesignConfig.bodyMedium,
                  ),
              ],
            ),
          ),

          const SizedBox(height: InventoryDesignConfig.spacingL),

          _buildReviewSection(
            title: 'Key Measurements',
            icon: PhosphorIcons.ruler(),
            content: Column(children: _getKeyMeasurementsForReview()),
          ),

          if (_getAdditionalMeasurementsForReview().isNotEmpty) ...[
            const SizedBox(height: InventoryDesignConfig.spacingL),
            _buildReviewSection(
              title: 'Additional Measurements',
              icon: PhosphorIcons.listDashes(),
              content: Column(children: _getAdditionalMeasurementsForReview()),
            ),
          ],

          if (_getStyleDetailsForReview().isNotEmpty) ...[
            const SizedBox(height: InventoryDesignConfig.spacingL),
            _buildReviewSection(
              title: 'Style Details',
              icon: PhosphorIcons.palette(),
              content: Column(children: _getStyleDetailsForReview()),
            ),
          ],

          if (_notesController.text.isNotEmpty) ...[
            const SizedBox(height: InventoryDesignConfig.spacingL),
            _buildReviewSection(
              title: 'Notes',
              icon: PhosphorIcons.note(),
              content: Text(
                _notesController.text,
                style: InventoryDesignConfig.bodyMedium,
              ),
            ),
          ],
        ],
      ),
    );
  }

  List<Widget> _getKeyMeasurementsForReview() {
    final measurements = <Widget>[];

    if (_selectedStyle == 'Emirati' && _lengthArabiController.text.isNotEmpty) {
      measurements.add(
        _buildReviewMeasurement('Length (Arabic)', _lengthArabiController.text),
      );
    } else if (_selectedStyle != 'Emirati' &&
        _lengthKuwaitiController.text.isNotEmpty) {
      measurements.add(
        _buildReviewMeasurement(
          'Length (Kuwaiti)',
          _lengthKuwaitiController.text,
        ),
      );
    }

    if (_chestController.text.isNotEmpty) {
      measurements.add(_buildReviewMeasurement('Chest', _chestController.text));
    }
    if (_widthController.text.isNotEmpty) {
      measurements.add(_buildReviewMeasurement('Width', _widthController.text));
    }

    return measurements;
  }

  List<Widget> _getAdditionalMeasurementsForReview() {
    final measurements = <Widget>[];

    if (_backLengthController.text.isNotEmpty) {
      measurements.add(
        _buildReviewMeasurement('Back Length', _backLengthController.text),
      );
    }
    if (_collarStartController.text.isNotEmpty ||
        _collarCenterController.text.isNotEmpty ||
        _collarEndController.text.isNotEmpty) {
      final parts = [
        _collarStartController.text,
        _collarCenterController.text,
        _collarEndController.text,
      ].where((s) => s.isNotEmpty).map((s) => '$s"').join(' - ');
      measurements.add(_buildReviewMeasurement('Collar Size', parts));
    }
    if (_shoulderController.text.isNotEmpty) {
      measurements.add(
        _buildReviewMeasurement('Shoulder', _shoulderController.text),
      );
    }
    if (_sleeveController.text.isNotEmpty) {
      measurements.add(
        _buildReviewMeasurement('Sleeve Length', _sleeveController.text),
      );
    }
    if (_neckController.text.isNotEmpty) {
      measurements.add(
        _buildReviewMeasurement('Sleeve Fitting', _neckController.text),
      );
    }
    if (_underController.text.isNotEmpty) {
      measurements.add(
        _buildReviewMeasurement('Under Shoulder', _underController.text),
      );
    }

    return measurements;
  }

  List<Widget> _getStyleDetailsForReview() {
    final details = <Widget>[];

    final textFields = [
      (_seamController, 'Side Seam'),
      (_adhesiveController, 'Adhesive'),
      (_underKanduraController, 'Under Kandura'),
      (_openSleeveController, 'Sleeve Opening'),
      (_stitchingController, 'Stitching Style'),
      (_pleatController, 'Pleat Style'),
      (_buttonController, 'Side Pocket'),
      (_cuffController, 'Cuff Style'),
      (_embroideryController, 'Embroidery'),
      (_neckStyleController, 'Neck Style'),
    ];

    for (final (controller, label) in textFields) {
      if (controller.text.isNotEmpty) {
        details.add(_buildReviewTextField(label, controller.text));
      }
    }

    return details;
  }

  Widget _buildFooter() {
    return Container(
      padding: EdgeInsets.fromLTRB(
        InventoryDesignConfig.spacingL,
        InventoryDesignConfig.spacingL,
        InventoryDesignConfig.spacingL,
        InventoryDesignConfig.spacingL + MediaQuery.of(context).padding.bottom,
      ),
      decoration: BoxDecoration(
        color: InventoryDesignConfig.surfaceColor,
        border: Border(
          top: BorderSide(color: InventoryDesignConfig.borderSecondary),
        ),
      ),
      child: Row(
        children: [
          if (_currentPage > 0)
            Expanded(
              child: _buildFooterButton(
                label: 'Back',
                onPressed: _previousPage,
                isPrimary: false,
              ),
            ),
          if (_currentPage > 0)
            const SizedBox(width: InventoryDesignConfig.spacingM),
          Expanded(
            flex: _currentPage == 0 ? 1 : 2,
            child: _buildFooterButton(
              label: _currentPage == 4 ? 'Save Measurement' : 'Next',
              onPressed: _currentPage == 4 ? _saveMeasurement : _nextPage,
              isPrimary: true,
              isLoading: _isLoading && _currentPage == 4,
              isEnabled: _currentPage == 4 ? true : _canProceedToNextPage(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFooterButton({
    required String label,
    required VoidCallback onPressed,
    required bool isPrimary,
    bool isLoading = false,
    bool isEnabled = true,
  }) {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(InventoryDesignConfig.radiusM),
      child: InkWell(
        onTap: isLoading || !isEnabled ? null : onPressed,
        borderRadius: BorderRadius.circular(InventoryDesignConfig.radiusM),
        child: Container(
          padding: const EdgeInsets.symmetric(
            vertical: InventoryDesignConfig.spacingL,
          ),
          decoration: BoxDecoration(
            color:
                isPrimary
                    ? (isEnabled
                        ? InventoryDesignConfig.primaryColor
                        : InventoryDesignConfig.primaryColor.withOpacity(0.5))
                    : InventoryDesignConfig.surfaceLight,
            borderRadius: BorderRadius.circular(InventoryDesignConfig.radiusM),
            border: Border.all(
              color:
                  isPrimary
                      ? (isEnabled
                          ? InventoryDesignConfig.primaryColor
                          : InventoryDesignConfig.primaryColor.withOpacity(0.5))
                      : InventoryDesignConfig.borderPrimary,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (isLoading)
                SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: InventoryDesignConfig.surfaceColor,
                  ),
                )
              else
                Icon(
                  _currentPage == 4
                      ? PhosphorIcons.check()
                      : (_currentPage > 0 && !isPrimary
                          ? PhosphorIcons.arrowLeft()
                          : PhosphorIcons.arrowRight()),
                  size: 18,
                  color:
                      isPrimary
                          ? InventoryDesignConfig.surfaceColor
                          : InventoryDesignConfig.textSecondary,
                ),
              const SizedBox(width: InventoryDesignConfig.spacingS),
              Text(
                isLoading ? 'Saving...' : label,
                style: InventoryDesignConfig.bodyMedium.copyWith(
                  color:
                      isPrimary
                          ? InventoryDesignConfig.surfaceColor
                          : InventoryDesignConfig.textSecondary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Helper widget builders
  Widget _buildSectionCard({
    required String title,
    required IconData icon,
    required Widget child,
  }) {
    return Container(
      width: double.infinity,
      decoration: InventoryDesignConfig.cardDecoration,
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
                    fontWeight: FontWeight.w600,
                    color: InventoryDesignConfig.primaryColor,
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(InventoryDesignConfig.spacingL),
            child: child,
          ),
        ],
      ),
    );
  }

  Widget _buildSelectedCustomerCard() {
    return Container(
      padding: const EdgeInsets.all(InventoryDesignConfig.spacingM),
      decoration: BoxDecoration(
        color: InventoryDesignConfig.surfaceLight,
        borderRadius: BorderRadius.circular(InventoryDesignConfig.radiusM),
        border: Border.all(color: InventoryDesignConfig.borderPrimary),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 20,
            backgroundColor: InventoryDesignConfig.primaryColor.withOpacity(
              0.1,
            ),
            child: Text(
              _selectedCustomer!.name[0].toUpperCase(),
              style: InventoryDesignConfig.bodyMedium.copyWith(
                color: InventoryDesignConfig.primaryColor,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(width: InventoryDesignConfig.spacingM),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _selectedCustomer!.name,
                  style: InventoryDesignConfig.titleMedium,
                ),
                Text(
                  'Bill #${_selectedCustomer!.billNumber}',
                  style: InventoryDesignConfig.bodySmall.copyWith(
                    color: InventoryDesignConfig.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () => setState(() => _selectedCustomer = null),
            icon: Icon(
              PhosphorIcons.x(),
              color: InventoryDesignConfig.errorColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCustomerSelectorButton() {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(InventoryDesignConfig.radiusM),
      child: InkWell(
        onTap: _selectCustomer,
        borderRadius: BorderRadius.circular(InventoryDesignConfig.radiusM),
        child: Container(
          padding: const EdgeInsets.all(InventoryDesignConfig.spacingL),
          decoration: BoxDecoration(
            color: InventoryDesignConfig.surfaceLight,
            borderRadius: BorderRadius.circular(InventoryDesignConfig.radiusM),
            border: Border.all(color: InventoryDesignConfig.borderPrimary),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                PhosphorIcons.userPlus(),
                color: InventoryDesignConfig.primaryColor,
              ),
              const SizedBox(width: InventoryDesignConfig.spacingS),
              Text(
                'Select Customer',
                style: InventoryDesignConfig.bodyMedium.copyWith(
                  color: InventoryDesignConfig.primaryColor,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStyleSelector() {
    return Wrap(
      spacing: InventoryDesignConfig.spacingM,
      runSpacing: InventoryDesignConfig.spacingM,
      children:
          _styleOptions.map((style) {
            final isSelected = _selectedStyle == style;
            return Material(
              color: Colors.transparent,
              borderRadius: BorderRadius.circular(
                InventoryDesignConfig.radiusM,
              ),
              child: InkWell(
                onTap: () => setState(() => _selectedStyle = style),
                borderRadius: BorderRadius.circular(
                  InventoryDesignConfig.radiusM,
                ),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: InventoryDesignConfig.spacingL,
                    vertical: InventoryDesignConfig.spacingM,
                  ),
                  decoration: BoxDecoration(
                    color:
                        isSelected
                            ? InventoryDesignConfig.primaryColor
                            : InventoryDesignConfig.surfaceLight,
                    borderRadius: BorderRadius.circular(
                      InventoryDesignConfig.radiusM,
                    ),
                    border: Border.all(
                      color:
                          isSelected
                              ? InventoryDesignConfig.primaryColor
                              : InventoryDesignConfig.borderPrimary,
                    ),
                  ),
                  child: Text(
                    style,
                    style: InventoryDesignConfig.bodyMedium.copyWith(
                      color:
                          isSelected
                              ? InventoryDesignConfig.surfaceColor
                              : InventoryDesignConfig.textPrimary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
    );
  }

  Widget _buildDesignTypeSelector() {
    return Row(
      children:
          _designOptions.map((design) {
            final isSelected = _selectedDesignType == design;
            return Expanded(
              child: Padding(
                padding: EdgeInsets.only(
                  right:
                      design != _designOptions.last
                          ? InventoryDesignConfig.spacingM
                          : 0,
                ),
                child: Material(
                  color: Colors.transparent,
                  borderRadius: BorderRadius.circular(
                    InventoryDesignConfig.radiusM,
                  ),
                  child: InkWell(
                    onTap: () => setState(() => _selectedDesignType = design),
                    borderRadius: BorderRadius.circular(
                      InventoryDesignConfig.radiusM,
                    ),
                    child: Container(
                      padding: const EdgeInsets.all(
                        InventoryDesignConfig.spacingL,
                      ),
                      decoration: BoxDecoration(
                        color:
                            isSelected
                                ? InventoryDesignConfig.primaryColor
                                    .withOpacity(0.1)
                                : InventoryDesignConfig.surfaceLight,
                        borderRadius: BorderRadius.circular(
                          InventoryDesignConfig.radiusM,
                        ),
                        border: Border.all(
                          color:
                              isSelected
                                  ? InventoryDesignConfig.primaryColor
                                  : InventoryDesignConfig.borderPrimary,
                        ),
                      ),
                      child: Text(
                        design,
                        textAlign: TextAlign.center,
                        style: InventoryDesignConfig.bodyMedium.copyWith(
                          color:
                              isSelected
                                  ? InventoryDesignConfig.primaryColor
                                  : InventoryDesignConfig.textPrimary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
    );
  }

  Widget _buildTarbooshTypeSelector() {
    return Row(
      children:
          _tarbooshOptions.map((tarboosh) {
            final isSelected = _selectedTarbooshType == tarboosh;
            return Expanded(
              child: Padding(
                padding: EdgeInsets.only(
                  right:
                      tarboosh != _tarbooshOptions.last
                          ? InventoryDesignConfig.spacingM
                          : 0,
                ),
                child: Material(
                  color: Colors.transparent,
                  borderRadius: BorderRadius.circular(
                    InventoryDesignConfig.radiusM,
                  ),
                  child: InkWell(
                    onTap:
                        () => setState(() => _selectedTarbooshType = tarboosh),
                    borderRadius: BorderRadius.circular(
                      InventoryDesignConfig.radiusM,
                    ),
                    child: Container(
                      padding: const EdgeInsets.all(
                        InventoryDesignConfig.spacingL,
                      ),
                      decoration: BoxDecoration(
                        color:
                            isSelected
                                ? InventoryDesignConfig.primaryColor
                                    .withOpacity(0.1)
                                : InventoryDesignConfig.surfaceLight,
                        borderRadius: BorderRadius.circular(
                          InventoryDesignConfig.radiusM,
                        ),
                        border: Border.all(
                          color:
                              isSelected
                                  ? InventoryDesignConfig.primaryColor
                                  : InventoryDesignConfig.borderPrimary,
                        ),
                      ),
                      child: Text(
                        tarboosh,
                        textAlign: TextAlign.center,
                        style: InventoryDesignConfig.bodyMedium.copyWith(
                          color:
                              isSelected
                                  ? InventoryDesignConfig.primaryColor
                                  : InventoryDesignConfig.textPrimary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
    );
  }

  Widget _buildMeasurementField({
    required TextEditingController controller,
    required String label,
    required String arabicLabel,
    required IconData icon,
    bool required = false,
    bool isHighlighted = false,
  }) {
    return Container(
      decoration: BoxDecoration(
        color:
            isHighlighted
                ? InventoryDesignConfig.primaryColor.withOpacity(0.05)
                : Colors.transparent,
        borderRadius: BorderRadius.circular(InventoryDesignConfig.radiusM),
        border:
            isHighlighted
                ? Border.all(
                  color: InventoryDesignConfig.primaryColor.withOpacity(0.2),
                )
                : null,
      ),
      padding:
          isHighlighted
              ? const EdgeInsets.all(InventoryDesignConfig.spacingM)
              : EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (isHighlighted)
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: InventoryDesignConfig.primaryColor,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Icon(
                    PhosphorIcons.star(),
                    size: 12,
                    color: InventoryDesignConfig.surfaceColor,
                  ),
                ),
              if (isHighlighted)
                const SizedBox(width: InventoryDesignConfig.spacingS),
              Expanded(
                child: Text(
                  label + (required ? ' *' : ''),
                  style: InventoryDesignConfig.labelLarge.copyWith(
                    color:
                        isHighlighted
                            ? InventoryDesignConfig.primaryColor
                            : InventoryDesignConfig.textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Text(
                arabicLabel,
                style: InventoryDesignConfig.bodySmall.copyWith(
                  color: InventoryDesignConfig.textSecondary,
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
                color: InventoryDesignConfig.textSecondary,
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
                      ? InventoryDesignConfig.surfaceColor
                      : InventoryDesignConfig.surfaceLight,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(
                  InventoryDesignConfig.radiusM,
                ),
                borderSide: BorderSide(
                  color:
                      isHighlighted
                          ? InventoryDesignConfig.primaryColor
                          : InventoryDesignConfig.borderPrimary,
                ),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(
                  InventoryDesignConfig.radiusM,
                ),
                borderSide: BorderSide(
                  color:
                      isHighlighted
                          ? InventoryDesignConfig.primaryColor
                          : InventoryDesignConfig.borderPrimary,
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(
                  InventoryDesignConfig.radiusM,
                ),
                borderSide: BorderSide(
                  color: InventoryDesignConfig.primaryColor,
                  width: 2,
                ),
              ),
              contentPadding: const EdgeInsets.symmetric(
                vertical: InventoryDesignConfig.spacingM,
              ),
            ),
            validator:
                required
                    ? (value) =>
                        value?.isEmpty ?? true ? 'This field is required' : null
                    : null,
            onChanged: (value) {
              if (value.contains('"')) {
                final cleanValue = value.replaceAll('"', '');
                controller.value = TextEditingValue(
                  text: cleanValue,
                  selection: TextSelection.collapsed(offset: cleanValue.length),
                );
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    String? arabicHint,
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
          style: InventoryDesignConfig.bodyLarge,
          decoration: InputDecoration(
            hintText: arabicHint ?? hint,
            hintStyle: InventoryDesignConfig.bodyMedium.copyWith(
              color: InventoryDesignConfig.textTertiary,
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
                width: 2,
              ),
            ),
            contentPadding: const EdgeInsets.all(
              InventoryDesignConfig.spacingM,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildReviewSection({
    required String title,
    required IconData icon,
    required Widget content,
  }) {
    return Container(
      width: double.infinity,
      decoration: InventoryDesignConfig.cardDecoration,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(InventoryDesignConfig.spacingL),
            decoration: BoxDecoration(
              color: InventoryDesignConfig.surfaceAccent,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(InventoryDesignConfig.radiusL),
                topRight: Radius.circular(InventoryDesignConfig.radiusL),
              ),
            ),
            child: Row(
              children: [
                Icon(icon, size: 16, color: InventoryDesignConfig.primaryColor),
                const SizedBox(width: InventoryDesignConfig.spacingM),
                Text(
                  title,
                  style: InventoryDesignConfig.titleMedium.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(InventoryDesignConfig.spacingL),
            child: content,
          ),
        ],
      ),
    );
  }

  Widget _buildReviewMeasurement(String label, String value) {
    if (value.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(bottom: InventoryDesignConfig.spacingS),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: InventoryDesignConfig.bodyMedium.copyWith(
                color: InventoryDesignConfig.textSecondary,
              ),
            ),
          ),
          Text(
            value.endsWith('"') ? value : '$value"',
            style: InventoryDesignConfig.bodyMedium.copyWith(
              fontWeight: FontWeight.w600,
              color: InventoryDesignConfig.primaryColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReviewTextField(String label, String value) {
    if (value.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(bottom: InventoryDesignConfig.spacingS),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: InventoryDesignConfig.bodyMedium.copyWith(
                color: InventoryDesignConfig.textSecondary,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: InventoryDesignConfig.bodyMedium.copyWith(
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.end,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCollarInput() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                'Collar Size',
                style: InventoryDesignConfig.labelLarge.copyWith(
                  color: InventoryDesignConfig.textPrimary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            Text(
              'رقبة',
              style: InventoryDesignConfig.bodySmall.copyWith(
                color: InventoryDesignConfig.textSecondary,
              ),
            ),
          ],
        ),
        const SizedBox(height: InventoryDesignConfig.spacingS),
        Row(
          children: [
            Expanded(
              child: _buildCollarSubField(
                controller: _collarStartController,
                label: 'Start',
                arabicLabel: 'بداية',
              ),
            ),
            const SizedBox(width: InventoryDesignConfig.spacingM),
            Expanded(
              child: _buildCollarSubField(
                controller: _collarCenterController,
                label: 'Center',
                arabicLabel: 'وسط',
              ),
            ),
            const SizedBox(width: InventoryDesignConfig.spacingM),
            Expanded(
              child: _buildCollarSubField(
                controller: _collarEndController,
                label: 'End',
                arabicLabel: 'نهاية',
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildCollarSubField({
    required TextEditingController controller,
    required String label,
    required String arabicLabel,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: InventoryDesignConfig.bodySmall.copyWith(
            color: InventoryDesignConfig.textSecondary,
          ),
        ),
        const SizedBox(height: 4),
        TextFormField(
          controller: controller,
          keyboardType: TextInputType.text,
          textAlign: TextAlign.center,
          style: InventoryDesignConfig.bodyLarge.copyWith(
            color: InventoryDesignConfig.textPrimary,
            fontWeight: FontWeight.w600,
          ),
          decoration: InputDecoration(
            hintText: arabicLabel,
            hintStyle: InventoryDesignConfig.bodyMedium.copyWith(
              color: InventoryDesignConfig.textTertiary,
            ),
            suffixText: '"',
            suffixStyle: InventoryDesignConfig.bodySmall.copyWith(
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
                width: 2,
              ),
            ),
            contentPadding: const EdgeInsets.symmetric(
              vertical: InventoryDesignConfig.spacingM,
              horizontal: InventoryDesignConfig.spacingS,
            ),
          ),
          onChanged: (value) {
            if (value.contains('"')) {
              final cleanValue = value.replaceAll('"', '');
              controller.value = TextEditingValue(
                text: cleanValue,
                selection: TextSelection.collapsed(offset: cleanValue.length),
              );
            }
          },
        ),
      ],
    );
  }
}
