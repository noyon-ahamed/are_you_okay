# Are You Okay? (আপনি কি ঠিক আছেন?) 🛡️

**Are You Okay?** is a comprehensive safety and wellness companion designed to keep you and your loved ones secure. It combines proactive safety check-ins, instant emergency alerts, real-time environment monitoring, and AI-driven health support into a single, seamless experience.

## 🚀 Key Features

### 🛡️ Safety & Emergency
- **Daily Safety Check-ins**: Automated rolling 24-hour check-in window with streak tracking.
- **SOS Alerts**: Instant emergency signal with real-time location sharing to trusted contacts.
- **Scream Detection**: Automatic SOS activation upon detecting loud screams (Voice SOS).
- **Fake Call**: Simulation tool to help users exit uncomfortable or unsafe situations.
- **Emergency Contacts**: Hierarchical priority-based contact management.

### 🌎 Environment & Health
- **Real-time Earthquake Alerts**: Integration with global seismic data (USGS) to provide proximity-based warnings.
- **AI Health Assistant**: Intelligent chatbot for physical and mental health advice (powered by GenAI).
- **Mood Tracking**: Daily mood logging with history and patterns analysis.

### 📱 User Experience
- **Real-time Updates**: Powered by Socket.io for instant status synchronization.
- **Offline Support**: Robust local caching (Hive/SharedPrefs) for viewing history and logging data without internet.
- **Multi-language**: Full support for English and Bangla.
- **Dark Mode**: Premium, eye-friendly design for all environments.

---

## 🛠️ Tech Stack

### Frontend (Flutter)
- **Framework**: [Flutter](https://flutter.dev/) (Dart)
- **State Management**: [Riverpod](https://riverpod.dev/)
- **Navigation**: [GoRouter](https://pub.dev/packages/go_router)
- **Local Storage**: [Hive](https://pub.dev/packages/hive), [Shared Preferences](https://pub.dev/packages/shared_preferences)
- **Real-time**: [Socket.io Client](https://pub.dev/packages/socket_io_client)
- **Animations**: [Lottie](https://pub.dev/packages/lottie), Flutter Animate
- **Notifications**: [Firebase Cloud Messaging](https://firebase.google.com/docs/cloud-messaging), [Flutter Local Notifications](https://pub.dev/packages/flutter_local_notifications)

### Backend (Node.js)
- **Runtime**: [Node.js](https://nodejs.org/)
- **Framework**: [Express](https://expressjs.com/)
- **Database**: [MongoDB](https://www.mongodb.com/) (Mongoose ODM)
- **Real-time**: [Socket.io](https://socket.io/)
- **Authentication**: JWT (JSON Web Tokens) with Bcrypt encryption.
- **Integrations**: 
  - Firebase Admin SDK (Push Notifications)
  - Twilio (SMS/Voice Alerts)
  - Nodemailer (Email Alerts)
  - Groq/Anthropic SDKs (AI Assistant)
  - SSLCommerz/Stripe (Payment Gateways)

---

## ⚙️ Installation & Setup

### Prerequisites
- Flutter SDK (Latest Stable)
- Node.js (v18+)
- MongoDB (Local or Atlas)

### Backend Setup
1. Navigate to the `backend` directory.
2. Install dependencies:
   ```bash
   npm install
   ```
3. Configure environment variables (create a `.env` file):
   ```env
   PORT=3000
   MONGODB_URI=your_mongodb_uri
   JWT_SECRET=your_jwt_secret
   FIREBASE_KEY=your_firebase_key
   TWILIO_ACCOUNT_SID=your_twilio_account_sid
   TWILIO_AUTH_TOKEN=your_twilio_token
   TWILIO_PHONE_NUMBER=your_twilio_phone_number
   EMAIL_USER=your_email@gmail.com
   EMAIL_PASS=your_email_app_password
   ```
4. Start the server:
   ```bash
   npm run dev
   ```

### Flutter Setup
1. Install Flutter dependencies:
   ```bash
   flutter pub get
   ```
2. Configure `.env` in the root directory for API endpoints.
3. Run the app:
   ```bash
   flutter run
   ```

---

## 🏗️ Architecture

The project follows a modular and scalable architecture:
- **Clean Architecture Principles**: Separation of concerns between Data, Domain, and Presentation layers.
- **Provider Pattern**: Decoupled state management using Riverpod.
- **Repository Pattern**: Abstracted data sources for both API and Local storage.
- **Background Services**: WorkManager integration for periodic safety logic.

---

## 🤝 Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

## 📄 License

This project is licensed under the MIT License.

---
*Developed by [Noyon Ahamed](https://github.com/noyon-ahamed)*
