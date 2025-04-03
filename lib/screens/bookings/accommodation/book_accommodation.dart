import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart'; // Added FirebaseAuth import
import '../../../widgets/navigation/custom_navbar.dart' as custom;

class book_accommodation extends StatefulWidget {
  final Map<String, dynamic> accommodation;
  final String destinationID;
  final String destinationName;
  final String tripPlanId; // Added tripPlanId to use in Firestore

  const book_accommodation({
    super.key,
    required this.accommodation,
    required this.destinationID,
    required this.destinationName,
    required this.tripPlanId, // Added tripPlanId parameter
  });

  @override
  _BookAccommodationState createState() => _BookAccommodationState();
}

class _BookAccommodationState extends State<book_accommodation> {
  Future<void> _book_accommodation(BuildContext context) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('You need to be logged in to book accommodations')),
      );
      return;
    }

    try {
      // Save accommodation to tripAccommodations subcollection under tripDestinations
      await FirebaseFirestore.instance
          .collection('tripPlans')
          .doc(widget.tripPlanId)
          .collection('tripDestinations')
          .doc(widget.destinationID) // Use destinationID as the document ID
          .collection('tripAccommodations')
          .add({
        'accommodationName': widget.accommodation['name'],
        'price': widget.accommodation['price'],
        'description': widget.accommodation['description'],
        'imageurl': widget.accommodation['imageUrl'],
        'destinationID': widget.destinationID,
        'destinationName': widget.destinationName,
        'userID': user.uid, // Add the userID
        'bookedAt': FieldValue.serverTimestamp(),
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Accommodation booked successfully!')),
      );

      Navigator.pop(context); // Return to the previous screen
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error booking accommodation: $e')),
      );
    }
  }

  void _showConfirmationDialog() {
    final TextEditingController daysController = TextEditingController();
    int selectedRooms = 1; // Default to 1 room
    double updatedPrice = (widget.accommodation['price'] as num).toDouble();

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            void calculatePrice() {
              final int days = int.tryParse(daysController.text) ?? 1;

              setState(() {
                updatedPrice =
                    (widget.accommodation['price'] as num).toDouble() *
                        days *
                        selectedRooms;
              });
            }

            return AlertDialog(
              title: const Text("Booking Details"),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: daysController,
                      decoration: const InputDecoration(
                        labelText: 'Number of Days',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.number,
                      onChanged: (value) => calculatePrice(),
                    ),
                    const SizedBox(height: 16),
                    // Dropdown for Number of Rooms
                    DropdownButtonFormField<int>(
                      value: selectedRooms,
                      decoration: const InputDecoration(
                        labelText: 'Number of Rooms',
                        border: OutlineInputBorder(),
                      ),
                      items: [1, 2].map((int value) {
                        return DropdownMenuItem<int>(
                          value: value,
                          child: Text('$value Room${value > 1 ? 's' : ''}'),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() {
                          selectedRooms = value!;
                          calculatePrice();
                        });
                      },
                    ),
                    const SizedBox(height: 20),
                    Text(
                      'Total Price: ${updatedPrice.toStringAsFixed(2)} PKR',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.green,
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    final int days = int.tryParse(daysController.text) ?? 1;

                    try {
                      await FirebaseFirestore.instance
                          .collection('tripPlans')
                          .doc(widget.tripPlanId)
                          .collection('tripDestinations')
                          .doc(widget.destinationID)
                          .collection('tripAccommodations')
                          .add({
                        ...widget.accommodation,
                        'days': days,
                        'rooms': selectedRooms,
                        'totalPrice': updatedPrice,
                        'bookedAt': Timestamp.now(), // Fixed typo here
                      });

                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Booking confirmed!')),
                      );
                      Navigator.pop(context); // Close dialog
                      Navigator.pop(context, true); // Return to previous screen
                    } catch (e) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Booking failed: $e')),
                      );
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.black,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Confirm Booking'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    List<String> images =
        List<String>.from(widget.accommodation['images'] ?? []);
    print(widget.accommodation);

    // Use null-aware operators to handle null values
    String accommodationName = widget.accommodation['name'] ?? 'Unknown Name';
    String accommodationDescription =
        widget.accommodation['description'] ?? 'No description available';
    String accommodationPrice =
        widget.accommodation['price']?.toString() ?? 'Price not available';
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(widget.accommodation['name'] ?? 'Hotel Details'),
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
          custom.NavigationBar(),

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
                          "Book your stay at ${widget.accommodation['name']} in ${widget.accommodation['destination'] ?? 'Amazing Location'}",
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
                                "${widget.accommodation['rating'] ?? '4.5'} Rating"),
                            _buildInfoItem(Icons.king_bed,
                                "${widget.accommodation['rooms'] ?? '1'} Rooms"),
                            _buildInfoItem(Icons.price_change,
                                "PKR ${widget.accommodation['price']} /night"),
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
                          widget.accommodation['name'] ?? 'No Name',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 10),
                        // Price
                        Text(
                          "PKR ${widget.accommodation['price']} per night",
                          style: TextStyle(
                            fontSize: 18,
                            color: Colors.green,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 10),
                        // Description
                        Text(
                          widget.accommodation['description'] ?? '',
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
                              // Call the booking function
                              _showConfirmationDialog();
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
