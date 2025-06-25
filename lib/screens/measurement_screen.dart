import 'package:flutter/material.dart';
import '../models/measurement_filter.dart';
import '../widgets/measurement/measurement_desktop_view.dart';
import '../widgets/measurement/measurement_mobile_view.dart';

class MeasurementScreen extends StatefulWidget {
  const MeasurementScreen({super.key});

  @override
  State<MeasurementScreen> createState() => _MeasurementScreenState();
}

class _MeasurementScreenState extends State<MeasurementScreen> {
  MeasurementFilter _filter = const MeasurementFilter();

  @override
  void initState() {
    super.initState();
  }

  void _onFilterChanged(MeasurementFilter newFilter) {
    setState(() {
      _filter = newFilter;
    });
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktop = screenWidth >= 1024;

    return Scaffold(
      body:
          isDesktop
              ? MeasurementDesktopView(
                filter: _filter,
                onFilterChanged: _onFilterChanged,
              )
              : MeasurementMobileView(
                filter: _filter,
                onFilterChanged: _onFilterChanged,
              ),
    );
  }
}
