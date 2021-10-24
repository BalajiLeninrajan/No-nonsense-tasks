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

class _TaskViewState extends State<TaskView> with TickerProviderStateMixin {
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
            child: ListView.builder(
              itemBuilder: (_, index) {
                return Dismissible(
                  key: UniqueKey(),
                  child: _buildTask(_tasks[index]),
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
              itemCount: _tasks.length,
              reverse: true,
            ),
          ),
          _textComposer(),
        ],
      ),
    );
  }

  Widget _buildTask(String text) {
    return Container(
      margin: const EdgeInsets.only(right: 20.0),
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
    });
  }

  void _handleSubmitted(String task) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    _textController.clear();
    setState(() {
      _isComposing = false;
    });
    setState(() {
      _tasks.insert(0, task);
    });
    await prefs.setStringList('tasks', _tasks);
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

  void _deleteTask(int index) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      _tasks.removeAt(index);
    });
    await prefs.setStringList('tasks', _tasks);
  }
}
