import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:lockify/models/messages.dart';
import 'package:lockify/services/auth/auth_service.dart';
import 'package:lockify/services/messaging_service.dart';
import 'package:async/async.dart';

class ChannelService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final AuthService _authService = AuthService();
  final MessagingService _messagingService = MessagingService();

  static final ChannelService _instance = ChannelService._internal();
  factory ChannelService() => _instance;
  ChannelService._internal();

  // Optimized Cache: Stores roomId -> Member List
  final Map<String, List<Map<String, dynamic>>> _memberCache = {};

  List<Map<String, dynamic>>? getCachedMembers(String channelId) => _memberCache[channelId];
  void setCachedMembers(String channelId, List<Map<String, dynamic>> members) => _memberCache[channelId] = members;

  String normalizePhone(String phone) => _authService.normalizePhone(phone);

  // Get a channel by ID
  Future<Map<String, dynamic>?> getChannelById(String channelId) async {
    final doc = await _firestore.collection('channels').doc(channelId).get();
    if (doc.exists) {
      final data = doc.data();
      if (data != null) {
        data['channelId'] = doc.id;
        return data;
      }
    }
    return null;
  }

  // get channel link
  Future<String?> getChannelLink(String channelId) async {
    final doc = await _firestore.collection('channels').doc(channelId).get();
    if (doc.exists) {
      final data = doc.data();
      return data?['url'] as String?;
    }
    return null;
  }

  /// Returns true if the current user is the creator of the channel
  Future<bool> isCreator(String channelId) async {
    final currentUser = _authService.getCurrentUser();
    if (currentUser == null) return false;

    final doc = await _firestore.collection('channels').doc(channelId).get();
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

  // Create a new channel
  Future<String> createChannel({
    required String name,
    required String description,
    required bool isPaid,
    String? imageUrl, 
    required String channelType, 
    required String subscriberVisibility, 
    required bool restrictContentSaving, 
    required paymentPeriod, 
    required subscriptionPrice,
    required String url,
  }) async {
    final currentUser = _authService.getCurrentUser();
    if (currentUser == null) throw Exception("User not authenticated");
    final myPhone = await getCurrentUserPhone();
    final myName = await getCurrentUserName();

    final docRef = _firestore.collection('channels').doc();
    await docRef.set({
      'type': 'channel',
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
      'channelType': channelType,
      'subscriberVisibility': subscriberVisibility,
      'restrictContentSaving': restrictContentSaving,
      'subscriptionPrice': subscriptionPrice,
      'paymentPeriod': paymentPeriod,
      'url': url,
    }, SetOptions(merge: true));

    await _messagingService.updateMember(
      collectionPath: 'channels',
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

  // Get channels (Optimized Reverse Index Discovery)
  Stream<List<Map<String, dynamic>>> getChannels() {
    final currentUser = _authService.getCurrentUser();
    if (currentUser == null) return Stream.value([]);

    _healMissingMembershipIndex(currentUser.uid);

    return _firestore
        .collection('users')
        .doc(currentUser.uid)
        .collection('memberships')
        .where('type', isEqualTo: 'channel')
        .snapshots()
        .asyncExpand((indexSnap) {
          if (indexSnap.docs.isEmpty) return Stream.value([]);

          final channelIds = indexSnap.docs.map((doc) => doc.id).toList();
          
          List<Stream<List<Map<String, dynamic>>>> channelStreams = [];
          for (var i = 0; i < channelIds.length; i += 30) {
            final chunk = channelIds.sublist(i, i + 30 > channelIds.length ? channelIds.length : i + 30);
            channelStreams.add(
              _firestore
                  .collection('channels')
                  .where(FieldPath.documentId, whereIn: chunk)
                  .snapshots()
                  .map((snap) => snap.docs.map((doc) => {...doc.data(), 'channelId': doc.id}).toList())
            );
          }

          return StreamGroup.merge(channelStreams).map((listOfLists) {
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

    final uidSnap = await _firestore.collection('channels').where('participantUids', arrayContains: uid).get();
    for (var doc in uidSnap.docs) {
      _ensureIndexed(doc.id, uid);
    }

    if (normalizedPhone.isNotEmpty) {
      final phoneSnap = await _firestore.collection('channels').where('participantPhones', arrayContains: normalizedPhone).get();
      for (var doc in phoneSnap.docs) {
        _ensureIndexed(doc.id, uid);
      }
    }
  }

  void _ensureIndexed(String channelId, String uid) async {
    final indexRef = _firestore.collection('users').doc(uid).collection('memberships').doc(channelId);
    final doc = await indexRef.get();
    if (!doc.exists) {
      final channelDoc = await _firestore.collection('channels').doc(channelId).get();
      final data = channelDoc.data() ?? {};
      String role = 'subscriber';
      if (data['adminUids']?.contains(uid) ?? false) role = 'admin';
      if (data['createdBy'] == uid) role = 'owner';

      final userDoc = await _firestore.collection('users').doc(uid).get();
      final userData = userDoc.data();

      await _messagingService.updateMember(
        collectionPath: 'channels',
        docId: channelId,
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

  // Add participants to a channel
  Future<void> addParticipants(String channelId, List<String> phones) async {
    for (String phone in phones) {
      await _messagingService.updateMember(
        collectionPath: 'channels',
        docId: channelId,
        uid: phone, 
        memberData: {
          'phone': phone,
          'role': 'subscriber',
          'addedAt': FieldValue.serverTimestamp(),
          'status': 'pending',
        },
      );
    }
  }

  // Add admins to a channel
  Future<void> addAdmins(String channelId, String adminId) async {
    final userDoc = await _firestore.collection('users').doc(adminId).get();
    final userData = userDoc.data();

    await _messagingService.updateMember(
      collectionPath: 'channels',
      docId: channelId,
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
  Future<void> promoteToAdmin(String channelId, String uid) async {
    await _messagingService.updateMember(
      collectionPath: 'channels',
      docId: channelId,
      uid: uid,
      memberData: {'role': 'admin'},
    );
  }

  // Demote from Admin
  Future<void> demoteFromAdmin(String channelId, String uid) async {
    await _messagingService.updateMember(
      collectionPath: 'channels',
      docId: channelId,
      uid: uid,
      memberData: {'role': 'subscriber'},
    );
  }

  // Remove Member
  Future<void> removeMember(String channelId, String uid) async {
    await _messagingService.removeMember(
      collectionPath: 'channels',
      docId: channelId,
      uid: uid,
    );
  }

  // Leave a channel
  Future<void> leaveChannel(String channelId) async {
    final currentUser = _authService.getCurrentUser();
    if (currentUser == null) throw Exception("User not authenticated");
    
    final myPhone = await getCurrentUserPhone();

    final channelRef = _firestore.collection('channels').doc(channelId);
    await channelRef.update({
      'leftUids': FieldValue.arrayUnion([currentUser.uid]),
      'lastMessage': "left",
      'messageType': "system",
      'lastSenderPhone': myPhone,
      'lastMessageTimestamp': FieldValue.serverTimestamp(),
    });

    await removeMember(channelId, currentUser.uid);
  }

  // Delete a channel
  Future<void> deleteChannel(String channelId) async {
    final isCreatorUser = await isCreator(channelId);
    if (!isCreatorUser) throw Exception("Only the creator can delete the channel");
    
    await _firestore.collection('channels').doc(channelId).delete();
  }

  // Send a message in a channel
  Future<void> sendChannelMessage({
    required String channelId,
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
      collectionPath: 'channels',
      docId: channelId,
      message: messageObj,
      additionalMetadata: {'type': 'channel'},
      senderPhone: senderPhone,
    );
  }

  // Get messages stream for a channel
  Stream<QuerySnapshot> getChannelMessages(String channelId) {
    return _messagingService.getMessageStream('channels', channelId);
  }
}
