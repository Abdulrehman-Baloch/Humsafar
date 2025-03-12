import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'navigation_provider.dart';
import 'find_accommodation.dart';

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
              ],
            ),
          ),
          // Logout button at bottom with padding
          Padding(
            padding: const EdgeInsets.only(bottom: 20.0),
            child: _buildNavItem(
                context, Icons.logout, 'Logout', 4, navigationProvider),
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
        } else if (index == 1) {
          // Navigate to Lists screen
        } else if (index == 2) {
          // Navigate to Accommodation search
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => FindAccommodationScreen()),
          );
        } else if (index == 3) {
          // Navigate to Transportation search
        } else if (index == 4) {
          // Handle logout
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
