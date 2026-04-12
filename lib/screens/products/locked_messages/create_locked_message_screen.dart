import 'package:lockify/utils/colors.dart';
import 'dart:io';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/services.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:lockify/services/auth/auth_service.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shimmer/shimmer.dart';
import 'package:video_compress/video_compress.dart';
import 'package:path/path.dart' as p;
import 'package:lockify/utils/snackbar.dart';

enum MediaType { image, video, document }

class CreateLockedMessageScreen extends StatefulWidget {
  const CreateLockedMessageScreen({super.key});

  @override
  CreateLockedMessageScreenState createState() => CreateLockedMessageScreenState();
}

class CreateLockedMessageScreenState extends State<CreateLockedMessageScreen> {
  bool expireMessage = false;
  bool isPublic = false;
  XFile? _capturedImage;
  XFile? _capturedVideo;
  File? _selectedDocument;

  final TextEditingController teaserTextController = TextEditingController();
  final TextEditingController unlockPriceController = TextEditingController();
  final TextEditingController lockedContentController = TextEditingController();

  String? selectedExpiryTime;
  final List<String> expiryOptions = ['1 hour', '2 hours', '3 hours','4 hours','5 hours', '12 hours', '1 day', '3 days', '7 days', '15 days', '1 month','3 months','6 months', '1 year'];

  bool isUploading = false;
  final ImagePicker _picker = ImagePicker();

  Future<void> recordVideo() async {
    final video = await _picker.pickVideo(source: ImageSource.camera);
    if (video != null) setState(() => _capturedVideo = video);
  }

