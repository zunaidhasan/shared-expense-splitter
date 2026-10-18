import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/person.dart';
import '../models/expense.dart';

class StorageService {
  static const _peopleKey = 'people';
  static const _expensesKey = 'expenses';
  static const _groupNameKey = 'group_name';

  Future<String> getGroupName() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_groupNameKey) ?? 'Apartment Expenses';
  }

  Future<void> setGroupName(String name) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_groupNameKey, name);
  }

  Future<List<Person>> getPeople() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString(_peopleKey);
    if (jsonString == null || jsonString.isEmpty) return [];
    final List<dynamic> list = jsonDecode(jsonString);
    return list.map((e) => Person.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<void> savePeople(List<Person> people) async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = jsonEncode(people.map((p) => p.toJson()).toList());
    await prefs.setString(_peopleKey, jsonString);
  }

  Future<List<Expense>> getExpenses() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString(_expensesKey);
    if (jsonString == null || jsonString.isEmpty) return [];
    final List<dynamic> list = jsonDecode(jsonString);
    return list
        .map((e) => Expense.fromJson(e as Map<String, dynamic>))
        .toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  Future<void> saveExpenses(List<Expense> expenses) async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = jsonEncode(expenses.map((e) => e.toJson()).toList());
    await prefs.setString(_expensesKey, jsonString);
  }

  /// Calculate balance for each person.
  /// Positive = others owe them, Negative = they owe the group.
  Map<String, double> calculateBalances(
    List<Person> people,
    List<Expense> expenses,
  ) {
    final balances = <String, double>{};
    for (final person in people) {
      balances[person.id] = 0.0;
    }

    for (final expense in expenses) {
      if (expense.participantIds.isEmpty) continue;
      final share = expense.sharePerPerson;

      // Creditor (payer) gets the full amount back in theory
      if (balances.containsKey(expense.payerId)) {
        balances[expense.payerId] =
            (balances[expense.payerId] ?? 0) + expense.amount;
      }

      // Each participant (including payer if they shared) is charged their share
      for (final pid in expense.participantIds) {
        if (balances.containsKey(pid)) {
          balances[pid] = (balances[pid] ?? 0) - share;
        }
      }
    }

    return balances;
  }
}
