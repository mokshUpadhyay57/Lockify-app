import 'package:lockify/utils/colors.dart';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:sticky_headers/sticky_headers.dart';
import 'package:lockify/components/widgets/lockify_scaffold.dart';
import 'package:lockify/components/widgets/message_bubble.dart';
import 'package:lockify/components/widgets/chat_input.dart';
import 'package:lockify/components/widgets/online_indicator.dart';
import 'package:lockify/screens/products/chats/poll_screen.dart';
import 'package:lockify/screens/settings/profile/profile_screen.dart';
import 'package:lockify/services/auth/auth_service.dart';
import 'package:lockify/services/chats/chat_service.dart';
import 'package:lockify/services/contact_service.dart';
import 'package:lockify/services/media_service.dart';

import 'package:lockify/utils/chat_date_mixin.dart';
import 'package:lockify/utils/snackbar.dart';
import 'package:flutter_contacts/flutter_contacts.dart';

class ChatDetailPage extends StatefulWidget {
  final String recieverPhone;
  final String recieverName;

  const ChatDetailPage({super.key, required this.recieverPhone, required this.recieverName});

  @override
  State<ChatDetailPage> createState() => _ChatDetailPageState();
}

class _ChatDetailPageState extends State<ChatDetailPage> with ChatDateMixin {
  final ChatService _chatService = ChatService();
  final AuthService _authService = AuthService();
  final ContactService _contactService = ContactService();
  final MediaService _mediaService = MediaService();

  late final Future<String> currentUserPhone;
  late final Future<List<Contact>> _contactsFuture;
  bool _isUploading = false;
  File? _pendingMedia; 
  MediaType? _pendingType;

  @override
  void initState() {
    super.initState();
    currentUserPhone = _chatService.getSenderPhone();
    _contactsFuture = _contactService.getCachedContacts(context);
  }

