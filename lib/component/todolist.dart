import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:hive/hive.dart';

class Todolist extends StatelessWidget {
  final String TaskName;
  final bool IsChecked;
  final Function(bool?)? onChanged;
  final Function(BuildContext)? Delete_Fun;
  final Function(BuildContext)? Update_Fun;

  const Todolist({
    super.key,
    required this.TaskName,
    required this.IsChecked,
    required this.onChanged,
    required this.Delete_Fun,
    required this.Update_Fun,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 20),
      child: Slidable(
        endActionPane: ActionPane(
          motion: const StretchMotion(),
          children: [
            SlidableAction(
              onPressed: Update_Fun,
              icon: Icons.edit,
              backgroundColor: Colors.blue,
            ),
            SlidableAction(
              onPressed: Delete_Fun,
              icon: Icons.delete,
              backgroundColor: Colors.red,
            ),
          ],
        ),
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 20),
          padding: const EdgeInsets.all(15),
          decoration: BoxDecoration(
            color: const Color.fromARGB(255, 96, 210, 102),
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: const Color.fromARGB(255, 39, 95, 41).withOpacity(0.5),
                offset: Offset(4, 4), 
                blurRadius: 10,
                spreadRadius: 2,
              )
            ],
          ),
          child: Row(
            children: [
              Checkbox(
                value: IsChecked,
                onChanged: onChanged,
                activeColor: const Color.fromARGB(255, 9, 125, 1),
              ),
              Expanded(
                child: Text(
                  TaskName,
                  style: TextStyle(
                    fontSize: 18,
                    decoration: IsChecked ? TextDecoration.lineThrough : null,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
