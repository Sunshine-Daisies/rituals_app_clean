---
sidebar_position: 5
---

import FullscreenDiagram from '@site/src/components/FullscreenDiagram';

# Notifications

Notifications are crucial for habit formation. The Rituals App uses a hybrid approach combining local scheduling and remote push notifications.

## Notification Types

| Type | Source | Purpose |
| :--- | :--- | :--- |
| **Ritual Reminder** | Local | Remind user to perform a specific ritual at a set time. |
| **Streak Warning** | Remote/Local | Warn user if they are about to lose a streak (e.g., 8 PM). |
| **Social Nudge** | Remote (FCM) | A friend manually sends a reminder. |
| **Friend Request** | Remote (FCM) | Notification when someone adds you. |
| **System Update** | Remote (FCM) | App updates, maintenance, or special events. |

## Architecture

<FullscreenDiagram definition={`
flowchart TD
    subgraph Local [Device / Local]
        App[Flutter App]
        LocalNotif[flutter_local_notifications]
        Alarm[Android AlarmManager / iOS Calendar]
    end
    
    subgraph Remote [Backend / Cloud]
        Server[Node.js Server]
        FCM[Firebase Cloud Messaging]
        APNS[Apple Push Notification Service]
    end
    
    %% Local Flow
    App -->|Schedule Reminder| LocalNotif
    LocalNotif -->|Trigger at Time| Alarm
    Alarm -->|Show| User((User))
    
    %% Remote Flow
    Server -->|Send Nudge| FCM
    FCM -->|Push| App
    App -->|Display| User
    
    style Local fill:#e1f5fe,stroke:#01579b
    style Remote fill:#fff3e0,stroke:#e65100
`} />

## Configuration

Users can customize their notification preferences in the Settings page:
*   **Do Not Disturb:** Mute all notifications during specific hours.
*   **Sound:** Toggle notification sounds.
*   **Vibration:** Toggle vibration.
