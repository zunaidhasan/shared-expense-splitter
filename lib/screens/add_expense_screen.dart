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
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Expense'),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _people.isEmpty
              ? const Center(
                  child: Padding(
                    padding: EdgeInsets.all(24),
                    child: Text(
                      'Add at least one person in the People tab before creating an expense.',
                      textAlign: TextAlign.center,
                    ),
                  ),
                )
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        TextFormField(
                          controller: _titleController,
                          decoration: const InputDecoration(
                            labelText: 'Expense title',
                            hintText: 'e.g. Groceries, Rent, Utilities',
                          ),
                          textCapitalization: TextCapitalization.sentences,
                          validator: (v) {
                            if (v == null || v.trim().isEmpty) {
                              return 'Please enter a title';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _amountController,
                          decoration: const InputDecoration(
                            labelText: 'Amount',
                            hintText: '0.00',
                            prefixText: '\$ ',
                          ),
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                          validator: (v) {
                            if (v == null || v.trim().isEmpty) {
                              return 'Please enter an amount';
                            }
                            final value = double.tryParse(v.trim());
                            if (value == null || value <= 0) {
                              return 'Enter a valid positive number';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 24),
                        Text(
                          'Who paid?',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 8),
                        DropdownButtonFormField<String>(
                          value: _payerId,
                          decoration: const InputDecoration(
                            labelText: 'Payer',
                          ),
                          items: _people
                              .map(
                                (p) => DropdownMenuItem(
                                  value: p.id,
                                  child: Text(p.name),
                                ),
                              )
                              .toList(),
                          onChanged: (value) {
                            setState(() => _payerId = value);
                          },
                        ),
                        const SizedBox(height: 24),
                        Text(
                          'Who shares this expense?',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Equal split among selected people',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                        const SizedBox(height: 8),
                        ..._people.map((person) {
                          final selected =
                              _selectedParticipantIds.contains(person.id);
                          return CheckboxListTile(
                            title: Text(person.name),
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
                          );
                        }),
                        const SizedBox(height: 24),
                        FilledButton(
                          onPressed: _saving ? null : _saveExpense,
                          child: _saving
                              ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Text('Save Expense'),
                        ),
                      ],
                    ),
                  ),
                ),
    );
  }
}
