import 'dart:convert';
import 'package:http/http.dart' as http;

class WeatherService {
  // Replace with your API key from OpenWeatherMap
  final String apiKey = 'ed9ba45798433ef47570875ffce28aae';
  final String baseUrl = 'https://api.openweathermap.org/data/2.5';

  // Get current weather for a location
  Future<Map<String, dynamic>> getCurrentWeather(String city) async {
    final response = await http.get(
      Uri.parse('$baseUrl/weather?q=$city&units=imperial&appid=$apiKey'),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to load weather data: ${response.statusCode}');
    }
  }

  // Get 5-day forecast
  Future<Map<String, dynamic>> getForecast(String city) async {
    final response = await http.get(
      Uri.parse('$baseUrl/forecast?q=$city&units=imperial&appid=$apiKey'),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to load forecast data: ${response.statusCode}');
    }
  }

  // Get weather by coordinates (for current location)
  Future<Map<String, dynamic>> getWeatherByCoordinates(
      double lat, double lon) async {
    final response = await http.get(
      Uri.parse(
          '$baseUrl/weather?lat=$lat&lon=$lon&units=imperial&appid=$apiKey'),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to load weather data: ${response.statusCode}');
    }
  }
}
