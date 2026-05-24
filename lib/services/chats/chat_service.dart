import 'dart:async';
import 'dart:io';
import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:flutter_contacts/flutter_contacts.dart';
import 'package:lockify/services/auth/auth_service.dart';
import 'package:lockify/models/messages.dart';
import 'package:lockify/services/messaging_service.dart';
import 'package:lockify/utils/app_logger.dart';
import 'package:lockify/utils/contacts.dart' as contact_util;

class ChatService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final AuthService _authService = AuthService();
  final MessagingService _messagingService = MessagingService();

  static final ChatService _instance = ChatService._internal();
  factory ChatService() => _instance;
  ChatService._internal();

  String normalizePhone(String phone) => _authService.normalizePhone(phone);

  /// Get current Firebase user
  User? getCurrentUser() {
    return _authService.getCurrentUser();
  }

  Future<String> getSenderPhone() => _authService.getCurrentUserPhone();

  Future<String> getSenderNameFromContacts(
    BuildContext context,
    String phone,
  ) async {
    final contacts = await getContacts(context);
    final normalized = normalizePhone(phone);
    for (var contact in contacts) {
      if (contact.phones.isNotEmpty &&
          normalizePhone(contact.phones.first.number) == normalized) {
        return contact.displayName;
      }
    }
    return phone;
  }

  Future<String?> _generateBase64Thumbnail(File file) async {
    try {
      final result = await FlutterImageCompress.compressWithFile(
        file.absolute.path,
        minWidth: 40,
        minHeight: 40,
        quality: 5,
        format: CompressFormat.webp,
      );
      if (result != null) return base64Encode(result);
    } catch (e) {
      AppLogger.error("Thumbnail generation failed", error: e);
    }
    return null;
  }

  /// Get only private chats for the current user
  Stream<List<Map<String, dynamic>>> getPrivateChats(String myPhone) {
    final currentUser = _authService.getCurrentUser();
    if (currentUser == null) return Stream.value([]);

    final normalizedMyPhone = normalizePhone(myPhone);
    final controller = StreamController<List<Map<String, dynamic>>>();

    final Map<String, List<Map<String, dynamic>>> snapshotBuffer = {};

    void updateBuffer(String queryId, List<Map<String, dynamic>> data) {
      snapshotBuffer[queryId] = data;

      final Map<String, Map<String, dynamic>> uniqueChats = {};
      for (var list in snapshotBuffer.values) {
        for (var chat in list) {
          uniqueChats[chat['roomID']] = chat;
        }
      }

      final result = uniqueChats.values.toList();
      result.sort((a, b) {
        final tA = (a['lastMessageTimestamp'] ?? a['createdAt']) as Timestamp?;
        final tB = (b['lastMessageTimestamp'] ?? b['createdAt']) as Timestamp?;
        if (tA == null) return 1;
        if (tB == null) return -1;
        return tB.compareTo(tA);
      });

      if (!controller.isClosed) {
        controller.add(result);
      }
    }

    // 1. Query by UID
    final uidSub = _firestore
        .collection('chat_rooms')
        .where('participantUids', arrayContains: currentUser.uid)
        .snapshots()
        .listen((snap) {
          final data =
              snap.docs
                  .map(
                    (doc) => {
                      'roomID': doc.id,
                      'type': 'private',
                      ...doc.data(),
                    },
                  )
                  .toList();
          updateBuffer('uid', data);
        });

    // 2. Query by Phone (if available)
    StreamSubscription? phoneSub;
    if (normalizedMyPhone.isNotEmpty) {
      phoneSub = _firestore
          .collection('chat_rooms')
          .where('participantPhones', arrayContains: normalizedMyPhone)
          .snapshots()
          .listen((snap) {
            final data =
                snap.docs
                    .map(
                      (doc) => {
                        'roomID': doc.id,
                        'type': 'private',
                        ...doc.data(),
                      },
                    )
                    .toList();
            updateBuffer('phone', data);
          });
    }

    controller.onCancel = () {
      uidSub.cancel();
      phoneSub?.cancel();
      controller.close();
    };

    return controller.stream;
  }

  // Helper to find the other person in a private chat and resolve their identity
  Map<String, String> resolvePrivateChatReceiver({
    required Map<String, dynamic> chatData,
    required String myPhone,
    required List<Contact> localContacts,
  }) {
    final participantPhones = List<String>.from(
      chatData['participantPhones'] ?? [],
    );
    final normalizedMyPhone = normalizePhone(myPhone);

    final receiverPhone = participantPhones.firstWhere(
      (p) => normalizePhone(p) != normalizedMyPhone,
      orElse: () => participantPhones.isNotEmpty ? participantPhones.first : "",
    );

    final displayName = _authService.resolveName(
      phone: receiverPhone,
      localContacts: localContacts,
      dbNames: chatData['participantNames'],
    );

    return {'receiverPhone': receiverPhone, 'displayName': displayName};
  }

  Future<List<Contact>> getContacts(BuildContext context) async {
    return await contact_util.getContacts(context);
  }

  Future<String> resolveReceiverName(
    BuildContext context,
    String phone,
    String? passedName,
  ) async {
    final normalizedTarget = normalizePhone(phone);
    final contacts = await getContacts(context);
    for (final contact in contacts) {
      if (contact.phones.isNotEmpty &&
          normalizePhone(contact.phones.first.number) == normalizedTarget) {
        return contact.displayName;
      }
    }
    if (passedName != null && passedName != "User" && passedName.isNotEmpty)
      return passedName;
    return phone;
  }

  Future<void> sendMessage(
    BuildContext context,
    String receiverPhone,
    String message, {
    String? receiverName,
  }) async {
    try {
      final currentUser = _authService.getCurrentUser();
      if (currentUser == null) throw Exception("User not authenticated");

      final senderPhone = await getSenderPhone();
      final normalizedReceiverPhone = normalizePhone(receiverPhone);
      final finalReceiverName = await resolveReceiverName(
        context,
        receiverPhone,
        receiverName,
      );

      List<String> sortedPhones = [senderPhone, normalizedReceiverPhone];
      sortedPhones.sort();
      String roomID = sortedPhones.join('_');

      Messages messageObj = Messages(
        message: message,
        timestamp: FieldValue.serverTimestamp(),
        senderUid: currentUser.uid,
      );

      // Try to find the receiver's UID in the 'users' collection
      String? receiverUid;
      final userQuery =
          await _firestore
              .collection('users')
              .where('phone', isEqualTo: normalizedReceiverPhone)
              .limit(1)
              .get();
      if (userQuery.docs.isNotEmpty) {
        receiverUid = userQuery.docs.first.id;
      }

      // Use the unified MessagingService
      await _messagingService.sendMessage(
        collectionPath: 'chat_rooms',
        docId: roomID,
        message: messageObj,
        senderPhone: senderPhone,
        additionalMetadata: {
          'type': 'private',
          'participantPhones': FieldValue.arrayUnion([
            senderPhone,
            normalizedReceiverPhone,
          ]),
          'participantUids': FieldValue.arrayUnion(
            receiverUid != null
                ? [currentUser.uid, receiverUid]
                : [currentUser.uid],
          ),
        },
      );
    } catch (error) {
      AppLogger.error("Failed to send message", error: error);
      rethrow;
    }
  }

  Stream<QuerySnapshot> getMessages(String senderPhone, String receiverPhone) {
    final String sPhone = normalizePhone(senderPhone);
    final String rPhone = normalizePhone(receiverPhone);
    List<String> ids = [sPhone, rPhone];
    ids.sort();
    String roomId = ids.join('_');

    return _messagingService.getMessageStream('chat_rooms', roomId);
  }

  Future<void> voteOnPoll(String pollId, String option) async {
    try {
      final currentUser = _authService.getCurrentUser();
      if (currentUser == null) throw Exception("User not authenticated");
      DocumentReference pollRef = _firestore.collection('polls').doc(pollId);

      await _firestore.runTransaction((transaction) async {
        DocumentSnapshot snapshot = await transaction.get(pollRef);
        if (!snapshot.exists) return;
        Map<String, dynamic> data = snapshot.data() as Map<String, dynamic>;
        List<String> votedUserIds = List<String>.from(
          data['votedUserIds'] ?? [],
        );
        if (votedUserIds.contains(currentUser.uid))
          throw Exception("You have already voted!");

        Map<String, dynamic> votes = Map<String, dynamic>.from(
          data['votes'] ?? {},
        );
        votes[option] = (votes[option] ?? 0) + 1;
        votedUserIds.add(currentUser.uid);

        transaction.update(pollRef, {
          'votes': votes,
          'votedUserIds': votedUserIds,
        });
      });
    } catch (e) {
      AppLogger.error("Voting failed", error: e);
      rethrow;
    }
  }
}
