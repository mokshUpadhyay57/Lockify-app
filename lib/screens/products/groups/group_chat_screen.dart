import 'package:lockify/utils/snackbar.dart';
import 'package:lockify/utils/colors.dart';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:sticky_headers/sticky_headers.dart';
import 'package:lockify/components/widgets/lockify_scaffold.dart';
import 'package:lockify/components/widgets/chat_input.dart';
import 'package:lockify/components/widgets/message_bubble.dart';
import 'package:lockify/screens/products/chats/poll_screen.dart';
import 'package:lockify/screens/products/groups/group_info_screen.dart';
import 'package:lockify/screens/products/groups/group_screen.dart';
import 'package:lockify/services/auth/auth_service.dart';
import 'package:lockify/services/group/group_service.dart';
import 'package:lockify/services/media_service.dart';

import 'package:lockify/utils/chat_date_mixin.dart';
import 'package:lockify/utils/contacts.dart' as contact_util;
import 'package:flutter_contacts/flutter_contacts.dart';

class GroupChatScreen extends StatefulWidget {
  final String groupId;
  final String groupName;
  final String? groupDesc;
  final String? groupImage;
  final bool? isPaid;
  final List? participants;

  const GroupChatScreen({
    super.key,
    required this.groupId,
    required this.groupName,
    this.groupDesc,
    this.groupImage,
    this.isPaid,
    this.participants,
  });

  @override
  State<GroupChatScreen> createState() => _GroupChatScreenState();
}

class _GroupChatScreenState extends State<GroupChatScreen> with ChatDateMixin {
  final AuthService _authService = AuthService();
  final GroupService _groupService = GroupService();
  final MediaService _mediaService = MediaService();
  
  late final Future<List<Contact>> _contactsFuture;
  bool _isUploading = false;
  File? _pendingMedia;
  MediaType? _pendingType;

  @override
  void initState() {
    super.initState();
    _contactsFuture = contact_util.getContacts(context);
  }

