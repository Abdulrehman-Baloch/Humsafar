import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'custom_navbar.dart' as custom;

class SearchTransportationScreen extends StatefulWidget {
  const SearchTransportationScreen({super.key});

  @override
  SearchTransportationScreenState createState() =>
      SearchTransportationScreenState();
}

class SearchTransportationScreenState
    extends State<SearchTransportationScreen> {
  final TextEditingController _sourceController = TextEditingController();
  final TextEditingController _destinationController = TextEditingController();
  final TextEditingController _minPriceController = TextEditingController();
  final TextEditingController _maxPriceController = TextEditingController();

  String _selectedTransportMode = "All";
  List<Map<String, dynamic>> _transportResults = [];
  bool _isLoading = false;
  bool _showAdvancedFilters = false;

  final List<String> transportModes = ["All", "Bus", "Train", "Airplane"];

  @override
  void initState() {
    super.initState();
    // Load all transportation data when the screen initializes
    fetchAllTransportOptions();
  }

  /// Fetch all transport options without any filters
  Future<void> fetchAllTransportOptions() async {
    setState(() => _isLoading = true);

    try {
      QuerySnapshot querySnapshot =
          await FirebaseFirestore.instance.collection('transportation').get();

      List<Map<String, dynamic>> transportData = querySnapshot.docs.map((doc) {
        // Cast with safety check to avoid null issues
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        // Ensure all required fields exist with fallback values
        return {
          'departure': data['departure'] ?? 'Unknown',
          'destination': data['destination'] ?? 'Unknown',
          'type': data['type'] ?? 'Unknown',
          'price': data['price'] ?? 0,
          'class': data['class'] ?? 'Standard',
          'company': data['company'] ?? 'Unknown Provider',
          'departureTime': data['departureTime'],
          'scheduleType': data['scheduleType'] ?? 'Daily',
          // Add any other fields you need with appropriate defaults
        };
      }).toList();

      // Sort the transport data by destination
      transportData.sort((a, b) => (a['destination'] ?? 'Unknown')
          .toString()
          .compareTo((b['destination'] ?? 'Unknown').toString()));

      setState(() {
        _transportResults = transportData;
      });
    } catch (e) {
      print("Error fetching initial transport options: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Failed to load transportation data.")),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  /// Fetch transport options with filters
  Future<void> fetchTransportOptions() async {
    setState(() => _isLoading = true);

    String source = _sourceController.text.trim();
    String destination = _destinationController.text.trim();
    String minPriceText = _minPriceController.text.trim();
    String maxPriceText = _maxPriceController.text.trim();
    int? minPrice = minPriceText.isNotEmpty ? int.tryParse(minPriceText) : null;
    int? maxPrice = maxPriceText.isNotEmpty ? int.tryParse(maxPriceText) : null;

    try {
      Query query = FirebaseFirestore.instance.collection('transportation');

      if (_selectedTransportMode != "All") {
        query = query.where('type', isEqualTo: _selectedTransportMode);
      }
      if (source.isNotEmpty) {
        query = query.where('departure', isEqualTo: source);
      }
      if (destination.isNotEmpty) {
        query = query.where('destination', isEqualTo: destination);
      }
      if (minPrice != null) {
        query = query.where('price', isGreaterThanOrEqualTo: minPrice);
      }
      if (maxPrice != null) {
        query = query.where('price', isLessThanOrEqualTo: maxPrice);
      }

      QuerySnapshot querySnapshot = await query.get();
      List<Map<String, dynamic>> transportData = querySnapshot.docs.map((doc) {
        // Cast with safety check to avoid null issues
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        // Ensure all required fields exist with fallback values
        return {
          'departure': data['departure'] ?? 'Unknown',
          'destination': data['destination'] ?? 'Unknown',
          'type': data['type'] ?? 'Unknown',
          'price': data['price'] ?? 0,
          'class': data['class'] ?? 'Standard',
          'company': data['company'] ?? 'Unknown Provider',
          'departureTime': data['departureTime'],
          'scheduleType': data['scheduleType'] ?? 'Daily',
          // Add any other fields you need with appropriate defaults
        };
      }).toList();

      // Sort the transport data by destination
      transportData.sort((a, b) => (a['destination'] ?? 'Unknown')
          .toString()
          .compareTo((b['destination'] ?? 'Unknown').toString()));

      if (mounted) {
        setState(() {
          _transportResults = transportData;
        });

        if (_transportResults.isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("No transport options found.")),
          );
        }
      }
    } catch (e) {
      print("Error fetching transport options: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Failed to fetch transport options.")),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Row(
          // Keep the Row layout from your original code
          children: [
            // Navigation Bar on the left
            const custom.NavigationBar(),

            // Main Content on the right
            Expanded(
              child: Column(
                children: [
                  // Banner Section
                  Container(
                    color: Colors.blueGrey[700], // Grey background
                    padding: const EdgeInsets.symmetric(
                        vertical: 15, horizontal: 10),
                    child: Row(
                      children: [
                        IconButton(
                          icon: Icon(Icons.arrow_back, color: Colors.white),
                          onPressed: () =>
                              Navigator.pop(context), // Navigate back
                        ),
                        Expanded(
                          child: Text(
                            "Find Transportation",
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.normal,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  Expanded(
                    child: SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Stack Banner
                          Stack(
                            children: [
                              Container(
                                width: double.infinity,
                                height: 200,
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
                                  child: Container(
                                    padding: EdgeInsets.symmetric(
                                        vertical: 8, horizontal: 20),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(25),
                                    ),
                                    child: Text(
                                      "FIND YOUR PERFECT TRANSPORT",
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.black,
                                        letterSpacing: 1.0,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          _buildHeader(),
                          _buildMainSearchRow(),
                          if (_showAdvancedFilters) _buildAdvancedFilters(),
                          _buildSearchButton(),
                          _buildResultsSection(),
                        ],
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

  Widget _buildHeader() {
    return Container(
      padding: EdgeInsets.all(16.0),
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(15),
          bottomRight: Radius.circular(15),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 5,
            offset: Offset(0, 2),
          ),
        ],
      ),
    );
  }

  Widget _buildMainSearchRow() {
    return Container(
      margin: EdgeInsets.all(16),
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            spreadRadius: 1,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Spacer(),
              TextButton.icon(
                onPressed: () {
                  setState(() {
                    _showAdvancedFilters = !_showAdvancedFilters;
                  });
                },
                icon: Icon(
                  _showAdvancedFilters ? Icons.expand_less : Icons.expand_more,
                  color: Colors.blue,
                ),
                label: Text(
                  _showAdvancedFilters ? "Less Filters" : "More Filters",
                  style: TextStyle(color: Colors.blue),
                ),
              ),
            ],
          ),
          SizedBox(height: 16),
          Row(
            children: [
              // Departure field
              Expanded(
                child: _buildCompactTextInput(
                  "From",
                  _sourceController,
                  Icons.flight_takeoff_rounded,
                ),
              ),
              SizedBox(width: 16),
              // Destination field
              Expanded(
                child: _buildCompactTextInput(
                  "To",
                  _destinationController,
                  Icons.flight_land_rounded,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAdvancedFilters() {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16),
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            spreadRadius: 1,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Advanced Filters',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.black54,
            ),
          ),
          SizedBox(height: 16),
          Row(
            children: [
              // Transport mode dropdown
              Expanded(
                flex: 2,
                child: _buildTransportModeDropdown(),
              ),
              SizedBox(width: 12),
              // Min price field
              Expanded(
                flex: 1,
                child: _buildCompactTextInput(
                  "Min Price",
                  _minPriceController,
                  Icons.money,
                  isNumber: true,
                ),
              ),
              SizedBox(width: 12),
              // Max price field
              Expanded(
                flex: 1,
                child: _buildCompactTextInput(
                  "Max Price",
                  _maxPriceController,
                  Icons.money,
                  isNumber: true,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSearchButton() {
    return Center(
      child: Container(
        margin: EdgeInsets.symmetric(vertical: 16),
        child: ElevatedButton(
          onPressed: () {
            fetchTransportOptions();
          },
          style: ElevatedButton.styleFrom(
            backgroundColor:
                Color(0xFF5D838A), // Bluish-gray color matching the image
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(25),
            ),
            padding: EdgeInsets.symmetric(horizontal: 30, vertical: 12),
          ),
          child: Text(
            "Search",
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCompactTextInput(
      String label, TextEditingController controller, IconData icon,
      {bool isNumber = false}) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey.shade300),
      ),
      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: TextField(
        controller: controller,
        keyboardType: isNumber ? TextInputType.number : TextInputType.text,
        decoration: InputDecoration(
          labelText: label,
          border: InputBorder.none,
          icon: Icon(icon, color: Colors.blue.shade700),
          labelStyle: TextStyle(color: Colors.grey.shade600),
        ),
        style: TextStyle(fontWeight: FontWeight.w500),
      ),
    );
  }

  Widget _buildTransportModeDropdown() {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Row(
        children: [
          Icon(Icons.directions, color: Colors.blue.shade700),
          SizedBox(width: 12),
          Text(
            'Transport Mode:',
            style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
          ),
          SizedBox(width: 12),
          Expanded(
            child: DropdownButton<String>(
              value: _selectedTransportMode,
              isExpanded: true,
              underline: Container(),
              icon: Icon(Icons.arrow_drop_down, color: Colors.blue.shade700),
              items: transportModes.map((String mode) {
                return DropdownMenuItem(
                  value: mode,
                  child: Text(
                    mode,
                    style: TextStyle(fontWeight: FontWeight.w500),
                  ),
                );
              }).toList(),
              onChanged: (String? newValue) {
                if (newValue != null) {
                  setState(() => _selectedTransportMode = newValue);
                }
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResultsSection() {
    return Container(
      padding: const EdgeInsets.all(16.0),
      margin: EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            spreadRadius: 1,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.list_alt, color: Colors.blue.shade700),
              SizedBox(width: 8),
              Text(
                'Available Transport Options',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
          SizedBox(height: 16),
          _isLoading
              ? Center(
                  child: CircularProgressIndicator(
                    color: Colors.blue.shade700,
                  ),
                )
              : _transportResults.isEmpty
                  ? Center(
                      child: Column(
                        children: [
                          Icon(
                            Icons.search_off,
                            size: 48,
                            color: Colors.grey,
                          ),
                          SizedBox(height: 16),
                          Text(
                            'No transportation options found.',
                            style: TextStyle(
                              color: Colors.grey.shade700,
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                    )
                  : _buildGroupedTransportResults(),
        ],
      ),
    );
  }

  // New method to build grouped transport results
  Widget _buildGroupedTransportResults() {
    // Group the results by destination
    Map<String, List<Map<String, dynamic>>> groupedResults = {};

    for (var transport in _transportResults) {
      final destination = transport['destination'] ?? 'Unknown';
      if (!groupedResults.containsKey(destination)) {
        groupedResults[destination] = [];
      }
      groupedResults[destination]!.add(transport);
    }

    // Convert the grouped map to a list of widgets
    List<Widget> destinationGroups = [];

    groupedResults.forEach((destination, transports) {
      // Add a destination header
      destinationGroups.add(
        Padding(
          padding: EdgeInsets.symmetric(vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(Icons.location_on,
                        color: Colors.blue.shade700, size: 20),
                    SizedBox(width: 8),
                    Text(
                      'Destination: $destination',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: Colors.blue.shade900,
                      ),
                    ),
                    SizedBox(width: 8),
                    Text(
                      '(${transports.length} options)',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade700,
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 12),
              // Add the transport cards for this destination
              ...transports.map((transport) {
                // This is your existing card code
                final departure = transport['departure'] ?? 'Unknown';
                final destination = transport['destination'] ?? 'Unknown';
                final type = transport['type'] ?? 'Unknown';
                final price = transport['price'] ?? 0;
                final company = transport['company'] ?? 'Unknown Provider';
                final travelClass = transport['class'] ?? 'Standard';
                final scheduleType = transport['scheduleType'] ?? 'Daily';

                return Card(
                  margin: EdgeInsets.only(bottom: 16),
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    children: [
                      // Header with transport type, company and price
                      Container(
                        padding:
                            EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        decoration: BoxDecoration(
                          color: Colors.grey[50],
                          borderRadius:
                              BorderRadius.vertical(top: Radius.circular(12)),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: _getTransportColor(type),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: _getTransportIcon(type.toString()),
                                ),
                                SizedBox(width: 10),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      company,
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                      ),
                                    ),
                                    SizedBox(height: 2),
                                    Text(
                                      '$type • $travelClass',
                                      style: TextStyle(
                                        color: Colors.grey.shade700,
                                        fontSize: 14,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            Text(
                              '$price PKR',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                                color: Colors.black87,
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Route and Details
                      Padding(
                        padding: EdgeInsets.all(16),
                        child: Column(
                          children: [
                            // Route
                            Row(
                              children: [
                                Text(
                                  departure,
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                Expanded(
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 8.0),
                                    child: Stack(
                                      alignment: Alignment.center,
                                      children: [
                                        Divider(thickness: 1),
                                        Icon(Icons.arrow_forward, size: 16),
                                      ],
                                    ),
                                  ),
                                ),
                                Text(
                                  destination,
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: 16),

                            // Departure Time
                            if (transport['departureTime'] != null)
                              Row(
                                children: [
                                  Icon(Icons.access_time,
                                      size: 16, color: Colors.black54),
                                  SizedBox(width: 8),
                                  Text(
                                    'Departure: ${(transport['departureTime'])}',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Colors.black87,
                                    ),
                                  ),
                                ],
                              ),
                            SizedBox(height: 8),

                            // Schedule Type
                            Row(
                              children: [
                                Icon(Icons.calendar_today,
                                    size: 16, color: Colors.black54),
                                SizedBox(width: 8),
                                Text(
                                  'Schedule: $scheduleType',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.black87,
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: 16),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              }),
            ],
          ),
        ),
      );
    });

    return Column(children: destinationGroups);
  }

  // Helper method to get appropriate icon based on transport type
  Icon _getTransportIcon(String transportType) {
    switch (transportType.toLowerCase()) {
      case 'bus':
        return Icon(Icons.directions_bus, color: Colors.white);
      case 'train':
        return Icon(Icons.train, color: Colors.white);
      case 'airplane':
        return Icon(Icons.flight, color: Colors.white);
      default:
        return Icon(Icons.directions, color: Colors.white);
    }
  }

  // Helper method to get color based on transport type
  Color _getTransportColor(String transportType) {
    switch (transportType.toLowerCase()) {
      case 'bus':
        return const Color.fromARGB(255, 1, 10, 17);
      case 'train':
        return Colors.orange;
      case 'airplane':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  @override
  void dispose() {
    _sourceController.dispose();
    _destinationController.dispose();
    _minPriceController.dispose();
    _maxPriceController.dispose();
    super.dispose();
  }
}
