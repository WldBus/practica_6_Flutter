import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const NotesApp());
}

class NotesApp extends StatefulWidget {
  const NotesApp({super.key});

  @override
  State<NotesApp> createState() => _NotesAppState();
}

class _NotesAppState extends State<NotesApp> {
  ThemeMode _themeMode = ThemeMode.system;
  Map<String, String>? _userData;

  @override
  void initState() {
    super.initState();
    _loadTheme();
    _loadUserData();
  }

  Future<void> _loadTheme() async {
    final prefs = await SharedPreferences.getInstance();
    final theme = prefs.getString('theme') ?? 'system';
    setState(() {
      _themeMode = {
        'light': ThemeMode.light,
        'dark': ThemeMode.dark,
        'system': ThemeMode.system,
      }[theme] ?? ThemeMode.system;
    });
  }

  Future<void> _loadUserData() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _userData = {
        'lastName': prefs.getString('lastName') ?? '',
        'firstName': prefs.getString('firstName') ?? '',
        'middleName': prefs.getString('middleName') ?? '',
      };
    });
  }

  Future<void> _toggleTheme() async {
    ThemeMode newMode;
    String modeString;

    switch (_themeMode) {
      case ThemeMode.system:
        newMode = ThemeMode.light;
        modeString = 'light';
        break;
      case ThemeMode.light:
        newMode = ThemeMode.dark;
        modeString = 'dark';
        break;
      case ThemeMode.dark:
        newMode = ThemeMode.system;
        modeString = 'system';
        break;
    }

    setState(() {
      _themeMode = newMode;
    });

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('theme', modeString);
  }

  Future<void> _updateUserData(Map<String, String> newData) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('lastName', newData['lastName'] ?? '');
    await prefs.setString('firstName', newData['firstName'] ?? '');
    await prefs.setString('middleName', newData['middleName'] ?? '');
    await _loadUserData();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Заметки',
      theme: ThemeData.light(),
      darkTheme: ThemeData.dark(),
      themeMode: _themeMode,
      debugShowCheckedModeBanner: false,
      home: NotesListScreen(
        onToggleTheme: _toggleTheme,
        themeMode: _themeMode,
        userData: _userData,
        onUpdateUserData: _updateUserData,
      ),
    );
  }
}

class NotesListScreen extends StatefulWidget {
  final VoidCallback onToggleTheme;
  final ThemeMode themeMode;
  final Map<String, String>? userData;
  final Function(Map<String, String>) onUpdateUserData;

  const NotesListScreen({
    required this.onToggleTheme,
    required this.themeMode,
    required this.onUpdateUserData,
    this.userData,
    Key? key,
  }) : super(key: key);

  @override
  _NotesListScreenState createState() => _NotesListScreenState();
}

