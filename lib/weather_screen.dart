import 'dart:ui';

import 'package:google_fonts/google_fonts.dart';
import 'package:weatherapp/chartbox.dart';

import 'utils/const_style.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter/material.dart';
import 'dart:convert';
import 'config.dart';
import 'package:http/http.dart' as http;
import 'package:lottie/lottie.dart';

class WeatherScreen extends StatefulWidget {
  const WeatherScreen({super.key});

  @override
  _WeatherScreenState createState() => _WeatherScreenState();
}

class _WeatherScreenState extends State<WeatherScreen> {
  String cityName = '';
  Map<String, dynamic>? weatherData;
  List<dynamic> hourlyForecastData = [];

  bool isLoading = false;
  DateTime date = DateTime.now();
  double lon = 0;
  double lat = 0;

  String _addLeadPadding(int number) {
    return number < 10 ? '0$number' : '$number';
  }

  String _convertMilisecondToTime(int miliseconds) {
    final date = DateTime.fromMillisecondsSinceEpoch(miliseconds * 1000);
    return '${date.hour > 12 ? date.hour - 12 : date.hour}:${_addLeadPadding(date.minute)} ${date.hour > 12 ? 'PM' : 'AM'}';
  }

  String _convertPressure(int pressure) {
    // hPa to atm
    return (pressure * 0.750062).toStringAsFixed(0).toString();
  }

