---
sidebar_position: 6
---

import FullscreenDiagram from '@site/src/components/FullscreenDiagram';

# Roadmap

This document outlines the development progress and future plans for the Rituals App.

> **Status:** 🚀 Production Ready
> **Version:** 2.0

## 📅 Development Timeline

<FullscreenDiagram definition={`
gantt
    title Rituals App Development Roadmap
    dateFormat  YYYY-MM-DD
    section MVP Phase
    Backend Setup           :done,    des1, 2025-10-01, 2025-10-15
    Auth and Profile        :done,    des2, 2025-10-16, 2025-10-30
    Ritual Core Logic       :done,    des3, 2025-11-01, 2025-11-20
    Gamification XP Levels  :done,    des4, 2025-11-15, 2025-12-01
    
    section Beta Phase
    Social Features         :done,    des5, 2025-12-01, 2025-12-10
    Push Notifications      :done,    des6, 2025-12-10, 2025-12-15
    AI Chat Integration     :done,    des7, 2025-12-15, 2025-12-20
    
    section Launch Phase
    Onboarding Flow         :done,    launch1, 2025-12-20, 2025-12-22
    Premium Features        :done,    launch2, 2025-12-19, 2025-12-22
    Documentation           :active,  launch3, 2025-12-22, 2025-12-25
    
    section Future
    Group Rituals           :         fut1, 2026-01-15, 30d
    Theme Store             :         fut2, 2026-02-15, 20d
`} />

## ✅ Completed Features

### Core Functionality
| Feature | Status | Release |
| :--- | :--- | :--- |
| User Authentication | ✅ Done | v1.0 |
| Ritual CRUD | ✅ Done | v1.0 |
| Swipe-to-Complete | ✅ Done | v1.5 |
| Checklist Steps | ✅ Done | v1.0 |
| Push Notifications | ✅ Done | v1.5 |

### Gamification
| Feature | Status | Release |
| :--- | :--- | :--- |
| XP & Levels | ✅ Done | v1.0 |
| Coin System | ✅ Done | v1.5 |
| 15 Zen Badges | ✅ Done | v2.0 |
| Streak System | ✅ Done | v1.0 |
| Streak Freeze | ✅ Done | v1.5 |
| Leaderboards | ✅ Done | v1.5 |

### Social Features
| Feature | Status | Release |
| :--- | :--- | :--- |
| Friend System | ✅ Done | v1.0 |
| Equal Partnerships | ✅ Done | v2.0 |
| Nudges | ✅ Done | v2.0 |
| Pending Invites | ✅ Done | v2.0 |

### AI & Premium
| Feature | Status | Release |
| :--- | :--- | :--- |
| AI Habit Coach | ✅ Done | v1.5 |
| Intent Actions | ✅ Done | v2.0 |
| Premium Subscription | ✅ Done | v2.0 |
| Onboarding Flow | ✅ Done | v2.0 |

## 📋 Key Decisions

| Topic | Decision |
| :--- | :--- |
| **Friend Limit** | ❌ None (Unlimited) |
| **Group Rituals** | 🔮 Future Feature (Currently 1v1 only) |
| **Leaderboard Display** | 👤 By Username |
| **XP to Coin Conversion** | ❌ Not available |
| **Premium Pricing** | 💰 Subscription model |
| **Private Rituals** | 🔒 Cannot be shared |

## 🔮 Future Features

These features are planned for future updates:

### Q1 2026
| Feature | Description | Priority |
| :--- | :--- | :--- |
| **Group Rituals** | 3+ person group streaks | P0 |
| **Activity Feed** | See friends' completions | P1 |
| **Habit Analytics** | Detailed completion insights | P1 |

### Q2 2026
| Feature | Description | Priority |
| :--- | :--- | :--- |
| **Theme Store** | Buy app themes with Coins | P2 |
| **Avatar System** | Unlock avatars with Coins | P2 |
| **Widget Support** | iOS/Android home screen widgets | P1 |

### Long-term Vision
| Feature | Description |
| :--- | :--- |
| **Apple Watch** | Companion app for quick check-ins |
| **Desktop App** | Web/Desktop version |
| **AI Insights** | Personalized habit recommendations |
| **Habit Templates** | Community-shared ritual templates |