  Future<void> _handleMediaSend(File file, MediaType type) async {
    if (mounted) {
      setState(() {
        _isUploading = true;
        _pendingMedia = file;
        _pendingType = type;
      });
    }
    try {
      await _mediaService.sendGroupMediaMessage(
        context: context,
        groupId: widget.groupId,
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

  Widget _buildGroupStatus() {
    final uids = List<String>.from(widget.participants ?? []);
    if (uids.isEmpty) return const Text("Group", style: TextStyle(fontSize: 11, color: AppColors.white70));

    final subsetUids = uids.take(10).toList();

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .where('uid', whereIn: subsetUids)
          .where('isOnline', isEqualTo: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Text("Group", style: TextStyle(fontSize: 11, color: AppColors.white70));
        
        final onlineCount = snapshot.data!.docs.length;
        if (onlineCount > 0) {
          return Text(
            "$onlineCount online", 
            style: const TextStyle(fontSize: 11, color: AppColors.white, fontWeight: FontWeight.w500)
          );
        }
        return const Text("Group", style: TextStyle(fontSize: 11, color: AppColors.white70));
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final primaryColor = AppColors.primaryPurple;

    return LockifyScaffold(
      backgroundColor: AppColors.backgroundGrey,
      titleWidget: GestureDetector(
        onTap: () async {
          Map<String, dynamic>? initialData;
          var isPaid = widget.isPaid;
          if (widget.participants == null || isPaid == null) {
            initialData = await _groupService.getGroupById(widget.groupId);
            isPaid = initialData?['isPaid'] ?? false;
          }
          if (mounted) {
            Navigator.push(context, MaterialPageRoute(builder: (context) => 
              GroupInfoScreen(
                groupId: widget.groupId,
                groupName: widget.groupName, 
                isPaid: isPaid!,
                initialData: initialData,
              )
            ));
          }
        },
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: AppColors.white.withOpacity(0.2),
              radius: 18,
              child: Text(
                widget.groupName.isNotEmpty ? widget.groupName[0].toUpperCase() : "?",
                style: const TextStyle(fontSize: 16, color: AppColors.white, fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(widget.groupName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16), overflow: TextOverflow.ellipsis),
                  _buildGroupStatus(),
                ],
              ),
            ),
          ],
        ),
      ),
      actions: [
        FutureBuilder<bool>(
          future: _groupService.isCreator(widget.groupId),
          builder: (context, snapshot) {
            final isCreator = snapshot.data ?? false;
            return PopupMenuButton<String>(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
              onSelected: (value) async {
                if (value == 'info') {
                  Map<String, dynamic>? initialData;
                  var isPaid = widget.isPaid;
                  if (widget.participants == null || isPaid == null) {
                    initialData = await _groupService.getGroupById(widget.groupId);
                    isPaid = initialData?['isPaid'] ?? false;
                  }
                  if (mounted) {
                    Navigator.push(context, MaterialPageRoute(builder: (context) => 
                      GroupInfoScreen(
                        groupId: widget.groupId,
                        groupName: widget.groupName, 
                        isPaid: isPaid!,
                        initialData: initialData,
                      )
                    ));
                  }
                } else if (value == 'leave' || value == 'delete') {
                  final isDelete = value == 'delete';
                  final confirm = await showDialog<bool>(
                    context: context,
                    builder: (context) => AlertDialog(
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                      title: Text(isDelete ? 'Delete Group' : 'Leave Group'),
                      content: Text(isDelete ? 'Are you sure you want to delete this group for everyone?' : 'Are you sure you want to leave this group?'),
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
                        await _groupService.deleteGroup(widget.groupId);
                      } else {
                        await _groupService.leaveGroup(widget.groupId);
                      }
                      if (mounted) {
                        Navigator.pushAndRemoveUntil(
                          context, 
                          MaterialPageRoute(builder: (context) => const GroupScreen()),
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
                const PopupMenuItem(value: 'info', child: ListTile(dense: true, leading: Icon(Icons.info_outline), title: Text('Group Info'))),
                PopupMenuItem(
                  value: isCreator ? 'delete' : 'leave', 
                  child: ListTile(
                    dense: true,
                    leading: Icon(isCreator ? Icons.delete_outline : Icons.exit_to_app, color: AppColors.errorRed),
                    title: Text(isCreator ? 'Delete Group' : 'Leave Group', style: const TextStyle(color: AppColors.errorRed)),
                  ),
                ),
              ],
            );
          }
        ),
      ],
      body: Column(
        children: [
          if (_isUploading) const LinearProgressIndicator(color: AppColors.primaryPurple),
          Expanded(
            child: FutureBuilder<List<Contact>>(
              future: _contactsFuture,
              builder: (context, contactSnap) {
                final localContacts = contactSnap.data ?? [];
                
                return StreamBuilder<QuerySnapshot>(
                  stream: _groupService.getGroupMessages(widget.groupId),
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

                                  String? displayName;
                                  if (!isMe) {
                                    final senderPhone = message['senderPhone'] as String? ?? '';
                                    displayName = _authService.resolveName(
                                      phone: senderPhone,
                                      localContacts: localContacts,
                                    );
                                  }
                                  
                                  return MessageBubble(
                                    message: message['message'] ?? '',
                                    imageUrl: message['imageUrl'],
                                    base64Thumbnail: message['base64Thumbnail'],
                                    messageType: message['messageType'] ?? 'text',
                                    time: formattedTime,
                                    isMe: isMe,
                                    primaryColor: primaryColor,
                                    currentUid: myUid,
                                    senderName: displayName,
                                  );
                                },
                              ),
                            ],
                          ),
                        );
                      },
                    );
                  },
                );
              }
            ),
          ),

          ChatInput(
            primaryColor: primaryColor,
            onSendText: (message) async {
              try {
                await _groupService.sendGroupMessage(groupId: widget.groupId, message: message);
              } catch (e) {
                AppSnackBar.error(context, 'Failed to send: $e');
              }
            },
            onSendMedia: (file, type) async {
              await _handleMediaSend(file, type);
            },
            onAddPoll: () {
              Navigator.push(context, MaterialPageRoute(builder: (context) => AddPollScreen(
                groupId: widget.groupId,
                groupName: widget.groupName,
              )));
            },
          ),
        ],
      ),
    );
  }
}

