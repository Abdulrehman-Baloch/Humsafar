import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:humsafar_app/screens/home.dart';
import 'package:humsafar_app/screens/lists/create_packing_list_screen.dart';
//import 'book_accommodation.dart';
import '../bookings/transportation/book_transportation.dart';
import 'package:intl/intl.dart';
import '../../widgets/trip/trip_timeline.dart';
import 'edit_trip_plan.dart';
import 'edit_trip_destination.dart';
import '../bookings/accommodation/display_accommodation.dart';
import 'package:share_plus/share_plus.dart';
import 'share_trip_plan.dart';
import 'trip_attractions_display.dart';

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
  List<Map<String, dynamic>> selectedActivities = [];
  late String _currentTripName;
  final ShareTripPlan _tripShareService = ShareTripPlan();
  String tripId = ''; // Add this

  @override
  void initState() {
    super.initState();
    _currentTripName = widget.tripName;
    tripId = widget.tripPlanId;
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
          // Fetch accommodations for this destination
          final accommodationsSnapshot = await FirebaseFirestore.instance
              .collection('tripPlans')
              .doc(widget.tripPlanId)
              .collection('tripDestinations')
              .doc(destinationId)
              .collection('tripAccommodations')
              .get();
          // Store transport bookings in a list
          final transportBookings = transportSnapshot.docs
              .map((doc) => {
                    ...doc.data(),
                    'id': doc.id, // Include transport document ID
                  })
              .toList();
          // Store accommodations in a list
          final accommodations = accommodationsSnapshot.docs
              .map((doc) => {
                    ...doc.data(),
                    'id': doc.id, // Include accommodation document ID
                  })
              .toList();
          // Add transport bookings to the destination
          destinations.add({
            ...destinationData,
            'id': destinationId,
            'destinationName': destinationData['destinationName'],
            'transportBookings': transportBookings,
            'accommodations': accommodations,
          });
        }

        // Sort destinations by start date
        destinations.sort((a, b) {
          final aDate = (a['startDate'] as Timestamp).toDate();
          final bDate = (b['startDate'] as Timestamp).toDate();
          return aDate.compareTo(bDate);
        });

        // Update trip dates based on destinations if there are any
        if (destinations.isNotEmpty) {
          // Get the earliest start date and latest end date
          final earliestStartDate =
              (destinations.first['startDate'] as Timestamp).toDate();
          final latestEndDate =
              (destinations.last['endDate'] as Timestamp).toDate();

          // Calculate total days
          final difference =
              latestEndDate.difference(earliestStartDate).inDays + 1;

          // Update the trip dates in Firestore
          await FirebaseFirestore.instance
              .collection('tripPlans')
              .doc(widget.tripPlanId)
              .update({
            'startDate': Timestamp.fromDate(earliestStartDate),
            'endDate': Timestamp.fromDate(latestEndDate),
            'totalDays': difference,
          });

          // Update the trip data with the new dates
          _tripData = {...tripDoc.data()!};
          _tripData!['startDate'] = Timestamp.fromDate(earliestStartDate);
          _tripData!['endDate'] = Timestamp.fromDate(latestEndDate);
          _tripData!['totalDays'] = difference;
        }

        setState(() {
          _tripData = _tripData ?? tripDoc.data();
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

  Future<void> _navigateToEditDestinationScreen(
      Map<String, dynamic> destination) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EditDestinationScreen(
          tripPlanId: widget.tripPlanId,
          destinationId: destination['id'],
          destinationData: destination,
        ),
      ),
    );

    // Handle the result when returning from edit screen
    if (result != null && result['updated'] == true) {
      // Refresh trip details
      _fetchTripDetails();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Destination updated successfully')),
      );
    }
  }

  Future<void> _navigateToEditScreen() async {
    if (_tripData == null) return;

    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EditTripPlanScreen(
          tripPlanId: widget.tripPlanId,
          tripData: _tripData!,
          tripName: _currentTripName,
        ),
      ),
    );

    // Handle the result when returning from edit screen
    if (result != null && result['updated'] == true) {
      setState(() {
        _currentTripName = result['name'];
      });
      // Refresh trip details
      _fetchTripDetails();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Trip updated successfully')),
      );
    }
  }

  // New method to build the trip timeline widget
  Widget _buildTripTimeline() {
    if (_tripData == null) return const SizedBox.shrink();

    final startDate = (_tripData!['startDate'] as Timestamp).toDate();
    final endDate = (_tripData!['endDate'] as Timestamp).toDate();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: TripCalendarTimeline(
        tripStartDate: startDate,
        tripEndDate: endDate,
        destinations: _destinations,
      ),
    );
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
                    color: const Color.fromARGB(255, 219, 218, 218),
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            _currentTripName,
                            style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: Colors.black,
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
                          icon: const Icon(Icons.edit, color: Colors.black),
                          onPressed: () {
                            _navigateToEditScreen();
                          },
                        ),
                      ],
                    ),
                  ),

                  // Trip Overview Section
                  _buildTripOverview(),

                  // Trip Timeline Section - Added here
                  _buildTripTimeline(),

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
                            if (_tripData != null) {
                              _tripShareService.shareTrip(
                                context,
                                tripPlanId: widget.tripPlanId,
                                tripName: _currentTripName,
                                tripData: _tripData!,
                                destinations: _destinations,
                              );
                            }
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
                        const SizedBox(height: 12),

                        // Packing List Button
                        ElevatedButton.icon(
                          icon: const Icon(Icons.checklist, size: 20),
                          label: const Text(
                            'PACKING LIST',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor:
                                const Color(0xFF5E3A69), // Purple accent
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => CreatePackingListScreen(
                                  tripId: tripId, // Pass the tripId
                                  tripName: _tripData?['name'] ??
                                      'Trip', // Pass trip name from _tripData
                                ),
                              ),
                            );
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

  // Check if accommodation is already booked for the given dates
  Future<bool> isAccommodationAlreadyBooked(
      String accommodationId,
      DateTime startDate,
      DateTime endDate,
      String tripPlanId,
      String destinationId) async {
    try {
      final accommodationsSnapshot = await FirebaseFirestore.instance
          .collection('tripPlans')
          .doc(tripPlanId)
          .collection('tripDestinations')
          .doc(destinationId)
          .collection('tripAccommodations')
          .get();

      // Check if this accommodation is already booked
      for (var doc in accommodationsSnapshot.docs) {
        final booking = doc.data();

        // If it's the same accommodation
        if (booking['accommodationId'] == accommodationId) {
          // Check date overlap: it's a conflict if:
          // 1. New start date is between existing booking dates, or
          // 2. New end date is between existing booking dates, or
          // 3. New booking dates completely contain the existing booking
          final bookedStartDate =
              (booking['checkInDate'] as Timestamp).toDate();
          final bookedEndDate = (booking['checkOutDate'] as Timestamp).toDate();

          if ((startDate.isAfter(bookedStartDate) &&
                  startDate.isBefore(bookedEndDate)) ||
              (endDate.isAfter(bookedStartDate) &&
                  endDate.isBefore(bookedEndDate)) ||
              (startDate.isBefore(bookedStartDate) &&
                  endDate.isAfter(bookedEndDate))) {
            return true; // Booking conflict exists
          }
        }
      }

      return false; // No booking conflict
    } catch (e) {
      print('Error checking booking status: $e');
      return false;
    }
  }

  // Creates a widget to manage an accommodation booking
  Widget _buildAccommodationCard(Map<String, dynamic> accommodation) {
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
                  accommodation['name'] ?? 'Unknown Accommodation',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  '${accommodation['price'] ?? 'N/A'} PKR',
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
                const Icon(Icons.hotel, size: 16, color: Colors.orange),
                const SizedBox(width: 4),
                Text(
                  accommodation['description'] ?? 'No description available',
                  style: const TextStyle(fontSize: 14),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                const Icon(Icons.calendar_today, size: 16, color: Colors.blue),
                const SizedBox(width: 4),
                Text(
                  'Booked on: ${_formatDate(accommodation['bookedAt'])}',
                  style: const TextStyle(fontSize: 14),
                ),
              ],
            ),
            // Check-in and check-out dates
            if (accommodation['checkInDate'] != null &&
                accommodation['checkOutDate'] != null)
              Padding(
                padding: const EdgeInsets.only(top: 6.0),
                child: Row(
                  children: [
                    const Icon(Icons.date_range,
                        size: 16, color: Colors.purple),
                    const SizedBox(width: 4),
                    Text(
                      'Stay: ${_formatDate(accommodation['checkInDate'])} - ${_formatDate(accommodation['checkOutDate'])}',
                      style: const TextStyle(fontSize: 14),
                    ),
                  ],
                ),
              ),

            // Actions row
            Padding(
              padding: const EdgeInsets.only(top: 12.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton.icon(
                    icon: const Icon(Icons.edit, size: 16),
                    label: const Text('Modify'),
                    onPressed: () {
                      _showModifyBookingDialog(accommodation);
                    },
                  ),
                  const SizedBox(width: 8),
                  TextButton.icon(
                    icon: const Icon(Icons.cancel, size: 16, color: Colors.red),
                    label: const Text('Cancel',
                        style: TextStyle(color: Colors.red)),
                    onPressed: () {
                      _showCancelBookingConfirmation(accommodation);
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

  void _showCancelBookingConfirmation(Map<String, dynamic> accommodation) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Cancel Booking'),
          content: Text(
              'Are you sure you want to cancel your booking at ${accommodation['name']}?'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('NO'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                _cancelAccommodationBooking(accommodation);
              },
              child: const Text(
                'YES, CANCEL',
                style: TextStyle(color: Colors.red),
              ),
            ),
          ],
        );
      },
    );
  }

