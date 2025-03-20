import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:firebase_storage/firebase_storage.dart';

class SubmitReviewPage extends StatefulWidget {
  final String destinationID;

  const SubmitReviewPage({
    super.key,
    required this.destinationID,
  });

  @override
  State<SubmitReviewPage> createState() => _SubmitReviewPageState();
}

class _SubmitReviewPageState extends State<SubmitReviewPage> {
  double _rating = 0;
  final TextEditingController _commentController = TextEditingController();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  List<PlatformFile> _images = [];

  Future<void> _pickImages() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.image,
      allowMultiple: true,
    );

    if (result != null) {
      setState(() {
        _images = result.files;
      });
    }
  }

  Future<String> uploadImageToFirebase(PlatformFile image) async {
    try {
      // Create a reference to the Firebase Storage location
      final storageRef = FirebaseStorage.instance
          .ref()
          .child('reviews/${DateTime.now().millisecondsSinceEpoch}.jpg');

      // Upload the file to Firebase Storage
      if (image.bytes != null) {
        await storageRef.putData(image.bytes!);
      } else {
        throw Exception('File bytes are null');
      }

      // Get the download URL
      String downloadURL = await storageRef.getDownloadURL();
      return downloadURL;
    } catch (e) {
      print('Error uploading image: $e');
      throw e;
    }
  }

  Future<void> _submitReview() async {
    final User? user = _auth.currentUser;

    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('You must be logged in to submit a review.'),
        ),
      );
      return;
    }

    // Check if the user has provided a rating
    if (_rating == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please provide a rating.'),
        ),
      );
      return;
    }

    // Check if the user has provided a review comment
    if (_commentController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please write a review.'),
        ),
      );
      return;
    }

    // Upload images and get their URLs
    List<String> imageUrls = [];
    for (var image in _images) {
      try {
        print('Uploading image: ${image.name}');
        String imageUrl = await uploadImageToFirebase(image);
        imageUrls.add(imageUrl);
        print('Image uploaded successfully: $imageUrl');
      } catch (e) {
        print('Error uploading image: $e');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to upload image: ${e.toString()}'),
          ),
        );
        return;
      }
    }

    // Save the review to Firestore
    try {
      print('Saving review to Firestore...');
      await FirebaseFirestore.instance.collection('reviews').add({
        'destinationID': widget.destinationID,
        'userEmail': user.email!,
        'rating': _rating,
        'text': _commentController.text,
        'imageUrls': imageUrls,
        'timestamp': Timestamp.now(),
      });
      print('Review saved successfully!');

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Review submitted successfully!'),
        ),
      );

      // Go back to the previous screen
      Navigator.pop(context);
    } catch (e) {
      print('Error saving review: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to submit review: ${e.toString()}'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Submit Review'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            RatingBar.builder(
              initialRating: _rating,
              minRating: 1,
              direction: Axis.horizontal,
              allowHalfRating: true,
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
            const SizedBox(height: 16),
            TextField(
              controller: _commentController,
              decoration: const InputDecoration(
                labelText: 'Your Review',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _pickImages,
              child: const Text('Add Images'),
            ),
            const SizedBox(height: 16),
            // Display selected images
            _images.isNotEmpty
                ? Wrap(
                    children: _images.map((image) {
                      return Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: image.bytes != null
                            ? Image.memory(
                                image.bytes!,
                                width: 100,
                                height: 100,
                                fit: BoxFit.cover,
                              )
                            : const Text('No image data'),
                      );
                    }).toList(),
                  )
                : Container(),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _submitReview,
              child: const Text('Submit Review'),
            ),
          ],
        ),
      ),
    );
  }
}
