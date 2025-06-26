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

class _AIChatScreenState extends State<AIChatScreen>
    with SingleTickerProviderStateMixin {
  final TextEditingController _controller = TextEditingController();
  final List<Map<String, String>> _messages = [];
  final GeminiService _geminiService = GeminiService();
  final FirestoreService _firestoreService = FirestoreService();
  bool _isLoading = false;
  late ScrollController _scrollController;
  late AnimationController _animationController;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _animation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeOut,
      ),
    );
    // Initial AI greeting
    _messages.add({
      'role': 'ai',
      'text': 'Hello! I am your AI financial assistant. How can I help you today?'
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    _animationController.dispose(); // Dispose animation controller
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<List<app_transaction.Transaction>> _fetchUserTransactions(
      String userId) async {
    final snapshot =
        await _firestoreService.getTransactionsForUser(userId).first;
    return snapshot;
  }

  Future<app_user.User?> _fetchUserData(String userId) async {
    return await _firestoreService.getUserData(userId);
  }

  Future<void> _sendMessage() async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;

    if (!mounted) return; // Add this check
    setState(() {
      _messages.add({'role': 'user', 'text': text});
      _controller.clear();
      _isLoading = true;
    });

    _scrollToBottom();

    try {
      final app_user.User? user = await _fetchUserData(widget.userId);
      final List<app_transaction.Transaction> allTransactions =
          await _fetchUserTransactions(widget.userId);

      final now = DateTime.now();
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

      if (!mounted) return; // Add this check
      setState(() {
        _messages.add({'role': 'ai', 'text': response});
      });
      _scrollToBottom();
    } catch (e) {
      if (!mounted) return; // Add this check
      setState(() {
        _messages.add({'role': 'ai', 'text': 'Error: ${e.toString()}'});
      });
      _scrollToBottom();
    } finally {
      if (!mounted) return; // Add this check
      setState(() {
        _isLoading = false;
      });
    }
  }

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
          final String displayNote =
              t.note != null && t.note!.isNotEmpty ? ' (${t.note})' : '';
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
      appBar: AppBar(
        title: const Text(
          'AI Financial Assistant',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF3062CE), Color(0xFF6B8DE3)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFE3F2FD), Colors.white],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Column(
          children: [
            Expanded(
              child: ListView.builder(
                controller: _scrollController,
                padding: const EdgeInsets.all(12.0),
                itemCount: _messages.length,
                itemBuilder: (context, index) {
                  final message = _messages[index];
                  final bool isUser = message['role'] == 'user';
                  // Only forward animation if the widget is mounted
                  if (mounted) {
                    _animationController.forward(from: 0);
                  }
                  return FadeTransition(
                    opacity: _animation,
                    child: SlideTransition(
                      position: Tween<Offset>(
                        begin: isUser ? const Offset(0.5, 0) : const Offset(-0.5, 0),
                        end: Offset.zero,
                      ).animate(
                        CurvedAnimation(
                          parent: _animationController,
                          curve: Curves.easeOut,
                        ),
                      ),
                      child: Align(
                        alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
                        child: ChatBubble(
                          message: message['text']!,
                          isUser: isUser,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            if (_isLoading)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
                child: LinearProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF3062CE)),
                  backgroundColor: Color(0xFFD9E6FE),
                ),
              ),
            Padding(
              padding: const EdgeInsets.all(12.0),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      decoration: InputDecoration(
                        hintText: 'Ask your financial assistant...',
                        hintStyle: TextStyle(color: Colors.grey[600]),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(25.0),
                          borderSide: BorderSide.none,
                        ),
                        filled: true,
                        fillColor: Colors.grey[200],
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 20.0, vertical: 14.0),
                      ),
                      style: const TextStyle(fontSize: 16.0),
                      onSubmitted: (_) => _sendMessage(),
                      textCapitalization: TextCapitalization.sentences,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFF3062CE),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.2),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: IconButton(
                      icon: const Icon(Icons.send, color: Colors.white),
                      onPressed: _isLoading ? null : _sendMessage,
                      tooltip: 'Send message',
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class ChatBubble extends StatelessWidget {
  final String message;
  final bool isUser;

  const ChatBubble({
    super.key,
    required this.message,
    required this.isUser,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 6.0, horizontal: 4.0),
      padding: const EdgeInsets.symmetric(vertical: 10.0, horizontal: 16.0),
      constraints: BoxConstraints(
        maxWidth: MediaQuery.of(context).size.width * 0.75,
      ),
      decoration: BoxDecoration(
        color: isUser ? const Color(0xFF3062CE) : Colors.grey[100],
        borderRadius: BorderRadius.only(
          topLeft: const Radius.circular(16.0),
          topRight: const Radius.circular(16.0),
          bottomLeft: isUser ? const Radius.circular(16.0) : Radius.zero,
          bottomRight: isUser ? Radius.zero : const Radius.circular(16.0),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Text(
        message,
        style: TextStyle(
          color: isUser ? Colors.white : Colors.black87,
          fontSize: 15.0,
        ),
      ),
    );
  }
}