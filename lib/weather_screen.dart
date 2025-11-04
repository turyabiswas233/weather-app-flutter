import 'dart:io';

import 'const_color.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter/material.dart';
import 'dart:convert';
import 'config.dart';
import 'package:http/http.dart' as http;

class WeatherScreen extends StatefulWidget {
  const WeatherScreen({super.key});

  @override
  _WeatherScreenState createState() => _WeatherScreenState();
}

class _WeatherScreenState extends State<WeatherScreen> {
  String cityName = '';
  Map<String, dynamic>? weatherData;
  bool isLoading = false;
  DateTime date = DateTime.now();


  String _addLeadPadding(int number) {
    return number < 10 ? '0$number' : '$number';
  }

  String _convertMilisecondToTime(int miliseconds) {
    final date = DateTime.fromMillisecondsSinceEpoch(miliseconds * 1000);
    return '${date.hour > 12 ? date.hour - 12 : date.hour}:${_addLeadPadding(date.minute)} ${date.hour > 12 ? 'PM' : 'AM'}';
  }

  String _convertPressure(int pressure) {
    // hPa to atm
    return (pressure / 1013.25).toStringAsFixed(4).toString();
  }

  String _degToDirection(int degree) {
    if (degree >= 0 && degree < 45) {
      return 'N';
    } else if (degree >= 45 && degree < 90) {
      return 'NE';
    } else if (degree >= 90 && degree < 135) {
      return 'East';
    } else if (degree >= 135 && degree < 180) {
      return 'SE';
    } else if (degree >= 180 && degree < 225) {
      return 'South';
    } else if (degree >= 225 && degree < 270) {
      return 'SW';
    } else if (degree >= 270 && degree < 315) {
      return 'West';
    } else {
      return 'NW';
    }
  }

