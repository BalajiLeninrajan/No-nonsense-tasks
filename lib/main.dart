import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  runApp(const NoNonsenseTasks());
}

const String title = 'No Nonsense Tasks';

class NoNonsenseTasks extends StatelessWidget {
  const NoNonsenseTasks({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      title: title,
      home: TaskView(),
    );
  }
}

class TaskView extends StatefulWidget {
  const TaskView({Key? key}) : super(key: key);

  @override
  _TaskViewState createState() => _TaskViewState();
}

class _TaskViewState extends State<TaskView> {
  final GlobalKey<AnimatedListState> listKey = GlobalKey<AnimatedListState>();
  List<String> _tasks = [];
  List<String> _completedTasks = [];
  final _textController = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  bool _isComposing = false;

  @override
  void initState() {
    _getTasks();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(title),
      ),
      body: Column(
        children: [
          Flexible(
              child: AnimatedList(
            key: listKey,
            initialItemCount: _tasks.length,
            itemBuilder: (_, index, animation) {
              return Dismissible(
                key: UniqueKey(),
                child: _buildTask(_tasks[index], animation),
                onDismissed: (_) => _deleteTask(index),
                background: Container(
                  color: Colors.red,
                  alignment: Alignment.centerRight,
                  child: const Icon(
                    Icons.delete,
                    color: Colors.white,
                  ),
                ),
              );
            },
            reverse: true,
          )),
          _textComposer(),
        ],
      ),
    );
  }

  Widget _buildTask(String text, animation) {
    return Container(
      margin: const EdgeInsets.only(right: 20.0),
      child: SizeTransition(
        sizeFactor: CurvedAnimation(
            parent: animation, curve: Curves.fastLinearToSlowEaseIn),
        child: Row(
          children: [
            IconButton(
              icon: _completedTasks.contains(text)
                  ? const Icon(Icons.check_box)
                  : const Icon(Icons.check_box_outline_blank),
              onPressed: () => _handleCompleted(text),
            ),
            Expanded(
              child: Text(
                text,
                style: Theme.of(context).textTheme.headline5,
              ),
            ),
            const Spacer(),
            const Icon(Icons.arrow_back)
          ],
        ),
      ),
    );
  }

  Widget _textComposer() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 10.0),
      child: Row(
        children: [
          Flexible(
            child: TextField(
              controller: _textController,
              decoration: const InputDecoration(hintText: 'Add a task'),
              onChanged: (text) {
                setState(() {
                  _isComposing = text.isNotEmpty;
                });
              },
              onSubmitted: _isComposing ? _handleSubmitted : null,
              focusNode: _focusNode,
            ),
          ),
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () =>
                _isComposing ? _handleSubmitted(_textController.text) : null,
          )
        ],
      ),
    );
  }

  void _getTasks() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      _tasks = prefs.getStringList('tasks') ?? [];
      _completedTasks = prefs.getStringList('completedTasks') ?? [];
      for (int i = 0; i < _tasks.length; i++) {
        listKey.currentState!
            .insertItem(0, duration: const Duration(milliseconds: 500));
      }
    });
  }

  void _handleSubmitted(String task) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    _textController.clear();
    setState(() {
      _isComposing = false;
    });
    if (_tasks.contains(task)) {
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: const Text('Task already exists'),
        action: SnackBarAction(
            label: 'Dismiss',
            onPressed: () {
              ScaffoldMessenger.of(context).hideCurrentSnackBar();
            }),
      ));
    } else {
      setState(() {
        listKey.currentState!
            .insertItem(0, duration: const Duration(milliseconds: 700));
        _tasks.insert(0, task);
      });
      await prefs.setStringList('tasks', _tasks);
    }
    _focusNode.requestFocus();
  }

  void _handleCompleted(String task) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      _completedTasks.contains(task)
          ? _completedTasks.remove(task)
          : _completedTasks.insert(0, task);
    });
    await prefs.setStringList('completedTasks', _completedTasks);
  }

  // ignore: unused_element
  void _deleteTask(int index) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      listKey.currentState!.removeItem(
          index, (_, animation) => _buildTask(_tasks[index], animation),
          duration: const Duration(milliseconds: 0));
      _tasks.removeAt(index);
    });
    await prefs.setStringList('tasks', _tasks);
  }
}
