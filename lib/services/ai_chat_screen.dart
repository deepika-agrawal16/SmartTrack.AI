import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; // Import Firestore
import 'package:aifinanceapp/services/gemini_service.dart';

// CORRECT IMPORTS WITH ALIASES
import 'package:aifinanceapp/features/transactions/data/models/transaction_model.dart'
    as app_transaction;
import 'package:aifinanceapp/features/authentication/data/models/user_model.dart'
    as app_user;

// Make sure FirestoreService uses the aliased types
class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Stream<List<app_transaction.Transaction>> getTransactionsForUser(
      String userId) {
    // IMPORTANT: Firestore Security Rules are crucial here.
    // Ensure your rules allow read access to 'transactions' collection
    // for authenticated users, specifically:
    // match /transactions/{transactionId} {
    //   allow read: if request.auth != null && request.auth.uid == userId;
    // }
    return _db
        .collection('transactions')
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => app_transaction.Transaction.fromFirestore(doc))
              .toList(),
        );
  }

  // Use app_user.User here
  Future<app_user.User?> getUserData(String userId) async {
    // IMPORTANT: Firestore Security Rules are crucial here.
    // Ensure your rules allow read access to 'users' collection
    // for authenticated users, specifically:
    // match /users/{userId} {
    //   allow read: if request.auth != null && request.auth.uid == userId;
    // }
    try {
      DocumentSnapshot doc = await _db.collection('users').doc(userId).get();
      if (doc.exists) {
        return app_user.User.fromFirestore(
            doc); // Use app_user.User for the factory call
      }
    } catch (e) {
      print("Error fetching user data: $e");
    }
    return null;
  }
}

class AIChatScreen extends StatefulWidget {
  final String userId; // Pass the current user's ID

  const AIChatScreen({super.key, required this.userId});

  @override
  State<AIChatScreen> createState() => _AIChatScreenState();
}

class _AIChatScreenState extends State<AIChatScreen> {
  final TextEditingController _controller = TextEditingController();
  final List<Map<String, String>> _messages = [];
  final GeminiService _geminiService = GeminiService();
  final FirestoreService _firestoreService = FirestoreService();
  bool _isLoading = false;

  @override
  void dispose() {
    _controller.dispose(); // Dispose the controller to prevent memory leaks
    super.dispose();
  }

  // Use app_transaction.Transaction for the list type
  Future<List<app_transaction.Transaction>> _fetchUserTransactions(
      String userId) async {
    // Use .first to convert the Stream<List> to a Future<List>
    final snapshot = await _firestoreService.getTransactionsForUser(userId).first;
    return snapshot;
  }

  // Use app_user.User for the Future type
  Future<app_user.User?> _fetchUserData(String userId) async {
    return await _firestoreService.getUserData(userId);
  }

  Future<void> _sendMessage() async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;

    setState(() {
      _messages.add({'role': 'user', 'text': text});
      _controller.clear();
      _isLoading = true;
    });

