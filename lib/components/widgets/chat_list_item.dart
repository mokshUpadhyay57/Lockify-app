import 'package:lockify/utils/colors.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_contacts/flutter_contacts.dart';
import 'package:intl/intl.dart';
import 'package:lockify/services/auth/auth_service.dart';

import 'package:lockify/components/widgets/online_indicator.dart';

class ChatListItem extends StatelessWidget {
  final Map<String, dynamic>? chatData;
  final String? myPhone;
  final List<Contact> localContacts;
  final VoidCallback onTap;

  // Optional overrides
  final String? title;
  final String? subtitle;
  final dynamic timestamp;
  final String? type;

  const ChatListItem({
    super.key,
    this.chatData,
    this.myPhone,
    required this.localContacts,
    required this.onTap,
    this.title,
    this.subtitle,
    this.timestamp,
    this.type,
  });

  String _formatTime(dynamic time) {
    DateTime dateTime;
    if (time is Timestamp) {
      dateTime = time.toDate();
    } else if (time is DateTime) {
      dateTime = time;
    } else {
      dateTime = DateTime.now();
    }
    return DateFormat('hh:mm a').format(dateTime);
  }

  @override
  Widget build(BuildContext context) {
    final authService = AuthService();
    final data = chatData ?? {};
    
    // 1. Resolve Type
    final chatType = type ?? data['type'] ?? 'private';
    
    // 2. Resolve Receiver Phone (for private chats)
    String receiverPhone = "";
    if (chatType == 'private' && myPhone != null) {
      final participantPhones = List<String>.from(data['participantPhones'] ?? []);
      final normalizedMyPhone = authService.normalizePhone(myPhone!);
      receiverPhone = participantPhones.firstWhere(
        (p) => authService.normalizePhone(p) != normalizedMyPhone,
        orElse: () => participantPhones.isNotEmpty ? participantPhones.first : ""
      );
    }

    // 3. Resolve Display Name (Title)
    String displayTitle = title ?? "";
    if (displayTitle.isEmpty) {
      if (chatType == 'private') {
        displayTitle = authService.resolveName(
          phone: receiverPhone,
          localContacts: localContacts,
          dbNames: data['participantNames'],
        );
      } else {
        displayTitle = data['name'] ?? "Unnamed";
      }
    }

    // 4. Resolve Subtitle (Last Message & System Logic)
    final messageType = data['messageType'] as String?;
    final lastMsg = subtitle ?? data['lastMessage'] ?? (chatType == 'private' ? "Tap to start chatting" : "New Chat created");
    String displaySubtitle = lastMsg;

    if (messageType == 'system' || lastMsg == 'left' || lastMsg == 'created') {
      final lastSenderPhone = data['lastSenderPhone'] as String?;
      String senderName = authService.resolveName(
        phone: lastSenderPhone ?? "",
        localContacts: localContacts,
      );
      
      if (lastMsg == 'left') {
        displaySubtitle = "$senderName left";
      } else if (lastMsg == 'created') {
        displaySubtitle = "$senderName created the $chatType";
      }
    }

    // 5. Resolve Timestamp
    final displayTime = timestamp ?? data['lastMessageTimestamp'] ?? data['createdAt'];

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 16),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: AppColors.primaryPurple.withOpacity(0.06),
              blurRadius: 12,
              spreadRadius: 1,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          leading: Stack(
            children: [
              CircleAvatar(
                radius: 26,
                backgroundColor: _getAvatarColor(chatType).withOpacity(0.15),
                child: Text(
                  displayTitle.isNotEmpty ? displayTitle[0].toUpperCase() : '?',
                  style: TextStyle(
                    fontWeight: FontWeight.bold, 
                    color: _getAvatarColor(chatType), 
                    fontSize: 20
                  ),
                ),
              ),
              if (chatType == 'private' && receiverPhone.isNotEmpty)
                Positioned(
                  right: 0,
                  bottom: 0,
                  child: OnlineIndicator(phone: receiverPhone),
                ),
            ],
          ),
          title: Text(
            displayTitle, 
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          subtitle: Text(
            displaySubtitle,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: messageType == 'system' ? AppColors.grey : AppColors.black87.withOpacity(0.6), 
              fontSize: 13,
              fontStyle: messageType == 'system' ? FontStyle.italic : FontStyle.normal,
            ),
          ),
          trailing: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                _formatTime(displayTime),
                style: const TextStyle(color: AppColors.grey, fontSize: 11),
              ),
              const SizedBox(height: 4),
              if (messageType == 'image')
                const Icon(Icons.camera_alt, size: 14, color: AppColors.grey),
            ],
          ),
        ),
      ),
    );
  }

  Color _getAvatarColor(String chatType) {
    switch (chatType) {
      case 'group': return Colors.blue;
      case 'channel': return AppColors.warningOrange;
      default: return AppColors.primaryPurple;
    }
  }
}

