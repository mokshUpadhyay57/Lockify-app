import 'package:lockify/utils/colors.dart';
import 'package:lockify/utils/snackbar.dart';
import 'dart:convert';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import 'package:lockify/services/chats/chat_service.dart';

class MessageBubble extends StatelessWidget {
  final String message;
  final String? imageUrl;
  final String? base64Thumbnail;
  final File? localFile;
  final String messageType;
  final String time;
  final bool isMe;
  final Color primaryColor;
  final bool isPending;
  final String? currentUid;
  final String? senderName; // Optional: shown in groups/channels
  final String? pollId; // Formalized pollId

  const MessageBubble({
    super.key,
    required this.message,
    this.imageUrl,
    this.base64Thumbnail,
    this.localFile,
    required this.messageType,
    required this.time,
    required this.isMe,
    required this.primaryColor,
    this.isPending = false,
    this.currentUid,
    this.senderName,
    this.pollId,
  });

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
        margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
        child: Column(
          crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Sender name (only for others in groups/channels)
            if (!isMe && senderName != null && senderName!.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(left: 12, bottom: 2),
                child: Text(
                  senderName!,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primaryPurple,
                  ),
                ),
              ),
            
            Container(
              padding: (messageType == 'image' || messageType == 'video') 
                  ? const EdgeInsets.all(4) 
                  : const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: isMe ? primaryColor : AppColors.white,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(20),
                  topRight: const Radius.circular(20),
                  bottomLeft: Radius.circular(isMe ? 20 : 0),
                  bottomRight: Radius.circular(isMe ? 0 : 20),
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.black.withOpacity(0.05),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  )
                ],
              ),
              child: Column(
                crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (messageType == 'image' || messageType == 'video')
                    _buildMediaContent(context),
                  if (messageType == 'document')
                    _buildDocumentContent(),
                  if (messageType == 'poll')
                    _buildPollContent(context),
                  if (messageType == 'text')
                    Text(
                      message,
                      style: TextStyle(
                        color: isMe ? AppColors.white : AppColors.black87,
                        fontSize: 15,
                        height: 1.3,
                      ),
                    ),
                      const SizedBox(height: 4),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        time,
                        style: TextStyle(
                          color: isMe ? AppColors.white.withOpacity(0.7) : AppColors.black54,
                          fontSize: 10,
                        ),
                      ),
                      if (isMe && isPending) ...[
                        const SizedBox(width: 4),
                        Icon(Icons.access_time, size: 10, color: AppColors.white.withOpacity(0.7)),
                      ]
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPollContent(BuildContext context) {
    final String activePollId = pollId ?? imageUrl ?? ""; 
    if (activePollId.isEmpty) return const Text("Invalid Poll");

    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance.collection('polls').doc(activePollId).snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
        final data = snapshot.data!.data() as Map<String, dynamic>?;
        if (data == null) return const Text("Poll not found");

        final question = data['question'] ?? "";
        final options = List<String>.from(data['options'] ?? []);
        final votes = Map<String, dynamic>.from(data['votes'] ?? {});
        final votedUserIds = List<String>.from(data['votedUserIds'] ?? []);
        
        bool hasVoted = currentUid != null && votedUserIds.contains(currentUid);
        int totalVotes = votes.values.fold(0, (sum, v) => sum + (v as int));

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.bar_chart, color: isMe ? AppColors.white : Colors.blue),
                const SizedBox(width: 8),
                Expanded(child: Text(question, style: TextStyle(fontWeight: FontWeight.bold, color: isMe ? AppColors.white : AppColors.black87))),
              ],
            ),
            const SizedBox(height: 10),
            ...options.map((opt) {
              int optVotes = votes[opt] ?? 0;
              double percent = totalVotes == 0 ? 0 : optVotes / totalVotes;
              
              return GestureDetector(
                onTap: hasVoted ? null : () async {
                  try {
                    await ChatService().voteOnPoll(activePollId, opt);
                  } catch (e) {
                    AppSnackBar.error(context, e.toString());
                  }
                },
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(opt, style: TextStyle(fontSize: 13, color: isMe ? AppColors.white : AppColors.black87)),
                          if (hasVoted)
                            Text("${(percent * 100).toInt()}%", style: TextStyle(fontSize: 11, color: isMe ? AppColors.white70 : AppColors.grey)),
                        ],
                      ),
                      const SizedBox(height: 4),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: percent,
                          backgroundColor: isMe ? AppColors.white24 : AppColors.grey200,
                          color: isMe ? AppColors.white : Colors.blue,
                          minHeight: 6,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),
            if (totalVotes > 0)
              Text("$totalVotes votes", style: TextStyle(fontSize: 10, fontStyle: FontStyle.italic, color: isMe ? AppColors.white70 : AppColors.grey)),
          ],
        );
      },
    );
  }

  Widget _buildMediaContent(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: AspectRatio(
        aspectRatio: 1,
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (localFile != null) Image.file(localFile!, fit: BoxFit.cover),
            if (localFile == null && imageUrl != null && imageUrl!.trim().isNotEmpty && imageUrl!.startsWith('http'))
              Image.network(
                imageUrl!,
                fit: BoxFit.cover,
                frameBuilder: (context, child, frame, wasSynchronouslyLoaded) {
                  if (wasSynchronouslyLoaded) return child;
                  return AnimatedOpacity(opacity: frame == null ? 0 : 1, duration: const Duration(milliseconds: 300), curve: Curves.easeOut, child: child);
                },
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) return child;
                  return (base64Thumbnail != null && base64Thumbnail!.isNotEmpty)
                    ? Image.memory(base64Decode(base64Thumbnail!), fit: BoxFit.cover)
                    : Container(color: AppColors.grey100, child: const Center(child: CircularProgressIndicator(strokeWidth: 2)));
                },
                errorBuilder: (context, error, stackTrace) => Container(color: AppColors.grey100, child: const Icon(Icons.broken_image, color: AppColors.grey)),
              ),
            if (localFile == null && (imageUrl == null || imageUrl!.isEmpty) && base64Thumbnail != null)
              Image.memory(base64Decode(base64Thumbnail!), fit: BoxFit.cover),
            if (messageType == 'video')
              const Center(child: Icon(Icons.play_circle_fill, color: AppColors.white70, size: 50)),
            if (isPending)
              const Center(child: CircularProgressIndicator(color: AppColors.white, strokeWidth: 2)),
          ],
        ),
      ),
    );
  }

  Widget _buildDocumentContent() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(Icons.description, color: AppColors.warningOrange, size: 30),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                isMe ? "Sent Document" : "Document", 
                style: TextStyle(
                  color: isMe ? AppColors.white : AppColors.black87,
                  fontWeight: FontWeight.bold,
                )
              ),
              if (!isMe)
                const Text("Tap to view", style: TextStyle(color: AppColors.grey, fontSize: 11)),
            ],
          ),
        ),
      ],
    );
  }
}

