import 'package:lockify/utils/colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_contacts/flutter_contacts.dart';
import 'package:lockify/components/widgets/lockify_scaffold.dart';
import 'package:lockify/screens/products/channels/channel_chat_screen.dart';
import 'package:lockify/screens/products/chats/chat_detail_screen.dart';
import 'package:lockify/screens/products/create_screen.dart';
import 'package:lockify/screens/products/channels/channel_screen.dart';
import 'package:lockify/screens/products/groups/group_chat_screen.dart';
import 'package:lockify/screens/products/groups/group_screen.dart';
import 'package:lockify/services/chats/chat_service.dart';
import 'package:lockify/services/contact_service.dart';

import 'package:lockify/components/widgets/chat_list_item.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> with SingleTickerProviderStateMixin {
  final ChatService _chatService = ChatService();
  final ContactService _contactService = ContactService();

  late Future<String> _myPhoneFuture;
  late Future<List<Contact>> _contactsFuture;

  @override
  void initState() {
    super.initState();
    _myPhoneFuture = _chatService.getSenderPhone();
    _contactsFuture = _contactService.getCachedContacts(context);
  }

  @override
  Widget build(BuildContext context) {
    return LockifyScaffold(
      showAppBar: false,
      floatingActionButton: Container(
        margin: const EdgeInsets.only(bottom: 95, right: 4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            RawMaterialButton(
              onPressed: () {
                Navigator.push(context, MaterialPageRoute(builder: (context) => const GroupScreen()));
              },
              fillColor: AppColors.primaryPurple,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              constraints: const BoxConstraints(minWidth: 50, minHeight: 50),
              elevation: 6,
              child: const Icon(Icons.group, color: AppColors.white, size: 24),
            ),
            const SizedBox(height: 12),
            RawMaterialButton(
              onPressed: () {
                Navigator.push(context, MaterialPageRoute(builder: (context) => const ChannelScreen()));
              },
              fillColor: AppColors.primaryPurple,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              constraints: const BoxConstraints(minWidth: 50, minHeight: 50),
              elevation: 6,
              child: const Icon(Icons.campaign, color: AppColors.white, size: 24),
            ),
            const SizedBox(height: 12),
            RawMaterialButton(
              onPressed: () {
                Navigator.push(context, MaterialPageRoute(builder: (context) => const CreateScreen()));
              },
              fillColor: AppColors.primaryPurple,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              constraints: const BoxConstraints(minWidth: 95, minHeight: 50),
              elevation: 6,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: const [
                  Icon(Icons.add, color: AppColors.white, size: 24),
                  SizedBox(width: 6),
                  Text("New", style: TextStyle(color: AppColors.white, fontSize: 20, fontWeight: FontWeight.w500)),
                ],
              ),
            )
          ],
        ),
      ),
      body: FutureBuilder<String>(
        future: _myPhoneFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final myPhone = snapshot.data ?? "";
          return _buildChatList(myPhone);
        },
      ),
    );
  }

  // Function to load chat data
  Widget _buildChatList(String myPhone) {
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: _chatService.getPrivateChats(myPhone),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return const Center(child: Text("Error loading chats"));
        }

        final chatRooms = snapshot.data ?? [];
        if (chatRooms.isEmpty) {
          return const Center(child: Text("No private chats available"));
        }

        return FutureBuilder<List<Contact>>(
          future: _contactsFuture,
          builder: (context, contactSnapshot) {
            final localContacts = contactSnapshot.data ?? [];

            return ListView.builder(
              itemCount: chatRooms.length,
              itemBuilder: (context, index) {
                final chat = chatRooms[index];
                
                return ChatListItem(
                  chatData: chat,
                  myPhone: myPhone,
                  localContacts: localContacts,
                  onTap: () {
                    final type = chat['type'] ?? 'private';

                    if (type == 'private') {
                      final receiver = _chatService.resolvePrivateChatReceiver(
                        chatData: chat,
                        myPhone: myPhone,
                        localContacts: localContacts,
                      );
                      
                      Navigator.push(context, MaterialPageRoute(builder: (context) => ChatDetailPage(
                        recieverPhone: receiver['receiverPhone']!, 
                        recieverName: receiver['displayName']!
                      )));
                    } else if (type == 'group') {
                      Navigator.push(context, MaterialPageRoute(builder: (context) => GroupChatScreen(groupId: chat['groupId'] ?? "", groupName: chat['name'] ?? "Group")));
                    } else if (type == 'channel') {
                      Navigator.push(context, MaterialPageRoute(builder: (context) => ChannelDetailPage(
                        channelId: chat['channelId'] ?? "",
                        channelName: chat['name'] ?? "Channel",
                        channelDesc: chat['description'] ?? "",
                        channelImage: chat['imageUrl'] ?? "",
                        isPaid: chat['isPaid'] ?? false,
                        participants: chat['participants'] ?? [],
                      )));
                    }
                  },
                );
              },
            );
          }
        );
      },
    );
  }
}

