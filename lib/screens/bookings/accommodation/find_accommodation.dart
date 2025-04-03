import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'view_accommodation.dart';
import '../../../widgets/navigation/custom_navbar.dart' as cn; // Import your custom NavigationBar

class FindAccommodationScreen extends StatefulWidget {
  const FindAccommodationScreen({super.key});

  @override
  _FindAccommodationScreenState createState() =>
      _FindAccommodationScreenState();
}

class _FindAccommodationScreenState extends State<FindAccommodationScreen> {
  final TextEditingController _searchController = TextEditingController();
  List<QueryDocumentSnapshot> _accommodations = [];
  List<QueryDocumentSnapshot> _allAccommodations = [];

  // Price range filter
  int? _minPrice;
  int? _maxPrice;

  @override
  void initState() {
    super.initState();
    _fetchAllAccommodations(); // Fetch all accommodations initially
  }

  void _fetchAllAccommodations() async {
    try {
      QuerySnapshot querySnapshot =
          await FirebaseFirestore.instance.collection('accommodations').get();

      setState(() {
        _allAccommodations = querySnapshot.docs;
        _accommodations =
            _allAccommodations; // Display all accommodations initially
      });
    } catch (e) {
      print("Error fetching all accommodations: $e");
    }
  }

  void _searchAccommodation() async {
    String searchQuery = _searchController.text.trim().toLowerCase();
    if (searchQuery.isEmpty) {
      // If search bar is empty, show all accommodations
      setState(() {
        _accommodations = _allAccommodations;
      });
      return;
    }

    try {
      // Filter accommodations based on the search query
      List<QueryDocumentSnapshot> filteredAccommodations =
          _allAccommodations.where((doc) {
        var accommodation = doc.data() as Map<String, dynamic>;
        String destination =
            accommodation['destination']?.toString().toLowerCase() ?? '';
        return destination.contains(searchQuery);
      }).toList();

      setState(() {
        _accommodations = filteredAccommodations;
      });
    } catch (e) {
      print("Error filtering accommodations: $e");
    }
  }

