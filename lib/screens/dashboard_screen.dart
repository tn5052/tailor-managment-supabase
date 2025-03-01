import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../widgets/responsive_layout.dart';
import '../models/invoice.dart';
import '../models/measurement.dart';
import '../models/complaint.dart';
import '../services/invoice_service.dart';
import '../widgets/dashboard/status_distribution.dart';
import '../widgets/dashboard/overview_grid.dart';
import '../widgets/dashboard/recent_activity.dart';
import '../widgets/dashboard/performance_metrics.dart';
import '../widgets/dashboard/dashboard_header.dart';
import '../services/measurement_service.dart';
import '../services/complaint_service.dart';  // Add this import
import 'package:supabasetest/screens/settings_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final InvoiceService _invoiceService = InvoiceService();
  final MeasurementService _measurementService = MeasurementService();
  final ComplaintService _complaintService = ComplaintService(Supabase.instance.client);  // Add this
  late Stream<List<Invoice>> _invoicesStream;
  late Stream<List<Measurement>> _measurementsStream;
  late Stream<List<Complaint>> _complaintsStream;  // Add this

  @override
  void initState() {
    super.initState();
    _invoicesStream = _invoiceService.getInvoicesStream();
    _measurementsStream = _measurementService.getMeasurementsStream();
    _complaintsStream = _complaintService.getComplaintsStream();  // Add this
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard'),
        actions: [
          if (ResponsiveLayout.isMobile(context))
            IconButton(
              icon: const Icon(Icons.settings),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const SettingsScreen()),
                );
              },
            ),
        ],
      ),
      body: StreamBuilder<List<Invoice>>(
        stream: _invoicesStream,
        builder: (context, invoiceSnapshot) {
          return StreamBuilder<List<Measurement>>(
            stream: _measurementsStream,
            builder: (context, measurementSnapshot) {
              return StreamBuilder<List<Complaint>>(  // Add this StreamBuilder
                stream: _complaintsStream,
                builder: (context, complaintSnapshot) {
                  if (invoiceSnapshot.hasError || 
                      measurementSnapshot.hasError ||
                      complaintSnapshot.hasError) {
                    return const Center(child: Text('Error loading data'));
                  }

                  if (!invoiceSnapshot.hasData || 
                      !measurementSnapshot.hasData ||
                      !complaintSnapshot.hasData) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  final invoices = invoiceSnapshot.data!;
                  final measurements = measurementSnapshot.data!;
                  final complaints = complaintSnapshot.data!;  // Add this

                  return SingleChildScrollView(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: ResponsiveLayout(
                        mobileBody: _buildMobileLayout(
                          invoices, 
                          measurements,
                          complaints,  // Add this
                        ),
                        desktopBody: _buildDesktopLayout(
                          invoices, 
                          measurements,
                          complaints,  // Add this
                        ),
                      ),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildMobileLayout(
    List<Invoice> invoices, 
    List<Measurement> measurements,
    List<Complaint> complaints,  // Add this
  ) {
    return Column(
      children: [
        SafeArea(
          child: DashboardHeader(
            invoices: invoices,
            onRefresh: () => setState(() {}),
            isMobile: true,
          ),
        ),
        const SizedBox(height: 24),
        OverviewGrid(invoices: invoices, isExpanded: true),
        const SizedBox(height: 16),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),

        ),
        const SizedBox(height: 16),
        StatusDistribution(invoices: invoices),
        const SizedBox(height: 16),
        PerformanceMetrics(invoices: invoices),
        const SizedBox(height: 16),
        RecentActivity(
          invoices: invoices, 
          measurements: measurements,
          complaints: complaints,  // Add this
        ),
        // Add bottom padding for mobile
        SizedBox(height: MediaQuery.of(context).padding.bottom + 16),
      ],
    );
  }

  Widget _buildDesktopLayout(
    List<Invoice> invoices, 
    List<Measurement> measurements,
    List<Complaint> complaints,  // Add this
  ) {
    return Column(
      children: [
        DashboardHeader(
          invoices: invoices,
          onRefresh: () => setState(() {}),
        ),
        const SizedBox(height: 24),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: 3,
              child: Column(
                children: [
                  OverviewGrid(invoices: invoices),
                  const SizedBox(height: 16),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: StatusDistribution(invoices: invoices),
                      ),
                      const SizedBox(width: 16),
           
                    ],
                  ),
                  const SizedBox(height: 16),
                  PerformanceMetrics(invoices: invoices),
                ],
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              flex: 2,
              child: RecentActivity(
                invoices: invoices, 
                measurements: measurements,
                complaints: complaints,  // Add this
              ),
            ),
          ],
        ),
      ],
    );
  }

}
