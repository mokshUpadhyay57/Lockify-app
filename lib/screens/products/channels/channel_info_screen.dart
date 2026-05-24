import 'package:lockify/utils/colors.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_contacts/flutter_contacts.dart';
import 'package:lockify/components/widgets/member_tile.dart';
import 'package:lockify/screens/products/participant_selection_screen.dart';
import 'package:lockify/services/auth/auth_service.dart';
import 'package:lockify/services/channel/channel_service.dart';
import 'package:share_plus/share_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:lockify/utils/snackbar.dart';

class ChannelInfoScreen extends StatefulWidget {
  final String channelId;
  final String channelName;
  final bool isPaid;
  final Map<String, dynamic>? initialData;

  const ChannelInfoScreen({
    super.key,
    required this.channelId,
    required this.channelName,
    required this.isPaid,
    this.initialData,
  });

  @override
  State<ChannelInfoScreen> createState() => _ChannelInfoScreenState();
}

class _ChannelInfoScreenState extends State<ChannelInfoScreen> {
  final AuthService _authService = AuthService();
  final ChannelService _channelService = ChannelService();
  bool notificationsEnabled = true;
  String channelLink = "Loading...";
  bool linkLoaded = false;
  
  Map<String, dynamic>? channelData;
  List<Map<String, dynamic>> subscribersProfiles = [];
  List<Contact> localContacts = [];
  bool isLoadingSubscribers = true;
  int subscriberCount = 0;
  int adminCount = 0;

  @override
  void initState() {
    super.initState();
    channelData = widget.initialData;

    // Load cached members immediately
    final cached = _channelService.getCachedMembers(widget.channelId);
    if (cached != null) {
      subscribersProfiles = cached;
      subscriberCount = cached.length;
      adminCount = cached.where((m) => m['role'] == 'admin' || m['role'] == 'owner').length;
      isLoadingSubscribers = false;
    }

    loadChannelDetails();
  }

  Future<void> loadChannelDetails() async {
    loadChannelLink();
    localContacts = await _authService.getCachedContacts(context);

    if (channelData == null) {
      await fetchChannelData();
    }
    fetchMembersFromSubcollection();
  }

  Future<void> fetchChannelData() async {
    final data = await _channelService.getChannelById(widget.channelId);
    if (mounted) {
      setState(() {
        channelData = data;
      });
    }
  }

  Future<void> fetchMembersFromSubcollection() async {
    if (subscribersProfiles.isEmpty) {
      setState(() => isLoadingSubscribers = true);
    }

    final membersQuery = await FirebaseFirestore.instance
        .collection('channels')
        .doc(widget.channelId)
        .collection('members')
        .get();

    final List<Map<String, dynamic>> fetchedMembers = [];
    int admins = 0;

    for (var doc in membersQuery.docs) {
      final data = doc.data();
      final phone = data['phone'] as String? ?? "";
      final nameFromDb = data['name'] as String? ?? "User";
      
      final resolvedName = _authService.resolveName(
        phone: phone, 
        localContacts: localContacts,
        dbNames: {phone: nameFromDb},
      );

      final member = {
        'uid': data['uid'] ?? phone,
        'name': resolvedName,
        'phone': phone,
        'role': data['role'] ?? 'subscriber',
        'imageUrl': data['imageUrl'] ?? '',
      };

      if (data['role'] == 'admin' || data['role'] == 'owner') admins++;
      fetchedMembers.add(member);
    }

    // Update Cache
    _channelService.setCachedMembers(widget.channelId, fetchedMembers);

    if (mounted) {
      setState(() {
        subscribersProfiles = fetchedMembers;
        subscriberCount = fetchedMembers.length;
        adminCount = admins;
        isLoadingSubscribers = false;
      });
    }
  }

  Future<void> loadChannelLink() async {
    final prefs = await SharedPreferences.getInstance();
    final cacheKey = 'channel_link_${widget.channelId}';
    final cachedLink = prefs.getString(cacheKey);

    if (cachedLink != null && cachedLink.isNotEmpty) {
      setState(() {
        channelLink = cachedLink;
        linkLoaded = true;
      });
    } else {
      final link = await getChannelLink();
      setState(() {
        channelLink = link;
        linkLoaded = link != "Loading..." && link != "No link available";
      });
      if (link != "No link available") {
        prefs.setString(cacheKey, link);
      }
    }
  }

