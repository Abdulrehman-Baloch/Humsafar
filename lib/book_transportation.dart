import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'custom_navbar.dart' as custom;

class BookTransportationScreen extends StatefulWidget {
  final String destinationCity;
  final String tripPlanID;
  final String destinationID;

  const BookTransportationScreen(
      {super.key,
      required this.destinationCity,
      required this.tripPlanID,
      required this.destinationID});

  @override
  BookTransportationScreenState createState() =>
      BookTransportationScreenState();
}

class BookTransportationScreenState extends State<BookTransportationScreen> {
  final TextEditingController _sourceController = TextEditingController();
  final TextEditingController _destinationController = TextEditingController();

  String _selectedTransportMode = "Bus"; // Default mode
  List<Map<String, dynamic>> _transportResults = [];
  bool _isLoading = false;

  final List<String> transportModes = ["Bus", "Train", "Airplane"];

  @override
  void initState() {
    super.initState();
    _destinationController.text =
        widget.destinationCity; // Pre-fill destination
  }

  /// Fetch transport options based on Source and Destination only
  Future<void> fetchTransportOptions() async {
    setState(() => _isLoading = true);

    String source = _sourceController.text.trim();
    String destination = _destinationController.text.trim();

    if (source.isEmpty || destination.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text("Please enter both source and destination.")),
      );
      setState(() => _isLoading = false);
      return;
    }

    try {
      QuerySnapshot querySnapshot = await FirebaseFirestore.instance
          .collection('transportation')
          .where('type', isEqualTo: _selectedTransportMode)
          .where('departure', isEqualTo: source)
          .where('destination', isEqualTo: destination)
          .get();

      List<Map<String, dynamic>> transportData = querySnapshot.docs
          .map((doc) => doc.data() as Map<String, dynamic>)
          .toList();

      setState(() {
        _transportResults = transportData;
      });

      if (_transportResults.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text("No transport options found for this route.")),
        );
      }
    } catch (e) {
      print("Error fetching transport options: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Failed to fetch transport options.")),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: SafeArea(
        child: Row(
          children: [
            // Vertical Navigation Bar with text labels - reusing existing NavigationBar
            const custom.NavigationBar(),

            // Main Content
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header
                    _buildHeader(),

                    // Search Form
                    _buildSearchForm(),

                    // Results Section
                    _buildResultsSection(),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(24.0),
      width: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF2C3E50), Color(0xFF1A2533)],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Book Transportation',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Colors.white,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Search and compare transportation options for your journey',
            style: TextStyle(
              fontSize: 16,
              color: Colors.white.withOpacity(0.9),
              letterSpacing: 0.3,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchForm() {
    return Container(
      margin: const EdgeInsets.all(16.0),
      padding: const EdgeInsets.all(24.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            spreadRadius: 0,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Travel Details',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF2C3E50),
            ),
          ),
          const SizedBox(height: 24),

          // Transport mode selection
          Container(
            margin: const EdgeInsets.only(bottom: 18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Mode of Transport',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey[700],
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: transportModes.map((mode) {
                    bool isSelected = mode == _selectedTransportMode;
                    IconData icon;

                    switch (mode) {
                      case "Bus":
                        icon = Icons.directions_bus_filled_rounded;
                        break;
                      case "Train":
                        icon = Icons.train_rounded;
                        break;
                      case "Airplane":
                        icon = Icons.flight_rounded;
                        break;
                      default:
                        icon = Icons.emoji_transportation_rounded;
                    }

                    return Expanded(
                      child: GestureDetector(
                        onTap: () {
                          setState(() => _selectedTransportMode = mode);
                        },
                        child: Container(
                          margin: const EdgeInsets.symmetric(horizontal: 4),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? const Color(0xFF2C3E50)
                                : Colors.grey[100],
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: isSelected
                                  ? const Color(0xFF2C3E50)
                                  : Colors.grey[300]!,
                              width: 1,
                            ),
                          ),
                          child: Column(
                            children: [
                              Icon(
                                icon,
                                size: 28,
                                color: isSelected
                                    ? Colors.white
                                    : Colors.grey[700],
                              ),
                              const SizedBox(height: 8),
                              Text(
                                mode,
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: isSelected
                                      ? FontWeight.bold
                                      : FontWeight.normal,
                                  color: isSelected
                                      ? Colors.white
                                      : Colors.grey[800],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),

          // Source input
          Container(
            margin: const EdgeInsets.only(bottom: 18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Departure From',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey[700],
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  decoration: BoxDecoration(
                    color: Colors.grey[50],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey[300]!),
                  ),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  child: TextField(
                    controller: _sourceController,
                    decoration: InputDecoration(
                      hintText: "Enter departure city",
                      border: InputBorder.none,
                      icon: Icon(Icons.location_on_outlined,
                          color: const Color(0xFF2C3E50)),
                      hintStyle: TextStyle(color: Colors.grey[400]),
                    ),
                    style: const TextStyle(fontSize: 16),
                  ),
                ),
              ],
            ),
          ),

          // Destination input
          Container(
            margin: const EdgeInsets.only(bottom: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Going To',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey[700],
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  decoration: BoxDecoration(
                    color: Colors.grey[50],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey[300]!),
                  ),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  child: TextField(
                    controller: _destinationController,
                    decoration: InputDecoration(
                      hintText: "Enter destination city",
                      border: InputBorder.none,
                      icon: Icon(Icons.location_on,
                          color: const Color(0xFF2C3E50)),
                      hintStyle: TextStyle(color: Colors.grey[400]),
                    ),
                    style: const TextStyle(fontSize: 16),
                    readOnly: true,
                  ),
                ),
              ],
            ),
          ),

          // Search button
          SizedBox(
            width: double.infinity,
            height: 54,
            child: ElevatedButton(
              onPressed: fetchTransportOptions,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2C3E50),
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.search, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    'Search Options',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5,
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

  Widget _buildResultsSection() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Available Options',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 16),

          // Results
          _isLoading
              ? Center(child: CircularProgressIndicator())
              : _transportResults.isEmpty
                  ? Container(
                      padding: EdgeInsets.symmetric(vertical: 24),
                      alignment: Alignment.center,
                      child: Text(
                        'No transportation options found. Try different search criteria.',
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 16,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    )
                  : ListView.builder(
                      physics: NeverScrollableScrollPhysics(),
                      shrinkWrap: true,
                      itemCount: _transportResults.length,
                      itemBuilder: (context, index) {
                        var transport = _transportResults[index];
                        return _buildTransportCard(transport);
                      },
                    ),
        ],
      ),
    );
  }

  Widget _buildTransportCard(Map<String, dynamic> transport) {
    // Define icons based on transport mode
    IconData modeIcon;
    switch (_selectedTransportMode) {
      case "Bus":
        modeIcon = Icons.directions_bus;
        break;
      case "Train":
        modeIcon = Icons.train;
        break;
      case "Airplane":
        modeIcon = Icons.airplanemode_active;
        break;
      default:
        modeIcon = Icons.emoji_transportation;
    }

    return Container(
      margin: EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey[300]!),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 4,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Header with transport type and company
          Container(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.vertical(top: Radius.circular(9)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(modeIcon, size: 22, color: Colors.black87),
                    SizedBox(width: 8),
                    Text(
                      transport['company'] ?? 'Unknown Provider',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    SizedBox(width: 8),
                    Text(
                      transport['class'] ?? '',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.black54,
                      ),
                    ),
                  ],
                ),
                Text(
                  "${transport['price'] ?? 'N/A'} pkr",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ),

          // Details Section
          Padding(
            padding: EdgeInsets.all(16),
            child: Column(
              children: [
                // Route
                Row(
                  children: [
                    Text(
                      '${transport['departure'] ?? 'Unknown'}',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8.0),
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
                      '${transport['destination'] ?? 'Unknown'}',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 12),

                // Departure Time
                if (transport['departureTime'] != null)
                  Row(
                    children: [
                      Icon(Icons.access_time, size: 16, color: Colors.black54),
                      SizedBox(width: 8),
                      Text(
                        'Departure Time: ${_formatTimestamp(transport['departureTime'])}',
                        style: TextStyle(
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                SizedBox(height: 8),

                // Schedule Type (Daily, Weekends, etc.)
                if (transport['scheduleType'] != null)
                  Row(
                    children: [
                      Icon(Icons.calendar_today,
                          size: 16, color: Colors.black54),
                      SizedBox(width: 8),
                      Text(
                        'Schedule: ${transport['scheduleType']}',
                        style: TextStyle(
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                SizedBox(height: 16),

                // Book button
                ElevatedButton(
                  onPressed: () {
                    // Book transport functionality
                    _showConfirmationDialog(transport);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.black,
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(vertical: 12),
                    minimumSize: Size(double.infinity, 45),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: Text(
                    'Book Now',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showConfirmationDialog(Map<String, dynamic> transport) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text("Confirm Booking"),
          content: Text("Are you sure you want to book this transportation?"),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Close the dialog
              },
              child: Text("Cancel"),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop(); // Close the dialog
                _bookTransport(transport); // Proceed with booking
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.black),
              child: Text("Yes, Book Now"),
            ),
          ],
        );
      },
    );
  }

  Future<void> _bookTransport(Map<String, dynamic> transport) async {
    try {
      setState(() => _isLoading = true);

      // You need to know which trip and destination this transportation belongs to
      // This should be passed to the BookTransportationScreen when it's created
      final String tripPlanId = widget.tripPlanID;
      final String destinationId = widget.destinationID;

      // Create a new document in the transportation subcollection
      final docRef = await FirebaseFirestore.instance
          .collection('tripPlans')
          .doc(tripPlanId)
          .collection('tripDestinations')
          .doc(destinationId)
          .collection('transportation')
          .add({
        'transportType': _selectedTransportMode,
        'company': transport['company'],
        'class': transport['class'],
        'price': transport['price'],
        'departure': transport['departure'],
        'destination': transport['destination'],
        'departureTime': transport['departureTime'],
        'scheduleType': transport['scheduleType'],
        'bookedAt': Timestamp.now(),
      });

      final bookedTransport = {
        'id': docRef.id, // The Firestore document ID
        'transportType': _selectedTransportMode,
        'company': transport['company'],
        'class': transport['class'],
        'price': transport['price'],
        'departure': transport['departure'],
        'destination': transport['destination'],
        'departureTime': transport['departureTime'],
        'scheduleType': transport['scheduleType'],
        'bookedAt': Timestamp.now(),
      };

      setState(() => _isLoading = false);

      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Transportation booked successfully!")),
      );

      // Navigate back to previous screen
      Navigator.pop(context, bookedTransport);
    } catch (e) {
      setState(() => _isLoading = false);

      // Show error message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Failed to book transportation: $e")),
      );
    }
  }

  /// Formats Firestore Timestamp to readable date-time
  String _formatTimestamp(dynamic timestamp) {
    if (timestamp == null) return "Not specified";

    if (timestamp is Timestamp) {
      DateTime dateTime = timestamp.toDate();
      return DateFormat('EEE, MMM d • h:mm a').format(dateTime);
    } else if (timestamp is String) {
      return timestamp; // If already stored as "8:00 PM", just return it
    }

    return timestamp.toString();
  }

  @override
  void dispose() {
    _sourceController.dispose();
    _destinationController.dispose();
    super.dispose();
  }
}
// import 'package:flutter/material.dart';
// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:intl/intl.dart';
// import 'custom_navbar.dart' as custom;

// class BookTransportationScreen extends StatefulWidget {
//   const BookTransportationScreen({super.key});

//   @override
//   BookTransportationScreenState createState() =>
//       BookTransportationScreenState();
// }

// class BookTransportationScreenState extends State<BookTransportationScreen> {
//   final TextEditingController _sourceController = TextEditingController();
//   final TextEditingController _destinationController = TextEditingController();

//   String _selectedTransportMode = "Bus"; // Default mode
//   List<Map<String, dynamic>> _transportResults = [];
//   bool _isLoading = false;

//   final List<String> transportModes = ["Bus", "Train", "Airplane"];

//   /// Fetch transport options based on Source and Destination only
//   Future<void> fetchTransportOptions() async {
//     setState(() => _isLoading = true);

//     String source = _sourceController.text.trim();
//     String destination = _destinationController.text.trim();

//     if (source.isEmpty || destination.isEmpty) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(content: Text("Please enter both source and destination.")),
//       );
//       setState(() => _isLoading = false);
//       return;
//     }

//     try {
//       QuerySnapshot querySnapshot = await FirebaseFirestore.instance
//           .collection('transportation')
//           .where('type', isEqualTo: _selectedTransportMode)
//           .where('departure', isEqualTo: source)
//           .where('destination', isEqualTo: destination)
//           .get();

//       List<Map<String, dynamic>> transportData = querySnapshot.docs
//           .map((doc) => doc.data() as Map<String, dynamic>)
//           .toList();

//       setState(() {
//         _transportResults = transportData;
//       });

//       if (_transportResults.isEmpty) {
//         ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(content: Text("No transport options found for this route.")),
//         );
//       }
//     } catch (e) {
//       print("Error fetching transport options: $e");
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(content: Text("Failed to fetch transport options.")),
//       );
//     } finally {
//       setState(() => _isLoading = false);
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: Colors.white,
//       body: SafeArea(
//         child: Row(
//           children: [
//             // Vertical Navigation Bar with text labels - reusing existing NavigationBar
//             const custom.NavigationBar(),

//             // Main Content
//             Expanded(
//               child: SingleChildScrollView(
//                 child: Column(
//                   crossAxisAlignment: CrossAxisAlignment.start,
//                   children: [
//                     // Header
//                     _buildHeader(),

//                     // Search Form
//                     _buildSearchForm(),

//                     // Results Section
//                     _buildResultsSection(),
//                   ],
//                 ),
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }

//   Widget _buildHeader() {
//     return Container(
//       padding: EdgeInsets.all(16.0),
//       width: double.infinity,
//       decoration: BoxDecoration(
//         color: Colors.grey[100],
//       ),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           Center(
//             child: Text(
//               'Book Transportation',
//               style: TextStyle(
//                 fontSize: 24,
//                 fontWeight: FontWeight.bold,
//               ),
//             ),
//           ),
//           SizedBox(height: 8),
//           Text(
//             'Search for available transportation options',
//             style: TextStyle(
//               fontSize: 16,
//               color: Colors.black87,
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _buildSearchForm() {
//     return Padding(
//       padding: const EdgeInsets.all(16.0),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           Text(
//             'Travel Details',
//             style: TextStyle(
//               fontSize: 18,
//               fontWeight: FontWeight.bold,
//             ),
//           ),
//           SizedBox(height: 16),

//           // Source input
//           Container(
//             decoration: BoxDecoration(
//               color: Colors.grey[100],
//               borderRadius: BorderRadius.circular(8),
//             ),
//             padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
//             child: TextField(
//               controller: _sourceController,
//               decoration: InputDecoration(
//                 labelText: "Departure Location",
//                 border: InputBorder.none,
//                 icon: Icon(Icons.location_on_outlined),
//               ),
//             ),
//           ),
//           SizedBox(height: 12),

//           // Destination input
//           Container(
//             decoration: BoxDecoration(
//               color: Colors.grey[100],
//               borderRadius: BorderRadius.circular(8),
//             ),
//             padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
//             child: TextField(
//               controller: _destinationController,
//               decoration: InputDecoration(
//                 labelText: "Destination",
//                 border: InputBorder.none,
//                 icon: Icon(Icons.location_on),
//               ),
//             ),
//           ),
//           SizedBox(height: 12),

//           // Transport mode selection
//           Container(
//             width: double.infinity,
//             padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
//             decoration: BoxDecoration(
//               color: Colors.grey[100],
//               borderRadius: BorderRadius.circular(8),
//             ),
//             child: Row(
//               children: [
//                 Icon(Icons.directions, color: Colors.black54),
//                 SizedBox(width: 12),
//                 Text(
//                   'Transport Mode:',
//                   style: TextStyle(
//                     fontSize: 16,
//                     color: Colors.black54,
//                   ),
//                 ),
//                 SizedBox(width: 12),
//                 Expanded(
//                   child: DropdownButton<String>(
//                     value: _selectedTransportMode,
//                     isExpanded: true,
//                     underline: Container(),
//                     items: transportModes.map((String mode) {
//                       return DropdownMenuItem(value: mode, child: Text(mode));
//                     }).toList(),
//                     onChanged: (String? newValue) {
//                       setState(() => _selectedTransportMode = newValue!);
//                     },
//                   ),
//                 ),
//               ],
//             ),
//           ),
//           SizedBox(height: 24),

//           // Search button
//           ElevatedButton(
//             onPressed: fetchTransportOptions,
//             style: ElevatedButton.styleFrom(
//               backgroundColor: Colors.black,
//               foregroundColor: Colors.white,
//               padding: EdgeInsets.symmetric(vertical: 16),
//               minimumSize: Size(double.infinity, 50),
//               shape: RoundedRectangleBorder(
//                 borderRadius: BorderRadius.circular(10),
//               ),
//             ),
//             child: Text(
//               'Search Transportation',
//               style: TextStyle(
//                 fontSize: 16,
//                 fontWeight: FontWeight.bold,
//               ),
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _buildResultsSection() {
//     return Padding(
//       padding: const EdgeInsets.all(16.0),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           Text(
//             'Available Options',
//             style: TextStyle(
//               fontSize: 18,
//               fontWeight: FontWeight.bold,
//             ),
//           ),
//           SizedBox(height: 16),

//           // Results
//           _isLoading
//               ? Center(child: CircularProgressIndicator())
//               : _transportResults.isEmpty
//                   ? Container(
//                       padding: EdgeInsets.symmetric(vertical: 24),
//                       alignment: Alignment.center,
//                       child: Text(
//                         'No transportation options found. Try different search criteria.',
//                         style: TextStyle(
//                           color: Colors.grey[600],
//                           fontSize: 16,
//                         ),
//                         textAlign: TextAlign.center,
//                       ),
//                     )
//                   : ListView.builder(
//                       physics: NeverScrollableScrollPhysics(),
//                       shrinkWrap: true,
//                       itemCount: _transportResults.length,
//                       itemBuilder: (context, index) {
//                         var transport = _transportResults[index];
//                         return _buildTransportCard(transport);
//                       },
//                     ),
//         ],
//       ),
//     );
//   }

//   Widget _buildTransportCard(Map<String, dynamic> transport) {
//     // Define icons based on transport mode
//     IconData modeIcon;
//     switch (_selectedTransportMode) {
//       case "Bus":
//         modeIcon = Icons.directions_bus;
//         break;
//       case "Train":
//         modeIcon = Icons.train;
//         break;
//       case "Airplane":
//         modeIcon = Icons.airplanemode_active;
//         break;
//       default:
//         modeIcon = Icons.emoji_transportation;
//     }

//     return Container(
//       margin: EdgeInsets.only(bottom: 16),
//       decoration: BoxDecoration(
//         color: Colors.white,
//         borderRadius: BorderRadius.circular(10),
//         border: Border.all(color: Colors.grey[300]!),
//         boxShadow: [
//           BoxShadow(
//             color: Colors.grey.withOpacity(0.1),
//             spreadRadius: 1,
//             blurRadius: 4,
//             offset: Offset(0, 2),
//           ),
//         ],
//       ),
//       child: Column(
//         children: [
//           // Header with transport type and company
//           Container(
//             padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
//             decoration: BoxDecoration(
//               color: Colors.grey[100],
//               borderRadius: BorderRadius.vertical(top: Radius.circular(9)),
//             ),
//             child: Row(
//               mainAxisAlignment: MainAxisAlignment.spaceBetween,
//               children: [
//                 Row(
//                   children: [
//                     Icon(modeIcon, size: 22, color: Colors.black87),
//                     SizedBox(width: 8),
//                     Text(
//                       transport['company'] ?? 'Unknown Provider',
//                       style: TextStyle(
//                         fontWeight: FontWeight.bold,
//                         fontSize: 16,
//                       ),
//                     ),
//                     SizedBox(width: 8),
//                     Text(
//                       transport['class'] ?? '',
//                       style: TextStyle(
//                         fontSize: 14,
//                         color: Colors.black54,
//                       ),
//                     ),
//                   ],
//                 ),
//                 Text(
//                   "${transport['price'] ?? 'N/A'} pkr",
//                   style: TextStyle(
//                     fontWeight: FontWeight.bold,
//                     fontSize: 16,
//                   ),
//                 ),
//               ],
//             ),
//           ),

//           // Details Section
//           Padding(
//             padding: EdgeInsets.all(16),
//             child: Column(
//               children: [
//                 // Route
//                 Row(
//                   children: [
//                     Text(
//                       '${transport['departure'] ?? 'Unknown'}',
//                       style: TextStyle(
//                         fontSize: 15,
//                         fontWeight: FontWeight.w500,
//                       ),
//                     ),
//                     Expanded(
//                       child: Padding(
//                         padding: const EdgeInsets.symmetric(horizontal: 8.0),
//                         child: Stack(
//                           alignment: Alignment.center,
//                           children: [
//                             Divider(thickness: 1),
//                             Icon(Icons.arrow_forward, size: 16),
//                           ],
//                         ),
//                       ),
//                     ),
//                     Text(
//                       '${transport['destination'] ?? 'Unknown'}',
//                       style: TextStyle(
//                         fontSize: 15,
//                         fontWeight: FontWeight.w500,
//                       ),
//                     ),
//                   ],
//                 ),
//                 SizedBox(height: 12),

//                 // Departure Time
//                 if (transport['departureTime'] != null)
//                   Row(
//                     children: [
//                       Icon(Icons.access_time, size: 16, color: Colors.black54),
//                       SizedBox(width: 8),
//                       Text(
//                         'Departure Time: ${_formatTimestamp(transport['departureTime'])}',
//                         style: TextStyle(
//                           fontSize: 14,
//                         ),
//                       ),
//                     ],
//                   ),
//                 SizedBox(height: 8),

//                 // Schedule Type (Daily, Weekends, etc.)
//                 if (transport['scheduleType'] != null)
//                   Row(
//                     children: [
//                       Icon(Icons.calendar_today,
//                           size: 16, color: Colors.black54),
//                       SizedBox(width: 8),
//                       Text(
//                         'Schedule: ${transport['scheduleType']}',
//                         style: TextStyle(
//                           fontSize: 14,
//                         ),
//                       ),
//                     ],
//                   ),
//                 SizedBox(height: 16),

//                 // Book button
//                 ElevatedButton(
//                   onPressed: () {
//                     // Book transport functionality
//                   },
//                   style: ElevatedButton.styleFrom(
//                     backgroundColor: Colors.black,
//                     foregroundColor: Colors.white,
//                     padding: EdgeInsets.symmetric(vertical: 12),
//                     minimumSize: Size(double.infinity, 45),
//                     shape: RoundedRectangleBorder(
//                       borderRadius: BorderRadius.circular(8),
//                     ),
//                   ),
//                   child: Text(
//                     'Book Now',
//                     style: TextStyle(
//                       fontWeight: FontWeight.bold,
//                     ),
//                   ),
//                 ),
//               ],
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   /// Formats Firestore Timestamp to readable date-time
//   String _formatTimestamp(dynamic timestamp) {
//     if (timestamp == null) return "Unknown";

//     if (timestamp is Timestamp) {
//       DateTime dateTime = timestamp.toDate();
//       return DateFormat('EEE, MMM d, yyyy • h:mm a').format(dateTime);
//     } else if (timestamp is String) {
//       return timestamp; // If already stored as "8:00 PM", just return it
//     }

//     return timestamp.toString();
//   }
// }
