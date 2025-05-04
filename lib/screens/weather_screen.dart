import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../widgets/navigation/weather_provider.dart';

class WeatherScreen extends StatefulWidget {
  const WeatherScreen({Key? key}) : super(key: key);

  @override
  State<WeatherScreen> createState() => _WeatherScreenState();
}

class _WeatherScreenState extends State<WeatherScreen> {
  final TextEditingController _cityController = TextEditingController();

  @override
  void dispose() {
    _cityController.dispose();
    super.dispose();
  }

  // Get weather icon based on condition code
  Widget _getWeatherIcon(String iconCode, {double size = 48}) {
    // Map OpenWeatherMap icon codes to Flutter icons
    final Map<String, IconData> iconMap = {
      '01d': Icons.wb_sunny, // clear sky day
      '01n': Icons.nightlight_round, // clear sky night
      //'02d': Icons.partly_cloudy_day, // few clouds day
      '02n': Icons.nights_stay, // few clouds night
      '03d': Icons.cloud, // scattered clouds
      '03n': Icons.cloud,
      '04d': Icons.cloud, // broken clouds
      '04n': Icons.cloud,
      '09d': Icons.grain, // shower rain
      '09n': Icons.grain,
      '10d': Icons.beach_access, // rain
      '10n': Icons.beach_access,
      '11d': Icons.flash_on, // thunderstorm
      '11n': Icons.flash_on,
      '13d': Icons.ac_unit, // snow
      '13n': Icons.ac_unit,
      '50d': Icons.waves, // mist
      '50n': Icons.waves,
    };

    IconData iconData = iconMap[iconCode] ?? Icons.help_outline;
    Color iconColor = iconCode.startsWith('01')
        ? Colors.orange
        : iconCode.startsWith('13')
            ? Colors.blue.shade300
            : Colors.grey;

    return Icon(
      iconData,
      size: size,
      color: iconColor,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Weather Updates'),
        backgroundColor: Colors.blue,
      ),
      body: Consumer<WeatherProvider>(
        builder: (context, weatherProvider, _) {
          if (weatherProvider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (weatherProvider.error != null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, size: 60, color: Colors.red),
                  const SizedBox(height: 16),
                  Text(
                    'Error loading weather data',
                    style: TextStyle(fontSize: 18),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    weatherProvider.error!,
                    style: TextStyle(color: Colors.red),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: () => weatherProvider
                        .fetchWeatherData(weatherProvider.currentLocation),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }

          final weather = weatherProvider.currentWeather;
          if (weather == null) {
            return const Center(child: Text('No weather data available'));
          }

          return SingleChildScrollView(
            child: Column(
              children: [
                // Search bar
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _cityController,
                          decoration: const InputDecoration(
                            hintText: 'Enter city name',
                            prefixIcon: Icon(Icons.search),
                            border: OutlineInputBorder(),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton(
                        onPressed: () {
                          if (_cityController.text.isNotEmpty) {
                            weatherProvider
                                .fetchWeatherData(_cityController.text);
                            _cityController.clear();
                            FocusScope.of(context).unfocus();
                          }
                        },
                        child: const Text('Search'),
                      ),
                    ],
                  ),
                ),

                // Current weather card
                Container(
                  width: double.infinity,
                  margin: const EdgeInsets.all(16.0),
                  padding: const EdgeInsets.all(16.0),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade100,
                    borderRadius: BorderRadius.circular(12.0),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withOpacity(0.3),
                        spreadRadius: 2,
                        blurRadius: 5,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      Text(
                        weather.cityName,
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          _getWeatherIcon(weather.icon, size: 64),
                          const SizedBox(width: 16),
                          Text(
                            '${weather.temperature.round()}°F',
                            style: const TextStyle(
                              fontSize: 48,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      Text(
                        weather.condition,
                        style: const TextStyle(
                          fontSize: 18,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _buildWeatherDetail(Icons.thermostat, 'Feels like',
                              '${weather.feelsLike.round()}°F'),
                          _buildWeatherDetail(
                              Icons.air, 'Wind', '${weather.windSpeed} mph'),
                          _buildWeatherDetail(Icons.water_drop, 'Humidity',
                              '${weather.humidity}%'),
                        ],
                      ),
                    ],
                  ),
                ),

                // Forecast section
                if (weatherProvider.forecast.isNotEmpty) ...[
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          '5-Day Forecast',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        for (var forecast in weatherProvider.forecast)
                          ListTile(
                            leading: _getWeatherIcon(forecast.icon, size: 30),
                            title:
                                Text(DateFormat('EEEE').format(forecast.date)),
                            subtitle:
                                Text(DateFormat('MMM d').format(forecast.date)),
                            trailing: Text(
                              '${forecast.temperature.round()}°F',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ],

                const SizedBox(height: 16),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildWeatherDetail(IconData icon, String label, String value) {
    return Column(
      children: [
        Icon(icon, size: 24),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(fontSize: 12),
        ),
        Text(
          value,
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ],
    );
  }
}
