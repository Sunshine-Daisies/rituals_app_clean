---
sidebar_position: 5
---

import FullscreenDiagram from '@site/src/components/FullscreenDiagram';

# Onboarding Flow

The Onboarding Flow provides a seamless introduction for new users, guiding them through the app's core features and helping them create their first ritual.

## Overview

The onboarding experience consists of three main components:

1. **Welcome Screens** - Visual introduction to app features
2. **First Ritual Wizard** - Guided ritual creation
3. **First Completion Celebration** - Confetti reward on first success

<FullscreenDiagram definition={`
flowchart LR
    Login[User Logs In] --> Check{First Time?}
    Check -->|Yes| Welcome[Welcome Screens]
    Check -->|No| Home[Home Screen]
    
    Welcome --> Wizard[First Ritual Wizard]
    Wizard --> Home
    
    Home --> Complete[Complete First Ritual]
    Complete --> Celebrate[Celebration Animation 🎉]
    
    style Welcome fill:#9cf,stroke:#09f
    style Wizard fill:#f9f,stroke:#f09
    style Celebrate fill:#ff9,stroke:#f90
`} />

## Welcome Screens

Three swipeable pages introduce the app's core value propositions:

### Page 1: Build Better Habits 🎯
> "Create daily rituals that transform your life. Track your progress and watch yourself grow."

### Page 2: Grow Together 🤝
> "Partner up with friends and family. Support each other on your wellness journey."

### Page 3: Earn Rewards 🏆
> "Complete rituals to earn XP, unlock badges, and climb the leaderboards."

### Navigation
- **Skip Button:** Top-right corner to bypass screens
- **Next Button:** Proceed to next page
- **Get Started:** Final page button leads to wizard

## First Ritual Wizard

A 4-step guided flow for creating the user's first ritual:

### Step 1: Choose Your Habit

Users select from preset options or create custom:

| Preset | Emoji | Description |
| :--- | :--- | :--- |
| Morning Meditation | 🧘 | Start your day with mindfulness |
| Daily Exercise | 💪 | Move your body every day |
| Reading | 📚 | Expand your mind with books |
| Journaling | ✍️ | Reflect on your thoughts |
| Hydration | 💧 | Drink 8 glasses of water |
| Gratitude Practice | 🙏 | Count your blessings |

**Custom Option:** Text input for personalized habits

### Step 2: Set Time

- Large, prominent time display
- Tap to open time picker
- Default: 7:00 AM

### Step 3: Select Days

- Visual day selector (circular buttons)
- M, T, W, T, F, S, S
- Default: Weekdays (Mon-Fri)
- Shows "X days selected" count

### Step 4: Confirm & Create

- Summary card showing:
  - 🌟 Ritual name
  - ⏰ Reminder time
  - 📅 Days per week
- "Create My Ritual" button
- Loading state during API call

## First Completion Celebration

When user completes their first ritual ever:

### Visual Experience
- Full-screen overlay
- Confetti burst animation (multi-colored)
- Trophy emoji (🏆) with glow effect
- "First Ritual Complete!" title
- "+20 XP" bonus display
- "Tap anywhere to continue" prompt

### Technical Details
- Uses `confetti` Flutter package
- Auto-dismisses after 4 seconds
- State tracked via `OnboardingService`
- Triggers only once per account

## State Management

The `OnboardingService` manages onboarding state via SharedPreferences:

| Key | Purpose |
| :--- | :--- |
| `has_seen_welcome` | Tracks if welcome screens were viewed |
| `has_completed_first_ritual` | Triggers celebration on first completion |
| `is_first_launch` | General first-launch flag |

### Replay Feature

Users can replay the onboarding experience:
1. Navigate to Profile → Settings → Help & Support
2. Tap "Replay App Introduction"
3. Onboarding state is reset
4. Redirected to welcome screens

## Implementation Files

```
lib/
├── services/
│   └── onboarding_service.dart       # State management
├── features/onboarding/
│   ├── onboarding_screen.dart        # Welcome carousel
│   ├── first_ritual_wizard.dart      # 4-step wizard
│   └── widgets/
│       ├── onboarding_page.dart      # Single page template
│       └── page_indicator.dart       # Dot indicators
└── widgets/
    └── celebration_overlay.dart      # Confetti animation
```
