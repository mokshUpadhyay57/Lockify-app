import 'package:lockify/utils/colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_contacts/flutter_contacts.dart';
import 'package:lockify/components/widgets/lockify_scaffold.dart';
import 'package:lockify/components/widgets/chat_list_item.dart';
import 'package:lockify/components/widgets/empty_state.dart';
import 'package:lockify/screens/products/channels/channel_chat_screen.dart';
import 'package:lockify/screens/products/channels/create_channel_screen.dart';
import 'package:lockify/services/chats/chat_service.dart';
import 'package:lockify/services/channel/channel_service.dart';
import 'package:lockify/services/contact_service.dart';

class ChannelScreen extends StatefulWidget {
  const ChannelScreen({super.key});

  @override
  State<ChannelScreen> createState() => _ChannelScreenState();
}

class _ChannelScreenState extends State<ChannelScreen> {
  final ChatService _chatService = ChatService();
  final ChannelService _channelService = ChannelService();
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
      title: 'Channels',
      backgroundColor: AppColors.white,
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const CreateChannelScreen()),
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
                stream: _channelService.getChannels(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (snapshot.hasError) {
                    return const Center(child: Text("Error loading channels"));
                  }

                  final channels = snapshot.data ?? [];
                  
                  if (channels.isEmpty) {
                    return const Center(child: EmptyState());
                  }

                  return ListView.builder(
                    itemCount: channels.length,
                    itemBuilder: (context, index) {
                      final chat = channels[index];
                      final name = chat['name'] ?? 'Unnamed Channel';


                      // Check if I have left this channel
                      final leftUids = chat['leftUids'] as List? ?? [];
                      final myUid = _chatService.getCurrentUser()?.uid;
                      final hasLeft = leftUids.contains(myUid);

                      return ChatListItem(
                        chatData: chat,
                        myPhone: myPhone,
                        localContacts: localContacts,
                        subtitle: hasLeft ? "You left" : null,
                        type: 'channel',
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => ChannelDetailPage(
                                channelId: chat['channelId'] ?? "",
                                channelName: name,
                                channelDesc: chat['description'] ?? "",
                                channelImage: chat['imageUrl'] ?? "",
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

