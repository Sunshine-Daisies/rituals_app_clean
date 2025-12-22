---
sidebar_position: 7
---

import FullscreenDiagram from '@site/src/components/FullscreenDiagram';

# Push Notifications

Notifications are crucial for habit formation. The Rituals App uses Firebase Cloud Messaging (FCM) for reliable push notifications across all platforms.

## Notification Types

| Type | Source | Purpose |
| :--- | :--- | :--- |
| **Ritual Reminder** | Scheduled | Remind user to perform a specific ritual at set time |
| **Streak Warning** | Backend | Warn user at 8 PM if they haven't completed their ritual |
| **Partner Nudge** | Real-time | Friend manually sends a reminder |
| **Friend Request** | Real-time | Notification when someone adds you |
| **Partnership Invite** | Real-time | Notification when invited to join a ritual |
| **Badge Unlock** | Real-time | Celebration when a new badge is earned |

## Architecture

<FullscreenDiagram definition={`
flowchart TD
    subgraph Mobile [Flutter App]
        App[App Instance]
        FCMToken[FCM Token]
        LocalStore[Local Notification Display]
    end
    
    subgraph Backend [Node.js Server]
        API[API Server]
        TokenDB[(user_fcm_tokens)]
        NotifDB[(notifications)]
    end
    
    subgraph Firebase [Firebase Cloud Messaging]
        FCM[FCM Service]
    end
    
    App -->|Register Token| API
    API -->|Store| TokenDB
    
    API -->|Send Push| FCM
    FCM -->|Deliver| App
    App -->|Display| LocalStore
    
    API -->|Log| NotifDB
    
    style Firebase fill:#ff9800,stroke:#e65100
    style Backend fill:#4caf50,stroke:#2e7d32
    style Mobile fill:#2196f3,stroke:#1565c0
`} />

## FCM Token Management

### Token Registration Flow

1. User logs in to the app
2. App requests FCM permission
3. Firebase returns device token
4. Token sent to backend: `POST /api/notifications/fcm-token`
5. Token stored in `user_fcm_tokens` table

### Database Schema

```sql
CREATE TABLE user_fcm_tokens (
  id SERIAL PRIMARY KEY,
  user_id UUID REFERENCES users(id),
  fcm_token TEXT NOT NULL,
  device_id TEXT,
  created_at TIMESTAMP DEFAULT NOW(),
  updated_at TIMESTAMP DEFAULT NOW(),
  UNIQUE(user_id, fcm_token)
);
```

### Multi-Device Support

Users can be logged in on multiple devices. Each device registers its own FCM token, and notifications are sent to all active tokens.

## Notification Actions

Some notifications support **actionable buttons**:

| Notification | Actions |
| :--- | :--- |
| Ritual Reminder | [Complete] [Snooze] |
| Partner Nudge | [View Ritual] [Dismiss] |
| Partnership Invite | [Accept] [Decline] |
| Friend Request | [Accept] [View Profile] |

## In-App Notifications

Beyond push notifications, the app maintains an in-app notification center:

### Notification Screen
- Access via bell icon in header
- Unread badge count
- List of all notifications (read/unread)
- Tap to navigate to relevant screen

### Notification Storage

```sql
CREATE TABLE notifications (
  id SERIAL PRIMARY KEY,
  user_id UUID REFERENCES users(id),
  type VARCHAR(50) NOT NULL,
  title VARCHAR(200),
  body TEXT,
  data JSONB,
  is_read BOOLEAN DEFAULT FALSE,
  created_at TIMESTAMP DEFAULT NOW()
);
```

## Configuration

Users can customize preferences in Settings:

| Setting | Options |
| :--- | :--- |
| **Push Enabled** | On / Off |
| **Sound** | On / Off |
| **Streak Warnings** | On / Off |
| **Partner Nudges** | On / Off |

## Background Service

The Flutter app uses a **background service** to:
- Handle notifications when app is closed
- Process notification taps
- Navigate to correct screen on tap
