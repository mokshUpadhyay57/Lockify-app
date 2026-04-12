import 'package:lockify/utils/colors.dart';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:lockify/screens/products/channels/channel_setting_screen.dart';
import 'package:lockify/utils/snackbar.dart';

class CreateChannelScreen extends StatefulWidget {
  const CreateChannelScreen({super.key});

  @override
  State<CreateChannelScreen> createState() => CreateChannelScreenState();
}

class CreateChannelScreenState extends State<CreateChannelScreen> {
  File? _image;
  bool _isPaidChannel = false;
  String _paymentPeriod = 'Monthly';

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _descController = TextEditingController();
  final TextEditingController _priceController = TextEditingController();

  Future<void> _pickImage(ImageSource source) async {
    final pickedFile = await ImagePicker().pickImage(source: source, imageQuality: 50);
    if (pickedFile != null) {
      setState(() {
        _image = File(pickedFile.path);
      });
    } else {
      AppSnackBar.error(context, 'No image selected');
    }
  }

  void _showImageSourceDialog() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Padding(
                padding: EdgeInsets.all(16),
                child: Text(
                  'Select Image Source',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
              const Divider(),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  GestureDetector(
                    onTap: () {
                      Navigator.pop(context);
                      _pickImage(ImageSource.camera);
                    },
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: const [
                        Icon(Icons.camera_alt, size: 50, color: AppColors.primaryPurple),
                        SizedBox(height: 8),
                        Text('Camera', style: TextStyle(fontSize: 16)),
                      ],
                    ),
                  ),
                  GestureDetector(
                    onTap: () {
                      Navigator.pop(context);
                      _pickImage(ImageSource.gallery);
                    },
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: const [
                        Icon(Icons.photo_library, size: 50, color: AppColors.primaryPurple),
                        SizedBox(height: 8),
                        Text('Gallery', style: TextStyle(fontSize: 16)),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text(
                  'Cancel',
                  style: TextStyle(fontSize: 16, color: AppColors.errorRed),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.primaryPurple,
        foregroundColor: AppColors.white,
        title: const Text('New Channel', style: TextStyle(fontSize: 18)),
        centerTitle: false,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.check),
            onPressed: () {
              if (_isPaidChannel && _priceController.text.isEmpty) {
                AppSnackBar.error(context, 'Please enter subscription price');
                return;
              }
              if (_nameController.text.isEmpty) {
                AppSnackBar.error(context, 'Please enter channel name');
                return;
              }

              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ChannelSettingScreen(
                    name: _nameController.text.trim(),
                    description: _descController.text.trim(),
                    image: _image,
                    isPaidChannel: _isPaidChannel,
                    paymentPeriod: _paymentPeriod,
                    subscriptionPrice: _isPaidChannel ? _priceController.text.trim() : '',
                  ),
                ),
              );
            },
          ),
          const SizedBox(width: 10),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Row(
              children: [
                GestureDetector(
                  onTap: _showImageSourceDialog,
                  child: CircleAvatar(
                    radius: 30,
                    backgroundColor: AppColors.black,
                    backgroundImage: _image != null ? FileImage(_image!) : null,
                    child: _image == null
                        ? const Icon(Icons.add_a_photo, color: AppColors.white)
                        : null,
                  ),
                ),
                const SizedBox(width: 20),
                Expanded(
                  child: TextField(
                    controller: _nameController,
                    decoration: const InputDecoration(
                      hintText: 'Channel name',
                      border: UnderlineInputBorder(),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _descController,
              decoration: const InputDecoration(
                hintText: 'Description',
                border: UnderlineInputBorder(),
              ),
            ),
            const SizedBox(height: 10),
            const Align(
              alignment: Alignment.centerLeft,
              child: Padding(
                padding: EdgeInsets.only(top: 8),
                child: Text(
                  'Provide a description about channel.',
                  style: TextStyle(color: AppColors.grey),
                ),
              ),
            ),
            const SizedBox(height: 30),
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.wallet_outlined, color: AppColors.primaryPurple),
                        const SizedBox(width: 10),
                        const Text(
                          'Launch paid Channel',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                        ),
                        const Spacer(),
                        Switch(
                          value: _isPaidChannel,
                          activeColor: AppColors.primaryPurple,
                          onChanged: (value) {
                            setState(() {
                              _isPaidChannel = value;
                            });
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Launch paid channel where users will be able to join only after paying the subscription price!',
                      style: TextStyle(fontSize: 14, color: AppColors.grey),
                    ),
                    if (_isPaidChannel) ...[
                      const Divider(height: 28),
                      Row(
                        children: [
                          const Icon(Icons.calendar_month, color: AppColors.primaryPurple),
                          const SizedBox(width: 10),
                          const Text(
                            'Payment Period',
                            style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
                          ),
                          const Spacer(),
                          DropdownButton<String>(
                            value: _paymentPeriod,
                            borderRadius: BorderRadius.circular(10),
                            items: const [
                              DropdownMenuItem(
                                value: 'Monthly',
                                child: Text('Monthly'),
                              ),
                              DropdownMenuItem(
                                value: 'Quarterly',
                                child: Text('Quarterly'),
                              ),
                              DropdownMenuItem(
                                value: 'Half Yearly',
                                child: Text('Half Yearly'),
                              ),
                              DropdownMenuItem(
                                value: 'Yearly',
                                child: Text('Yearly'),
                              ),
                            ],
                            onChanged: (value) {
                              if (value != null) {
                                setState(() {
                                  _paymentPeriod = value;
                                });
                              }
                            },
                          ),
                        ],
                      ),
                      const SizedBox(height: 18),
                      Row(
                        children: [
                          const Icon(Icons.currency_rupee, size: 22, color: AppColors.primaryPurple),
                          const SizedBox(width: 10),
                          const Text(
                            'Subscription Price',
                            style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
                          ),
                          const Spacer(),
                          SizedBox(
                            width: 110,
                            child: TextField(
                              controller: _priceController,
                              keyboardType: const TextInputType.numberWithOptions(decimal: true),
                              decoration: InputDecoration(
                                hintText: 'Set Price',
                                isDense: true,
                                contentPadding: const EdgeInsets.symmetric(vertical: 8, horizontal: 10),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  borderSide: BorderSide(color: AppColors.purple100),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  borderSide: const BorderSide(color: AppColors.primaryPurple, width: 1.5),
                                ),
                              ),
                              style: const TextStyle(fontSize: 16),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

