import 'package:lockify/utils/snackbar.dart';
import 'package:lockify/utils/colors.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_contacts/flutter_contacts.dart';
import 'package:lockify/components/widgets/member_tile.dart';
import 'package:lockify/screens/products/participant_selection_screen.dart';
import 'package:lockify/services/admin/admin_service.dart';
import 'package:lockify/services/auth/auth_service.dart';
import 'package:lockify/services/group/group_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class GroupInfoScreen extends StatefulWidget {
  final String groupId;
  final String groupName;
  final bool isPaid;
  final Map<String, dynamic>? initialData;

  const GroupInfoScreen({
    super.key,
    required this.groupId,
    required this.groupName,
    required this.isPaid,
    this.initialData,
  });

  @override
  State<GroupInfoScreen> createState() => _GroupInfoScreenState();
}

class _GroupInfoScreenState extends State<GroupInfoScreen> {
  final AuthService _authService = AuthService();
  final GroupService _groupService = GroupService();
  bool notificationsEnabled = true;
  String groupLink = "Loading...";
  bool linkLoaded = false;
  
  Map<String, dynamic>? groupData;
  List<Map<String, dynamic>> membersProfiles = [];
  List<Contact> localContacts = [];
  bool isLoadingMembers = true;
  int memberCount = 0;
  int adminCount = 0;

  @override
  void initState() {
    super.initState();
    groupData = widget.initialData;
    
    // Load cached members immediately for 0ms UI load
    final cached = _groupService.getCachedMembers(widget.groupId);
    if (cached != null) {
      membersProfiles = cached;
      memberCount = cached.length;
      adminCount = cached.where((m) => m['role'] == 'admin' || m['role'] == 'owner').length;
      isLoadingMembers = false;
    }

    loadGroupDetails();
  }

  Future<void> loadGroupDetails() async {
    loadGroupLink();
    
    // Use the optimized AuthService cache for contacts
    localContacts = await _authService.getCachedContacts(context);

    if (groupData == null) {
      await fetchGroupData();
    }
    fetchMembersFromSubcollection();
  }

  Future<void> fetchGroupData() async {
    final data = await _groupService.getGroupById(widget.groupId);
    if (mounted) {
      setState(() {
        groupData = data;
      });
    }
  }

  Future<void> fetchMembersFromSubcollection() async {
    // If no cache, show loader. If cache exists, update silently.
    if (membersProfiles.isEmpty) {
      setState(() => isLoadingMembers = true);
    }

    final membersQuery = await FirebaseFirestore.instance
        .collection('groups')
        .doc(widget.groupId)
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
        'role': data['role'] ?? 'member',
        'imageUrl': data['imageUrl'] ?? '',
      };

      if (data['role'] == 'admin' || data['role'] == 'owner') admins++;
      fetchedMembers.add(member);
    }

    // Update Cache
    _groupService.setCachedMembers(widget.groupId, fetchedMembers);

    if (mounted) {
      setState(() {
        membersProfiles = fetchedMembers;
        memberCount = fetchedMembers.length;
        adminCount = admins;
        isLoadingMembers = false;
      });
    }
  }

  Future<void> loadGroupLink() async {
    final prefs = await SharedPreferences.getInstance();
    final cacheKey = 'group_link_${widget.groupId}';
    final cachedLink = prefs.getString(cacheKey);

    if (cachedLink != null && cachedLink.isNotEmpty) {
      setState(() {
        groupLink = cachedLink;
        linkLoaded = true;
      });
    } else {
      final link = await getGroupLink();
      setState(() {
        groupLink = link;
        linkLoaded = link != "Loading..." && link != "No link available";
      });
      if (link != "No link available") {
        prefs.setString(cacheKey, link);
      }
    }
  }

  Future<String> getGroupType() async {
    if (groupData != null) return groupData?['groupType']?.toString() ?? 'Unknown';
    final data = await _groupService.getGroupById(widget.groupId);
    return data?['groupType']?.toString() ?? 'Unknown';
  }

  Future<String> getGroupLink() async {
    final link = await _groupService.getGroupLink(widget.groupId);
    return link ?? "No link available";
  }

  @override
  Widget build(BuildContext context) {
    final String? currentUserId = FirebaseAuth.instance.currentUser?.uid;
    final String creatorId = groupData?['createdBy'] ?? "";

    String userRole = "Not a member";
    bool isOwner = currentUserId == creatorId;
    bool isAdmin = isOwner;

    if (currentUserId != null && membersProfiles.isNotEmpty) {
      try {
        final currentUserData = membersProfiles.firstWhere((m) => m['uid'] == currentUserId);
        final role = currentUserData['role'] ?? 'member';
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
          widget.groupName,
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
              tooltip: "Edit Group",
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
                  widget.groupName.isNotEmpty ? widget.groupName[0].toUpperCase() : "?",
                  style: const TextStyle(fontSize: 25, color: AppColors.white, fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(width: 22),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.groupName,
                    style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, letterSpacing: 0.2),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    "$memberCount Members",
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
                          groupLink,
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
                                await Clipboard.setData(ClipboardData(text: groupLink));
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
                            ? () {
                                // Implement share logic
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
                  future: getGroupType(),
                  builder: (context, snapshot) {
                    String groupType = snapshot.data ?? "Loading...";
                    return buildInfoRow(
                      "Group type",
                      Icons.public,
                      trailing: Text(groupType, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
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
                  "Members",
                  Icons.group,
                  trailing: isLoadingMembers
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                      : Text(
                          "$memberCount",
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                        ),
                  onTap: () => _showMembersBottomSheet(context, creatorId, currentUserId, isAdmin),
                ),
                buildInfoRow(
                  "Administrators",
                  Icons.admin_panel_settings,
                  trailing: isLoadingMembers
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

  void _showMembersBottomSheet(BuildContext context, String creatorId, String? currentUserId, bool isAdmin) {
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
                    const Text("Group Members", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                    if (isAdmin)
                      IconButton(
                        icon: const Icon(Icons.person_add, color: AppColors.primaryPurple),
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => ParticipantSelectionScreen(
                                title: 'Add Members',
                                onConfirm: (phones) async {
                                  final admins = await AdminService().getAdminByUid();
                                  if (admins != null) {
                                    await _groupService.addAdmins(widget.groupId, admins);
                                  }
                                  await _groupService.addParticipants(widget.groupId, phones);
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
                child: isLoadingMembers
                    ? const Center(child: CircularProgressIndicator())
                    : ListView.builder(
                        itemCount: membersProfiles.length,
                        itemBuilder: (context, index) {
                          final user = membersProfiles[index];
                          final uid = user['uid'];
                          
                          String role = 'Member';

                          if (user['role'] != null) {
                            role = user['role'][0].toUpperCase() + user['role'].substring(1);
                          }

                          return MemberTile(
                            userData: user,
                            role: role,
                            canManage: isAdmin && uid != currentUserId && role != 'Owner',
                            onPromote: () async {
                              await _groupService.promoteToAdmin(widget.groupId, uid);
                              await fetchMembersFromSubcollection();
                              setModalState(() {});
                            },
                            onDemote: () async {
                              await _groupService.demoteFromAdmin(widget.groupId, uid);
                              await fetchMembersFromSubcollection();
                              setModalState(() {});
                            },
                            onRemove: () async {
                              await _groupService.removeMember(widget.groupId, uid);
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