class _NotesListScreenState extends State<NotesListScreen> {
  List<Map<String, dynamic>> notes = [];
  String searchQuery = '';
  final TextEditingController searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadNotes();
  }

  Future<void> _saveNotes() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('notes', jsonEncode(notes));
  }

  Future<void> _loadNotes() async {
    final prefs = await SharedPreferences.getInstance();
    final notesString = prefs.getString('notes');
    if (notesString != null && notesString.isNotEmpty) {
      final List<dynamic> decoded = jsonDecode(notesString);
      setState(() {
        notes = decoded.map((item) => Map<String, dynamic>.from(item)).toList();
      });
    }
  }

  Future<Map<String, String>> _getUserData() async {
    final prefs = await SharedPreferences.getInstance();
    return {
      'lastName': prefs.getString('lastName') ?? '',
      'firstName': prefs.getString('firstName') ?? '',
      'middleName': prefs.getString('middleName') ?? '',
    };
  }

  List<Map<String, dynamic>> get filteredNotes {
    if (searchQuery.isEmpty) return notes;
    return notes
        .where((note) =>
            note['title'].toString().toLowerCase().contains(searchQuery.toLowerCase()))
        .toList();
  }

  void addNote(Map<String, dynamic> note) {
    setState(() {
      notes.add(note);
    });
    _saveNotes();
  }

  void updateNote(int index, Map<String, dynamic> updatedNote) {
    setState(() {
      notes[index] = updatedNote;
    });
    _saveNotes();
  }

  void removeNote(int index) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Удалить заметку?'),
        content: const Text('Вы уверены, что хотите удалить эту заметку?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context), child: const Text('Отмена')),
          TextButton(
              onPressed: () {
                Navigator.pop(context);
                setState(() {
                  notes.removeAt(index);
                });
                _saveNotes();
              },
              child: const Text('Удалить')),
        ],
      ),
    );
  }

  Future<void> _showUserDataDialog() async {
    final lastNameController = TextEditingController(text: widget.userData?['lastName'] ?? '');
    final firstNameController = TextEditingController(text: widget.userData?['firstName'] ?? '');
    final middleNameController = TextEditingController(text: widget.userData?['middleName'] ?? '');

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Ваши данные'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: lastNameController,
              decoration: const InputDecoration(labelText: 'Фамилия'),
            ),
            TextField(
              controller: firstNameController,
              decoration: const InputDecoration(labelText: 'Имя'),
            ),
            TextField(
              controller: middleNameController,
              decoration: const InputDecoration(labelText: 'Отчество'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Отмена'),
          ),
          TextButton(
            onPressed: () {
              widget.onUpdateUserData({
                'lastName': lastNameController.text,
                'firstName': firstNameController.text,
                'middleName': middleNameController.text,
              });
              Navigator.pop(context);
            },
            child: const Text('Сохранить'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    IconData icon;
    switch (widget.themeMode) {
      case ThemeMode.light:
        icon = Icons.light_mode;
        break;
      case ThemeMode.dark:
        icon = Icons.dark_mode;
        break;
      default:
        icon = Icons.brightness_auto;
        break;
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Мои заметки'),
        actions: [
          IconButton(
            icon: const Icon(Icons.person),
            tooltip: 'Мои данные',
            onPressed: _showUserDataDialog,
          ),
          IconButton(
            icon: Icon(icon),
            tooltip: 'Сменить тему',
            onPressed: widget.onToggleTheme,
          ),
        ],
      ),
      body: Column(
        children: [
          if (widget.userData != null && 
              (widget.userData!['lastName']?.isNotEmpty ?? false) &&
              (widget.userData!['firstName']?.isNotEmpty ?? false))
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text(
                'Пользователь: ${widget.userData!['lastName']} ${widget.userData!['firstName']} ${widget.userData!['middleName']}',
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: TextField(
              controller: searchController,
              decoration: InputDecoration(
                hintText: 'Поиск по заголовку...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          setState(() {
                            searchQuery = '';
                            searchController.clear();
                          });
                        },
                      )
                    : null,
              ),
              onChanged: (value) {
                setState(() {
                  searchQuery = value;
                });
              },
            ),
          ),
          Expanded(
            child: filteredNotes.isEmpty
                ? const Center(child: Text('Нет заметок'))
                : ListView.builder(
                    itemCount: filteredNotes.length,
                    itemBuilder: (context, index) {
                      final note = filteredNotes[index];
                      final originalIndex = notes.indexOf(note);
                      return FutureBuilder(
                        future: _getUserData(),
                        builder: (context, snapshot) {
                          String userName = '';
                          if (snapshot.hasData && snapshot.data != null) {
                            final userData = snapshot.data!;
                            if ((userData['lastName']?.isNotEmpty ?? false) && 
                                (userData['firstName']?.isNotEmpty ?? false)) {
                              userName = '${userData['lastName']} ${userData['firstName']} ${userData['middleName']}';
                            }
                          }

                          return Card(
                            margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
                            child: ListTile(
                              title: Text(note['title'] ?? ''),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  if ((note['text'] ?? '').isNotEmpty)
                                    Text(
                                      note['text'],
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  if ((note['dueDate'] ?? '').isNotEmpty)
                                    Text('Дата реализации: ${note['dueDate']}'),
                                  Text('Добавлено: ${note['createdAt']}'),
                                  if ((note['additional'] ?? '').isNotEmpty)
                                    Text('Дополнительно: ${note['additional']}'),
                                  if (userName.isNotEmpty)
                                    Text('Автор: $userName'),
                                ],
                              ),
                              onTap: () async {
                                final result = await Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => CreateNoteScreen(
                                      note: note,
                                      index: originalIndex,
                                      userData: widget.userData,
                                    ),
                                  ),
                                );
                                if (result != null) {
                                  updateNote(originalIndex, result);
                                }
                              },
                              onLongPress: () => removeNote(originalIndex),
                            ),
                          );
                        },
                      );
                    },
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => CreateNoteScreen(userData: widget.userData),
            ),
          );
          if (result != null) {
            addNote(result);
          }
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}

class CreateNoteScreen extends StatefulWidget {
  final Map<String, dynamic>? note;
  final int? index;
  final Map<String, String>? userData;

  const CreateNoteScreen({this.note, this.index, this.userData});

  @override
  _CreateNoteScreenState createState() => _CreateNoteScreenState();
}

class _CreateNoteScreenState extends State<CreateNoteScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController titleController = TextEditingController();
  final TextEditingController textController = TextEditingController();
  final TextEditingController dueDateController = TextEditingController();
  final TextEditingController additionalController = TextEditingController();
  DateTime? selectedDueDate;

  @override
  void initState() {
    super.initState();
    if (widget.note != null) {
      titleController.text = widget.note!['title'] ?? '';
      textController.text = widget.note!['text'] ?? '';
      dueDateController.text = widget.note!['dueDate'] ?? '';
      additionalController.text = widget.note!['additional'] ?? '';
    }
  }

  Future<void> _selectDueDate(BuildContext context) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: selectedDueDate ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(2030),
    );

    if (picked != null) {
      setState(() {
        selectedDueDate = picked;
        dueDateController.text = DateFormat('dd.MM.yyyy').format(picked);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.note != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(isEdit ? 'Редактировать заметку' : 'Создать заметку'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                controller: titleController,
                decoration: const InputDecoration(labelText: 'Заголовок'),
                validator: (value) =>
                    value == null || value.trim().isEmpty ? 'Заголовок обязателен' : null,
              ),
              TextFormField(
                controller: textController,
                decoration: const InputDecoration(labelText: 'Текст заметки'),
                maxLines: 3,
                validator: (value) =>
                    value == null || value.trim().isEmpty ? 'Введите текст заметки' : null,
              ),
              TextFormField(
                controller: dueDateController,
                readOnly: true,
                decoration: InputDecoration(
                  labelText: 'Дата реализации (необязательно)',
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.calendar_today),
                    onPressed: () => _selectDueDate(context),
                  ),
                ),
              ),
              TextFormField(
                controller: additionalController,
                decoration:
                    const InputDecoration(labelText: 'Дополнительные данные'),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () {
                  if (_formKey.currentState!.validate()) {
                    final now = DateFormat('dd.MM.yyyy HH:mm').format(DateTime.now());
                    
                    final newNote = {
                      'title': titleController.text,
                      'text': textController.text,
                      'createdAt': widget.note?['createdAt'] ?? now,
                      'dueDate': dueDateController.text,
                      'additional': additionalController.text,
                    };
                    Navigator.pop(context, newNote);
                  }
                },
                child: Text(isEdit ? 'Сохранить' : 'Добавить заметку'),
              )
            ],
          ),
        ),
      ),
    );
  }
}