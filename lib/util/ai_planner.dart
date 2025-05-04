// updated_ai_planner.dart
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:humsafar_app/models/destination.dart';
import 'package:humsafar_app/models/trip_plan.dart';

class AIPlanner {
  final String apiToken;
  final String modelEndpoint =
      'https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-flash:generateContent';

  AIPlanner({required this.apiToken});

  Future<Map<String, dynamic>> generateTripPlan({
    required String description,
    required int days,
    required int people,
    required List<Destination> destinations,
    DateTime? startDate,
  }) async {
    // Format destinations for the prompt with more detailed information
    final destinationsText = destinations
        .map((d) =>
            "${d.name} (Rating: ${d.rating}/5): ${d.description} | "
                "Best time to visit: ${d.ttv ?? 'Year-round'} | " "Weather: ${d.weather ?? 'Varies seasonally'} | " "Region: ${d.region ?? 'Not specified'} | " "Category: ${d.category ?? 'Not specified'}")
        .join("\n");

    // Create the prompt with focus on Pakistan tourism
    final promptText =
        """Create a $days-day travel itinerary in Pakistan for $people people based on: "$description"

    IMPORTANT: Select destinations ONLY from this approved list:
    $destinationsText

    For each day, recommend 1-2 destinations from the list above. Each destination recommendation must include:
    1. Name of the destination (exactly as listed)
    2. Why it fits the user's preferences
    3. Suggested activities at this location
    4. Recommended number of days to spend there

    Format the output in this exact structure:
    {
      "plan_name": "A catchy name for this trip plan",
      "plan_description": "A brief 2-3 sentence overview of the entire trip",
      "destinations": [
        {
          "name": "Exact destination name",
          "days": number of days to spend,
          "activities": "Description of activities",
          "reasoning": "Why this fits the user's preferences",
          "notes": "Any special tips or recommendations for this destination"
        },
        ... additional destinations ...
      ]
    }

    The total number of days across all destinations should equal $days.
    All destination names must match exactly with names in the provided list.
    Make the plan logical in terms of geographic proximity when possible.
    Consider the best time to visit each location when making recommendations.
    
    IMPORTANT: Return ONLY the JSON output, no additional text before or after.""";

    try {
      // Format the request body according to Gemini API requirements
      final requestBody = {
        "contents": [
          {
            "parts": [
              {"text": promptText}
            ]
          }
        ],
        "generationConfig": {
          "temperature": 0.7,
          "maxOutputTokens": 1000,
          "topP": 0.95,
          "topK": 40
        }
      };

      final response = await http.post(
        Uri.parse('$modelEndpoint?key=$apiToken'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode(requestBody),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        // Extract text from Gemini response
        if (data.containsKey('candidates') &&
            data['candidates'] is List &&
            data['candidates'].isNotEmpty &&
            data['candidates'][0].containsKey('content') &&
            data['candidates'][0]['content'].containsKey('parts') &&
            data['candidates'][0]['content']['parts'] is List &&
            data['candidates'][0]['content']['parts'].isNotEmpty) {
          String generatedText =
              data['candidates'][0]['content']['parts'][0]['text'] ?? '';

          // Extract the JSON part from the response
          RegExp jsonRegex = RegExp(r'{[\s\S]*}');
          var match = jsonRegex.firstMatch(generatedText);

          if (match != null) {
            try {
              Map<String, dynamic> parsedPlan = jsonDecode(match.group(0)!);

              // Validate the plan structure
              if (!parsedPlan.containsKey('plan_name') ||
                  !parsedPlan.containsKey('plan_description') ||
                  !parsedPlan.containsKey('destinations')) {
                throw Exception('Generated plan is missing required fields');
              }

              // Verify destinations exist in our database
              List<dynamic> planDestinations = parsedPlan['destinations'];
              for (var dest in planDestinations) {
                String destName = dest['name'];
                if (!destinations.any((d) => d.name == destName)) {
                  dest['name'] =
                      _findClosestDestination(destName, destinations);
                }
              }

              return parsedPlan;
            } catch (e) {
              // If JSON parsing fails, return a manually structured response
              return _createManualPlanFromText(
                  generatedText, days, people, destinations, startDate);
            }
          } else {
            return _createManualPlanFromText(
                generatedText, days, people, destinations, startDate);
          }
        } else {
          throw Exception('Unexpected Gemini API response format');
        }
      } else if (response.statusCode == 429) {
        // Rate limit exceeded
        await Future.delayed(Duration(seconds: 10));
        return generateTripPlan(
            description: description,
            days: days,
            people: people,
            destinations: destinations,
            startDate: startDate);
      } else {
        throw Exception('API Error: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      // For any errors, fall back to manual plan creation
      return _createManualPlanFromLocalData(
          description, days, people, destinations, startDate);
    }
  }

  // Find the most similar destination name in our database
  String _findClosestDestination(String name, List<Destination> destinations) {
    // Simple string similarity - can be improved
    String closest = destinations.first.name;
    int maxCommonChars = 0;

    for (var dest in destinations) {
      int common = 0;
      for (int i = 0; i < name.length && i < dest.name.length; i++) {
        if (name[i].toLowerCase() == dest.name[i].toLowerCase()) common++;
      }
      if (common > maxCommonChars) {
        maxCommonChars = common;
        closest = dest.name;
      }
    }

    return closest;
  }

  // Create a structured plan when JSON parsing fails
  Map<String, dynamic> _createManualPlanFromText(String text, int days,
      int people, List<Destination> destinations, DateTime? startDate) {
    // Extract potential destination names from the text
    List<String> potentialDestinations = [];
    for (var dest in destinations) {
      if (text.contains(dest.name)) {
        potentialDestinations.add(dest.name);
      }
    }

    // If we couldn't find any, use the fallback method
    if (potentialDestinations.isEmpty) {
      return _createManualPlanFromLocalData(
          text, days, people, destinations, startDate);
    }

    // Calculate days per destination
    int destinationsCount = potentialDestinations.length;
    int daysPerDest = days ~/ destinationsCount;
    int extraDays = days % destinationsCount;

    List<Map<String, dynamic>> planDestinations = [];
    for (int i = 0; i < potentialDestinations.length; i++) {
      int daysAtDest = daysPerDest + (i < extraDays ? 1 : 0);
      planDestinations.add({
        "name": potentialDestinations[i],
        "days": daysAtDest,
        "activities":
            "Explore the local attractions and experience the culture.",
        "reasoning":
            "This destination matches your preferences for a Pakistan trip.",
        "notes": "Selected based on your preferences."
      });
    }

    return {
      "plan_name": "Pakistan Adventure Tour",
      "plan_description":
          "A $days-day journey through Pakistan's most beautiful destinations, perfect for $people travelers looking for an authentic experience.",
      "destinations": planDestinations
    };
  }

  // Create a plan from local data when API fails completely
  Map<String, dynamic> _createManualPlanFromLocalData(
      String description,
      int days,
      int people,
      List<Destination> destinations,
      DateTime? startDate) {
    // Try to find destinations that match the user's description
    List<Destination> matchingDestinations = [];

    // Look for matching keywords in the description
    final keywords = [
      'cold',
      'hot',
      'mountain',
      'beach',
      'history',
      'culture',
      'food',
      'adventure',
      'relax',
      'hiking',
      'swimming',
      'city',
      'rural',
      'nature',
      'wildlife',
      'heritage',
      'traditional'
    ];

    final textLower = description.toLowerCase();

    // Find what keywords are present in the text
    final presentKeywords =
        keywords.where((k) => textLower.contains(k)).toList();

    if (presentKeywords.isNotEmpty) {
      // Find destinations that match these keywords
      for (var dest in destinations) {
        final destText = (dest.description ?? '').toLowerCase() +
            (dest.category ?? '').toLowerCase() +
            (dest.region ?? '').toLowerCase() +
            dest.name.toLowerCase();

        for (var keyword in presentKeywords) {
          if (destText.contains(keyword)) {
            matchingDestinations.add(dest);
            break;
          }
        }
      }
    }

    // If no matching destinations, take some based on high ratings
    if (matchingDestinations.isEmpty) {
      matchingDestinations = destinations
          .where((d) => d.rating >= 4.0)
          .toList();
    }

    // If still empty, just take the first few destinations
    if (matchingDestinations.isEmpty) {
      matchingDestinations = destinations.take(3).toList();
    }

    // Limit to number of days (1 destination per 2 days, minimum 1 destination)
    int destsToInclude = (days / 2).ceil();
    destsToInclude = destsToInclude.clamp(1, matchingDestinations.length);

    matchingDestinations = matchingDestinations.take(destsToInclude).toList();

    // Calculate days per destination
    int destinationsCount = matchingDestinations.length;
    int daysPerDest = days ~/ destinationsCount;
    int extraDays = days % destinationsCount;

    List<Map<String, dynamic>> planDestinations = [];
    for (int i = 0; i < matchingDestinations.length; i++) {
      int daysAtDest = daysPerDest + (i < extraDays ? 1 : 0);

      // Create reasonable activity descriptions based on destination category
      String activities =
          "Explore the local attractions and experience the culture.";
      String reasoning = "This matches your preferences for a Pakistan trip.";

      final dest = matchingDestinations[i];
      if (dest.category != null) {
        if (dest.category!.toLowerCase().contains('mountain')) {
          activities =
              "Hiking, enjoying scenic views, and experiencing the mountain culture.";
        } else if (dest.category!.toLowerCase().contains('historic')) {
          activities =
              "Visit historical sites, learn about local history, and explore cultural landmarks.";
        } else if (dest.category!.toLowerCase().contains('beach')) {
          activities =
              "Enjoy the beach, water activities, and relaxing by the shore.";
        } else if (dest.category!.toLowerCase().contains('nature')) {
          activities = "Wildlife spotting, nature walks, and photography.";
        }
      }

      if (textLower.contains('cold') &&
          dest.weather != null &&
          dest.weather!.toLowerCase().contains('cold')) {
        reasoning =
            "This destination offers the cold climate you're looking for with rich cultural experiences.";
      } else if (textLower.contains('culture') &&
          dest.description.toLowerCase().contains('culture')) {
        reasoning =
            "This destination is known for its rich cultural heritage and traditional experiences.";
      }

      planDestinations.add({
        "name": matchingDestinations[i].name,
        "days": daysAtDest,
        "activities": activities,
        "reasoning": reasoning,
        "notes":
            "Best time to visit: ${matchingDestinations[i].ttv ?? 'Year-round'}"
      });
    }

    // Create a custom plan name based on destinations or user description
    String planName = "Pakistan Adventure";
    if (textLower.contains('culture')) {
      planName = "Cultural Heritage Tour of Pakistan";
    } else if (textLower.contains('mountain')) {
      planName = "Pakistan Mountain Expedition";
    } else if (textLower.contains('history')) {
      planName = "Historical Pakistan Journey";
    } else if (textLower.contains('food')) {
      planName = "Pakistani Culinary Adventure";
    }

    return {
      "plan_name": planName,
      "plan_description":
          "A $days-day journey through Pakistan's most beautiful destinations, perfect for $people travelers looking for an authentic experience based on your preferences.",
      "destinations": planDestinations
    };
  }

  // New method to convert AI response to TripPlan object
  Future<TripPlan> aiResponseToTripPlan({
    required Map<String, dynamic> aiResponse,
    required String userEmail,
    required String userID,
    required int numberOfTravelers,
    required DateTime startDate,
    required List<Destination> allDestinations,
  }) async {
    // Calculate end date based on total days
    int totalDays = 0;
    List<TripDestination> tripDestinations = [];

    if (aiResponse.containsKey('destinations') &&
        aiResponse['destinations'] is List) {
      List<dynamic> destinations = aiResponse['destinations'];

      DateTime currentDate = startDate;
      for (var dest in destinations) {
        int daysOfStay = dest['days'] ?? 1;
        totalDays += daysOfStay;

        // Find the destination in our database
        String destName = dest['name'];
        Destination? matchingDest = allDestinations.firstWhere(
          (d) => d.name == destName,
          orElse: () => allDestinations.first,
        );

        // Calculate end date for this destination
        DateTime destEndDate = currentDate.add(Duration(days: daysOfStay));

        // Create the TripDestination object with notes from AI if available
        tripDestinations.add(TripDestination(
          destinationId: matchingDest.id,
          destinationName: matchingDest.name,
          daysOfStay: daysOfStay,
          startDate: currentDate,
          endDate: destEndDate,
          addedAt: DateTime.now(),
          notes:
              dest['notes'] ?? '${dest['activities']}\n\n${dest['reasoning']}',
        ));

        // Update the current date for the next destination
        currentDate = destEndDate;
      }
    }

    // If no destinations or total days is 0, set default
    if (totalDays == 0) {
      totalDays = 1;
    }

    // Create the TripPlan object
    return TripPlan(
      name: aiResponse['plan_name'] ?? 'Pakistan Trip Plan',
      userEmail: userEmail,
      userID: userID,
      numberOfTravelers: numberOfTravelers,
      totalDays: totalDays,
      startDate: startDate,
      endDate: startDate.add(Duration(days: totalDays)),
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      isCompleted: false,
      destinations: tripDestinations,
    );
  }
}
