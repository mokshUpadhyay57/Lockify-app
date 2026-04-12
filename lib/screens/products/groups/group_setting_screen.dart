import 'package:lockify/utils/colors.dart';
import 'dart:io';

import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:lockify/screens/products/groups/group_screen.dart';
import 'package:lockify/screens/products/participant_selection_screen.dart';
import 'package:lockify/services/admin/admin_service.dart';
import 'package:lockify/services/group/group_service.dart';
import 'package:lockify/utils/snackbar.dart';
import 'package:share_plus/share_plus.dart';
import 'package:dotted_border/dotted_border.dart';

class GroupSettingScreen extends StatefulWidget {
  final String name;
  final String description;
  final File? image;
  final bool isPaidGroup;
  final String paymentPeriod;
  final String? subscriptionPrice;

  const GroupSettingScreen({
    super.key,
    required this.name,
    required this.description,
    required this.image,
    required this.isPaidGroup, 
    required this.paymentPeriod, 
    this.subscriptionPrice,
  });

  @override
  State<GroupSettingScreen> createState() => _GroupSettingScreenState();
}

Future<String?> _compressImageAndReturnDownloadString(File file) async {
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
      debugPrint('Original size: ${await file.length() / 1024} KB');
      debugPrint('Compressed size: ${await compressedFile.length() / 1024} KB');

      // Upload to Firebase Storage
      final ref = FirebaseStorage.instance.ref().child('groups/${DateTime.now().millisecondsSinceEpoch}.webp');
      final uploadTask = await ref.putFile(compressedFile);
      return await uploadTask.ref.getDownloadURL();
    } else {
      debugPrint('Failed to compress image.');
    }
  } catch (e) {
    debugPrint('Error compressing image: $e');
  }
  return null;
}

class _GroupSettingScreenState extends State<GroupSettingScreen> {
  String groupType = 'Public';
  String memberVisibility = 'Everyone';
  bool restrictContentSaving = false;

  final String baseUrl = 'https://lockify.co.in/gl/';
  String uniqueCode = "";

  // Generate a unique code for the group
 String generateUniqueCode([int length = 6]) {
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz';
    final rand = DateTime.now().millisecondsSinceEpoch;
    return List.generate(length, (index) => chars[(rand + index) % chars.length]).join();
  }

  String get groupLink => '$baseUrl$uniqueCode';



  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.primaryPurple,
        foregroundColor: AppColors.white,
        title: Row(
          children: [
            const Icon(Icons.settings, size: 22, color: AppColors.white),
            const SizedBox(width: 8),
            const Text('Group Settings', style: TextStyle(fontSize: 18)),
          ],
        ),
        centerTitle: false,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        leadingWidth: 35,
        actions: [
          IconButton(
            icon: const Icon(Icons.check),
            onPressed: () async {



              String? imageUrl;
              if (widget.image != null) {
                imageUrl = await _compressImageAndReturnDownloadString(widget.image!);
              }

              uniqueCode = generateUniqueCode(8);

              final groupId = await GroupService().createGroup(
                name: widget.name,
                description: widget.description,
                isPaid: widget.isPaidGroup,
                imageUrl: imageUrl,
                groupType: groupType,
                memberVisibility: memberVisibility,
                restrictContentSaving: restrictContentSaving,
                subscriptionPrice: widget.subscriptionPrice,
                paymentPeriod: widget.paymentPeriod,
                url: groupLink,
              );

              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ParticipantSelectionScreen(
                    title: 'Add Members',
                    onConfirm: (phones) async {
                      final admins = await AdminService().getAdminByUid();
                      if (admins != null) {
                        await GroupService().addAdmins(groupId, admins);
                      }
                      await GroupService().addParticipants(groupId, phones);
                    },
                  ),
                ),
              ).then((_) {
                 Navigator.pushAndRemoveUntil(
                  context, 
                  MaterialPageRoute(builder: (context) => const GroupScreen()),
                  (route) => route.isFirst
                );
              });
            },
          ),
          const SizedBox(width: 10)
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // Image preview
          if (widget.image != null)
            Center(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Image.file(
                  widget.image!,
                  width: 120,
                  height: 120,
                  fit: BoxFit.cover,
                ),
              ),
            ),
          if (widget.image != null) const SizedBox(height: 20),

          // Group Type Section
          Card(
            elevation: 2,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      Icon(
                        Icons.group,
                        color: AppColors.primaryPurple,
                        size: 20,
                      ),
                      const SizedBox(width: 10),
                      const Text("Group Type", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    ],
                  ),
                  RadioListTile(
                    value: 'Public',
                    groupValue: groupType,
                    onChanged: (value) => setState(() => groupType = value!),
                    title: const Text("Public Group"),
                    subtitle: const Text("Anyone can join and find the group."),
                  ),
                  RadioListTile(
                    value: 'Private',
                    groupValue: groupType,
                    onChanged: (value) => setState(() => groupType = value!),
                    title: const Text("Private Group"),
                    subtitle: const Text("Only accessible via link."),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 18),

          // Member Visibility Section
          Card(
            elevation: 2,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      Icon(
                        Icons.visibility,
                        color: AppColors.primaryPurple,
                        size: 20,
                      ),
                      const SizedBox(width: 10),
                      const Text("Member Visibility", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    ],
                  ),
                  RadioListTile(
                    value: 'Everyone',
                    groupValue: memberVisibility,
                    onChanged: (value) => setState(() => memberVisibility = value!),
                    title: const Text("Show member count to everyone"),
                  ),
                  RadioListTile(
                    value: 'Owner',
                    groupValue: memberVisibility,
                    onChanged: (value) => setState(() => memberVisibility = value!),
                    title: const Text("Show member count to only owner"),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 18),

          // Restrict Content Saving Section
          Card(
            elevation: 2,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
              child: SwitchListTile(
                title: const Text("Restrict saving content"),
                subtitle: const Text(
                  "Members won't be able to take screenshot or record screen of this group",
                ),
                value: restrictContentSaving,
                onChanged: (value) => setState(() => restrictContentSaving = value),
              ),
            ),
          ),
          const SizedBox(height: 18),

          // Group Link Section
          Card(
            color: AppColors.purple50,
            margin: const EdgeInsets.symmetric(vertical: 12),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 40),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: DottedBorder(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
                        child: SelectableText(
                          // Display the generated group link
                          groupLink,
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 25),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primaryPurple,
                          foregroundColor: AppColors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        icon: const Icon(Icons.copy),
                        label: const Text("Copy"),
                        onPressed: () async {
                          await Clipboard.setData(ClipboardData(text: groupLink));
                          AppSnackBar.success(context, 'Link copied to clipboard!');
                        },
                      ),
                      const SizedBox(width: 35),
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primaryPurple,
                          foregroundColor: AppColors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        icon: const Icon(Icons.share),
                        label: const Text("Share"),
                        onPressed: () {
                          Share.share(groupLink);
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

