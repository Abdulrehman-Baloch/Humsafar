import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class TripCalendarTimeline extends StatelessWidget {
  final DateTime tripStartDate;
  final DateTime tripEndDate;
  final List<Map<String, dynamic>> destinations;

  const TripCalendarTimeline({
    super.key,
    required this.tripStartDate,
    required this.tripEndDate,
    required this.destinations,
  });

  @override
  Widget build(BuildContext context) {
    // Calculate total days in trip
    final int tripDays = tripEndDate.difference(tripStartDate).inDays + 1;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Trip Timeline:',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Container(
          height: 70,
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey.shade300),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: List.generate(tripDays, (index) {
              final day = tripStartDate.add(Duration(days: index));
              final dayNumber = day.day;
              final monthName = DateFormat('MMM').format(day);

              // Check if this day is already covered by an existing destination
              bool isDayBooked = false;
              String? destinationName;

              for (final dest in destinations) {
                final destStartDate = (dest['startDate'] as Timestamp).toDate();
                final destEndDate = (dest['endDate'] as Timestamp).toDate();

                if ((day.isAfter(destStartDate) ||
                        day.isAtSameMomentAs(destStartDate)) &&
                    (day.isBefore(destEndDate) ||
                        day.isAtSameMomentAs(destEndDate))) {
                  isDayBooked = true;
                  destinationName = dest['destinationName'] as String;
                  break;
                }
              }

              return Expanded(
                child: Tooltip(
                  message: isDayBooked
                      ? '$monthName $dayNumber: Booked ($destinationName)'
                      : '$monthName $dayNumber: Available',
                  child: Container(
                    decoration: BoxDecoration(
                      color: isDayBooked
                          ? Colors.grey.shade300
                          : const Color.fromARGB(255, 146, 129, 151),
                      border: index < tripDays - 1
                          ? Border(
                              right: BorderSide(color: Colors.grey.shade200))
                          : null,
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          dayNumber.toString(),
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: isDayBooked ? Colors.black54 : Colors.black,
                          ),
                        ),
                        Text(
                          monthName,
                          style: TextStyle(
                            fontSize: 10,
                            color: isDayBooked ? Colors.black54 : Colors.black,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }),
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Container(
              width: 16,
              height: 16,
              color: const Color.fromARGB(255, 146, 129, 151),
            ),
            const SizedBox(width: 4),
            const Text('Available'),
            const SizedBox(width: 16),
            Container(
              width: 16,
              height: 16,
              color: Colors.grey.shade300,
            ),
            const SizedBox(width: 4),
            const Text('Booked'),
          ],
        ),
      ],
    );
  }
}
