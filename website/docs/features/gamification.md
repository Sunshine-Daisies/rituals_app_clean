---
sidebar_position: 1
---

import FullscreenDiagram from '@site/src/components/FullscreenDiagram';

# Gamification System

The Rituals App uses a robust gamification system to keep users motivated and engaged. This system includes Experience Points (XP), Levels, Coins, Badges, Streaks, and Freezes.

## Experience Points (XP) & Levels

Users earn XP for completing various actions within the app. Accumulating XP allows users to level up.

### XP Sources

| Action | XP Reward | Frequency |
| :--- | :--- | :--- |
| **Complete a Ritual** | 10 XP | Per completion |
| **Maintain a Streak** | 5 XP | Daily bonus |
| **First Ritual Completion** | 20 XP | One-time (after onboarding) |
| **Add a New Friend** | 20 XP | One-time per friend |
| **Create a Ritual** | 15 XP | One-time per ritual |
| **Unlock a Badge** | Varies | Per badge (15-500 XP) |

### Leveling Logic

<FullscreenDiagram definition={`
flowchart LR
    Action[User Action] -->|Earns XP| Calc{Calculate Total XP}
    Calc --> Check{Threshold Reached?}
    
    Check -->|No| Update[Update Progress Bar]
    Check -->|Yes| LevelUp[Level Up Event]
    
    LevelUp --> Dialog[Show Celebration]
    LevelUp --> Unlock[Unlock New Features/Badges]
    LevelUp --> Coins[Award Coins]
    
    style LevelUp fill:#ff9,stroke:#f90,stroke-width:2px
`} />

### Leveling Formula

Levels are calculated based on total XP. The formula uses a linear progression:

> **Current Formula:** `Level = floor(TotalXP / 100) + 1`

## Coins

Coins are a secondary currency earned through various achievements:

| Source | Coins Earned |
| :--- | :--- |
| Level Up | 10-50 coins |
| Badge Unlock | 5-200 coins (varies by badge) |
| Streak Milestones | Bonus coins |

### Coin Usage
*   **Streak Freeze:** Protect your streak from breaking (1 freeze = 50 coins)
*   **Future:** Theme Store, Avatar System

## Zen Badges 🏆

Our badge system features 15 unique achievements across three categories, each with a Zen-inspired theme:

### 🔥 Streak Category

| Badge | Name | Requirement | XP | Coins |
| :--- | :--- | :--- | :--- | :--- |
| 🔥 | Spark | 3-day streak | 15 | 5 |
| 🔥🔥 | Flame | 7-day streak | 30 | 10 |
| 🔥🔥🔥 | Fireball | 14-day streak | 50 | 20 |
| ☄️ | Meteor | 30-day streak | 100 | 50 |
| 💎 | Legend | 100-day streak | 500 | 200 |

### 🤝 Social Category

| Badge | Name | Requirement | XP | Coins |
| :--- | :--- | :--- | :--- | :--- |
| 🤝 | First Friend | Add 1 friend | 10 | 5 |
| 👥 | Social Butterfly | Add 10 friends | 50 | 25 |
| 🌟 | Popular | Add 25 friends | 100 | 50 |
| 🎯 | Team Player | Join 1 partner ritual | 20 | 10 |
| 🏅 | Mentor | 5 people join your ritual | 100 | 50 |

### 🎉 Milestone Category

| Badge | Name | Requirement | XP | Coins |
| :--- | :--- | :--- | :--- | :--- |
| 🎉 | Beginning | Complete 1 ritual | 15 | 5 |
| 📅 | Regular | Complete 30 rituals | 50 | 25 |
| 📚 | Collector | Create 5 rituals | 30 | 15 |
| 🌅 | Early Bird | 10 morning rituals | 40 | 20 |
| 🌙 | Night Owl | 10 evening rituals | 40 | 20 |

## Streaks ✅

A "Streak" is a count of consecutive days a user has completed a specific ritual.

*   **Building Streaks:** Complete your ritual daily to increase your streak count.
*   **Breaking a Streak:** Missing a day resets the streak to 0 (unless protected).
*   **Streak Bonus:** Longer streaks earn more XP per completion.

### Streak Freeze 🧊

Streak Freeze is an **active feature** that allows users to protect their streaks:

*   **Cost:** 50 coins per freeze
*   **Duration:** Protects for 1 missed day
*   **Limit:** Can stack multiple freezes
*   **Usage:** Automatically applied when a day is missed

<FullscreenDiagram definition={`
flowchart TD
    Miss[Missed Day] --> Check{Has Freeze?}
    Check -->|Yes| UseFreeze[Use 1 Freeze]
    UseFreeze --> Keep[Streak Preserved ✅]
    Check -->|No| Reset[Streak Reset to 0 ❌]
    
    style UseFreeze fill:#9cf,stroke:#09f
    style Keep fill:#9f9,stroke:#090
    style Reset fill:#f99,stroke:#f00
`} />

## Leaderboard

Users can compare their progress with friends on multiple leaderboards:

*   **Global Leaderboard:** Top users based on total XP
*   **Friends Leaderboard:** Ranking among your added friends only
*   **Weekly Rankings:** Reset every week for fresh competition

Rankings are based on:
1. Total XP
2. Current Level
3. Active Streaks
