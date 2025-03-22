import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'custom_navbar.dart' as custom;
import 'add_to_existing_plan.dart';
import 'create_trip_plan.dart';
import 'submit_review.dart';
import 'display_reviews.dart';
import 'package:cached_network_image/cached_network_image.dart';

class ViewDestinationScreen extends StatelessWidget {
  final String destinationID;
  final String imageUrls;
  final String name;
  final double rating;

  const ViewDestinationScreen({
    super.key,
    required this.destinationID,
    required this.imageUrls,
    required this.name,
    required this.rating,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Row(
          children: [
            // Vertical Navigation Bar with text labels - reusing existing NavigationBar
            const custom.NavigationBar(),

            // Main Content
            Expanded(
              child: FutureBuilder<DocumentSnapshot>(
                future: FirebaseFirestore.instance
                    .collection('destinations')
                    .doc(destinationID)
                    .get(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return Center(child: CircularProgressIndicator());
                  }

                  if (!snapshot.hasData || !snapshot.data!.exists) {
                    return Center(child: Text('Destination not found'));
                  }

                  Map<String, dynamic> data =
                      snapshot.data!.data() as Map<String, dynamic>;

                  String description =
                      data['description'] ?? 'No description available';
                  String ttv = data['ttv'] ?? 'Not specified';
                  String weather = data['weather'] ?? 'Not specified';

                  return SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Hero image at the top
                        _buildHeroImage(),

                        // Destination name and rating
                        _buildNameRatingSection(),

                        // Description and details
                        _buildDescriptionSection(description, ttv, weather),

                        // Local Attractions section
                        _buildLocalAttractionsSection(),

                        // Reviews section
                        _buildReviewsSection(context),

                        // Action buttons at the bottom
                        _buildActionButtons(context),

                        // Bottom padding
                        SizedBox(height: 20),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeroImage() {
    return SizedBox(
      height: 250,
      width: double.infinity,
      child: imageUrls.startsWith('http')
          ? Image.network(
              imageUrls,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  color: Colors.grey[200],
                  child: Icon(Icons.image, color: Colors.grey[600], size: 50),
                );
              },
            )
          : Image.asset(
              imageUrls,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  color: Colors.grey[200],
                  child: Icon(Icons.broken_image,
                      color: Colors.grey[600], size: 50),
                );
              },
            ),
    );
  }

  Widget _buildNameRatingSection() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(
              name,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          Row(
            children: [
              Icon(Icons.star, color: Colors.amber),
              SizedBox(width: 4),
              Text(
                rating.toString(),
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDescriptionSection(
      String description, String ttv, String weather) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'About this destination',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 8),
          Text(
            description,
            style: TextStyle(
              fontSize: 16,
              color: Colors.black87,
            ),
          ),
          SizedBox(height: 16),

          // Additional information
          Row(
            children: [
              Expanded(
                child: _infoCard(
                  'Best time to visit',
                  ttv,
                  Icons.calendar_today,
                ),
              ),
              SizedBox(width: 16),
              Expanded(
                child: _infoCard(
                  'Weather',
                  weather,
                  Icons.wb_sunny,
                ),
              ),
            ],
          ),
          SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildLocalAttractionsSection() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Local Attractions and Activities',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 16),

          // Fetch local attractions from Firestore
          StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection(
                    'destinations') // Access the destinations collection
                .doc(destinationID) // Select the specific destination document
                .collection(
                    'localAttractions') // Fetch the localAttractions subcollection
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return Center(child: CircularProgressIndicator());
              }

              if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                return Container(
                  padding: EdgeInsets.symmetric(vertical: 16),
                  child: Text(
                    'No local attractions found for this destination.',
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 16,
                    ),
                  ),
                );
              }

              // Display attractions in a vertical list with horizontal cards
              return ListView.builder(
                physics: NeverScrollableScrollPhysics(),
                shrinkWrap: true,
                itemCount: snapshot.data!.docs.length,
                itemBuilder: (context, i) {
                  var attractionData =
                      snapshot.data!.docs[i].data() as Map<String, dynamic>;

                  String attractionName =
                      attractionData['name'] ?? 'Unnamed Attraction';
                  String attractionImageUrl = attractionData['imageUrl'] ?? '';
                  String attractionDescription =
                      attractionData['description'] ??
                          'No description available';

                  return _buildAttractionCardHorizontal(
                    context,
                    attractionName,
                    attractionImageUrl,
                    attractionDescription,
                  );
                },
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildAttractionCardHorizontal(
    BuildContext context,
    String name,
    String imageUrl,
    String description,
  ) {
    return Container(
      margin: EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Attraction image - left side
          ClipRRect(
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(10),
              bottomLeft: Radius.circular(10),
            ),
            child: Container(
              height: 120,
              width: 120,
              child: imageUrl.isNotEmpty
                  ? Image.network(
                      imageUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          color: Colors.grey[200],
                          child: Icon(Icons.image,
                              size: 40, color: Colors.grey[600]),
                        );
                      },
                    )
                  : Container(
                      color: Colors.grey[200],
                      child:
                          Icon(Icons.place, size: 40, color: Colors.grey[600]),
                    ),
            ),
          ),

          // Attraction information - right side
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(12.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Attraction name
                  Text(
                    name,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),

                  // Optional: You could add a category or tag here with a colored label
                  Container(
                    margin: EdgeInsets.only(top: 6, bottom: 8),
                    padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.green[100],
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      'Popular Attraction',
                      style: TextStyle(
                        color: Colors.green[800],
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),

                  // Description - limited to 2 lines with ellipsis
                  Text(
                    description,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[700],
                      height: 1.3,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

// Update the attraction section to use the horizontal card

  Widget _infoCard(String title, String value, IconData icon) {
    return Container(
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: Colors.black54),
              SizedBox(width: 8),
              Text(
                title,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Colors.black54,
                ),
              ),
            ],
          ),
          SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReviewsSection(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Reviews',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              ElevatedButton(
                onPressed: () {
                  // Add review functionality
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => SubmitReviewPage(
                        destinationID: destinationID,
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
                child: Text('Add'),
              ),
            ],
          ),
          SizedBox(height: 16),

          // Reviews list
          StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('reviews')
                .where('destinationID', isEqualTo: destinationID)
                .orderBy('timestamp', descending: true)
                .limit(5)
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return Center(child: CircularProgressIndicator());
              }

              if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                return Container(
                  padding: EdgeInsets.symmetric(vertical: 24),
                  alignment: Alignment.center,
                  child: Text(
                    'No reviews yet. Be the first to review!',
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 16,
                    ),
                  ),
                );
              }

