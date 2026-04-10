import 'package:flutter/material.dart';
import 'add_task_screen.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Nhắc Việc App',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: const HomeScreen(),
    );
  }
}

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Dữ liệu mẫu như trong ảnh của bạn
    final List<String> tasks = [
      "Bảo vệ bài tập lớn ứng dụng di động 18/12",
      "Đi chơi Noel 24/12",
      "Đá bóng với lớp IT 3 ngày 12/10"
    ];

    return Scaffold(
      appBar: AppBar(title: const Text("HÃY TẠO ỨNG DỤNG NHẮC VIỆC")),
      body: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: tasks.length,
        separatorBuilder: (context, index) => const Divider(),
        itemBuilder: (context, index) {
          return ListTile(
            title: Text(tasks[index], style: const TextStyle(fontSize: 16)),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const AddTaskScreen()),
          );
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}