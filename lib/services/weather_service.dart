import 'dart:convert';

import 'package:http/http.dart' as http;

import '../config.dart';

class WeatherService {
  WeatherService({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;

  Future<Map<String, dynamic>> fetchCurrentWeather(String city) async {
    final apiKey = Credentials.apiKey;
    final baseUrl = Credentials.baseUrl;
    final url = '$baseUrl/weather?q=$city&appid=$apiKey&units=metric';
    final response = await _client.get(Uri.parse(url));

    if (response.statusCode == 200) {
      return json.decode(response.body) as Map<String, dynamic>;
    }

    throw WeatherServiceException('City not found');
  }

  Future<List<dynamic>> fetchHourlyForecast(double lat, double lon) async {
    final apiKey = Credentials.apiKey;
    final baseUrl = Credentials.baseUrl;
    final url = '$baseUrl/onecall?lat=$lat&lon=$lon&appid=$apiKey&units=metric';
    final response = await _client.get(Uri.parse(url));

    if (response.statusCode == 200) {
      final data = json.decode(response.body) as Map<String, dynamic>;
      return (data['hourly'] as List<dynamic>).take(24).toList();
    }

    throw WeatherServiceException('Hourly forecast unavailable');
  }
}

class WeatherServiceException implements Exception {
  WeatherServiceException(this.message);

  final String message;

  @override
  String toString() => message;
}
