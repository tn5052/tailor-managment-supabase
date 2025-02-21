import 'package:flutter/material.dart';
import 'package:pdfx/pdfx.dart';
import 'dart:typed_data';

class PdfPreviewWidget extends StatefulWidget {
  final List<int> pdfBytes;

  const PdfPreviewWidget({super.key, required this.pdfBytes});

  @override
  State<PdfPreviewWidget> createState() => _PdfPreviewWidgetState();
}

class _PdfPreviewWidgetState extends State<PdfPreviewWidget> {
  late PdfController pdfController;

  @override
  void initState() {
    super.initState();
    pdfController = PdfController(
      document: PdfDocument.openData(Uint8List.fromList(widget.pdfBytes)),
    );
  }

  @override
  void dispose() {
    pdfController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PdfView(
      controller: pdfController,
      scrollDirection: Axis.vertical,
      pageSnapping: false,
      physics: const ClampingScrollPhysics(),
      builders: PdfViewBuilders<DefaultBuilderOptions>(
        options: const DefaultBuilderOptions(),
        documentLoaderBuilder:
            (_) => const Center(child: CircularProgressIndicator()),
        pageLoaderBuilder:
            (_) => const Center(child: CircularProgressIndicator()),
        errorBuilder:
            (_, error) => Center(
              child: Text(
                error.toString(),
                style: const TextStyle(color: Colors.red),
              ),
            ),
      ),
    );
  }
}
