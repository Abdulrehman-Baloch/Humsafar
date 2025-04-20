// trip_attractions_display.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'local_attractions_selector.dart';

class TripAttractionsDisplay extends StatefulWidget {
  final String tripPlanId;
  final String destinationId;
  final String destinationName;

  const TripAttractionsDisplay({
    super.key,
    required this.tripPlanId,
    required this.destinationId,
    required this.destinationName,
  });

  @override
  State<TripAttractionsDisplay> createState() => _TripAttractionsDisplayState();
}

class _TripAttractionsDisplayState extends State<TripAttractionsDisplay> {
  bool _isLoading = true;
  List<Map<String, dynamic>> _attractions = [];

  @override
  void initState() {
    super.initState();
    _loadSavedAttractions();
  }

  Future<void> _loadSavedAttractions() async {
    try {
      final attractionsSnapshot = await FirebaseFirestore.instance
          .collection('tripPlans')
          .doc(widget.tripPlanId)
          .collection('tripDestinations')
          .doc(widget.destinationId)
          .collection('localAttractions')
          .get();

      final attractions = attractionsSnapshot.docs.map((doc) {
        return {
          'id': doc.data()['attractionId'],
          'docId': doc.id,
          ...doc.data(),
        };
      }).toList();

      setState(() {
        _attractions = attractions;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      print('Error loading saved attractions: $e');
    }
  }

  Future<void> _navigateToAttractionsSelector() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => LocalAttractionsSelector(
          tripPlanId: widget.tripPlanId,
          destinationId: widget.destinationId,
          destinationName: widget.destinationName,
        ),
      ),
    );

    // If attractions were updated, reload them
    if (result != null && result['updated'] == true) {
      _loadSavedAttractions();
    }
  }

  Future<void> _removeAttraction(String docId) async {
    try {
      await FirebaseFirestore.instance
          .collection('tripPlans')
          .doc(widget.tripPlanId)
          .collection('tripDestinations')
          .doc(widget.destinationId)
          .collection('localAttractions')
          .doc(docId)
          .delete();

      setState(() {
        _attractions.removeWhere((attraction) => attraction['docId'] == docId);
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Attraction removed from trip')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error removing attraction: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const SizedBox(
        height: 100,
        child: Center(child: CircularProgressIndicator()),
      );
    }

    if (_attractions.isEmpty) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Activities',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
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
          const SizedBox(height: 8),
          Center(
            // Add a Center widget to center the button
            child: ElevatedButton.icon(
              icon: const Icon(Icons.add, size: 16),
              label: const Text('Add Activities'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.black,
                foregroundColor: Colors.white,
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                minimumSize: const Size(0, 32),
              ),
              onPressed: _navigateToAttractionsSelector,
            ),
          ),
        ],
      );
    }

    return Column(
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
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                minimumSize: const Size(0, 32),
              ),
              onPressed: _navigateToAttractionsSelector,
            ),
          ],
        ),
        const SizedBox(height: 8),
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: _attractions.length,
          itemBuilder: (context, index) {
            final attraction = _attractions[index];
            return _buildAttractionCard(attraction);
          },
        ),
      ],
    );
  }

  Widget _buildAttractionCard(Map<String, dynamic> attraction) {
    return Card(
      margin: const EdgeInsets.only(top: 8, bottom: 8),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Attraction image
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: attraction['imageUrl'] != null &&
                      attraction['imageUrl'].toString().isNotEmpty
                  ? Image.network(
                      attraction['imageUrl'],
                      width: 60,
                      height: 60,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          width: 60,
                          height: 60,
                          color: Colors.grey[300],
                          child: const Icon(Icons.image_not_supported),
                        );
                      },
                    )
                  : Container(
                      width: 60,
                      height: 60,
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
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          attraction['name'] ?? 'Unknown Attraction',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.remove_circle_outline,
                            color: Colors.red, size: 20),
                        onPressed: () => _removeAttraction(attraction['docId']),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    attraction['description'] ?? 'No description available',
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
          ],
        ),
      ),
    );
  }
}
