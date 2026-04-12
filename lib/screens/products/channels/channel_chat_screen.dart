import 'package:lockify/utils/colors.dart';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:sticky_headers/sticky_headers.dart';
import 'package:lockify/components/widgets/lockify_scaffold.dart';
import 'package:lockify/components/widgets/chat_input.dart';
import 'package:lockify/components/widgets/message_bubble.dart';
import 'package:lockify/screens/products/channels/channel_screen.dart';
import 'package:lockify/screens/products/chats/poll_screen.dart';
import 'package:lockify/screens/products/channels/channel_info_screen.dart';
import 'package:lockify/services/auth/auth_service.dart';
import 'package:lockify/services/channel/channel_service.dart';
import 'package:lockify/services/media_service.dart';
import 'package:lockify/utils/snackbar.dart';

import 'package:lockify/utils/chat_date_mixin.dart';

class ChannelDetailPage extends StatefulWidget {
  final String channelId;
  final String channelName;
  final String? channelDesc;
  final String? channelImage;
  final bool? isPaid;
  final List? participants;

  const ChannelDetailPage({
    super.key,
    required this.channelId,
    required this.channelName,
    this.channelDesc,
    this.channelImage,
    this.isPaid,
    this.participants,
  });

  @override
  State<ChannelDetailPage> createState() => _ChannelDetailPageState();
}

class _ChannelDetailPageState extends State<ChannelDetailPage> with ChatDateMixin {
  final AuthService _authService = AuthService();
  final ChannelService _channelService = ChannelService();
  final MediaService _mediaService = MediaService();
  late Future<bool> isCreator;
  bool _isUploading = false;
  File? _pendingMedia;
  MediaType? _pendingType;

  @override
  void initState() {
    super.initState();
    isCreator = _channelService.isCreator(widget.channelId);
  }

