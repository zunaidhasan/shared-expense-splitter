import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../models/person.dart';
import '../models/expense.dart';
import '../services/storage_service.dart';

class AddExpenseScreen extends StatefulWidget {
  const AddExpenseScreen({super.key});

  @override
  State<AddExpenseScreen> createState() => _AddExpenseScreenState();
}

class _AddExpenseScreenState extends State<AddExpenseScreen> {
  final _storage = StorageService();
  final _uuid = const Uuid();
  final _titleController = TextEditingController();
  final _amountController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  List<Person> _people = [];
  String? _payerId;
  final Set<String> _selectedParticipantIds = {};
  bool _loading = true;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _loadPeople();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  Future<void> _loadPeople() async {
    setState(() => _loading = true);
    final people = await _storage.getPeople();
    if (mounted) {
      setState(() {
        _people = people;
        _loading = false;
      });
    }
  }

  void _addQuickAmount(double amount) {
    final current = double.tryParse(_amountController.text.trim()) ?? 0;
    _amountController.text = (current + amount).toStringAsFixed(2);
    setState(() {});
  }

  Future<void> _saveExpense() async {
    if (!_formKey.currentState!.validate()) return;
    if (_payerId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select who paid')),
      );
      return;
    }
    if (_selectedParticipantIds.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Select at least one participant')),
      );
      return;
    }

    setState(() => _saving = true);

    final amount = double.parse(_amountController.text.trim());
    final expense = Expense(
      id: _uuid.v4(),
      title: _titleController.text.trim(),
      amount: amount,
      payerId: _payerId!,
      participantIds: _selectedParticipantIds.toList(),
      createdAt: DateTime.now(),
    );

    final expenses = await _storage.getExpenses();
    expenses.insert(0, expense);
    await _storage.saveExpenses(expenses);

    if (mounted) {
      setState(() => _saving = false);
      _titleController.clear();
      _amountController.clear();
      setState(() {
        _payerId = null;
        _selectedParticipantIds.clear();
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Expense saved')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final amount = double.tryParse(_amountController.text.trim()) ?? 0;
    final share = _selectedParticipantIds.isEmpty
        ? 0.0
        : amount / _selectedParticipantIds.length;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Add expense'),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _people.isEmpty
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(28),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.group_add_outlined,
                            color: Color(0xFF5ADBC1), size: 34),
                        const SizedBox(height: 14),
                        const Text(
                          'Add your group first',
                          style: TextStyle(
                              fontSize: 19, fontWeight: FontWeight.w700),
                        ),
                        const SizedBox(height: 6),
                        const Text(
                          'Add at least one person in the People tab before creating an expense.',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Color(0xFF9AA8C0)),
                        ),
                      ],
                    ),
                  ),
                )
              : Form(
                  key: _formKey,
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(18, 8, 18, 24),
                    children: [
                      Container(
                        padding: const EdgeInsets.fromLTRB(20, 18, 20, 18),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1A2A3D),
                          borderRadius: BorderRadius.circular(22),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Expanded(
                                  child: Text(
                                    'TOTAL EXPENSE',
                                    style: TextStyle(
                                      color: Color(0xFFB4C2D5),
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                                Icon(Icons.swap_horiz_rounded,
                                    color:
                                        Theme.of(context).colorScheme.primary,
                                    size: 18),
                                const SizedBox(width: 5),
                                const Text(
                                  'Equal split',
                                  style: TextStyle(
                                    color: Color(0xFF5ADBC1),
                                    fontWeight: FontWeight.w600,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                const Text(
                                  '\$',
                                  style: TextStyle(
                                    color: Color(0xFF5ADBC1),
                                    fontSize: 42,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: TextFormField(
                                    controller: _amountController,
                                    onChanged: (_) => setState(() {}),
                                    style: const TextStyle(
                                      fontSize: 38,
                                      fontWeight: FontWeight.w800,
                                      color: Color(0xFFE7ECFF),
                                    ),
                                    decoration: const InputDecoration(
                                      hintText: '0.00',
                                      filled: false,
                                      border: InputBorder.none,
                                      enabledBorder: InputBorder.none,
                                      focusedBorder: InputBorder.none,
                                      contentPadding: EdgeInsets.zero,
                                    ),
                                    keyboardType:
                                        const TextInputType.numberWithOptions(
                                            decimal: true),
                                    validator: (value) {
                                      final parsed =
                                          double.tryParse(value?.trim() ?? '');
                                      if (parsed == null || parsed <= 0) {
                                        return 'Enter a valid amount';
                                      }
                                      return null;
                                    },
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: [10.0, 25.0, 50.0, 100.0].map((value) {
                                return ActionChip(
                                  label: Text('+ \$${value.toInt()}'),
                                  backgroundColor: const Color(0xFF101A2D),
                                  side: BorderSide.none,
                                  labelStyle: TextStyle(
                                    color:
                                        Theme.of(context).colorScheme.primary,
                                    fontWeight: FontWeight.w600,
                                  ),
                                  onPressed: () => _addQuickAmount(value),
                                );
                              }).toList(),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.all(17),
                        decoration: BoxDecoration(
                          color: const Color(0xFF151F32),
                          borderRadius: BorderRadius.circular(19),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'TITLE & PURPOSE',
                              style: TextStyle(
                                color: Color(0xFFB4C2D5),
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 10),
                            TextFormField(
                              controller: _titleController,
                              decoration: const InputDecoration(
                                prefixIcon: Icon(Icons.receipt_long_outlined),
                                hintText: 'e.g. Groceries, rent, utilities',
                              ),
                              textCapitalization: TextCapitalization.sentences,
                              validator: (value) {
                                if (value == null || value.trim().isEmpty) {
                                  return 'Enter an expense title';
                                }
                                return null;
                              },
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
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
                                    'Who paid?',
                                    style: TextStyle(
                                        fontSize: 17,
                                        fontWeight: FontWeight.w700),
                                  ),
                                ),
                                Text(
                                  'PAYER',
                                  style: TextStyle(
                                    color: Theme.of(context).colorScheme.primary,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: _people.map((person) {
                                final selected = _payerId == person.id;
                                return ChoiceChip(
                                  label: Text(person.name),
                                  selected: selected,
                                  onSelected: (_) =>
                                      setState(() => _payerId = person.id),
                                  selectedColor: const Color(0xFF174843),
                                  backgroundColor: const Color(0xFF202B40),
                                  side: BorderSide.none,
                                  labelStyle: TextStyle(
                                    color: selected
                                        ? const Color(0xFF5ADBC1)
                                        : const Color(0xFFD6DEEF),
                                    fontWeight: FontWeight.w600,
                                  ),
                                );
                              }).toList(),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
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
                                    'Who shares the cost?',
                                    style: TextStyle(
                                        fontSize: 17,
                                        fontWeight: FontWeight.w700),
                                  ),
                                ),
                                Text(
                                  'Split equally',
                                  style: TextStyle(
                                    color: Theme.of(context).colorScheme.primary,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _selectedParticipantIds.isEmpty
                                  ? 'Choose group members'
                                  : '\$${share.toStringAsFixed(2)} per person',
                              style: const TextStyle(
                                  color: Color(0xFF9AA8C0), fontSize: 13),
                            ),
                            const SizedBox(height: 12),
                            Container(
                              margin: const EdgeInsets.only(bottom: 7),
                              decoration: BoxDecoration(
                                color: const Color(0xFF101A2D),
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: CheckboxListTile(
                                value: _selectedParticipantIds.length ==
                                    _people.length,
                                onChanged: (checked) {
                                  setState(() {
                                    if (checked == true) {
                                      _selectedParticipantIds
                                        ..clear()
                                        ..addAll(_people.map((person) => person.id));
                                    } else {
                                      _selectedParticipantIds.clear();
                                    }
                                  });
                                },
                                title: const Text(
                                  'Select all',
                                  style: TextStyle(fontWeight: FontWeight.w700),
                                ),
                                subtitle: Text(
                                  '${_selectedParticipantIds.length} of ${_people.length} members',
                                  style: const TextStyle(
                                      color: Color(0xFF9AA8C0), fontSize: 12),
                                ),
                                controlAffinity:
                                    ListTileControlAffinity.leading,
                                contentPadding:
                                    const EdgeInsets.symmetric(horizontal: 8),
                                activeColor:
                                    Theme.of(context).colorScheme.primary,
                              ),
                            ),
                            ..._people.map((person) {
                              final selected = _selectedParticipantIds
                                  .contains(person.id);
                              return Container(
                                margin: const EdgeInsets.only(bottom: 7),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF101A2D),
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                child: CheckboxListTile(
                                  value: selected,
                                  onChanged: (checked) {
                                    setState(() {
                                      if (checked == true) {
                                        _selectedParticipantIds.add(person.id);
                                      } else {
                                        _selectedParticipantIds.remove(person.id);
                                      }
                                    });
                                  },
                                  title: Text(
                                    person.name,
                                    style: const TextStyle(
                                        fontWeight: FontWeight.w600),
                                  ),
                                  secondary: CircleAvatar(
                                    radius: 17,
                                    backgroundColor: const Color(0xFF28344A),
                                    child: Text(
                                      person.name.isEmpty
                                          ? '?'
                                          : person.name[0].toUpperCase(),
                                      style: const TextStyle(
                                        color: Color(0xFFB8C5DB),
                                        fontSize: 12,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ),
                                  subtitle: selected
                                      ? Text(
                                          '\$${share.toStringAsFixed(2)} share',
                                          style: TextStyle(
                                            color: Theme.of(context)
                                                .colorScheme
                                                .primary,
                                            fontSize: 12,
                                          ),
                                        )
                                      : null,
                                  controlAffinity:
                                      ListTileControlAffinity.leading,
                                  contentPadding:
                                      const EdgeInsets.symmetric(horizontal: 8),
                                  activeColor:
                                      Theme.of(context).colorScheme.primary,
                                ),
                              );
                            }),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
      bottomNavigationBar: _people.isEmpty || _loading
          ? null
          : SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(18, 10, 18, 12),
                child: FilledButton.icon(
                  onPressed: _saving ? null : _saveExpense,
                  icon: _saving
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.check_circle_outline_rounded),
                  label: Text(
                    _saving
                        ? 'Saving...'
                        : 'Save expense  (\$${amount.toStringAsFixed(2)})',
                  ),
                  style: FilledButton.styleFrom(
                    minimumSize: const Size.fromHeight(54),
                    backgroundColor: const Color(0xFF00A98F),
                    foregroundColor: const Color(0xFF061921),
                    textStyle: const TextStyle(
                        fontSize: 15, fontWeight: FontWeight.w700),
                  ),
                ),
              ),
            ),
    );
  }
}
