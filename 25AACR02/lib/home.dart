import 'package:barter_system/chatbot.dart';
import 'package:barter_system/history.dart';
import 'package:barter_system/login.dart';
import 'package:barter_system/profile.dart';
import 'package:barter_system/reviews.dart';
import 'package:barter_system/notification.dart';
import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';

class TodoList extends StatelessWidget {
  final DateTime selectedDate;
  final TextEditingController controller;
  final List<Map<String, dynamic>> todos;
  final VoidCallback onAdd;
  final Function(int index, bool? value) onToggle;
  final Function(int index) onDelete;

  const TodoList({
    super.key,
    required this.selectedDate,
    required this.controller,
    required this.todos,
    required this.onAdd,
    required this.onToggle,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const SizedBox(height: 12),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: controller,
                  decoration: const InputDecoration(
                    labelText: 'Add a to-do',
                    border: OutlineInputBorder(),
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.check),
                onPressed: onAdd,
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        todos.isEmpty
            ? const Center(child: Text("No tasks for today."))
            : ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: todos.length,
                itemBuilder: (context, index) {
                  final todo = todos[index];
                  return ListTile(
                    leading: Checkbox(
                      value: todo['done'],
                      onChanged: (value) => onToggle(index, value),
                    ),
                    title: Text(
                      todo['task'],
                      style: TextStyle(
                        decoration: todo['done']
                            ? TextDecoration.lineThrough
                            : TextDecoration.none,
                      ),
                    ),
                    trailing: IconButton(
                      icon: const Icon(Icons.delete, color: Color(0xFF56195B)),
                      onPressed: () => onDelete(index),
                    ),
                  );
                },
              ),
      ],
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  CalendarFormat _calendarFormat = CalendarFormat.month;
  final TextEditingController _todoController = TextEditingController();
  final TextEditingController _eventController = TextEditingController();
  final Map<DateTime, List<Map<String, dynamic>>> _todos = {};
  final Map<DateTime, List<String>> _events = {};

  DateTime _getDateKey(DateTime date) {
    return DateTime(date.year, date.month, date.day);
  }

