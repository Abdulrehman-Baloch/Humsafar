import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:firebase_auth/firebase_auth.dart';

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
  final _notesController = TextEditingController();

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
    _notesController.dispose();
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
    // Get trip plan dates for validation
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
          ? tripStartDate ?? DateTime.now() // Can't start before trip start
          : (_startDate ?? tripStartDate ?? DateTime.now()),
      lastDate:
          tripEndDate ?? DateTime.now().add(const Duration(days: 365 * 2)),
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

  Future<void> _addDestinationToTripPlan() async {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedTripPlanId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a trip plan')),
      );
      return;
    }

    try {
      // Add this destination to the selected trip plan
      final destinationData = {
        'destinationID': widget.destinationID,
        'destinationName': widget.destinationName,
        'startDate': Timestamp.fromDate(_startDate!),
        'endDate': Timestamp.fromDate(_endDate!),
        'daysOfStay': _daysOfStay,
        'notes': _notesController.text,
        'addedAt': FieldValue.serverTimestamp(),
      };

      // Add destination to the trip plan
      await FirebaseFirestore.instance
          .collection('tripPlans')
          .doc(_selectedTripPlanId)
          .collection('tripDestinations')
          .add(destinationData);

      // Update the trip plan's "updatedAt" field
      await FirebaseFirestore.instance
          .collection('tripPlans')
          .doc(_selectedTripPlanId)
          .update({
        'updatedAt': FieldValue.serverTimestamp(),
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Destination added to trip plan successfully!')),
      );

      Navigator.pop(context);
    } catch (e) {
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

                      if (_selectedTripPlan != null) ...[
                        const SizedBox(height: 8),
                        Card(
                          color: const Color.fromARGB(255, 245, 245, 245),
                          child: Padding(
                            padding: const EdgeInsets.all(12.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Trip: ${_selectedTripPlan!['name']}',
                                  style: const TextStyle(
                                      fontWeight: FontWeight.bold),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Duration: ${_selectedTripPlan!['totalDays']} days with ${_selectedTripPlan!['numberOfTravelers']} travelers',
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
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
                      if (_daysOfStay > 0)
                        Padding(
                          padding: const EdgeInsets.only(top: 8.0),
                          child: Text(
                            'Duration at this destination: $_daysOfStay days',
                            style: TextStyle(
                              fontWeight: FontWeight.w500,
                              color: Colors.blue[800],
                            ),
                          ),
                        ),
                      const SizedBox(height: 24),

                      // Notes
                      TextFormField(
                        controller: _notesController,
                        decoration: const InputDecoration(
                          labelText: 'Notes about this destination',
                          border: OutlineInputBorder(),
                          hintText:
                              'Key places to visit, activities, special requirements...',
                        ),
                        maxLines: 3,
                      ),
                      const SizedBox(height: 32),

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
