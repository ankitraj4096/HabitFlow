import 'package:flutter/material.dart';

class TaskDialog extends StatelessWidget {
  final String title;
  final TextEditingController controller;
  final String buttonText;
  final VoidCallback onConfirm;

  const TaskDialog({
    super.key,
    required this.title,
    required this.controller,
    required this.buttonText,
    required this.onConfirm,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: const Color.fromARGB(255, 110, 213, 151),
      title: Text(title),
      content: TextField(
        controller: controller,
        decoration: const InputDecoration(
          border: OutlineInputBorder(),
          hintText: "Enter task",
        ),
      ),
      actions: [
        ElevatedButton(
          onPressed: onConfirm,
          style: ElevatedButton.styleFrom(backgroundColor: const Color.fromARGB(255, 10, 228, 50)),
          child: Text(buttonText),
        ),
        ElevatedButton(
          onPressed: () {
            Navigator.of(context).pop();
            controller.clear();
          },
          style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
          child: const Text("Cancel"),
        ),
      ],
    );
  }
}
