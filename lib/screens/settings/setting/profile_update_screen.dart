import 'package:lockify/utils/colors.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:io';

import 'package:lockify/components/widgets/my_textfield.dart';
import 'package:lockify/utils/snackbar.dart'; // Import the utility function

class UpdateProfileScreen extends StatefulWidget {
  const UpdateProfileScreen({super.key});

  @override
  State<UpdateProfileScreen> createState() => _UpdateProfileScreenState();
}

class _UpdateProfileScreenState extends State<UpdateProfileScreen> {
  final ImagePicker picker = ImagePicker();
  XFile? selectedImage;

  // Controllers for text fields
  final Map<String, TextEditingController> controllers = {
    'firstName': TextEditingController(),
    'lastName': TextEditingController(),
    'username': TextEditingController(),
    'about': TextEditingController(),
    'city': TextEditingController(),
    'address': TextEditingController(),
    'instagram': TextEditingController(),
    'twitter': TextEditingController(),
    'facebook': TextEditingController(),
    'linkedin': TextEditingController(),
    'youtube': TextEditingController(),
  };

  // List to hold dynamically added text fields
  final List<TextEditingController> additionalFields = [];
  final List<String> additionalFieldLabels = [];

  @override
  void initState() {
    super.initState();
    _fetchUserData();
  }

  Future<void> _fetchUserData() async {
    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) throw Exception('No user is logged in.');

      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(currentUser.uid)
          .get();

      if (userDoc.exists) {
        final data = userDoc.data()!;
        controllers.forEach((key, controller) {
          controller.text = data[key] ?? '';

        });

        // Populate additional fields if they exist
        data.forEach((key, value) {
          if (key.startsWith('Link website')) {
            additionalFields.add(TextEditingController(text: value));
            additionalFieldLabels.add(key);
          }
        });
      }
    } catch (e) {
      AppSnackBar.error(context, 'Error fetching user data: $e');
    }
  }

  Future<void> saveProfile() async {
    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) throw Exception('No user is logged in.');

      // Fetch the current user data from Firestore
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(currentUser.uid)
          .get();

      if (!userDoc.exists) throw Exception('User document does not exist.');

      final currentData = userDoc.data() ?? {};

      // Prepare additional fields
      final Map<String, String> additionalData = {};
      for (int i = 0; i < additionalFields.length; i++) {
        additionalData[additionalFieldLabels[i]] = additionalFields[i].text.trim();
      }

      // Prepare updated data
      final updatedData = {
        ...controllers.map((key, controller) => MapEntry(key, controller.text.trim())),
        'profileImage': selectedImage?.path,
        ...additionalData,
      };

      // Check if the data has changed
      bool hasChanged = false;
      updatedData.forEach((key, value) {
        if (currentData[key] != value) {
          hasChanged = true;
        }
      });

      if (!hasChanged) {
        AppSnackBar.info(context, 'No changes detected.');
        return;
      }

      // Save user details to Firestore
      await FirebaseFirestore.instance.collection('users').doc(currentUser.uid).update(updatedData);

      AppSnackBar.success(context, 'Profile updated successfully!');
    } catch (e) {
      AppSnackBar.error(context, 'Error saving profile: $e');
    }
  }

  Future<void> pickImage() async {
    try {
      final XFile? image = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 80,
      );

      if (image != null) {
        setState(() => selectedImage = image);
      }
    } catch (e) {
      AppSnackBar.error(context, 'Error picking image: $e');
    }
  }

  void addMoreFields() {
    if (additionalFields.length >= 5) {
      AppSnackBar.warning(context, 'You can only add up to 5 additional fields.');
      return;
    }

    setState(() {
      additionalFields.add(TextEditingController());
      additionalFieldLabels.add('Link website ${additionalFields.length}');
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Update Profile",
          style: TextStyle(color: AppColors.white, fontSize: 18),
        ),
        backgroundColor: AppColors.primaryPurple,
        leading: const BackButton(color: AppColors.white),
        leadingWidth: 35,
        toolbarHeight: 50,
        actions: [
          IconButton(
            icon: const Icon(Icons.check, color: AppColors.white),
            onPressed: saveProfile,
          ),
          const SizedBox(width: 15),
        ],
      ),
      body: SingleChildScrollView(
        physics:ClampingScrollPhysics(),
        padding: const EdgeInsets.all(8.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const SizedBox(height: 20),
            _buildProfileImage(),
            const SizedBox(height: 24),
            ..._buildProfileFields(),
            ..._buildAdditionalFields(),
            const SizedBox(height: 16),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                foregroundColor: AppColors.white,
                backgroundColor: AppColors.primaryPurple,
                side: const BorderSide(color: AppColors.black12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              onPressed: addMoreFields,
              child: const Text('Add More Fields'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileImage() {
    return Center(
      child: Stack(
        alignment: Alignment.bottomRight,
        children: [
          CircleAvatar(
            radius: 50,
            backgroundColor: AppColors.black12,
            backgroundImage: selectedImage != null ? FileImage(File(selectedImage!.path)) : null,
            child: selectedImage == null
                ? const Icon(
                    Icons.person,
                    size: 45,
                    color: Colors.blueGrey,
                  )
                : null,
          ),
          GestureDetector(
            onTap: pickImage,
            child: CircleAvatar(
              radius: 16,
              backgroundColor: AppColors.black,
              child: const Icon(
                Icons.add_a_photo,
                size: 16,
                color: AppColors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildProfileFields() {
    final fields = [
      {'icon': Icons.person, 'label': 'First Name', 'key': 'firstName'},
      {'icon': Icons.person, 'label': 'Last Name', 'key': 'lastName'},
      {'icon': Icons.person, 'label': 'Username', 'key': 'username', 'readOnly': true},
      {'icon': Icons.desktop_windows, 'label': 'About You', 'key': 'about'},
      {'icon': Icons.location_on, 'label': 'Your City', 'key': 'city'},
      {'icon': Icons.place, 'label': 'Address', 'key': 'address'},
      {'icon': FontAwesomeIcons.instagram, 'label': 'Instagram user ID', 'key': 'instagram'},
      {'icon': FontAwesomeIcons.twitter, 'label': 'Twitter user ID', 'key': 'twitter'},
      {'icon': FontAwesomeIcons.facebook, 'label': 'Facebook Link', 'key': 'facebook'},
      {'icon': FontAwesomeIcons.linkedinIn, 'label': 'LinkedIn Link', 'key': 'linkedin'},
      {'icon': FontAwesomeIcons.youtube, 'label': 'YouTube Link', 'key': 'youtube'},
    ];

    return fields
        .map(
          (field) => MyTextField(
            icon: field['icon'] as IconData,
            label: field['label'] as String,
            controller: controllers[field['key']]!,
            readOnly: field['readOnly'] as bool? ?? false,
          ),
        )
        .toList();
  }

  List<Widget> _buildAdditionalFields() {
    return List.generate(additionalFields.length, (index) {
      return MyTextField(
        icon: Icons.link_sharp,
        label: additionalFieldLabels[index],
        controller: additionalFields[index],
      );
    });
  }
}

