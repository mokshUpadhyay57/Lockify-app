import 'package:flutter_test/flutter_test.dart';
import 'package:lockify/models/polls.dart';

void main() {
  group('Polls Model Tests', () {
    final now = DateTime.now();

    test('toMap() should correctly serialize a Polls object', () {
      final poll = Polls(
        id: 'poll123',
        question: 'What is your favorite color?',
        options: ['Red', 'Blue', 'Green'],
        votes: {'Red': 1, 'Blue': 0, 'Green': 5},
        votedUserIds: ['user1', 'user2'],
        createdAt: now,
      );

      final map = poll.toMap();

      expect(map['id'], 'poll123');
      expect(map['question'], 'What is your favorite color?');
      expect(map['options'], ['Red', 'Blue', 'Green']);
      expect(map['votes'], {'Red': 1, 'Blue': 0, 'Green': 5});
      expect(map['votedUserIds'], ['user1', 'user2']);
      expect(map['createdAt'], now.toIso8601String());
    });

    test('fromMap() should correctly deserialize a Map to a Polls object', () {
      final map = {
        'id': 'poll456',
        'question': 'Tabs or Spaces?',
        'options': ['Tabs', 'Spaces'],
        'votes': {'Tabs': 10, 'Spaces': 10},
        'votedUserIds': ['user3', 'user4'],
        'createdAt': now.toIso8601String(),
      };

      final poll = Polls.fromMap(map);

      expect(poll.id, 'poll456');
      expect(poll.question, 'Tabs or Spaces?');
      expect(poll.options, ['Tabs', 'Spaces']);
      expect(poll.votes, {'Tabs': 10, 'Spaces': 10});
      expect(poll.votedUserIds, ['user3', 'user4']);
      expect(poll.createdAt, now);
    });

    test('fromMap() should handle missing optional fields (if any default logically applied)', () {
      final map = {
        'options': ['A', 'B'],
        'votes': {'A': 0, 'B': 0},
        'votedUserIds': <String>[],
        'createdAt': now.toIso8601String(),
      };

      final poll = Polls.fromMap(map);

      expect(poll.id, ''); // Default when null
      expect(poll.question, ''); // Default when null
    });
  });
}
