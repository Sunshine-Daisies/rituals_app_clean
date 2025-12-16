---
sidebar_position: 2
---

import FullscreenDiagram from '@site/src/components/FullscreenDiagram';

# Rituals Management

Rituals are the core unit of the application. A "Ritual" represents a habit or task that a user wants to perform regularly.

## User Flow

The following diagram illustrates the lifecycle of a ritual from creation to completion.

<FullscreenDiagram definition={`
flowchart TD
    A[User] -->|Creates Ritual| B(Ritual Created)
    B --> C{Is it Due Today?}
    C -->|Yes| D[Show on Dashboard]
    C -->|No| E[Hide from Dashboard]
    D --> F[User Checks Box]
    F --> G[Mark as Completed]
    G --> H[Award XP]
    H --> I{Streak Continued?}
    I -->|Yes| J[Increment Streak]
    I -->|No| K[Reset Streak]
    J --> L[Update Leaderboard]
    K --> L
    
    style A fill:#f9f,stroke:#333
    style G fill:#9f9,stroke:#333
`} />

## Ritual Structure

Each ritual consists of the following properties:

*   **Title:** The name of the ritual (e.g., "Morning Meditation").
*   **Description:** Optional details about the ritual.
*   **Frequency:** How often the ritual should be performed (Daily, Weekly, Specific Days).
*   **Time:** The target time for the ritual.
*   **Reminder:** Whether the user should receive a push notification.
*   **Category:** Tags like Health, Productivity, Mindfulness.

## Creating a Ritual

Users can create rituals via the "Create" tab.
1.  Enter a title and description.
2.  Select frequency (e.g., "Every Mon, Wed, Fri").
3.  Set a reminder time.
4.  Choose an icon and color for visual distinction.

## Tracking & Completion

*   **Dashboard:** The home screen shows rituals due for the current day.
*   **Check-in:** Users mark a ritual as "Complete" by tapping the checkbox.
*   **History:** Users can view a calendar history of their completions.

## Social Rituals (Partnerships)

Users can invite friends to join a ritual.
*   **Partnership:** When a friend accepts, both users track the same ritual.
*   **Accountability:** Partners can see each other's progress on that specific ritual.
*   **Nudges:** Partners can send "Nudges" to remind each other to complete the task.