  Future<void> _handleMediaSend(File file, MediaType type) async {
    if (mounted) {
      setState(() {
        _pendingMedia = file;
        _pendingType = type;
        _isUploading = true;
      });
    }

    try {
      await _mediaService.sendMediaMessage(
        receiverPhone: widget.recieverPhone,
        file: file,
        type: type,
        receiverName: widget.recieverName,
      );
    } catch (e) {
      AppSnackBar.error(context, 'Failed to send: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isUploading = false;
          _pendingMedia = null;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    const primaryColor = AppColors.primaryPurple;

    return LockifyScaffold(
      backgroundColor: AppColors.backgroundGrey,
      titleWidget: _ChatAppBarTitle(
        receiverPhone: widget.recieverPhone,
        chatService: _chatService,
        contactsFuture: _contactsFuture,
      ),
      actions: [
        PopupMenuButton<String>(
          icon: const Icon(Icons.more_vert),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
          onSelected: (value) {
            switch (value) {
              case 'profile':
                Navigator.push(context, MaterialPageRoute(builder: (context) => const ProfileScreen()));
                break;
              case 'search':
                AppSnackBar.info(context, 'Search coming soon');
                break;
              case 'mute':
                AppSnackBar.info(context, 'Notifications muted');
                break;
              case 'clear':
                AppSnackBar.success(context, 'Chat cleared locally');
                break;
              case 'block':
                AppSnackBar.error(context, 'User blocked');
                break;
            }
          },
          itemBuilder: (context) => [
            const PopupMenuItem(
                value: 'profile',
                child: ListTile(dense: true, leading: Icon(Icons.person_outline), title: Text('View Profile'))),
            const PopupMenuItem(
                value: 'search', child: ListTile(dense: true, leading: Icon(Icons.search), title: Text('Search'))),
            const PopupMenuItem(
                value: 'mute',
                child: ListTile(
                    dense: true, leading: Icon(Icons.notifications_off_outlined), title: Text('Mute Notifications'))),
            const PopupMenuItem(
                value: 'clear',
                child: ListTile(dense: true, leading: Icon(Icons.delete_sweep_outlined), title: Text('Clear Chat'))),
            const PopupMenuDivider(),
            const PopupMenuItem(
                value: 'block',
                child: ListTile(
                    dense: true,
                    leading: Icon(Icons.block, color: AppColors.errorRed),
                    title: Text('Block User', style: TextStyle(color: AppColors.errorRed)))),
          ],
        ),
      ],
      body: FutureBuilder<String>(
        future: currentUserPhone,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
          final userPhone = snapshot.data ?? '';
          final normalizedUserPhone = _chatService.normalizePhone(userPhone);

          return Column(
            children: [
              if (_isUploading) const LinearProgressIndicator(color: AppColors.primaryPurple),
              Expanded(
                child: StreamBuilder<QuerySnapshot>(
                  stream: _chatService.getMessages(normalizedUserPhone, widget.recieverPhone),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
                    final docs = snapshot.data?.docs ?? [];
                    if (docs.isEmpty && !_isUploading) return _buildEmptyState();

                    final Map<String, List<QueryDocumentSnapshot>> groupedMessages = {};
                    for (var doc in docs) {
                      final data = doc.data() as Map<String, dynamic>?;
                      if (data == null) continue;
                      final timestamp = data['timestamp'];
                      final date = getDateTime(timestamp).toLocal();
                      final dateString = formatDate(date);
                      groupedMessages.putIfAbsent(dateString, () => []).add(doc);
                    }

                    final dateKeys = groupedMessages.keys.toList();

                    return ListView.builder(
                      reverse: true,
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      itemCount: dateKeys.length,
                      itemBuilder: (context, dateIndex) {
                        final dateString = dateKeys[dateIndex];
                        final messages = groupedMessages[dateString]!;

                        return StickyHeader(
                          header: buildStickyDateHeader(dateString),
                          content: Column(
                            children: [
                              if (dateIndex == 0 && _isUploading && _pendingMedia != null)
                                MessageBubble(
                                  message: '',
                                  messageType: _pendingType == MediaType.image
                                      ? 'image'
                                      : _pendingType == MediaType.video
                                          ? 'video'
                                          : 'document',
                                  time: 'Sending...',
                                  isMe: true,
                                  primaryColor: AppColors.primaryPurple,
                                  isPending: true,
                                  localFile: _pendingMedia,
                                ),
                              ListView.builder(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                reverse: true,
                                itemCount: messages.length,
                                itemBuilder: (context, msgIndex) {
                                  final data = messages[msgIndex].data() as Map<String, dynamic>;
                                  final myUid = _authService.getCurrentUser()?.uid;
                                  final isMe = data['senderUid'] == myUid;

                                  return MessageBubble(
                                    message: data['message'] ?? '',
                                    imageUrl: data['imageUrl'],
                                    base64Thumbnail: data['base64Thumbnail'],
                                    messageType: data['messageType'] ?? 'text',
                                    time: DateFormat('hh:mm a').format(getDateTime(data['timestamp'])),
                                    isMe: isMe,
                                    primaryColor: primaryColor,
                                    currentUid: myUid,
                                  );
                                },
                              ),
                            ],
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
              ChatInput(
                primaryColor: primaryColor,
                onSendText: (message) async {
                  await _chatService.sendMessage(context, widget.recieverPhone, message,
                      receiverName: widget.recieverName);
                },
                onSendMedia: (file, type) async {
                  await _handleMediaSend(file, type);
                },
                onAddPoll: () {
                  Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => AddPollScreen(
                                receiverPhone: widget.recieverPhone,
                                receiverName: widget.recieverName,
                              )));
                },
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.chat_bubble_outline, size: 64, color: AppColors.grey300),
          const SizedBox(height: 16),
          const Text('No messages yet', style: TextStyle(color: AppColors.grey)),
        ],
      ),
    );
  }
}

class _ChatAppBarTitle extends StatefulWidget {
  final String receiverPhone;
  final ChatService chatService;
  final Future<List<Contact>> contactsFuture;

  const _ChatAppBarTitle({
    required this.receiverPhone,
    required this.chatService,
    required this.contactsFuture,
  });

  @override
  State<_ChatAppBarTitle> createState() => _ChatAppBarTitleState();
}

class _ChatAppBarTitleState extends State<_ChatAppBarTitle> {
  String? _resolvedName;
  final AuthService _authService = AuthService();

  @override
  void initState() {
    super.initState();
    _initIdentity();
  }

  Future<void> _initIdentity() async {
    final contacts = await widget.contactsFuture;
    if (mounted) {
      setState(() {
        _resolvedName = _authService.resolveName(
          phone: widget.receiverPhone,
          localContacts: contacts,
        );
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final displayName = _resolvedName ?? widget.receiverPhone;

    return Row(
      children: [
        Stack(
          children: [
            CircleAvatar(
              radius: 18,
              backgroundColor: AppColors.white.withOpacity(0.2),
              child: Text(
                displayName.isNotEmpty ? displayName[0].toUpperCase() : '?',
                style: const TextStyle(fontSize: 14, color: AppColors.white, fontWeight: FontWeight.bold),
              ),
            ),
            Positioned(
              right: 0,
              bottom: 0,
              child: OnlineIndicator(
                phone: widget.receiverPhone,
                size: 10,
                borderWidth: 1.5,
              ),
            ),
          ],
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                displayName,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.white),
                overflow: TextOverflow.ellipsis,
              ),
              _StatusText(phone: widget.receiverPhone),
            ],
          ),
        ),
      ],
    );
  }
}

class _StatusText extends StatelessWidget {
  final String phone;
  const _StatusText({required this.phone});

  @override
  Widget build(BuildContext context) {
    final authService = AuthService();
    final normalized = authService.normalizePhone(phone);

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .where('phone', isEqualTo: normalized)
          .limit(1)
          .snapshots(),
      builder: (context, snapshot) {
        bool isOnline = false;
        if (snapshot.hasData && snapshot.data!.docs.isNotEmpty) {
          isOnline = (snapshot.data!.docs.first.data() as Map<String, dynamic>)['isOnline'] ?? false;
        }

        return Text(
          isOnline ? 'Online' : 'Offline',
          style: TextStyle(
            fontSize: 12,
            color: AppColors.white.withOpacity(0.8),
            fontWeight: FontWeight.w400,
          ),
        );
      },
    );
  }
}
