# Are You Okay Deployment Checklist

## 1. Backend Environment

Set these environment variables on the backend host before deploy:

```env
NODE_ENV=production
PORT=3000
MONGODB_URI=...
JWT_SECRET=...
JWT_EXPIRE=30d
ENABLE_JOBS=true

FIREBASE_PROJECT_ID=...
FIREBASE_CLIENT_EMAIL=...
FIREBASE_PRIVATE_KEY="-----BEGIN PRIVATE KEY-----\n...\n-----END PRIVATE KEY-----\n"
# or use FIREBASE_SERVICE_ACCOUNT_PATH

EMAIL_USER=...
EMAIL_PASS=...

TWILIO_ACCOUNT_SID=...
TWILIO_AUTH_TOKEN=...
TWILIO_PHONE_NUMBER=...

ANTHROPIC_API_KEY=...
STRIPE_SECRET_KEY=...
SSLCOMMERZ_STORE_ID=...
SSLCOMMERZ_STORE_PASSWORD=...
```

Minimum required for reminder flow:

- `MONGODB_URI`
- `JWT_SECRET`
- `ENABLE_JOBS=true`
- Firebase Admin credentials

## 2. Backend Deploy

From [render.yaml](/Users/noyon/StudioProjects/are_you_okay/backend/render.yaml), confirm:

- service root is `backend`
- start command is `node server.js`
- `ENABLE_JOBS=true`

Deploy steps:

1. Push code to the branch used by your hosting provider.
2. Trigger a fresh backend deploy.
3. Confirm backend boots without Firebase/Mongo errors.
4. Confirm cron jobs start in logs.

Expected startup log indicators:

- `Server running on port`
- `Environment: production`
- `All background jobs started`

## 3. Mobile App Config

Before releasing the app:

1. Set the correct `API_BASE_URL` in `.env`.
2. Ensure Android uses a valid `google-services.json`.
3. Ensure iOS uses valid Firebase config if you release on iPhone.
4. Build and install on at least one real Android device.

## 4. Reminder Flow Smoke Test

Use one real test account.

1. Log in on a real device.
2. Open app settings and keep notifications enabled.
3. Confirm FCM token is registered on backend.
4. Ensure the user has not checked in for 24 hours, or manually adjust DB for testing.
5. Set test user `settings.reminderTimes` to a time 1-2 minutes ahead.
6. Wait for the scheduler to run.

Expected result:

- push notification appears even if app is closed
- notification opens the app to Home
- Home shows check-in prompt
- notification appears in Notification screen

## 5. Database Verification

For the test user, verify in MongoDB:

- `User.fcmToken` exists
- `User.settings.notificationEnabled=true`
- `User.settings.reminderTimes` contains the target time
- `Notification` document is created with:
  - `type=checkin_reminder`
  - `fcmStatus=sent` or `failed`
  - `actionData.screen=home`
  - `actionData.params.action=open_checkin`

## 6. Settings Toggle Verification

1. Turn notifications off in the app.
2. Confirm backend user document updates:
   - `settings.notificationEnabled=false`
3. Wait through a reminder slot.
4. Confirm no notification is sent.
5. Turn notifications on again.
6. Confirm reminder resumes on next slot.

## 7. Offline/Backlog Verification

1. Keep app installed.
2. Disable internet on device before reminder time.
3. Let reminder time pass.
4. Turn internet back on.
5. Open app once to allow app-side fallback sync.

Expected result:

- missed reminder is added to Notification screen
- tapping it opens Home

Note:

- fully guaranteed backlog replay while app never opens requires backend-driven catch-up logic plus FCM delivery
- current app includes local fallback, but backend remains the main reliable delivery path

## 8. Tap Routing Verification

Tap each reminder from:

- foreground state
- background state
- terminated state

Expected result:

- app lands on Home
- pending check-in prompt appears
- user can complete check-in

## 9. Production Readiness Checks

- Android notification permission granted
- Android battery optimization disabled for test devices
- Firebase Admin credentials valid
- Backend clock/timezone sane
- Mongo indexes created
- Render/host logs show scheduler running every minute

## 10. Rollback Plan

If reminder flow misbehaves:

1. Set `ENABLE_JOBS=false`
2. Redeploy backend
3. Keep app usable while reminders are paused

## 11. Post-Deploy Monitoring

Track these after release:

- number of `checkin_reminder` notifications created
- FCM send failures
- reminder click-through rate
- successful check-ins after reminder
- duplicate reminder creation

