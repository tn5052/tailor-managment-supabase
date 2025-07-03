import 'package:flutter/material.dart';
import '../widgets/complaint/complaint_desktop_view.dart';
import '../widgets/complaint/complaint_mobile_view.dart';
import '../widgets/responsive_layout.dart';

class ComplaintsScreen extends StatelessWidget {
  const ComplaintsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const ResponsiveLayout(
      desktopBody: ComplaintDesktopView(),
      mobileBody: ComplaintMobileView(),
    );
  }
}
