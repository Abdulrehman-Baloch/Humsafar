import 'package:flutter/material.dart';

class AIPlannerScreen extends StatelessWidget {
  final TextEditingController _controller = TextEditingController();

  AIPlannerScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('AI Trip Planner'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: _controller,
              maxLines: 5,
              decoration: InputDecoration(
                border: OutlineInputBorder(
                  borderSide: BorderSide(
                      color: const Color.fromARGB(255, 41, 132, 207)),
                  borderRadius: BorderRadius.all(Radius.circular(10)),
                ),
                hintText: 'Enter your vacation description here...',
              ),
            ),
            SizedBox(height: 20),
            Center(
              child: ElevatedButton(
                onPressed: () {
                  // Add your submission logic here
                },
                child: Text('Submit'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
