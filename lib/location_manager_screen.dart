import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';

import 'services/weather_service.dart';
import 'utils/const_style.dart';
import 'weather_screen.dart';

class LocationManagerScreen extends StatefulWidget {
  const LocationManagerScreen({super.key});

  @override
  State<LocationManagerScreen> createState() => _LocationManagerScreenState();
}

class _LocationManagerScreenState extends State<LocationManagerScreen> {
  final WeatherService _weatherService = WeatherService();
  final TextEditingController _searchController = TextEditingController();
  final List<LocationSummary> _locations = <LocationSummary>[];
  bool _isAdding = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _handleAddCity() async {
    final query = _searchController.text.trim();
    if (query.isEmpty) {
      return;
    }

    final alreadySaved = _locations.any(
      (location) => location.city.toLowerCase() == query.toLowerCase(),
    );
    if (alreadySaved) {
      _showMessage('City already added');
      return;
    }

    setState(() => _isAdding = true);
    try {
      final data = await _weatherService.fetchCurrentWeather(query);
      final summary = LocationSummary.fromApi(data);
      setState(() {
        _locations.add(summary);
        _searchController.clear();
      });
    } on WeatherServiceException catch (error) {
      _showMessage(error.message);
    } catch (_) {
      _showMessage('Unable to add city');
    } finally {
      if (mounted) {
        setState(() => _isAdding = false);
      }
    }
  }

  Future<void> _addCurrentLocation() async {
    if (_isAdding) {
      return;
    }

    setState(() => _isAdding = true);
    try {
      final city = await _resolveCurrentCity();
      final alreadySaved = _locations.any(
        (location) => location.city.toLowerCase() == city.toLowerCase(),
      );

      if (alreadySaved) {
        _showMessage('City already added');
        return;
      }

      final data = await _weatherService.fetchCurrentWeather(city);
      final summary = LocationSummary.fromApi(data);
      setState(() {
        _locations.add(summary);
      });
    } on WeatherServiceException catch (error) {
      _showMessage(error.message);
    } catch (error) {
      _showMessage('$error');
    } finally {
      if (mounted) {
        setState(() => _isAdding = false);
      }
    }
  }

  Future<void> _openWeatherScreen(int index) async {
    if (_locations.isEmpty) {
      return;
    }

    final updatedCities = await Navigator.of(context).push<List<String>>(
      MaterialPageRoute<List<String>>(
        builder: (_) => WeatherScreen(
          savedCities: _locations.map((location) => location.city).toList(),
          initialIndex: index,
        ),
      ),
    );

    if (updatedCities == null) {
      return;
    }

    await _syncCities(updatedCities);
  }

  Future<void> _syncCities(List<String> cities) async {
    final lowerNames = cities.map((city) => city.toLowerCase()).toList();
    _locations.removeWhere(
      (location) => !lowerNames.contains(location.city.toLowerCase()),
    );

    for (final city in cities) {
      final exists = _locations.any(
        (location) => location.city.toLowerCase() == city.toLowerCase(),
      );

      if (!exists) {
        try {
          final data = await _weatherService.fetchCurrentWeather(city);
          _locations.add(LocationSummary.fromApi(data));
        } catch (_) {
          // Ignore sync failures silently.
        }
      }
    }

    if (mounted) {
      setState(() {});
    }
  }

  void _handleRemove(LocationSummary summary) {
    setState(() {
      _locations.remove(summary);
    });
  }

