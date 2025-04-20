import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class EditDestinationScreen extends StatefulWidget {
  final String tripPlanId;
  final String destinationId;
  final Map<String, dynamic> destinationData;

  const EditDestinationScreen({
    super.key,
    required this.tripPlanId,
    required this.destinationId,
    required this.destinationData,
  });

  @override
  State<EditDestinationScreen> createState() => _EditDestinationScreenState();
}

class _EditDestinationScreenState extends State<EditDestinationScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;

  late TextEditingController _destinationNameController;
  //late TextEditingController _notesController;
  late DateTime _startDate;
  late DateTime _endDate;
  late int _daysOfStay;

  @override
  void initState() {
    super.initState();

    // Initialize controllers with existing data
    _destinationNameController = TextEditingController(
      text: widget.destinationData['destinationName'],
    );

    _startDate = (widget.destinationData['startDate'] as Timestamp).toDate();
    _endDate = (widget.destinationData['endDate'] as Timestamp).toDate();
    _daysOfStay = widget.destinationData['daysOfStay'];
  }

  @override
  void dispose() {
    _destinationNameController.dispose();
    //_notesController.dispose();
    super.dispose();
  }

  // Function to pick date
  Future<void> _selectDate(BuildContext context, bool isStartDate) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: isStartDate ? _startDate : _endDate,
      firstDate: isStartDate ? DateTime.now() : _startDate,
      lastDate: DateTime(2100),
    );

    if (picked != null) {
      setState(() {
        if (isStartDate) {
          _startDate = picked;
          // Recalculate days of stay
          _daysOfStay = _endDate.difference(_startDate).inDays + 1;
        } else {
          _endDate = picked;
          // Recalculate days of stay
          _daysOfStay = _endDate.difference(_startDate).inDays + 1;
        }
      });
    }
  }

  Future<void> _updateDestination() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      // Check for date overlaps with other destinations (excluding the current one being edited)
      bool hasOverlap = await _checkForDateOverlaps(_startDate, _endDate);

      if (hasOverlap) {
        setState(() {
          _isLoading = false;
        });
        return; // Stop the update process if there's an overlap
      }

      // Update destination document
      await FirebaseFirestore.instance
          .collection('tripPlans')
          .doc(widget.tripPlanId)
          .collection('tripDestinations')
          .doc(widget.destinationId)
          .update({
        'destinationName': _destinationNameController.text.trim(),
        'startDate': Timestamp.fromDate(_startDate),
        'endDate': Timestamp.fromDate(_endDate),
        'daysOfStay': _daysOfStay,
        //'notes': _notesController.text.trim(),
        'updatedAt': Timestamp.now(),
      });

      if (!mounted) return;

      // Return updated data to previous screen
      Navigator.pop(context, {
        'updated': true,
        'destination': {
          'destinationID': widget.destinationId,
          'destinationName': _destinationNameController.text.trim(),
          'startDate': Timestamp.fromDate(_startDate),
          'endDate': Timestamp.fromDate(_endDate),
          'daysOfStay': _daysOfStay,
          //'notes': _notesController.text.trim(),
        }
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error updating destination: $e')),
      );
    }
  }

  Future<bool> _checkForDateOverlaps(
      DateTime startDate, DateTime endDate) async {
    try {
      // Get all existing destinations in the trip plan
      final destinationsSnapshot = await FirebaseFirestore.instance
          .collection('tripPlans')
          .doc(widget.tripPlanId)
          .collection('tripDestinations')
          .get();

      // List to store any overlapping destinations for reporting to the user
      List<String> overlappingDestinations = [];

      // Check each destination for date overlaps
      for (final doc in destinationsSnapshot.docs) {
        // Skip the current destination being edited
        if (doc.id == widget.destinationId) continue;

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
              title: const Text('Cannot Update Destination'),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Destination'),
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Destination Name Field
                    TextFormField(
                      controller: _destinationNameController,
                      decoration: const InputDecoration(
                        labelText: 'Destination Name',
                        border: OutlineInputBorder(),
                      ),
                      readOnly: true,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Please enter destination name';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 20),

                    // Date Selection
                    Row(
                      children: [
                        Expanded(
                          child: InkWell(
                            onTap: () => _selectDate(context, true),
                            child: InputDecorator(
                              decoration: const InputDecoration(
                                labelText: 'Start Date',
                                border: OutlineInputBorder(),
                              ),
                              child: Text(
                                DateFormat('MMM dd, yyyy').format(_startDate),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: InkWell(
                            onTap: () => _selectDate(context, false),
                            child: InputDecorator(
                              decoration: const InputDecoration(
                                labelText: 'End Date',
                                border: OutlineInputBorder(),
                              ),
                              child: Text(
                                DateFormat('MMM dd, yyyy').format(_endDate),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),

                    // Days of Stay (Calculated)
                    Card(
                      color: Colors.grey[200],
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Days of Stay:',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '$_daysOfStay ${_daysOfStay == 1 ? 'day' : 'days'}',
                              style: const TextStyle(fontSize: 16),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Update Button
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.black,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      onPressed: _updateDestination,
                      child: const Text(
                        'UPDATE DESTINATION',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),

                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ),
    );
  }
}
