import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'custom_navbar.dart' as custom;
import 'view_destination.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  // State variable for search query
  String searchQuery = '';
  final TextEditingController searchController = TextEditingController();

  // Use this to control the overall list height
  final double _gridHeight = 600; // Adjust based on your needs

  @override
  void dispose() {
    // Clean up the controller when the widget is disposed
    searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Row(
          children: [
            // Vertical Navigation Bar with text labels
            const custom.NavigationBar(),
            // Main Content
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildHeaderSection(context),
                    _buildSearchSection(context),
                    _buildDiscoverySection(context),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeaderSection(BuildContext context) {
    return Stack(
      children: [
        Container(
          height: 200,
          width: double.infinity,
          decoration: BoxDecoration(
            image: DecorationImage(
              image: AssetImage('images/bg3.jpg'),
              fit: BoxFit.cover,
            ),
          ),
        ),
        Positioned.fill(
          child: Container(
            color: Colors.black.withOpacity(0.3),
            alignment: Alignment.center,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: Colors.black,
                textStyle: TextStyle(fontSize: 20, fontWeight: FontWeight.w900),
                padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              ),
              onPressed: () {},
              child: Text('PLAN YOUR PERFECT TRIP WITH AI'),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDiscoverySection(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Discover on your own',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 10),
          SizedBox(
            height: _gridHeight, // Fixed height container
            child: StreamBuilder(
              stream: FirebaseFirestore.instance
                  .collection('destinations')
                  .snapshots(),
              builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(child: CircularProgressIndicator());
                }
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return _buildEmptyState('No destinations found');
                }

                // Filter documents based on search query
                var filteredDocs = snapshot.data!.docs;
                if (searchQuery.isNotEmpty) {
                  filteredDocs = filteredDocs.where((doc) {
                    Map<String, dynamic> data =
                        doc.data() as Map<String, dynamic>;
                    String name = (data['name'] ?? '').toString().toLowerCase();

                    // Search by name
                    bool matchesName = name.contains(searchQuery.toLowerCase());

                    // Search by keywords
                    bool matchesKeywords = false;
                    if (data.containsKey('searchKeywords')) {
                      List<String> keywords =
                          List<String>.from(data['searchKeywords'] ?? []);
                      matchesKeywords = keywords.any((keyword) => keyword
                          .toLowerCase()
                          .contains(searchQuery.toLowerCase()));
                    }

                    // Return true if either condition is met
                    return matchesName || matchesKeywords;
                  }).toList();
                }
                // If no results after filtering
                if (filteredDocs.isEmpty) {
                  return _buildEmptyState(
                      'No destinations found for your search');
                }

                return GridView.builder(
                  shrinkWrap: true,
                  physics:
                      const AlwaysScrollableScrollPhysics(), // Changed from NeverScrollableScrollPhysics
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 10,
                    mainAxisSpacing: 10,
                    childAspectRatio: 3 / 2,
                  ),
                  itemCount: filteredDocs.length,
                  itemBuilder: (context, index) {
                    var doc = filteredDocs[index];
                    Map<String, dynamic> data =
                        doc.data() as Map<String, dynamic>;

                    String imageUrl = data['imageUrl'] ?? 'images/img1.jpg';
                    String name = data['name'] ?? 'Unknown';
                    double rating = (data['rating'] ?? 0.0).toDouble();
                    String destinationID = doc.id;

                    return _buildDestinationCard(
                      context,
                      destinationID,
                      imageUrl,
                      name,
                      rating,
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // Helper method to create consistent empty state UI
  Widget _buildEmptyState(String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search_off, size: 48, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              message,
              style: TextStyle(fontSize: 16, color: Colors.grey[700]),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchSection(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        children: [
          // Search box - takes most of the space
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(10),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: TextField(
                controller: searchController, // Use the class-level controller
                decoration: InputDecoration(
                  hintText: 'Search destinations...',
                  prefixIcon: const Icon(Icons.search, color: Colors.black54),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(vertical: 15),
                ),
                onSubmitted: (value) {
                  setState(() {
                    searchQuery = value;
                  });
                },
              ),
            ),
          ),
          // Search button
          SizedBox(width: 10),
          Container(
            decoration: BoxDecoration(
              color: Colors.black,
              borderRadius: BorderRadius.circular(10),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 10,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: IconButton(
              icon: const Icon(Icons.search, color: Colors.white),
              onPressed: () {
                setState(() {
                  searchQuery = searchController.text;
                });
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, bool isSelected) {
    return Padding(
      padding: const EdgeInsets.only(right: 8.0),
      child: FilterChip(
        label: Text(label),
        selected: isSelected,
        onSelected: (selected) {
          // Handle filter selection
        },
        backgroundColor: Colors.white,
        selectedColor: Colors.black,
        labelStyle: TextStyle(
          color: isSelected ? Colors.white : Colors.black,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: Colors.grey[300]!),
        ),
      ),
    );
  }

  void _showFilterDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Filter Options'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Price Range',
                    style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 10),
                RangeSlider(
                  values: const RangeValues(100, 1000),
                  min: 0,
                  max: 2000,
                  divisions: 20,
                  labels: const RangeLabels('\$100', '\$1000'),
                  onChanged: (RangeValues values) {
                    // Update price range
                  },
                ),
                const SizedBox(height: 15),
                const Text('Rating',
                    style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: List.generate(5, (index) {
                    return GestureDetector(
                      onTap: () {
                        // Handle star rating selection
                      },
                      child: Icon(
                        Icons.star,
                        color: index < 4 ? Colors.amber : Colors.grey,
                        size: 30,
                      ),
                    );
                  }),
                ),
                const SizedBox(height: 15),
                const Text('Categories',
                    style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8.0,
                  runSpacing: 8.0,
                  children: [
                    _buildFilterChip('Beach', false),
                    _buildFilterChip('Mountain', false),
                    _buildFilterChip('City', true),
                    _buildFilterChip('Historical', false),
                    _buildFilterChip('Adventure', false),
                    _buildFilterChip('Cultural', false),
                  ],
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('CANCEL'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.black,
                foregroundColor: Colors.white,
              ),
              child: const Text('APPLY'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildDestinationCard(
    BuildContext context,
    String destinationID,
    String imageUrl,
    String name,
    double rating,
  ) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.vertical(top: Radius.circular(10)),
              child: _buildImage(imageUrl),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Flexible(
                  child: Text(
                    name,
                    style: TextStyle(fontWeight: FontWeight.bold),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Row(
                  children: [
                    Icon(Icons.star, color: Colors.amber, size: 16),
                    Text(
                      rating.toString(),
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(8.0, 4.0, 8.0, 8.0),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ViewDestinationScreen(
                        destinationID: destinationID,
                        imageUrl: imageUrl,
                        name: name,
                        rating: rating,
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
                  padding: EdgeInsets.symmetric(vertical: 8.0),
                ),
                child: Text(
                  'EXPLORE',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImage(String imageUrl) {
    if (imageUrl.startsWith('http')) {
      return Image.network(
        imageUrl,
        fit: BoxFit.cover,
        width: double.infinity,
        errorBuilder: (context, error, stackTrace) {
          return Container(
            color: Colors.grey[200],
            child: Icon(Icons.image, color: Colors.grey[600], size: 50),
          );
        },
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return Center(
            child: CircularProgressIndicator(
              value: loadingProgress.expectedTotalBytes != null
                  ? loadingProgress.cumulativeBytesLoaded /
                      loadingProgress.expectedTotalBytes!
                  : null,
            ),
          );
        },
      );
    } else {
      return Image.asset(
        imageUrl,
        fit: BoxFit.cover,
        width: double.infinity,
        errorBuilder: (context, error, stackTrace) {
          return Container(
            color: Colors.grey[200],
            child: Icon(Icons.broken_image, color: Colors.grey[600], size: 50),
          );
        },
      );
    }
  }
}
