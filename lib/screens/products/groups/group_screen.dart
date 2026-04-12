import 'package:lockify/utils/colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_contacts/flutter_contacts.dart';
import 'package:lockify/components/widgets/lockify_scaffold.dart';
import 'package:lockify/components/widgets/chat_list_item.dart';
import 'package:lockify/components/widgets/empty_state.dart';
import 'package:lockify/screens/products/groups/create_group_screen.dart';
import 'package:lockify/screens/products/groups/group_chat_screen.dart';
import 'package:lockify/services/chats/chat_service.dart';
import 'package:lockify/services/group/group_service.dart';
import 'package:lockify/services/contact_service.dart';

class GroupScreen extends StatefulWidget {
  const GroupScreen({super.key});

  @override
  State<GroupScreen> createState() => _GroupScreenState();
}

class _GroupScreenState extends State<GroupScreen> {
  final ChatService _chatService = ChatService();
  final GroupService _groupService = GroupService();
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
      title: 'Groups',
      backgroundColor: AppColors.white,
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const CreateGroupScreen()),
          );
        },
        backgroundColor: AppColors.primaryPurple,
        child: const Icon(Icons.add, color: AppColors.white),
      ),
      body: FutureBuilder<String>(
        future: _myPhoneFuture,
        builder: (context, phoneSnap) {
          if (phoneSnap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final myPhone = phoneSnap.data ?? "";
          return FutureBuilder<List<Contact>>(
            future: _contactsFuture,
            builder: (context, contactSnapshot) {
              final localContacts = contactSnapshot.data ?? [];

              return StreamBuilder<List<Map<String, dynamic>>>(
                stream: _groupService.getGroups(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (snapshot.hasError) {
                    return const Center(child: Text("Error loading groups"));
                  }

                  final groups = snapshot.data ?? [];
                  
                  if (groups.isEmpty) {
                    return const Center(child: EmptyState());
                  }

                  return ListView.builder(
                    itemCount: groups.length,
                    itemBuilder: (context, index) {
                      final chat = groups[index];
                      final groupName = chat['name'] ?? 'Unnamed Group';


                      // Check if I have left this group
                      final leftUids = chat['leftUids'] as List? ?? [];
                      final myUid = _chatService.getCurrentUser()?.uid;
                      final hasLeft = leftUids.contains(myUid);

                      return ChatListItem(
                        chatData: chat,
                        myPhone: myPhone,
                        localContacts: localContacts,
                        subtitle: hasLeft ? "You left" : null,
                        type: 'group',
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => GroupChatScreen(
                                groupId: chat['groupId'] ?? "",
                                groupName: groupName,
                                groupDesc: chat['description'] ?? "",
                                groupImage: chat['imageUrl'] ?? "",
                                isPaid: chat['isPaid'] == true || chat['isPaid'] == 'true',
                                participants: chat['participantUids'] ?? [],
                              ),
                            ),
                          );
                        },
                      );
                    },
                  );
                },
              );
            }
          );
        },
      ),
    );
  }
}

