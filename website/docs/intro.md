---
sidebar_position: 1
---

# Introduction

**Rituals App** is a comprehensive habit-tracking and social gamification platform designed to help users build better habits through social accountability and game-like mechanics.

## 🎯 Project Vision

Unlike traditional to-do lists, Rituals App focuses on the **social** and **emotional** aspects of habit formation. By combining streak mechanics, XP progression, and 1-on-1 partnerships, we aim to make self-improvement addictive and fun.

## 🏗️ Tech Stack Overview

The project consists of two main components:

### 🔙 Backend API
*   **Runtime:** Node.js (v18+)
*   **Framework:** Express.js
*   **Language:** TypeScript
*   **Database:** PostgreSQL (Relational Data)
*   **Documentation:** OpenAPI 3.0 (Swagger)
*   **Containerization:** Docker & Docker Compose

### 📱 Mobile Application
*   **Framework:** Flutter (v3.x)
*   **Language:** Dart
*   **State Management:** Riverpod (v2.x)
*   **Navigation:** GoRouter
*   **Local Storage:** Shared Preferences & Flutter Secure Storage

## 🔑 Key Features

*   **Ritual Tracking:** Create and track daily/weekly habits.
*   **Gamification:** Earn XP, level up, and unlock badges.
*   **Social Partnerships:** Pair up with a friend for a specific ritual (1v1 accountability).
*   **Streak System:** Maintain streaks to earn bonus rewards; use "Freezes" to save streaks.
*   **Leaderboards:** Compete with friends on weekly XP leaderboards.

## 📂 Repository Structure

```text
rituals_app/
├── backend/          # Node.js API Server source code
├── lib/              # Flutter Mobile App source code
├── website/          # Documentation (Docusaurus)
├── docs/             # Legacy planning documents
└── android/ios/web/  # Platform-specific Flutter code
```
