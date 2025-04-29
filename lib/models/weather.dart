class WeatherModel {
  final String cityName;
  final double temperature;
  final String condition;
  final String icon;
  final double feelsLike;
  final double windSpeed;
  final int humidity;

  WeatherModel({
    required this.cityName,
    required this.temperature,
    required this.condition,
    required this.icon,
    required this.feelsLike,
    required this.windSpeed,
    required this.humidity,
  });

  // Create model from API response
  factory WeatherModel.fromJson(Map<String, dynamic> json) {
    return WeatherModel(
      cityName: json['name'],
      temperature: json['main']['temp'].toDouble(),
      condition: json['weather'][0]['main'],
      icon: json['weather'][0]['icon'],
      feelsLike: json['main']['feels_like'].toDouble(),
      windSpeed: json['wind']['speed'].toDouble(),
      humidity: json['main']['humidity'],
    );
  }
}

class ForecastDay {
  final DateTime date;
  final double temperature;
  final String condition;
  final String icon;

  ForecastDay({
    required this.date,
    required this.temperature,
    required this.condition,
    required this.icon,
  });

  // Create from API data
  factory ForecastDay.fromJson(Map<String, dynamic> json) {
    return ForecastDay(
      date: DateTime.fromMillisecondsSinceEpoch(json['dt'] * 1000),
      temperature: json['main']['temp'].toDouble(),
      condition: json['weather'][0]['main'],
      icon: json['weather'][0]['icon'],
    );
  }
}
