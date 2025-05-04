// local_attractions_selector.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class LocalAttractionsSelector extends StatefulWidget {
  final String tripPlanId;
  final String destinationId;
  final String destinationName;

  const LocalAttractionsSelector({
    super.key,
    required this.tripPlanId,
    required this.destinationId,
    required this.destinationName,
  });

  @override
  State<LocalAttractionsSelector> createState() =>
      _LocalAttractionsSelectorState();
}

class _LocalAttractionsSelectorState extends State<LocalAttractionsSelector> {
  bool _isLoading = true;
  List<Map<String, dynamic>> _attractions = [];
  Set<String> _selectedAttractionIds = {};
  String? _destinationId;

  @override
  void initState() {
    super.initState();
    _loadAttractions();
    _loadExistingAttractions();
  }

  // Load attractions already added to the trip plan
  Future<void> _loadExistingAttractions() async {
    try {
      final existingAttractionsSnapshot = await FirebaseFirestore.instance
          .collection('tripPlans')
          .doc(widget.tripPlanId)
          .collection('tripDestinations')
          .doc(widget.destinationId)
          .collection('localAttractions')
          .get();

      final existingIds = existingAttractionsSnapshot.docs
          .map((doc) => doc.data()['attractionId'] as String)
          .toSet();

      setState(() {
        _selectedAttractionIds = existingIds;
      });
    } catch (e) {
      // Just log error, doesn't affect the main functionality
      print('Error loading existing attractions: $e');
    }
  }

  Future<void> _loadAttractions() async {
    try {
      // First find the destination document with the matching name
      final destinationsSnapshot = await FirebaseFirestore.instance
          .collection('destinations')
          .where('name', isEqualTo: widget.destinationName)
          .limit(1)
          .get();

      if (destinationsSnapshot.docs.isNotEmpty) {
        final destinationDoc = destinationsSnapshot.docs.first;
        _destinationId = destinationDoc.id;

        // Now fetch the local attractions for this destination
        final attractionsSnapshot = await FirebaseFirestore.instance
            .collection('destinations')
            .doc(_destinationId)
            .collection('localAttractions')
            .get();

        final attractions = attractionsSnapshot.docs.map((doc) {
          return {
            'id': doc.id,
            ...doc.data(),
          };
        }).toList();

        setState(() {
          _attractions = attractions;
          _isLoading = false;
        });
      } else {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content:
                  Text('Destination "${widget.destinationName}" not found')),
        );
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading attractions: $e')),
      );
    }
  }

  void _toggleAttractionSelection(String attractionId) {
    setState(() {
      if (_selectedAttractionIds.contains(attractionId)) {
        _selectedAttractionIds.remove(attractionId);
      } else {
        _selectedAttractionIds.add(attractionId);
      }
    });
  }

  Future<void> _addToTripPlan() async {
    try {
      // Show loading indicator
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return const Center(
            child: CircularProgressIndicator(),
          );
        },
      );

      // Get selected attractions
      final selectedAttractions = _attractions
          .where(
              (attraction) => _selectedAttractionIds.contains(attraction['id']))
          .toList();

      // Add each attraction to the trip plan
      for (var attraction in selectedAttractions) {
        // Check if this attraction is already in the trip plan
        final existingDocs = await FirebaseFirestore.instance
            .collection('tripPlans')
            .doc(widget.tripPlanId)
            .collection('tripDestinations')
            .doc(widget.destinationId)
            .collection('localAttractions')
            .where('attractionId', isEqualTo: attraction['id'])
            .get();

        // Only add if not already in the trip plan
        if (existingDocs.docs.isEmpty) {
          await FirebaseFirestore.instance
              .collection('tripPlans')
              .doc(widget.tripPlanId)
              .collection('tripDestinations')
              .doc(widget.destinationId)
              .collection('localAttractions')
              .add({
            'attractionId': attraction['id'],
            'name': attraction['name'],
            'description': attraction['description'] ?? '',
            'imageUrl': attraction['imageUrl'] ?? '',
            'addedAt': Timestamp.now(),
          });
        }
      }

      // Close loading dialog
      Navigator.pop(context);

      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(
                'Added ${selectedAttractions.length} attraction(s) to your trip')),
      );

      // Return to previous screen with success result
      Navigator.pop(context, {'updated': true});
    } catch (e) {
      // Close loading dialog
      Navigator.pop(context);

      // Show error message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error adding attractions: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Attractions in ${widget.destinationName}'),
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _attractions.isEmpty
              ? const Center(
                  child: Text('No attractions found for this destination'),
                )
              : ListView.builder(
                  itemCount: _attractions.length,
                  itemBuilder: (context, index) {
                    final attraction = _attractions[index];
                    final isSelected =
                        _selectedAttractionIds.contains(attraction['id']);

                    return Card(
                      margin: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                      elevation: 2,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: BorderSide(
                          color:
                              isSelected ? Colors.purple : Colors.transparent,
                          width: 2,
                        ),
                      ),
                      child: InkWell(
                        onTap: () =>
                            _toggleAttractionSelection(attraction['id']),
                        child: Padding(
                          padding: const EdgeInsets.all(12.0),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Attraction image
                              ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: attraction['imageUrl'] != null &&
                                        attraction['imageUrl']
                                            .toString()
                                            .isNotEmpty
                                    ? Image.network(
                                        attraction['imageUrl'],
                                        width: 80,
                                        height: 80,
                                        fit: BoxFit.cover,
                                        errorBuilder:
                                            (context, error, stackTrace) {
                                          return Container(
                                            width: 80,
                                            height: 80,
                                            color: Colors.grey[300],
                                            child: const Icon(
                                                Icons.image_not_supported),
                                          );
                                        },
                                      )
                                    : Container(
                                        width: 80,
                                        height: 80,
                                        color: Colors.grey[300],
                                        child: const Icon(Icons.image),
                                      ),
                              ),
                              const SizedBox(width: 12),
                              // Attraction details
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      attraction['name'] ??
                                          'Unknown Attraction',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      attraction['description'] ??
                                          'No description available',
                                      maxLines: 3,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        color: Colors.grey[700],
                                        fontSize: 14,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              // Selection checkbox
                              Checkbox(
                                value: isSelected,
                                onChanged: (_) => _toggleAttractionSelection(
                                    attraction['id']),
                                activeColor: Colors.purple,
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(16.0),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 4,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: SafeArea(
          child: ElevatedButton(
            onPressed: _selectedAttractionIds.isEmpty ? null : _addToTripPlan,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.black,
              foregroundColor: Colors.white,
              disabledBackgroundColor: Colors.grey,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: Text(
              'ADD ${_selectedAttractionIds.length} ATTRACTIONS TO TRIP',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
