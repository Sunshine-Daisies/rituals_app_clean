---
sidebar_position: 2
---

import FullscreenDiagram from '@site/src/components/FullscreenDiagram';

# Architecture

The backend is a **RESTful API** built with **Node.js** and **Express**, written in **TypeScript**. It follows a **Service-Controller** pattern to separate concerns and ensure maintainability.

## High-Level Overview

The system is designed to be stateless and scalable, integrating with PostgreSQL for data and Firebase for notifications.

<FullscreenDiagram definition={`
flowchart LR
    Client[Mobile App] -->|HTTP Requests| API[Express API]
    
    subgraph Backend [Backend Server]
        API --> Auth[Auth Middleware]
        Auth --> Router[Router]
        Router --> Controller[Controllers]
        Controller --> Service[Services]
    end
    
    Service -->|SQL| DB[(PostgreSQL)]
    Service -->|Push Notif| FCM[Firebase Cloud Messaging]
    Service -->|Email| SMTP[Nodemailer]
    
    Cron[Cron Jobs] -->|Scheduled Tasks| Service
    
    style Backend fill:#f5f5f5,stroke:#333,stroke-dasharray: 5 5
    style DB fill:#bbf,stroke:#333,stroke-width:2px
    style FCM fill:#ffcc80,stroke:#e65100
`} />

## Layered Architecture

We strictly separate the "how" (HTTP handling) from the "what" (Business Logic).

<FullscreenDiagram definition={`
classDiagram
    class Controller {
        +handleRequest(req, res)
        +validateInput()
        +sendResponse()
    }
    
    class Service {
        +executeBusinessLogic()
        +calculateStats()
        +triggerNotifications()
    }
    
    class Database {
        +query(sql, params)
        +pool
    }

    Controller --> Service : Calls
    Service --> Database : Queries
    
    note for Controller "Layer: Presentation\nHandles HTTP, JSON, Status Codes"
    note for Service "Layer: Business Logic\nPure logic, reusable, throws Errors"
    note for Database "Layer: Data Access\nRaw SQL / Query Builder"
`} />

### 1. Presentation Layer (Controllers & Routes)
*   **Routes:** Define the API endpoints (e.g., `POST /rituals`).
*   **Controllers:** Extract data from requests (`req.body`, `req.user`), call the appropriate service, and format the response. They do *not* contain business logic.

### 2. Business Logic Layer (Services)
*   **Services:** Contain the core application logic. For example, `RitualService` handles creating a ritual, validating limits, and scheduling initial reminders.
*   **Independence:** Services don't know about HTTP. They accept parameters and return data or throw errors.

### 3. Data Access Layer
*   **PostgreSQL:** We use raw SQL queries (via `pg` pool) for maximum control and performance.
*   **Migrations:** Database schema changes are managed via SQL scripts.

## Background Processes

We use `node-cron` for scheduled tasks that run independently of user requests.

*   **Streak Scheduler:** Runs daily at midnight to check for missed rituals and reset streaks.
*   **Notification Scheduler:** Checks for upcoming ritual reminders and sends push notifications via Firebase.

## Tech Stack

| Category | Technology | Purpose |
|----------|------------|---------|
| **Runtime** | Node.js | Server-side JavaScript runtime |
| **Language** | TypeScript | Type safety and modern features |
| **Framework** | Express.js | Web server framework |
| **Database** | PostgreSQL | Relational database |
| **Auth** | JWT (jsonwebtoken) | Stateless authentication |
| **Scheduling** | node-cron | Scheduled tasks |
| **Push Notif** | Firebase Admin | Sending FCM messages |
| **Docs** | Swagger (OpenAPI) | API Documentation |
