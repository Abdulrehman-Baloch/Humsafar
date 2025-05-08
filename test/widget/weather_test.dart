import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:humsafar_app/widgets/navigation/weather_provider.dart';
import 'package:humsafar_app/screens/weather_screen.dart';
import 'package:humsafar_app/models/weather.dart';

// Mock implementation of WeatherProvider
class MockWeatherProvider extends ChangeNotifier implements WeatherProvider {
  bool _isLoading = false;
  String? _error;
  WeatherModel? _weatherData;
  String _currentLocation = "";
  String? _lastFetchedLocation;

  @override
  bool get isLoading => _isLoading;

  @override
  String? get error => _error;

  @override
  WeatherModel? get currentWeather => _weatherData;

  @override
  List<ForecastDay> get forecast => []; // Not used in tests

  @override
  String get currentLocation => _currentLocation;

  @override
  Future<void> fetchWeatherData(String location) async {
    _lastFetchedLocation = location;
    notifyListeners();
  }

  void setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void setError(String? error) {
    _error = error;
    notifyListeners();
  }

  void setWeatherData(WeatherModel? weather) {
    _weatherData = weather;
    notifyListeners();
  }

  void setCurrentLocation(String location) {
    _currentLocation = location;
    notifyListeners();
  }

  String? get lastFetchedLocation => _lastFetchedLocation;
}

void main() {
  late MockWeatherProvider mockWeatherProvider;

  setUp(() {
    mockWeatherProvider = MockWeatherProvider();
  });

  Widget createWeatherScreen() {
    return MaterialApp(
      home: ChangeNotifierProvider<WeatherProvider>.value(
        value: mockWeatherProvider,
        child: const WeatherScreen(),
      ),
    );
  }

  group('WeatherScreen Tests', () {
    testWidgets('Shows loading indicator when loading', (tester) async {
      mockWeatherProvider.setLoading(true);
      await tester.pumpWidget(createWeatherScreen());
      await tester.pump();
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('Shows error message when there is an error', (tester) async {
      mockWeatherProvider.setLoading(false);
      mockWeatherProvider.setError('City not found');
      mockWeatherProvider.setCurrentLocation('London');

      await tester.pumpWidget(createWeatherScreen());
      await tester.pump();

      expect(find.byIcon(Icons.error_outline), findsOneWidget);
      expect(find.textContaining('City not found'), findsOneWidget);
      expect(find.textContaining('Retry'), findsOneWidget);
    });
    testWidgets('Shows weather data when available', (tester) async {
      mockWeatherProvider.setLoading(false);
      mockWeatherProvider.setError(null);
      mockWeatherProvider.setWeatherData(WeatherModel(
        cityName: 'New York',
        temperature: 72.5, // Ensure this matches your actual model
        condition: 'Clear',
        icon: '01d',
        feelsLike: 75.0,
        windSpeed: 8.5,
        humidity: 65,
      ));

      await tester.pumpWidget(createWeatherScreen());
      await tester.pumpAndSettle();

      // Check if the temperature text contains the value '72'
      expect(
          find.textContaining('73'), findsOneWidget); // Match partial text (72)
      expect(find.text('Clear'), findsOneWidget);
      expect(find.text('New York'), findsOneWidget);
    });

    testWidgets('Search bar triggers fetchWeatherData', (tester) async {
      mockWeatherProvider.setLoading(false);
      mockWeatherProvider.setError(null);
      mockWeatherProvider.setWeatherData(WeatherModel(
        cityName: 'City A',
        temperature: 70,
        condition: 'Clear',
        icon: '01d',
        feelsLike: 72,
        windSpeed: 5.0,
        humidity: 60,
      ));

      await tester.pumpWidget(createWeatherScreen());
      await tester.pump();

      final textField = find.byType(TextField);
      expect(textField, findsOneWidget);

      await tester.enterText(textField, 'Paris');
      await tester.pump();

      final searchButton = find.byType(ElevatedButton).first;
      await tester.tap(searchButton);
      await tester.pump();

      expect(mockWeatherProvider.lastFetchedLocation, 'Paris');
    });

    testWidgets('No weather data shows empty state', (tester) async {
      mockWeatherProvider.setLoading(false);
      mockWeatherProvider.setError(null);
      mockWeatherProvider.setWeatherData(null);

      await tester.pumpWidget(createWeatherScreen());
      await tester.pump();

      expect(find.textContaining('No weather data'), findsOneWidget);
    });
  });
}