// Delete the booking from Firestore
  Future<void> _cancelAccommodationBooking(
      Map<String, dynamic> accommodation) async {
    try {
      // First find which destination this accommodation belongs to
      String? destinationId;

      for (var destination in _destinations) {
        if (destination['accommodations'] != null) {
          for (var acc in destination['accommodations']) {
            if (acc['id'] == accommodation['id']) {
              destinationId = destination['id'];
              break;
            }
          }
        }
        if (destinationId != null) break;
      }

      if (destinationId != null) {
        // Delete from Firestore
        await FirebaseFirestore.instance
            .collection('tripPlans')
            .doc(widget.tripPlanId)
            .collection('tripDestinations')
            .doc(destinationId)
            .collection('tripAccommodations')
            .doc(accommodation['id'])
            .delete();

        // Update local state
        setState(() {
          for (var destination in _destinations) {
            if (destination['id'] == destinationId) {
              destination['accommodations']
                  .removeWhere((acc) => acc['id'] == accommodation['id']);
              break;
            }
          }
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Booking cancelled successfully')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error cancelling booking: $e')),
      );
    }
  }

// Show dialog to modify booking
  void _showModifyBookingDialog(Map<String, dynamic> accommodation) {
    // Find which destination this accommodation belongs to
    String? destinationId;
    Map<String, dynamic>? destinationData;

    for (var destination in _destinations) {
      if (destination['accommodations'] != null) {
        for (var acc in destination['accommodations']) {
          if (acc['id'] == accommodation['id']) {
            destinationId = destination['id'];
            destinationData = destination;
            break;
          }
        }
      }
      if (destinationId != null) break;
    }

    if (destinationId == null || destinationData == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not find destination data')),
      );
      return;
    }

    // Get destination date bounds
    final destinationStartDate =
        (destinationData['startDate'] as Timestamp).toDate();
    final destinationEndDate =
        (destinationData['endDate'] as Timestamp).toDate();

    // Initialize date controllers with current values
    DateTime checkInDate = accommodation['checkInDate'] != null
        ? (accommodation['checkInDate'] as Timestamp).toDate()
        : destinationStartDate;
    DateTime checkOutDate = accommodation['checkOutDate'] != null
        ? (accommodation['checkOutDate'] as Timestamp).toDate()
        : destinationEndDate;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Modify Booking'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Accommodation: ${accommodation['name']}'),
                  const SizedBox(height: 16),
                  Text(
                      'Check-in Date: ${DateFormat('MMM dd, yyyy').format(checkInDate)}'),
                  ElevatedButton(
                    child: const Text('Change Check-in Date'),
                    onPressed: () async {
                      final pickedDate = await showDatePicker(
                        context: context,
                        initialDate: checkInDate,
                        firstDate: destinationStartDate,
                        lastDate:
                            checkOutDate.subtract(const Duration(days: 1)),
                      );
                      if (pickedDate != null) {
                        setState(() {
                          checkInDate = pickedDate;
                        });
                      }
                    },
                  ),
                  const SizedBox(height: 16),
                  Text(
                      'Check-out Date: ${DateFormat('MMM dd, yyyy').format(checkOutDate)}'),
                  ElevatedButton(
                    child: const Text('Change Check-out Date'),
                    onPressed: () async {
                      final pickedDate = await showDatePicker(
                        context: context,
                        initialDate: checkOutDate,
                        firstDate: checkInDate.add(const Duration(days: 1)),
                        lastDate: destinationEndDate,
                      );
                      if (pickedDate != null) {
                        setState(() {
                          checkOutDate = pickedDate;
                        });
                      }
                    },
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  child: const Text('CANCEL'),
                ),
                TextButton(
                  onPressed: () async {
                    Navigator.of(context).pop();

                    // Check for booking conflicts
                    bool alreadyBooked = await isAccommodationAlreadyBooked(
                      accommodation['accommodationId'],
                      checkInDate,
                      checkOutDate,
                      widget.tripPlanId,
                      destinationId!,
                    );

                    if (alreadyBooked) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content:
                              Text('These dates conflict with another booking'),
                          backgroundColor: Colors.red,
                        ),
                      );
                      return;
                    }

                    // Update the booking
                    _updateAccommodationBooking(accommodation, destinationId!,
                        checkInDate, checkOutDate);
                  },
                  child: const Text('SAVE CHANGES'),
                ),
              ],
            );
          },
        );
      },
    );
  }

