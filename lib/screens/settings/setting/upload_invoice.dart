import 'package:lockify/utils/colors.dart';
import 'package:flutter/material.dart';
import 'package:signature/signature.dart';
import 'package:lockify/components/dotted_border_box.dart';
import 'package:lockify/components/section_header.dart';
import 'package:lockify/components/signature_box.dart';
import 'package:lockify/utils/snackbar.dart';


class UploadInvoicePage extends StatefulWidget {
  const UploadInvoicePage({super.key});

  @override
  State<UploadInvoicePage> createState() => _UploadInvoicePageState();
}

class _UploadInvoicePageState extends State<UploadInvoicePage> {
  final SignatureController _signatureController = SignatureController(
    penStrokeWidth: 2,
    penColor: AppColors.black,
    exportBackgroundColor: AppColors.white,
  );

  @override
  void dispose() {
    _signatureController.dispose();
    super.dispose();
  }

  void _clearSignature() {
    _signatureController.clear();
    AppSnackBar.info(context, "Signature cleared.");
  }

  Future<void> _saveSignature() async {
    if (_signatureController.isNotEmpty) {
      try {
        // Simulate saving signature (replace with actual logic)
        await Future.delayed(const Duration(seconds: 1));

        // Show success message
        AppSnackBar.success(context, "Signature saved successfully!");
        _signatureController.clear();
      } catch (e) {
        AppSnackBar.error(context, "Failed to save signature. Please try again.");
      }
    } else {
      AppSnackBar.error(context, "Please provide a signature before saving.");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: AppBar(
        backgroundColor: AppColors.primaryPurple,
        foregroundColor: AppColors.white,
        title: const Text('GST Invoicing', style: TextStyle(fontSize: 18)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // GST Upload Section
            const SectionHeader(
              icon: Icons.insert_drive_file_outlined,
              title: "Add GST certificate",
              subtitle: "Please upload your GST certificate.",
            ),
            const DottedBorderBox(),
            const SizedBox(height: 24),

            // Signature Section
            const SectionHeader(
              icon: Icons.edit,
              title: "Add your signature",
              subtitle: "We need your signature. Please sign in the box below.",
            ),
            SignatureBox(controller: _signatureController),
            const SizedBox(height: 16),

            // Action Buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                TextButton(
                  onPressed: _clearSignature,
                  child: const Text(
                    "CLEAR",
                    style: TextStyle(color: AppColors.primaryPurple),
                  ),
                ),
                ElevatedButton(
                  onPressed: _saveSignature,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.grey700,
                    foregroundColor: AppColors.white,
                  ),
                  child: const Text("APPLY"),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

