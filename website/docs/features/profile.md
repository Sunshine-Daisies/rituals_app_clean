---
sidebar_position: 6
---

import FullscreenDiagram from '@site/src/components/FullscreenDiagram';

# Profile & Settings

The Profile section allows users to manage their identity, preferences, and account security.

## Features

### 1. User Identity
*   **Avatar:** Users can upload a profile picture or choose from preset avatars.
*   **Username:** Unique identifier used for friend searches.
*   **Bio:** A short description visible to friends.

### 2. Statistics Dashboard
A summary of the user's journey:
*   **Total XP:** Cumulative experience points.
*   **Current Streak:** Longest active streak across all rituals.
*   **Completion Rate:** Percentage of rituals completed on time.

### 3. App Settings

| Setting | Description |
| :--- | :--- |
| **Theme** | Switch between Light, Dark, or System Default mode. |
| **Language** | Change app language (English, Turkish, Spanish, etc.). |
| **Notifications** | Granular control over push and local notifications. |
| **Privacy** | Control who can see your profile (Public, Friends Only, Private). |

## Data Management

<FullscreenDiagram definition={`
flowchart LR
    User -->|Request Data| App
    App -->|Export JSON| API
    API -->|Email Link| User
    
    User -->|Delete Account| App
    App -->|Confirm| API
    API -->|Soft Delete (30 Days)| DB
    API -->|Hard Delete| DB
`} />
