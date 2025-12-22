---
sidebar_position: 8
---

import FullscreenDiagram from '@site/src/components/FullscreenDiagram';

# Profile & Settings

The Profile section allows users to manage their identity, preferences, account security, and premium subscription.

## Profile Overview

### User Identity
*   **Avatar:** Upload a custom profile picture (stored on server)
*   **Username:** Unique identifier used for friend searches
*   **Display Name:** Visible name on leaderboards and to friends
*   **Bio:** A short description visible to friends

### Statistics Dashboard

A summary of the user's journey displayed on the profile screen:

| Stat | Description |
| :--- | :--- |
| **Level** | Current level based on XP |
| **Total XP** | Cumulative experience points |
| **Current Streak** | Longest active streak across all rituals |
| **Rituals Created** | Number of rituals the user has made |
| **Friends** | Total friend count |
| **Badges** | Number of badges earned |

### Badge Showcase

Users can view all their earned badges:
- Grouped by category (Streak, Social, Milestone)
- Locked badges shown with requirements
- Tap to see badge details and unlock date

## Premium Subscription ⭐

Premium users receive enhanced features:

| Feature | Free | Premium |
| :--- | :--- | :--- |
| Ritual Creation | ✅ Unlimited | ✅ Unlimited |
| AI Chat | ✅ Available | ⭐ Priority |
| Badges | ✅ All | ⭐ All + Exclusive |
| Support | Standard | ⭐ Priority |
| Premium Badge | ❌ | ⭐ Displayed on profile |

### Premium Indicator
- Crown icon (👑) next to username
- Premium badge on profile card
- Special styling in leaderboards

## Settings

### App Settings

| Setting | Description |
| :--- | :--- |
| **Theme** | Dark mode (default), custom themes planned |
| **Language** | English (more languages coming) |
| **Notifications** | Granular push notification controls |

### Account Settings

| Setting | Description |
| :--- | :--- |
| **Edit Profile** | Change name, username, avatar |
| **Change Password** | Update account password |
| **Email Verification** | Verify or change email |
| **Logout** | Sign out of account |

### Help & Support

| Option | Description |
| :--- | :--- |
| **FAQ** | Frequently asked questions |
| **Contact Support** | Chat with support team |
| **Replay Onboarding** | Re-watch app introduction |
| **Report Bug** | Submit bug reports |

## Privacy & Data

<FullscreenDiagram definition={`
flowchart LR
    User -->|Request Data| App
    App -->|Export JSON| API
    API -->|Email Link| User
    
    User -->|Delete Account| App
    App -->|Confirm| API
    API -->|Soft Delete 30 Days| DB
    API -->|Hard Delete| DB
`} />

### Profile Visibility

| Level | Who Can See |
| :--- | :--- |
| **Public** | Anyone on platform |
| **Friends Only** | Only accepted friends |
| **Private** | Only you |

### Data Export

Users can request a full export of their data:
- Rituals and completion history
- XP and badge history
- Friend list
- Delivered as JSON file via email

### Account Deletion

1. Go to Settings → Account → Delete Account
2. Confirm deletion
3. 30-day grace period (soft delete)
4. Permanent deletion after 30 days
