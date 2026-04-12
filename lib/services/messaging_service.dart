import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:lockify/models/messages.dart';

class MessagingService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  static final MessagingService _instance = MessagingService._internal();
  factory MessagingService() => _instance;
  MessagingService._internal();

  /// Generic function to send a message to any conversation type.
  /// Handles both the message subcollection and updating the parent doc's metadata.
  Future<void> sendMessage({
    required String collectionPath, // 'chat_rooms', 'groups', or 'channels'
    required String docId,
    required Messages message,
    Map<String, dynamic>? additionalMetadata,
    String? senderPhone, // Added senderPhone to update the message doc directly
  }) async {
    final roomRef = _firestore.collection(collectionPath).doc(docId);
    final msgRef = roomRef.collection('messages').doc();

    WriteBatch batch = _firestore.batch();

    // 1. Prepare room metadata update (Single Logic for all types)
    Map<String, dynamic> roomUpdate = {
      'lastMessage': message.message,
      'lastMessageTimestamp': message.timestamp,
      'messageType': message.messageType,
      'lastSenderPhone': senderPhone, // Added for local-first identity in lists
      'pollId': message.pollId, // Keep room metadata in sync with polls
    };

    if (additionalMetadata != null) {
      roomUpdate.addAll(additionalMetadata);
    }

    // 2. Set/Update the room document (merge: true ensures we don't overwrite unrelated fields)
    batch.set(roomRef, roomUpdate, SetOptions(merge: true));

    // 3. Add the message to the subcollection
    final msgData = message.toMap();
    if (senderPhone != null) msgData['senderPhone'] = senderPhone;
    batch.set(msgRef, msgData);

    await batch.commit();
  }

  /// Generic stream for messages in any conversation.
  Stream<QuerySnapshot> getMessageStream(String collectionPath, String docId) {
    return _firestore
        .collection(collectionPath)
        .doc(docId)
        .collection('messages')
        .orderBy('timestamp', descending: true)
        .snapshots();
  }

  /// Scalable Membership Logic (Subcollection Pattern)
  /// This handles 10k+ users by storing them in a subcollection instead of an array.
  /// Optimization: Also writes to a Reverse Index (users/{uid}/memberships/{roomId})
  Future<void> updateMember({
    required String collectionPath,
    required String docId,
    required String uid,
    required Map<String, dynamic> memberData,
  }) async {
    final batch = _firestore.batch();

    // 1. Room's Member List
    final roomMemberRef = _firestore
        .collection(collectionPath)
        .doc(docId)
        .collection('members')
        .doc(uid);
    batch.set(roomMemberRef, memberData, SetOptions(merge: true));

    // 2. User's Membership Index (Reverse Index)
    // Avoid indexing if it's just a phone number (pending user)
    if (!uid.startsWith('+') && uid.length > 5) {
      final userMembershipRef = _firestore
          .collection('users')
          .doc(uid)
          .collection('memberships')
          .doc(docId);
      
      batch.set(userMembershipRef, {
        'roomId': docId,
        'type': collectionPath == 'groups' ? 'group' : 'channel',
        'joinedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    }

    await batch.commit();
  }

  /// Remove a member and clean up their index
  Future<void> removeMember({
    required String collectionPath,
    required String docId,
    required String uid,
  }) async {
    final batch = _firestore.batch();

    // 1. Delete from room
    final roomMemberRef = _firestore
        .collection(collectionPath)
        .doc(docId)
        .collection('members')
        .doc(uid);
    batch.delete(roomMemberRef);

    // 2. Delete from user index
    if (!uid.startsWith('+')) {
      final userMembershipRef = _firestore
          .collection('users')
          .doc(uid)
          .collection('memberships')
          .doc(docId);
      batch.delete(userMembershipRef);
    }

    await batch.commit();
  }
}
