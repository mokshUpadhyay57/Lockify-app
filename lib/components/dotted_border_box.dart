import 'package:lockify/utils/colors.dart';
import 'package:lockify/utils/snackbar.dart';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:dotted_border/dotted_border.dart';
import 'package:image_picker/image_picker.dart';


class DottedBorderBox extends StatefulWidget {
  const DottedBorderBox({super.key});

  @override
  State<DottedBorderBox> createState() => _DottedBorderBoxState();
}

class _DottedBorderBoxState extends State<DottedBorderBox> {
  XFile? _selectedImage;

  Future<void> _pickImage(BuildContext context) async {
    final ImagePicker picker = ImagePicker();

    try {
      // Open the image picker
      final XFile? image = await picker.pickImage(source: ImageSource.gallery);

      if (image != null) {
        setState(() {
          _selectedImage = image; // Update the state with the selected image
        });
        AppSnackBar.success(context, "Image selected: ${image.name}");
      } else {
        AppSnackBar.info(context, "No image selected.");
      }
    } catch (e) {
      AppSnackBar.error(context, "Error picking image: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return DottedBorder(
      child: Container(
        height: 140,
        width: double.infinity,
        color: Colors.transparent,
        child: _selectedImage == null
            ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.file_present_outlined,
                      size: 36,
                      color: AppColors.grey,
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      "Upload your GST Certificate",
                      style: TextStyle(color: AppColors.grey),
                    ),
                    ElevatedButton(
                      onPressed: () => _pickImage(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryPurple,
                        foregroundColor: AppColors.white,
                      ),
                      child: const Text("Upload"),
                    ),
                  ],
                ),
              )
            : ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: Image.file(
                  // Display the selected image
                  File(_selectedImage!.path),
                  fit: BoxFit.cover,
                  width: double.infinity,
                  height: double.infinity,
                ),
              ),
      ),
    );
  }
}

