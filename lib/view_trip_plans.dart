import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'view_trip_details.dart';
import 'home.dart';

class ViewTripPlansScreen extends StatefulWidget {
  const ViewTripPlansScreen({super.key});

  @override
  State<ViewTripPlansScreen> createState() => _ViewTripPlansScreenState();
}

class _ViewTripPlansScreenState extends State<ViewTripPlansScreen> {
  late Stream<QuerySnapshot> _tripPlansStream;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _initTripPlansStream();
  }

  void _initTripPlansStream() {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      _tripPlansStream = FirebaseFirestore.instance
          .collection('tripPlans')
          .where('userID', isEqualTo: user.uid)
          .orderBy('startDate', descending: false)
          .snapshots();

      setState(() {
        _isLoading = false;
      });
    }
  }

  String _formatDate(Timestamp timestamp) {
    final date = timestamp.toDate();
    return DateFormat('MMM dd, yyyy').format(date);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Trip Plans'),
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : StreamBuilder<QuerySnapshot>(
              stream: _tripPlansStream,
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(
                    child: Text('Error: ${snapshot.error}'),
                  );
                }

                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                final tripPlans = snapshot.data!.docs;

                if (tripPlans.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.hiking,
                          size: 80,
                          color: Colors.grey,
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'No trip plans yet',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Add destinations to start planning your next adventure',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.grey),
                        ),
                        const SizedBox(height: 24),
                        ElevatedButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (context) => const HomeScreen()),
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.black,
                            foregroundColor: Colors.white,
                          ),
                          child: const Text('Explore Destinations'),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: tripPlans.length,
                  itemBuilder: (context, index) {
                    final tripPlan = tripPlans[index];
                    final tripData = tripPlan.data() as Map<String, dynamic>;

                    final tripName = tripData['name'] as String;
                    final startDate = tripData['startDate'] as Timestamp;
                    final endDate = tripData['endDate'] as Timestamp;
                    final numberOfTravelers =
                        tripData['numberOfTravelers'] as int;
                    final isCompleted = tripData['isCompleted'] as bool;

                    return Card(
                      margin: const EdgeInsets.only(bottom: 16),
                      elevation: 2,
                      color: const Color.fromARGB(255, 190, 185, 185),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Trip name and status indicator
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    tripName,
                                    style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: isCompleted
                                        ? Colors.grey
                                        : const Color.fromARGB(
                                            255, 94, 58, 105),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    isCompleted ? 'Completed' : 'Upcoming',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),

                            // Trip dates
                            Row(
                              children: [
                                const Icon(Icons.calendar_today, size: 16),
                                const SizedBox(width: 8),
                                Text(
                                  '${_formatDate(startDate)} - ${_formatDate(endDate)}',
                                  style: const TextStyle(
                                    color: Color.fromARGB(255, 20, 4, 4),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),

                            // Number of travelers
                            Row(
                              children: [
                                const Icon(Icons.person, size: 16),
                                const SizedBox(width: 8),
                                Text(
                                  '$numberOfTravelers ${numberOfTravelers == 1 ? 'Traveler' : 'Travelers'}',
                                  style: const TextStyle(
                                    color: Color.fromARGB(255, 20, 4, 4),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),

                            // Show Details button
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton(
                                onPressed: () {
                                  // Navigate to trip details screen
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) =>
                                          TripPlanDetailsScreen(
                                        tripPlanId: tripPlan.id,
                                        tripName: tripName,
                                      ),
                                    ),
                                  );
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.black,
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                                child: const Text('SHOW DETAILS'),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
    );
  }
}
