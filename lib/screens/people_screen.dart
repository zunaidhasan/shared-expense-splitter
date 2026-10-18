import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
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
    final people = await _storage.getPeople();
    if (mounted) {
      setState(() {
        _people = people;
        _loading = false;
      });
    }
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
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _nameController,
                          decoration: const InputDecoration(
                            labelText: 'Name',
                            hintText: 'Enter participant name',
                          ),
                          textCapitalization: TextCapitalization.words,
                          onSubmitted: (_) => _addPerson(),
                        ),
                      ),
                      const SizedBox(width: 12),
                      FilledButton(
                        onPressed: _addPerson,
                        child: const Text('Add'),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: _people.isEmpty
                      ? const Center(
                          child: Text(
                            'No participants yet.\nAdd the first person above.',
                            textAlign: TextAlign.center,
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          itemCount: _people.length,
                          itemBuilder: (context, index) {
                            final person = _people[index];
                            return Card(
                              margin: const EdgeInsets.only(bottom: 8),
                              child: ListTile(
                                leading: CircleAvatar(
                                  child: Text(
                                    person.name.isNotEmpty
                                        ? person.name[0].toUpperCase()
                                        : '?',
                                  ),
                                ),
                                title: Text(person.name),
                                trailing: IconButton(
                                  icon: const Icon(Icons.delete_outline),
                                  onPressed: () => _removePerson(person),
                                  tooltip: 'Remove',
                                ),
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
    );
  }
}