  String _degToDirection(int degree) {
    if (degree >= 0 && degree < 45) {
      return 'North';
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
        lat = weatherData!['coord']['lat'];
        lon = weatherData!['coord']['lon'];
        fetchHourlyData(lat, lon);
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

      // if network is not connected
      if (permission == LocationPermission.denied) {
        return Future.error('Location permissions are denied');
      } else if (permission == LocationPermission.deniedForever) {
        return Future.error(
          'Location permissions are permanently denied, we cannot request permissions.',
        );
      }
    }

    Position position = await Geolocator.getCurrentPosition(
      locationSettings: LocationSettings(
        accuracy: LocationAccuracy.best,
        timeLimit: Duration(seconds: 10),
        distanceFilter: 10,
      ),
    );

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

  Future<void> fetchHourlyData(double lat, double lon) async {
    String baseUrl = Credentials.baseUrl;
    String apiKey = Credentials.apiKey;

    try {
      final oneCallUrl =
          '$baseUrl/onecall?lat=${lat}&lon=${lon}&appid=$apiKey&units=metric';
      final response = await http.get(Uri.parse(oneCallUrl));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          // Taking the first 24 hours of data
          hourlyForecastData = data['hourly'].take(24).toList();
          isLoading = false;
        });
      }
    } catch (e) {
      debugPrint("Error: $e");
      setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ConstColors.grad3,
      appBar: AppBar(
        title: Row(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            Image(
              image: ResizeImage(
                AssetImage('assets/logo.png'),
                width: 28,
                height: 28,
                allowUpscaling: true,
              ),
            ),
            SizedBox(width: 10),
            Text(
              'Weather App',
              style: TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
        iconTheme: IconThemeData(color: ConstColors.fColor),
        // backgroundColor: ConstColors.grad3,
      ),
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [ConstColors.grad1, ConstColors.grad2, ConstColors.grad3],
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          spacing: 10,
          children: [
            SizedBox(height: 10),
            Padding(
              padding: EdgeInsetsGeometry.all(10),
              child: TextField(
                cursorColor: ConstColors.fColor,
                scrollPadding: EdgeInsets.all(10),
                decoration: InputDecoration(
                  filled: true,
                  fillColor: ConstColors.grad3.withAlpha(50),
                  hintText: 'Enter city name',
                  hintStyle: TextStyle(
                    color: ConstColors.fColor.withAlpha(100),
                  ),
                  border: OutlineInputBorder(
                    borderSide: BorderSide(
                      color: ConstColors.bColor.withAlpha(20),
                    ),
                    borderRadius: BorderRadius.circular(40),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(
                      color: ConstColors.bColor.withAlpha(40),
                    ),
                    borderRadius: BorderRadius.circular(40),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: ConstColors.fColor),
                    borderRadius: BorderRadius.circular(40),
                  ),
                  suffixIcon: IconButton(
                    icon: Icon(
                      Icons.search,
                      color: ConstColors.fColor,
                      size: 28,
                    ),
                    onPressed: () {
                      if (cityName.isNotEmpty) {
                        fetchWeather(cityName);
                      }
                    },
                  ),
                ),
                style: TextStyle(color: ConstColors.fColor, fontSize: 14),
                onChanged: (value) {
                  setState(() {
                    cityName = value;
                  });
                },
                onSubmitted: (value) {
                  fetchWeather(cityName);
                },
              ),
            ),
            if (isLoading)
              RefreshProgressIndicator(
                color: ConstColors.loadingColor,
                strokeWidth: 3,
              ),
            if (weatherData != null)
              SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                // Adds a smooth bounce effect on iOS/Android
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      margin: const EdgeInsets.only(bottom: 14),
                      child: Column(
                        children: [
                          // City and Temperature Section
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Text(
                                '${weatherData!['name']}, ${weatherData!['sys']['country']}',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: ConstColors.fColor,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              Text(
                                '${weatherData!['main']['temp'].toInt()}°C',
                                style: TextStyle(
                                  fontSize: 48,
                                  color: ConstColors.fColor,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              Text(
                                'Feeling ${weatherData!['main']['feels_like']}°C',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: ConstColors.fColor,
                                ),
                              ),
                            ],
                          ),

                          // Icon and "See More" Button Section
                          Padding(
                            padding: const EdgeInsets.all(10),
                            child: Column(
                              children: [
                                _getWeatherIcon(
                                  weatherData!['weather'][0]['main'],
                                ),
                                Text(
                                  weatherData!['weather'][0]['description']
                                      .toString()
                                      .toUpperCase(),
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: ConstColors.fColor,
                                  ),
                                ),
                                const SizedBox(height: 10),
                                ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: ConstColors.bColor,
                                    shadowColor: ConstColors.grad3,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                  ),
                                  onPressed: () => _showDetailsGrid(context),
                                  child: Container(
                                    width: double.infinity,
                                    height: 48,
                                    alignment: Alignment.center,
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Text(
                                          'See more',
                                          style: TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w500,
                                            color: ConstColors.grad1,
                                          ),
                                        ),
                                        const SizedBox(width: 10),
                                        Icon(
                                          Icons.keyboard_arrow_right,
                                          color: ConstColors.grad1,
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          if (hourlyForecastData.isNotEmpty)
                            ChartBox(hourlyForecastData: hourlyForecastData),
                        ],
                      ),
                    ),
                  ],
                ),
              )
            else
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(top: 100, left: 20, right: 20),
                  child: Text(
                    'Search for a city to get weather information.',
                    style: TextStyle(
                      fontSize: 28,
                      color: ConstColors.fColor.withAlpha(200),
                      fontWeight: FontWeight.w400,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
          ],
        ),
      ),

      floatingActionButton: ClipRRect(
        borderRadius: BorderRadiusGeometry.circular(10),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 4, sigmaY: 4),
          child: FloatingActionButton(
            backgroundColor: ConstColors.grad1.withAlpha(50),
            hoverColor: ConstColors.bColor.withAlpha(50),
            onPressed: fetchWeatherByLocation,
            tooltip: 'Get weather by location',
            child: Icon(
              Icons.location_on_rounded,
              color: ConstColors.grad1,
              size: 24,
            ),
          ),
        ),
      ),
    );
  }

  IconData _getSunRiseSet(int time) {
    final date = DateTime.fromMillisecondsSinceEpoch(time * 1000);
    return date.hour < 12 ? Icons.wb_sunny : Icons.nightlight_round;
  }

  LottieBuilder _getWeatherIcon(String weatherCondition) {
    dynamic wh = Map<String, double>.from({'width': 150.0, 'height': 150.0});
    switch (weatherCondition.toLowerCase()) {
      case 'clear':
        return Lottie.asset(
          'assets/sun.json',
          width: wh['width'],
          height: wh['height'],
        );
      case 'clouds':
        return Lottie.asset(
          'assets/cloudy_sun.json',
          width: wh['width'],
          height: wh['height'],
        );
      case 'thunderstorm':
      case 'rain':
        return Lottie.asset(
          'assets/thunderstorm.json',
          width: wh['width'],
          height: wh['height'],
        );
      case 'snow':
        return Lottie.asset(
          'assets/snow.json',
          width: wh['width'],
          height: wh['height'],
        );
      case 'drizzle':
        return Lottie.asset(
          'assets/drizzle.json',
          width: wh['width'],
          height: wh['height'],
        );
      default:
        return Lottie.asset(
          'assets/cloudy_sun.json',
          width: wh['width'],
          height: wh['height'],
        );
    }
  }

  // Inside your button's onPressed/onTap callback
  void _showDetailsGrid(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: ConstColors.fColor.withAlpha(50),
      // Allows the sheet to take up more than half the screen
      builder: (BuildContext context) {
        // This is the container for your slide-up view
        return ClipRRect(
          borderRadius: BorderRadiusGeometry.circular(20),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
            child: Padding(
              padding: const EdgeInsets.all(10),
              child: SizedBox(
                height: MediaQuery.of(context).size.height * 0.8,
                child: Column(
                  // Use Column to stack your title and the GridView
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    Container(
                      width: 40,
                      height: 5,
                      decoration: BoxDecoration(
                        color: ConstColors.grad1,
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Expanded(
                      child: GridView.count(
                        crossAxisCount: 2,
                        mainAxisSpacing: 10,
                        crossAxisSpacing: 10,
                        children: [
                          infoCard(
                            context,
                            Icons.air_rounded,
                            '${(weatherData!['wind']['speed'] * 3.6).toStringAsFixed(2)} km/h',
                          ),
                          infoCard(
                            context,
                            Icons.water_drop_rounded,
                            'Humidity: ${weatherData!['main']['humidity']}%',
                          ),
                          infoCard(
                            context,
                            Icons.thunderstorm_rounded,
                            'Chance of Rain: ${weatherData!['clouds']['all']}%',
                          ),
                          infoCard(
                            context,
                            Icons.thermostat_rounded,
                            'Pressure: ${_convertPressure(weatherData!['main']['pressure'])} mmHg',
                          ),
                          infoCard(
                            context,
                            _getSunRiseSet(weatherData!['sys']['sunrise']),
                            "Sunrise: ${_convertMilisecondToTime(weatherData!['sys']['sunrise'])}",
                          ),
                          infoCard(
                            context,
                            _getSunRiseSet(weatherData!['sys']['sunset']),
                            "Sunset: ${_convertMilisecondToTime(weatherData!['sys']['sunset'])}",
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget infoCard(BuildContext context, IconData icon, String text) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: ConstColors.grad1.withAlpha(50),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: ConstColors.grad1.withAlpha(120),
          width: 1,
          strokeAlign: BorderSide.strokeAlignInside,
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: 10,
        children: [
          Icon(icon, color: ConstColors.fColor, size: 44),
          Text(
            text,
            style: TextStyle(
              fontSize: 12,
              color: ConstColors.fColor,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