  void _showMessage(String text) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(text, textAlign: TextAlign.center),
        backgroundColor: ConstColors.grad1,
      ),
    );
  }

  Future<String> _resolveCurrentCity() async {
    LocationPermission permission = await Geolocator.checkPermission();

    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      permission = await Geolocator.requestPermission();

      if (permission == LocationPermission.denied) {
        throw Exception('Location permissions are denied');
      } else if (permission == LocationPermission.deniedForever) {
        throw Exception(
          'Location permissions are permanently denied, we cannot request permissions.',
        );
      }
    }

    final position = await Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.best,
        timeLimit: Duration(seconds: 5),
        distanceFilter: 5,
      ),
    );

    final placemarks = await placemarkFromCoordinates(
      position.latitude,
      position.longitude,
    );
    final city = placemarks.isNotEmpty ? placemarks.first.locality : null;

    if (city == null || city.isEmpty) {
      throw Exception('Unable to resolve current city');
    }

    return city;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ConstColors.grad3,
      appBar: AppBar(
        title: Row(
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
        actions: [
          IconButton(
            icon: const Icon(
              Icons.info_outline_rounded,
              color: ConstColors.fColor,
              size: 28,
            ),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  animation: const AlwaysStoppedAnimation<double>(1.0),
                  content: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text(
                        'TB Weather App',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: ConstColors.fColor,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 10),
                      const Text(
                        'Developed by TTT',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: ConstColors.fColor,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                  backgroundColor: ConstColors.grad1,
                  duration: const Duration(seconds: 3),
                ),
              );
            },
          ),
        ],
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [ConstColors.grad1, ConstColors.grad2, ConstColors.grad3],
          ),
        ),
        child: Column(
          children: [
            const SizedBox(height: 10),
            Padding(
              padding: const EdgeInsets.all(10),
              child: TextField(
                controller: _searchController,
                cursorColor: ConstColors.fColor,
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
                    borderSide: BorderSide(
                      color: ConstColors.errorFg.withAlpha(180),
                    ),
                    borderRadius: BorderRadius.circular(40),
                  ),
                  suffixIcon: IconButton(
                    icon: const Icon(
                      Icons.search,
                      color: ConstColors.fColor,
                      size: 28,
                    ),
                    onPressed: _isAdding ? null : _handleAddCity,
                  ),
                ),
                style: const TextStyle(color: ConstColors.fColor, fontSize: 14),
                onSubmitted: (_) {
                  if (!_isAdding) {
                    _handleAddCity();
                  }
                },
              ),
            ),
            if (_isAdding)
              const Padding(
                padding: EdgeInsets.only(top: 20),
                child: CircularProgressIndicator(
                  backgroundColor: Colors.white,
                  color: Colors.blueAccent,
                ),
              ),
            Expanded(
              child: _locations.isEmpty
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        child: Text(
                          'Add cities to manage weather cards.',
                          style: TextStyle(
                            fontSize: 20,
                            color: ConstColors.fColor.withAlpha(180),
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(10),
                      physics: const BouncingScrollPhysics(),
                      itemCount: _locations.length,
                      itemBuilder: (context, index) {
                        final location = _locations[index];
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: GestureDetector(
                            onTap: () => _openWeatherScreen(index),
                            child: Container(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(24),
                                border: Border.all(
                                  color: ConstColors.grad1.withAlpha(120),
                                  width: 1,
                                  strokeAlign: BorderSide.strokeAlignOutside,
                                ),
                                color: ConstColors.grad1.withAlpha(40),
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(24),
                                child: BackdropFilter(
                                  filter: ImageFilter.blur(
                                    sigmaX: 4,
                                    sigmaY: 4,
                                  ),
                                  child: ListTile(
                                    contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 20,
                                      vertical: 14,
                                    ),
                                    title: Text(
                                      '${location.city}, ${location.country}',
                                      style: const TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                        color: ConstColors.fColor,
                                      ),
                                    ),
                                    subtitle: Text(
                                      location.description.toUpperCase(),
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: ConstColors.fColor.withAlpha(
                                          180,
                                        ),
                                      ),
                                    ),
                                    trailing: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text(
                                          '${location.temperature}°C',
                                          style: const TextStyle(
                                            fontSize: 28,
                                            fontWeight: FontWeight.w600,
                                            color: ConstColors.fColor,
                                          ),
                                        ),
                                        // const SizedBox(width: 8),
                                        IconButton(
                                          iconSize: 22,
                                          padding: EdgeInsets.zero,
                                          constraints: const BoxConstraints(),
                                          icon: const Icon(
                                            Icons.close,
                                            color: ConstColors.fColor,
                                          ),
                                          onPressed: () =>
                                              _handleRemove(location),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        );
                      },
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
            backgroundColor: ConstColors.grad1,
            hoverColor: ConstColors.bColor.withAlpha(50),
            onPressed: _isAdding ? null : _addCurrentLocation,
            tooltip: 'Add current location',
            child: Icon(
              Icons.location_on_rounded,
              color: ConstColors.fColor.withAlpha(100),
              size: 24,
            ),
          ),
        ),
      ),
    );
  }
}

class LocationSummary {
  const LocationSummary({
    required this.city,
    required this.country,
    required this.temperature,
    required this.description,
  });

  final String city;
  final String country;
  final int temperature;
  final String description;

  factory LocationSummary.fromApi(Map<String, dynamic> data) {
    final weather = data['weather'] as List<dynamic>?;
    final firstWeather = weather != null && weather.isNotEmpty
        ? weather.first
        : null;
    final description = firstWeather != null
        ? (firstWeather['description'] as String? ?? '').trim()
        : '';

    return LocationSummary(
      city: (data['name'] as String? ?? '').trim(),
      country: (data['sys']?['country'] as String? ?? '').trim(),
      temperature: (data['main']?['temp'] as num? ?? 0).round(),
      description: description,
    );
  }
}
