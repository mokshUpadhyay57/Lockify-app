import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:lockify/models/messages.dart';
import 'package:lockify/services/auth/auth_service.dart';
import 'package:lockify/services/messaging_service.dart';
import 'package:async/async.dart';

class GroupService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final AuthService _authService = AuthService();
  final MessagingService _messagingService = MessagingService();

  static final GroupService _instance = GroupService._internal();
  factory GroupService() => _instance;
  GroupService._internal();

  // Optimized Cache: Stores roomId -> Member List
  final Map<String, List<Map<String, dynamic>>> _memberCache = {};

  List<Map<String, dynamic>>? getCachedMembers(String groupId) => _memberCache[groupId];
  void setCachedMembers(String groupId, List<Map<String, dynamic>> members) => _memberCache[groupId] = members;

  String normalizePhone(String phone) => _authService.normalizePhone(phone);

  // Get a group by ID
  Future<Map<String, dynamic>?> getGroupById(String groupId) async {
    final doc = await _firestore.collection('groups').doc(groupId).get();
    if (doc.exists) {
      final data = doc.data();
      if (data != null) {
        data['groupId'] = doc.id;
        return data;
      }
    }
    return null;
  }

  // get group link 
  Future<String?> getGroupLink(String groupId) async {
    final doc = await _firestore.collection('groups').doc(groupId).get();
    if (doc.exists) {
      final data = doc.data();
      return data?['url'] as String?;
    }
    return null;
  }

  /// Returns true if the current user is the creator of the group
  Future<bool> isCreator(String groupId) async {
    final currentUser = _authService.getCurrentUser();
    if (currentUser == null) return false;

    final doc = await _firestore.collection('groups').doc(groupId).get();
    final data = doc.data();
    if (data == null) return false;

    final creatorId = data['createdBy'];
    return creatorId == currentUser.uid;
  }

  // return the current user name
  Future<String> getCurrentUserName() => _authService.getCurrentUserName();

  // Get the current user ID
  String getCurrentUserId() {
    final currentUser = _authService.getCurrentUser();
    if (currentUser == null) throw Exception("User not authenticated");
    return currentUser.uid;
  }

  // Create a new Group
  Future<String> createGroup({
    required String name,
    required String description,
    required bool isPaid,
    String? imageUrl, 
    required String groupType, 
    required String memberVisibility, 
    required bool restrictContentSaving, 
    required String? subscriptionPrice, 
    required String paymentPeriod,
    required String url,
  }) async {
    final currentUser = _authService.getCurrentUser();
    if (currentUser == null) throw Exception("User not authenticated");
    final myPhone = await getCurrentUserPhone();
    final myName = await getCurrentUserName();

    final docRef = _firestore.collection('groups').doc();
    await docRef.set({
      'type': 'group',
      'name': name,
      'description': description,
      'createdAt': FieldValue.serverTimestamp(),
      'createdBy': currentUser.uid,
      'isPaid': isPaid,
      'participantUids': [currentUser.uid],
      'adminUids': [currentUser.uid], 
      'participantPhones': myPhone.isNotEmpty ? [myPhone] : [],
      'lastSenderPhone': myPhone,
      'imageUrl': imageUrl ?? '',
      'groupType': groupType,
      'memberVisibility': memberVisibility,
      'restrictContentSaving': restrictContentSaving,
      'subscriptionPrice': subscriptionPrice,
      'paymentPeriod': paymentPeriod,
      'url': url,
    }, SetOptions(merge: true));

    await _messagingService.updateMember(
      collectionPath: 'groups',
      docId: docRef.id,
      uid: currentUser.uid,
      memberData: {
        'uid': currentUser.uid,
        'name': myName,
        'phone': myPhone,
        'role': 'owner',
        'addedAt': FieldValue.serverTimestamp(),
        'status': 'active',
      },
    );

    return docRef.id;
  }

  // Get groups (Optimized Reverse Index Discovery)
  Stream<List<Map<String, dynamic>>> getGroups() {
    final currentUser = _authService.getCurrentUser();
    if (currentUser == null) return Stream.value([]);

    _healMissingMembershipIndex(currentUser.uid);

    return _firestore
        .collection('users')
        .doc(currentUser.uid)
        .collection('memberships')
        .where('type', isEqualTo: 'group')
        .snapshots()
        .asyncExpand((indexSnap) {
          if (indexSnap.docs.isEmpty) return Stream.value([]);

          final groupIds = indexSnap.docs.map((doc) => doc.id).toList();
          
          List<Stream<List<Map<String, dynamic>>>> groupStreams = [];
          for (var i = 0; i < groupIds.length; i += 30) {
            final chunk = groupIds.sublist(i, i + 30 > groupIds.length ? groupIds.length : i + 30);
            groupStreams.add(
              _firestore
                  .collection('groups')
                  .where(FieldPath.documentId, whereIn: chunk)
                  .snapshots()
                  .map((snap) => snap.docs.map((doc) => {...doc.data(), 'groupId': doc.id}).toList())
            );
          }

          return StreamGroup.merge(groupStreams).map((listOfLists) {
            final flatList = listOfLists.toList();
            flatList.sort((a, b) {
              final tA = (a['lastMessageTimestamp'] ?? a['createdAt']) as Timestamp?;
              final tB = (b['lastMessageTimestamp'] ?? b['createdAt']) as Timestamp?;
              if (tA == null) return 1;
              if (tB == null) return -1;
              return tB.compareTo(tA);
            });
            return flatList;
          });
        });
  }

  // Self-healing Indexer
  void _healMissingMembershipIndex(String uid) async {
    final myPhone = await getCurrentUserPhone();
    final normalizedPhone = normalizePhone(myPhone);

    final uidSnap = await _firestore.collection('groups').where('participantUids', arrayContains: uid).get();
    for (var doc in uidSnap.docs) {
      _ensureIndexed(doc.id, uid);
    }

    if (normalizedPhone.isNotEmpty) {
      final phoneSnap = await _firestore.collection('groups').where('participantPhones', arrayContains: normalizedPhone).get();
      for (var doc in phoneSnap.docs) {
        _ensureIndexed(doc.id, uid);
      }
    }
  }

  void _ensureIndexed(String groupId, String uid) async {
    final indexRef = _firestore.collection('users').doc(uid).collection('memberships').doc(groupId);
    final doc = await indexRef.get();
    if (!doc.exists) {
      final groupDoc = await _firestore.collection('groups').doc(groupId).get();
      final data = groupDoc.data() ?? {};
      String role = 'member';
      if (data['adminUids']?.contains(uid) ?? false) role = 'admin';
      if (data['createdBy'] == uid) role = 'owner';

      final userDoc = await _firestore.collection('users').doc(uid).get();
      final userData = userDoc.data();

      await _messagingService.updateMember(
        collectionPath: 'groups',
        docId: groupId,
        uid: uid,
        memberData: {
          'uid': uid,
          'name': userData?['name'] ?? 'User',
          'phone': userData?['phone'] ?? '',
          'role': role,
          'addedAt': FieldValue.serverTimestamp(),
          'status': 'active',
        },
      );
    }
  }

  // Helper to get phone
  Future<String> getCurrentUserPhone() => _authService.getCurrentUserPhone();

  // Add participants to a group
  Future<void> addParticipants(String groupId, List<String> phones) async {
    for (String phone in phones) {
      await _messagingService.updateMember(
        collectionPath: 'groups',
        docId: groupId,
        uid: phone, 
        memberData: {
          'phone': phone,
          'role': 'member',
          'addedAt': FieldValue.serverTimestamp(),
          'status': 'pending',
        },
      );
    }
  }

  // Add admins to a group
  Future<void> addAdmins(String groupId, String adminId) async {
    final userDoc = await _firestore.collection('users').doc(adminId).get();
    final userData = userDoc.data();

    await _messagingService.updateMember(
      collectionPath: 'groups',
      docId: groupId,
      uid: adminId,
      memberData: {
        'uid': adminId,
        'name': userData?['name'] ?? 'User',
        'phone': userData?['phone'] ?? '',
        'role': 'admin',
        'addedAt': FieldValue.serverTimestamp(),
        'status': 'active',
      },
    );
  }

  // Promote to Admin
  Future<void> promoteToAdmin(String groupId, String uid) async {
    await _messagingService.updateMember(
      collectionPath: 'groups',
      docId: groupId,
      uid: uid,
      memberData: {'role': 'admin'},
    );
  }

  // Demote from Admin
  Future<void> demoteFromAdmin(String groupId, String uid) async {
    await _messagingService.updateMember(
      collectionPath: 'groups',
      docId: groupId,
      uid: uid,
      memberData: {'role': 'member'},
    );
  }

  // Remove Member
  Future<void> removeMember(String groupId, String uid) async {
    await _messagingService.removeMember(
      collectionPath: 'groups',
      docId: groupId,
      uid: uid,
    );
  }

  // Leave a group
  Future<void> leaveGroup(String groupId) async {
    final currentUser = _authService.getCurrentUser();
    if (currentUser == null) throw Exception("User not authenticated");
    
    final myPhone = await getCurrentUserPhone();

    final groupRef = _firestore.collection('groups').doc(groupId);
    await groupRef.update({
      'leftUids': FieldValue.arrayUnion([currentUser.uid]),
      'lastMessage': "left",
      'messageType': "system",
      'lastSenderPhone': myPhone, 
      'lastMessageTimestamp': FieldValue.serverTimestamp(),
    });

    await removeMember(groupId, currentUser.uid);
  }

  // Delete a group
  Future<void> deleteGroup(String groupId) async {
    final isCreatorUser = await isCreator(groupId);
    if (!isCreatorUser) throw Exception("Only the creator can delete the group");
    
    await _firestore.collection('groups').doc(groupId).delete();
  }

  // Send a message in a group
  Future<void> sendGroupMessage({
    required String groupId,
    required String message,
  }) async {
    final currentUser = _authService.getCurrentUser();
    if (currentUser == null) throw Exception("User not authenticated");
    final senderPhone = await getCurrentUserPhone();

    Messages messageObj = Messages(
      message: message,
      timestamp: FieldValue.serverTimestamp(),
      senderUid: currentUser.uid,
    );

    await _messagingService.sendMessage(
      collectionPath: 'groups',
      docId: groupId,
      message: messageObj,
      additionalMetadata: {'type': 'group'},
      senderPhone: senderPhone,
    );
  }

  // Get messages stream for a group
  Stream<QuerySnapshot> getGroupMessages(String groupId) {
    return _messagingService.getMessageStream('groups', groupId);
  }
}
