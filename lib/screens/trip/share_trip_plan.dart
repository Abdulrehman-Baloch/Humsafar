// trip_share_service.dart
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:screenshot/screenshot.dart';
import 'package:share_plus/share_plus.dart';

class ShareTripPlan {
  // Controller for taking screenshots
  final ScreenshotController screenshotController = ScreenshotController();

  // Share trip as an image
  Future<void> shareTrip(
    BuildContext context, {
    required String tripPlanId,
    required String tripName,
    required Map<String, dynamic> tripData,
    required List<Map<String, dynamic>> destinations,
  }) async {
    try {
      // Show loading indicator
      showDialog(
          context: context,
          barrierDismissible: false,
          builder: (BuildContext context) {
            return Dialog(
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const CircularProgressIndicator(),
                    const SizedBox(width: 20),
                    const Text("Creating share image..."),
                  ],
                ),
              ),
            );
          });

      // Fetch additional details for destinations
      final List<Map<String, dynamic>> enrichedDestinations =
          await _fetchDestinationDetails(tripPlanId, destinations);

      // Capture widget as image
      final Uint8List imageBytes = await screenshotController.captureFromWidget(
        _buildShareableCard(tripName, tripData, enrichedDestinations),
        delay: const Duration(milliseconds: 10),
        context: context,
        pixelRatio: 3.0,
      );

      // Close loading dialog
      Navigator.pop(context);

      // Share the image directly using bytes
      await Share.shareXFiles(
        [
          XFile.fromData(
            imageBytes,
            name: 'trip_plan.png',
            mimeType: 'image/png',
          )
        ],
        text: 'Check out my trip plan on Humsafar!',
        subject: 'My Trip Plan: $tripName',
      );
    } catch (e) {
      // Close loading dialog if open
      if (context.mounted && Navigator.canPop(context)) {
        Navigator.pop(context);
      }

      // Show error
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error sharing trip: $e')),
        );
      }
    }
  }

  // Fetch destination details including activities and bookings
  Future<List<Map<String, dynamic>>> _fetchDestinationDetails(
      String tripPlanId, List<Map<String, dynamic>> destinations) async {
    List<Map<String, dynamic>> enrichedDestinations = [];

    for (var destination in destinations) {
      Map<String, dynamic> enrichedDestination = {...destination};

      // Fetch activities
      final attractionsSnapshot = await FirebaseFirestore.instance
          .collection('tripPlans')
          .doc(tripPlanId)
          .collection('tripDestinations')
          .doc(destination['id'])
          .collection('localAttractions')
          .get();

      enrichedDestination['activities'] =
          attractionsSnapshot.docs.map((doc) => doc.data()).toList();

      // Transportation and accommodations should already be in destination data
      // as 'transportBookings' and 'accommodations'

      enrichedDestinations.add(enrichedDestination);
    }

    return enrichedDestinations;
  }

  // Build a visually appealing card for sharing
  Widget _buildShareableCard(
    String tripName,
    Map<String, dynamic> tripData,
    List<Map<String, dynamic>> destinations,
  ) {
    return Container(
      width: 1080,
      padding: const EdgeInsets.only(bottom: 16),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF7B1FA2), // Primary purple
            Color(0xFF9C27B0), // Medium purple
            Color(0xFF8E24AA), // Light purple
          ],
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header with app logo and trip status
          Container(
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.1),
            ),
            child: Row(
              children: [
                Image.asset(
                  'assets/images/logo.png', // Replace with your app logo
                  width: 40,
                  height: 40,
                  errorBuilder: (context, error, stackTrace) => const Icon(
                    Icons.travel_explore,
                    color: Colors.white,
                    size: 40,
                  ),
                ),
                const SizedBox(width: 12),
                const Text(
                  'Humsafar',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    tripData['isCompleted'] == true ? 'Completed' : 'Upcoming',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Trip title
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 4),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                tripName,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 36,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                ),
              ),
            ),
          ),

          // Trip details section
          Container(
            margin: const EdgeInsets.fromLTRB(20, 16, 20, 24),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.15),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              children: [
                // Trip dates
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.calendar_today,
                          color: Colors.white, size: 20),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Trip Dates',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${DateFormat('MMM dd').format((tripData['startDate'] as Timestamp).toDate())} - ${DateFormat('MMM dd, yyyy').format((tripData['endDate'] as Timestamp).toDate())}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                // Duration and travelers
                Row(
                  children: [
                    Expanded(
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(Icons.timelapse,
                                color: Colors.white, size: 20),
                          ),
                          const SizedBox(width: 12),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Duration',
                                style: TextStyle(
                                    color: Colors.white70, fontSize: 14),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '${tripData['totalDays']} days',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(Icons.people,
                                color: Colors.white, size: 20),
                          ),
                          const SizedBox(width: 12),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Travelers',
                                style: TextStyle(
                                    color: Colors.white70, fontSize: 14),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '${tripData['numberOfTravelers']}',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Destinations section
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(12),
                      topRight: Radius.circular(12),
                    ),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.place, color: Colors.white, size: 18),
                      SizedBox(width: 8),
                      Text(
                        'DESTINATIONS',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.2,
                        ),
                      ),
                    ],
                  ),
                ),

                // List destinations with details
                ...destinations
                    .take(3)
                    .map((destination) => _buildDestinationCard(destination))
                    ,

                if (destinations.length > 3)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8.0),
                    child: Center(
                      child: Text(
                        '+ ${destinations.length - 3} more destinations',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.8),
                          fontSize: 14,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),

          // Bottom tag
          const Spacer(),
          Center(
            child: Container(
              margin: const EdgeInsets.only(top: 24),
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Text(
                'Shared via Humsafar App',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Build a destination card with activities and bookings
  Widget _buildDestinationCard(Map<String, dynamic> destination) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.15),
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(12),
          bottomRight: Radius.circular(12),
          topRight: Radius.circular(12),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Destination header
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        destination['destinationName'],
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${DateFormat('MMM dd').format((destination['startDate'] as Timestamp).toDate())} - ${DateFormat('MMM dd').format((destination['endDate'] as Timestamp).toDate())}',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.9),
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    '${destination['daysOfStay']} days',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Activities section
          if (destination['activities'] != null &&
              (destination['activities'] as List).isNotEmpty)
            _buildSectionCard(
              'Activities',
              Icons.attractions,
              _buildActivitiesList(destination['activities'] as List),
            ),

          // Accommodations section
          if (destination['accommodations'] != null &&
              (destination['accommodations'] as List).isNotEmpty)
            _buildSectionCard(
              'Accommodations',
              Icons.hotel,
              _buildAccommodationsList(destination['accommodations'] as List),
            ),

          // Transportation section
          if (destination['transportBookings'] != null &&
              (destination['transportBookings'] as List).isNotEmpty)
            _buildSectionCard(
              'Transportation',
              Icons.directions_bus,
              _buildTransportList(destination['transportBookings'] as List),
            ),
        ],
      ),
    );
  }

  // Build a section card (Activities, Accommodations, Transportation)
  Widget _buildSectionCard(String title, IconData icon, Widget content) {
    return Container(
      padding: const EdgeInsets.all(12),
      margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: Colors.white70, size: 16),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          content,
        ],
      ),
    );
  }

  // Build activities list
  Widget _buildActivitiesList(List activities) {
    if (activities.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      children: activities.take(3).map<Widget>((activity) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 6),
          child: Row(
            children: [
              const Icon(Icons.circle, color: Colors.white38, size: 8),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  activity['name'] ?? 'Unknown Activity',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  // Build accommodations list
  Widget _buildAccommodationsList(List accommodations) {
    if (accommodations.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      children: accommodations.take(2).map<Widget>((accommodation) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 6),
          child: Row(
            children: [
              const Icon(Icons.circle, color: Colors.white38, size: 8),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  accommodation['name'] ?? 'Unknown Accommodation',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  // Build transport list
  Widget _buildTransportList(List transports) {
    if (transports.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      children: transports.take(2).map<Widget>((transport) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 6),
          child: Row(
            children: [
              const Icon(Icons.circle, color: Colors.white38, size: 8),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  '${transport['transportType']} (${transport['departure']} → ${transport['destination']})',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}
