---
sidebar_position: 3
---

import FullscreenDiagram from '@site/src/components/FullscreenDiagram';

# Social & Community

Building habits is easier when you're not alone. The Rituals App includes comprehensive social features to foster accountability and friendly competition.

## Friends System

Users can build their social circle within the app.

### Adding Friends
*   **Search:** Find users by username
*   **Friend Requests:** Send and receive friend requests
*   **Pending Invites:** Manage incoming requests (accept/reject)

### Friend List Features
*   View all connected friends
*   See friend's level and XP
*   View friend's public profile
*   Quick access to send partnership invites

### Friend Badges
Grow your social network to unlock badges:
- 🤝 **First Friend:** Add 1 friend (10 XP, 5 coins)
- 👥 **Social Butterfly:** Add 10 friends (50 XP, 25 coins)
- 🌟 **Popular:** Add 25 friends (100 XP, 50 coins)

## Equal Partnerships

This is the core feature for 1-on-1 accountability.

<FullscreenDiagram definition={`
flowchart TD
    A[User A] -->|Creates Ritual| R[Ritual]
    A -->|Invites| B[User B]
    B -->|Accepts Invite| P[Partnership Created]
    
    P --> PA[User A's Instance]
    P --> PB[User B's Instance]
    
    PA -->|Completes| CA[A's Streak +1]
    PB -->|Completes| CB[B's Streak +1]
    
    CA --> VIS[Visible to Both]
    CB --> VIS
    
    style P fill:#ff9,stroke:#f90,stroke-width:2px
    style VIS fill:#9f9,stroke:#090
`} />

### How Partnerships Work

1. **Sharing:** User A creates a ritual and taps "Invite Partner"
2. **Invite Code:** A unique code is generated (e.g., `ABC123`)
3. **Joining:** User B enters the code in "Join Ritual" screen
4. **Co-op Tracking:** Both users now track the same ritual separately
5. **Independence:** Each user maintains their own streak

### Partnership Dashboard

On the home screen, partnership cards show:
- Partner's avatar and username
- Partner's completion status for today
- Your streak vs. partner's streak
- Nudge button if partner hasn't completed

### Nudges 👋

If a partner hasn't completed their ritual by a certain time:
1. Tap the "Nudge" button on their partnership card
2. Partner receives a push notification
3. Nudge shows as a friendly reminder

### Managing Partnerships

**Pending Invitations:**
- View all incoming partnership requests
- Accept to join the ritual
- Reject if not interested

**Leaving a Partnership:**
- Navigate to partnership details
- Tap "Leave Partnership"
- Your progress is preserved; you just stop tracking together

### Partnership Badges
- 🎯 **Team Player:** Join 1 partner ritual (20 XP, 10 coins)
- 🏅 **Mentor:** 5 people join your rituals (100 XP, 50 coins)

## Leaderboards

Compete with friends and the global community.

### Types of Leaderboards

| Leaderboard | Description | Reset |
| :--- | :--- | :--- |
| **Global** | Top users worldwide | Never |
| **Friends** | Ranking among your friends | Never |
| **Weekly** | This week's top performers | Every Monday |

### Ranking Criteria

Users are ranked by:
1. Total XP earned
2. Current level
3. Number of active streaks

### Leaderboard Features
- Your rank is highlighted
- See top 3 with special styling
- Tap any user to view their public profile

## Public Profiles

Each user has a public profile visible to friends:

*   **Display Name:** Customizable username
*   **Avatar:** Profile picture (upload or default)
*   **Level & XP:** Current progress
*   **Badges Earned:** Showcase achievements
*   **Active Streaks:** Current streak counts
*   **Premium Status:** Premium badge if subscribed
