import 'package:demo/component/dialogbox.dart';
import 'package:demo/component/todolist.dart';
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';

class Homepage extends StatefulWidget {
  const Homepage({super.key});

  @override
  State<Homepage> createState() => _HomepageState();
}

class _HomepageState extends State<Homepage> {
  final mybox = Hive.box('mybox');
  List tasklist = [];
  final TextEditingController control = TextEditingController();

  @override
  void initState() {
    super.initState();
    if (mybox.get("ToDoList") == null) {
      tasklist = [];
      updateDatabase();
    } else {
      loadData();
    }
  }

  void loadData() {
    tasklist = mybox.get("ToDoList");
  }

  void updateDatabase() {
    mybox.put("ToDoList", tasklist);
  }

  void CheckBoxChanged(bool? value, int index) {
    setState(() {
      tasklist[index][0] = !tasklist[index][0];
    });
    updateDatabase();
  }

  void Add_Task() {
    if (control.text.isNotEmpty) {
      setState(() {
        tasklist.add([false, control.text]);
      });
      updateDatabase();
    }
    Navigator.of(context).pop();
    control.clear();
  }

  void NewTask() {
    showDialog(
      context: context,
      builder: (context) => TaskDialog(
        title: "Add Task",
        controller: control,
        buttonText: "Save",
        onConfirm: Add_Task,
      ),
    );
  }

  void DeleteTask(int index) {
    setState(() {
      tasklist.removeAt(index);
    });
    updateDatabase();
  }

  void UpdateTask(int index) {
    control.text = tasklist[index][1];
    showDialog(
      context: context,
      builder: (context) => TaskDialog(
        title: "Update Task",
        controller: control,
        buttonText: "Update",
        onConfirm: () {
          setState(() {
            tasklist[index][1] = control.text;
          });
          updateDatabase();
          Navigator.of(context).pop();
          control.clear();
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 161, 231, 161),
      appBar: AppBar(
        title:  Center(child: Text("Task List",style: TextStyle(color: const Color.fromARGB(255, 64, 63, 63),fontSize: 30,),)),
        elevation: 10,
        backgroundColor: const Color.fromARGB(255, 99, 238, 141),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: NewTask,
        backgroundColor: const Color.fromARGB(255, 96, 210, 102),
        child: const Icon(Icons.add,),
      ),
      body: ListView.builder(
        itemCount: tasklist.length,
        itemBuilder: (context, index) => Todolist(
          IsChecked: tasklist[index][0],
          TaskName: tasklist[index][1],
          onChanged: (value) => CheckBoxChanged(value, index),
          Delete_Fun: (context) => DeleteTask(index),
          Update_Fun: (context) => UpdateTask(index),
        ),
      ),
    );
  }
}
