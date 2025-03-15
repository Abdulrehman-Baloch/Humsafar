import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:humsafar_app/home.dart';
import 'bookAccommodation.dart';
import 'book_transportation.dart';
import 'package:intl/intl.dart';

class TripPlanDetailsScreen extends StatefulWidget {
  final String tripPlanId;
  final String tripName;

  const TripPlanDetailsScreen({
    super.key,
    required this.tripPlanId,
    required this.tripName,
  });

  @override
  State<TripPlanDetailsScreen> createState() => _TripPlanDetailsScreenState();
}

class _TripPlanDetailsScreenState extends State<TripPlanDetailsScreen> {
  bool _isLoading = true;
  Map<String, dynamic>? _tripData;
  List<Map<String, dynamic>> _destinations = [];

  @override
  void initState() {
    super.initState();
    _fetchTripDetails();
  }

  Future<void> _fetchTripDetails() async {
    try {
      // Fetch trip plan data
      final tripDoc = await FirebaseFirestore.instance
          .collection('tripPlans')
          .doc(widget.tripPlanId)
          .get();

      if (tripDoc.exists) {
        // Fetch destinations for this trip
        final destinationsSnapshot = await FirebaseFirestore.instance
            .collection('tripPlans')
            .doc(widget.tripPlanId)
            .collection('tripDestinations')
            .get();

        final List<Map<String, dynamic>> destinations = [];

        for (var destinationDoc in destinationsSnapshot.docs) {
          final destinationData = destinationDoc.data();
          final destinationId = destinationDoc.id;

          // Fetch transport bookings for this destination
          final transportSnapshot = await FirebaseFirestore.instance
              .collection('tripPlans')
              .doc(widget.tripPlanId)
              .collection('tripDestinations')
              .doc(destinationId)
              .collection('transportation')
              .get();

          // Store transport bookings in a list
          final transportBookings = transportSnapshot.docs
              .map((doc) => {
                    ...doc.data(),
                    'id': doc.id, // Include transport document ID
                  })
              .toList();

          // Add transport bookings to the destination
          destinations.add({
            ...destinationData,
            'id': destinationId,
            'transportBookings': transportBookings,
          });
        }

        setState(() {
          _tripData = tripDoc.data();
          _destinations = destinations;
          _isLoading = false;
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Trip plan not found')),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading trip details: $e')),
      );
    }
  }

