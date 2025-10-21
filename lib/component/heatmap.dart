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
          // The count is passed directly. The widget uses this as a key.
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
      // THE FIX: Use ColorMode.color to select from your colorsets
      colorMode: ColorMode.color,
      showColorTip: false,
      size: 30,
      fontSize: 10,
      monthFontSize: 12,
      weekFontSize: 11,
      // Your color map is perfect for ColorMode.color
      colorsets: {
        1: Colors.green.shade100,
        2: Colors.green.shade200,
        3: Colors.green.shade300,
        4: Colors.green.shade400,
        5: Colors.green.shade500,
        6: Colors.green.shade600,
        7: Colors.green.shade700,
        8: Colors.green.shade800,
        9: Colors.green.shade900,
      },
      onClick: (value) {
        // Use the original count for the snackbar message
        final originalCount = completionData[
                '${value.year}-${value.month.toString().padLeft(2, '0')}-${value.day.toString().padLeft(2, '0')}'] ??
            0;

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              originalCount > 0
                  ? '$originalCount task${originalCount > 1 ? 's' : ''} completed on ${value.day}/${value.month}/${value.year}'
                  : 'No tasks completed on ${value.day}/${value.month}/${value.year}',
            ),
            duration: const Duration(seconds: 2),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
      },
    );
  }
}
