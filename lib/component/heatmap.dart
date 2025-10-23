import 'package:demo/component/daily_task_show.dart';
import 'package:flutter/material.dart';
import 'package:flutter_heatmap_calendar/flutter_heatmap_calendar.dart';

class HeatMapPage extends StatelessWidget {
  final Map<String, int> completionData;
  final String? viewingUserID; 
  final String? viewingUsername; 

  const HeatMapPage({
    super.key,
    this.completionData = const {},
    this.viewingUserID,
    this.viewingUsername,
  });

  @override
  Widget build(BuildContext context) {
    // Convert String dates to DateTime for HeatMap
    Map<DateTime, int> heatMapDataset = {};
    
    completionData.forEach((dateStr, count) {
      try {
        final parts = dateStr.split('-');
        if (parts.length == 3) {
          final date = DateTime(
            int.parse(parts[0]),
            int.parse(parts[1]),
            int.parse(parts[2]),
          );
          heatMapDataset[date] = count;
        }
      } catch (e) {
        debugPrint('Error parsing date: $dateStr'); // ✅ FIXED - Changed from print() to debugPrint()
      }
    });

    return HeatMapCalendar(
      defaultColor: Colors.grey.shade200,
      flexible: true,
      datasets: heatMapDataset,
      colorMode: ColorMode.color,
      showColorTip: false,
      size: 30,
      fontSize: 10,
      monthFontSize: 12,
      weekFontSize: 11,
      colorsets: {
        1: Colors.green.shade100,
        2: Colors.green.shade200,
        3: Colors.green.shade300,
        4: Colors.green.shade400,
        5: Colors.green.shade500,
        6: Colors.green.shade600,
        7: Colors.green.shade700,
      },
      onClick: (value) {
        // Navigate to DailyCompletedTasksPage
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => DailyCompletedTasksPage(
              selectedDate: value,
              viewingUserID: viewingUserID,
              viewingUsername: viewingUsername,
            ),
          ),
        );
      },
    );
  }
}