  void _handleMediaSend(File file, MediaType type) async {
    if (mounted) {
      setState(() {
        _isUploading = true;
        _pendingMedia = file;
        _pendingType = type;
      });
    }
    try {
      await _mediaService.sendChannelMediaMessage(
        context: context,
        channelId: widget.channelId,
        file: file,
        type: type,
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
    final primaryColor = AppColors.primaryPurple;

    return LockifyScaffold(
      backgroundColor: AppColors.backgroundGrey,
      titleWidget: GestureDetector(
        onTap:() async {
          Map<String, dynamic>? initialData;
          var isPaid = widget.isPaid;
          if (widget.participants == null || isPaid == null) {
            initialData = await _channelService.getChannelById(widget.channelId);
            isPaid = initialData?['isPaid'] ?? false;
          }
          if (mounted) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => ChannelInfoScreen(
                  channelId: widget.channelId,
                  channelName: widget.channelName,
                  isPaid: isPaid!,
                  initialData: initialData,
                ),
              ),
            );
          }
        },
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: AppColors.white.withOpacity(0.2),
              radius: 18,
              child: Text(
                widget.channelName.isNotEmpty ? widget.channelName[0].toUpperCase() : "?",
                style: const TextStyle(fontSize: 16, color: AppColors.white, fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(widget.channelName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16), overflow: TextOverflow.ellipsis),
                  FutureBuilder<Map<String, dynamic>?>(
                    future: _channelService.getChannelById(widget.channelId),
                    builder: (context, snapshot) {
                      final creatorUid = snapshot.data?['createdBy'] ?? '';
                      if (creatorUid.isEmpty) return const SizedBox.shrink();
                      
                      return StreamBuilder<DocumentSnapshot>(
                        stream: FirebaseFirestore.instance.collection('users').doc(creatorUid).snapshots(),
                        builder: (context, userSnap) {
                          final isOnline = (userSnap.data?.data() as Map<String, dynamic>?)?['isOnline'] ?? false;
                          return Text(
                            isOnline ? "creator online" : "creator offline",
                            style: const TextStyle(fontSize: 11, color: AppColors.white70),
                          );
                        },
                      );
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      actions: [
        FutureBuilder<bool>(
          future: isCreator,
          builder: (context, snapshot) {
            final isCreatorUser = snapshot.data ?? false;
            return PopupMenuButton<String>(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
              onSelected: (value) async {
                if (value == 'info') {
                  Map<String, dynamic>? initialData;
                  var isPaid = widget.isPaid;
                  if (widget.participants == null || isPaid == null) {
                    initialData = await _channelService.getChannelById(widget.channelId);
                    isPaid = initialData?['isPaid'] ?? false;
                  }
                  if (mounted) {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ChannelInfoScreen(
                          channelId: widget.channelId,
                          channelName: widget.channelName,
                          isPaid: isPaid!,
                          initialData: initialData,
                        ),
                      ),
                    );
                  }
                } else if (value == 'leave' || value == 'delete') {
                  final isDelete = value == 'delete';
                  final confirm = await showDialog<bool>(
                    context: context,
                    builder: (context) => AlertDialog(
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                      title: Text(isDelete ? 'Delete Channel' : 'Leave Channel'),
                      content: Text(isDelete ? 'Are you sure you want to delete this channel for everyone?' : 'Are you sure you want to leave this channel?'),
                      actions: [
                        TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
                        TextButton(
                          onPressed: () => Navigator.pop(context, true), 
                          child: Text(isDelete ? 'Delete' : 'Leave', style: const TextStyle(color: AppColors.errorRed)),
                        ),
                      ],
                    ),
                  );

                  if (confirm == true) {
                    try {
                      if (isDelete) {
                        await _channelService.deleteChannel(widget.channelId);
                      } else {
                        await _channelService.leaveChannel(widget.channelId);
                      }
                      if (mounted) {
                        Navigator.pushAndRemoveUntil(
                          context, 
                          MaterialPageRoute(builder: (context) => const ChannelScreen()),
                          (route) => route.isFirst,
                        );
                      }
                    } catch (e) {
                      AppSnackBar.error(context, "Action failed: $e");
                    }
                  }
                }
              },
              itemBuilder: (context) => [
                const PopupMenuItem(value: 'info', child: ListTile(dense: true, leading: Icon(Icons.info_outline), title: Text('Channel Info'))),
                PopupMenuItem(
                  value: isCreatorUser ? 'delete' : 'leave', 
                  child: ListTile(
                    dense: true,
                    leading: Icon(isCreatorUser ? Icons.delete_outline : Icons.exit_to_app, color: AppColors.errorRed),
                    title: Text(isCreatorUser ? 'Delete Channel' : 'Leave Channel', style: const TextStyle(color: AppColors.errorRed)),
                  ),
                ),
              ],
            );
          }
        ),
      ],
      body: FutureBuilder<bool>(
        future: isCreator,
        builder: (context, creatorSnapshot) {
          if (creatorSnapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final canSend = creatorSnapshot.data == true;

          return Column(
            children: [
              if (_isUploading) const LinearProgressIndicator(color: AppColors.primaryPurple),
              Expanded(
                child: StreamBuilder<QuerySnapshot>(
                  stream: _channelService.getChannelMessages(widget.channelId),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    final docs = snapshot.data?.docs ?? [];
                    if (docs.isEmpty && !_isUploading) {
                      return const Center(child: Text('No messages yet.', style: TextStyle(color: AppColors.grey)));
                    }

                    // Group messages by date
                    final Map<String, List<QueryDocumentSnapshot>> groupedMessages = {};
                    for (var doc in docs) {
                      final data = doc.data() as Map<String, dynamic>;
                      final timestamp = data['timestamp'];
                      final date = getDateTime(timestamp).toLocal();
                      final dateString = formatDate(date);
                      groupedMessages.putIfAbsent(dateString, () => []).add(doc);
                    }

                    final dateKeys = groupedMessages.keys.toList();

                    return ListView.builder(
                      reverse: true,
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
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
                                  messageType: _pendingType == MediaType.image ? 'image' : _pendingType == MediaType.video ? 'video' : 'document',
                                  time: 'Sending...',
                                  isMe: true,
                                  primaryColor: primaryColor,
                                  isPending: true,
                                  localFile: _pendingMedia,
                                ),
                              ListView.builder(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                reverse: true,
                                itemCount: messages.length,
                                itemBuilder: (context, msgIndex) {
                                  final message = messages[msgIndex].data() as Map<String, dynamic>;
                                  final myUid = _authService.getCurrentUser()?.uid;
                                  final isMe = message['senderUid'] == myUid;
                                  final timestamp = message['timestamp'] as Timestamp?;
                                  final formattedTime = timestamp != null ? DateFormat('hh:mm a').format(timestamp.toDate()) : '';

                                  return MessageBubble(
                                    message: message['message'] ?? '',
                                    imageUrl: message['imageUrl'],
                                    base64Thumbnail: message['base64Thumbnail'],
                                    messageType: message['messageType'] ?? 'text',
                                    time: formattedTime,
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

              if (canSend)
                ChatInput(
                  primaryColor: primaryColor,
                  onSendText: (message) async {
                    try {
                      await _channelService.sendChannelMessage(channelId: widget.channelId, message: message);
                    } catch (e) {
                      AppSnackBar.error(context, 'Failed to send: $e');
                    }
                  },
                  onSendMedia: (file, type) async {
                    _handleMediaSend(file, type);
                  },
                  onAddPoll: () {
                    Navigator.push(context, MaterialPageRoute(builder: (context) => AddPollScreen(
                      channelId: widget.channelId,
                      channelName: widget.channelName,
                    )));
                  },
                )
              else
                const Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Text(
                    "Only the channel creator can send messages.",
                    style: TextStyle(color: AppColors.grey, fontStyle: FontStyle.italic),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}