  void _showAddEventDialog() {
    _eventController.clear();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Add Event"),
        content: TextField(
          controller: _eventController,
          decoration: const InputDecoration(labelText: "Event Title"),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () {
              if (_eventController.text.isEmpty) return;
              final dateKey = _getDateKey(_selectedDay ?? _focusedDay);
              setState(() {
                _events[dateKey] = [
                  ...(_events[dateKey] ?? []),
                  _eventController.text
                ];
              });
              Navigator.pop(context);
            },
            child: const Text("Add"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final dateKey = _getDateKey(_selectedDay ?? _focusedDay);
    final todaysTodos = _todos[dateKey] ?? [];
    final todaysEvents = _events[dateKey] ?? [];

    return Scaffold(
      drawer: Drawer(
        backgroundColor: const Color(0xFF123b53),
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
                child: Row(
              children: [
                /*IconButton(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  icon: Icon(Icons.arrow_back_ios_new_rounded),
                  color: Color.fromARGB(255, 255, 255, 255),
                ),*/
                Expanded(
                  child: Align(
                    alignment: Alignment.center,
                    child: Text(
                      'SkillSocket',
                      style: TextStyle(
                          color: Color.fromARGB(255, 255, 255, 255),
                          fontSize: 39),
                    ),
                  ),
                ),
              ],
            )),
            ListTile(
              leading: Icon(
                Icons.history,
                color: Color.fromARGB(255, 255, 255, 255),
              ),
              title: Text(
                'History',
                style: TextStyle(color: Color.fromARGB(255, 255, 255, 255)),
              ),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(context,
                    MaterialPageRoute(builder: (context) => History()));
              },
            ),
            Divider(color: Colors.white, thickness: 1),
            ListTile(
              leading: Icon(
                Icons.reviews,
                color: Color.fromARGB(255, 255, 255, 255),
              ),
              title: Text(
                'Reviews',
                style: TextStyle(color: Color.fromARGB(255, 255, 255, 255)),
              ),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(context,
                    MaterialPageRoute(builder: (context) => Reviews()));
              },
            ),
            Divider(color: Colors.white, thickness: 1),
            ListTile(
                leading: Icon(
                  Icons.logout,
                  color: Color.fromARGB(255, 255, 255, 255),
                ),
                title: Text(
                  'Sign Out',
                  style: TextStyle(color: Color.fromARGB(255, 255, 255, 255)),
                ),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(context,
                      MaterialPageRoute(builder: (context) => LoginScreen()));
                }),
            Divider(color: Colors.white, thickness: 1),
          ],
        ),
      ),
      appBar: AppBar(
        centerTitle: true,
        title: Text(
          'SkillSocket',
          style: TextStyle(
              fontSize: 20,
              // fontStyle: FontStyle.italic,
              color: Color.fromARGB(255, 255, 255, 255)),
        ),
        backgroundColor: Color(0xFF123b53),
        iconTheme:
            IconThemeData(color: const Color.fromARGB(255, 255, 255, 255)),
        actions: [
          IconButton(
              onPressed: () {
                Navigator.push(context,
                    MaterialPageRoute(builder: (context) => Notifications()));
              },
              icon: Icon(Icons.notifications)),
          IconButton(
              onPressed: () {
                Navigator.push(context,
                    MaterialPageRoute(builder: (context) => Profile()));
              },
              icon: Icon(Icons.person_rounded)),
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
            padding: const EdgeInsets.all(12.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: TableCalendar(
                    focusedDay: _focusedDay,
                    firstDay: DateTime.utc(1970, 1, 1),
                    lastDay: DateTime.utc(2100, 12, 31),
                    selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
                    onDaySelected: (selectedDay, focusedDay) {
                      setState(() {
                        _selectedDay = selectedDay;
                        _focusedDay = focusedDay;
                      });
                    },
                    eventLoader: (day) {
                      return _events[_getDateKey(day)] ?? [];
                    },
                    calendarFormat: _calendarFormat,
                    onFormatChanged: (format) {
                      setState(() {
                        _calendarFormat = format;
                      });
                    },
                    availableCalendarFormats: const {
                      CalendarFormat.month: 'Month',
                      CalendarFormat.week: 'Week',
                    },
                    calendarStyle: const CalendarStyle(
                      selectedDecoration: BoxDecoration(
                        color: Color.fromARGB(255, 178, 211, 240),
                        shape: BoxShape.circle,
                      ),
                      todayDecoration: BoxDecoration(
                        color: Color(0xFF123b53),
                        shape: BoxShape.circle,
                      ),
                      markerDecoration: BoxDecoration(
                        color: Colors.deepPurple,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "Events on ${dateKey.toLocal().toString().split(' ')[0]}",
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      IconButton(
                        icon: const Icon(Icons.add_circle,
                            color: Colors.deepPurple),
                        onPressed: _showAddEventDialog,
                      ),
                    ],
                  ),
                ),
                if (todaysEvents.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12.0),
                    child: Column(
                      children: todaysEvents.asMap().entries.map((entry) {
                        final index = entry.key;
                        final event = entry.value;
                        return ListTile(
                          leading: const Icon(Icons.event),
                          title: Text(event),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.edit,
                                    color: Colors.deepPurple),
                                onPressed: () {
                                  TextEditingController editController =
                                      TextEditingController(text: event);
                                  showDialog(
                                    context: context,
                                    builder: (context) => AlertDialog(
                                      title: const Text("Edit Event"),
                                      content:
                                          TextField(controller: editController),
                                      actions: [
                                        TextButton(
                                            onPressed: () =>
                                                Navigator.pop(context),
                                            child: const Text("Cancel")),
                                        TextButton(
                                          onPressed: () {
                                            setState(() {
                                              todaysEvents[index] =
                                                  editController.text;
                                              _events[dateKey] = [
                                                ...todaysEvents
                                              ];
                                            });
                                            Navigator.pop(context);
                                          },
                                          child: const Text("Save"),
                                        ),
                                      ],
                                    ),
                                  );
                                },
                              ),
                              IconButton(
                                icon:
                                    const Icon(Icons.delete, color: Colors.red),
                                onPressed: () {
                                  setState(() {
                                    todaysEvents.removeAt(index);
                                    _events[dateKey] = [...todaysEvents];
                                  });
                                },
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    ),
                  )
                else
                  const Padding(
                    padding: EdgeInsets.all(8.0),
                    child: Text("No events for today."),
                  ),
                TodoList(
                  selectedDate: dateKey,
                  controller: _todoController,
                  todos: todaysTodos,
                  onAdd: () {
                    if (_todoController.text.isNotEmpty) {
                      setState(() {
                        _todos[dateKey] = [
                          ...todaysTodos,
                          {"task": _todoController.text, "done": false}
                        ];
                        _todoController.clear();
                      });
                    }
                  },
                  onToggle: (index, value) {
                    setState(() {
                      final updatedTodos = [...todaysTodos];
                      updatedTodos[index] = {
                        ...updatedTodos[index],
                        'done': value,
                      };
                      _todos[dateKey] = updatedTodos;
                    });
                  },
                  onDelete: (index) {
                    setState(() {
                      final updatedTodos =
                          List<Map<String, dynamic>>.from(todaysTodos);
                      updatedTodos.removeAt(index);
                      _todos[dateKey] = updatedTodos;
                    });
                  },
                ),
                Padding(
                  padding: EdgeInsets.all(25.0),
                ),
              ],
            )),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(context,
              MaterialPageRoute(builder: (context) => ChatbotScreen()));
        },
        child: Icon(Icons.android),
      ),
    );
  }
}
