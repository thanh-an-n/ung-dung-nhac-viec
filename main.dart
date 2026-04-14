import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  runApp(const TaskReminderApp());
}

class TaskReminderApp extends StatelessWidget {
  const TaskReminderApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Task Pro: Nhắc Việc',
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSwatch(primarySwatch: Colors.teal).copyWith(secondary: Colors.tealAccent),
        scaffoldBackgroundColor: const Color(0xFFF0F5F5),
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.teal,
          foregroundColor: Colors.white,
          centerTitle: true,
          elevation: 2,
          titleTextStyle: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
        ),
      ),
      home: const TaskListScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}

// 1. Lớp Model có thêm tính năng chuyển đổi JSON để lưu trữ
class TaskItem {
  String id;
  String name;
  DateTime dateTime;
  String location;
  bool isReminderOn;
  String reminderMethod;

  TaskItem({
    required this.id,
    required this.name,
    required this.dateTime,
    required this.location,
    required this.isReminderOn,
    required this.reminderMethod,
  });

  // Chuyển Object thành Map (JSON) để lưu vào máy
  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'dateTime': dateTime.toIso8601String(),
    'location': location,
    'isReminderOn': isReminderOn,
    'reminderMethod': reminderMethod,
  };

  // Đọc từ Map (JSON) tạo lại Object
  factory TaskItem.fromJson(Map<String, dynamic> json) => TaskItem(
    id: json['id'],
    name: json['name'],
    dateTime: DateTime.parse(json['dateTime']),
    location: json['location'],
    isReminderOn: json['isReminderOn'],
    reminderMethod: json['reminderMethod'],
  );
}

const List<String> reminderMethods = ['Thông báo', 'Email', 'Chuông'];

// 2. Màn hình chính
class TaskListScreen extends StatefulWidget {
  const TaskListScreen({super.key});

  @override
  State<TaskListScreen> createState() => _TaskListScreenState();
}

class _TaskListScreenState extends State<TaskListScreen> {
  List<TaskItem> tasks = [];
  bool isLoading = true; // Hiệu ứng tải dữ liệu

  @override
  void initState() {
    super.initState();
    _loadTasks(); // Tải dữ liệu khi mở app
  }

  // --- CÁC HÀM XỬ LÝ LƯU TRỮ DỮ LIỆU --- //

  Future<void> _loadTasks() async {
    final prefs = await SharedPreferences.getInstance();
    final String? tasksString = prefs.getString('saved_tasks');

    if (tasksString != null) {
      final List<dynamic> decodedList = jsonDecode(tasksString);
      setState(() {
        tasks = decodedList.map((item) => TaskItem.fromJson(item)).toList();
      });
    }
    _sortTasks();
    setState(() => isLoading = false);
  }

  Future<void> _saveTasksToDevice() async {
    final prefs = await SharedPreferences.getInstance();
    final String encodedData = jsonEncode(tasks.map((t) => t.toJson()).toList());
    await prefs.setString('saved_tasks', encodedData);
  }

  // ------------------------------------- //

  void _sortTasks() {
    tasks.sort((a, b) => a.dateTime.compareTo(b.dateTime));
  }