    try {
      // Use app_user.User for the type of 'user' variable
      final app_user.User? user = await _fetchUserData(widget.userId);
      // Use app_transaction.Transaction for the type of 'allTransactions' variable
      final List<app_transaction.Transaction> allTransactions =
          await _fetchUserTransactions(widget.userId);

      final now = DateTime.now();
      // Use app_transaction.Transaction for the type of 'currentMonthTransactions'
      final currentMonthTransactions = allTransactions.where((t) {
        return t.date.year == now.year && t.date.month == now.month;
      }).toList();

      String financialContext = _buildFinancialContext(
        user,
        currentMonthTransactions,
      );

      final String fullPrompt = """
You are a helpful personal finance AI assistant for a money tracking app.
The current date is ${now.toLocal().toString().split(' ')[0]}.
Here's the user's financial data for the current month:
$financialContext

User's question: "$text"

Based on the provided data, give a concise and actionable financial advice or answer the question.
If the question is about budgeting, refer to their set monthly budget.
If the question is about spending, analyze their transactions.
Avoid making up data not provided.
""";

      final response = await _geminiService.getGeminiResponse(fullPrompt);

      setState(() {
        _messages.add({'role': 'ai', 'text': response});
      });
    } catch (e) {
      setState(() {
        _messages.add({'role': 'ai', 'text': 'Error: ${e.toString()}'});
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  // Use app_user.User and app_transaction.Transaction for parameters
  String _buildFinancialContext(
    app_user.User? user,
    List<app_transaction.Transaction> transactions,
  ) {
    if (user == null && transactions.isEmpty) {
      return "No financial data available for the user.";
    }

    StringBuffer contextBuffer = StringBuffer();
    if (user != null) {
      contextBuffer.writeln("User Name: ${user.userName}");
      if (user.monthlyBudget != null) {
        contextBuffer.writeln(
          "Set Monthly Budget: ₹${user.monthlyBudget?.toStringAsFixed(2)}",
        );
      }
    }

    if (transactions.isNotEmpty) {
      double totalIncome = 0;
      double totalExpense = 0;
      Map<String, double> categorySpending = {};

      for (var t in transactions) {
        if (t.type.toLowerCase() == 'income') {
          totalIncome += t.amount;
        } else if (t.type.toLowerCase() == 'expense' ||
            t.type.toLowerCase() == 'debit & loan') {
          categorySpending.update(
            t.category ?? 'Uncategorized',
            (value) => value + t.amount,
            ifAbsent: () => t.amount,
          );
          totalExpense += t.amount;
        }
      }

      contextBuffer.writeln("\nFinancial Summary for current month:");
      contextBuffer.writeln(
        "- Total Income: ₹${totalIncome.toStringAsFixed(2)}",
      );
      contextBuffer.writeln(
        "- Total Expense: ₹${totalExpense.toStringAsFixed(2)}",
      );
      contextBuffer.writeln("Expense by Category (current month):");
      if (categorySpending.isEmpty) {
        contextBuffer.writeln("  - No categorized expenses this month.");
      } else {
        categorySpending.forEach((category, amount) {
          contextBuffer.writeln("  - $category: ₹${amount.toStringAsFixed(2)}");
        });
      }

      contextBuffer.writeln("\nTop 5 Recent Transactions (current month):");
      if (transactions.isEmpty) {
        contextBuffer.writeln("  - No recent transactions this month.");
      } else {
        transactions.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        for (var i = 0; i < transactions.length && i < 5; i++) {
          final t = transactions[i];
          final String displayCategory = t.category ?? 'N/A';
          final String displayNote = t.note != null && t.note!.isNotEmpty
              ? ' (${t.note})'
              : '';
          contextBuffer.writeln(
            "- ${t.type.toUpperCase()}: $displayCategory - ₹${t.amount.toStringAsFixed(2)} (${t.date.toLocal().toString().split(' ')[0]})$displayNote",
          );
        }
      }
    } else {
      contextBuffer.writeln(
        "\nNo transactions recorded for the current month.",
      );
    }

    return contextBuffer.toString();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('AI Financial Assistant')),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(8.0),
              reverse: true, // Show latest messages at the bottom
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                // Display messages in chronological order, but scroll from bottom
                final message = _messages[_messages.length - 1 - index];
                return Align(
                  alignment: message['role'] == 'user'
                      ? Alignment.centerRight
                      : Alignment.centerLeft,
                  child: Container(
                    margin: const EdgeInsets.symmetric(vertical: 4.0),
                    padding: const EdgeInsets.all(12.0),
                    decoration: BoxDecoration(
                      color: message['role'] == 'user'
                          ? Colors.blueAccent
                          : Colors.grey[300],
                      borderRadius: BorderRadius.circular(12.0),
                    ),
                    child: Text(
                      message['text']!,
                      style: TextStyle(
                        color: message['role'] == 'user'
                            ? Colors.white
                            : Colors.black87,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          if (_isLoading)
            const Padding(
              padding: EdgeInsets.all(8.0),
              child: LinearProgressIndicator(),
            ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    decoration: InputDecoration(
                      hintText: 'Ask your financial assistant...',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(20.0),
                      ),
                    ),
                    onSubmitted: (_) => _sendMessage(),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.send),
                  onPressed: _isLoading ? null : _sendMessage,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}