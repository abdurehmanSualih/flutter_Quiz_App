# Flutter Quiz App

A comprehensive quiz application featuring a Flutter web admin interface (`quiz_admin_web`) for managing quiz questions, a Flutter mobile app (`quiz_app`) for users to take quizzes, and a Node.js/MongoDB backend for data storage and API services. Administrators sign in to add, edit, delete (with confirmation), and search questions, while users interact with quizzes via a mobile app with a welcome screen, quiz-taking interface, and results display.

## Features

### Admin Web Interface (`quiz_admin_web`)
- **Sign-In**: Secure admin authentication (signup removed).
- **Question Management**:
  - Add questions with four options, correct answer, and explanation (form validation).
  - Edit questions via a dialog with validation.
  - Delete questions with a confirmation dialog ("Are you sure you want to delete this question?").
  - Real-time search to filter questions.
- **UI**: Responsive design using Flutter, styled with `GoogleFonts.lato`.
- **Logout**: Clears session and returns to sign-in page.

### Mobile App (`quiz_app`)
- **Offline-First**: Caches questions locally using `shared_preferences`, syncs with backend when online.
- **Welcome Screen**: Onboarding or home screen to start the quiz (`welcome_screen.dart`).
- **Quiz-Taking**: Users answer multiple-choice questions with navigation (`quiz_screen.dart`).
- **Results Screen**: Displays quiz score and summary after completion (`result_screen.dart`).
- **Feedback**: Immediate feedback on correct/incorrect answers with explanations.
- **UI**: User-friendly Flutter interface with smooth navigation.
- **Backend Integration**: Fetches questions from the Node.js API.
- **Serialization**: Uses `json_serializable` for question data handling (`question.g.dart`).

### Backend
- **Node.js/Express**: REST API for authentication and question management.
- **MongoDB**: Stores users and questions.
- **Endpoints**:
  - `POST /api/auth/signin`: Admin login.
  - `GET /api/questions`: Fetch questions.
  - `POST /api/questions`: Add question.
  - `PUT /api/questions/:id`: Update question.
  - `DELETE /api/questions/:id`: Delete question.

## Prerequisites
- **Flutter**: SDK 3.0.0 or higher.
- **Dart**: Included with Flutter.
- **Node.js**: v16 or higher.
- **MongoDB**: v5.0 or higher (local or MongoDB Atlas).
- **Git**: For cloning the repository.
- **Chrome**: For running the web app.
- **Android/iOS Emulator**: For running the mobile app.

## Setup

### 1. Clone the Repository
```bash
git clone <repository-url>
cd flutter_Quiz_App

2. Backend Setup

Navigate to the backend: cd backend
Install dependencies: npm install
Create a .env file:ADMIN_API_KEY=your-secret-admin-key
JWT_SECRET=your-jwt-secret


Start MongoDB locally or configure Atlas in server.js.
Seed an admin user and sample question:use quiz_db
db.users.insertOne({ email: "test@example.com", password: "password" });
db.questions.insertOne({
  question: "What is 2 + 2?",
  options: ["3", "4", "5", "6"],
  correctAnswer: "4",
  explanation: "2 + 2 equals 4"
});


Start the backend: node server.js
Default port: 3000.



3. Web App Setup (quiz_admin_web)

Navigate to the web app: cd quiz_admin_web
Install Flutter dependencies: flutter pub get
Verify pubspec.yaml:dependencies:
  flutter:
    sdk: flutter
  http: ^1.1.0
  google_fonts: ^6.1.0
  shared_preferences: ^2.2.2


Configure lib/services/api_service.dart:static const String baseUrl = 'http://localhost:3000/api';


Use host IP (e.g., 192.168.x.x) if localhost fails.


Run the web app:flutter clean
flutter run -d chrome --web-port=8080


Open http://localhost:8080.



4. Mobile App Setup (quiz_app)

Navigate to the mobile app: cd quiz_app
Install dependencies: flutter pub get
Verify pubspec.yaml:dependencies:
  flutter:
    sdk: flutter
  http: ^1.1.0
  json_annotation: ^4.8.1
  shared_preferences: ^2.2.2
dev_dependencies:
  json_serializable: ^6.7.1
  build_runner: ^2.4.6


Generate serialization code for question.g.dart:flutter pub run build_runner build --delete-conflicting-outputs


Configure lib/services/api_service.dart:static const String baseUrl = 'http://localhost:3000/api';


Use host IP if localhost fails.


Run the mobile app:flutter clean
flutter run -d emulator



Usage
Admin Web Interface (quiz_admin_web)

Sign-In:
Go to http://localhost:8080.
Enter:
Email: test@example.com
Password: password


Redirects to Admin Dashboard.


Manage Questions:
Add: Expand "Add New Question," fill fields (question, options, correct answer, explanation), click "Add Question."
Edit: Click edit icon, update fields in dialog, click "Save."
Delete: Click delete icon, confirm in dialog ("Are you sure you want to delete this question?"), question is removed.
Search: Type in search bar to filter questions.


Logout: Click logout icon to return to sign-in.

Mobile App (quiz_app)

Launch the app on an emulator or device (works offline or online).
Welcome Screen: View onboarding or click to start the quiz.
Quiz Screen: Browse questions, select answers, and submit.
Results Screen: View score and summary after completing the quiz.
Receive immediate feedback (correct/incorrect, explanation) per question.
Questions are cached locally for offline use; syncs with backend when online.
Restart the quiz from the welcome or results screen.

Project Structure
flutter_Quiz_App/
├── backend/                    # Node.js backend
│   ├── server.js               # API server
│   ├── .env                    # Environment variables
│   ├── package.json            # Node.js dependencies
├── quiz_admin_web/             # Flutter web admin app
│   ├── lib/
│   │   ├── models/
│   │   │   ├── question.dart   # Question model
│   │   ├── screens/
│   │   │   ├── admin_dashboard.dart
│   │   │   ├── signin_screen.dart
│   │   ├── services/
│   │   │   ├── api_service.dart
│   │   ├── main.dart           # Web app entry point
│   ├── pubspec.yaml            # Flutter dependencies
├── quiz_app/                   # Flutter mobile app
│   ├── lib/
│   │   ├── models/
│   │   │   ├── question.dart   # Question model
│   │   │   ├── question.g.dart # Generated
│   │   ├── screens/
│   │   │   ├── quiz_screen.dart
│   │   │  ├── result_screen.dart
│   │   │   ├── welcome_screen.dart
│   │   ├── services/
│   │   │   ├── api_service.dart
│   │   ├── main.dart           # Mobile app entry point
│   ├── pubspec.yaml            # Flutter dependencies
├── README.md                   # This file



