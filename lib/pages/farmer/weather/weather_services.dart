import 'dart:convert';

import 'package:http/http.dart' as http;

class WeatherServices {
  final String apiKey = "1ade0b67ddc344df9e4181411251002";
  final String forecastbaseUrl = "https://api.weatherapi.com/v1/forecast.json";
  final String searchbaseUrl = "https://api.weatherapi.com/v1/search.json";

  Future<Map<String, dynamic>> fetchCurrentWeather(String city) async {
    final url = "$forecastbaseUrl?key=$apiKey&q=$city&days=1&aqi=no&alerts=no";
    final response = await http.get(Uri.parse(url));
    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Failed to load weather information');
    }
  }

  Future<Map<String, dynamic>> fetch7DayForecast(String city) async {
    final url = "$forecastbaseUrl?key=$apiKey&q=$city&days=7&aqi=no&alerts=no";
    final response = await http.get(Uri.parse(url));
    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Failed to load forecast information');
    }
  }

  Future<List<dynamic>?> fetchCitySuggestions(String query) async {
    final url = "$searchbaseUrl?key=$apiKey&q=$query";
    final response = await http.get(Uri.parse(url));
    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      return null;
    }
  }
}
