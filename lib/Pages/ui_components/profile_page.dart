import 'package:demo/component/heatmap.dart';
import 'package:flutter/material.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(97, 206, 205, 205),
      body: SafeArea(
        child: Center(
          child: Column(
            children: [
              const SizedBox(height: 20),

              //  Circular Profile Photo
              CircleAvatar(
                radius: 100,
                backgroundColor: Colors.grey[300],
                backgroundImage: AssetImage("assets/images/dp.jpg"), // replace with your image
                child: Icon(Icons.person, size: 100, color: Colors.grey[700]), // fallback
              ),

              const SizedBox(height: 20),

              // Function buttons row
              Container(
                height: 50,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly, // evenly spaces buttons
                  children: [
                    TextButton(onPressed: () {}, child: const Text("button1")),
                    TextButton(onPressed: () {}, child: const Text("button2")),
                    TextButton(onPressed: () {}, child: const Text("button3")),
                  ],
                ),
              ),

              const SizedBox(height: 50),

              // Heatmap
              const HeatMapPage(),
            ],
          ),
        ),
      ),
    );
  }
}
