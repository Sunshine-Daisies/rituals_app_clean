# 🌱 Personalized Daily Rituals App

> A habit tracking and ritual management app built with **Flutter**, **Node.js/Express**, **PostgreSQL**, and **OpenAI API**.

---

## 🚀 Project Overview

The app allows users to:
- Create and manage daily rituals (morning/evening routines, habits, etc.)
- Interact with an AI chatbot (powered by OpenAI API) to add/edit rituals in natural language
- Receive email verification for secure authentication
- Track progress with streaks and statistics

---

## 🛠 Tech Stack

### Frontend
- **Flutter** - Cross-platform UI framework (Android & Web)
- **Dart** - Programming language
- **Riverpod** - State management
- **GoRouter** - Navigation & routing
- **dart_openai** - OpenAI API client

### Backend
- **Node.js** - JavaScript runtime
- **Express.js** - Web framework
- **TypeScript** - Type-safe development
- **PostgreSQL 15** - Relational database
- **JWT** - JSON Web Token authentication
- **Nodemailer** - Email service (Gmail SMTP)

### AI/LLM
- **OpenAI GPT-4o** - Chat responses
- **OpenAI GPT-4o-mini** - Intent extraction (JSON)

### DevOps
- **Docker** - Containerization
- **Docker Compose** - Container orchestration

---

## 📱 Supported Platforms

- ✅ **Android** - Mobile app
- ✅ **Web** - Progressive Web App (PWA)

---

## 🔑 Core Features

- 🔐 User authentication with email verification
- 💬 AI chatbot for ritual management (natural language → JSON intents)
- 📋 Ritual CRUD (create, edit, delete, reorder steps)
- ✅ Checklist view for step-by-step ritual execution
- ⏰ Reminder scheduling (time & days)
- 📊 Statistics & streak tracking
- 🎨 Dark mode UI with modern design

---

## 🔧 Development Setup

### Prerequisites
- [Docker Desktop](https://www.docker.com/products/docker-desktop/) (Backend & Database)
- [Flutter SDK 3.8+](https://docs.flutter.dev/get-started/install)
- OpenAI API Key

### Backend Setup (Docker)

```bash
cd backend
docker-compose up --build