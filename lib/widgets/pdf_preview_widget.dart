import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'dart:convert';
import 'dart:typed_data';

class PdfPreviewWidget extends StatelessWidget {
  final Uint8List pdfBytes;

  const PdfPreviewWidget({super.key, required this.pdfBytes});

  @override
  Widget build(BuildContext context) {
    final base64Pdf = base64Encode(pdfBytes);
    
    return WebViewWidget(
      controller: WebViewController()
        ..loadRequest(
          Uri.parse(
            'data:application/pdf;base64,$base64Pdf',
          ),
        ),
    );
  }
}
