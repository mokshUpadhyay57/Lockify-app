import 'package:flutter_test/flutter_test.dart';
import 'package:lockify/models/messages.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

void main() {
  group('Messages Model Tests', () {
    test('toMap() should correctly serialize a Messages object', () {
      final timestamp = Timestamp.now();
      final message = Messages(
        message: 'Hello, World!',
        timestamp: timestamp,
        senderUid: 'user123',
        imageUrl: 'https://example.com/image.png',
        messageType: 'image',
      );

      final map = message.toMap();

      expect(map['message'], 'Hello, World!');
      expect(map['timestamp'], timestamp);
      expect(map['senderUid'], 'user123');
      expect(map['imageUrl'], 'https://example.com/image.png');
      expect(map['pollId'], null);
      expect(map['base64Thumbnail'], null);
      expect(map['messageType'], 'image');
    });

    test('toMap() should use default messageType when not provided', () {
      final timestamp = Timestamp.now();
      final message = Messages(
        message: 'Just text',
        timestamp: timestamp,
        senderUid: 'user456',
      );

      final map = message.toMap();

      expect(map['messageType'], 'text'); // Default value
    });
  });
}