  Future<void> openCameraOrGallery() async {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(18))),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt, color: AppColors.primaryPurple),
              title: const Text('Take Photo'),
              onTap: () async {
                Navigator.pop(context);
                final result = await _picker.pickImage(source: ImageSource.camera);
                if (result != null) setState(() => _capturedImage = result);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library, color: AppColors.primaryPurple),
              title: const Text('Choose from Gallery'),
              onTap: () async {
                Navigator.pop(context);
                final result = await _picker.pickImage(source: ImageSource.gallery);
                if (result != null) setState(() => _capturedImage = result);
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> selectDocument() async {
    final result = await FilePicker.platform.pickFiles(type: FileType.any);
    if (result != null && result.files.single.path != null) {
      setState(() => _selectedDocument = File(result.files.single.path!));
    }
  }

  Future<String?> compressAndUploadMedia(File file, String path, MediaType type) async {
    try {
      var uploadFile = file;
      if (type == MediaType.image) {
        final compressedFilePath = file.path.replaceAll(RegExp(r'\.\w+$'), '.webp');
        final compressedBytes = await FlutterImageCompress.compressWithFile(
          file.path,
          quality: 50,
          format: CompressFormat.webp,
        );
        if (compressedBytes != null) {
          uploadFile = File(compressedFilePath)..writeAsBytesSync(compressedBytes);
        }
      } else if (type == MediaType.video) {
        final info = await VideoCompress.compressVideo(
          file.path,
          quality: VideoQuality.MediumQuality,
          deleteOrigin: false,
        );
        final compressedVideo = info?.file;
        if (compressedVideo != null) uploadFile = compressedVideo;
      }
      final ref = FirebaseStorage.instance.ref().child(path);
      final uploadTask = await ref.putFile(uploadFile);
      return await uploadTask.ref.getDownloadURL();
    } catch (e) {
      debugPrint('Error compressing/uploading media: $e');
      return null;
    }
  }

  String generateUniqueCode([int length = 6]) {
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz';

    final rand = DateTime.now().millisecondsSinceEpoch;
    return List.generate(length, (index) => chars[(rand + index) % chars.length]).join();
  }



  Future<void> saveLockedMessage() async {
    final teaserText = teaserTextController.text.trim();
    final unlockPrice = unlockPriceController.text.trim();
    final lockedContent = lockedContentController.text.trim();
    final authService = AuthService();

    if (teaserText.isEmpty || unlockPrice.isEmpty || lockedContent.isEmpty) {
      AppSnackBar.error(context, 'Please fill in all required fields.');
      return;
    }

    setState(() => isUploading = true);

    try {
      final createdBy = authService.getCurrentUser()!.uid;
      String? imageUrl, videoUrl, documentUrl;

      if (_capturedImage != null) {
        imageUrl = await compressAndUploadMedia(
          File(_capturedImage!.path),
          'lockedMessages/images/${DateTime.now().millisecondsSinceEpoch}.jpg',
          MediaType.image,
        );
      }
      if (_capturedVideo != null) {
        videoUrl = await compressAndUploadMedia(
          File(_capturedVideo!.path),
          'lockedMessages/videos/${DateTime.now().millisecondsSinceEpoch}.mp4',
          MediaType.video,
        );
      }
      if (_selectedDocument != null) {
        final ext = p.extension(_selectedDocument!.path).replaceFirst('.', '');
        documentUrl = await compressAndUploadMedia(
          _selectedDocument!,
          'lockedMessages/documents/${DateTime.now().millisecondsSinceEpoch}.$ext',
          MediaType.document,
        );
      }
      final uniqueCode = generateUniqueCode(6);
      final lockedMessageData = {
        'teaserText': teaserText,
        'unlockPrice': double.tryParse(unlockPrice) ?? 0.0,
        'lockedContent': lockedContent,
        'expireMessage': expireMessage,
        'expiryTime': expireMessage ? selectedExpiryTime : null,
        'createdAt': FieldValue.serverTimestamp(),
        'createdBy': createdBy,
        'imageUrl': imageUrl,
        'videoUrl': videoUrl,
        'documentUrl': documentUrl,
        'isPublic': isPublic,
        "uniqueCode": uniqueCode,
      };

      await FirebaseFirestore.instance.collection('lockedMessages').add(lockedMessageData);
      AppSnackBar.success(context, 'Locked message saved successfully!');
      Navigator.pop(context);
    } catch (e) {
      debugPrint('Error saving locked message: $e');
      AppSnackBar.error(context, 'Failed to save locked message.');
    } finally {
      setState(() => isUploading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.primaryPurple,
        foregroundColor: AppColors.white,
        leading: IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => Navigator.pop(context)),
        leadingWidth: 35,
        title: const Text("Send Locked Message", style: TextStyle(fontSize: 18)),
        actions: [
          IconButton(icon: const Icon(Icons.check), onPressed: isUploading ? null : saveLockedMessage),
          const SizedBox(width: 10),
        ],
      ),
      body: Stack(
        children: [
          ListView(
            padding: const EdgeInsets.all(18),
            children: [
              // Recipient Section
              Card(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(3)),
                child: Container(
                  decoration: BoxDecoration(
                    color: AppColors.purple50,
                    borderRadius: BorderRadius.circular(3),
                    border: Border.all(color: AppColors.purple100, width: 1),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                    child: Row(
                      children: [
                        Icon(Icons.info_outline_rounded, color: AppColors.black54),
                        const SizedBox(width: 6),
                        Text("What is a Locked Message?", style: TextStyle(color: AppColors.black54))
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 25),

              _buildSectionHeader("Teaser", Icons.message_outlined),
              TextField(
                controller: teaserTextController,
                maxLines: 2,
                decoration: const InputDecoration(
                  contentPadding: EdgeInsets.all(8),
                  hintText: "Enter teaser message which will be visible to the everyone",
                  border: UnderlineInputBorder(),
                  enabledBorder: UnderlineInputBorder(
                    borderSide: BorderSide(color: AppColors.grey, ),
                  ),
                  focusedBorder: UnderlineInputBorder(
                    borderSide: BorderSide(color: AppColors.primaryPurple, width: 2),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              _buildSectionHeader("Unlock Price", Icons.lock_open),
              TextField(
                controller: unlockPriceController,
                maxLines: 1,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  contentPadding: EdgeInsets.all(8),
                  hintText: "Enter price to view content",
                  border: UnderlineInputBorder(),
                  enabledBorder: UnderlineInputBorder(
                    borderSide: BorderSide(color: AppColors.grey),
                  ),
                  focusedBorder: UnderlineInputBorder(
                    borderSide: BorderSide(color: AppColors.primaryPurple, width: 2),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              _buildSectionHeader("Add Locked Content", Icons.visibility_off),
              TextField(
                controller: lockedContentController,
                maxLines: 3,
                decoration: const InputDecoration(
                  contentPadding: EdgeInsets.all(8),
                  hintText: "Enter hidden message here. Add images, videos, files and audio messages from the options below.",
                  border: UnderlineInputBorder(),
                  enabledBorder: UnderlineInputBorder(
                    borderSide: BorderSide(color: AppColors.grey),
                  ),
                  focusedBorder: UnderlineInputBorder(
                    borderSide: BorderSide(color: AppColors.primaryPurple, width: 2),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Media Preview
              if (_capturedImage != null)
                _buildMediaPreview(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.file(
                      File(_capturedImage!.path),
                      width: double.infinity,
                      height: 180,
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
              if (_selectedDocument != null)
                _buildMediaPreview(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Builder(
                        builder: (context) {
                          final ext = p.extension(_selectedDocument!.path).toLowerCase();
                          if (['.jpg', '.jpeg', '.png', '.gif', '.bmp', '.webp'].contains(ext)) {
                            return ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Image.file(
                                _selectedDocument!,
                                width: 48,
                                height: 48,
                                fit: BoxFit.cover,
                              ),
                            );
                          } else if (ext == '.pdf') {
                            return Container(
                              width: 48,
                              height: 48,
                              alignment: Alignment.center,
                              child: Icon(Icons.picture_as_pdf, size: 40, color: AppColors.errorRedAccent),
                            );
                          } else {
                            return Icon(Icons.insert_drive_file, size: 48, color: AppColors.primaryPurple);
                          }
                        },
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              p.basename(_selectedDocument!.path),
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                              overflow: TextOverflow.ellipsis,
                            ),
                            Text(
                              p.extension(_selectedDocument!.path).replaceFirst('.', '').toUpperCase(),
                              style: const TextStyle(color: AppColors.primaryPurple, fontSize: 13),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close, color: AppColors.errorRed),
                        onPressed: () => setState(() => _selectedDocument = null),
                      ),
                    ],
                  ),
                ),

              // Media Actions
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 10),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildMediaIcon(Icons.camera_alt, openCameraOrGallery),
                    _buildMediaIcon(Icons.videocam, recordVideo),
                    _buildMediaIcon(Icons.insert_drive_file, selectDocument),
                    _buildMediaIcon(Icons.mic, () {/* Add audio logic */}),
                  ],
                ),
              ),
              const SizedBox(height: 18),

              _buildSectionHeader("Advanced Settings", Icons.settings),
              const SizedBox(height: 10),
              Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 18),
                decoration: BoxDecoration(
                  color: AppColors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.purple100, width: 1.2),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primaryPurple.withOpacity(0.07),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text("Expire message", style: TextStyle(fontWeight: FontWeight.w600)),
                      subtitle: const Text("Make this message unavailable after a certain time."),
                      value: expireMessage,
                      activeColor: AppColors.primaryPurple,
                      onChanged: (val) => setState(() => expireMessage = val),
                    ),
                    if (expireMessage)
                      Padding(
                        padding: const EdgeInsets.only(left: 8, right: 8, bottom: 10, top: 2),
                        child: Row(
                          children: [
                            const Text("Expiry Time:", style: TextStyle(fontWeight: FontWeight.w500)),
                            const SizedBox(width: 16),
                            Expanded(
                              child: DropdownButton<String>(
                                value: selectedExpiryTime,
                                items: expiryOptions
                                    .map((option) => DropdownMenuItem<String>(
                                          value: option,
                                          child: Text(option),
                                        ))
                                    .toList(),
                                onChanged: (value) => setState(() => selectedExpiryTime = value),
                                borderRadius: BorderRadius.circular(12),
                                underline: Container(height: 1, color: AppColors.purple100),
                                icon: const Icon(Icons.arrow_drop_down, color: AppColors.primaryPurple),
                                hint: const Text("Select"),
                                isExpanded: true,
                              ),
                            ),
                          ],
                        ),
                      ),
                    if (expireMessage)
                      Divider(color: AppColors.purple100, height: 24, thickness: 1),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text("Make Message public", style: TextStyle(fontWeight: FontWeight.w600)),
                      subtitle: const Text("Set this message to be public after expiry."),
                      value: isPublic,
                      activeColor: AppColors.primaryPurple,
                      onChanged: (val) => setState(() => isPublic = val),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
          if (isUploading)
            Positioned.fill(
              child: Stack(
                children: [
                  BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                    child: Container(
                      color: AppColors.black.withOpacity(0.1),
                    ),
                  ),
                  Shimmer.fromColors(
                    baseColor: AppColors.primaryPurple.withOpacity(0.10),
                    highlightColor: AppColors.white.withOpacity(0.18),
                    child: Container(
                      width: double.infinity,
                      height: double.infinity,
                      color: AppColors.white.withOpacity(0.15),
                    ),
                  ),
                  const Center(
                    child: CircularProgressIndicator(color: AppColors.primaryPurple),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) => Padding(
        padding: const EdgeInsets.only(bottom: 8, left: 2, top: 8),
        child: Row(
          children: [
            Icon(icon, color: AppColors.primaryPurple, size: 16),
            const SizedBox(width: 10),
            Text(
              title,
              style: const TextStyle(
                  fontWeight: FontWeight.w500, fontSize: 15, color: AppColors.primaryPurple, letterSpacing: 0.5),
            ),
          ],
        ),
      );

  Widget _buildMediaPreview({required Widget child}) => Container(
        margin: const EdgeInsets.symmetric(vertical: 10),
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: AppColors.purple50,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.purple100, width: 1),
        ),
        child: child,
      );

  Widget _buildMediaIcon(IconData icon, VoidCallback onTap) => InkWell(
        borderRadius: BorderRadius.circular(32),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                  padding: const EdgeInsets.all(10),
                  child: Icon(icon, color: AppColors.primaryPurple, size: 30)),
              const SizedBox(height: 6),
            ],
          ),
        ),
      );
}

