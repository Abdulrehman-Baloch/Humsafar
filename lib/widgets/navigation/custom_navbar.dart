import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'navigation_provider.dart';
import '../../screens/bookings/accommodation/find_accommodation.dart';
import '../../screens/trip/view_trip_plans.dart';
import '../../screens/bookings/transportation/search_transportation.dart';
import '../../screens/welcome.dart';
import '../../screens/lists/my_lists_screen.dart';
import '../../screens/weather_screen.dart'; // Import the weather screen

class NavigationBar extends StatelessWidget {
  const NavigationBar({super.key});

  @override
  Widget build(BuildContext context) {
    final navigationProvider = Provider.of<NavigationProvider>(context);

    return Container(
      width: 100,
      color: const Color.fromARGB(255, 92, 91, 91),
      child: Column(
        children: [
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildNavItem(
                    context, Icons.map, 'Your Trips', 0, navigationProvider),
                _buildNavItem(
                    context, Icons.list, 'Your Lists', 1, navigationProvider),
                _buildNavItem(context, Icons.hotel, 'Find \nAccommodation', 2,
                    navigationProvider),
                _buildNavItem(context, Icons.directions_car,
                    'Find \nTransportation', 3, navigationProvider),
                _buildNavItem(context, Icons.wb_sunny, 'Weather\nUpdates', 4,
                    navigationProvider), // Added weather item
              ],
            ),
          ),
          // Logout button at bottom with padding
          Padding(
            padding: const EdgeInsets.only(bottom: 20.0),
            child: _buildNavItem(context, Icons.logout, 'Logout', 5,
                navigationProvider), // Changed index to 5
          ),
        ],
      ),
    );
  }

  Widget _buildNavItem(BuildContext context, IconData icon, String label,
      int index, NavigationProvider provider) {
    final isSelected = provider.selectedIndex == index;

    return GestureDetector(
      onTap: () {
        provider.updateSelectedIndex(index);
        // Add navigation logic here if needed
        if (index == 0) {
          // Navigate to Trips screen
          Navigator.push(
            context,
            MaterialPageRoute(
                builder: (context) => const ViewTripPlansScreen()),
          );
        } else if (index == 1) {
          // Navigate to Lists screen
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const MyListsScreen()),
          );
        } else if (index == 2) {
          // Navigate to Accommodation search
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => FindAccommodationScreen()),
          );
        } else if (index == 3) {
          // Navigate to Transportation search
          Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (context) => SearchTransportationScreen()));
        } else if (index == 4) {
          // Navigate to Weather screen
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const WeatherScreen()),
          );
        } else if (index == 5) {
          // Changed from 4 to 5
          Navigator.pushAndRemoveUntil(
            // Navigate to Welcome screen
            context,
            MaterialPageRoute(builder: (context) => WelcomeScreen()),
            (route) => false,
          );
        }
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon,
                size: 24, color: isSelected ? Colors.black : Colors.white),
            const SizedBox(height: 8),
            SizedBox(
              width: 100,
              child: Text(
                label,
                style: TextStyle(
                  color: isSelected ? Colors.black : Colors.white,
                  fontSize: 11,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                ),
                textAlign: TextAlign.center,
                overflow: TextOverflow.ellipsis,
                maxLines: 2,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
