import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/person.dart';
import '../models/expense.dart';
import '../services/storage_service.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  final _storage = StorageService();
  List<Expense> _expenses = [];
  List<Person> _people = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _loading = true);
    final expenses = await _storage.getExpenses();
    final people = await _storage.getPeople();
    if (mounted) {
      setState(() {
        _expenses = expenses;
        _people = people;
        _loading = false;
      });
    }
  }

  String _personName(String id) {
    final person = _people.where((p) => p.id == id).firstOrNull;
    return person?.name ?? 'Unknown';
  }

  Future<void> _deleteExpense(Expense expense) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete expense?'),
        content: Text('Delete "${expense.title}"? This cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    final updated = _expenses.where((e) => e.id != expense.id).toList();
    await _storage.saveExpenses(updated);
    await _loadData();

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Expense deleted')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('MMM d · h:mm a');

    return Scaffold(
      appBar: AppBar(
        title: const Text('Expense history'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: _loadData,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadData,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(18, 8, 18, 24),
                children: [
                  Container(
                    padding: const EdgeInsets.all(19),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1A2A3D),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 46,
                          height: 46,
                          decoration: BoxDecoration(
                            color: const Color(0xFF00B99D).withOpacity(0.14),
                            borderRadius: BorderRadius.circular(15),
                          ),
                          child: const Icon(Icons.receipt_long_outlined,
                              color: Color(0xFF5ADBC1)),
                        ),
                        const SizedBox(width: 13),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'ALL ACTIVITY',
                                style: TextStyle(
                                  color: Color(0xFFB4C2D5),
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '${_expenses.length} expense${_expenses.length == 1 ? '' : 's'} logged',
                                style: const TextStyle(
                                  fontSize: 19,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 19),
                  if (_expenses.isEmpty)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 22, vertical: 34),
                      decoration: BoxDecoration(
                        color: const Color(0xFF151F32),
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: const Column(
                        children: [
                          Icon(Icons.receipt_long_outlined,
                              color: Color(0xFF5ADBC1), size: 30),
                          SizedBox(height: 12),
                          Text(
                            'No expenses yet',
                            style: TextStyle(
                                fontSize: 17, fontWeight: FontWeight.w700),
                          ),
                          SizedBox(height: 5),
                          Text(
                            'Add an expense and it will appear here.',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: Color(0xFF9AA8C0)),
                          ),
                        ],
                      ),
                    )
                  else
                    ..._expenses.map((expense) {
                      final payerName = _personName(expense.payerId);
                      final shareNames = expense.participantIds
                          .map(_personName)
                          .join(', ');
                      return Container(
                        margin: const EdgeInsets.only(bottom: 10),
                        padding: const EdgeInsets.fromLTRB(15, 14, 10, 12),
                        decoration: BoxDecoration(
                          color: const Color(0xFF151F32),
                          borderRadius: BorderRadius.circular(18),
                        ),
                        child: Column(
                          children: [
                            Row(
                              children: [
                                Container(
                                  width: 43,
                                  height: 43,
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF00B99D)
                                        .withOpacity(0.14),
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                  child: const Icon(
                                    Icons.receipt_long_outlined,
                                    color: Color(0xFF5ADBC1),
                                    size: 20,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        expense.title,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(
                                          fontSize: 15,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        'Paid by $payerName',
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(
                                          color: Color(0xFF9AA8C0),
                                          fontSize: 12,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  '\$${expense.amount.toStringAsFixed(2)}',
                                  style: const TextStyle(
                                    color: Color(0xFF5ADBC1),
                                    fontSize: 15,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ],
                            ),
                            const Padding(
                              padding: EdgeInsets.only(left: 55, top: 10),
                              child: Divider(height: 1),
                            ),
                            Padding(
                              padding: const EdgeInsets.only(left: 55, top: 9),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          dateFormat.format(expense.createdAt),
                                          style: const TextStyle(
                                            color: Color(0xFFADB9CE),
                                            fontSize: 11,
                                          ),
                                        ),
                                        const SizedBox(height: 3),
                                        Text(
                                          'Shared by $shareNames',
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: const TextStyle(
                                            color: Color(0xFF7F8DA7),
                                            fontSize: 11,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  IconButton(
                                    onPressed: () => _deleteExpense(expense),
                                    tooltip: 'Delete expense',
                                    icon: const Icon(
                                        Icons.delete_outline_rounded,
                                        size: 19),
                                    color: const Color(0xFF9AA8C0),
                                    visualDensity: VisualDensity.compact,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    }),
                ],
              ),
            ),
    );
  }
}
