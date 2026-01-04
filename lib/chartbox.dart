import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart'; // Ensure fl_chart is in pubspec.yaml

class ChartBox extends StatelessWidget {
  final List<dynamic> hourlyForecastData;
  // Define a fixed width for each hour column to ensure the graph aligns
  final double itemWidth = 80.0;

  const ChartBox({super.key, required this.hourlyForecastData});

  @override
  Widget build(BuildContext context) {
    // Calculate the total width needed for all hours
    double totalWidth = itemWidth * hourlyForecastData.length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          child: Text(
            'Hourly Forecast',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        Container(
          height: 200,
          margin: const EdgeInsets.symmetric(horizontal: 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white.withAlpha(50)),
          ),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: SizedBox(
              width: totalWidth,
              child: Stack(
                children: [
                  // LAYER 1: The Graph (Background)
                  Positioned.fill(
                    top: 40, // Adjust to position line between icons and temp
                    bottom: 20,
                    child: IgnorePointer(
                      // Let scroll events pass to the list
                      child: LineChart(mainData()),
                    ),
                  ),
                  // LAYER 2: The UI Cards (Foreground)
                  Row(
                    children: hourlyForecastData
                        .map((data) => _buildHourlyCard(data))
                        .toList(),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  LineChartData mainData() {
    List<FlSpot> spots = [];
    for (int i = 0; i < hourlyForecastData.length; i++) {
      double temp = hourlyForecastData[i]['temp'].toDouble();
      // 'i' represents the index, which aligns with the center of each itemWidth
      spots.add(FlSpot(i.toDouble(), temp));
    }

    List<Color> list = [
      ...(() {
        final temps = hourlyForecastData
            .map((e) => (e['temp'] as num).toDouble())
            .toList();

        // Fallback gradient if no data
        if (temps.isEmpty) {
          return <Color>[Colors.lightBlueAccent, Colors.blue];
        }

        // Temperature -> Color using HSL (cold=blue, hot=red)
        Color tempToColor(double t) {
          const double minT = -10.0; // adjust to your expected range
          const double maxT = 40.0; // adjust to your expected range

          final double clamped = t.clamp(minT, maxT);
          final double tNorm = (clamped - minT) / (maxT - minT); // 0..1

          // Hue: 220° (blue) -> 0° (red)
          final double hue = lerpDouble(220.0, 0.0, tNorm)!;

          return HSLColor.fromAHSL(1.0, hue, 0.90, 0.80).toColor();
        }

        temps.sort();
        final double tMin = temps.first;
        final double tMax = temps.last;
        final double tMid = (tMin + tMax) / 2.0;
        final double tQ1 = tMin + (tMid - tMin) / 2.0;
        final double tQ3 = tMid + (tMax - tMid) / 2.0;

        // Build a smooth gradient (top -> bottom)
        return <Color>[
          tempToColor(tMax),
          tempToColor(tQ3),
          tempToColor(tMid),
          tempToColor(tQ1),
          tempToColor(tMin),
        ];
      })(),
    ];
    return LineChartData(
      gridData: const FlGridData(show: false),
      titlesData: const FlTitlesData(show: false),
      borderData: FlBorderData(show: false),
      // Set min/max to ensure the line starts/ends exactly at the card centers
      minX: 0,
      maxX: (hourlyForecastData.length - 1).toDouble(),
      minY: hourlyForecastData
              .map((e) => (e['temp'] as num).toDouble())
              .reduce((a, b) => a < b ? a : b) -
          5,
      maxY: hourlyForecastData
              .map((e) => (e['temp'] as num).toDouble())
              .reduce((a, b) => a > b ? a : b) + 5,
      lineBarsData: [
        LineChartBarData(
          spots: spots,
          isCurved: true,
          curveSmoothness: 0.1,
          color: Colors.white.withAlpha(150),
          barWidth: 2,
          dotData: const FlDotData(show: true), // Show dots at the temp points
          belowBarData: BarAreaData(
            show: true,
            gradient: LinearGradient(
              colors: [
                Colors.white.withAlpha(150),
                Colors.white10.withAlpha(50),
                Colors.transparent,
              ].toList(),
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
        ),
      ],
    );
  }

  // retrive weather icon based on icon code
  Icon _retriveIcon(String iconCode) {
    const double size = 30;
    const Color sunny = Colors.orangeAccent;
    const Color moon = Colors.blueGrey;
    const Color rainy = Colors.lightBlueAccent;
    const Color cloudy = Colors.white70;
    const Color snow = Color.fromARGB(255, 161, 209, 241);

    switch (iconCode) {
      case '01d': // clear sky (day)
        return const Icon(Icons.wb_sunny, color: sunny, size: size);
      case '01n': // clear sky (night)
        return const Icon(Icons.nights_stay, color: moon, size: size);

      case '02d': // few clouds (day)
        return const Icon(Icons.wb_cloudy, color: cloudy, size: size);
      case '02n': // few clouds (night)
        return const Icon(Icons.cloud, color: cloudy, size: size);

      case '03d': // scattered clouds
      case '03n':
        return const Icon(Icons.cloud, color: cloudy, size: size);
      case '04d': // broken clouds
      case '04n':
        return const Icon(Icons.cloud, color: cloudy, size: size);

      case '09d': // shower rain
      case '09n':
        return const Icon(Icons.grain, color: rainy, size: size);
      case '10d': // rain (day)
      case '10n': // rain (night)
        return const Icon(Icons.umbrella, color: rainy, size: size);

      case '11d': // thunderstorm
      case '11n':
        return const Icon(Icons.thunderstorm, color: rainy, size: size);
      case '13d': // snow
      case '13n':
        return const Icon(Icons.ac_unit, color: snow, size: size);

      case '50d': // mist
      case '50n':
        return const Icon(Icons.dehaze, color: cloudy, size: size);
      default:
        return const Icon(Icons.wb_sunny, color: sunny, size: size);
    }
  }

  Widget _buildHourlyCard(dynamic data) {
    DateTime time = DateTime.fromMillisecondsSinceEpoch(data['dt'] * 1000);
    String formattedTime = DateFormat('ha').format(time);
    String temp = "${data['temp']}°";
    String iconCode = data['weather'][0]['icon'];

    return SizedBox(
      width: itemWidth,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          Text(
            formattedTime,
            style: const TextStyle(color: Colors.white70, fontSize: 13),
          ),
          _retriveIcon(iconCode),
          // Adding spacing so the graph line has room to breathe between icon and temp
          const SizedBox(height: 30),
          Text(
            temp,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w300,
            ),
          ),
        ],
      ),
    );
  }
}
