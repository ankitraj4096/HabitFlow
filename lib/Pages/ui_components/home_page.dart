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
        title: "Add New Task",
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

  int get completedTasksCount {
    return tasklist.where((task) => task[0] == true).length;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFFF3E5F5), // Light purple
              Colors.white,
              Color(0xFFE3F2FD), // Light blue
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Header Section with Gradient
              Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFF7C4DFF), Color(0xFF448AFF)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.only(
                    bottomLeft: Radius.circular(30),
                    bottomRight: Radius.circular(30),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Color(0xFF7C4DFF).withOpacity(0.3),
                      blurRadius: 20,
                      offset: Offset(0, 10),
                    ),
                  ],
                ),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Task List',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 32,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              SizedBox(height: 8),
                              Text(
                                'Stay organized and productive 📝',
                                style: TextStyle(
                                  color: Colors.white70,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                          Container(
                            padding: EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(15),
                            ),
                            child: Icon(
                              Icons.checklist_rounded,
                              color: Colors.white,
                              size: 28,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 20),
                      // Progress Stats
                      Container(
                        padding: EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(15),
                          border: Border.all(
                            color: Colors.white.withOpacity(0.2),
                            width: 1,
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            _buildStatChip(
                              icon: Icons.format_list_bulleted,
                              label: 'Total',
                              value: tasklist.length.toString(),
                            ),
                            Container(
                              width: 1,
                              height: 30,
                              color: Colors.white.withOpacity(0.3),
                            ),
                            _buildStatChip(
                              icon: Icons.check_circle,
                              label: 'Completed',
                              value: completedTasksCount.toString(),
                            ),
                            Container(
                              width: 1,
                              height: 30,
                              color: Colors.white.withOpacity(0.3),
                            ),
                            _buildStatChip(
                              icon: Icons.pending_actions,
                              label: 'Pending',
                              value: (tasklist.length - completedTasksCount).toString(),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Task List
              Expanded(
                child: tasklist.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              padding: EdgeInsets.all(24),
                              decoration: BoxDecoration(
                                color: Color(0xFF7C4DFF).withOpacity(0.1),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                Icons.task_alt,
                                size: 64,
                                color: Color(0xFF7C4DFF),
                              ),
                            ),
                            SizedBox(height: 24),
                            Text(
                              'No tasks yet',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Colors.grey[700],
                              ),
                            ),
                            SizedBox(height: 8),
                            Text(
                              'Tap the + button to add your first task',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[500],
                              ),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: EdgeInsets.only(top: 20, bottom: 100),
                        itemCount: tasklist.length,
                        itemBuilder: (context, index) => Todolist(
                          IsChecked: tasklist[index][0],
                          TaskName: tasklist[index][1],
                          onChanged: (value) => CheckBoxChanged(value, index),
                          Delete_Fun: (context) => DeleteTask(index),
                          Update_Fun: (context) => UpdateTask(index),
                        ),
                      ),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF7C4DFF), Color(0xFF448AFF)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Color(0xFF7C4DFF).withOpacity(0.4),
              blurRadius: 15,
              offset: Offset(0, 8),
            ),
          ],
        ),
        child: FloatingActionButton(
          onPressed: NewTask,
          backgroundColor: Colors.transparent,
          elevation: 0,
          child: Icon(Icons.add, size: 32),
        ),
      ),
    );
  }

  Widget _buildStatChip({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Column(
      children: [
        Row(
          children: [
            Icon(icon, color: Colors.white, size: 18),
            SizedBox(width: 4),
            Text(
              value,
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            color: Colors.white70,
            fontSize: 11,
          ),
        ),
      ],
    );
  }
}