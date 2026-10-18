import 'package:flutter/material.dart';
import '../models/person.dart';
import '../models/expense.dart';
import '../services/storage_service.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final _storage = StorageService();
  String _groupName = 'Apartment Expenses';
  List<Person> _people = [];
  List<Expense> _expenses = [];
  Map<String, double> _balances = {};
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _loading = true);
    final groupName = await _storage.getGroupName();
    final people = await _storage.getPeople();
    final expenses = await _storage.getExpenses();
    final balances = _storage.calculateBalances(people, expenses);

    if (mounted) {
      setState(() {
        _groupName = groupName;
        _people = people;
        _expenses = expenses;
        _balances = balances;
        _loading = false;
      });
    }
  }

  double get _totalExpenses {
    return _expenses.fold(0.0, (sum, e) => sum + e.amount);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_groupName),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
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
                padding: const EdgeInsets.all(16),
                children: [
                  // Total card
                  Card(
                    color: Theme.of(context).colorScheme.primaryContainer,
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Total Shared Expenses',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '\$${_totalExpenses.toStringAsFixed(2)}',
                            style: Theme.of(context)
                                .textTheme
                                .headlineMedium
                                ?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: Theme.of(context)
                                      .colorScheme
                                      .onPrimaryContainer,
                                ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${_expenses.length} expense${_expenses.length == 1 ? '' : 's'}',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Balances',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 12),
                  if (_people.isEmpty)
                    const Card(
                      child: Padding(
                        padding: EdgeInsets.all(24),
                        child: Center(
                          child: Text(
                            'No participants yet.\nAdd people from the People tab.',
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                    )
                  else
                    ..._people.map((person) {
                      final balance = _balances[person.id] ?? 0.0;
                      final isPositive = balance >= 0;
                      return Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: isPositive
                                ? Colors.green.shade100
                                : Colors.red.shade100,
                            child: Icon(
                              isPositive
                                  ? Icons.arrow_upward
                                  : Icons.arrow_downward,
                              color: isPositive
                                  ? Colors.green.shade700
                                  : Colors.red.shade700,
                              size: 20,
                            ),
                          ),
                          title: Text(person.name),
                          subtitle: Text(
                            isPositive
                                ? 'Others owe them'
                                : 'They owe the group',
                          ),
                          trailing: Text(
                            '\$${balance.abs().toStringAsFixed(2)}',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              color: isPositive
                                  ? Colors.green.shade700
                                  : Colors.red.shade700,
                            ),
                          ),
                        ),
                      );
                    }),
                ],
              ),
            ),
    );
  }
}