  String _formatDate(Timestamp timestamp) {
    final date = timestamp.toDate();
    return DateFormat('MMMM dd, yyyy').format(date);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Trip Plan Details'),
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Trip Title and Status Row
                  Container(
                    color: const Color.fromARGB(255, 112, 108, 108),
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            widget.tripName,
                            style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: _tripData?['isCompleted'] == true
                                ? Colors.grey
                                : const Color.fromARGB(255, 94, 58, 105),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Text(
                            _tripData?['isCompleted'] == true
                                ? 'Completed'
                                : 'Upcoming',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        IconButton(
                          icon: const Icon(Icons.edit, color: Colors.white),
                          onPressed: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                  content: Text(
                                      'Edit trip functionality coming soon')),
                            );
                          },
                        ),
                      ],
                    ),
                  ),

                  // Trip Overview Section
                  _buildTripOverview(),

                  const Divider(height: 32, thickness: 1),

                  // Destinations Section
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Destinations',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            ElevatedButton.icon(
                              label: const Text('Explore More Destinations'),
                              icon: const Icon(Icons.explore),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.black,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => HomeScreen(),
                                  ),
                                );
                              },
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        _destinations.isEmpty
                            ? const Center(
                                child: Padding(
                                  padding: EdgeInsets.all(24.0),
                                  child: Text(
                                    'No destinations added to this trip yet',
                                    style: TextStyle(
                                      color: Colors.grey,
                                      fontSize: 16,
                                    ),
                                  ),
                                ),
                              )
                            : ListView.separated(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                itemCount: _destinations.length,
                                separatorBuilder: (context, index) =>
                                    const Divider(height: 1),
                                itemBuilder: (context, index) {
                                  final destination = _destinations[index];
                                  return _buildDestinationTile(destination);
                                },
                              ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Trip Actions
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        ElevatedButton.icon(
                          icon: const Icon(Icons.share),
                          label: const Text(
                            'SHARE TRIP',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.black,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                          onPressed: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                  content: Text(
                                      'Share trip functionality coming soon')),
                            );
                          },
                        ),
                        const SizedBox(height: 12),
                        ElevatedButton.icon(
                          icon: Icon(
                            _tripData?['isCompleted'] == true
                                ? Icons.refresh
                                : Icons.check_circle_outline,
                            color: Colors.white,
                          ),
                          label: Text(
                            _tripData?['isCompleted'] == true
                                ? 'MARK AS UPCOMING'
                                : 'MARK AS COMPLETED',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.black,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                          onPressed: () {
                            _toggleTripStatus();
                          },
                        ),
                        const SizedBox(height: 12),
                        ElevatedButton.icon(
                          icon: const Icon(Icons.delete, color: Colors.red),
                          label: const Text(
                            'DELETE TRIP',
                            style: TextStyle(
                                color: Colors.red, fontWeight: FontWeight.bold),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.black,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                          onPressed: () {
                            _showDeleteConfirmation();
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildTripOverview() {
    if (_tripData == null) return const SizedBox.shrink();

    final startDate = _tripData!['startDate'] as Timestamp;
    final endDate = _tripData!['endDate'] as Timestamp;
    final totalDays = _tripData!['totalDays'] as int;
    final travelers = _tripData!['numberOfTravelers'] as int;

    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Trip details
          Row(
            children: [
              const Icon(Icons.calendar_today),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${_formatDate(startDate)} - ${_formatDate(endDate)}',
                      style: const TextStyle(
                        fontSize: 16,
                      ),
                    ),
                    Text(
                      '$totalDays days',
                      style: const TextStyle(
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              const Icon(Icons.person),
              const SizedBox(width: 8),
              Text(
                '$travelers ${travelers == 1 ? 'Traveler' : 'Travelers'}',
                style: const TextStyle(
                  fontSize: 16,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDestinationTile(Map<String, dynamic> destination) {
    final destinationId = destination['id'] as String;
    final destinationName = destination['destinationName'] as String;
    final startDate = destination['startDate'] as Timestamp;
    final endDate = destination['endDate'] as Timestamp;
    final daysOfStay = destination['daysOfStay'] as int;
    //final notes = destination['notes'] as String? ?? '';

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12.0),
      child: ExpansionTile(
        tilePadding: EdgeInsets.zero,
        childrenPadding: EdgeInsets.zero,
        title: Row(
          children: [
            const Icon(Icons.location_on),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                destinationName,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        subtitle: Text(
          '${_formatDate(startDate)} - ${_formatDate(endDate)} ($daysOfStay days)',
          style: const TextStyle(
            fontSize: 14,
            color: Colors.grey,
          ),
        ),
        children: [
          // Activities Section for this destination
          Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Activities',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    ElevatedButton.icon(
                      icon: const Icon(Icons.add, size: 16),
                      label: const Text('Add'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.black,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 8),
                        minimumSize: const Size(0, 32),
                      ),
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                              content: Text(
                                  'Add activity for $destinationName coming soon')),
                        );
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                const Center(
                  child: Padding(
                    padding: EdgeInsets.symmetric(vertical: 12.0),
                    child: Text(
                      'No activities added for this destination yet',
                      style: TextStyle(
                        color: Colors.grey,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          const Divider(thickness: 0.5),

          // Booking Information Section for this destination
          Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Booking Information',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    ElevatedButton.icon(
                      icon: const Icon(Icons.add, size: 16),
                      label: const Text('Add'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.black,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 8),
                        minimumSize: const Size(0, 32),
                      ),
                      onPressed: () {
                        _showAddOptions(context, destination);
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                destination['transportBookings'] == null ||
                        destination['transportBookings'].isEmpty
                    ? const Center(
                        child: Padding(
                          padding: EdgeInsets.symmetric(vertical: 12.0),
                          child: Text(
                            'No booking information added for this destination yet',
                            style: TextStyle(
                              color: Colors.grey,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      )
                    : Column(
                        children: destination['transportBookings']
                            .map<Widget>(
                                (transport) => _buildTransportCard(transport))
                            .toList(),
                      ),
              ],
            ),
          ),
          // Destination actions
          Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton.icon(
                  icon: const Icon(Icons.edit, size: 18),
                  label: const Text('Edit'),
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                          content: Text(
                              'Edit destination functionality coming soon')),
                    );
                  },
                ),
                const SizedBox(width: 8),
                TextButton.icon(
                  icon: const Icon(Icons.delete, size: 18, color: Colors.red),
                  label:
                      const Text('Remove', style: TextStyle(color: Colors.red)),
                  onPressed: () {
                    _showDeleteDestinationConfirmation(destination);
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTransportCard(Map<String, dynamic> transport) {
    return Card(
      margin: const EdgeInsets.only(top: 10),
      elevation: 3,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${transport['company']} - ${transport['transportType']}',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  '${transport['price']} PKR',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.green,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.location_on, size: 16, color: Colors.red),
                const SizedBox(width: 4),
                Text(
                  '${transport['departure']} → ${transport['destination']}',
                  style: const TextStyle(fontSize: 14),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                const Icon(Icons.access_time, size: 16, color: Colors.blue),
                const SizedBox(width: 4),
                Text(
                  'Departure: ${(transport['departureTime'])}',
                  style: const TextStyle(fontSize: 14),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showAddOptions(BuildContext context, Map<String, dynamic> destination) {
    showModalBottomSheet(
      context: context,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (BuildContext context) {
        return Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                "What would you like to add?",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),

              // Add Transportation Button
              ElevatedButton.icon(
                icon: const Icon(Icons.directions_bus),
                label: const Text("Add Transportation"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                  minimumSize: const Size(double.infinity, 40),
                ),
                onPressed: () async {
                  Navigator.pop(context); // Close bottom sheet
                  final bookedTransport = await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => BookTransportationScreen(
                        destinationCity: destination['destinationName'],
                        tripPlanID: widget.tripPlanId,
                        destinationID: destination['id'],
                      ),
                    ),
                  );

                  // If transport was booked, add it to UI
                  if (bookedTransport != null) {
                    _addTransportToDestination(
                        destination['id'], bookedTransport);
                  }
                },
              ),
              const SizedBox(height: 10),

              // Add Accommodation Button
              // ElevatedButton.icon(
              //   icon: const Icon(Icons.hotel),
              //   label: const Text("Add Accommodation"),
              //   style: ElevatedButton.styleFrom(
              //     backgroundColor: Colors.green,
              //     foregroundColor: Colors.white,
              //     minimumSize: const Size(double.infinity, 40),
              //   ),
              //   onPressed: () {
              //     Navigator.pop(context); // Close bottom sheet
              //     Navigator.push(
              //       context,
              //       MaterialPageRoute(
              //         builder: (context) => bookAccommodation(),
              //       ),
              //     );
              //   },
              // ),
            ],
          ),
        );
      },
    );
  }

  void _addTransportToDestination(
      String destinationId, Map<String, dynamic> bookedTransport) {
    setState(() {
      for (var destination in _destinations) {
        if (destination['id'] == destinationId) {
          destination['transportBookings'] ??= [];
          destination['transportBookings'].add(bookedTransport);
          break;
        }
      }
    });
  }

  Future<void> _toggleTripStatus() async {
    if (_tripData == null) return;

    try {
      final isCompleted = _tripData!['isCompleted'] as bool;

      // Update the trip status
      await FirebaseFirestore.instance
          .collection('tripPlans')
          .doc(widget.tripPlanId)
          .update({'isCompleted': !isCompleted});

      // Update local state
      setState(() {
        _tripData!['isCompleted'] = !isCompleted;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content:
              Text('Trip marked as ${!isCompleted ? 'completed' : 'upcoming'}'),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error updating trip status: $e')),
      );
    }
  }

  Future<void> _showDeleteConfirmation() async {
    return showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Delete Trip Plan'),
          content: const Text(
              'Are you sure you want to delete this trip plan? This action cannot be undone.'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('CANCEL'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                _deleteTrip();
              },
              child: const Text(
                'DELETE',
                style: TextStyle(color: Colors.red),
              ),
            ),
          ],
        );
      },
    );
  }

  Future<void> _deleteTrip() async {
    try {
      // Delete the entire trip plan document (will also delete subcollections)
      await FirebaseFirestore.instance
          .collection('tripPlans')
          .doc(widget.tripPlanId)
          .delete();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Trip plan deleted successfully')),
      );
      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error deleting trip plan: $e')),
      );
    }
  }

  Future<void> _showDeleteDestinationConfirmation(
      Map<String, dynamic> destination) async {
    return showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Remove Destination'),
          content: Text(
              'Are you sure you want to remove ${destination['destinationName']} from this trip?'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('CANCEL'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                _deleteDestination(destination['id']);
              },
              child: const Text(
                'REMOVE',
                style: TextStyle(color: Colors.red),
              ),
            ),
          ],
        );
      },
    );
  }

  Future<void> _deleteDestination(String destinationId) async {
    try {
      // Delete the destination document
      await FirebaseFirestore.instance
          .collection('tripPlans')
          .doc(widget.tripPlanId)
          .collection('tripDestinations')
          .doc(destinationId)
          .delete();

      // Update local state
      setState(() {
        _destinations.removeWhere((dest) => dest['id'] == destinationId);
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Destination removed successfully')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error removing destination: $e')),
      );
    }
  }
}