// Update the booking in Firestore
  Future<void> _updateAccommodationBooking(Map<String, dynamic> accommodation,
      String destinationId, DateTime checkInDate, DateTime checkOutDate) async {
    try {
      // Calculate night count
      final nightCount = checkOutDate.difference(checkInDate).inDays;

      // Update Firestore document
      await FirebaseFirestore.instance
          .collection('tripPlans')
          .doc(widget.tripPlanId)
          .collection('tripDestinations')
          .doc(destinationId)
          .collection('tripAccommodations')
          .doc(accommodation['id'])
          .update({
        'checkInDate': Timestamp.fromDate(checkInDate),
        'checkOutDate': Timestamp.fromDate(checkOutDate),
        'nightCount': nightCount,
        'modifiedAt': Timestamp.now(),
      });

      // Update local state
      setState(() {
        for (var destination in _destinations) {
          if (destination['id'] == destinationId) {
            for (var acc in destination['accommodations']) {
              if (acc['id'] == accommodation['id']) {
                acc['checkInDate'] = Timestamp.fromDate(checkInDate);
                acc['checkOutDate'] = Timestamp.fromDate(checkOutDate);
                acc['nightCount'] = nightCount;
                acc['modifiedAt'] = Timestamp.now();
                break;
              }
            }
            break;
          }
        }
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Booking updated successfully')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error updating booking: $e')),
      );
    }
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
    //final destinationId = destination['id'] as String;
    //print(destinationId);
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
          // Activities Section for this destination
          Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: TripAttractionsDisplay(
              tripPlanId: widget.tripPlanId,
              destinationId: destination['id'],
              destinationName: destination['destinationName'],
            ),
          ),

          const Divider(thickness: 0.5),

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
                destination['accommodations'] == null ||
                        destination['accommodations'].isEmpty
                    ? const SizedBox.shrink()
                    : Column(
                        children: destination['accommodations']
                            .map<Widget>((accommodation) =>
                                _buildAccommodationCard(accommodation))
                            .toList(),
                      ),
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
                    _navigateToEditDestinationScreen(destination);
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

  void _showModifyTransportDialog(Map<String, dynamic> transport) {
    // Find which destination this transport belongs to
    String? destinationId;
    Map<String, dynamic>? destinationData;

    for (var destination in _destinations) {
      if (destination['transportBookings'] != null) {
        for (var tr in destination['transportBookings']) {
          if (tr['id'] == transport['id']) {
            destinationId = destination['id'];
            destinationData = destination;
            break;
          }
        }
      }
      if (destinationId != null) break;
    }

    if (destinationId == null || destinationData == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not find destination data')),
      );
      return;
    }

    // Create controllers with existing values
    final companyController = TextEditingController(text: transport['company']);
    final typeController =
        TextEditingController(text: transport['transportType']);
    final departureController =
        TextEditingController(text: transport['departure']);
    final destinationController =
        TextEditingController(text: transport['destination']);
    final departureTimeController =
        TextEditingController(text: transport['departureTime']);
    final priceController =
        TextEditingController(text: transport['price'].toString());

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Modify Transport Booking'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: companyController,
                  decoration: const InputDecoration(labelText: 'Company'),
                ),
                TextField(
                  controller: typeController,
                  decoration:
                      const InputDecoration(labelText: 'Transport Type'),
                ),
                TextField(
                  controller: departureController,
                  decoration: const InputDecoration(labelText: 'Departure'),
                ),
                TextField(
                  controller: destinationController,
                  decoration: const InputDecoration(labelText: 'Destination'),
                ),
                TextField(
                  controller: departureTimeController,
                  decoration:
                      const InputDecoration(labelText: 'Departure Time'),
                  onTap: () async {
                    // Show time picker
                    final TimeOfDay? picked = await showTimePicker(
                      context: context,
                      initialTime: TimeOfDay.now(),
                    );
                    if (picked != null) {
                      // Format time and update controller
                      departureTimeController.text =
                          '${picked.hour}:${picked.minute.toString().padLeft(2, '0')}';
                    }
                  },
                ),
                TextField(
                  controller: priceController,
                  decoration: const InputDecoration(labelText: 'Price (PKR)'),
                  keyboardType: TextInputType.number,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('CANCEL'),
            ),
            TextButton(
              onPressed: () {
                // Update transport details
                transport['company'] = companyController.text;
                transport['transportType'] = typeController.text;
                transport['departure'] = departureController.text;
                transport['destination'] = destinationController.text;
                transport['departureTime'] = departureTimeController.text;
                transport['price'] =
                    int.tryParse(priceController.text) ?? transport['price'];

                // Update the booking in destination data
                for (var i = 0;
                    i < destinationData!['transportBookings'].length;
                    i++) {
                  if (destinationData['transportBookings'][i]['id'] ==
                      transport['id']) {
                    destinationData['transportBookings'][i] = transport;
                    break;
                  }
                }

                // Close dialog and show confirmation
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                      content: Text('Transport booking updated successfully')),
                );

                // Refresh UI
                setState(() {});
              },
              child: const Text('SAVE CHANGES'),
            ),
          ],
        );
      },
    );
  }