  void _addOrUpdateTask(TaskItem? task, {bool isAdding = false}) async {
    final TaskItem? updatedTask = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AddOrEditTaskScreen(taskToEdit: task, isAdding: isAdding),
      ),
    );

    if (updatedTask != null) {
      setState(() {
        if (isAdding) {
          tasks.add(updatedTask);
        } else {
          final index = tasks.indexWhere((t) => t.id == updatedTask.id);
          if (index != -1) tasks[index] = updatedTask;
        }
        _sortTasks();
      });
      _saveTasksToDevice(); // Lưu lại ngay sau khi thay đổi
    }
  }

  // Hộp thoại xác nhận xóa
  void _confirmDelete(TaskItem task) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Xác nhận xóa'),
        content: Text('Bạn có chắc muốn xóa công việc "${task.name}" không?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Hủy', style: TextStyle(color: Colors.grey))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () {
              setState(() => tasks.removeWhere((t) => t.id == task.id));
              _saveTasksToDevice(); // Cập nhật lại bộ nhớ
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Đã xóa công việc')));
            },
            child: const Text('Xóa', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Danh sách công việc')),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : tasks.isEmpty
          ? _buildEmptyState()
          : ListView.builder(
        padding: const EdgeInsets.only(top: 8, bottom: 80), // Cách dưới để không bị che bởi FAB
        itemCount: tasks.length,
        itemBuilder: (context, index) {
          final task = tasks[index];
          return TaskListItem(
            task: task,
            onEdit: () => _addOrUpdateTask(task, isAdding: false),
            onDelete: () => _confirmDelete(task),
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _addOrUpdateTask(null, isAdding: true),
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text('Thêm việc mới'),
        elevation: 4,
      ),
    );
  }

  // Giao diện khi chưa có công việc nào
  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.assignment_turned_in_outlined, size: 80, color: Colors.teal.withOpacity(0.5)),
          const SizedBox(height: 16),
          const Text("Bạn đã hoàn thành mọi việc!", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.teal)),
          const SizedBox(height: 8),
          const Text("Hãy bấm Thêm việc mới để bắt đầu.", style: TextStyle(color: Colors.grey)),
        ],
      ),
    );
  }
}

