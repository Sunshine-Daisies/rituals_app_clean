---
sidebar_position: 1
---

# Introduction

**Rituals App** is a comprehensive habit-tracking and social gamification platform designed to help users build better habits through social accountability and game-like mechanics.

## 🎯 Project Vision

Unlike traditional to-do lists, Rituals App focuses on the **social** and **emotional** aspects of habit formation. By combining streak mechanics, XP progression, partnerships, and AI coaching, we aim to make self-improvement addictive and fun.

## 🏗️ Tech Stack Overview

The project consists of three main components:

### 🔙 Backend API
*   **Runtime:** Node.js (v18+)
*   **Framework:** Express.js
*   **Language:** TypeScript
*   **Database:** PostgreSQL (Relational Data)
*   **Cache:** Redis (Session & Rate Limiting)
*   **AI:** OpenAI GPT-4 Integration
*   **Notifications:** Firebase Cloud Messaging (FCM)
*   **Documentation:** OpenAPI 3.0 (Swagger)

### 📱 Mobile Application
*   **Framework:** Flutter (v3.x)
*   **Language:** Dart
*   **State Management:** Riverpod (v2.x)
*   **Navigation:** GoRouter
*   **Local Storage:** SharedPreferences & Flutter Secure Storage
*   **Push Notifications:** Firebase Messaging

### 🌐 Documentation Website
*   **Framework:** Docusaurus (v3.x)
*   **Language:** React/MDX
*   **Diagrams:** Mermaid.js

## 🔑 Key Features

### Core Functionality
*   **Ritual Tracking:** Create and track daily/weekly habits with customizable reminders.
*   **Onboarding Flow:** Guided setup for new users with welcome screens and first ritual wizard.
*   **Swipe-to-Complete:** Quick ritual completion with a simple swipe gesture.

### Gamification
*   **XP & Levels:** Earn experience points and level up your profile.
*   **Zen Badges:** 15 unique achievement badges across streak, social, and milestone categories.
*   **Coins:** Earn coins through badges and level-ups.
*   **Leaderboards:** Compete with friends on weekly XP rankings.
*   **Streaks:** Maintain daily streaks with Freeze protection.

### Social Features
*   **Equal Partnerships:** 1-on-1 accountability with friends on specific rituals.
*   **Friends System:** Add friends via username search, manage pending invites.
*   **Nudges:** Send friendly reminders to partners who haven't completed their ritual.

### AI & Smart Features
*   **AI Habit Coach:** Chat-based assistant for motivation and habit advice.
*   **Intent Actions:** AI can create rituals, adjust reminders, and take in-app actions.
*   **Push Notifications:** FCM-powered reminders and streak warnings.

### Premium Features
*   **Premium Subscription:** Enhanced features for subscribed users.
*   **Unlimited AI:** Premium users get unlimited AI interactions.
*   **Priority Support:** Faster response times for premium members.

## 📂 Repository Structure

```text
rituals_app/
├── backend/          # Node.js API Server
│   ├── src/
│   │   ├── controllers/   # Request handlers
│   │   ├── routes/        # API endpoints
│   │   ├── services/      # Business logic
│   │   └── middleware/    # Auth & validation
│   └── package.json
├── lib/              # Flutter Mobile App
│   ├── features/     # Feature-based modules
│   ├── services/     # API & business services
│   ├── routes/       # Navigation configuration
│   └── theme/        # App theming
├── website/          # Docusaurus Documentation
└── android/ios/      # Platform-specific code
```

## 🚀 Getting Started

1. **Backend:** See [Deployment Guide](/docs/deployment) for setup instructions.
2. **Mobile:** Run `flutter pub get` and `flutter run` in the root directory.
3. **Documentation:** Run `npm start` in the `website/` directory.