  Widget _buildWindDirection() {
    String direction = _degToDirection(weatherData!['wind']['deg']);
    return Row(
      children: [
        Text(
          direction,
          style: TextStyle(
            fontSize: 14,
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        _windIcon(direction),
      ],
    );
  }

  Future<void> fetchWeather(String city) async {
    setState(() {
      isLoading = true;
    });

    debugPrint('city: $city');
    debugPrint('date: $date');

    final apiKey = Credentials.apiKey;
    final baseUrl = Credentials.baseUrl;
    final url = '$baseUrl/weather?q=$city&appid=$apiKey&units=metric';

    try {
      weatherData = null;
      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        weatherData = json.decode(response.body);
        // Fetch minute forecast data
        final lat = weatherData!['coord']['lat'];
        final lon = weatherData!['coord']['lon'];
        final oneCallUrl =
            '$baseUrl/onecall?lat=$lat&lon=$lon&exclude=current,minutely,daily,alerts&appid=$apiKey&units=metric';
        final oneCallResponse = await http.get(Uri.parse(oneCallUrl));

        if (oneCallResponse.statusCode == 200) {
          final oneCallData = json.decode(oneCallResponse.body);
          debugPrint("minute-forecast-debug: ${oneCallData['minutely']}");
        } else {
          debugPrint("Failed to load minute forecast data");
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: ConstColors.errorBg,
            content: Text(
              'City not found!',
              style: TextStyle(
                color: ConstColors.errorFg,
                fontWeight: FontWeight.bold,
                fontFamily: 'Inter',
              ),
            ),
          ),
        );
      }
      debugPrint("weather-debug: ${weatherData.toString()}");
    } catch (e) {
      debugPrint("error-debug: ${e.toString()}");
      setState(() {
        isLoading = false;
      });
      return Future.error('Failed to load weather data');
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<String> _determinePosition() async {
    LocationPermission permission = await Geolocator.checkPermission();

    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      permission = await Geolocator.requestPermission();

      setState(() {
        isLoading = false;
      });

      debugPrint('Debugging location access: ${permission.toString()}');
      // if network is not connected
      if (permission == LocationPermission.denied) {
        return Future.error('Location permissions are denied');
      } else if (permission == LocationPermission.deniedForever) {
        return Future.error(
            'Location permissions are permanently denied, we cannot request permissions.');
      }
    }

    Position position = await Geolocator.getCurrentPosition(
      locationSettings: LocationSettings(
        accuracy: LocationAccuracy.best,
        timeLimit: Duration(seconds: 10),
        distanceFilter: 10,
      ),
    );

    debugPrint('placemarks: ${position.toString()}');
    List<Placemark> placemarks = await placemarkFromCoordinates(
      position.latitude,
      position.longitude,
    );

    String? city = placemarks[0].locality;
    return city!;
  }

  Future<void> fetchWeatherByLocation() async {
    setState(() {
      isLoading = true;
      weatherData = null;
    });

    // ask permission for location and get lat-lng
    try {
      cityName = await _determinePosition();
      await fetchWeather(cityName);
    } catch (e) {
      debugPrint('error: $e');

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: ConstColors.errorBg,
          content: Text(
            'Location permission denied!',
            style: TextStyle(
              color: ConstColors.errorFg,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      );

      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ConstColors.bColor,
      drawerScrimColor: Colors.white,
      appBar: AppBar(
        title: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image(image: AssetImage('assets/logo.png'), height: 30),
            SizedBox(width: 10),
            Text(
              'Weather App',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w400,
              ),
            ),
          ],
        ),
        iconTheme: IconThemeData(color: ConstColors.textColor),
        backgroundColor: ConstColors.bColorTitle,
      ),
      body: RefreshIndicator(
        child: Container(
          padding: const EdgeInsets.all(5),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [ConstColors.grad1, ConstColors.grad2, ConstColors.grad3],
            ),
          ),
          child: Column(
            children: [
              TextField(
                cursorColor: ConstColors.boxColor,
                scrollPadding: EdgeInsets.all(10),
                decoration: InputDecoration(
                  filled: true,
                  fillColor: ConstColors.textColor,
                  hintText: 'Enter city name',
                  hintStyle: TextStyle(
                    color: ConstColors.boxColor.withAlpha(100),
                  ),
                  border: OutlineInputBorder(
                    borderSide: BorderSide(color: ConstColors.boxColor),
                    borderRadius: BorderRadius.circular(40),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: ConstColors.boxColor),
                    borderRadius: BorderRadius.circular(40),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.white),
                    borderRadius: BorderRadius.circular(40),
                  ),
                  suffixIcon: IconButton(
                    icon: Icon(Icons.search, color: ConstColors.grad1),
                    onPressed: () {
                      if (cityName.isNotEmpty) {
                        fetchWeather(cityName);
                      }
                    },
                  ),
                ),
                style: TextStyle(color: ConstColors.boxColor),
                onChanged: (value) {
                  setState(() {
                    cityName = value;
                  });
                },
                onSubmitted: (value) {
                  fetchWeather(cityName);
                },
              ),
              if (isLoading)
                CircularProgressIndicator(
                  color: ConstColors.loadingColor,
                  strokeWidth: 6,
                  padding: EdgeInsets.all(50),
                )
              else if (weatherData != null)
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Container(
                          padding: const EdgeInsets.only(
                            top: 5,
                            bottom: 5,
                            left: 16,
                            right: 16,
                          ),
                          margin: const EdgeInsets.only(bottom: 14),
                          decoration: BoxDecoration(
                            color: ConstColors.boxColor,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            spacing: 10,
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            mainAxisSize: MainAxisSize.max,
                            children: [
                              // Left part UI
                              Padding(
                                padding: const EdgeInsets.all(16),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      '${weatherData!['name']}, ${weatherData!['sys']['country']}',
                                      style: TextStyle(
                                        fontSize: 16,
                                        color: ConstColors.textColor,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),

                                    Text(
                                      '${weatherData!['main']['temp'].toInt()}°C',
                                      style: TextStyle(
                                        fontSize: 50,
                                        color: ConstColors.textColor,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),

                                    SizedBox(height: 10),
                                    Text(
                                      'Feels like ${weatherData!['main']['feels_like']}°C',
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: ConstColors.textColor,
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                              // Right part UI
                              Padding(
                                padding: const EdgeInsets.all(16),
                                child: Column(
                                  children: [
                                    Icon(
                                      _getWeatherIcon(
                                        weatherData!['weather'][0]['main'],
                                      ),
                                      color: ConstColors.textColor,
                                      size: 50,
                                    ),
                                    SizedBox(height: 10),
                                    Text(
                                      weatherData!['weather'][0]['description']
                                          .toString()
                                          .toUpperCase(),
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: ConstColors.textColor,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        Expanded(
                          child: GridView.count(
                            crossAxisCount: 2,
                            mainAxisSpacing: 10,
                            crossAxisSpacing: 10,
                            children: [
                              Container(
                                padding: const EdgeInsets.only(
                                  top: 5,
                                  bottom: 5,
                                  left: 16,
                                  right: 16,
                                ),
                                decoration: BoxDecoration(
                                  color: ConstColors.boxColor,
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Icon(
                                      Icons.air_rounded,
                                      color: ConstColors.textColor,
                                      size: 50,
                                    ),

                                    Row(
                                      spacing: 5,
                                      children: [
                                        Text(
                                          '${(weatherData!['wind']['speed'] * 3.6).toStringAsFixed(2)} km/h ',
                                          style: TextStyle(
                                            fontSize: 16,
                                            color: Colors.white,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),

                                        _buildWindDirection(),
                                      ],
                                    ),
                                  ],
                                ),
                              ),

                              Container(
                                padding: const EdgeInsets.only(
                                  top: 5,
                                  bottom: 5,
                                  left: 16,
                                  right: 16,
                                ),
                                decoration: BoxDecoration(
                                  color: ConstColors.boxColor,
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Icon(
                                      Icons.water_drop_rounded,
                                      color: ConstColors.textColor,
                                      size: 50,
                                    ),
                                    Text(
                                      'Humidity: ${weatherData!['main']['humidity']}%',
                                      style: TextStyle(
                                        fontSize: 16,
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                              Container(
                                padding: const EdgeInsets.only(
                                  top: 5,
                                  bottom: 5,
                                  left: 16,
                                  right: 16,
                                ),
                                decoration: BoxDecoration(
                                  color: ConstColors.boxColor,
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Icon(
                                      Icons.thunderstorm_rounded,
                                      color: ConstColors.textColor,
                                      size: 50,
                                    ),
                                    Text(
                                      'Chance of Rain: ${weatherData!['clouds']['all']}%',
                                      style: TextStyle(
                                        fontSize: 16,
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                              Container(
                                padding: const EdgeInsets.only(
                                  top: 5,
                                  bottom: 5,
                                  left: 16,
                                  right: 16,
                                ),
                                decoration: BoxDecoration(
                                  color: ConstColors.boxColor,
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Icon(
                                      Icons.thermostat_rounded,
                                      color: ConstColors.textColor,
                                      size: 50,
                                    ),
                                    Text(
                                      'Pressure: ${_convertPressure(weatherData!['main']['pressure'])} atm',
                                      style: TextStyle(
                                        fontSize: 16,
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                              Container(
                                padding: const EdgeInsets.only(
                                  top: 5,
                                  bottom: 5,
                                  left: 16,
                                  right: 16,
                                ),
                                decoration: BoxDecoration(
                                  color: ConstColors.boxColor,
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  spacing: 10,
                                  children: [
                                    Icon(
                                      _getSunRiseSet(
                                        weatherData!['sys']['sunrise'],
                                      ),
                                      color: ConstColors.textColor,
                                      size: 50,
                                    ),
                                    Text(
                                      _convertMilisecondToTime(
                                        weatherData!['sys']['sunrise'],
                                      ),
                                      style: TextStyle(
                                        fontSize: 16,
                                        color: Colors.white,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                              Container(
                                padding: const EdgeInsets.only(
                                  top: 5,
                                  bottom: 5,
                                  left: 16,
                                  right: 16,
                                ),
                                decoration: BoxDecoration(
                                  color: ConstColors.boxColor,
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  spacing: 10,
                                  children: [
                                    Icon(
                                      _getSunRiseSet(
                                        weatherData!['sys']['sunset'],
                                      ),
                                      color: ConstColors.textColor,
                                      size: 50,
                                    ),
                                    Text(
                                      _convertMilisecondToTime(
                                        weatherData!['sys']['sunset'],
                                      ),
                                      style: TextStyle(
                                        fontSize: 16,
                                        color: Colors.white,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              else
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(
                      top: 100,
                      left: 20,
                      right: 20,
                    ),
                    child: Text(
                      'Search for a city to get weather information.',
                      style: TextStyle(
                        fontSize: 28,
                        color: ConstColors.textColor.withAlpha(180),
                        fontWeight: FontWeight.w400,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
            ],
          ),
        ),
        onRefresh: () async {
          if (cityName.isNotEmpty) await fetchWeather(cityName);
        },
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: ConstColors.boxColor,
        hoverColor: ConstColors.boxColor.withAlpha(200),
        onPressed: fetchWeatherByLocation,
        tooltip: 'Get weather by location',
        child: Icon(
          Icons.location_on_rounded,
          color: ConstColors.grad3,
          size: 24,
        ),
      ),
    );
  }

  IconData _getSunRiseSet(int time) {
    final date = DateTime.fromMillisecondsSinceEpoch(time * 1000);
    return date.hour < 12 ? Icons.wb_sunny : Icons.nightlight_round;
  }

  Icon _windIcon(String direction) {
    switch (direction) {
      case 'N':
        return Icon(
          Icons.arrow_upward_rounded,
          color: ConstColors.textColor,
          size: 15,
        );
      case 'NE':
        return Icon(
          Icons.arrow_forward_rounded,
          color: ConstColors.textColor,
          size: 15,
        );
      case 'East':
        return Icon(
          Icons.arrow_forward_rounded,
          color: ConstColors.textColor,
          size: 15,
        );
      case 'SE':
        return Icon(
          Icons.arrow_forward_rounded,
          color: ConstColors.textColor,
          size: 15,
        );
      case 'South':
        return Icon(
          Icons.arrow_downward_rounded,
          color: ConstColors.textColor,
          size: 15,
        );
      case 'SW':
        return Icon(
          Icons.arrow_back_rounded,
          color: ConstColors.textColor,
          size: 15,
        );
      case 'West':
        return Icon(
          Icons.arrow_back_rounded,
          color: ConstColors.textColor,
          size: 15,
        );
      case 'NW':
        return Icon(
          Icons.arrow_back_rounded,
          color: ConstColors.textColor,
          size: 15,
        );
      default:
        return Icon(
          Icons.arrow_upward_rounded,
          color: ConstColors.textColor,
          size: 15,
        );
    }
  }

  IconData _getWeatherIcon(String weatherCondition) {
    switch (weatherCondition.toLowerCase()) {
      case 'clear':
        return Icons.wb_sunny_rounded;
      case 'clouds':
        return Icons.cloud_rounded;
      case 'thunderstorm':
        return Icons.flash_on_rounded;
      case 'snow':
        return Icons.cloudy_snowing;
      case 'drizzle':
      case 'rain':
        return Icons.beach_access_rounded;
      case 'atmosphere':
        return Icons.grain_outlined;
      default:
        return Icons.wb_cloudy_outlined;
    }
  }
}
