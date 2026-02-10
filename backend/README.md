# Are You Okay? - Backend

This is the backend server for the "Are You Okay?" application, a personal safety and emergency response system.

## Features

- **Authentication**: User registration, login, JWT-based auth.
- **Emergency Contacts**: Manage trusted contacts for SOS alerts.
- **Check-In System**: Scheduled check-ins; alerts if missed.
- **SOS Alerts**: Trigger emergency alerts via SMS, Voice Call, and Push Notification.
- **AI Consultation**: Chat with Claude AI for safety advice or mental health support.
- **Earthquake Alerts**: Real-time earthquake monitoring and notifications.
- **Subscriptions**: Premium features via Stripe integration.
- **Real-time Updates**: Socket.io for live location and status updates.

## Project Structure

```
backend/
├── config/         # Configuration (DB, Firebase, etc.)
├── jobs/           # Background tasks (Cron jobs)
├── middleware/     # Express middleware (Auth, Error handling)
├── model/          # Mongoose models
├── routes/         # API routes
├── services/       # Business logic
├── sockets/        # WebSocket handlers
├── templates/      # Email/SMS templates
├── utils/          # Helper functions
└── server.js       # Entry point
```

## Setup & Installation

1.  **Install Dependencies**
    ```bash
    npm install
    ```

2.  **Environment Variables**
    - Copy `.env.example` to `.env`
    - Fill in the required API keys (MongoDB, Firebase, Stripe, Twilio, Anthropic).

3.  **Run Locally**
    ```bash
    npm run dev
    ```

4.  **Run in Production**
    ```bash
    npm start
    ```

## API Documentation

(Include API endpoint details here if available or link to Swagger/Postman)

## License

ISC
