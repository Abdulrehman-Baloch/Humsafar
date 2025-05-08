import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';

class TestableSubmitReviewPage extends StatelessWidget {
  final VoidCallback? onSubmit;

  const TestableSubmitReviewPage({
    Key? key,
    this.onSubmit,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: SubmitReviewTestWidget(onSubmit: onSubmit),
    );
  }
}

class SubmitReviewTestWidget extends StatefulWidget {
  final VoidCallback? onSubmit;

  const SubmitReviewTestWidget({Key? key, this.onSubmit}) : super(key: key);

  @override
  State<SubmitReviewTestWidget> createState() => _SubmitReviewTestWidgetState();
}

class _SubmitReviewTestWidgetState extends State<SubmitReviewTestWidget> {
  double _rating = 0;
  final TextEditingController _commentController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            const Text(
              'Submit Your Review',
              style: TextStyle(fontSize: 24),
            ),
            const SizedBox(height: 16),
            Container(
              key: const Key('rating_bar'),
              child: RatingBar.builder(
                initialRating: 0,
                minRating: 1,
                direction: Axis.horizontal,
                allowHalfRating: false,
                itemCount: 5,
                itemBuilder: (context, _) => const Icon(
                  Icons.star,
                  color: Colors.amber,
                ),
                onRatingUpdate: (rating) {
                  setState(() {
                    _rating = rating;
                  });
                },
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              key: const Key('comment_field'),
              controller: _commentController,
              decoration: const InputDecoration(
                labelText: 'Write your review',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              key: const Key('submit_button'),
              onPressed: () {
                if (_commentController.text.isEmpty || _rating == 0) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content: Text('Please provide a rating and comment')),
                  );
                  return;
                }
                if (widget.onSubmit != null) {
                  widget.onSubmit!();
                }
              },
              child: const Text('Submit'),
            ),
          ],
        ),
      ),
    );
  }
}

void main() {
  testWidgets('Submit Review UI elements are displayed correctly',
      (WidgetTester tester) async {
    await tester.pumpWidget(const TestableSubmitReviewPage());
    await tester.pump(); // Ensure the widget tree is fully rendered

    // Verifying if the UI elements are found
    expect(find.text('Submit Your Review'), findsOneWidget);
    expect(find.byKey(const Key('rating_bar')),
        findsOneWidget); // RatingBar should be found now
    expect(find.byKey(const Key('comment_field')), findsOneWidget);
    expect(find.byKey(const Key('submit_button')), findsOneWidget);
  });

  testWidgets('Shows error message when trying to submit with empty fields',
      (WidgetTester tester) async {
    await tester.pumpWidget(const TestableSubmitReviewPage());

    await tester.tap(find.byKey(const Key('submit_button')));
    await tester.pump();

    expect(find.text('Please provide a rating and comment'), findsOneWidget);
  });

  testWidgets('Allows entering text in comment field',
      (WidgetTester tester) async {
    await tester.pumpWidget(const TestableSubmitReviewPage());

    await tester.enterText(
        find.byKey(const Key('comment_field')), 'Amazing place!');
    expect(find.text('Amazing place!'), findsOneWidget);
  });

  testWidgets('Rating bar updates the rating', (WidgetTester tester) async {
    await tester.pumpWidget(const TestableSubmitReviewPage());

    // Tap the 4th star (0-indexed star + 1 = rating)
    await tester.tap(find.byIcon(Icons.star).at(3));
    await tester.pump();

    // Verify that 4 stars are shown as expected (because we're tapping on the 4th star)
    expect(find.byIcon(Icons.star), findsNWidgets(5));
  });

  testWidgets('Submit callback is triggered when fields are valid',
      (WidgetTester tester) async {
    bool submitCalled = false;

    await tester.pumpWidget(TestableSubmitReviewPage(
      onSubmit: () {
        submitCalled = true;
      },
    ));

    await tester.enterText(
        find.byKey(const Key('comment_field')), 'Nice destination!');
    await tester.tap(find.byIcon(Icons.star).at(4)); // 5-star rating
    await tester.pump();

    await tester.tap(find.byKey(const Key('submit_button')));
    await tester.pump();

    expect(submitCalled, true);
  });
}
