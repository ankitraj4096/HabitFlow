import 'package:flutter/material.dart';
import 'package:flutter_heatmap_calendar/flutter_heatmap_calendar.dart';

class HeatMapPage extends StatelessWidget {
  const HeatMapPage({super.key});

  @override
  Widget build(BuildContext context) {
    return HeatMap(
      datasets:{
        DateTime(2025,01,01):3,
        DateTime(2025,01,02):7,
        DateTime(2025,01,03):8,
      },
      size: 22,
      showText: false,
      scrollable: true,
      startDate:DateTime.now() ,
      endDate: DateTime.now().add(Duration(days:90)),
      colorMode:ColorMode.opacity,
      showColorTip: false,
      colorsets:{
        1:Color.fromARGB(0, 76, 175, 80),
        2:Color.fromARGB(20, 76, 175, 80),
        3:Color.fromARGB(40, 76, 175, 80),
        4:Color.fromARGB(60, 76, 175, 80),
        5:Color.fromARGB(80, 76, 175, 80),
        6:Color.fromARGB(100, 76, 175, 80),
        7:Color.fromARGB(120, 76, 175, 80),
        8:Color.fromARGB(140, 76, 175, 80),
        9:Color.fromARGB(160, 76, 175, 80),
        10:Color.fromARGB(180, 76, 175, 80),
      }
    );
  }
}