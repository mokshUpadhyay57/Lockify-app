import 'package:lockify/utils/colors.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';


mixin ChatDateMixin {
  DateTime getDateTime(dynamic timestamp) {
    if (timestamp is Timestamp) return timestamp.toDate();
    if (timestamp is DateTime) return timestamp;
    return DateTime.now();
  }

  String formatDate(DateTime date) {
    final now = DateTime.now();
    if (date.day == now.day && date.month == now.month && date.year == now.year) return "Today";
    if (date.day == now.day - 1 && date.month == now.month && date.year == now.year) return "Yesterday";
    return DateFormat.yMMMMd().format(date);
  }

  Widget buildStickyDateHeader(String dateString) {
    return Container(
      width: double.infinity,
      alignment: Alignment.center,
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [BoxShadow(color: AppColors.black.withOpacity(0.05), blurRadius: 4)]),
        child: Text(dateString,
            style: const TextStyle(fontSize: 12, color: AppColors.grey600, fontWeight: FontWeight.w500)),
      ),
    );
  }
}

