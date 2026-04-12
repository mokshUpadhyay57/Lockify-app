import 'package:lockify/utils/colors.dart';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'package:lockify/services/media_service.dart';


class ChatInput extends StatefulWidget {
  final Function(String) onSendText;
  final Function(File, MediaType) onSendMedia;
  final VoidCallback onAddPoll;
  final Color primaryColor;
  final String hintText;

  const ChatInput({
    super.key,
    required this.onSendText,
    required this.onSendMedia,
    required this.onAddPoll,
    this.primaryColor = AppColors.primaryPurple,
    this.hintText = 'Message...',
  });

  @override
  State<ChatInput> createState() => _ChatInputState();
}

class _ChatInputState extends State<ChatInput> {
  final TextEditingController _messageController = TextEditingController();
  final ValueNotifier<bool> _isTextFieldEmpty = ValueNotifier<bool>(true);
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _messageController.addListener(() {
      _isTextFieldEmpty.value = _messageController.text.trim().isEmpty;
    });
  }

  @override
  void dispose() {
    _messageController.dispose();
    _isTextFieldEmpty.dispose();
    super.dispose();
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? pickedFile = await _picker.pickImage(source: source);
      if (pickedFile != null) {
        widget.onSendMedia(File(pickedFile.path), MediaType.image);
      }
    } catch (e) {
      debugPrint('Error picking image: $e');
    }
  }

  Future<void> _pickVideo() async {
    try {
      final XFile? video = await _picker.pickVideo(source: ImageSource.gallery);
      if (video != null) {
        widget.onSendMedia(File(video.path), MediaType.video);
      }
    } catch (e) {
      debugPrint('Error picking video: $e');
    }
  }

  Future<void> _pickFile() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles();
      if (result != null && result.files.single.path != null) {
        widget.onSendMedia(File(result.files.single.path!), MediaType.document);
      }
    } catch (e) {
      debugPrint('Error picking file: $e');
    }
  }

  void _showAttachmentOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 30),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40, 
              height: 4, 
              decoration: BoxDecoration(
                color: AppColors.grey300, 
                borderRadius: BorderRadius.circular(10)
              )
            ),
            const SizedBox(height: 25),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildAttachmentItem(Icons.image_rounded, 'Gallery', Colors.blue, () {
                  Navigator.pop(context);
                  _pickImage(ImageSource.gallery);
                }),
                _buildAttachmentItem(Icons.videocam_rounded, 'Video', AppColors.errorRed, () {
                  Navigator.pop(context);
                  _pickVideo();
                }),
                _buildAttachmentItem(Icons.insert_drive_file_rounded, 'Document', AppColors.warningOrange, () {
                  Navigator.pop(context);
                  _pickFile();
                }),
                _buildAttachmentItem(Icons.bar_chart_rounded, 'Poll', AppColors.primaryPurple, () {
                  Navigator.pop(context);
                  widget.onAddPoll();
                }),
              ],
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildAttachmentItem(IconData icon, String label, Color color, VoidCallback onTap) {
    return Column(
      children: [
        InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(15),
          child: Container(
            width: 60, height: 60,
            decoration: BoxDecoration(
              color: color.withOpacity(0.1), 
              borderRadius: BorderRadius.circular(15)
            ),
            child: Icon(icon, color: color, size: 28),
          ),
        ),
        const SizedBox(height: 10),
        Text(
          label, 
          style: const TextStyle(
            fontSize: 13, 
            fontWeight: FontWeight.w500, 
            color: AppColors.black87
          )
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.white, 
        boxShadow: [
          BoxShadow(
            color: AppColors.black.withOpacity(0.05), 
            offset: const Offset(0, -1), 
            blurRadius: 4
          )
        ]
      ),
      child: SafeArea(
        child: Row(
          children: [
            ValueListenableBuilder<bool>(
              valueListenable: _isTextFieldEmpty,
              builder: (context, isEmpty, child) {
                return IconButton(
                  icon: Icon(
                    isEmpty ? Icons.attach_file : Icons.add_circle_outline, 
                    color: widget.primaryColor
                  ), 
                  onPressed: _showAttachmentOptions
                );
              },
            ),
            Expanded(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: AppColors.grey100, 
                  borderRadius: BorderRadius.circular(24)
                ),
                child: TextField(
                  controller: _messageController, 
                  maxLines: 4, 
                  minLines: 1, 
                  decoration: InputDecoration(
                    hintText: widget.hintText, 
                    border: InputBorder.none
                  )
                ),
              ),
            ),
            const SizedBox(width: 8),
            ValueListenableBuilder<bool>(
              valueListenable: _isTextFieldEmpty,
              builder: (context, isEmpty, child) {
                return GestureDetector(
                  onTap: isEmpty ? null : () {
                    final message = _messageController.text.trim();
                    if (message.isNotEmpty) {
                      widget.onSendText(message);
                      _messageController.clear();
                    }
                  },
                  child: CircleAvatar(
                    backgroundColor: isEmpty ? AppColors.grey300 : widget.primaryColor, 
                    child: const Icon(Icons.send, color: AppColors.white, size: 20)
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

