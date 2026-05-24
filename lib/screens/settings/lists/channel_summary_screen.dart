import 'package:lockify/utils/colors.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:lockify/screens/products/channels/channel_chat_screen.dart';
import 'package:lockify/services/channel/channel_service.dart';

class ChannelSummaryScreen extends StatelessWidget {
  final bool createdOnly;

  const ChannelSummaryScreen({super.key, this.createdOnly = true});

  Stream<List<Map<String, dynamic>>> _channelsStream() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return Stream.value([]);

    return ChannelService().getChannels().map(
      (channels) {
        return channels.where((channel) {
          final isCreator = channel['createdBy'] == user.uid;
          return createdOnly ? isCreator : !isCreator;
        }).toList();
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final title = createdOnly ? 'Created Channels' : 'Joined Channels';

    return Scaffold(
      appBar: AppBar(
        title: Text(title, style: const TextStyle(fontSize: 18)),
        foregroundColor: AppColors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        backgroundColor: Colors.deepPurple,
        elevation: 0,
      ),
      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: _channelsStream(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          final channels = snapshot.data ?? [];
          if (channels.isEmpty) {
            return Center(
              child: Text(
                createdOnly ? 'No created channels found.' : 'No joined channels found.',
                style: const TextStyle(fontSize: 16, color: AppColors.grey),
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: channels.length,
            itemBuilder: (context, index) {
              final channel = channels[index];
              final channelName = channel['name']?.toString() ?? 'Channel';
              final channelId = channel['channelId']?.toString() ?? '';

              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                elevation: 2,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: AppColors.purple50,
                    child: Text(
                      channelName.isNotEmpty ? channelName[0].toUpperCase() : '?',
                      style: const TextStyle(color: AppColors.primaryPurple),
                    ),
                  ),
                  title: Text(
                    channelName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  subtitle: Text(
                    channel['description']?.toString().isNotEmpty == true
                        ? channel['description'].toString()
                        : (channel['isPaid'] == true ? 'Paid channel' : 'Free channel'),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                  onTap: channelId.isEmpty
                      ? null
                      : () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => ChannelDetailPage(
                                channelId: channelId,
                                channelName: channelName,
                                channelDesc: channel['description']?.toString() ?? '',
                                channelImage: channel['imageUrl']?.toString() ?? '',
                                isPaid: channel['isPaid'] == true || channel['isPaid'] == 'true',
                                participants: channel['participantUids'] ?? [],
                              ),
                            ),
                          );
                        },
                ),
              );
            },
          );
        },
      ),
    );
  }
}
