import 'package:flutter/foundation.dart';
import '../../util/weather_service.dart';
import '../../models/weather.dart';

class WeatherProvider with ChangeNotifier {
  WeatherModel? _currentWeather;
  List<ForecastDay> _forecast = [];
  bool _isLoading = false;
  String? _error;
  String _currentLocation = 'New York'; // Default location

  // Getters
  WeatherModel? get currentWeather => _currentWeather;
  List<ForecastDay> get forecast => _forecast;
  bool get isLoading => _isLoading;
  String? get error => _error;
  String get currentLocation => _currentLocation;

  // Create instance of weather service
  final WeatherService _weatherService = WeatherService();

  // Initialize with default city
  WeatherProvider() {
    fetchWeatherData(_currentLocation);
  }

  // Fetch weather for a specific city
  Future<void> fetchWeatherData(String city) async {
    _isLoading = true;
    _error = null;
    _currentLocation = city;
    notifyListeners();

    try {
      // Get current weather
      final weatherData = await _weatherService.getCurrentWeather(city);
      _currentWeather = WeatherModel.fromJson(weatherData);

      // Get forecast
      final forecastData = await _weatherService.getForecast(city);
      _processForecastData(forecastData);

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _error = e.toString();
      notifyListeners();
    }
  }

  // Process forecast data to get one entry per day
  void _processForecastData(Map<String, dynamic> forecastData) {
    final List<dynamic> list = forecastData['list'];
    Map<String, ForecastDay> dailyForecasts = {};

    // Group by day and take noon forecast
    for (var item in list) {
      final forecastItem = ForecastDay.fromJson(item);
      final day = DateTime(forecastItem.date.year, forecastItem.date.month,
          forecastItem.date.day);
      final dayString = day.toString();

      // If we don't have this day yet, or this forecast is closer to noon
      if (!dailyForecasts.containsKey(dayString) ||
          (forecastItem.date.hour - 12).abs() <
              (dailyForecasts[dayString]!.date.hour - 12).abs()) {
        dailyForecasts[dayString] = forecastItem;
      }
    }

    // Convert map to list and sort by date
    _forecast = dailyForecasts.values.toList()
      ..sort((a, b) => a.date.compareTo(b.date));

    // Limit to 5 days
    if (_forecast.length > 5) {
      _forecast = _forecast.sublist(0, 5);
    }
  }
}
