// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class WeatherScreen extends StatefulWidget {
  const WeatherScreen({super.key});

  @override
  // ignore: library_private_types_in_public_api
  _WeatherScreenState createState() => _WeatherScreenState();
}

// Add this mixin to the state class
class _WeatherScreenState extends State<WeatherScreen>
    with SingleTickerProviderStateMixin {
  final String apiKey = '9e4facc3f437949979cb7ec5aa9f551b';
  String city = 'Taxila';

  // final Color primaryColor = Color(0xFF2E7D32); // Forest Green
  // final Color secondaryColor = Color(0xFF81C784); // Light Green
  // final Color accentColor = Color(0xFFFFC107); // Amber
  // final Color backgroundColor = Color(0xFF1B5E20); // Dark Green
  final Color primaryColor = Color(0xFF0D47A1); // Dark Blue
  final Color secondaryColor = Color(0xFF1976D2); // Blue
  final Color accentColor = Color(0xFFFFA000); // Amber
  final Color backgroundColor = Color(0xFF0D47A1); // Dark Blue

  late AnimationController _controller;
  late Animation<double> _fadeInAnimation;
  late Animation<Offset> _slideAnimation;

  // Add these variables at the top of _WeatherScreenState
  String _previousCity = 'Rome';
  bool _isError = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _fadeInAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Interval(0.0, 0.5, curve: Curves.easeOut),
    ));

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Interval(0.0, 0.5, curve: Curves.easeOut),
    ));

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _controller.forward();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  // Update the fetchWeather method with better error handling
  Future<Map<String, dynamic>> fetchWeather() async {
    try {
      final weatherUrl = Uri.parse(
          'https://api.openweathermap.org/data/2.5/weather?q=$city&appid=$apiKey&units=metric');
      final forecastUrl = Uri.parse(
          'https://api.openweathermap.org/data/2.5/forecast?q=$city&appid=$apiKey&units=metric');

      final weatherResponse = await http.get(weatherUrl);
      final forecastResponse = await http.get(forecastUrl);

      if (weatherResponse.statusCode == 200 &&
          forecastResponse.statusCode == 200) {
        final weatherData = json.decode(weatherResponse.body);
        final forecastData = json.decode(forecastResponse.body);

        if (weatherData != null && forecastData != null) {
          _isError = false;
          _previousCity = city;
          return {
            'current': weatherData,
            'forecast': forecastData,
          };
        } else {
          throw Exception('Invalid data received from API');
        }
      } else {
        _isError = true;
        city = _previousCity;
        return await _fetchPreviousCityWeather();
      }
    } catch (e) {
      _isError = true;
      city = _previousCity;
      return await _fetchPreviousCityWeather();
    }
  }

  // Add method to fetch previous city weather
  Future<Map<String, dynamic>> _fetchPreviousCityWeather() async {
    final weatherUrl = Uri.parse(
        'https://api.openweathermap.org/data/2.5/weather?q=$_previousCity&appid=$apiKey&units=metric');
    final forecastUrl = Uri.parse(
        'https://api.openweathermap.org/data/2.5/forecast?q=$_previousCity&appid=$apiKey&units=metric');

    final weatherResponse = await http.get(weatherUrl);
    final forecastResponse = await http.get(forecastUrl);

    return {
      'current': json.decode(weatherResponse.body),
      'forecast': json.decode(forecastResponse.body),
    };
  }

  // Update the _showCityInputDialog method to refresh animations
  void _showCityInputDialog() {
    TextEditingController cityController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Enter City Name'),
          content: TextField(
            controller: cityController,
            decoration: const InputDecoration(hintText: 'City'),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                setState(() {
                  city = cityController.text.trim();
                  _refreshAnimations(); // Add this line
                });
                Navigator.of(context).pop();
              },
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }

  IconData _getWeatherIcon(
      String condition, DateTime sunrise, DateTime sunset) {
    DateTime now = DateTime.now();
    bool isDayTime = now.isAfter(sunrise) && now.isBefore(sunset);

    switch (condition.toLowerCase()) {
      case 'clear':
        return isDayTime ? Icons.wb_sunny : Icons.nightlight_round;
      case 'clouds':
        return Icons.wb_cloudy;
      case 'rain':
        return Icons.umbrella;
      case 'thunderstorm':
        return Icons.flash_on;
      case 'snow':
        return Icons.ac_unit;
      case 'mist':
      case 'fog':
        return Icons.cloud;
      default:
        return isDayTime ? Icons.wb_sunny : Icons.nightlight_round;
    }
  }

  // Add pull-to-refresh animation
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async {
            setState(() {
              if (_isError) {
                city = _previousCity;
                _isError = false;
              }
            });
            _refreshAnimations();
            await fetchWeather();
          },
          child: FutureBuilder<Map<String, dynamic>>(
            future: fetchWeather(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              } else if (snapshot.hasError || _isError || !snapshot.hasData) {
                return _buildErrorWidget();
              } else {
                try {
                  final weatherData = snapshot.data!['current'];
                  if (weatherData == null || weatherData['main'] == null) {
                    throw Exception('Invalid weather data');
                  }

                  final temperature =
                      weatherData['main']['temp']?.toString() ?? 'N/A';
                  final condition =
                      weatherData['weather']?[0]?['main'] ?? 'Unknown';
                  final maxTemp =
                      weatherData['main']['temp_max']?.toString() ?? 'N/A';
                  final minTemp =
                      weatherData['main']['temp_min']?.toString() ?? 'N/A';
                  final humidity =
                      weatherData['main']['humidity']?.toString() ?? 'N/A';
                  final windSpeed =
                      weatherData['wind']?['speed']?.toString() ?? 'N/A';
                  final sunrise = DateTime.fromMillisecondsSinceEpoch(
                          (weatherData['sys']?['sunrise'] ?? 0) * 1000)
                      .toLocal();
                  final sunset = DateTime.fromMillisecondsSinceEpoch(
                          (weatherData['sys']?['sunset'] ?? 0) * 1000)
                      .toLocal();

                  return SingleChildScrollView(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Align(
                          alignment: Alignment.centerLeft,
                          child: GestureDetector(
                            onTap: _showCityInputDialog,
                            child: Row(
                              children: [
                                const Icon(Icons.location_on,
                                    color: Colors.white),
                                const SizedBox(width: 5),
                                Text(
                                  city,
                                  style: GoogleFonts.lato(
                                    textStyle: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 24,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),
                        Icon(
                          _getWeatherIcon(condition, sunrise, sunset),
                          size: 80,
                          color: Colors.white,
                        ),
                        const SizedBox(height: 10),
                        Text(
                          '$temperature°C',
                          style: GoogleFonts.lato(
                            textStyle: const TextStyle(
                              color: Colors.white,
                              fontSize: 40,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        Text(
                          condition,
                          style: GoogleFonts.lato(
                            textStyle: const TextStyle(
                              color: Colors.white70,
                              fontSize: 22,
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),
                        Text(
                          'Max: $maxTemp°C  Min: $minTemp°C',
                          style: const TextStyle(
                              color: Colors.white, fontSize: 16),
                        ),
                        const SizedBox(height: 20),
                        Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                Colors.white.withOpacity(0.2),
                                Colors.white.withOpacity(0.1),
                              ],
                            ),
                            borderRadius: BorderRadius.circular(15),
                            border: Border.all(
                              color: Colors.white.withOpacity(0.2),
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.1),
                                blurRadius: 10,
                                spreadRadius: 1,
                              ),
                            ],
                          ),
                          padding: const EdgeInsets.symmetric(
                              vertical: 15, horizontal: 10),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: [
                              _buildWeatherDetail(
                                  Icons.water_drop, 'Humidity', '$humidity%'),
                              _buildWeatherDetail(
                                  Icons.thermostat, 'Temp', '$temperature°C'),
                              _buildWeatherDetail(
                                  Icons.air, 'Wind', '$windSpeed km/h'),
                            ],
                          ),
                        ),
                        const SizedBox(height: 30),
                        _buildForecastSection(),
                      ],
                    ),
                  );
                } catch (e) {
                  return _buildErrorWidget();
                }
              }
            },
          ),
        ),
      ),
    );
  }

  // Update the weather details container style with animation
  Widget _buildWeatherDetail(IconData icon, String title, String value) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return FadeTransition(
          opacity: _fadeInAnimation,
          child: SlideTransition(
            position: _slideAnimation,
            child: child,
          ),
        );
      },
      child: Container(
        width: MediaQuery.of(context).size.width * 0.27,
        padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 10),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              primaryColor.withOpacity(0.8),
              primaryColor.withOpacity(0.6),
            ],
          ),
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: Colors.white.withOpacity(0.1)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 8,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: Colors.white, size: 28),
            const SizedBox(height: 8),
            Text(
              title,
              style: GoogleFonts.lato(
                textStyle: TextStyle(
                  color: Colors.white.withOpacity(0.8),
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: GoogleFonts.lato(
                textStyle: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Update the forecast section to show 7 days
  Widget _buildForecastSection() {
    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.white.withOpacity(0.15),
            Colors.white.withOpacity(0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(25),
        border: Border.all(
          color: Colors.white.withOpacity(0.2),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            spreadRadius: 1,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '7-Day Forecast',
            style: GoogleFonts.lato(
              textStyle: TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(height: 20),
          FutureBuilder<Map<String, dynamic>>(
            future: fetchWeather(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return Center(
                  child: CircularProgressIndicator(
                    color: Colors.white,
                  ),
                );
              }

              final forecastList = snapshot.data!['forecast']['list'] as List;
              final dailyForecasts = <String, Map<String, dynamic>>{};

              for (var forecast in forecastList) {
                final date =
                    DateTime.fromMillisecondsSinceEpoch(forecast['dt'] * 1000);
                final dateKey = '${date.year}-${date.month}-${date.day}';

                if (!dailyForecasts.containsKey(dateKey)) {
                  dailyForecasts[dateKey] = forecast;
                }
              }

              final next7Days = dailyForecasts.values.take(7).toList();

              return Column(
                children: next7Days.map((forecast) {
                  forecast['main']['temp'].round().toString();
                  forecast['main']['temp_max'].round().toString();
                  forecast['main']['temp_min'].round().toString();

                  return _buildForecastItem(
                      forecast, next7Days.indexOf(forecast));
                }).toList(),
              );
            },
          ),
        ],
      ),
    );
  }

  // Add animation to forecast items
  Widget _buildForecastItem(Map<String, dynamic> forecast, int index) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final delay = index * 0.2;
        final slideAnimation = Tween<Offset>(
          begin: const Offset(1.0, 0.0),
          end: Offset.zero,
        ).animate(CurvedAnimation(
          parent: _controller,
          curve: Interval(delay, delay + 0.5, curve: Curves.easeOut),
        ));

        final fadeAnimation = Tween<double>(
          begin: 0.0,
          end: 1.0,
        ).animate(CurvedAnimation(
          parent: _controller,
          curve: Interval(delay, delay + 0.5, curve: Curves.easeOut),
        ));

        return FadeTransition(
          opacity: fadeAnimation,
          child: SlideTransition(
            position: slideAnimation,
            child: child,
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 8),
        padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.white.withOpacity(0.2),
              Colors.white.withOpacity(0.1),
            ],
          ),
          borderRadius: BorderRadius.circular(15),
          border: Border.all(
            color: Colors.white.withOpacity(0.1),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            SizedBox(
              width: 100,
              child: Text(
                _getDayName(
                    DateTime.fromMillisecondsSinceEpoch(forecast['dt'] * 1000)),
                style: GoogleFonts.lato(
                  textStyle: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
            Row(
              children: [
                Icon(
                  _getWeatherIcon(
                      forecast['weather'][0]['main'],
                      DateTime.fromMillisecondsSinceEpoch(
                          forecast['dt'] * 1000),
                      DateTime.fromMillisecondsSinceEpoch(
                          forecast['dt'] * 1000)),
                  color: accentColor,
                  size: 24,
                ),
                const SizedBox(width: 8),
                Text(
                  forecast['weather'][0]['main'],
                  style: GoogleFonts.lato(
                    textStyle: TextStyle(
                      color: Colors.white.withOpacity(0.8),
                      fontSize: 14,
                    ),
                  ),
                ),
              ],
            ),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                children: [
                  Text(
                    '${forecast['main']['temp_min'].round()}°',
                    style: GoogleFonts.lato(
                      textStyle: TextStyle(
                        color: Colors.white70,
                        fontSize: 16,
                      ),
                    ),
                  ),
                  Text(
                    ' / ',
                    style: TextStyle(color: Colors.white70),
                  ),
                  Text(
                    '${forecast['main']['temp_max'].round()}°',
                    style: GoogleFonts.lato(
                      textStyle: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Add this method for refreshing animations
  void _refreshAnimations() {
    _controller.reset();
    _controller.forward();
  }

  String _getDayName(DateTime date) {
    final days = [
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
      'Sunday'
    ];
    return days[date.weekday - 1];
  }

  // Update the error widget
  Widget _buildErrorWidget() {
    return SingleChildScrollView(
      physics: AlwaysScrollableScrollPhysics(),
      child: SizedBox(
        height: MediaQuery.of(context).size.height - 100,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.location_off,
                size: 64,
                color: Colors.white70,
              ),
              SizedBox(height: 16),
              Text(
                'City not found',
                style: GoogleFonts.lato(
                  textStyle: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              SizedBox(height: 8),
              Text(
                'Showing weather for $_previousCity\nPull down to refresh',
                textAlign: TextAlign.center,
                style: GoogleFonts.lato(
                  textStyle: TextStyle(
                    color: Colors.white70,
                    fontSize: 16,
                  ),
                ),
              ),
              SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: _showCityInputDialog,
                icon: Icon(Icons.search),
                label: Text('Try Another City'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: accentColor,
                  foregroundColor: backgroundColor,
                  padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
