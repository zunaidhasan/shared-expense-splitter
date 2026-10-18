import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../models/expense.dart';
import '../models/person.dart';
import '../services/storage_service.dart';

class PeopleScreen extends StatefulWidget {
  const PeopleScreen({super.key});

  @override
  State<PeopleScreen> createState() => _PeopleScreenState();
}

class _PeopleScreenState extends State<PeopleScreen> {
  final _storage = StorageService();
  final _uuid = const Uuid();
  List<Person> _people = [];
  List<Expense> _expenses = [];
  Map<String, double> _balances = {};
  String _groupName = 'Apartment Expenses';
  bool _loading = true;
  final _nameController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadPeople();
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _loadPeople() async {
    setState(() => _loading = true);
    final results = await Future.wait([
      _storage.getPeople(),
      _storage.getExpenses(),
      _storage.getGroupName(),
    ]);
    final people = results[0] as List<Person>;
    final expenses = results[1] as List<Expense>;
    final groupName = results[2] as String;
    if (mounted) {
      setState(() {
        _people = people;
        _expenses = expenses;
        _groupName = groupName;
        _balances = _storage.calculateBalances(people, expenses);
        _loading = false;
      });
    }
  }

  double _totalPaidBy(Person person) {
    return _expenses
        .where((expense) => expense.payerId == person.id)
        .fold(0.0, (total, expense) => total + expense.amount);
  }

  Future<void> _addPerson() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) return;

    final newPerson = Person(id: _uuid.v4(), name: name);
    final updated = [..._people, newPerson];
    await _storage.savePeople(updated);
    _nameController.clear();
    await _loadPeople();

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$name added')),
      );
    }
  }

  Future<void> _removePerson(Person person) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Remove person?'),
        content: Text(
          'Remove ${person.name}? Existing expenses that include them will keep the name for history.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Remove'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    final updated = _people.where((p) => p.id != person.id).toList();
    await _storage.savePeople(updated);
    await _loadPeople();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('People'),
        actions: [
          IconButton(
            onPressed: _loadPeople,
            tooltip: 'Refresh',
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.fromLTRB(18, 8, 18, 24),
              children: [
                Container(
                  padding: const EdgeInsets.all(19),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1A2A3D),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: const Color(0xFF26384A)),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'ACTIVE GROUP',
                              style: TextStyle(
                                color: Theme.of(context).colorScheme.primary,
                                fontSize: 11,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const SizedBox(height: 7),
                            Text(
                              _groupName,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              '${_people.length} group member${_people.length == 1 ? '' : 's'}  ·  ${_expenses.length} expenses',
                              style: const TextStyle(
                                color: Color(0xFFADB9CE),
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: const Color(0xFF00B99D).withOpacity(0.14),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Icon(Icons.groups_rounded,
                            color: Theme.of(context).colorScheme.primary),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 18),
                Container(
                  padding: const EdgeInsets.all(17),
                  decoration: BoxDecoration(
                    color: const Color(0xFF151F32),
                    borderRadius: BorderRadius.circular(19),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Expanded(
                            child: Text(
                              'Add participant',
                              style: TextStyle(
                                  fontSize: 17, fontWeight: FontWeight.w700),
                            ),
                          ),
                          Text(
                            'NEW MEMBER',
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.primary,
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: _nameController,
                        decoration: const InputDecoration(
                          prefixIcon: Icon(Icons.person_add_alt_1_rounded),
                          hintText: 'Enter a name',
                        ),
                        textCapitalization: TextCapitalization.words,
                        onSubmitted: (_) => _addPerson(),
                      ),
                      const SizedBox(height: 10),
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton.icon(
                          onPressed: _addPerson,
                          icon: const Icon(Icons.add_rounded),
                          label: const Text('Add member'),
                          style: FilledButton.styleFrom(
                            minimumSize: const Size.fromHeight(48),
                            backgroundColor: const Color(0xFF5ADBC1),
                            foregroundColor: const Color(0xFF071A20),
                            textStyle: const TextStyle(
                                fontWeight: FontWeight.w700),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 22),
                Row(
                  children: [
                    const Expanded(
                      child: Text(
                        'Roster & balance',
                        style: TextStyle(
                            fontSize: 17, fontWeight: FontWeight.w700),
                      ),
                    ),
                    Text(
                      '${_people.length} members',
                      style: const TextStyle(
                        color: Color(0xFF9AA8C0),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 11),
                if (_people.isEmpty)
                  Container(
                    padding: const EdgeInsets.all(22),
                    decoration: BoxDecoration(
                      color: const Color(0xFF151F32),
                      borderRadius: BorderRadius.circular(17),
                    ),
                    child: const Center(
                      child: Text(
                        'Add the first person to start your group.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Color(0xFF9AA8C0)),
                      ),
                    ),
                  )
                else
                  ..._people.map((person) {
                    final balance = _balances[person.id] ?? 0;
                    final settled = balance.abs() < 0.01;
                    final balanceColor = settled
                        ? const Color(0xFF8794AA)
                        : balance > 0
                            ? const Color(0xFF5ADBC1)
                            : const Color(0xFFFF8297);
                    return Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: const Color(0xFF151F32),
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              CircleAvatar(
                                radius: 23,
                                backgroundColor:
                                    const Color(0xFF26334A),
                                child: Text(
                                  person.name.isEmpty
                                      ? '?'
                                      : person.name[0].toUpperCase(),
                                  style: const TextStyle(
                                    color: Color(0xFF5ADBC1),
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  person.name,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                              IconButton(
                                onPressed: () => _removePerson(person),
                                tooltip: 'Remove ${person.name}',
                                icon: const Icon(Icons.delete_outline_rounded),
                                color: const Color(0xFF9AA8C0),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 10),
                            decoration: BoxDecoration(
                              color: const Color(0xFF101A2D),
                              borderRadius: BorderRadius.circular(13),
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  child: _personMetric(
                                    'TOTAL PAID',
                                    '\$${_totalPaidBy(person).toStringAsFixed(2)}',
                                    const Color(0xFFDCE4F6),
                                  ),
                                ),
                                Expanded(
                                  child: _personMetric(
                                    'NET BALANCE',
                                    settled
                                        ? '\$0.00 · settled'
                                        : '${balance > 0 ? '+' : '-'}\$${balance.abs().toStringAsFixed(2)} ${balance > 0 ? 'owed' : 'owes'}',
                                    balanceColor,
                                    alignEnd: true,
                                  ),
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
    );
  }

  Widget _personMetric(
    String label,
    String value,
    Color color, {
    bool alignEnd = false,
  }) {
    return Column(
      crossAxisAlignment:
          alignEnd ? CrossAxisAlignment.end : CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: Color(0xFF9AA8C0),
            fontSize: 9,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 3),
        Text(
          value,
          textAlign: alignEnd ? TextAlign.end : TextAlign.start,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(color: color, fontWeight: FontWeight.w700),
        ),
      ],
    );
  }
}
