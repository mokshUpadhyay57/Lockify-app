import 'package:lockify/utils/colors.dart';
import 'dart:io';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/services.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:image_picker/image_picker.dart';
import 'package:compress_video/video_compress_compat.dart';
import 'package:path/path.dart' as p;
import 'package:lockify/utils/app_logger.dart';
import 'package:lockify/utils/snackbar.dart';

enum MediaType { image, video, document }

class EditLockedMessageScreen extends StatefulWidget {
  final String documentId;
  const EditLockedMessageScreen({super.key, required this.documentId});

  @override
  EditLockedMessageScreenState createState() => EditLockedMessageScreenState();
}

class EditLockedMessageScreenState extends State<EditLockedMessageScreen> {
  bool expireMessage = false;
  bool isPublic = false;
  XFile? _newImage;
  XFile? _newVideo;
  File? _newDocument;

  String? _existingImageUrl;
  String? _existingVideoUrl;
  String? _existingDocumentUrl;

  final TextEditingController teaserTextController = TextEditingController();
  final TextEditingController unlockPriceController = TextEditingController();
  final TextEditingController lockedContentController = TextEditingController();

  String? selectedExpiryTime;
  final List<String> expiryOptions = [
    '1 hour',
    '2 hours',
    '3 hours',
    '4 hours',
    '5 hours',
    '12 hours',
    '1 day',
    '3 days',
    '7 days',
    '15 days',
    '1 month',
    '3 months',
    '6 months',
    '1 year',
  ];

