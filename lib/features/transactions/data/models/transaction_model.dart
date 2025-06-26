import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart'; // For IconData

class Transaction {
  final String? id; // Null for new transactions, populated after Firestore save
  final String userId;
  final String type; // 'Income', 'Expense', 'Debit & Loan', 'Repay'
  final double amount;
  final String currency;
  final String? category; // Null for income
  final String? note;
  final DateTime date;
  final TimeOfDay? time;
  final String? localImagePath; // Path to locally stored receipt image
  final Timestamp createdAt; // When the transaction was added to Firestore

  Transaction({
    this.id,
    required this.userId,
    required this.type,
    required this.amount,
    required this.currency,
    this.category,
    this.note,
    required this.date,
    this.time,
    this.localImagePath,
    required this.createdAt,
  });

  // Convert a Transaction object to a Firestore-compatible Map
  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'type': type,
      'amount': amount,
      'currency': currency,
      'category': category,
      'note': note,
      'date': Timestamp.fromDate(date), // Store DateTime as Firestore Timestamp
      'time': time != null
          ? '${time!.hour}:${time!.minute}'
          : null, // Store TimeOfDay as string (e.g., "14:30")
      'localImagePath': localImagePath,
      'createdAt': createdAt,
    };
  }

  // Create a Transaction object from a Firestore snapshot
  factory Transaction.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;

    // Safely parse TimeOfDay from string
    TimeOfDay? parsedTime;
    if (data['time'] != null && data['time'] is String) {
      final parts = (data['time'] as String).split(':');
      if (parts.length == 2) {
        parsedTime = TimeOfDay(
          hour: int.parse(parts[0]),
          minute: int.parse(parts[1]),
        );
      }
    }

    // Always return a Transaction or throw if required fields are missing
    if (data['userId'] == null ||
        data['type'] == null ||
        data['amount'] == null ||
        data['currency'] == null ||
        data['date'] == null ||
        data['createdAt'] == null) {
      throw StateError('Missing required transaction fields in Firestore document');
    }

    return Transaction(
      id: doc.id,
      userId: data['userId'],
      type: data['type'],
      amount: (data['amount'] as num).toDouble(), // Ensure it's a double
      currency: data['currency'],
      category: data['category'],
      note: data['note'],
      date: (data['date'] as Timestamp).toDate(), // Convert Firestore Timestamp to DateTime
      time: parsedTime,
      localImagePath: data['localImagePath'],
      createdAt: data['createdAt'] as Timestamp,
    );
  }

  @override
  String toString() {
    return 'Transaction(id: $id, userId: $userId, type: $type, amount: $amount, '
        'currency: $currency, category: $category, note: $note, date: $date, '
        'time: ${time != null ? '${time!.hour.toString().padLeft(2, '0')}:${time!.minute.toString().padLeft(2, '0')}' : null}, '
        'localImagePath: $localImagePath, createdAt: $createdAt)';
  }
}
