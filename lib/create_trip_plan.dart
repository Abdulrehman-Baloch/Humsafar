import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:firebase_auth/firebase_auth.dart';

class CreateTripPlanScreen extends StatefulWidget {
  final String destinationID;
  final String destinationName;

  const CreateTripPlanScreen({
    super.key,
    required this.destinationID,
    required this.destinationName,
  });

  @override
  State<CreateTripPlanScreen> createState() => _CreateTripPlanScreenState();
}

class _CreateTripPlanScreenState extends State<CreateTripPlanScreen> {
  // Form controllers
  final _startDateController = TextEditingController();
  final _endDateController = TextEditingController();
  final _notesController = TextEditingController();
  final _tripPlanNameController = TextEditingController();

  // Form values
  DateTime? _startDate;
  DateTime? _endDate;
  int _numberOfTravelers = 1;

  // Form key for validation
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    _startDateController.dispose();
    _endDateController.dispose();
    _notesController.dispose();
    _tripPlanNameController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context, bool isStartDate) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: isStartDate
          ? (_startDate ?? DateTime.now())
          : (_endDate ??
              (_startDate != null
                  ? _startDate!.add(const Duration(days: 1))
                  : DateTime.now().add(const Duration(days: 1)))),
      firstDate: isStartDate
          ? DateTime.now()
          : (_startDate ?? DateTime.now()).add(const Duration(days: 1)),
      lastDate: DateTime.now().add(const Duration(days: 365 * 2)),
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

  Future<void> _createNewTripPlan() async {
    if (!_formKey.currentState!.validate()) return;

    // Get current user
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('You need to be logged in to save a trip plan')),
      );
      return;
    }

    try {
      // Create new trip plan with this destination
      await _createNewTripPlanWithDestination();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Trip plan created successfully!')),
      );

      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error creating trip plan: $e')),
      );
    }
  }

  Future<void> _createNewTripPlanWithDestination() async {
    final user = FirebaseAuth.instance.currentUser!;

    // First create the trip plan
    final tripPlanData = {
      'name': _tripPlanNameController.text.isNotEmpty
          ? _tripPlanNameController.text
          : 'Trip to ${widget.destinationName}',
      'userID': user.uid,
      'userEmail': user.email,
      'startDate': Timestamp.fromDate(_startDate!),
      'endDate': Timestamp.fromDate(_endDate!),
      'totalDays': _daysOfStay,
      'numberOfTravelers': _numberOfTravelers,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
      'isCompleted': false,
    };

    // Create trip plan document
    final docRef = await FirebaseFirestore.instance
        .collection('tripPlans')
        .add(tripPlanData);

    // Add this destination to the new trip plan
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
    await docRef.collection('tripDestinations').add(destinationData);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Create New Trip Plan'),
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
      ),
      body: Form(
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

                // Trip Plan Section
                const Text(
                  'Trip Plan',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),

                // Text field for new trip plan name
                TextFormField(
                  controller: _tripPlanNameController,
                  decoration: const InputDecoration(
                    labelText: 'Trip Plan Name',
                    border: OutlineInputBorder(),
                    hintText: 'E.g., Summer Vacation 2025',
                  ),
                ),
                const SizedBox(height: 24),

                // Travel dates section
                const Text(
                  'Stay Details',
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
                  onTap: () => _selectDate(context, true),
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
                  onTap: () => _selectDate(context, false),
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

                // Trip Details section
                const Text(
                  'Travelers',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),

                // Number of travelers
                Row(
                  children: [
                    const Text(
                      'Number of Travelers:',
                      style: TextStyle(fontSize: 16),
                    ),
                    const Spacer(),
                    IconButton(
                      icon: const Icon(Icons.remove),
                      onPressed: _numberOfTravelers > 1
                          ? () {
                              setState(() {
                                _numberOfTravelers--;
                              });
                            }
                          : null,
                    ),
                    Text(
                      '$_numberOfTravelers',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.add),
                      onPressed: () {
                        setState(() {
                          _numberOfTravelers++;
                        });
                      },
                    ),
                  ],
                ),
                const Divider(),
                const SizedBox(height: 16),

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

                // Create button
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: _createNewTripPlan,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.black,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: const Text(
                      'CREATE NEW TRIP PLAN',
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
