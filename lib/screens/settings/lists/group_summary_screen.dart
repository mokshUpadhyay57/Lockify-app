import 'package:lockify/utils/colors.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:lockify/screens/products/groups/group_chat_screen.dart';
import 'package:lockify/services/group/group_service.dart';

class GroupSummaryScreen extends StatelessWidget {
  final bool createdOnly;

  const GroupSummaryScreen({super.key, this.createdOnly = true});

  Stream<List<Map<String, dynamic>>> _groupsStream() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return Stream.value([]);

    return GroupService().getGroups().map(
      (groups) {
        return groups.where((group) {
          final isCreator = group['createdBy'] == user.uid;
          return createdOnly ? isCreator : !isCreator;
        }).toList();
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final title = createdOnly ? 'Created Groups' : 'Joined Groups';

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
        stream: _groupsStream(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          final groups = snapshot.data ?? [];
          if (groups.isEmpty) {
            return Center(
              child: Text(
                createdOnly ? 'No created groups found.' : 'No joined groups found.',
                style: const TextStyle(fontSize: 16, color: AppColors.grey),
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: groups.length,
            itemBuilder: (context, index) {
              final group = groups[index];
              final groupName = group['name']?.toString() ?? 'Group';
              final groupId = group['groupId']?.toString() ?? '';

              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                elevation: 2,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: AppColors.purple50,
                    child: Text(
                      groupName.isNotEmpty ? groupName[0].toUpperCase() : '?',
                      style: const TextStyle(color: AppColors.primaryPurple),
                    ),
                  ),
                  title: Text(
                    groupName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  subtitle: Text(
                    group['description']?.toString().isNotEmpty == true
                        ? group['description'].toString()
                        : (group['isPaid'] == true ? 'Paid group' : 'Free group'),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                  onTap: groupId.isEmpty
                      ? null
                      : () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => GroupChatScreen(
                                groupId: groupId,
                                groupName: groupName,
                                groupDesc: group['description']?.toString() ?? '',
                                groupImage: group['imageUrl']?.toString() ?? '',
                                isPaid: group['isPaid'] == true || group['isPaid'] == 'true',
                                participants: group['participantUids'] ?? [],
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
