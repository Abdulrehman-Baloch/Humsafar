import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../widgets/trip/trip_timeline.dart';

class AddDestinationToExistingTripScreen extends StatefulWidget {
  final String destinationID;
  final String destinationName;

  const AddDestinationToExistingTripScreen({
    super.key,
    required this.destinationID,
    required this.destinationName,
  });

  @override
  State<AddDestinationToExistingTripScreen> createState() =>
      _AddDestinationToExistingTripScreenState();
}

class _AddDestinationToExistingTripScreenState
    extends State<AddDestinationToExistingTripScreen> {
  // Form controllers
  final _startDateController = TextEditingController();
  final _endDateController = TextEditingController();
  //final _notesController = TextEditingController();

  // Form values
  DateTime? _startDate;
  DateTime? _endDate;

  // Selected trip plan
  String? _selectedTripPlanId;
  Map<String, dynamic>? _selectedTripPlan;

  // Loading states
  bool _isLoading = true;

  // Available trip plans
  List<Map<String, dynamic>> _tripPlans = [];

  // Form key for validation
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    _loadUserTripPlans();
  }

  @override
  void dispose() {
    _startDateController.dispose();
    _endDateController.dispose();
    //_notesController.dispose();
    super.dispose();
  }

  // Load user's existing trip plans
  Future<void> _loadUserTripPlans() async {
    setState(() => _isLoading = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        throw Exception('User not logged in');
      }

      final snapshot = await FirebaseFirestore.instance
          .collection('tripPlans')
          .where('userID', isEqualTo: user.uid)
          .where('isCompleted', isEqualTo: false) // Only get active trips
          .orderBy('startDate', descending: true)
          .get();

      final plans = snapshot.docs.map((doc) {
        final data = doc.data();
        return {
          'id': doc.id,
          ...data,
        };
      }).toList();

      setState(() {
        _tripPlans = plans;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading trip plans: $e')),
      );
    }
  }

  Future<void> _selectDate(BuildContext context, bool isStartDate) async {
    // We'll keep trip dates as reference but allow selection outside these dates
    DateTime? tripStartDate, tripEndDate;

    if (_selectedTripPlan != null) {
      tripStartDate = (_selectedTripPlan!['startDate'] as Timestamp).toDate();
      tripEndDate = (_selectedTripPlan!['endDate'] as Timestamp).toDate();
    }

    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: isStartDate
          ? (_startDate ?? tripStartDate ?? DateTime.now())
          : (_endDate ??
              (_startDate != null
                  ? _startDate!.add(const Duration(days: 1))
                  : tripStartDate ?? DateTime.now())),
      firstDate: isStartDate
          ? DateTime.now().subtract(
              const Duration(days: 365)) // Allow past dates within reason
          : (_startDate ?? DateTime.now()), // End date must be after start date
      lastDate: DateTime.now()
          .add(const Duration(days: 365 * 5)), // Allow planning far in advance
    );

    if (picked != null) {
      setState(() {
        if (isStartDate) {
          _startDate = picked;
          _startDateController.text = DateFormat('MMM dd, yyyy').format(picked);

          // If end date is before start date, reset it
          if (_endDate != null && _endDate!.isBefore(_startDate!)) {
            _endDate = null;
            _endDateController.text = '';
          }
        } else {
          _endDate = picked;
          _endDateController.text = DateFormat('MMM dd, yyyy').format(picked);
        }
      });
    }
  }

  // Calculate number of days
  int get _daysOfStay {
    if (_startDate == null || _endDate == null) return 0;
    return _endDate!.difference(_startDate!).inDays + 1;
  }

  // When trip plan selection changes
  void _onTripPlanSelected(String tripPlanId) {
    final selectedPlan =
        _tripPlans.firstWhere((plan) => plan['id'] == tripPlanId);

    setState(() {
      _selectedTripPlanId = tripPlanId;
      _selectedTripPlan = selectedPlan;

      // Reset dates based on trip dates
      final tripStartDate = (selectedPlan['startDate'] as Timestamp).toDate();
      final tripEndDate = (selectedPlan['endDate'] as Timestamp).toDate();

      // Default destination dates to trip dates
      _startDate = tripStartDate;
      _endDate = tripEndDate;
      _startDateController.text =
          DateFormat('MMM dd, yyyy').format(tripStartDate);
      _endDateController.text = DateFormat('MMM dd, yyyy').format(tripEndDate);
    });
  }

  // Add this function to check for date overlaps with existing destinations
  Future<bool> _checkForDateOverlaps(
      DateTime startDate, DateTime endDate) async {
    try {
      // Get all existing destinations in the selected trip plan
      final destinationsSnapshot = await FirebaseFirestore.instance
          .collection('tripPlans')
          .doc(_selectedTripPlanId)
          .collection('tripDestinations')
          .get();

      // List to store any overlapping destinations for reporting to the user
      List<String> overlappingDestinations = [];

      // Check each destination for date overlaps
      for (final doc in destinationsSnapshot.docs) {
        final destData = doc.data();
        final destName = destData['destinationName'] as String;
        final destStartDate = (destData['startDate'] as Timestamp).toDate();
        final destEndDate = (destData['endDate'] as Timestamp).toDate();

        // Check if dates overlap - the complex condition covers all overlap scenarios
        if ((startDate.isBefore(destEndDate) ||
                startDate.isAtSameMomentAs(destEndDate)) &&
            (endDate.isAfter(destStartDate) ||
                endDate.isAtSameMomentAs(destStartDate))) {
          // Format dates for readable error message
          final startDateStr = DateFormat('MMM dd').format(destStartDate);
          final endDateStr = DateFormat('MMM dd').format(destEndDate);
          overlappingDestinations
              .add('$destName ($startDateStr - $endDateStr)');
        }
      }

      // If any overlaps were found, show error message with details
      if (overlappingDestinations.isNotEmpty) {
        String errorMessage =
            'Date overlap detected with:\n• ${overlappingDestinations.join('\n• ')}';

        // Show dialog with detailed information
        await showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: const Text('Cannot Add Destination'),
              content: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'You cannot be in two places at the same time!',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 12),
                    Text(errorMessage),
                    const SizedBox(height: 12),
                    const Text(
                      'Please choose different dates that don\'t overlap with existing destinations.',
                      style: TextStyle(fontStyle: FontStyle.italic),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  child: const Text('OK'),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            );
          },
        );
        return true; // Overlap exists
      }

      return false; // No overlap
    } catch (e) {
      // Handle any errors
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error checking date overlaps: $e')),
      );
      return true; // Return true to prevent saving on error
    }
  }

  Future<void> _addDestinationToTripPlan() async {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedTripPlanId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a trip plan')),
      );
      return;
    }

    try {
      // Check for overlapping dates before proceeding
      setState(() => _isLoading = true);

      // Check if the selected dates overlap with any existing destination
      bool hasOverlap = await _checkForDateOverlaps(_startDate!, _endDate!);

      if (hasOverlap) {
        setState(() => _isLoading = false);
        return; // Stop here if there are overlaps
      }

      // Proceed with adding the destination as before...
      // Add this destination to the selected trip plan
      final destinationData = {
        'destinationID': widget.destinationID,
        'destinationName': widget.destinationName,
        'startDate': Timestamp.fromDate(_startDate!),
        'endDate': Timestamp.fromDate(_endDate!),
        'daysOfStay': _daysOfStay,
        //'notes': _notesController.text,
        'addedAt': FieldValue.serverTimestamp(),
      };

      // Add destination to the trip plan
      await FirebaseFirestore.instance
          .collection('tripPlans')
          .doc(_selectedTripPlanId)
          .collection('tripDestinations')
          .add(destinationData);

      // Fetch all destinations in the trip plan including the newly added one
      final destinationsSnapshot = await FirebaseFirestore.instance
          .collection('tripPlans')
          .doc(_selectedTripPlanId)
          .collection('tripDestinations')
          .get();

      // Find earliest start date and latest end date among all destinations
      DateTime? earliestStartDate;
      DateTime? latestEndDate;

      for (final doc in destinationsSnapshot.docs) {
        final destData = doc.data();
        final destStartDate = (destData['startDate'] as Timestamp).toDate();
        final destEndDate = (destData['endDate'] as Timestamp).toDate();

        if (earliestStartDate == null ||
            destStartDate.isBefore(earliestStartDate)) {
          earliestStartDate = destStartDate;
        }

        if (latestEndDate == null || destEndDate.isAfter(latestEndDate)) {
          latestEndDate = destEndDate;
        }
      }

      // Only update trip dates if destinations exist and dates have changed
      if (earliestStartDate != null && latestEndDate != null) {
        // Get current trip dates for comparison
        final tripData = await FirebaseFirestore.instance
            .collection('tripPlans')
            .doc(_selectedTripPlanId)
            .get();

        final currentTripStartDate =
            (tripData['startDate'] as Timestamp).toDate();
        final currentTripEndDate = (tripData['endDate'] as Timestamp).toDate();

        // Check if trip dates need updating
        final needsUpdate =
            earliestStartDate.compareTo(currentTripStartDate) != 0 ||
                latestEndDate.compareTo(currentTripEndDate) != 0;

        if (needsUpdate) {
          // Calculate new total days
          final totalDays =
              latestEndDate.difference(earliestStartDate).inDays + 1;

          // Update the trip plan with new dates
          await FirebaseFirestore.instance
              .collection('tripPlans')
              .doc(_selectedTripPlanId)
              .update({
            'startDate': Timestamp.fromDate(earliestStartDate),
            'endDate': Timestamp.fromDate(latestEndDate),
            'totalDays': totalDays,
            'updatedAt': FieldValue.serverTimestamp(),
          });
        } else {
          // Just update the timestamp
          await FirebaseFirestore.instance
              .collection('tripPlans')
              .doc(_selectedTripPlanId)
              .update({
            'updatedAt': FieldValue.serverTimestamp(),
          });
        }
      }

      setState(() => _isLoading = false);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Destination added to trip plan successfully!')),
      );

      Navigator.pop(context);
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error adding destination: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add to Existing Trip Plan'),
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Form(
              key: _formKey,
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Destination info
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.grey,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.location_on, color: Colors.black),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                widget.destinationName,
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Trip Plan Selection Section
                      const Text(
                        'Select Trip Plan',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Trip plans dropdown
                      if (_tripPlans.isEmpty)
                        const Card(
                          color: Color.fromARGB(255, 245, 245, 245),
                          child: Padding(
                            padding: EdgeInsets.all(16.0),
                            child: Center(
                              child: Text(
                                'You have no active trip plans. Create a new trip plan first.',
                                textAlign: TextAlign.center,
                                style: TextStyle(fontSize: 16),
                              ),
                            ),
                          ),
                        )
                      else
                        DropdownButtonFormField<String>(
                          decoration: const InputDecoration(
                            labelText: 'Trip Plan',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.travel_explore),
                          ),
                          hint: const Text('Select a trip plan'),
                          value: _selectedTripPlanId,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please select a trip plan';
                            }
                            return null;
                          },
                          items: _tripPlans.map((plan) {
                            final startDate =
                                (plan['startDate'] as Timestamp).toDate();
                            final endDate =
                                (plan['endDate'] as Timestamp).toDate();
                            final formattedDates =
                                '${DateFormat('MMM dd').format(startDate)} - ${DateFormat('MMM dd, yyyy').format(endDate)}';

                            return DropdownMenuItem<String>(
                              value: plan['id'],
                              child: Text('${plan['name']} ($formattedDates)'),
                            );
                          }).toList(),
                          onChanged: (value) {
                            if (value != null) {
                              _onTripPlanSelected(value);
                            }
                          },
                        ),

                      // In the build method, after the _selectedTripPlan card, add:
                      if (_selectedTripPlan != null) ...[
                        const SizedBox(height: 16),
                        ExpansionTile(
                          title: const Text(
                            'View Existing Destinations',
                            style: TextStyle(
                                fontSize: 16, fontWeight: FontWeight.w500),
                          ),
                          subtitle: const Text('Check available dates'),
                          leading: const Icon(Icons.date_range),
                          children: [
                            FutureBuilder<QuerySnapshot>(
                              future: FirebaseFirestore.instance
                                  .collection('tripPlans')
                                  .doc(_selectedTripPlanId)
                                  .collection('tripDestinations')
                                  .orderBy('startDate')
                                  .get(),
                              builder: (context, snapshot) {
                                if (snapshot.connectionState ==
                                    ConnectionState.waiting) {
                                  return const Padding(
                                    padding: EdgeInsets.all(16.0),
                                    child: Center(
                                        child: CircularProgressIndicator()),
                                  );
                                }

                                if (snapshot.hasError) {
                                  return Padding(
                                    padding: const EdgeInsets.all(16.0),
                                    child: Text('Error: ${snapshot.error}'),
                                  );
                                }

                                if (!snapshot.hasData ||
                                    snapshot.data!.docs.isEmpty) {
                                  return const Padding(
                                    padding: EdgeInsets.all(16.0),
                                    child: Text(
                                        'No destinations in this trip yet'),
                                  );
                                }

                                // Show list of existing destinations with their dates
                                return ListView.builder(
                                  shrinkWrap: true,
                                  physics: const NeverScrollableScrollPhysics(),
                                  itemCount: snapshot.data!.docs.length,
                                  itemBuilder: (context, index) {
                                    final doc = snapshot.data!.docs[index];
                                    final data =
                                        doc.data() as Map<String, dynamic>;
                                    final name =
                                        data['destinationName'] as String;
                                    final startDate =
                                        (data['startDate'] as Timestamp)
                                            .toDate();
                                    final endDate =
                                        (data['endDate'] as Timestamp).toDate();

                                    return ListTile(
                                      contentPadding:
                                          const EdgeInsets.symmetric(
                                              horizontal: 24),
                                      title: Text(name),
                                      subtitle: Text(
                                          '${DateFormat('MMM dd').format(startDate)} - ${DateFormat('MMM dd').format(endDate)} (${data['daysOfStay']} days)'),
                                      dense: true,
                                    );
                                  },
                                );
                              },
                            ),
                          ],
                        ),
                      ],
                      const SizedBox(height: 16),
                      FutureBuilder<QuerySnapshot>(
                        future: FirebaseFirestore.instance
                            .collection('tripPlans')
                            .doc(_selectedTripPlanId)
                            .collection('tripDestinations')
                            .get(),
                        builder: (context, snapshot) {
                          if (snapshot.connectionState ==
                                  ConnectionState.waiting ||
                              !snapshot.hasData ||
                              _selectedTripPlan == null) {
                            return const SizedBox.shrink();
                          }

                          final destinations = snapshot.data!.docs.map((doc) {
                            return doc.data() as Map<String, dynamic>;
                          }).toList();

                          final tripStartDate =
                              (_selectedTripPlan!['startDate'] as Timestamp)
                                  .toDate();
                          final tripEndDate =
                              (_selectedTripPlan!['endDate'] as Timestamp)
                                  .toDate();

                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 8.0),
                            child: TripCalendarTimeline(
                              tripStartDate: tripStartDate,
                              tripEndDate: tripEndDate,
                              destinations: destinations,
                            ),
                          );
                        },
                      ),

                      const SizedBox(height: 24),

                      // Stay Details section
                      const Text(
                        'Stay Details at This Destination',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Start date picker
                      TextFormField(
                        controller: _startDateController,
                        decoration: const InputDecoration(
                          labelText: 'Arrival Date',
                          border: OutlineInputBorder(),
                          suffixIcon: Icon(Icons.calendar_today),
                        ),
                        readOnly: true,
                        onTap: _selectedTripPlanId == null
                            ? () => ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                      content: Text(
                                          'Please select a trip plan first')),
                                )
                            : () => _selectDate(context, true),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please select an arrival date';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),

                      // End date picker
                      TextFormField(
                        controller: _endDateController,
                        decoration: const InputDecoration(
                          labelText: 'Departure Date',
                          border: OutlineInputBorder(),
                          suffixIcon: Icon(Icons.calendar_today),
                        ),
                        readOnly: true,
                        onTap: _selectedTripPlanId == null
                            ? () => ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                      content: Text(
                                          'Please select a trip plan first')),
                                )
                            : () => _selectDate(context, false),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please select a departure date';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 8),

                      // Days of stay (calculated)
                      _daysOfStay > 0
                          ? Padding(
                              padding: const EdgeInsets.only(top: 8.0),
                              child: Text(
                                'Duration at this destination: $_daysOfStay days',
                                style: TextStyle(
                                  fontWeight: FontWeight.w500,
                                  color: Colors.blue[800],
                                ),
                              ),
                            )
                          : SizedBox.shrink(),
                      const SizedBox(height: 24),

                      // Add destination button
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton(
                          onPressed: _tripPlans.isEmpty
                              ? null
                              : _addDestinationToTripPlan,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.black,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            disabledBackgroundColor: Colors.grey,
                          ),
                          child: const Text(
                            'ADD TO TRIP PLAN',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 30),
                    ],
                  ),
                ),
              ),
            ),
    );
  }
}
