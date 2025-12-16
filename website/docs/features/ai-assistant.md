---
sidebar_position: 4
---

# AI Assistant

The Rituals App features an intelligent AI Assistant designed to act as a personal habit coach.

## Capabilities

The AI Assistant is accessible via the "Chat" tab and can help with:
*   **Ritual Creation:** Users can say "I want to start meditating every morning," and the AI will propose a configured ritual.
*   **Motivation:** Provides encouragement and tips for maintaining streaks.
*   **Q&A:** Answers questions about habit formation and productivity techniques.

## Security & Privacy

We prioritize user safety and data privacy in our AI implementation.

### Keyword Filtering
The application implements a client-side security service (`LlmSecurityService`) that pre-validates user input.
*   **Allowed Topics:** The AI is restricted to topics related to rituals, habits, productivity, and well-being.
*   **Forbidden Topics:** Inputs containing keywords related to violence, illegal acts, or self-harm are blocked immediately before reaching the server.

### Rate Limiting
To prevent abuse and manage costs, users are limited to a specific number of AI interactions per minute (e.g., 10 requests/minute).

## Usage Tracking

The backend logs token usage and model performance to optimize the experience and manage API costs.
