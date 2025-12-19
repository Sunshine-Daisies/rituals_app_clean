# Rituals App - Design Brief

This document provides a comprehensive overview of the **Rituals App**, a Flutter-based mobile application designed for personal and social habit tracking.

## 1. Project Overview
The Rituals App helps users create, track, and share daily rituals. It features gamification elements like levels, XP, coins, and badges to motivate consistency, and a "Partnership" system for shared accountability.

---

## 2. Visual Identity (Design System)

### Color Palette
- **Primary**: `#6C63FF` (Modern Purple) - Main action color.
- **Accent**: `#FF6584` (Vibrant Pink/Red) - Secondary actions and highlights.
- **Background**: Dark Mode by default.
  - Deep Navy: `#1A1A2E`
  - Darker Navy: `#16213E`
- **Surface/Cards**: `#3E4A69` / `#2E3A59`
- **Status Colors**:
  - Success: `#4CAF50` (Green)
  - Error: `#EF5350` (Red)
  - Warning: `#FFA726` (Orange)

### Typography & Spacing
- **Font**: System Default (Inter/Roboto styled).
- **Radius**: Large rounded corners (`12px` to `24px`) for a modern, friendly feel.
- **Gradients**: Heavy use of linear gradients for buttons and specialty cards.
- **Shadows**: Soft, subtle shadows for depth.

---

## 3. Page Inventory & UX Flow

### 3.1. Authentication Flow
- **Welcome Screen**: Engaging entry point with logo animations and clear CTAs (Get Started / Sign In).
- **Auth Screen**: Unified Login/Signup with smooth transitions. Focus on minimal inputs (Email, Password, Name).

### 3.2. Core Experience
- **Home Screen**: The main "Dashboard". Displays a celebratory greeting, personal progress summary, and high-priority tiles for "Today's Rituals" and "Partnership Status".
- **Checklist Screen**: The execution layer. A focused, minimal list where users check off steps of an active ritual. Features an "all-complete" celebration.
- **Rituals List**: Categorized management. Toggle between "My Rituals" and "Partner Rituals". Action FAB for creating new habits.

### 3.3. Creation & Insights
- **Ritual Create**: Manual form for naming, step-by-step definition, and scheduling (time/days).
- **AI Chat Assistant**: Conversational creation. Users describe their goal, and the AI generates a structured ritual preview for approval.
- **Stats Screen**: Data-driven insights. Weekly activity bar charts, metric cards (streaks, success rate), and a 30-day "GitHub-style" contribution heatmap.

### 3.4. Social & Gamification
- **Profile Screen**: Personal hub. Visual progress bars for Level/XP, coin balance, and "Freeze" (streak save) inventory.
- **Leaderboard**: Competitive social layer. Toggle between Global and Friends rankings.
- **Badges Screen**: Reward gallery. "Earned" vs "In Progress" tabs. Each badge has unique requirement text and associated rewards.
- **Friends Screen**: Social management. Search for users, handle incoming/outgoing requests.
- **Join Ritual Screen**: Collaboration entry point via 6-digit invitation codes.

### 3.5. Communication
- **Notifications Screen**: Event-driven log. Level-up alerts, badge rewards, and partnership invites with inline Accept/Reject actions.

---

## 4. Key Design Principles
1. **Consistency**: Use existing gradients and radius tokens across all new UI components.
2. **Engagement**: Celebrate completions with haptics or visual micro-animations (implied in code).
3. **Accessibility**: Maintain high contrast between white text and dark navy backgrounds.
4. **Social Focus**: Prioritize partnership elements (shared cards, sync status) to drive user retention.

---

## 5. Technical Stack
- **Framework**: Flutter
- **State Management**: Riverpod
- **Navigation**: GoRouter
- **Theme**: Custom `AppTheme` class with centralized tokens.