              return ListView.builder(
                physics: NeverScrollableScrollPhysics(),
                shrinkWrap: true,
                itemCount: snapshot.data!.docs.length,
                itemBuilder: (context, index) {
                  var reviewData =
                      snapshot.data!.docs[index].data() as Map<String, dynamic>;

                  // Using email directly from the review document
                  String userEmail =
                      reviewData['userEmail'] ?? 'Anonymous User';
                  double reviewRating =
                      (reviewData['rating'] as num?)?.toDouble() ?? 5.0;
                  String reviewText = reviewData['text'] ?? 'No comment';
                  DateTime reviewTimestamp = reviewData['timestamp'] != null
                      ? (reviewData['timestamp'] as Timestamp).toDate()
                      : DateTime.now();

                  return Column(
                    children: [
                      _buildReviewItem(
                        userEmail,
                        reviewRating,
                        reviewText,
                        reviewTimestamp,
                        context,
                      ),
                      Divider(),
                    ],
                  );
                },
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildReviewItem(String userEmail, double rating, String comment,
      DateTime timestamp, BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  userEmail,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Row(
                children: [
                  Icon(Icons.star, color: Colors.amber, size: 18),
                  SizedBox(width: 4),
                  Text(
                    rating.toString(),
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ],
          ),
          SizedBox(height: 4),
          Text(
            comment,
            style: TextStyle(
              fontSize: 14,
            ),
          ),
          SizedBox(height: 4),
          Text(
            '${timestamp.day}/${timestamp.month}/${timestamp.year}',
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ElevatedButton(
            onPressed: () {
              // Navigate to CreateTripPlanScreen
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => CreateTripPlanScreen(
                    destinationID: destinationID,
                    destinationName: name,
                  ),
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.black,
              foregroundColor: Colors.white,
              padding: EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: Text(
              'Create Trip Plan',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          SizedBox(height: 12),
          OutlinedButton(
            onPressed: () {
              // Navigate to AddDestinationToExistingTripScreen
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => AddDestinationToExistingTripScreen(
                    destinationID: destinationID,
                    destinationName: name,
                  ),
                ),
              );
            },
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.black,
              side: BorderSide(color: Colors.black),
              padding: EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: Text(
              'Add to Existing Trip Plan',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
