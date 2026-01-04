import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:weatherapp/chartbox.dart';

import 'services/weather_service.dart';
import 'utils/const_style.dart';

class WeatherScreen extends StatefulWidget {
  const WeatherScreen({
    super.key,
    required this.savedCities,
    this.initialIndex = 0,
  });

  final List<String> savedCities;
  final int initialIndex;

  @override
  WeatherScreenState createState() => WeatherScreenState();
}

class WeatherScreenState extends State<WeatherScreen> {
  final WeatherService _weatherService = WeatherService();
  final Map<String, Map<String, dynamic>> _weatherCache =
      <String, Map<String, dynamic>>{};
  final Map<String, List<dynamic>> _hourlyCache = <String, List<dynamic>>{};

  late final PageController _pageController;
  late List<String> _cities;
  int _currentIndex = 0;
  bool _isLoading = false;
  String? _errorMessage;
  String? _loadingCity;
  bool _allowPop = false;

  @override
  void initState() {
    super.initState();
    _cities = List<String>.from(widget.savedCities);
    if (_cities.isNotEmpty) {
      final maxIndex = _cities.length - 1;
      _currentIndex = widget.initialIndex.clamp(0, maxIndex);
    } else {
      _currentIndex = 0;
    }
    _pageController = PageController(initialPage: _currentIndex);

    if (_cities.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) {
          return;
        }
        _loadWeatherForCity(_cities[_currentIndex]);
      });
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _loadWeatherForCity(String city) async {
    setState(() {
      _isLoading = true;
      _loadingCity = city;
      _errorMessage = null;
    });

    try {
      final current = await _weatherService.fetchCurrentWeather(city);
      final coord =
          (current['coord'] as Map<String, dynamic>?) ?? <String, dynamic>{};
      final latValue = (coord['lat'] as num?)?.toDouble() ?? 0;
      final lonValue = (coord['lon'] as num?)?.toDouble() ?? 0;
      final hourly = await _weatherService.fetchHourlyForecast(
        latValue,
        lonValue,
      );
      if (!mounted) {
        return;
      }

      final resolvedName = (current['name'] as String? ?? city).trim();
      final index = _cities.indexWhere(
        (value) => value.toLowerCase() == city.toLowerCase(),
      );
      if (index != -1) {
        _cities[index] = resolvedName;
      }

      setState(() {
        _weatherCache[resolvedName] = current;
        _hourlyCache[resolvedName] = hourly;
        _isLoading = false;
        _loadingCity = null;
      });
    } on WeatherServiceException catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _errorMessage = error.message;
        _isLoading = false;
        _loadingCity = null;
      });
      showErrorInfo(error.message);
    } catch (_) {
      if (!mounted) {
        return;
      }
      setState(() {
        _errorMessage = 'Failed to load weather data';
        _isLoading = false;
        _loadingCity = null;
      });
      showErrorInfo('Failed to load weather data');
    }
  }

  Future<void> _handlePageChanged(int index) async {
    setState(() {
      _currentIndex = index;
    });
    final city = _cities[index];

    if (!_weatherCache.containsKey(city)) {
      await _loadWeatherForCity(city);
    }
  }

  void showErrorInfo(dynamic e) {
    final alertDialog = AlertDialog(
      backgroundColor: ConstColors.errorBg,
      icon: const Icon(Icons.error_outline),
      content: Text('$e'),
      title: const Text('Weather Error'),
      titleTextStyle: const TextStyle(
        color: ConstColors.errorFg,
        fontWeight: FontWeight.bold,
        fontFamily: 'Inter',
      ),
    );

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return alertDialog;
      },
    );
  }

  String _addLeadPadding(int number) {
    return number < 10 ? '0$number' : '$number';
  }

  String _convertMillisecondToTime(int milliseconds) {
    final date = DateTime.fromMillisecondsSinceEpoch(milliseconds * 1000);
    final hour = date.hour > 12 ? date.hour - 12 : date.hour;
    final suffix = date.hour >= 12 ? 'PM' : 'AM';
    return '$hour:${_addLeadPadding(date.minute)} $suffix';
  }

  String _convertPressure(int pressure) {
    return (pressure * 0.750062).toStringAsFixed(0);
  }

  void _popWithResult() {
    if (!mounted) {
      return;
    }
    setState(() {
      _allowPop = true;
    });
    Navigator.of(context).pop(_cities);
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: _allowPop,
      onPopInvoked: (didPop) {
        if (!didPop) {
          _popWithResult();
        }
      },
      child: Scaffold(
        backgroundColor: ConstColors.grad3,
        appBar: AppBar(
          title: Row(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              Image(
                image: ResizeImage(
                  const AssetImage('assets/logo.png'),
                  width: 28,
                  height: 28,
                  allowUpscaling: true,
                ),
              ),
              const SizedBox(width: 10),
              const Text(
                'Weather',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          iconTheme: const IconThemeData(color: ConstColors.fColor),
          elevation: 1,
          leading: Container(
            margin: const EdgeInsets.only(left: 10),
            child: IconButton(
              icon: const Icon(
                Icons.arrow_back_ios,
                color: ConstColors.fColor,
                size: 28,
              ),
              onPressed: _popWithResult,
            ),
          ),
        ),
        body: Container(
          width: double.infinity,
          height: double.infinity,
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [ConstColors.grad1, ConstColors.grad2, ConstColors.grad3],
            ),
          ),
          child: _cities.isEmpty
              ? _buildEmptyState()
              : PageView.builder(
                  controller: _pageController,
                  onPageChanged: _handlePageChanged,
                  itemCount: _cities.length,
                  itemBuilder: (context, index) {
                    final city = _cities[index];
                    return _buildWeatherPage(city);
                  },
                ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Text(
          'Add cities from the locations page to view detailed weather.',
          style: TextStyle(
            fontSize: 20,
            color: ConstColors.fColor.withAlpha(200),
          ),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }

  Widget _buildWeatherPage(String city) {
    final weatherData = _weatherCache[city];
    final hourlyForecastData = _hourlyCache[city] ?? <dynamic>[];
    final isPageLoading =
        _loadingCity != null &&
        _loadingCity!.toLowerCase() == city.toLowerCase();
    final hasError = _errorMessage != null && isPageLoading;

    return ListView(
      physics: const BouncingScrollPhysics(),
      padding: EdgeInsets.zero,
      children: [
        const SizedBox(height: 10),
        if (hasError)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Text(
              _errorMessage!,
              style: const TextStyle(
                fontSize: 16,
                color: ConstColors.errorFg,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        if (isPageLoading && weatherData == null)
          const Padding(
            padding: EdgeInsets.only(top: 50),
            child: Center(
              child: CircularProgressIndicator(
                backgroundColor: Colors.white,
                color: Colors.blueAccent,
              ),
            ),
          )
        else if (weatherData != null)
          Container(
            margin: const EdgeInsets.only(bottom: 14),
            child: Column(
              children: [
                if (isPageLoading)
                  const Padding(
                    padding: EdgeInsets.only(top: 10),
                    child: CircularProgressIndicator(
                      backgroundColor: Colors.white,
                      color: Colors.blueAccent,
                    ),
                  ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text(
                      '${weatherData['name']}, ${weatherData['sys']['country']}',
                      style: const TextStyle(
                        fontSize: 16,
                        color: ConstColors.fColor,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      '${(weatherData['main']['temp'] as num).toInt()}°C',
                      style: const TextStyle(
                        fontSize: 48,
                        color: ConstColors.fColor,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      'Feeling ${weatherData['main']['feels_like']}°C',
                      style: const TextStyle(
                        fontSize: 14,
                        color: ConstColors.fColor,
                      ),
                    ),
                  ],
                ),
                Padding(
                  padding: const EdgeInsets.all(10),
                  child: Column(
                    children: [
                      _getWeatherIcon(weatherData['weather'][0]['main']),
                      Text(
                        weatherData['weather'][0]['description']
                            .toString()
                            .toUpperCase(),
                        style: const TextStyle(
                          fontSize: 12,
                          color: ConstColors.fColor,
                        ),
                      ),
                      const SizedBox(height: 10),
                    ],
                  ),
                ),
                if (hourlyForecastData.isNotEmpty)
                  ChartBox(hourlyForecastData: hourlyForecastData),
                _showDetailsGrid(context, weatherData),
              ],
            ),
          )
        else
          Padding(
            padding: const EdgeInsets.only(top: 100, left: 20, right: 20),
            child: Text(
              _isLoading
                  ? 'Loading weather details...'
                  : 'Swipe to another city or return to add more locations.',
              style: TextStyle(
                fontSize: 20,
                color: ConstColors.fColor.withAlpha(200),
                fontWeight: FontWeight.w400,
              ),
              textAlign: TextAlign.center,
            ),
          ),
      ],
    );
  }

  IconData _getSunRiseSet(int time) {
    final date = DateTime.fromMillisecondsSinceEpoch(time * 1000);
    return date.hour < 12 ? Icons.wb_sunny : Icons.nightlight_round;
  }

  LottieBuilder _getWeatherIcon(String weatherCondition) {
    final dimensions = Map<String, double>.from({
      'width': 150.0,
      'height': 150.0,
    });
    switch (weatherCondition.toLowerCase()) {
      case 'clear':
        return Lottie.asset(
          'assets/sun.json',
          width: dimensions['width'],
          height: dimensions['height'],
        );
      case 'clouds':
        return Lottie.asset(
          'assets/cloudy_sun.json',
          width: dimensions['width'],
          height: dimensions['height'],
        );
      case 'thunderstorm':
      case 'rain':
        return Lottie.asset(
          'assets/thunderstorm.json',
          width: dimensions['width'],
          height: dimensions['height'],
        );
      case 'snow':
        return Lottie.asset(
          'assets/snow.json',
          width: dimensions['width'],
          height: dimensions['height'],
        );
      case 'drizzle':
        return Lottie.asset(
          'assets/drizzle.json',
          width: dimensions['width'],
          height: dimensions['height'],
        );
      default:
        return Lottie.asset(
          'assets/cloudy_sun.json',
          width: dimensions['width'],
          height: dimensions['height'],
        );
    }
  }

  Widget _showDetailsGrid(
    BuildContext context,
    Map<String, dynamic> weatherData,
  ) {
    return Padding(
      padding: const EdgeInsets.all(10),
      child: GridView.count(
        physics: const NeverScrollableScrollPhysics(),
        shrinkWrap: true,
        primary: false,
        crossAxisCount: 2,
        mainAxisSpacing: 10,
        crossAxisSpacing: 10,
        children: [
          infoCard(
            context,
            Icons.air_rounded,
            '${((weatherData['wind']['speed'] as num) * 3.6).toStringAsFixed(2)} km/h',
          ),
          infoCard(
            context,
            Icons.water_drop_rounded,
            'Humidity: ${weatherData['main']['humidity']}%',
          ),
          infoCard(
            context,
            Icons.thunderstorm_rounded,
            'Chance of Rain: ${weatherData['clouds']['all']}%',
          ),
          infoCard(
            context,
            Icons.thermostat_rounded,
            'Pressure: ${_convertPressure(weatherData['main']['pressure'])} mmHg',
          ),
          infoCard(
            context,
            _getSunRiseSet(weatherData['sys']['sunrise']),
            'Sunrise: ${_convertMillisecondToTime(weatherData['sys']['sunrise'])}',
          ),
          infoCard(
            context,
            _getSunRiseSet(weatherData['sys']['sunset']),
            'Sunset: ${_convertMillisecondToTime(weatherData['sys']['sunset'])}',
          ),
        ],
      ),
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
        children: [
          Icon(icon, color: ConstColors.fColor, size: 44),
          const SizedBox(height: 10),
          Text(
            text,
            style: const TextStyle(
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
