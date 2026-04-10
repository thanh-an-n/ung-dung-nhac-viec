import 'package:flutter/material.dart';

class AddTaskScreen extends StatefulWidget {
  const AddTaskScreen({super.key});

  @override
  State<AddTaskScreen> createState() => _AddTaskScreenState();
}

class _AddTaskScreenState extends State<AddTaskScreen> {
  bool _isReminderOn = true;
  String _selectedMethod = 'Nhắc bằng chuông';
  final TextEditingController _dateController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Thêm Công Việc")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. Tên công việc
            const Text("Tên công việc"),
            TextField(decoration: InputDecoration(border: OutlineInputBorder())),
            const SizedBox(height: 15),

            // 2. Thời gian (kèm icon lịch)
            const Text("Thời gian"),
            TextField(
              controller: _dateController,
              decoration: InputDecoration(
                border: OutlineInputBorder(),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.calendar_month),
                  onPressed: () async {
                    DateTime? pickedDate = await showDatePicker(
                      context: context,
                      initialDate: DateTime.now(),
                      firstDate: DateTime(2000),
                      lastDate: DateTime(2101),
                    );
                    if (pickedDate != null) {
                      setState(() {
                        _dateController.text = "${pickedDate.day}/${pickedDate.month}/${pickedDate.year}";
                      });
                    }
                  },
                ),
              ),
            ),
            const SizedBox(height: 15),

            // 3. Địa điểm
            const Text("Địa điểm"),
            TextField(decoration: InputDecoration(border: OutlineInputBorder())),
            const SizedBox(height: 15),

            // 4. Nhắc việc trước 1 ngày (Switch)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text("Nhắc việc trước 1 ngày"),
                Switch(
                  value: _isReminderOn,
                  onChanged: (value) => setState(() => _isReminderOn = value),
                ),
              ],
            ),
            const SizedBox(height: 15),

            // 5. Hình thức nhắc (Dropdown)
            DropdownButtonFormField<String>(
              value: _selectedMethod,
              decoration: const InputDecoration(border: OutlineInputBorder()),
              items: ['Nhắc bằng chuông', 'Nhắc bằng email', 'Nhắc bằng thông báo']
                  .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                  .toList(),
              onChanged: (val) => setState(() => _selectedMethod = val!),
            ),
            const SizedBox(height: 30),

            // Nút Ghi lại
            Center(
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
                ),
                onPressed: () {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Đã lưu công việc!")),
                  );
                },
                child: const Text("Ghi lại công việc", style: TextStyle(fontSize: 16)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}