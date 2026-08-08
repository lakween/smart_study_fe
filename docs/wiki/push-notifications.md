# Push notifications

Smart Study persists every notification in PostgreSQL. Socket.IO updates an open
app, while Firebase Cloud Messaging displays notifications when Android or iOS is
backgrounded or terminated. The notification ID is shared across both transports,
and the REST inbox remains authoritative.

Direct-message pushes are the exception to the notification-inbox model: the
authoritative record is the PostgreSQL `direct_messages` row and the chat REST
history. A chat push does not add a duplicate item to the general notification inbox.

## Flutter configuration files

The Firebase Android app must use package ID `com.example.my_app`. Place its file at:

```text
android/app/google-services.json
```

The Firebase iOS app must use bundle ID `com.example.myApp`. Place its file at:

```text
ios/Runner/GoogleService-Info.plist
```

On macOS, open `ios/Runner.xcworkspace` in Xcode, add the plist to the Runner target,
and enable **Push Notifications** plus **Background Modes > Remote notifications**.
Upload the Apple Push Notification authentication key in Firebase Console under
Project settings > Cloud Messaging. Apple push must be tested on a physical device.

Android 13+ permission is requested after authentication. Android emulators must use
a Google Play-enabled image. Rebuild and reinstall after adding either platform file.

## Backend credentials

Download a Firebase Admin SDK service-account JSON. Do not place it in either Git
repository. The preferred production setup stores its complete, single-line JSON
value directly in the protected environment file:

```dotenv
PUSH_NOTIFICATIONS_ENABLED=true
FIREBASE_PROJECT_ID=your-firebase-project-id
FIREBASE_SERVICE_ACCOUNT_JSON='{"type":"service_account",...}'
```

Keep the private key newlines encoded as `\n` and set the environment file mode to
`600`. As a fallback, copy the file to:

```text
/opt/smart-study-backend/shared/firebase-service-account.json
```

Set owner/group to `deploy`, mode `600`, and add these values to
`/opt/smart-study-backend/shared/.env`:

```dotenv
PUSH_NOTIFICATIONS_ENABLED=true
FIREBASE_PROJECT_ID=your-firebase-project-id
GOOGLE_APPLICATION_CREDENTIALS=/opt/smart-study-backend/shared/firebase-service-account.json
```

Inline JSON takes priority if both credential variables are configured.

The normal backend deployment applies the `push_device_tokens` migration. Restarting
the web and scheduler services is handled by the deployment workflow.

## Delivery and navigation

- Login/register registers the current FCM token; token refresh updates it.
- Sign-out unregisters the device and deletes its local FCM token.
- Session expiry invalidates the local token; Firebase rejection cleans stale rows.
- Foreground FCM refreshes the REST inbox while Socket.IO provides the immediate item.
- Direct-message pushes use `type=message` and the sender ID as `relatedId`; foreground Socket.IO updates chat state and background/terminated taps open that friend conversation.
- Background/terminated taps open exam detail, revision practice, friend requests,
  quizzes, or the notification inbox based on authenticated notification data.
- Settings persists exam reminders as an hour-based lead time and revision reminders
  as a day-based lead time. These values affect reminder selection only; the
  scheduler's second-based environment intervals remain deployment controls.
