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
    D --> F[User Swipes to Complete]
    F --> G[Mark as Completed]
    G --> H[Award XP]
    H --> I{Streak Continued?}
    I -->|Yes| J[Increment Streak]
    I -->|No| K[Reset Streak]
    J --> L[Update Leaderboard]
    K --> L
    
    style A fill:#f9f,stroke:#333
    style F fill:#9cf,stroke:#333
    style G fill:#9f9,stroke:#333
`} />

## Ritual Structure

Each ritual consists of the following properties:

| Property | Description | Required |
| :--- | :--- | :--- |
| **Name** | The name of the ritual (e.g., "Morning Meditation") | ✅ |
| **Steps** | Optional checklist items within the ritual | ❌ |
| **Reminder Time** | When to send a push notification | ✅ |
| **Reminder Days** | Which days the ritual is active (Mon-Sun) | ✅ |
| **Is Public** | Whether the ritual can be shared with partners | ❌ |

## Creating Rituals

### Standard Creation

Users can create rituals via the "Create" tab:
1. Enter a name
2. (Optional) Add step-by-step checklist items
3. Set a reminder time
4. Choose which days (Mon, Tue, Wed, etc.)
5. Save the ritual

### First Ritual Wizard (Onboarding)

New users are guided through a **4-step wizard** after signup:

<FullscreenDiagram definition={`
flowchart LR
    S1[Step 1: Choose Habit] --> S2[Step 2: Set Time]
    S2 --> S3[Step 3: Select Days]
    S3 --> S4[Step 4: Confirm]
    S4 --> Home[Go to Home]
    
    style S1 fill:#f9f,stroke:#333
    style S4 fill:#9f9,stroke:#333
`} />

**Step 1: Habit Selection**
- Preset options: Morning Meditation, Daily Exercise, Reading, Journaling, Hydration, Gratitude Practice
- Custom input for personalized habits

**Step 2: Time Selection**
- Large time picker UI
- Default: 7:00 AM

**Step 3: Day Selection**
- Visual day selector (M, T, W, T, F, S, S)
- Default: Weekdays (Mon-Fri)

**Step 4: Summary & Confirmation**
- Review all settings
- "Create My Ritual" button

## Tracking & Completion

### Dashboard View

The home screen shows rituals due for the current day:
- **Active Rituals:** Available for completion
- **Completed Rituals:** Collapsed section showing today's completions

### Swipe-to-Complete

Users can complete rituals using a **swipe gesture**:
1. Swipe the ritual card from right to left
2. Card animates with green "Complete" background
3. Ritual marked as done
4. XP awarded instantly

### First Completion Celebration 🎉

When a user completes their **first ritual ever**, they receive:
- Full-screen confetti animation
- "First Ritual Complete!" message
- Bonus 20 XP
- Celebration overlay with trophy icon

### Checklist Mode

For rituals with steps:
1. Tap the ritual card to open checklist
2. Check off individual steps
3. Ritual auto-completes when all steps are done

## Social Rituals (Partnerships)

Users can invite friends to join a ritual for accountability.

### Creating a Partnership
1. Tap "Invite Partner" on any ritual
2. Share the generated invite code
3. Partner enters code in "Join Ritual" screen

### Partnership Features
- **Shared Progress:** Both partners track the same ritual
- **Visibility:** See when your partner completes their ritual
- **Nudges:** Send friendly reminders to partners
- **Dual Streak:** Both users maintain individual streaks

### Managing Partnerships
- View active partnerships on home screen
- Accept/reject pending invitations
- Leave a partnership at any time
