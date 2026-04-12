class Messages {
  final String message;
  final dynamic timestamp;
  final String? imageUrl;
  final String? pollId;
  final String? base64Thumbnail;
  final String messageType; 
  final String senderUid; // Only need senderUid to identify who sent it

  Messages({
    required this.message,
    required this.timestamp,
    required this.senderUid,
    this.imageUrl,
    this.pollId,
    this.base64Thumbnail,
    this.messageType = 'text',
  });

  Map<String, dynamic> toMap() {
    return {
      'message': message,
      'timestamp': timestamp,
      'senderUid': senderUid,
      'imageUrl': imageUrl,
      'pollId': pollId,
      'base64Thumbnail': base64Thumbnail,
      'messageType': messageType,
    };
  }
}
