---
sidebar_position: 2
---

import FullscreenDiagram from '@site/src/components/FullscreenDiagram';

# Architecture

The mobile application is built using **Flutter** and follows a **Feature-First** architecture with **Riverpod** for state management. This approach ensures scalability by grouping code by *domain* (what it does) rather than *layer* (what it is).

## High-Level Overview

The app follows a unidirectional data flow pattern, typical of modern declarative UI frameworks.

<FullscreenDiagram definition={`
flowchart TD
    subgraph UI ["Presentation Layer"]
        Screen["Screens / Pages"]
        Widget["Reusable Widgets"]
    end

    subgraph State ["Application State"]
        Controller["Riverpod Notifiers"]
        StateObj["Immutable State Objects"]
    end

    subgraph Data ["Data Layer"]
        Repo["Repositories"]
        Model["Data Models"]
    end

    subgraph External ["Infrastructure"]
        API["REST API (Dio)"]
        Local["Secure Storage / Hive"]
        Firebase["Firebase Services"]
    end

    Screen -->|Reads/Watches| Controller
    Screen -->|User Actions| Controller
    Controller -->|Updates| StateObj
    Controller -->|Calls| Repo
    Repo -->|Fetches| API
    Repo -->|Caches| Local
    
    style UI fill:#e1f5fe,stroke:#01579b
    style State fill:#fff9c4,stroke:#fbc02d
    style Data fill:#e8f5e9,stroke:#2e7d32
    style External fill:#f3e5f5,stroke:#7b1fa2
`} />

## Folder Structure Strategy

We organize code primarily by **Feature**. Each feature folder is a self-contained module containing its own UI, logic, and data handling.

```text
lib/
├── config/         # App-wide configuration (Env, Constants, Theme)
├── core/           # Shared utilities, extensions, and exceptions
├── data/           # Global data definitions (if shared across many features)
├── features/       # 📦 FEATURE MODULES
│   ├── auth/       
│   ├── home/       
│   ├── rituals/    # Example Feature
│   │   ├── presentation/   # UI: Screens & Widgets
│   │   ├── application/    # Logic: Providers & Notifiers
│   │   ├── domain/         # Models & Entities
│   │   ├── data/           # Repositories & DTOs
│   └── profile/    
├── routes/         # Navigation configuration (GoRouter)
├── services/       # External services (API, Local Storage, Notifications)
└── main.dart       # App entry point
```

## Dependency Injection & State Management

We use **Riverpod** (`flutter_riverpod`) for both DI and State Management.

<FullscreenDiagram definition={`
classDiagram
    class ApiService {
        +Dio dio
        +get()
        +post()
    }
    
    class RitualRepository {
        +ApiService api
        +getRituals()
        +createRitual()
    }
    
    class RitualListNotifier {
        +RitualRepository repo
        +state: AsyncValue<List<Ritual>>
        +loadRituals()
        +addRitual()
    }
    
    class RitualListScreen {
        +Widget build(ref)
    }

    RitualRepository ..> ApiService : Uses
    RitualListNotifier ..> RitualRepository : Uses
    RitualListScreen ..> RitualListNotifier : Watches
    
    note for RitualListNotifier "Provider: ritualListProvider"
    note for ApiService "Provider: apiServiceProvider"
`} />

### Key Concepts
*   **Providers:** The glue that holds the app together. Declared globally but used locally.
*   **AsyncValue:** Used to handle loading, error, and data states safely in the UI.
*   **Immutability:** All state classes are immutable (using `freezed` is recommended).

## Navigation (GoRouter)

Navigation is handled by `go_router`. It provides a URL-based navigation system which is essential for deep linking.

*   **Routes:** Defined in `lib/routes/app_router.dart`.
*   **Guards:** We use `redirect` logic to protect routes (e.g., redirecting unauthenticated users to `/login`).

## Tech Stack Summary

| Category | Package | Purpose |
|----------|---------|---------|
| **Framework** | Flutter | UI Toolkit |
| **State Mgt** | flutter_riverpod | State & DI |
| **Networking** | dio | HTTP Client |
| **Navigation** | go_router | Routing & Deep Links |
| **Local Data** | shared_preferences | Simple key-value storage |
| **Notifications** | flutter_local_notifications | Local scheduling |
| **Push Notif** | firebase_messaging | Remote push notifications |
