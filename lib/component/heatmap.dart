import 'package:flutter/material.dart';
import 'package:flutter_heatmap_calendar/flutter_heatmap_calendar.dart';

class HeatMapPage extends StatelessWidget {
  const HeatMapPage({super.key});

  @override
  Widget build(BuildContext context) {
    return HeatMap(
      datasets: {
        // Sample data - replace with your actual data
        DateTime(2024, 10, 15): 3,
        DateTime(2024, 10, 16): 7,
        DateTime(2024, 10, 18): 5,
        DateTime(2024, 10, 20): 9,
        DateTime(2024, 10, 22): 4,
        DateTime(2024, 10, 25): 8,
        DateTime(2024, 11, 1): 6,
        DateTime(2024, 11, 3): 7,
        DateTime(2024, 11, 5): 3,
        DateTime(2024, 11, 8): 9,
        DateTime(2024, 11, 10): 5,
        DateTime(2024, 11, 12): 8,
        DateTime(2024, 11, 15): 4,
        DateTime(2024, 11, 18): 7,
        DateTime(2024, 11, 20): 6,
        DateTime(2024, 11, 23): 9,
        DateTime(2024, 12, 1): 5,
        DateTime(2024, 12, 3): 8,
        DateTime(2024, 12, 5): 4,
        DateTime(2024, 12, 8): 7,
        DateTime(2024, 12, 10): 9,
        DateTime(2024, 12, 12): 6,
        DateTime(2024, 12, 15): 3,
        DateTime(2024, 12, 18): 8,
        DateTime(2025, 1, 1): 7,
        DateTime(2025, 1, 3): 5,
        DateTime(2025, 1, 5): 9,
        DateTime(2025, 1, 8): 6,
        DateTime(2025, 1, 10): 8,
        DateTime(2025, 1, 12): 4,
        DateTime(2025, 1, 14): 7,
      },
      startDate: DateTime(2024, 10, 1),
      endDate: DateTime(2025, 1, 14),
      size: 24,
      fontSize: 10,
      showText: false,
      scrollable: true,
      colorMode: ColorMode.opacity,
      showColorTip: false,
      defaultColor: Color(0xFFF5F5F5),
      textColor: Colors.black45,
      colorsets: {
        1: Color(0xFF4CAF50).withOpacity(0.15),
        2: Color(0xFF4CAF50).withOpacity(0.25),
        3: Color(0xFF4CAF50).withOpacity(0.35),
        4: Color(0xFF4CAF50).withOpacity(0.45),
        5: Color(0xFF4CAF50).withOpacity(0.55),
        6: Color(0xFF4CAF50).withOpacity(0.65),
        7: Color(0xFF4CAF50).withOpacity(0.75),
        8: Color(0xFF4CAF50).withOpacity(0.85),
        9: Color(0xFF4CAF50).withOpacity(0.95),
        10: Color(0xFF4CAF50),
      },
      onClick: (value) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Date: ${value.toString().split(' ')[0]}'),
            duration: Duration(seconds: 1),
            behavior: SnackBarBehavior.floating,
            backgroundColor: Color(0xFF4CAF50),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
      },
    );
  }
}