// ecranul pentru lista de lucruri de facut
// aici poti adauga si sterge taskuri

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class TodoScreen extends StatefulWidget {
  const TodoScreen({super.key});

  @override
  State<TodoScreen> createState() => _TodoScreenState();
}

class _TodoScreenState extends State<TodoScreen> {
  // lista cu taskuri
  List<String> _spaces = [];
  String? _currentSpace;
  Map<String, List<Map<String, dynamic>>> _spaceTodos = {};
  final TextEditingController _controller = TextEditingController();
  static const String _spacesKey = 'todo_spaces';
  static const String _spaceTodosKey = 'todo_space_lists';
  final GlobalKey<AnimatedListState> _listKey = GlobalKey<AnimatedListState>();

  @override
  void initState() {
    super.initState();
    _loadSpaces();
  }

  Future<void> _loadSpaces() async {
    final prefs = await SharedPreferences.getInstance();
    final String? spacesJson = prefs.getString(_spacesKey);
    final String? todosJson = prefs.getString(_spaceTodosKey);
    setState(() {
      if (spacesJson != null) {
        _spaces = List<String>.from(jsonDecode(spacesJson));
      } else {
        _spaces = ['Default'];
      }
      if (_spaces.isEmpty) _spaces = ['Default'];
      _currentSpace = _spaces.first;
      if (todosJson != null) {
        final decoded = jsonDecode(todosJson) as Map<String, dynamic>;
        _spaceTodos = decoded.map((k, v) => MapEntry(k, List<Map<String, dynamic>>.from(v)));
      } else {
        _spaceTodos = {};
      }
      for (final space in _spaces) {
        _spaceTodos.putIfAbsent(space, () => []);
      }
    });
  }

