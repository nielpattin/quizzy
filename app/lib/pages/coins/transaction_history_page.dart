import "package:flutter/material.dart";
import "package:intl/intl.dart";
import "../../services/quiz_service.dart";

class TransactionHistoryPage extends StatefulWidget {
  const TransactionHistoryPage({super.key});

  @override
  State<TransactionHistoryPage> createState() => _TransactionHistoryPageState();
}

class _TransactionHistoryPageState extends State<TransactionHistoryPage> {
  List<dynamic> _transactions = [];
  bool _isLoading = true;
  final ScrollController _scrollController = ScrollController();
  int _offset = 0;
  final int _limit = 20;
  bool _hasMore = true;

  @override
  void initState() {
    super.initState();
    _loadTransactions();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadTransactions() async {
    if (!_hasMore) return;

    try {
      final transactions = await QuizService.getCoinTransactions(
        limit: _limit,
        offset: _offset,
      );

      if (mounted) {
        setState(() {
          _transactions.addAll(transactions);
          _isLoading = false;
          _offset += _limit;
          _hasMore = transactions.length == _limit;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _onScroll() {
    if (_scrollController.position.pixels ==
        _scrollController.position.maxScrollExtent) {
      if (!_isLoading && _hasMore) {
        setState(() {
          _isLoading = true;
        });
        _loadTransactions();
      }
    }
  }

  IconData _getTransactionIcon(String type) {
    switch (type) {
      case "quiz_reward":
        return Icons.emoji_events;
      case "streak_bonus":
        return Icons.local_fire_department;
      case "achievement":
        return Icons.military_tech;
      case "daily_login":
        return Icons.calendar_today;
      case "purchase":
        return Icons.shopping_bag;
      case "spent":
        return Icons.shopping_cart;
      default:
        return Icons.monetization_on;
    }
  }

  Color _getTransactionColor(int amount) {
    return amount > 0 ? Colors.green : Colors.red;
  }

  String _formatTransactionType(String type) {
    return type
        .replaceAll("_", " ")
        .split(" ")
        .map((word) {
          return word[0].toUpperCase() + word.substring(1);
        })
        .join(" ");
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text("Transaction History"),
        elevation: 0,
        backgroundColor: theme.scaffoldBackgroundColor,
      ),
      body: _isLoading && _transactions.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : _transactions.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.receipt_long, size: 64, color: Colors.grey[400]),
                  const SizedBox(height: 16),
                  Text(
                    "No transactions yet",
                    style: TextStyle(fontSize: 18, color: Colors.grey[600]),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "Complete quizzes to earn coins!",
                    style: TextStyle(fontSize: 14, color: Colors.grey[500]),
                  ),
                ],
              ),
            )
          : RefreshIndicator(
              onRefresh: () async {
                setState(() {
                  _transactions.clear();
                  _offset = 0;
                  _hasMore = true;
                  _isLoading = true;
                });
                await _loadTransactions();
              },
              child: ListView.builder(
                controller: _scrollController,
                itemCount: _transactions.length + 1,
                itemBuilder: (context, index) {
                  if (index == _transactions.length) {
                    return _isLoading && _hasMore
                        ? const Center(
                            child: Padding(
                              padding: EdgeInsets.all(16.0),
                              child: CircularProgressIndicator(),
                            ),
                          )
                        : const SizedBox.shrink();
                  }

                  final transaction = _transactions[index];
                  final amount = transaction["amount"] as int;
                  final type = transaction["type"] as String;
                  final description = transaction["description"] as String?;
                  final createdAt = DateTime.parse(transaction["createdAt"]);
                  final balanceAfter = transaction["balanceAfter"] as int;

                  return Card(
                    margin: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 6,
                    ),
                    child: ListTile(
                      leading: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: _getTransactionColor(
                            amount,
                          ).withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          _getTransactionIcon(type),
                          color: _getTransactionColor(amount),
                        ),
                      ),
                      title: Text(
                        description ?? _formatTransactionType(type),
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 4),
                          Text(
                            DateFormat(
                              "MMM dd, yyyy • HH:mm",
                            ).format(createdAt),
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            "Balance: $balanceAfter coins",
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                      trailing: Text(
                        amount > 0 ? "+$amount" : "$amount",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: _getTransactionColor(amount),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
    );
  }
}
