import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:humsafar_app/models/trip_plan.dart';
import 'package:humsafar_app/models/destination.dart';
import 'package:humsafar_app/util/ai_planner.dart';
import 'package:humsafar_app/screens/trip/trip_plan_repository.dart';
import 'package:humsafar_app/screens/trip/view_trip_details.dart';

class AITripPlannerScreen extends StatefulWidget {
  const AITripPlannerScreen({super.key});

  @override
  _AITripPlannerScreenState createState() => _AITripPlannerScreenState();
}

class _AITripPlannerScreenState extends State<AITripPlannerScreen> {
  final TextEditingController _descriptionController = TextEditingController();
  int _days = 3;
  int _people = 2;
  DateTime _startDate = DateTime.now().add(Duration(days: 3));
  bool _isLoading = false;
  bool _isGeneratingPlan = false;
  Map<String, dynamic>? _generatedAIResponse;
  TripPlan? _generatedTripPlan;

  // Services and repositories
  final AIPlanner _aiService =
      AIPlanner(apiToken: 'AIzaSyBzSFu9EG6EUE6XuZHOo4CUV_AojBiLyzo');
  final TripPlanRepository _tripPlanRepository = TripPlanRepository();
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Categories for filtering destinations (optional)
  List<String> _categories = [];
  String? _selectedCategory;

  // Destinations from Firestore
  List<Destination> _destinations = [];
  bool _isLoadingDestinations = true;

  @override
  void initState() {
    super.initState();
    _loadDestinations();
  }

  // Load destinations from Firestore
  Future<void> _loadDestinations() async {
    try {
      setState(() {
        _isLoadingDestinations = true;
      });

      final destinations = await _tripPlanRepository.getAllDestinations();

      // Extract unique categories for filtering
      final categories = destinations
          .where((d) => d.category != null && d.category!.isNotEmpty)
          .map((d) => d.category!)
          .toSet()
          .toList();

      setState(() {
        _destinations = destinations;
        _categories = categories;
        _isLoadingDestinations = false;
      });
    } catch (e) {
      setState(() {
        _isLoadingDestinations = false;
      });
      _showErrorSnackBar('Failed to load destinations: $e');
    }
  }

  Future<void> _generatePlan() async {
    if (_descriptionController.text.trim().isEmpty) {
      _showErrorSnackBar('Please enter a description of your trip');
      return;
    }

    if (_destinations.isEmpty) {
      _showErrorSnackBar('No destinations available. Please try again later.');
      return;
    }

    setState(() {
      _isLoading = true;
      _isGeneratingPlan = true;
      _generatedAIResponse = null;
      _generatedTripPlan = null;
    });

    try {
      // Filter destinations if category is selected
      List<Destination> filteredDestinations = _destinations;
      if (_selectedCategory != null) {
        filteredDestinations = _destinations
            .where((d) => d.category == _selectedCategory)
            .toList();

        // If no destinations in the selected category, use all destinations
        if (filteredDestinations.isEmpty) {
          filteredDestinations = _destinations;
        }
      }

      // Generate the AI plan
      final aiResponse = await _aiService.generateTripPlan(
        description: _descriptionController.text,
        days: _days,
        people: _people,
        destinations: filteredDestinations,
        startDate: _startDate,
      );

      // Convert AI response to TripPlan object
      final user = _auth.currentUser;
      if (user == null) {
        throw Exception('User not logged in');
      }

      final tripPlan = await _aiService.aiResponseToTripPlan(
        aiResponse: aiResponse,
        userEmail: user.email ?? 'unknown@email.com',
        userID: user.uid, // Changed from userId to userID
        numberOfTravelers: _people,
        startDate: _startDate,
        allDestinations: _destinations,
      );

      setState(() {
        _generatedAIResponse = aiResponse;
        _generatedTripPlan = tripPlan;
        _isGeneratingPlan = false;
      });
    } catch (e) {
      setState(() {
        _isGeneratingPlan = false;
      });
      _showErrorSnackBar('Error: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _saveTripPlan() async {
    if (_generatedTripPlan == null) {
      _showErrorSnackBar('No trip plan to save');
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final tripPlanId =
          await _tripPlanRepository.saveTripPlan(_generatedTripPlan!);

      setState(() {
        _isLoading = false;
      });

      _showSuccessSnackBar('Trip plan saved successfully!');

      // Navigate to trip detail screen
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => TripPlanDetailsScreen(
            tripPlanId: tripPlanId,
            tripName: _generatedTripPlan!.name,
          ),
        ),
      );
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      _showErrorSnackBar('Failed to save trip plan: $e');
    }
  }

