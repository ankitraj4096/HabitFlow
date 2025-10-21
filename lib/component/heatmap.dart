import 'package:flutter/material.dart';
import 'package:flutter_heatmap_calendar/flutter_heatmap_calendar.dart';

class HeatMapPage extends StatelessWidget {
  final Map<String, int> completionData;

  const HeatMapPage({
    super.key,
    this.completionData = const {},
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
        print('Error parsing date: $dateStr');
      }
    });

    return HeatMapCalendar(
      defaultColor: Colors.grey.shade200,
      flexible: true,
      datasets: heatMapDataset,
      colorMode: ColorMode.opacity,
      showColorTip: false,
      size: 30,
      fontSize: 10,
      monthFontSize: 12,
      weekFontSize: 11,
      colorsets: {
        1: Colors.green.shade100,
        2: Colors.green.shade300,
        3: Colors.green.shade500,
        4: Colors.green.shade700,
        5: Colors.green.shade900,
      },
      onClick: (value) {
        final count = heatMapDataset[value] ?? 0;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              count > 0 
                  ? '$count task${count > 1 ? 's' : ''} completed on ${value.day}/${value.month}/${value.year}'
                  : 'No tasks completed on ${value.day}/${value.month}/${value.year}',
            ),
            duration: Duration(seconds: 2),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
      },
    );
  }
}
