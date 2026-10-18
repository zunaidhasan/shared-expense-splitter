import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
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

  String _personName(String id) {
    return _people.where((person) => person.id == id).firstOrNull?.name ??
        'Unknown';
  }

  String _initials(String name) {
    final parts = name.trim().split(RegExp(r'\s+')).where((part) => part.isNotEmpty);
    if (parts.isEmpty) return '?';
    return parts.take(2).map((part) => part[0].toUpperCase()).join();
  }

  Widget _sectionHeading(String title, String detail) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Expanded(
            child: Text(
              title,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
            ),
          ),
          Text(
            detail,
            style: TextStyle(
              color: Theme.of(context).colorScheme.primary,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'SHARETAB',
              style: TextStyle(
                color: Theme.of(context).colorScheme.primary,
                fontSize: 11,
                fontWeight: FontWeight.w800,
              ),
            ),
            Text(
              _groupName,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
            ),
          ],
        ),
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
                padding: const EdgeInsets.fromLTRB(18, 12, 18, 24),
                children: [
                  Container(
                    padding: const EdgeInsets.all(22),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1A2A3D),
                      borderRadius: BorderRadius.circular(22),
                      border: Border.all(color: const Color(0xFF26384A)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.account_balance_wallet_outlined,
                                size: 18, color: Color(0xFF5ADBC1)),
                            const SizedBox(width: 8),
                            const Expanded(
                              child: Text(
                                'TOTAL GROUP EXPENSES',
                                style: TextStyle(
                                  color: Color(0xFFB4C2D5),
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                            Icon(Icons.groups_rounded,
                                size: 17,
                                color: Theme.of(context).colorScheme.primary),
                            const SizedBox(width: 5),
                            Text(
                              '${_people.length} active',
                              style: const TextStyle(
                                  color: Color(0xFFB4C2D5), fontSize: 12),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Text(
                          '\$${_totalExpenses.toStringAsFixed(2)}',
                          style: const TextStyle(
                            color: Color(0xFFE7ECFF),
                            fontSize: 34,
                            height: 1.1,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 18),
                        Row(
                          children: [
                            _summaryMetric(
                              context,
                              '${_expenses.length}',
                              'items logged',
                              Icons.receipt_long_outlined,
                            ),
                            const SizedBox(width: 10),
                            _summaryMetric(
                              context,
                              _people.isEmpty ? '--' : '${_people.length}',
                              'members',
                              Icons.people_outline_rounded,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 26),
                  _sectionHeading(
                    'Member balances',
                    '${_balances.values.where((balance) => balance.abs() >= 0.01).length} unsettled',
                  ),
                  if (_people.isEmpty)
                    _emptyState(
                      context,
                      Icons.people_outline_rounded,
                      'Your group starts here',
                      'Add people to begin splitting expenses.',
                    )
                  else
                    ..._people.map((person) {
                      final balance = _balances[person.id] ?? 0.0;
                      final isSettled = balance.abs() < 0.01;
                      final isOwed = balance > 0;
                      final accent = isSettled
                          ? const Color(0xFF8794AA)
                          : isOwed
                              ? Theme.of(context).colorScheme.primary
                              : const Color(0xFFFF718A);
                      return Container(
                        margin: const EdgeInsets.only(bottom: 9),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 13),
                        decoration: BoxDecoration(
                          color: const Color(0xFF151F32),
                          borderRadius: BorderRadius.circular(17),
                        ),
                        child: Row(
                          children: [
                            CircleAvatar(
                              radius: 22,
                              backgroundColor: accent.withOpacity(0.15),
                              child: Text(
                                _initials(person.name),
                                style: TextStyle(
                                  color: accent,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    person.name,
                                    style: const TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  const SizedBox(height: 3),
                                  Text(
                                    isSettled
                                        ? 'Settled up'
                                        : isOwed
                                            ? 'Is owed by the group'
                                            : 'Owes the group',
                                    style: TextStyle(
                                      color: accent,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              '\$${balance.abs().toStringAsFixed(2)}',
                              style: TextStyle(
                                color: accent,
                                fontSize: 15,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ],
                        ),
                      );
                    }),
                  const SizedBox(height: 20),
                  _sectionHeading(
                    'Recent expenses',
                    '${_expenses.length} total',
                  ),
                  if (_expenses.isEmpty)
                    _emptyState(
                      context,
                      Icons.receipt_long_outlined,
                      'No expenses yet',
                      'Your recent activity will appear here.',
                    )
                  else
                    ..._expenses.take(4).map((expense) {
                      return Container(
                        margin: const EdgeInsets.only(bottom: 9),
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: const Color(0xFF151F32),
                          borderRadius: BorderRadius.circular(17),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 42,
                              height: 42,
                              decoration: BoxDecoration(
                                color: const Color(0xFF00B99D).withOpacity(0.14),
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
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    expense.title,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Paid by ${_personName(expense.payerId)} · ${DateFormat('MMM d').format(expense.createdAt)}',
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
                            const SizedBox(width: 8),
                            Text(
                              '\$${expense.amount.toStringAsFixed(2)}',
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w800,
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

  Widget _summaryMetric(
    BuildContext context,
    String value,
    String label,
    IconData icon,
  ) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
        decoration: BoxDecoration(
          color: const Color(0xFF101A2D).withOpacity(0.72),
          borderRadius: BorderRadius.circular(13),
        ),
        child: Row(
          children: [
            Icon(icon, color: Theme.of(context).colorScheme.primary, size: 17),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(value,
                      style: const TextStyle(fontWeight: FontWeight.w700)),
                  Text(label,
                      style: const TextStyle(
                          color: Color(0xFF9AA8C0), fontSize: 11)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _emptyState(
    BuildContext context,
    IconData icon,
    String title,
    String message,
  ) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      decoration: BoxDecoration(
        color: const Color(0xFF151F32),
        borderRadius: BorderRadius.circular(17),
      ),
      child: Column(
        children: [
          Icon(icon, color: Theme.of(context).colorScheme.primary, size: 26),
          const SizedBox(height: 10),
          Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
          const SizedBox(height: 4),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Color(0xFF9AA8C0), fontSize: 13),
          ),
        ],
      ),
    );
  }
}
