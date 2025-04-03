import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class EditTripPlanScreen extends StatefulWidget {
  final String tripPlanId;
  final Map<String, dynamic> tripData;
  final String tripName;

  const EditTripPlanScreen({
    super.key,
    required this.tripPlanId,
    required this.tripData,
    required this.tripName,
  });

  @override
  State<EditTripPlanScreen> createState() => _EditTripPlanScreenState();
}

class _EditTripPlanScreenState extends State<EditTripPlanScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _tripNameController;
  late DateTime _startDate;
  late DateTime _endDate;
  late int _numberOfTravelers;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _tripNameController = TextEditingController(text: widget.tripName);
    _startDate = (widget.tripData['startDate'] as Timestamp).toDate();
    _endDate = (widget.tripData['endDate'] as Timestamp).toDate();
    _numberOfTravelers = widget.tripData['numberOfTravelers'] as int;
  }

  @override
  void dispose() {
    _tripNameController.dispose();
    super.dispose();
  }

  int _calculateTotalDays() {
    return _endDate.difference(_startDate).inDays + 1;
  }

  Future<void> _saveTrip() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      // Update the trip data in Firestore, but don't change dates
      await FirebaseFirestore.instance
          .collection('tripPlans')
          .doc(widget.tripPlanId)
          .update({
        'name': _tripNameController.text.trim(),
        'numberOfTravelers': _numberOfTravelers,
        'updatedAt': Timestamp.now(),
        // We're no longer updating startDate, endDate, or totalDays here
      });

      if (mounted) {
        Navigator.pop(context, {
          'name': _tripNameController.text.trim(),
          'updated': true,
        });
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error updating trip: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Trip Plan'),
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Form(
              key: _formKey,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Trip Name
                    const SizedBox(height: 20),
                    TextFormField(
                      controller: _tripNameController,
                      decoration: const InputDecoration(
                        labelText: 'Trip Name',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.flight_takeoff),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Please enter a trip name';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 24),

                    // Date Display (Read-only)
                    const Text(
                      'Trip Dates',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Trip dates are automatically set based on your destinations',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.grey.shade300),
                              borderRadius: BorderRadius.circular(4),
                              color: Colors.grey.shade100,
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Start Date',
                                  style: TextStyle(
                                    color: Colors.grey,
                                    fontSize: 12,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    const Icon(Icons.calendar_today,
                                        size: 16, color: Colors.grey),
                                    const SizedBox(width: 8),
                                    Text(
                                      DateFormat('MMM dd, yyyy')
                                          .format(_startDate),
                                      style: const TextStyle(fontSize: 16),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.grey.shade300),
                              borderRadius: BorderRadius.circular(4),
                              color: Colors.grey.shade100,
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'End Date',
                                  style: TextStyle(
                                    color: Colors.grey,
                                    fontSize: 12,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    const Icon(Icons.calendar_today,
                                        size: 16, color: Colors.grey),
                                    const SizedBox(width: 8),
                                    Text(
                                      DateFormat('MMM dd, yyyy')
                                          .format(_endDate),
                                      style: const TextStyle(fontSize: 16),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Total Days: ${_calculateTotalDays()}',
                      style: const TextStyle(
                        fontSize: 14,
                        color: Colors.grey,
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Number of Travelers
                    const Text(
                      'Number of Travelers',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.remove_circle_outline),
                          onPressed: _numberOfTravelers > 1
                              ? () {
                                  setState(() {
                                    _numberOfTravelers--;
                                  });
                                }
                              : null,
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 8),
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            '$_numberOfTravelers',
                            style: const TextStyle(fontSize: 16),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.add_circle_outline),
                          onPressed: () {
                            setState(() {
                              _numberOfTravelers++;
                            });
                          },
                        ),
                        const SizedBox(width: 8),
                        Text(
                          _numberOfTravelers == 1 ? 'Traveler' : 'Travelers',
                          style: const TextStyle(fontSize: 16),
                        ),
                      ],
                    ),
                    const SizedBox(height: 52),

                    // Save Button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.black,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                        onPressed: _saveTrip,
                        child: const Text(
                          'SAVE CHANGES',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
