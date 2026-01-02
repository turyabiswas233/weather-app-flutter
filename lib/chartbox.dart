import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:weatherapp/utils/const_style.dart';

class ChartBox extends StatelessWidget {
  final List<dynamic> hourlyForecastData;

  const ChartBox({super.key, required this.hourlyForecastData});

  @override
  Widget build(BuildContext context) {
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
        SizedBox(
          height: 160,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 15),
            itemCount: hourlyForecastData.length,
            itemBuilder: (context, index) {
              return _buildHourlyCard(hourlyForecastData[index]);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildHourlyCard(dynamic data) {
    DateTime time = DateTime.fromMillisecondsSinceEpoch(data['dt'] * 1000);
    String formattedTime = DateFormat('ha').format(time);
    String temp = "${data['temp'].toInt()}°";
    String iconCode = data['weather'][0]['icon'];

    return Container(
      width: 75,
      margin: const EdgeInsets.only(right: 5),
      decoration: BoxDecoration(
        color: Colors.white12,
        borderRadius: BorderRadius.circular(40),
        border: Border.all(color: ConstColors.fColor.withAlpha(50)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            formattedTime,
            style: const TextStyle(color: Colors.white70, fontSize: 13),
          ),
          const SizedBox(height: 8),
          Image.network(
            "https://openweathermap.org/img/wn/$iconCode@2x.png",
            width: 45,
            height: 45,
          ),
          const SizedBox(height: 8),
          Text(
            temp,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
