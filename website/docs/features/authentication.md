---
sidebar_position: 1
---

# Authentication

The Rituals App uses a secure authentication system to manage user identities and sessions.

## Features

*   **Registration:** Users can create an account using their email and password.
*   **Login:** Secure login with JWT (JSON Web Token) issuance.
*   **Session Management:** Tokens are stored securely on the device.
*   **Profile Management:** Users can update their profile information.

## Technical Flow

1.  **Sign Up:**
    *   Endpoint: `POST /api/auth/register`
    *   Payload: `{ email, password, username }`
    *   Result: Creates a new user in the PostgreSQL database and returns a JWT.

2.  **Sign In:**
    *   Endpoint: `POST /api/auth/login`
    *   Payload: `{ email, password }`
    *   Result: Validates credentials and returns a JWT.

3.  **Token Storage:**
    *   **Mobile:** The JWT is stored in secure storage (e.g., `flutter_secure_storage`).
    *   **Requests:** The token is sent in the `Authorization` header (`Bearer <token>`) for all protected API calls.

## Security

*   **Password Hashing:** Passwords are hashed using `bcrypt` before storage.
*   **Route Protection:** Backend middleware verifies the JWT signature before allowing access to protected routes.