  bool isLoading = true;
  bool isUploading = false;
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _loadMessageData();
  }

  Future<void> _loadMessageData() async {
    try {
      final doc =
          await FirebaseFirestore.instance
              .collection('lockedMessages')
              .doc(widget.documentId)
              .get();

      if (doc.exists) {
        final data = doc.data()!;
        if (!mounted) return;
        setState(() {
          teaserTextController.text = data['teaserText'] ?? '';
          unlockPriceController.text = data['unlockPrice']?.toString() ?? '';
          lockedContentController.text = data['lockedContent'] ?? '';

          expireMessage = data['expireMessage'] ?? false;
          isPublic = data['isPublic'] ?? false;
          selectedExpiryTime = data['expiryTime'];
          _existingImageUrl = data['imageUrl'];
          _existingVideoUrl = data['videoUrl'];
          _existingDocumentUrl = data['documentUrl'];
          isLoading = false;
        });
      } else {
        if (!mounted) return;
        Navigator.pop(context);
        AppSnackBar.error(context, 'Message not found.');
      }
    } catch (e) {
      AppLogger.error('Error loading message', error: e);
      if (mounted) {
        setState(() => isLoading = false);
      }
    }
  }

  Future<void> recordVideo() async {
    final video = await _picker.pickVideo(source: ImageSource.camera);
    if (video != null) setState(() => _newVideo = video);
  }

  Future<void> openCameraOrGallery() async {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
      ),
      builder:
          (context) => SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  leading: const Icon(
                    Icons.camera_alt,
                    color: AppColors.primaryPurple,
                  ),
                  title: const Text('Take Photo'),
                  onTap: () async {
                    Navigator.pop(context);
                    final result = await _picker.pickImage(
                      source: ImageSource.camera,
                    );
                    if (result != null) setState(() => _newImage = result);
                  },
                ),
                ListTile(
                  leading: const Icon(
                    Icons.photo_library,
                    color: AppColors.primaryPurple,
                  ),
                  title: const Text('Choose from Gallery'),
                  onTap: () async {
                    Navigator.pop(context);
                    final result = await _picker.pickImage(
                      source: ImageSource.gallery,
                    );
                    if (result != null) setState(() => _newImage = result);
                  },
                ),
              ],
            ),
          ),
    );
  }

  Future<void> selectDocument() async {
    final result = await FilePicker.pickFile(type: FileType.any);
    if (result?.path != null) {
      setState(() => _newDocument = File(result!.path!));
    }
  }

  Future<String?> compressAndUploadMedia(
    File file,
    String path,
    MediaType type,
  ) async {
    try {
      var uploadFile = file;
      if (type == MediaType.image) {
        final compressedFilePath = file.path.replaceAll(
          RegExp(r'\.\w+$'),
          '.webp',
        );
        final compressedBytes = await FlutterImageCompress.compressWithFile(
          file.path,
          quality: 50,
          format: CompressFormat.webp,
        );
        if (compressedBytes != null) {
          uploadFile = File(compressedFilePath)
            ..writeAsBytesSync(compressedBytes);
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
      AppLogger.error('Error compressing/uploading media', error: e);
      return null;
    }
  }

  Future<void> updateLockedMessage() async {
    final teaserText = teaserTextController.text.trim();
    final unlockPrice = unlockPriceController.text.trim();
    final lockedContent = lockedContentController.text.trim();

    if (teaserText.isEmpty || unlockPrice.isEmpty || lockedContent.isEmpty) {
      AppSnackBar.error(context, 'Please fill in all required fields.');
      return;
    }

    setState(() => isUploading = true);

    try {
      String? imageUrl = _existingImageUrl;
      String? videoUrl = _existingVideoUrl;
      String? documentUrl = _existingDocumentUrl;

      if (_newImage != null) {
        imageUrl = await compressAndUploadMedia(
          File(_newImage!.path),
          'lockedMessages/images/${DateTime.now().millisecondsSinceEpoch}.jpg',
          MediaType.image,
        );
      }
      if (_newVideo != null) {
        videoUrl = await compressAndUploadMedia(
          File(_newVideo!.path),
          'lockedMessages/videos/${DateTime.now().millisecondsSinceEpoch}.mp4',
          MediaType.video,
        );
      }
      if (_newDocument != null) {
        final ext = p.extension(_newDocument!.path).replaceFirst('.', '');
        documentUrl = await compressAndUploadMedia(
          _newDocument!,
          'lockedMessages/documents/${DateTime.now().millisecondsSinceEpoch}.$ext',
          MediaType.document,
        );
      }
      if (!mounted) return;

      final updatedData = {
        'teaserText': teaserText,
        'unlockPrice': double.tryParse(unlockPrice) ?? 0.0,
        'lockedContent': lockedContent,
        'expireMessage': expireMessage,
        'expiryTime': expireMessage ? selectedExpiryTime : null,
        'imageUrl': imageUrl,
        'videoUrl': videoUrl,
        'documentUrl': documentUrl,
        'isPublic': isPublic,
      };

      await FirebaseFirestore.instance
          .collection('lockedMessages')
          .doc(widget.documentId)
          .update(updatedData);
      if (!mounted) return;
      AppSnackBar.success(context, 'Locked message updated successfully!');
      Navigator.pop(context);
    } catch (e) {
      AppLogger.error('Error updating locked message', error: e);
      AppSnackBar.error(context, 'Failed to update locked message.');
    } finally {
      if (mounted) {
        setState(() => isUploading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return Scaffold(
        appBar: AppBar(
          backgroundColor: AppColors.primaryPurple,
          title: const Text("Edit Locked Message"),
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.primaryPurple,
        foregroundColor: AppColors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        leadingWidth: 35,
        title: const Text(
          "Edit Locked Message",
          style: TextStyle(fontSize: 18),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.check),
            onPressed: isUploading ? null : updateLockedMessage,
          ),
          const SizedBox(width: 10),
        ],
      ),
      body: Stack(
        children: [
          ListView(
            padding: const EdgeInsets.all(18),
            children: [
              _buildSectionHeader("Teaser", Icons.message_outlined),
              TextField(
                controller: teaserTextController,
                maxLines: 2,
                decoration: const InputDecoration(
                  contentPadding: EdgeInsets.all(8),
                  hintText: "Enter teaser message",
                  border: UnderlineInputBorder(),
                  enabledBorder: UnderlineInputBorder(
                    borderSide: BorderSide(color: AppColors.grey),
                  ),
                  focusedBorder: UnderlineInputBorder(
                    borderSide: BorderSide(
                      color: AppColors.primaryPurple,
                      width: 2,
                    ),
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
                  hintText: "Enter price",
                  border: UnderlineInputBorder(),
                  enabledBorder: UnderlineInputBorder(
                    borderSide: BorderSide(color: AppColors.grey),
                  ),
                  focusedBorder: UnderlineInputBorder(
                    borderSide: BorderSide(
                      color: AppColors.primaryPurple,
                      width: 2,
                    ),
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
                  hintText: "Enter hidden message here",
                  border: UnderlineInputBorder(),
                  enabledBorder: UnderlineInputBorder(
                    borderSide: BorderSide(color: AppColors.grey),
                  ),
                  focusedBorder: UnderlineInputBorder(
                    borderSide: BorderSide(
                      color: AppColors.primaryPurple,
                      width: 2,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Media Preview (New or Existing)
              if (_newImage != null || _existingImageUrl != null)
                _buildMediaPreview(
                  label: "Image",
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child:
                        _newImage != null
                            ? Image.file(
                              File(_newImage!.path),
                              width: double.infinity,
                              height: 180,
                              fit: BoxFit.cover,
                            )
                            : Image.network(
                              _existingImageUrl!,
                              width: double.infinity,
                              height: 180,
                              fit: BoxFit.cover,
                            ),
                  ),
                  onRemove:
                      () => setState(() {
                        _newImage = null;
                        _existingImageUrl = null;
                      }),
                ),

              if (_newDocument != null || _existingDocumentUrl != null)
                _buildMediaPreview(
                  label: "Document",
                  child: Row(
                    children: [
                      const Icon(
                        Icons.insert_drive_file,
                        size: 40,
                        color: AppColors.primaryPurple,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          _newDocument != null
                              ? p.basename(_newDocument!.path)
                              : "Existing Document",
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  onRemove:
                      () => setState(() {
                        _newDocument = null;
                        _existingDocumentUrl = null;
                      }),
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
                  ],
                ),
              ),
              const SizedBox(height: 18),

              _buildSectionHeader("Advanced Settings", Icons.settings),
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.symmetric(
                  vertical: 16,
                  horizontal: 18,
                ),
                decoration: BoxDecoration(
                  color: AppColors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.purple100, width: 1.2),
                ),
                child: Column(
                  children: [
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text(
                        "Expire message",
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                      value: expireMessage,
                      activeColor: AppColors.primaryPurple,
                      onChanged: (val) => setState(() => expireMessage = val),
                    ),
                    if (expireMessage)
                      DropdownButton<String>(
                        value: selectedExpiryTime,
                        items:
                            expiryOptions
                                .map(
                                  (o) => DropdownMenuItem(
                                    value: o,
                                    child: Text(o),
                                  ),
                                )
                                .toList(),
                        onChanged:
                            (v) => setState(() => selectedExpiryTime = v),
                        isExpanded: true,
                        hint: const Text("Select Expiry Time"),
                      ),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text(
                        "Make Message public",
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
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
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                child: Container(
                  color: AppColors.black.withOpacity(0.1),
                  child: const Center(
                    child: CircularProgressIndicator(
                      color: AppColors.primaryPurple,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) => Padding(
    padding: const EdgeInsets.only(bottom: 8, top: 8),
    child: Row(
      children: [
        Icon(icon, color: AppColors.primaryPurple, size: 16),
        const SizedBox(width: 10),
        Text(
          title,
          style: const TextStyle(
            fontWeight: FontWeight.w500,
            fontSize: 15,
            color: AppColors.primaryPurple,
          ),
        ),
      ],
    ),
  );

  Widget _buildMediaPreview({
    required String label,
    required Widget child,
    required VoidCallback onRemove,
  }) => Container(
    margin: const EdgeInsets.symmetric(vertical: 10),
    padding: const EdgeInsets.all(8),
    decoration: BoxDecoration(
      color: AppColors.purple50,
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: AppColors.purple100),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: AppColors.primaryPurple,
              ),
            ),
            IconButton(
              icon: const Icon(
                Icons.close,
                color: AppColors.errorRed,
                size: 20,
              ),
              onPressed: onRemove,
            ),
          ],
        ),
        child,
      ],
    ),
  );

  Widget _buildMediaIcon(IconData icon, VoidCallback onTap) => InkWell(
    onTap: onTap,
    child: Padding(
      padding: const EdgeInsets.all(10),
      child: Icon(icon, color: AppColors.primaryPurple, size: 30),
    ),
  );
}