  void _applyPriceFilter() async {
    // Show a dialog to get min and max price
    final priceRange = await showDialog<Map<String, int>>(
      context: context,
      builder: (context) {
        final TextEditingController minPriceController =
            TextEditingController();
        final TextEditingController maxPriceController =
            TextEditingController();

        return AlertDialog(
          title: Text("Enter Price Range"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: minPriceController,
                decoration: InputDecoration(
                  labelText: "Minimum Price (PKR)",
                ),
                keyboardType: TextInputType.number,
              ),
              SizedBox(height: 10),
              TextField(
                controller: maxPriceController,
                decoration: InputDecoration(
                  labelText: "Maximum Price (PKR)",
                ),
                keyboardType: TextInputType.number,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context); // Close the dialog
              },
              child: Text("Cancel"),
            ),
            TextButton(
              onPressed: () {
                int minPrice = int.tryParse(minPriceController.text) ?? 0;
                int maxPrice = int.tryParse(maxPriceController.text) ?? 0;

                if (minPrice > 0 && maxPrice > 0 && maxPrice >= minPrice) {
                  Navigator.pop(context, {
                    'minPrice': minPrice,
                    'maxPrice': maxPrice,
                  });
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text("Invalid price range. Please try again."),
                    ),
                  );
                }
              },
              child: Text("Apply"),
            ),
          ],
        );
      },
    );

    if (priceRange != null) {
      setState(() {
        _minPrice = priceRange['minPrice'];
        _maxPrice = priceRange['maxPrice'];
      });

      // Apply price filter
      List<QueryDocumentSnapshot> filteredAccommodations =
          _allAccommodations.where((doc) {
        var accommodation = doc.data() as Map<String, dynamic>;
        int price = accommodation['price'] ?? 0;
        return price >= _minPrice! && price <= _maxPrice!;
      }).toList();

      setState(() {
        _accommodations = filteredAccommodations;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Row(
        children: [
          const cn.NavigationBar(),

          // Main Content
          Expanded(
            child: Scaffold(
              backgroundColor: Colors.white,
              appBar: AppBar(
                backgroundColor: Colors.blueGrey,
                title: Text(
                  "Find Accommodation",
                  style: TextStyle(color: Colors.white),
                ),
                iconTheme: IconThemeData(color: Colors.white),
              ),
              body: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Stack(
                      children: [
                        Container(
                          width: double.infinity,
                          height: 200, // Reduced height to accommodate AppBar
                          decoration: BoxDecoration(
                            image: DecorationImage(
                              image: AssetImage('images/bg1.jpg'),
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                        Positioned(
                          top: 80,
                          left: 0,
                          right: 0,
                          child: Center(
                            child: Text(
                              "Find Your Perfect Stay",
                              style: TextStyle(
                                fontSize: 28,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                                shadows: [
                                  Shadow(
                                    blurRadius: 5,
                                    color: Colors.black54,
                                    offset: Offset(2, 2),
                                  )
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        children: [
                          TextField(
                            controller: _searchController,
                            decoration: InputDecoration(
                              labelText: "Search Destination",
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(20),
                              ),
                              prefixIcon:
                                  Icon(Icons.search, color: Colors.blueGrey),
                              filled: true,
                              fillColor: Colors.grey[200],
                            ),
                          ),
                          SizedBox(height: 10),
                          ElevatedButton(
                            onPressed: _searchAccommodation,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blueGrey,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            child: Text(
                              "Search",
                              style: TextStyle(color: Colors.white),
                            ),
                          ),
                          SizedBox(height: 20),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.start,
                            children: [
                              Text(
                                "Filter by:",
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                              SizedBox(width: 10),
                              FilterChip(
                                label: Text("Price"),
                                selected:
                                    _minPrice != null && _maxPrice != null,
                                onSelected: (selected) {
                                  _applyPriceFilter();
                                },
                                backgroundColor: Colors.grey[200],
                                avatar: Icon(Icons.attach_money, size: 18),
                              ),
                            ],
                          ),
                          SizedBox(height: 10),
                          _accommodations.isNotEmpty
                              ? ListView.builder(
                                  shrinkWrap: true,
                                  physics: NeverScrollableScrollPhysics(),
                                  itemCount: _accommodations.length,
                                  itemBuilder: (context, index) {
                                    var accommodation = _accommodations[index]
                                        .data() as Map<String, dynamic>;
                                    String imageUrl =
                                        accommodation['imageurl'] ?? '';

                                    return AccommodationCard(
                                      name: accommodation['name'] ?? 'No Name',
                                      type: accommodation['type'] ?? 'No Type',
                                      price:
                                          "PKR ${accommodation['price']} per night",
                                      description:
                                          accommodation['description'] ?? '',
                                      imageUrl: imageUrl,
                                      onViewPressed: () {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (context) =>
                                                bookAccommodation(
                                              accommodation: accommodation,
                                            ),
                                          ),
                                        );
                                      },
                                    );
                                  },
                                )
                              : Padding(
                                  padding: const EdgeInsets.all(20.0),
                                  child: Column(
                                    children: [
                                      Icon(
                                        Icons.search_off,
                                        size: 60,
                                        color: Colors.grey,
                                      ),
                                      SizedBox(height: 10),
                                      Text(
                                        "No accommodations found",
                                        style: TextStyle(
                                          fontSize: 16,
                                          color: Colors.grey,
                                        ),
                                      ),
                                      Text(
                                        "Try searching for a different destination",
                                        style: TextStyle(
                                          fontSize: 14,
                                          color: Colors.grey,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class AccommodationCard extends StatelessWidget {
  final String name;
  final String type;
  final String price;
  final String description;
  final String imageUrl;
  final VoidCallback onViewPressed;

  const AccommodationCard({
    super.key,
    required this.name,
    required this.type,
    required this.price,
    required this.description,
    required this.imageUrl,
    required this.onViewPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.symmetric(vertical: 10, horizontal: 5),
      elevation: 5,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
      ),
      child: Padding(
        padding: const EdgeInsets.all(10.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Accommodation Image
            imageUrl.isNotEmpty
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: Image.network(
                      imageUrl,
                      width: 120,
                      height: 120,
                      fit: BoxFit.cover,
                    ),
                  )
                : Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      Icons.image_not_supported,
                      color: Colors.grey[600],
                    ),
                  ),
            SizedBox(width: 10),
            // Accommodation Details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          name,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                          ),
                        ),
                      ),
                      IconButton(
                        icon: Icon(Icons.favorite_border),
                        color: Colors.redAccent,
                        onPressed: () {
                          // Add to favorites functionality
                        },
                      ),
                    ],
                  ),
                  SizedBox(height: 5),
                  Text(
                    price,
                    style: TextStyle(
                      color: Colors.green,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 5),
                  Text(
                    type,
                    style: TextStyle(
                      color: Colors.grey[700],
                      fontSize: 14,
                    ),
                  ),
                  SizedBox(height: 5),
                  Text(
                    description,
                    style: TextStyle(color: Colors.grey[700]),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: 10),
                  // View Button
                  Align(
                    alignment: Alignment.centerRight,
                    child: ElevatedButton(
                      onPressed: onViewPressed,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blueGrey,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: Text(
                        "View",
                        style: TextStyle(color: Colors.white),
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
