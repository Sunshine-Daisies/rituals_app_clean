---
sidebar_position: 1
---

import FullscreenDiagram from '@site/src/components/FullscreenDiagram';

# Gamification System

The Rituals App uses a robust gamification system to keep users motivated and engaged. This system includes Experience Points (XP), Levels, Badges, and Streaks.

## Experience Points (XP) & Levels

Users earn XP for completing various actions within the app. Accumulating XP allows users to level up.

### XP Sources

| Action | XP Reward | Frequency |
| :--- | :--- | :--- |
| **Complete a Ritual** | 10 XP | Per completion |
| **Maintain a Streak** | 5 XP | Daily bonus |
| **Add a New Friend** | 20 XP | One-time per friend |
| **Create a Ritual** | 15 XP | One-time per ritual |

### Leveling Logic

<FullscreenDiagram definition={`
flowchart LR
    Action[User Action] -->|Earns XP| Calc{Calculate Total XP}
    Calc --> Check{Threshold Reached?}
    
    Check -->|No| Update[Update Progress Bar]
    Check -->|Yes| LevelUp[Level Up Event]
    
    LevelUp --> Dialog[Show Celebration]
    LevelUp --> Unlock[Unlock New Features/Badges]
    
    style LevelUp fill:#ff9,stroke:#f90,stroke-width:2px
`} />

### Leveling Formula

Levels are calculated based on total XP. The formula used is generally linear or slightly exponential to increase difficulty at higher levels.

> **Current Formula:** `Level = floor(TotalXP / 100) + 1`

## Badges

Badges are special achievements that users can unlock by meeting specific criteria.

*   **Early Bird:** Complete a ritual before 8:00 AM.
*   **Streak Master:** Maintain a ritual streak for 7 days.
*   **Social Butterfly:** Add 5 friends.
*   **Ritualist:** Create 5 different rituals.

## Streaks

A "Streak" is a count of consecutive days a user has completed a specific ritual.
*   **Breaking a Streak:** If a user misses a day, the streak resets to 0.
*   **Streak Freeze:** (Planned Feature) Allows users to miss a day without losing their streak.

## Leaderboard

Users can compare their progress with friends on the global and friends-only leaderboards. Rankings are based on:
1.  Total XP
2.  Current Level
