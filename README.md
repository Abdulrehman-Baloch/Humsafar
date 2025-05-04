Humsafar - AI-Powered Trip Planner
Overview
Humsafar is an AI-powered trip planner application designed to streamline the travel planning process for users, with a focus on promoting tourism in Pakistan. The application provides personalized destination recommendations, budget estimations, detailed itineraries, packing lists, and real-time weather updates. Built with a modern tech stack, Humsafar offers a seamless and intuitive user experience across Android, iOS, and web platforms.
Features

AI-Powered Trip Planning: Generate personalized trip itineraries based on user preferences, travel dates, and party size.
Destination Discovery: Explore destinations with comprehensive details, including attractions, best times to visit, and user reviews.
Accommodation & Transportation Booking: Search and book lodging and travel options with filters for price, amenities, and preferences.
Itinerary Management: Create, view, and modify detailed trip plans with calendar integration.
Packing List Management: Generate and customize packing lists with categorization and sharing capabilities.
Weather Updates: Access real-time weather forecasts and 5-day predictions for destinations.
User Reviews & Ratings: Share and view community-driven feedback to make informed travel decisions.
Culturally Relevant Design: Features Pakistani-inspired design elements for a localized experience.

Tech Stack

Frontend: Flutter (Dart) for cross-platform UI development.
Backend: Firebase
Firebase Authentication for secure user management.
Firebase Firestore for real-time NoSQL database storage.
Firebase Storage for image assets.


Architecture: Multi-tier (Presentation, Business Logic, Data Layer) for maintainability and scalability.

Installation
Prerequisites

Flutter SDK (version 3.0 or higher)
Dart (included with Flutter)
Firebase account and project setup
Android Studio/Xcode for mobile development
A code editor (e.g., VS Code)

Steps

Clone the Repository:
git clone https://github.com/your-repo/humsafar.git
cd humsafar


Install Dependencies:
flutter pub get


Set Up Firebase:

Create a Firebase project at console.firebase.google.com.
Add your Android, iOS, and web apps to the Firebase project.
Download the configuration files (google-services.json for Android, GoogleService-Info.plist for iOS, and Firebase config for web) and place them in the appropriate project directories.
Enable Firebase Authentication, Firestore, and Storage in the Firebase console.


Run the Application:
flutter run

Ensure an emulator or physical device is connected.


Project Structure
humsafar/
├── lib/
│   ├── screens/              # UI screens (e.g., Welcome, Login, Home)
│   ├── models/               # Data models for destinations, trips, etc.
│   ├── services/             # Business logic and Firebase interactions
│   ├── widgets/              # Reusable UI components
│   └── main.dart             # Entry point
├── assets/                   # Images and other static assets
├── android/                  # Android-specific configurations
├── ios/                      # iOS-specific configurations
├── web/                      # Web-specific configurations
└── pubspec.yaml              # Flutter dependencies and metadata

Usage

Register/Login: Create an account or log in using email and password via Firebase Authentication.
Plan a Trip:
Use the AI Trip Planner to input preferences and generate a custom itinerary.
Manually add destinations, accommodations, and transportation to your trip plan.


Explore Destinations: Browse destinations, view details, and read user reviews.
Manage Itineraries: View, modify, or share trip plans with others.
Create Packing Lists: Generate and customize packing lists for your trips.
Check Weather: Access real-time weather updates for your destinations.

Testing
The project includes a comprehensive test suite covering:

Unit Tests: For business logic and data processing.
Integration Tests: For Firebase interactions and UI flows.
Boundary Tests: For input validation (e.g., trip name length, traveler count).
Equivalence Class Testing: For feature functionality (e.g., booking, sharing).

Run tests using:
flutter test

Scalability & Future Enhancements

Regional Expansion: Add support for destinations beyond Pakistan.
Advanced UI: Implement component-based architecture and animated transitions.
Enhanced Search: Add more granular filters for accommodations and transportation.
Third-Party Integrations: Integrate with external APIs for real-time booking and payment processing.
Multilingual Support: Add locale support for languages beyond English.

Contributors

Sana Mir (22I-1160)
Ayesha Kiani (22I-1283)
Abdulrehman (22I-1182)

License
This project is licensed under the MIT License. See the LICENSE file for details.
Contact
For inquiries or support, contact the project team at your-email@example.com.
