---
sidebar_position: 1
---

# Setup & Installation

This guide covers the setup process for the Node.js backend server. You can run the backend either entirely via Docker or manually for development.

## Prerequisites

Ensure you have the following installed:
*   **Node.js** (v18 or higher)
*   **Docker Desktop** (Required for PostgreSQL database)
*   **Git**

---

## Option 1: Quick Start (Docker) 🐳

The easiest way to get the entire stack (API + Database) running.

1.  **Navigate to the backend directory:**
    ```bash
    cd backend
    ```

2.  **Run Docker Compose:**
    ```bash
    docker-compose up --build
    ```

    This will:
    *   Start a PostgreSQL container on port `5432`.
    *   Start the Backend API on port `3000`.
    *   Automatically apply environment variables defined in `docker-compose.yml`.

3.  **Verify:**
    Open [http://localhost:3000/api-docs](http://localhost:3000/api-docs) to see the Swagger documentation.

---

## Option 2: Manual Setup (Local Development) 🛠️

Recommended if you want to run the Node.js server locally for debugging while keeping the database in Docker.

### 1. Install Dependencies

```bash
cd backend
npm install
```

### 2. Environment Configuration

Create a `.env` file in the `backend` root directory.

```env title="backend/.env"
# Server Configuration
PORT=3001
NODE_ENV=development

# Database Configuration
DB_HOST=localhost
DB_USER=postgres
DB_PASSWORD=postgres
DB_NAME=rituals_db
DB_PORT=5432

# Security
JWT_SECRET=your_super_secret_key_change_this

# Firebase (Required for Notifications)
# Path to your service account file relative to root
GOOGLE_APPLICATION_CREDENTIALS=./firebase-service-account.json

# Email Service (Optional)
EMAIL_USER=your_email@gmail.com
EMAIL_PASS=your_app_password
```

### 3. Firebase Setup

1.  Go to the Firebase Console.
2.  Generate a new private key (Service Account).
3.  Save the file as `firebase-service-account.json` in the `backend/` folder.

### 4. Start the Database

Run only the database container:

```bash
docker-compose up -d db
```

### 5. Initialize Data

Run the gamification initialization script to seed badges and levels:

```bash
npm run init-gamification
```

### 6. Start the Server

```bash
# Development mode (with hot-reload)
npm run dev

# Production mode
npm start
```

The server will start on `http://localhost:3001`.

---

## Available Scripts

| Command | Description |
| :--- | :--- |
| `npm run dev` | Starts the server with `nodemon` for hot-reloading. |
| `npm start` | Starts the server using `ts-node`. |
| `npm run init-gamification` | Seeds the database with initial badges and gamification rules. |
| `npm run migrate-partnerships` | Migration script for updating partnership data structure. |

## Troubleshooting

### Database Connection Refused
*   Ensure Docker Desktop is running.
*   Check if port `5432` is already in use.
*   If running locally, ensure `DB_HOST=localhost`. If running inside Docker, `DB_HOST=db`.

### Firebase Errors
*   Ensure `firebase-service-account.json` exists and is valid.
*   Check `GOOGLE_APPLICATION_CREDENTIALS` path in `.env`.
