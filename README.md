# 🌱 Personalized Daily Rituals App# 🌱 Personalized Daily Rituals App


> Developed with **Flutter** (frontend), **Supabase** (backend), and **OpenAI API** for chatbot functionality.> Developed with **Flutter** (frontend), **Supabase** (backend), and **OpenAI API** for chatbot functionality.



------



## 🚀 Project Overview## 🚀 Project Overview

The app allows users to:The app allows users to:

- Create and manage daily rituals (morning/evening routines, habits, etc.)- Create and manage daily rituals (morning/evening routines, habits, etc.)

- Interact with a chatbot (powered by OpenAI API) to add/edit rituals in natural language- Interact with a chatbot (powered by OpenAI API) to add/edit rituals in natural language

- Get realtime updates via Supabase- Get realtime updates via Supabase

- Receive notifications when it's time for a ritual- Receive notifications when it’s time for a ritual

- Track progress with streaks and statistics- Track progress with streaks and statistics



------



## 🛠 Tech Stack## 🛠 Tech Stack

- **Frontend:** Flutter (Web & Android), Riverpod, fl_chart, FCM notifications- **Frontend:** Flutter, Riverpod, fl_chart, FCM notifications

- **Backend:** Supabase (Auth, Postgres DB, Realtime, Edge Functions)- **Backend:** Supabase (Auth, Postgres DB, Realtime, Edge Functions)

- **AI:** OpenAI API (chatbot, intent extraction)- **AI:** OpenAI API (chatbot, intent extraction)

- **DevOps:** Docker, Docker Compose- **Collaboration:** GitHub Projects, Issues, Labels, Milestones

- **Collaboration:** GitHub Projects, Issues, Labels, Milestones

---

---

## 📱 Core Features

## 📱 Supported Platforms- 🔑 User authentication (Supabase Auth)  

- ✅ **Android** - Mobile app- 💬 AI chatbot for ritual management (OpenAI API → JSON intents)  

- ✅ **Web** - Progressive Web App (PWA)- 📋 Ritual CRUD (create, edit, delete, reorder steps)  

- ✅ Checklist view for running a ritual step by step  

> ℹ️ **Note:** iOS, macOS, and Linux support removed for faster development cycles. Can be re-added later with `flutter create --platforms=ios,macos,linux .`- 🔔 Push notifications (reminders via Supabase Edge Functions)  

- 📊 Statistics & streak tracking (weekly/monthly charts)  

---- 🎨 Polished UI (dark mode, animations, onboarding flow)  



## 🔧 Development Setup---



### Prerequisites## 👥 Team

- Flutter SDK 3.8.1+- **Nuri** – AI & Chatbot (OpenAI API, intent design, integration)  

- Dart 3.0+- **Funda** – Backend (Supabase setup, DB, Auth, Functions)  

- Android Studio (for Android development)- **Azra** – Frontend (Flutter UI, state management, notifications)  

- Docker & Docker Compose (optional, for containerized development)

---

### Getting Started

## 📂 Project Structure

1. **Clone the repository**
```bash
git clone https://github.com/NuriOkumus/rituals_app.git
cd rituals_app
```

2. **Install dependencies**
```bash
flutter pub get
```

3. **Configure environment variables**
Create a `.env` file in the project root:
```env
OPENAI_API_KEY=your_openai_api_key_here
SUPABASE_URL=your_supabase_url_here
SUPABASE_ANON_KEY=your_supabase_anon_key_here
```

4. **Run the app**
```bash
# Web
flutter run -d chrome

# Android
flutter run -d android
```

### Docker Development
```bash
# Build and run web version
docker-compose up web

# Access at http://localhost:8080
```

---

## 📂 Project Structure
```
lib/
├── main.dart                 # App entry point
├── routes/
│   └── app_router.dart       # Go Router configuration
├── services/
│   ├── llm_service.dart      # OpenAI API integration
│   └── llm_security_service.dart # Llm security
│   └── supabase_service.dart # Supabase client
├── features/
│   ├── auth/                 # Authentication screens
│   ├── home/                 # Home dashboard
│   ├── chat/                 # AI chatbot
│   ├── ritual_detail/        # Ritual management
│   ├── checklist/            # Daily checklist
│   └── stats/                # Statistics & charts
├── data/
│   ├── models/               # Data models
│   └── repositories/         # Data access layer
└── widgets/                  # Reusable widgets
```

---

## 🔑 Core Features
- 🔑 User authentication (Supabase Auth)  
- 💬 AI chatbot for ritual management (OpenAI API → JSON intents)  
- 📋 Ritual CRUD (create, edit, delete, reorder steps)  
- ✅ Checklist view for running a ritual step by step  
- 🔔 Push notifications (reminders via Supabase Edge Functions)  
- 📊 Statistics & streak tracking (weekly/monthly charts)  
- 🎨 Polished UI (dark mode, animations, onboarding flow)  

---

## 👥 Team
- **Nuri** – AI & Chatbot (OpenAI API, intent design, integration)  
- **Funda** – Backend (Supabase setup, DB, Auth, Functions)  
- **Azra** – Frontend (Flutter UI, state management, notifications)  

---

## 📜 License
Copyright © 2025 Nuri Okumuş. All rights reserved.