// Show confirmation dialog for canceling transport
  void _showCancelTransportConfirmation(Map<String, dynamic> transport) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Cancel Transport Booking'),
          content: Text(
              'Are you sure you want to cancel your booking with ${transport['company']}?'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('NO'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                _cancelTransportBooking(transport);
              },
              child: const Text(
                'YES, CANCEL',
                style: TextStyle(color: Colors.red),
              ),
            ),
          ],
        );
      },
    );
  }

// Delete the transport booking from Firestore
  Future<void> _cancelTransportBooking(Map<String, dynamic> transport) async {
    try {
      // First find which destination this transport belongs to
      String? destinationId;

      for (var destination in _destinations) {
        if (destination['transportBookings'] != null) {
          for (var tr in destination['transportBookings']) {
            if (tr['id'] == transport['id']) {
              destinationId = destination['id'];
              break;
            }
          }
        }
        if (destinationId != null) break;
      }

      if (destinationId != null) {
        // Delete from Firestore
        await FirebaseFirestore.instance
            .collection('tripPlans')
            .doc(widget.tripPlanId)
            .collection('tripDestinations')
            .doc(destinationId)
            .collection('transportation')
            .doc(transport['id'])
            .delete();

        // Update local state
        setState(() {
          for (var destination in _destinations) {
            if (destination['id'] == destinationId) {
              destination['transportBookings']
                  .removeWhere((tr) => tr['id'] == transport['id']);
              break;
            }
          }
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Transport booking cancelled successfully')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error cancelling transport booking: $e')),
      );
    }
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
            Padding(
              padding: const EdgeInsets.only(top: 12.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton.icon(
                    icon: const Icon(Icons.edit, size: 16),
                    label: const Text('Modify'),
                    onPressed: () {
                      _showModifyTransportDialog(transport);
                    },
                  ),
                  const SizedBox(width: 8),
                  TextButton.icon(
                    icon: const Icon(Icons.cancel, size: 16, color: Colors.red),
                    label: const Text('Cancel',
                        style: TextStyle(color: Colors.red)),
                    onPressed: () {
                      _showCancelTransportConfirmation(transport);
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
              // Add Accommodation Button
              ElevatedButton.icon(
                icon: const Icon(Icons.hotel),
                label: const Text("Add Accommodation"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                  minimumSize: const Size(double.infinity, 40),
                ),
                onPressed: () {
                  Navigator.pop(context); // Close bottom sheet

                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => DisplayAccommodationsScreen(
                        destinationID: destination['id'],
                        destinationName: destination['destinationName'] ??
                            'unknown destination',
                        tripPlanId: widget.tripPlanId,
                      ),
                    ),
                  );
                },
              ),
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

      // Update trip dates if there are still destinations
      if (_destinations.isNotEmpty) {
        // Get the earliest start date and latest end date
        final earliestStartDate =
            (_destinations.first['startDate'] as Timestamp).toDate();
        final latestEndDate =
            (_destinations.last['endDate'] as Timestamp).toDate();

        // Calculate total days
        final difference =
            latestEndDate.difference(earliestStartDate).inDays + 1;

        // Update the trip dates in Firestore
        await FirebaseFirestore.instance
            .collection('tripPlans')
            .doc(widget.tripPlanId)
            .update({
          'startDate': Timestamp.fromDate(earliestStartDate),
          'endDate': Timestamp.fromDate(latestEndDate),
          'totalDays': difference,
        });

        // Update local state
        setState(() {
          _tripData!['startDate'] = Timestamp.fromDate(earliestStartDate);
          _tripData!['endDate'] = Timestamp.fromDate(latestEndDate);
          _tripData!['totalDays'] = difference;
        });
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Destination removed successfully')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error removing destination: $e')),
      );
    }
  }

  Future<void> _shareTrip() async {
    if (_tripData == null) return;

    try {
      // Build a formatted trip summary
      final StringBuffer tripSummary = StringBuffer();

      // Trip title and basic info
      tripSummary.writeln('🧳 ${_currentTripName.toUpperCase()} 🧳');
      tripSummary.writeln('');

      // Trip dates
      final startDate = (_tripData!['startDate'] as Timestamp).toDate();
      final endDate = (_tripData!['endDate'] as Timestamp).toDate();
      tripSummary.writeln(
          '📅 ${_formatDate(Timestamp.fromDate(startDate))} - ${_formatDate(Timestamp.fromDate(endDate))}');
      tripSummary.writeln('⏱️ ${_tripData!['totalDays']} days');
      tripSummary.writeln('👥 ${_tripData!['numberOfTravelers']} travelers');
      tripSummary.writeln('');

      // Destinations
      tripSummary.writeln('📍 DESTINATIONS:');
      for (int i = 0; i < _destinations.length; i++) {
        final destination = _destinations[i];
        final destStartDate = (destination['startDate'] as Timestamp).toDate();
        final destEndDate = (destination['endDate'] as Timestamp).toDate();

        tripSummary.writeln('${i + 1}. ${destination['destinationName']}');
        tripSummary.writeln(
            '   ${_formatDate(Timestamp.fromDate(destStartDate))} - ${_formatDate(Timestamp.fromDate(destEndDate))} (${destination['daysOfStay']} days)');

        // Add attractions if any
        final attractionsSnapshot = await FirebaseFirestore.instance
            .collection('tripPlans')
            .doc(widget.tripPlanId)
            .collection('tripDestinations')
            .doc(destination['id'])
            .collection('localAttractions')
            .get();

        if (attractionsSnapshot.docs.isNotEmpty) {
          tripSummary.writeln('   🎯 Activities:');
          for (int j = 0; j < attractionsSnapshot.docs.length; j++) {
            final attraction = attractionsSnapshot.docs[j].data();
            tripSummary.writeln('   - ${attraction['name']}');
          }
        }

        // Add accommodations if any
        if (destination['accommodations'] != null &&
            destination['accommodations'].isNotEmpty) {
          tripSummary.writeln('   🏨 Accommodations:');
          for (var accommodation in destination['accommodations']) {
            tripSummary.writeln('   - ${accommodation['name']}');
          }
        }

        // Add transport bookings if any
        if (destination['transportBookings'] != null &&
            destination['transportBookings'].isNotEmpty) {
          tripSummary.writeln('   🚌 Transportation:');
          for (var transport in destination['transportBookings']) {
            tripSummary.writeln(
                '   - ${transport['transportType']} from ${transport['departure']} to ${transport['destination']}');
          }
        }

        tripSummary.writeln('');
      }

      // App signature
      tripSummary.writeln('Shared via Humsafar App 📱');

      // Share the trip summary
      await Share.share(
        tripSummary.toString(),
        subject: 'My Trip Plan: $_currentTripName',
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error sharing trip: $e')),
      );
    }
  }
}