  Future<void> _saveSpaces() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_spacesKey, jsonEncode(_spaces));
    await prefs.setString(_spaceTodosKey, jsonEncode(_spaceTodos));
  }

  // adauga un task nou
  void _addTodo(String text) {
    if (text.trim().isEmpty || _currentSpace == null) return;
    setState(() {
      _spaceTodos[_currentSpace]!.insert(0, {'text': text.trim(), 'done': false});
    });
    _controller.clear();
    _saveSpaces();
    _listKey.currentState?.insertItem(0, duration: const Duration(milliseconds: 500));
  }

  // sterge un task
  void _deleteTodo(int index) {
    if (_currentSpace == null) return;
    final removed = _spaceTodos[_currentSpace]!.removeAt(index);
    _saveSpaces();
    _listKey.currentState?.removeItem(
      index,
      (context, animation) => _buildTodoItem(context, removed, index, animation),
      duration: const Duration(milliseconds: 400),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final todos = _currentSpace == null ? [] : _spaceTodos[_currentSpace]!;
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Expanded(
              child: DropdownButton<String>(
                value: _currentSpace,
                isExpanded: true,
                underline: const SizedBox(),
                items: _spaces.map((space) {
                  return DropdownMenuItem(
                    value: space,
                    child: Row(
                      children: [
                        Expanded(child: Text(space)),
                        IconButton(
                          icon: const Icon(Icons.edit, size: 18),
                          onPressed: () => _renameSpace(space),
                          tooltip: l10n.rename,
                        ),
                        if (_spaces.length > 1)
                          IconButton(
                            icon: const Icon(Icons.delete, size: 18),
                            onPressed: () => _deleteSpace(space),
                            tooltip: l10n.delete,
                          ),
                      ],
                    ),
                  );
                }).toList(),
                onChanged: (val) {
                  setState(() {
                    _currentSpace = val;
                  });
                },
              ),
            ),
            IconButton(
              icon: const Icon(Icons.add),
              onPressed: _addSpace,
              tooltip: l10n.add,
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    decoration: InputDecoration(
                      hintText: l10n.addNewTask,
                      border: const OutlineInputBorder(),
                    ),
                    onSubmitted: _addTodo,
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: () => _addTodo(_controller.text),
                  child: const Icon(Icons.add),
                ),
              ],
            ),
          ),
          Expanded(
            child: todos.isEmpty
                ? Center(child: Text(l10n.noTasksYet))
                : AnimatedList(
                    key: _listKey,
                    initialItemCount: todos.length,
                    itemBuilder: (context, index, animation) {
                      final todo = todos[index];
                      return Dismissible(
                        key: Key(todo['text'] + index.toString()),
                        direction: DismissDirection.endToStart,
                        background: Container(
                          color: Colors.red,
                          alignment: Alignment.centerRight,
                          padding: const EdgeInsets.only(right: 16),
                          child: const Icon(Icons.delete, color: Colors.white),
                        ),
                        onDismissed: (_) => _deleteTodo(index),
                        child: _buildTodoItem(context, todo, index, animation),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  void _addSpace() async {
    final controller = TextEditingController();
    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(AppLocalizations.of(context)!.newSpace),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: InputDecoration(hintText: AppLocalizations.of(context)!.spaceName),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text(AppLocalizations.of(context)!.cancel)),
          TextButton(
            onPressed: () {
              final name = controller.text.trim();
              if (name.isNotEmpty && !_spaces.contains(name)) {
                Navigator.pop(context, name);
              }
            },
            child: Text(AppLocalizations.of(context)!.add),
          ),
        ],
      ),
    );
    if (result != null && result.isNotEmpty && !_spaces.contains(result)) {
      setState(() {
        _spaces.add(result);
        _spaceTodos[result] = [];
        _currentSpace = result;
      });
      _saveSpaces();
    }
  }

  void _renameSpace(String oldName) async {
    final controller = TextEditingController(text: oldName);
    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(AppLocalizations.of(context)!.renameSpace),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: InputDecoration(hintText: AppLocalizations.of(context)!.spaceName),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text(AppLocalizations.of(context)!.cancel)),
          TextButton(
            onPressed: () {
              final name = controller.text.trim();
              if (name.isNotEmpty && !_spaces.contains(name)) {
                Navigator.pop(context, name);
              }
            },
            child: Text(AppLocalizations.of(context)!.rename),
          ),
        ],
      ),
    );
    if (result != null && result.isNotEmpty && !_spaces.contains(result)) {
      setState(() {
        final idx = _spaces.indexOf(oldName);
        _spaces[idx] = result;
        _spaceTodos[result] = _spaceTodos.remove(oldName) ?? [];
        if (_currentSpace == oldName) _currentSpace = result;
      });
      _saveSpaces();
    }
  }

  void _deleteSpace(String name) async {
    if (_spaces.length == 1) return; // Don't delete last space
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(AppLocalizations.of(context)!.deleteSpace),
        content: Text(AppLocalizations.of(context)!.deleteSpaceConfirm(name)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: Text(AppLocalizations.of(context)!.cancel)),
          TextButton(onPressed: () => Navigator.pop(context, true), child: Text(AppLocalizations.of(context)!.delete, style: const TextStyle(color: Colors.red))),
        ],
      ),
    );
    if (confirm == true) {
      setState(() {
        _spaces.remove(name);
        _spaceTodos.remove(name);
        if (_currentSpace == name) {
          _currentSpace = _spaces.first;
        }
      });
      _saveSpaces();
    }
  }

  Widget _buildTodoItem(BuildContext context, Map<String, dynamic> todo, int index, Animation<double> animation) {
    return SlideTransition(
      position: Tween<Offset>(
        begin: const Offset(0, -0.5),
        end: Offset.zero,
      ).animate(CurvedAnimation(parent: animation, curve: Curves.easeOut)),
      child: FadeTransition(
        opacity: animation,
        child: ListTile(
          leading: Checkbox(
            value: todo['done'] ?? false,
            onChanged: (_) => _toggleTodo(index),
          ),
          title: Text(
            todo['text'],
            style: TextStyle(
              decoration: (todo['done'] ?? false)
                  ? TextDecoration.lineThrough
                  : null,
            ),
          ),
          trailing: IconButton(
            icon: const Icon(Icons.delete_outline),
            onPressed: () => _deleteTodo(index),
          ),
        ),
      ),
    );
  }

  void _toggleTodo(int index) {
    if (_currentSpace == null) return;
    setState(() {
      _spaceTodos[_currentSpace]![index]['done'] = !_spaceTodos[_currentSpace]![index]['done'];
    });
    _saveSpaces();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}

// clasa pentru un task
class TodoItem {
  final String title;
  bool isDone;

  TodoItem({required this.title, this.isDone = false});
}