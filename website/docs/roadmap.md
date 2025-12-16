---
sidebar_position: 5
---

import FullscreenDiagram from '@site/src/components/FullscreenDiagram';

# Roadmap

This document outlines the development plan for the Rituals App, focusing on the Gamification System and future features.

> **Status:** 🚧 In Development
> **Version:** 1.0

## 📅 Development Timeline

<FullscreenDiagram definition={`
gantt
    title Rituals App Development Roadmap
    dateFormat  YYYY-MM-DD
    section MVP Phase
    Backend Setup           :done,    des1, 2025-10-01, 2025-10-15
    Auth & Profile          :done,    des2, 2025-10-16, 2025-10-30
    Ritual Core Logic       :active,  des3, 2025-11-01, 2025-11-20
    Gamification (XP/Levels):active,  des4, 2025-11-15, 2025-12-01
    
    section Beta Phase
    Social Features         :         des5, 2025-12-01, 2025-12-15
    Notifications           :         des6, 2025-12-10, 2025-12-20
    Testing & Bug Fixes     :         des7, 2025-12-20, 2026-01-01
    
    section Future
    Group Rituals           :         fut1, 2026-02-01, 30d
    AI Coach Advanced       :         fut2, 2026-03-01, 30d
`} />

## 📋 Overview

The goal is to create a habit-building app that leverages social accountability and gamification to keep users engaged.

### Key Decisions

| Topic | Decision |
| :--- | :--- |
| **Friend Limit** | ❌ None (Unlimited) |
| **Group Rituals** | 🔮 Future Feature (Currently 1v1 only) |
| **Leaderboard** | 👤 Display by Username |
| **XP to Coin** | ❌ No direct conversion |
| **Coin Sales** | 💰 Real money purchase (Future) |
| **Private Rituals** | ❌ Cannot be shared |

## ✅ MVP Scope (Current Phase)

These features are the current priority for the Minimum Viable Product.

| Feature | Description | Priority |
| :--- | :--- | :--- |
| **Friend System** | Send/Accept requests, unlimited friends | **P0** |
| **Ritual Sharing** | Public/Private options, 1v1 partner streaks | **P0** |
| **XP & Level System** | Earn XP from actions, 10 initial levels | **P0** |
| **Coin System** | Earn coins from leveling up & badges | **P0** |
| **Freeze Item** | Protect streak from breaking (Purchasable) | **P1** |
| **Badge System** | Achievement badges | **P1** |
| **Leaderboard** | Friends ranking (Global & Friends) | **P1** |
| **Notifications** | Streak warnings, invites | **P1** |

## 🔮 Future Features

These features are planned for future updates.

| Feature | Description |
| :--- | :--- |
| **Group Rituals** | 3+ person group streaks |
| **Theme Store** | Buy app themes with Coins |
| **Avatar System** | Unlock avatars with Coins |
| **Premium Freeze** | Real money freeze packages |
| **Coin Store** | Buy Coins with real money |
