import 'package:cloud_firestore/cloud_firestore.dart' hide Transaction;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart'; // For debugPrint

import 'package:aifinanceapp/features/transactions/data/models/transaction_model.dart';

class TransactionFirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Add a new transaction to Firestore
  Future<void> addTransaction(Transaction transaction) async {
    final user = _auth.currentUser;
    if (user == null) {
      debugPrint('TransactionFirestoreService: No authenticated user to add transaction.');
      throw Exception('User not logged in.');
    }
    
    debugPrint('TransactionFirestoreService: Attempting to add transaction: ${transaction.toString()}');
    try {
      // Ensure the transaction includes the correct userId
      final transactionData = transaction.toFirestore();
      transactionData['userId'] = user.uid; // Explicitly set or override userId from current auth user

      await _firestore.collection('transactions').add(transactionData);
      debugPrint('TransactionFirestoreService: Transaction added successfully.');
    } catch (e) {
      debugPrint('TransactionFirestoreService: Error adding transaction: $e');
      throw Exception('Failed to add transaction: $e');
    }
  }

  // Get a stream of all transactions for the current user
  Stream<List<Transaction>> getTransactionsForUser() {
    final user = _auth.currentUser;
    if (user == null) {
      debugPrint('TransactionFirestoreService: No authenticated user for transaction stream. Returning empty stream.');
      return Stream.value([]); // Return an empty stream if no user is logged in
    }

    debugPrint('TransactionFirestoreService: Listening for transactions for user: ${user.uid}');
    // Order by 'createdAt' to get the most recent transactions first
    // NOTE: Firestore requires an index for orderBy and where clauses on different fields.
    // If you encounter an error related to missing index, Firebase will provide a link to create it.
    // (This index was handled in the first step of this response)
    return _firestore
        .collection('transactions')
        .where('userId', isEqualTo: user.uid)
        .orderBy('createdAt', descending: true) // Most recent first
        .snapshots()
        .map((snapshot) {
          debugPrint('TransactionFirestoreService: Received ${snapshot.docs.length} transaction documents.');
          return snapshot.docs.map((doc) => Transaction.fromFirestore(doc)).toList();
        })
        .handleError((e) {
          debugPrint('TransactionFirestoreService: Error in transaction stream: $e');
          // Depending on error, you might want to rethrow or return an empty list/stream
          return <Transaction>[]; // Return empty list on error for stream
        });
  }

  // You might add methods for updating/deleting transactions later if needed.
}
