import 'package:lockify/utils/colors.dart';
import 'package:lockify/utils/snackbar.dart';
import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';


class UploadScreen extends StatefulWidget {
  final String type; // Type of verification (Aadhar or PAN)

  const UploadScreen({required this.type, super.key});

  @override
  State<UploadScreen> createState() => _UploadScreenState();
}

class _UploadScreenState extends State<UploadScreen> {
  final ImagePicker _picker = ImagePicker();
  File? _selectedImage;
  bool _isUploading = false;

  Future<File?> _compressImage(File file) async {
    try {
      debugPrint('Compressing image to WebP format...');
      final compressedFilePath = file.path.replaceAll(RegExp(r'\.\w+$'), '.webp');

      final compressedBytes = await FlutterImageCompress.compressWithFile(
        file.path,
        quality: 50,
        format: CompressFormat.webp,
      );

      if (compressedBytes != null) {
        final compressedFile = File(compressedFilePath)..writeAsBytesSync(compressedBytes);
        debugPrint('Image compression successful.');
        debugPrint('Original size: ${await file.length()} bytes');
        debugPrint('Compressed size: ${await compressedFile.length()} bytes');
        return compressedFile;
      } else {
        debugPrint('Failed to compress image.');
      }
    } catch (e) {
      debugPrint('Error compressing image: $e');
    }
    return null;
  }

  Future<void> _pickImage() async {
    try {
      final XFile? image = await _picker.pickImage(source: ImageSource.gallery);

      if (image != null) {
        final file = File(image.path);
        final fileSize = await file.length();

        if (fileSize > 10 * 1024 * 1024) {
          AppSnackBar.warning(context, 'File size exceeds 10MB. Please select a smaller file.');
          return;
        }

        final compressedFile = await _compressImage(file);

        if (compressedFile != null) {
          setState(() {
            _selectedImage = compressedFile;
          });
          AppSnackBar.success(context, 'Image selected and compressed successfully.');
        } else {
          AppSnackBar.error(context, 'Failed to compress the image.');
        }
      }
    } catch (e) {
      debugPrint('Error picking image: $e');
      AppSnackBar.error(context, 'Failed to pick an image.');
    }
  }

  Future<void> _uploadImage() async {
    
    final userId = FirebaseAuth.instance.currentUser?.uid;
    
    if (_selectedImage == null) {
      AppSnackBar.warning(context, 'Please select an image to upload.');
      return;
    }

    setState(() {
      _isUploading = true;
    });

    try {
      final storageRef = FirebaseStorage.instance
          .ref()
          .child('verification/${widget.type}/${DateTime.now().millisecondsSinceEpoch}.webp');
      await storageRef.putFile(_selectedImage!);

      final downloadUrl = await storageRef.getDownloadURL();

      await FirebaseFirestore.instance.collection('verifications').add({
        'userId': userId,
        'status': 'pending',
        'doctype': widget.type,
        'imageUrl': downloadUrl,
        'uploadedAt': Timestamp.now(),
      });

      AppSnackBar.success(context, '${widget.type} uploaded successfully!');
    } catch (e) {
      debugPrint('Error uploading image: $e');
      AppSnackBar.error(context, 'Failed to upload ${widget.type}.');
    } finally {
      setState(() {
        _isUploading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: AppBar(
        backgroundColor: AppColors.primaryPurple,
        foregroundColor: AppColors.white,
        title: Text('${widget.type} Upload', style: const TextStyle(fontSize: 18)),
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
            SectionHeader(
              icon: Icons.insert_drive_file_outlined,
              title: "Upload ${widget.type}",
              subtitle: "Please upload your ${widget.type} document.",
            ),
            const SizedBox(height: 16),
            _selectedImage != null
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.file(
                      _selectedImage!,
                      height: 200,
                      width: double.infinity,
                      fit: BoxFit.cover,
                    ),
                  )
                : DottedBorderBox(
                    child: const Center(
                      child: Text(
                        "No image selected.",
                        style: TextStyle(fontSize: 16, color: AppColors.grey),
                      ),
                    ),
                  ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                TextButton(
                  onPressed: () {
                    setState(() {
                      _selectedImage = null;
                    });
                    AppSnackBar.info(context, "Selection cleared.");
                  },
                  child: const Text(
                    "CLEAR",
                    style: TextStyle(color: AppColors.primaryPurple),
                  ),
                ),
                ElevatedButton(
                  onPressed: _isUploading ? null : _uploadImage,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.grey700,
                    foregroundColor: AppColors.white,
                  ),
                  child: _isUploading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            color: AppColors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : const Text("UPLOAD"),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Center(
              child: ElevatedButton.icon(
                onPressed: _pickImage,
                icon: const Icon(Icons.image),
                label: const Text('Select Image'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryPurple,
                  foregroundColor: AppColors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// SectionHeader Widget
class SectionHeader extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;

  const SectionHeader({
    required this.icon,
    required this.title,
    required this.subtitle,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: AppColors.primaryPurple, size: 28),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: const TextStyle(fontSize: 14, color: AppColors.grey),
            ),
          ],
        ),
      ],
    );
  }
}

// DottedBorderBox Widget
class DottedBorderBox extends StatelessWidget {
  final Widget? child;

  const DottedBorderBox({this.child, super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 200,
      width: double.infinity,
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.grey400, width: 1, style: BorderStyle.solid),
        borderRadius: BorderRadius.circular(8),
      ),
      child: child,
    );
  }
}