  void _showDatePicker() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _startDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(Duration(days: 365)),
    );

    if (picked != null && picked != _startDate) {
      setState(() {
        _startDate = picked;
      });
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('AI Trip Planner'),
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
      ),
      body: _isLoadingDestinations
          ? Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Plan Your Pakistan Adventure',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: 16),
                  Card(
                    elevation: 4,
                    color: Color.fromARGB(255, 219, 218, 218),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Trip Details',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(height: 16),
                          TextField(
                            controller: _descriptionController,
                            decoration: InputDecoration(
                              labelText:
                                  'Describe your ideal Pakistan vacation',
                              hintText:
                                  'E.g., "A cultural expedition with mountain views and local cuisine"',
                              border: OutlineInputBorder(),
                            ),
                            maxLines: 3,
                          ),
                          SizedBox(height: 16),

                          // Category dropdown (optional)
                          if (_categories.isNotEmpty)
                            DropdownButtonFormField<String>(
                              decoration: InputDecoration(
                                labelText: 'Destination Category (Optional)',
                                border: OutlineInputBorder(),
                              ),
                              value: _selectedCategory,
                              hint: Text('All Categories'),
                              items: [
                                DropdownMenuItem<String>(
                                  value: null,
                                  child: Text('All Categories'),
                                ),
                                ..._categories
                                    .map((category) => DropdownMenuItem<String>(
                                          value: category,
                                          child: Text(category),
                                        )),
                              ],
                              onChanged: (value) {
                                setState(() {
                                  _selectedCategory = value;
                                });
                              },
                            ),
                          if (_categories.isNotEmpty) SizedBox(height: 16),

                          Row(
                            children: [
                              Expanded(
                                child: Text('Number of travelers: $_people'),
                              ),
                              IconButton(
                                icon: Icon(Icons.remove),
                                onPressed: _people > 1
                                    ? () {
                                        setState(() {
                                          _people--;
                                        });
                                      }
                                    : null,
                              ),
                              IconButton(
                                icon: Icon(Icons.add),
                                onPressed: () {
                                  setState(() {
                                    _people++;
                                  });
                                },
                              ),
                            ],
                          ),
                          SizedBox(height: 8),
                          Row(
                            children: [
                              Expanded(
                                child: Text('Number of days: $_days'),
                              ),
                              IconButton(
                                icon: Icon(Icons.remove),
                                onPressed: _days > 1
                                    ? () {
                                        setState(() {
                                          _days--;
                                        });
                                      }
                                    : null,
                              ),
                              IconButton(
                                icon: Icon(Icons.add),
                                onPressed: () {
                                  setState(() {
                                    _days++;
                                  });
                                },
                              ),
                            ],
                          ),
                          SizedBox(height: 16),
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  'Start Date: ${DateFormat('MMM dd, yyyy').format(_startDate)}',
                                ),
                              ),
                              TextButton(
                                onPressed: _showDatePicker,
                                child: Text('Change Date'),
                              ),
                            ],
                          ),
                          SizedBox(height: 16),
                          Center(
                            child: ElevatedButton.icon(
                              onPressed: _isLoading ? null : _generatePlan,
                              icon: Icon(Icons.auto_awesome),
                              label: Text('Generate AI Trip Plan'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.black,
                                foregroundColor: Colors.white,
                                padding: EdgeInsets.symmetric(
                                  horizontal: 24,
                                  vertical: 12,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  SizedBox(height: 24),
                  if (_isGeneratingPlan)
                    Center(
                      child: Column(
                        children: [
                          CircularProgressIndicator(),
                          SizedBox(height: 16),
                          Text(
                            'Generating your personalized Pakistan trip plan...',
                            style: TextStyle(fontStyle: FontStyle.italic),
                          ),
                        ],
                      ),
                    ),
                  if (_generatedAIResponse != null && !_isGeneratingPlan)
                    _buildGeneratedPlanCard(),
                ],
              ),
            ),
    );
  }

  Widget _buildGeneratedPlanCard() {
    final planName =
        _generatedAIResponse!['plan_name'] ?? 'Your Pakistan Adventure';
    final planDescription = _generatedAIResponse!['plan_description'] ??
        'A customized trip through Pakistan\'s most beautiful destinations.';
    final destinations =
        _generatedAIResponse!['destinations'] as List<dynamic>? ?? [];

    return Card(
      elevation: 6,
      margin: EdgeInsets.only(bottom: 20),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      color: Color.fromARGB(255, 212, 208, 208),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Flexible(
                  child: Text(
                    planName,
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                ),
                Row(
                  children: [
                    IconButton(
                      icon: Icon(Icons.refresh),
                      tooltip: 'Generate a new plan',
                      onPressed: !_isLoading ? _generatePlan : null,
                    ),
                    IconButton(
                      icon: Icon(Icons.save),
                      tooltip: 'Save this plan',
                      onPressed: !_isLoading ? _saveTripPlan : null,
                    ),
                  ],
                ),
              ],
            ),
            Divider(),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: Text(
                planDescription,
                style: TextStyle(
                  fontSize: 16,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
            SizedBox(height: 16),
            Text(
              'Destinations:',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 8),
            ListView.builder(
              shrinkWrap: true,
              physics: NeverScrollableScrollPhysics(),
              itemCount: destinations.length,
              itemBuilder: (context, index) {
                final destination = destinations[index];
                return _buildDestinationCard(
                    name: destination['name'] ?? 'Unknown destination',
                    days: destination['days'] ?? 1,
                    activities: destination['activities'] ??
                        'Explore the local attractions',
                    reasoning: destination['reasoning'] ??
                        'This fits your preferences');
              },
            ),
            SizedBox(height: 16),
            if (_isLoading)
              Center(child: CircularProgressIndicator())
            else
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _generatePlan,
                      icon: Icon(Icons.refresh),
                      label: Text('New Plan'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.grey.shade700,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ),
                  SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _saveTripPlan,
                      icon: Icon(Icons.check),
                      label: Text('Save Plan'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.black,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildDestinationCard({
    required String name,
    required int days,
    required String activities,
    required String reasoning,
  }) {
    // Find the matching destination to get image URL
    final matchingDest = _destinations.firstWhere(
      (d) => d.name == name,
      orElse: () => _destinations.first,
    );

    return Card(
      margin: EdgeInsets.symmetric(vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.network(
                    matchingDest.imageUrl,
                    width: 80,
                    height: 80,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        width: 80,
                        height: 80,
                        color: Colors.grey.shade300,
                        child: Icon(Icons.image, color: Colors.grey.shade600),
                      );
                    },
                  ),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(Icons.calendar_today, size: 16),
                          SizedBox(width: 4),
                          Text(
                            '$days ${days == 1 ? 'day' : 'days'}',
                            style: TextStyle(
                              color: Colors.grey.shade700,
                            ),
                          ),
                          SizedBox(width: 12),
                          Icon(Icons.star, size: 16, color: Colors.amber),
                          SizedBox(width: 4),
                          Text(
                            '${matchingDest.rating}',
                            style: TextStyle(
                              color: Colors.grey.shade700,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            SizedBox(height: 12),
            Text(
              'Why this destination:',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
            Text(reasoning),
            SizedBox(height: 8),
            Text(
              'Suggested activities:',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
            Text(activities),
          ],
        ),
      ),
    );
  }
}
