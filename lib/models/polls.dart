class Polls {
  final String id; // unique poll ID (doc ID in Firestore)
  final String question;
  final List<String> options;
  final Map<String, int> votes; // option -> vote count
  final List<String> votedUserIds; // store userIds who already voted
  final DateTime createdAt;

  Polls({
    required this.id,
    required this.question,
    required this.options,
    required this.votes,
    required this.votedUserIds,
    required this.createdAt,
  });

  // Convert model to Map (for Firestore)
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'question': question,
      'options': options,
      'votes': votes,
      'votedUserIds': votedUserIds,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  // Factory method to create PollModel from Firestore snapshot
  factory Polls.fromMap(Map<String, dynamic> map) {
    return Polls(
      id: map['id'] ?? '',
      question: map['question'] ?? '',
      options: List<String>.from(map['options']),
      votes: Map<String, int>.from(map['votes']),
      votedUserIds: List<String>.from(map['votedUserIds']),
      createdAt: DateTime.parse(map['createdAt']),
    );
  }
}
