import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'navigation_provider.dart';
import 'find_accommodation.dart';

class bookAccommodation extends StatelessWidget {
  final Map<String, dynamic> accommodation;

  const bookAccommodation({super.key, required this.accommodation});

  @override
  Widget build(BuildContext context) {
    List<String> images = List<String>.from(accommodation['images'] ?? []);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(accommodation['name'] ?? 'Hotel Details'),
        backgroundColor: Colors.blueGrey,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: Icon(Icons.favorite_border),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text("Added to favorites"),
                  duration: Duration(seconds: 2),
                ),
              );
            },
          ),
          IconButton(
            icon: Icon(Icons.share),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text("Share functionality coming soon"),
                  duration: Duration(seconds: 2),
                ),
              );
            },
          ),
        ],
      ),
      body: Row(
        children: [
          // Add the sidebar navigation
          NavigationBar(),

          // Main content
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header Section
                  Container(
                    width: double.infinity,
                    color: const Color.fromARGB(255, 130, 14, 14),
                    padding: EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Accommodation Details",
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        SizedBox(height: 8),
                        Text(
                          "Book your stay at ${accommodation['name']} in ${accommodation['destination'] ?? 'Amazing Location'}",
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.white,
                          ),
                        ),
                        SizedBox(height: 16),
                        // Quick Info Row
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            _buildInfoItem(Icons.star,
                                "${accommodation['rating'] ?? '4.5'} Rating"),
                            _buildInfoItem(Icons.king_bed,
                                "${accommodation['rooms'] ?? '1'} Rooms"),
                            _buildInfoItem(Icons.emoji_people,
                                "${accommodation['guests'] ?? '2'} Guests"),
                            _buildInfoItem(Icons.price_change,
                                "PKR ${accommodation['price']} /night"),
                          ],
                        ),
                      ],
                    ),
                  ),
                  // Divider
                  Divider(height: 1, thickness: 1, color: Colors.white),

                  // Image Row - All images fit on one screen horizontally with increased height
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Property Photos",
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.blueGrey.shade800,
                          ),
                        ),
                        SizedBox(height: 12),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: images.map((imageUrl) {
                            // Calculate the width based on number of images
                            // Accounting for spacing between images and sidebar width
                            double padding = 8.0;
                            double totalPadding = (images.length - 1) * padding;
                            // Subtract 100px for the sidebar width
                            double imageWidth =
                                (MediaQuery.of(context).size.width -
                                        100 -
                                        32.0 -
                                        totalPadding) /
                                    images.length;

                            return ClipRRect(
                              borderRadius: BorderRadius.circular(10),
                              child: Image.network(
                                imageUrl,
                                width: imageWidth,
                                height: 220,
                                fit: BoxFit.cover,
                                loadingBuilder:
                                    (context, child, loadingProgress) {
                                  if (loadingProgress == null) return child;
                                  return SizedBox(
                                    width: imageWidth,
                                    height: 220,
                                    child: Center(
                                      child: CircularProgressIndicator(
                                        value: loadingProgress
                                                    .expectedTotalBytes !=
                                                null
                                            ? loadingProgress
                                                    .cumulativeBytesLoaded /
                                                loadingProgress
                                                    .expectedTotalBytes!
                                            : null,
                                      ),
                                    ),
                                  );
                                },
                                errorBuilder: (context, error, stackTrace) {
                                  return Container(
                                    width: imageWidth,
                                    height: 220,
                                    color: Colors.white,
                                    child: Icon(Icons.error_outline,
                                        color: Colors.grey[600]),
                                  );
                                },
                              ),
                            );
                          }).toList(),
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Property Details Heading
                        Text(
                          "Property Details",
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.blueGrey.shade800,
                          ),
                        ),
                        SizedBox(height: 12),
                        // Hotel Name
                        Text(
                          accommodation['name'] ?? 'No Name',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 10),
                        // Price
                        Text(
                          "PKR ${accommodation['price']} per night",
                          style: TextStyle(
                            fontSize: 18,
                            color: Colors.green,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 10),
                        // Description
                        Text(
                          accommodation['description'] ?? '',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey[700],
                          ),
                        ),
                        SizedBox(height: 20),
                        // Amenities
                        Text(
                          "Amenities",
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.blueGrey.shade800,
                          ),
                        ),
                        SizedBox(height: 12),
                        Wrap(
                          spacing: 8.0,
                          runSpacing: 8.0,
                          children: [
                            _buildAmenityChip(Icons.wifi, "Free WiFi"),
                            _buildAmenityChip(Icons.pool, "Swimming Pool"),
                            _buildAmenityChip(Icons.local_parking, "Parking"),
                            _buildAmenityChip(Icons.restaurant, "Restaurant"),
                            _buildAmenityChip(
                                Icons.ac_unit, "Air Conditioning"),
                            _buildAmenityChip(Icons.tv, "TV"),
                          ],
                        ),
                        SizedBox(height: 30),
                        // Book Hotel Button
                        Center(
                          child: ElevatedButton(
                            onPressed: () {
                              // Add booking logic here
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                      "Booking ${accommodation['name']}..."),
                                ),
                              );
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor:
                                  const Color.fromARGB(255, 137, 17, 8),
                              padding: EdgeInsets.symmetric(
                                  horizontal: 40, vertical: 15),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            child: Text(
                              "Book Now",
                              style: TextStyle(
                                fontSize: 18,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoItem(IconData icon, String text) {
    return Column(
      children: [
        Icon(icon, color: Colors.white),
        SizedBox(height: 4),
        Text(
          text,
          style: TextStyle(
            fontSize: 12,
            color: Colors.white,
          ),
        ),
      ],
    );
  }

  Widget _buildAmenityChip(IconData icon, String label) {
    return Chip(
      avatar: Icon(icon, size: 16, color: Colors.blueGrey),
      label: Text(label),
      backgroundColor: Colors.blueGrey.shade50,
      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 0),
    );
  }
}

// Navigation Bar Widget
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
