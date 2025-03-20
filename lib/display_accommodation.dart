import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'book_accommodation.dart';

class DisplayAccommodationsScreen extends StatefulWidget {
  final String destinationID;
  final String destinationName;
  final String tripPlanId;

  const DisplayAccommodationsScreen({
    super.key,
    required this.destinationID,
    required this.destinationName,
    required this.tripPlanId,
  });

  @override
  State<DisplayAccommodationsScreen> createState() =>
      _DisplayAccommodationsScreenState();
}

class _DisplayAccommodationsScreenState
    extends State<DisplayAccommodationsScreen> {
  // Fetch accommodations based on destinationName
  Stream<QuerySnapshot> _fetchAccommodations() {
    return FirebaseFirestore.instance
        .collection(
            'accommodations') // Ensure this matches your Firestore collection name
        .where('destination',
            isEqualTo: widget.destinationName) // Match destination name
        .snapshots();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Accommodations in ${widget.destinationName}'),
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _fetchAccommodations(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(
              child: Text('No accommodations found for this destination.'),
            );
          }

          final accommodations = snapshot.data!.docs;

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: accommodations.length,
            itemBuilder: (context, index) {
              final accommodation =
                  accommodations[index].data() as Map<String, dynamic>;

              return _buildAccommodationCard(accommodation);
            },
          );
        },
      ),
    );
  }

  // Build a card for each accommodation
  Widget _buildAccommodationCard(Map<String, dynamic> accommodation) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Small Image on the Left
            if (accommodation['imageurl'] != null)
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.network(
                  accommodation['imageurl'],
                  width: 80, // Small width
                  height: 100, // Small height
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      width: 80,
                      height: 80,
                      color: Colors.grey[200],
                      alignment: Alignment.center,
                      child: const Icon(
                        Icons.image,
                        color: Colors.grey,
                        size: 30,
                      ),
                    );
                  },
                  loadingBuilder: (context, child, loadingProgress) {
                    if (loadingProgress == null) return child;
                    return Container(
                      width: 80,
                      height: 80,
                      alignment: Alignment.center,
                      child: CircularProgressIndicator(
                        value: loadingProgress.expectedTotalBytes != null
                            ? loadingProgress.cumulativeBytesLoaded /
                                loadingProgress.expectedTotalBytes!
                            : null,
                      ),
                    );
                  },
                ),
              ),
            const SizedBox(width: 16), // Space between image and details

            // Accommodation Details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Accommodation Name
                  Text(
                    accommodation['name'] ?? 'No Name',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),

                  // Accommodation Price
                  Text(
                    '\$${accommodation['price'] ?? 'N/A'} per night',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.green[700],
                    ),
                  ),
                  const SizedBox(height: 8),

                  // Accommodation Description
                  if (accommodation['description'] != null)
                    Text(
                      accommodation['description'],
                      style: const TextStyle(
                        fontSize: 14,
                        color: Colors.grey,
                      ),
                    ),
                  const SizedBox(height: 16),

                  // Select Button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        // Navigate to BookAccommodationScreen with the selected accommodation
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => book_accommodation(
                              accommodation:
                                  accommodation, // Pass the selected accommodation
                              destinationID: widget.destinationID,
                              destinationName: widget.destinationName,
                              tripPlanId: widget.tripPlanId,
                            ),
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.black,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: const Text(
                        'SELECT',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
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
    );
  }
}
