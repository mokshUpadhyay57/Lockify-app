import 'package:lockify/utils/colors.dart';
import 'dart:io' show File;
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:lockify/utils/snackbar.dart';


class AddProfileIntroPage extends StatefulWidget {
  const AddProfileIntroPage({super.key});

  @override
  State<AddProfileIntroPage> createState() => _AddProfileIntroPageState();
}

class _AddProfileIntroPageState extends State<AddProfileIntroPage> {
  bool isImageSelected = true; // Tracks whether "Images" or "Video" is selected
  XFile? selectedFile; // Holds the selected file
  final ImagePicker _picker = ImagePicker(); // ImagePicker instance

  Future<void> _pickFile() async {
    try {
      final pickedFile = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85, // Compress image for optimization
      );
      if (pickedFile != null) {
        final file = File(pickedFile.path);
        final fileSize = await file.length();
        if (fileSize > 20 * 1024 * 1024) { // Check if file size exceeds 20 MB
          _showErrorDialog("The selected file exceeds the maximum allowed size of 20 MB.");
          return;
        }
        setState(() => selectedFile = pickedFile);
      }
    } catch (e) {
      _showErrorDialog("Failed to pick a file. Please try again.");
    }
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Error"),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("OK"),
          ),
        ],
      ),
    );
  }

  void _saveIntro() {
    if (selectedFile == null) {
      _showErrorDialog("Please select a file before saving.");
      return;
    }
    // Add logic to save the intro (e.g., upload to server or database)
    AppSnackBar.success(context, "Profile intro saved successfully!");
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Profile Intro', style: TextStyle(fontSize: 18)),
        backgroundColor: AppColors.primaryPurple,
        foregroundColor: AppColors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right:10),
            child: IconButton(
              icon: const Icon(Icons.check),
              onPressed: _saveIntro,
            ),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.grey200,
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "When you upload a video or image, it will come up in your profile page. Add details about why a user should join your groups, channels or do a paid conversation with you!",
                ),
                SizedBox(height: 8),
                Text(
                  "Check example",
                  style: TextStyle(color: AppColors.primaryPurple, fontWeight: FontWeight.bold),
                )
              ],
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            "Intro type",
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          Row(
            children: [
              Radio<bool>(
                value: true,
                groupValue: isImageSelected,
                onChanged: (value) => setState(() => isImageSelected = true),
                activeColor: AppColors.primaryPurple,
              ),
              const Text("Images"),
              const SizedBox(width: 16),
              Radio<bool>(
                value: false,
                groupValue: isImageSelected,
                onChanged: (value) => setState(() => isImageSelected = false),
                activeColor: AppColors.primaryPurple,
              ),
              const Text("Video"),
            ],
          ),
          const SizedBox(height: 12),
          selectedFile == null
              ? GestureDetector(
                  onTap: _pickFile,
                  child: Container(
                    height: 150,
                    margin: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(
                      border: Border.all(color: AppColors.grey),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.cloud_upload_outlined, size: 40),
                          SizedBox(height: 8),
                          Text("Click to add images"),
                        ],
                      ),
                    ),
                  ),
                )
              : Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Image.file(File(selectedFile!.path), height: 150, fit: BoxFit.cover),
                ),
          const Padding(
            padding: EdgeInsets.only(top: 8.0),
            child: Text("* Maximum allowed size is 20 MB", style: TextStyle(color: AppColors.grey)),
          ),
        ],
      ),
    );
  }
}

