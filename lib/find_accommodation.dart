import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'bookAccommodation.dart';
import 'custom_navbar.dart' as cn; // Import your custom NavigationBar

class FindAccommodationScreen extends StatefulWidget {
  const FindAccommodationScreen({super.key});

  @override
  _FindAccommodationScreenState createState() =>
      _FindAccommodationScreenState();
}

class _FindAccommodationScreenState extends State<FindAccommodationScreen> {
  final TextEditingController _searchController = TextEditingController();
  List<QueryDocumentSnapshot> _accommodations = [];

  void _searchAccommodation() async {
    String searchQuery = _searchController.text.trim().toLowerCase();
    if (searchQuery.isEmpty) return;

    try {
      QuerySnapshot querySnapshot =
          await FirebaseFirestore.instance.collection('accommodations').get();

      List<QueryDocumentSnapshot> filteredAccommodations =
          querySnapshot.docs.where((doc) {
        var accommodation = doc.data() as Map<String, dynamic>;
        String destination =
            accommodation['destination']?.toString().toLowerCase() ?? '';
        return destination.contains(searchQuery);
      }).toList();

      setState(() {
        _accommodations = filteredAccommodations;
      });
    } catch (e) {
      print("Error fetching data: $e");
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
                                onSelected: (selected) {},
                                backgroundColor: Colors.grey[200],
                                avatar: Icon(Icons.attach_money, size: 18),
                              ),
                              SizedBox(width: 8),
                              FilterChip(
                                label: Text("Rating"),
                                onSelected: (selected) {},
                                backgroundColor: Colors.grey[200],
                                avatar: Icon(Icons.star, size: 18),
                              ),
                              SizedBox(width: 8),
                              FilterChip(
                                label: Text("Amenities"),
                                onSelected: (selected) {},
                                backgroundColor: Colors.grey[200],
                                avatar: Icon(Icons.hotel, size: 18),
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

                                    return Card(
                                      margin: EdgeInsets.symmetric(
                                          vertical: 10, horizontal: 5),
                                      elevation: 5,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(15),
                                      ),
                                      child: Padding(
                                        padding: const EdgeInsets.all(10.0),
                                        child: Row(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            // Hotel Image
                                            imageUrl.isNotEmpty
                                                ? ClipRRect(
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            10),
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
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                              10),
                                                    ),
                                                    child: Icon(
                                                      Icons.image_not_supported,
                                                      color: Colors.grey[600],
                                                    ),
                                                  ),
                                            SizedBox(width: 10),
                                            // Hotel Details
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  Row(
                                                    mainAxisAlignment:
                                                        MainAxisAlignment
                                                            .spaceBetween,
                                                    children: [
                                                      Expanded(
                                                        child: Text(
                                                          accommodation[
                                                                  'name'] ??
                                                              'No Name',
                                                          style: TextStyle(
                                                            fontWeight:
                                                                FontWeight.bold,
                                                            fontSize: 18,
                                                          ),
                                                        ),
                                                      ),
                                                      IconButton(
                                                        icon: Icon(Icons
                                                            .favorite_border),
                                                        color: Colors.redAccent,
                                                        onPressed: () {
                                                          // Add to favorites functionality
                                                        },
                                                      ),
                                                    ],
                                                  ),
                                                  SizedBox(height: 5),
                                                  Text(
                                                    "PKR ${accommodation['price']} per night",
                                                    style: TextStyle(
                                                      color: Colors.green,
                                                      fontWeight:
                                                          FontWeight.bold,
                                                    ),
                                                  ),
                                                  SizedBox(height: 5),
                                                  Text(
                                                    accommodation[
                                                            'description'] ??
                                                        '',
                                                    style: TextStyle(
                                                        color:
                                                            Colors.grey[700]),
                                                    maxLines: 2,
                                                    overflow:
                                                        TextOverflow.ellipsis,
                                                  ),
                                                  SizedBox(height: 10),
                                                  // View Button
                                                  Align(
                                                    alignment:
                                                        Alignment.centerRight,
                                                    child: ElevatedButton(
                                                      onPressed: () {
                                                        Navigator.push(
                                                          context,
                                                          MaterialPageRoute(
                                                            builder: (context) =>
                                                                bookAccommodation(
                                                              accommodation:
                                                                  accommodation,
                                                            ),
                                                          ),
                                                        );
                                                      },
                                                      style: ElevatedButton
                                                          .styleFrom(
                                                        backgroundColor:
                                                            Colors.blueGrey,
                                                        shape:
                                                            RoundedRectangleBorder(
                                                          borderRadius:
                                                              BorderRadius
                                                                  .circular(10),
                                                        ),
                                                      ),
                                                      child: Text(
                                                        "View",
                                                        style: TextStyle(
                                                            color:
                                                                Colors.white),
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