  Future<String> getChannelType() async {
    if (channelData != null) return channelData?['channelType']?.toString() ?? 'Unknown';
    final data = await _channelService.getChannelById(widget.channelId);
    return data?['channelType']?.toString() ?? 'Unknown';
  }

  Future<String> getChannelLink() async {
    final link = await _channelService.getChannelLink(widget.channelId);
    return link ?? "No link available";
  }

  @override
  Widget build(BuildContext context) {
    final String? currentUserId = FirebaseAuth.instance.currentUser?.uid;
    final String creatorId = channelData?['createdBy'] ?? "";

    String userRole = "Not a subscriber";
    bool isOwner = currentUserId == creatorId;
    bool isAdmin = isOwner;

    if (currentUserId != null && subscribersProfiles.isNotEmpty) {
      try {
        final currentUserData = subscribersProfiles.firstWhere((m) => m['uid'] == currentUserId);
        final role = currentUserData['role'] ?? 'subscriber';
        if (role == 'owner') isOwner = true;
        if (role == 'admin' || role == 'owner') isAdmin = true;
        userRole = role[0].toUpperCase() + role.substring(1); 
      } catch (e) {
        // Not found
      }
    }

    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.primaryPurple,
        elevation: 2,
        leading: const BackButton(color: AppColors.white),
        leadingWidth: 35,
        title: Text(
          widget.channelName,
          style: const TextStyle(
            color: AppColors.white,
            fontWeight: FontWeight.bold,
            fontSize: 22,
            letterSpacing: 0.5,
          ),
        ),
        actions: [
          if (isAdmin)
            IconButton(
              icon: const Icon(Icons.edit, color: AppColors.white),
              onPressed: () {},
              tooltip: "Edit Channel",
            )
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              CircleAvatar(
                radius: 28,
                backgroundColor: AppColors.purple200,
                child: Text(
                  widget.channelName.isNotEmpty ? widget.channelName[0].toUpperCase() : "?",
                  style: const TextStyle(fontSize: 25, color: AppColors.white, fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(width: 22),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.channelName,
                    style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, letterSpacing: 0.2),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    "$subscriberCount Subscribers",
                    style: TextStyle(color: AppColors.grey600, fontSize: 15),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 24),
          Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
            elevation: 0,
            color: Colors.transparent,
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(18),
                color: AppColors.white,
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primaryPurple.withOpacity(0.10),
                    blurRadius: 18,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 22),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.link, color: AppColors.primaryPurple, size: 20),
                      const SizedBox(width: 10),
                      Flexible(
                        child: Text(
                          channelLink,
                          style: const TextStyle(
                            fontSize: 18,
                            color: AppColors.primaryPurple,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.2,
                          ),
                          textAlign: TextAlign.center,
                          maxLines: 2,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primaryPurple,
                          foregroundColor: AppColors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                        ),
                        icon: const Icon(Icons.copy, size: 20),
                        label: const Text("Copy", style: TextStyle(fontWeight: FontWeight.w600)),
                        onPressed: linkLoaded
                            ? () async {
                                await Clipboard.setData(ClipboardData(text: channelLink));
                                if (mounted) {
                                  AppSnackBar.success(context, 'Link copied to clipboard!');
                                }
                              }
                            : null,
                      ),
                      const SizedBox(width: 16),
                      OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.primaryPurple,
                          side: BorderSide(color: AppColors.purple200, width: 1.5),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                        ),
                        icon: const Icon(Icons.share, size: 20),
                        label: const Text("Share", style: TextStyle(fontWeight: FontWeight.w600)),
                        onPressed: linkLoaded
                            ? () async {
                                await SharePlus.instance.share(
                                  ShareParams(
                                    text: "Join ${widget.channelName} on Lockify: $channelLink",
                                    subject: "${widget.channelName} channel",
                                  ),
                                );
                              }
                            : null,
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          Container(
            decoration: BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.circular(14),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primaryPurple.withOpacity(0.04),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              children: [
                FutureBuilder<String>(
                  future: getChannelType(),
                  builder: (context, snapshot) {
                    String channelType = snapshot.data ?? "Loading...";
                    return buildInfoRow(
                      "Channel type",
                      Icons.public,
                      trailing: Text(channelType, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
                    );
                  },
                ),
                buildInfoRow(
                  "Access",
                  Icons.monetization_on,
                  trailing: Text(widget.isPaid ? "Paid" : "Free", style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
                ),
                buildInfoRow(
                  "Role",
                  Icons.person,
                  trailing: Text(userRole, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
                ),
                buildInfoRow(
                  "Notifications",
                  Icons.notifications,
                  trailing: Switch(
                    value: notificationsEnabled,
                    onChanged: (val) {
                      setState(() {
                        notificationsEnabled = val;
                      });
                    },
                    activeColor: AppColors.primaryPurple,
                  ),
                ),
                buildInfoRow(
                  "Subscribers",
                  Icons.group,
                  trailing: isLoadingSubscribers
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                      : Text(
                          "$subscriberCount",
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                        ),
                  onTap: () => _showSubscribersBottomSheet(context, creatorId, currentUserId, isAdmin),
                ),
                buildInfoRow(
                  "Administrators",
                  Icons.admin_panel_settings,
                  trailing: isLoadingSubscribers
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                      : Text(
                          "${adminCount.clamp(1, 999)}", 
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                        ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  void _showSubscribersBottomSheet(BuildContext context, String creatorId, String? currentUserId, bool isAdmin) {
    final visibility = channelData?['subscriberVisibility'] ?? 'Everyone';
    if (visibility == 'Owner' && !isAdmin) {
      AppSnackBar.info(context, 'Subscriber list is hidden by owner');
      return;
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Container(
          padding: const EdgeInsets.symmetric(vertical: 20),
          height: MediaQuery.of(context).size.height * 0.7,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text("Subscribers", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                    if (isAdmin)
                      IconButton(
                        icon: const Icon(Icons.person_add, color: AppColors.primaryPurple),
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => ParticipantSelectionScreen(
                                title: 'Add Subscribers',
                                onConfirm: (phones) async {
                                  await _channelService.addParticipants(widget.channelId, phones);
                                },
                              ),
                            ),
                          ).then((_) => fetchMembersFromSubcollection());
                        },
                      ),
                  ],
                ),
              ),
              const Divider(),
              Expanded(
                child: isLoadingSubscribers
                    ? const Center(child: CircularProgressIndicator())
                    : ListView.builder(
                        itemCount: subscribersProfiles.length,
                        itemBuilder: (context, index) {
                          final user = subscribersProfiles[index];
                          final uid = user['uid'];
                          
                          String role = 'Subscriber';

                          if (user['role'] != null) {
                            role = user['role'][0].toUpperCase() + user['role'].substring(1);
                          }

                          return MemberTile(
                            userData: user,
                            role: role,
                            canManage: isAdmin && uid != currentUserId && role != 'Owner',
                            onPromote: () async {
                              await _channelService.promoteToAdmin(widget.channelId, uid);
                              await fetchMembersFromSubcollection();
                              setModalState(() {});
                            },
                            onDemote: () async {
                              await _channelService.demoteFromAdmin(widget.channelId, uid);
                              await fetchMembersFromSubcollection();
                              setModalState(() {});
                            },
                            onRemove: () async {
                              await _channelService.removeMember(widget.channelId, uid);
                              await fetchMembersFromSubcollection();
                              setModalState(() {});
                            },
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

Widget buildInfoRow(
  String label,
  IconData? icon, {
  required Widget trailing,
  VoidCallback? onTap,
}) {
  return Padding(
    padding: const EdgeInsets.symmetric(horizontal: 8),
    child: ListTile(
      dense: true,
      onTap: onTap,
      minLeadingWidth: 24,
      leading: Icon(icon, size: 22, color: AppColors.purple400),
      title: Text(label, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
      contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      trailing: trailing,
    ),
  );
}

