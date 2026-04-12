import 'package:lockify/utils/colors.dart';
import 'dart:io';
import 'dart:math';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:lockify/screens/products/participant_selection_screen.dart';
import 'package:lockify/services/channel/channel_service.dart';
import 'package:share_plus/share_plus.dart';
import 'package:dotted_border/dotted_border.dart';
import 'package:lockify/utils/snackbar.dart';

class ChannelSettingScreen extends StatefulWidget {
  final String name;
  final String description;
  final File? image;
  final bool isPaidChannel;
  final String paymentPeriod;
  final String? subscriptionPrice;

  const ChannelSettingScreen({
    super.key,
    required this.name,
    required this.description,
    required this.image,
    required this.isPaidChannel, 
    required this.paymentPeriod, 
    required this.subscriptionPrice,
  });

  @override
  State<ChannelSettingScreen> createState() => _ChannelSettingScreenState();
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
      final ref = FirebaseStorage.instance.ref().child('channels/${DateTime.now().millisecondsSinceEpoch}.webp');
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

class _ChannelSettingScreenState extends State<ChannelSettingScreen> {
  String channelType = 'Public';
  String subscriberVisibility = 'Everyone';
  bool restrictContentSaving = false;

  final String baseUrl = 'https://lockify.co.in/cl/';
  String uniqueCode = "";

  // Generate a unique code for the channel
  String generateUniqueCode([int length = 8]) {
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz';
    final rand = Random.secure();
    return List.generate(length, (index) => chars[rand.nextInt(chars.length)]).join();
  }

  String get channelLink => '$baseUrl$uniqueCode';


  @override
  void initState() {
    super.initState();
    uniqueCode = generateUniqueCode(8);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.primaryPurple,
        foregroundColor: AppColors.white,
        title: const Text('Channel Settings', style: TextStyle(fontSize: 18)),
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

              // Use the generated uniqueCode for the channel link
              final channelId = await ChannelService().createChannel(
                name: widget.name,
                description: widget.description,
                isPaid: widget.isPaidChannel,
                imageUrl: imageUrl,
                channelType: channelType,
                subscriberVisibility: subscriberVisibility,
                restrictContentSaving: restrictContentSaving,
                paymentPeriod: widget.paymentPeriod,
                subscriptionPrice: widget.subscriptionPrice,
                url: channelLink, // Pass the generated link
              );

              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ParticipantSelectionScreen(
                    title: 'Add Subscribers',
                    onConfirm: (phones) async {
                      await ChannelService().addParticipants(channelId, phones);
                    },
                  ),
                ),
              );
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

          // Channel Type Section
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
                      const Text("Channel Type", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    ],
                  ),
                  RadioListTile(
                    value: 'Public',
                    groupValue: channelType,
                    onChanged: (value) => setState(() => channelType = value!),
                    title: const Text("Public Channel"),
                    subtitle: const Text("Anyone can join and find the channel."),
                  ),
                  RadioListTile(
                    value: 'Private',
                    groupValue: channelType,
                    onChanged: (value) => setState(() => channelType = value!),
                    title: const Text("Private Channel"),
                    subtitle: const Text("Only accessible via link."),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 18),

          // Channel Privacy Section
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
                        Icons.private_connectivity,
                        color: AppColors.primaryPurple,
                        size: 20,
                      ),
                      const SizedBox(width: 10),
                      const Text("Channel Privacy", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    ],
                  ),
                  RadioListTile(
                    value: 'Everyone',
                    groupValue: subscriberVisibility,
                    onChanged: (value) => setState(() => subscriberVisibility = value!),
                    title: const Text("Show subscriber count to everyone"),
                  ),
                  RadioListTile(
                    value: 'Owner',
                    groupValue: subscriberVisibility,
                    onChanged: (value) => setState(() => subscriberVisibility = value!),
                    title: const Text("Show subscriber count to only owner"),
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
                  "Subscribers won't be able to take screenshot or record screen of this channel",
                ),
                value: restrictContentSaving,
                onChanged: (value) => setState(() => restrictContentSaving = value),
              ),
            ),
          ),
          const SizedBox(height: 18),

          // Channel Link Section
          Card(
            color: AppColors.purple50,
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
                          channelLink,
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
                          await Clipboard.setData(ClipboardData(text: channelLink));
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
                          Share.share(channelLink);
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

