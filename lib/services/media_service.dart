import 'dart:io';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:video_compress/video_compress.dart';
import 'package:lockify/models/messages.dart';
import 'package:lockify/services/chats/chat_service.dart';
import 'package:lockify/services/messaging_service.dart';

enum MediaType { image, video, document, poll }

class MediaService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final ChatService _chatService = ChatService();
  final MessagingService _messagingService = MessagingService();

  // Helper for Metadata preparation
  Future<Map<String, dynamic>> _prepareMediaMetadata(File? file, MediaType type, String? question) async {
    String lastMsgText = "";
    String? base64Thumb;
    String messageTypeStr = "";

    if (type == MediaType.image && file != null) {
      lastMsgText = "📷 Photo";
      messageTypeStr = "image";
      final result = await FlutterImageCompress.compressWithFile(file.absolute.path, minWidth: 40, minHeight: 40, quality: 5, format: CompressFormat.webp);
      if (result != null) base64Thumb = base64Encode(result);
    } else if (type == MediaType.video && file != null) {
      lastMsgText = "📹 Video";
      messageTypeStr = "video";
      final thumbnailFile = await VideoCompress.getFileThumbnail(file.path, quality: 10);
      final result = await FlutterImageCompress.compressWithFile(thumbnailFile.path, minWidth: 40, minHeight: 40, quality: 5);
      if (result != null) base64Thumb = base64Encode(result);
    } else if (type == MediaType.document && file != null) {
      lastMsgText = "📄 Document";
      messageTypeStr = "document";
    } else if (type == MediaType.poll) {
      lastMsgText = "📊 Poll: $question";
      messageTypeStr = "poll";
    }

    return {
      'lastMsgText': lastMsgText,
      'messageTypeStr': messageTypeStr,
      'base64Thumb': base64Thumb,
    };
  }

  // Unified Media Sending Method
  Future<void> sendMedia({
    required String collectionPath,
    required String docId,
    required File? file,
    required MediaType type,
    String? pollId,
    String? question,
    Map<String, dynamic>? additionalMetadata,
  }) async {
    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) throw Exception("User not authenticated");
      
      final senderPhone = await _chatService.getSenderPhone();
      final meta = await _prepareMediaMetadata(file, type, question);

      Messages messageObj = Messages(
        message: meta['lastMsgText'],
        timestamp: FieldValue.serverTimestamp(),
        senderUid: currentUser.uid,
        imageUrl: type == MediaType.poll ? (pollId ?? "") : "", 
        pollId: pollId,
        base64Thumbnail: meta['base64Thumb'],
        messageType: meta['messageTypeStr'],
      );

      // Unified call to MessagingService
      await _messagingService.sendMessage(
        collectionPath: collectionPath,
        docId: docId,
        message: messageObj,
        senderPhone: senderPhone,
        additionalMetadata: additionalMetadata ?? {},
      );

      // Background Upload (if not a poll)
      if (file != null && type != MediaType.poll) {
        _uploadMediaInBackground(collectionPath, docId, file, type);
      }
    } catch (e) {
      debugPrint("Media send failed in $collectionPath: $e");
    }
  }

  // Backward Compatibility / Convenience Wrappers (Optional but helpful for MVP)
  Future<void> sendMediaMessage({
    required String receiverPhone,
    required File? file,
    required MediaType type,
    String? receiverName,
    String? pollId,
    String? question,
  }) async {
    final senderPhone = await _chatService.getSenderPhone();
    final normalizedReceiverPhone = _chatService.normalizePhone(receiverPhone);
    List<String> sortedPhones = [senderPhone, normalizedReceiverPhone];
    sortedPhones.sort();
    String roomID = sortedPhones.join('_');

    // Resolve receiver UID if possible for metadata
    String? receiverUid;
    final userQuery = await _firestore.collection('users').where('phone', isEqualTo: normalizedReceiverPhone).limit(1).get();
    if (userQuery.docs.isNotEmpty) receiverUid = userQuery.docs.first.id;

    await sendMedia(
      collectionPath: 'chat_rooms',
      docId: roomID,
      file: file,
      type: type,
      pollId: pollId,
      question: question,
      additionalMetadata: {
        'type': 'private',
        'participantPhones': FieldValue.arrayUnion([senderPhone, normalizedReceiverPhone]),
        'participantUids': FieldValue.arrayUnion(receiverUid != null ? [FirebaseAuth.instance.currentUser!.uid, receiverUid] : [FirebaseAuth.instance.currentUser!.uid]),
      },
    );
  }

  Future<void> sendGroupMediaMessage({
    required String groupId,
    required File? file,
    required MediaType type,
    String? pollId,
    String? question,
  }) async {
    await sendMedia(
      collectionPath: 'groups',
      docId: groupId,
      file: file,
      type: type,
      pollId: pollId,
      question: question,
      additionalMetadata: {'type': 'group'},
    );
  }

  Future<void> sendChannelMediaMessage({
    required String channelId,
    required File? file,
    required MediaType type,
    String? pollId,
    String? question,
  }) async {
    await sendMedia(
      collectionPath: 'channels',
      docId: channelId,
      file: file,
      type: type,
      pollId: pollId,
      question: question,
      additionalMetadata: {'type': 'channel'},
    );
  }

  Future<void> _uploadMediaInBackground(String collection, String docId, File file, MediaType type) async {
    try {
      String folder = type == MediaType.image ? "images" : type == MediaType.video ? "videos" : "docs";
      String ext = type == MediaType.image ? "webp" : type == MediaType.video ? "mp4" : file.path.split('.').last;
      String fileName = "${DateTime.now().millisecondsSinceEpoch}.$ext";
      
      Reference ref = _storage.ref().child('$collection/$docId/$folder/$fileName');
      await ref.putFile(file);
      String url = await ref.getDownloadURL();

      // Find the message doc by searching for the most recent one with this sender and no URL
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) return;

      final query = await _firestore.collection(collection).doc(docId).collection('messages')
          .where('senderUid', isEqualTo: currentUser.uid)
          .where('imageUrl', isEqualTo: "")
          .orderBy('timestamp', descending: true)
          .limit(1)
          .get();

      if (query.docs.isNotEmpty) {
        await query.docs.first.reference.update({'imageUrl': url});
      }
    } catch (e) {
      debugPrint("Background upload error: $e");
    }
  }
}