// 3. Widget Card hiển thị từng công việc
class TaskListItem extends StatelessWidget {
  final TaskItem task;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const TaskListItem({super.key, required this.task, required this.onEdit, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    final bool isPast = task.dateTime.isBefore(DateTime.now()); // Kiểm tra xem việc đã quá hạn chưa

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: Container(
          width: 55,
          height: 65,
          decoration: BoxDecoration(
              color: isPast ? Colors.grey : Colors.teal,
              borderRadius: BorderRadius.circular(10)
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(DateFormat('dd').format(task.dateTime), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 22, height: 1.1)),
              Text(DateFormat('MMM').format(task.dateTime).toUpperCase(), style: const TextStyle(color: Colors.white70, fontWeight: FontWeight.bold, fontSize: 11, height: 1.1)),
            ],
          ),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
                task.name,
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, decoration: isPast ? TextDecoration.lineThrough : null, color: isPast ? Colors.grey : Colors.black),
                maxLines: 2,
                overflow: TextOverflow.ellipsis
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                Icon(Icons.access_time_filled, size: 14, color: isPast ? Colors.grey : Colors.teal[300]),
                const SizedBox(width: 4),
                Text(DateFormat('HH:mm').format(task.dateTime), style: TextStyle(color: Colors.grey[700], fontSize: 13, fontWeight: FontWeight.w500)),
              ],
            ),
          ],
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 8.0),
          child: Row(
            children: [
              Icon(Icons.location_on, size: 14, color: isPast ? Colors.grey : Colors.red[300]),
              const SizedBox(width: 4),
              Expanded(child: Text(task.location, style: const TextStyle(fontSize: 13), maxLines: 1, overflow: TextOverflow.ellipsis)),
            ],
          ),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (task.isReminderOn) Icon(Icons.notifications_active, color: isPast ? Colors.grey : Colors.amber[600], size: 20),
            PopupMenuButton<String>(
              onSelected: (value) {
                if (value == 'edit') onEdit();
                if (value == 'delete') onDelete();
              },
              itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
                const PopupMenuItem<String>(value: 'edit', child: Row(children: [Icon(Icons.edit, color: Colors.blue), SizedBox(width: 8), Text('Chỉnh sửa')])),
                const PopupMenuItem<String>(value: 'delete', child: Row(children: [Icon(Icons.delete, color: Colors.red), SizedBox(width: 8), Text('Xóa')])),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// 4. Màn hình Thêm/Sửa công việc
class AddOrEditTaskScreen extends StatefulWidget {
  final TaskItem? taskToEdit;
  final bool isAdding;

  const AddOrEditTaskScreen({super.key, this.taskToEdit, this.isAdding = false});

  @override
  State<AddOrEditTaskScreen> createState() => _AddOrEditTaskScreenState();
}

class _AddOrEditTaskScreenState extends State<AddOrEditTaskScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _locationController;
  late DateTime _dateTime;
  late bool _isReminderOn;
  late String _selectedReminderMethod;

  @override
  void initState() {
    super.initState();
    final task = widget.taskToEdit;
    _nameController = TextEditingController(text: widget.isAdding ? '' : task!.name);
    _locationController = TextEditingController(text: widget.isAdding ? '' : task!.location);
    // Mặc định nến tạo mới thì gán giờ là giờ hiện tại cộng thêm 1 tiếng
    _dateTime = widget.isAdding ? DateTime.now().add(const Duration(hours: 1)) : task!.dateTime;
    _isReminderOn = widget.isAdding ? true : task!.isReminderOn;
    _selectedReminderMethod = widget.isAdding ? reminderMethods.first : task!.reminderMethod;
  }

  Future<void> _pickDateAndTime() async {
    final datePicked = await showDatePicker(
      context: context,
      initialDate: _dateTime,
      firstDate: DateTime.now().subtract(const Duration(days: 365)), // Cho phép chọn năm ngoái
      lastDate: DateTime(2101),
    );
    if (datePicked == null) return;

    final timePicked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_dateTime),
    );
    if (timePicked == null) return;

    setState(() {
      _dateTime = DateTime(datePicked.year, datePicked.month, datePicked.day, timePicked.hour, timePicked.minute);
    });
  }

  void _saveTask() {
    if (!_formKey.currentState!.validate()) return;

    final newTask = TaskItem(
      id: widget.isAdding ? DateTime.now().millisecondsSinceEpoch.toString() : widget.taskToEdit!.id,
      name: _nameController.text.trim(),
      dateTime: _dateTime,
      location: _locationController.text.trim(),
      isReminderOn: _isReminderOn,
      reminderMethod: _selectedReminderMethod,
    );

    Navigator.pop(context, newTask);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.isAdding ? 'Thêm công việc' : 'Sửa công việc')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Tên công việc', prefixIcon: Icon(Icons.task_alt)),
                validator: (value) => value!.trim().isEmpty ? 'Vui lòng nhập tên công việc' : null
            ),
            const SizedBox(height: 20),

            InkWell(
              onTap: _pickDateAndTime,
              borderRadius: BorderRadius.circular(8),
              child: InputDecorator(
                decoration: const InputDecoration(labelText: 'Thời gian', prefixIcon: Icon(Icons.calendar_month)),
                child: Text(DateFormat('dd/MM/yyyy - HH:mm').format(_dateTime), style: const TextStyle(fontSize: 16)),
              ),
            ),
            const SizedBox(height: 20),

            TextFormField(
                controller: _locationController,
                decoration: const InputDecoration(labelText: 'Địa điểm', prefixIcon: Icon(Icons.location_on_outlined)),
                validator: (value) => value!.trim().isEmpty ? 'Vui lòng nhập địa điểm' : null
            ),
            const SizedBox(height: 24),

            Card(
              elevation: 0,
              color: Colors.teal.withOpacity(0.08),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: Colors.teal.withOpacity(0.3))),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Row(
                          children: [
                            Icon(Icons.notifications_active, color: Colors.teal),
                            SizedBox(width: 8),
                            Text('Nhắc việc trước 1 ngày', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                          ],
                        ),
                        Switch(value: _isReminderOn, activeColor: Colors.teal, onChanged: (value) => setState(() => _isReminderOn = value)),
                      ],
                    ),
                    if (_isReminderOn) ...[
                      const Padding(
                        padding: EdgeInsets.only(top: 16.0, bottom: 8.0),
                        child: Text('Phương thức nhắc nhở:', style: TextStyle(fontWeight: FontWeight.w500)),
                      ),
                      Wrap(
                        spacing: 8,
                        children: reminderMethods.map((method) {
                          final isSelected = _selectedReminderMethod == method;
                          return ChoiceChip(
                            label: Text(method),
                            selected: isSelected,
                            onSelected: (selected) {
                              if (selected) setState(() => _selectedReminderMethod = method);
                            },
                            selectedColor: Colors.teal.withOpacity(0.3),
                            labelStyle: TextStyle(color: isSelected ? Colors.teal[900] : Colors.black87),
                          );
                        }).toList(),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 32),

            ElevatedButton.icon(
              onPressed: _saveTask,
              icon: const Icon(Icons.save),
              label: const Text('Lưu Công Việc'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                backgroundColor: Colors.teal,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                textStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
