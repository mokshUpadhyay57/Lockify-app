import 'package:flutter_test/flutter_test.dart';
import 'package:lockify/utils/chat_date_mixin.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

// Create a concrete class to mixin ChatDateMixin for testing
class TestClass with ChatDateMixin {}

void main() {
  group('ChatDateMixin Tests', () {
    late TestClass testClass;

    setUp(() {
      testClass = TestClass();
    });

    test('getDateTime() should return DateTime from Timestamp', () {
      final now = DateTime.now();
      final timestamp = Timestamp.fromDate(now);

      final result = testClass.getDateTime(timestamp);

      // They might not be exactly equal down to microsecond due to precision loss
      // when converting to Timestamp and back, but let's check it's very close or exact.
      expect(result.year, now.year);
      expect(result.month, now.month);
      expect(result.day, now.day);
      expect(result.hour, now.hour);
      expect(result.minute, now.minute);
      expect(result.second, now.second);
    });

    test('getDateTime() should return the same DateTime object if passed a DateTime', () {
      final now = DateTime.now();

      final result = testClass.getDateTime(now);

      expect(result, now);
    });

    test('getDateTime() should return current time (or at least a DateTime) if passed something else', () {
      final result = testClass.getDateTime('not a date');

      expect(result, isA<DateTime>());
      // It returns DateTime.now() inside the mixin when type doesn't match
      expect(result.difference(DateTime.now()).inSeconds, 0);
    });

    test('formatDate() should return "Today" for current date', () {
      final now = DateTime.now();
      final result = testClass.formatDate(now);

      expect(result, 'Today');
    });

    test('formatDate() should return "Yesterday" for yesterday\'s date', () {
      final yesterday = DateTime.now().subtract(const Duration(days: 1));
      final result = testClass.formatDate(yesterday);

      expect(result, 'Yesterday');
    });

    test('formatDate() should return formatted date string for older dates', () {
      final olderDate = DateTime.now().subtract(const Duration(days: 5));
      final expectedFormat = DateFormat.yMMMMd().format(olderDate);

      final result = testClass.formatDate(olderDate);

      expect(result, expectedFormat);
    });
  });
}
