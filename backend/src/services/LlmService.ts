import OpenAI from 'openai';
import dotenv from 'dotenv';

dotenv.config();

// Rate Limiting In-Memory Store (Simple implementation)
// For production with multiple instances, use Redis.
interface RateLimitData {
    count: number;
    lastRequest: number;
}
const rateLimits: Record<string, RateLimitData> = {};
const RATE_LIMIT_WINDOW_MS = 60 * 1000; // 1 minute
const MAX_REQUESTS_PER_WINDOW = 20;
// COOLDOWN_MS removed to allow parallel ritual mapping (intent + chat)

export class LlmService {
    private static openai: OpenAI;

    // Model configurations
    private static readonly CHAT_MODEL = 'gpt-4o-mini';
    private static readonly INTENT_MODEL = 'gpt-4o-mini';

    private static initialize() {
        if (!this.openai) {
            const apiKey = process.env.OPENAI_API_KEY;
            if (!apiKey) {
                throw new Error('Server misconfiguration: OPENAI_API_KEY missing');
            }
            this.openai = new OpenAI({ apiKey });
        }
    }

    // ==========================================
    // SECURITY & VALIDATION
    // ==========================================

    private static allowedKeywords = [
        'ritual', 'ritüel', 'rituel',
        'habit', 'alışkanlık', 'aliskanlik',
        'routine', 'rutin',
        'reminder', 'hatırlatma', 'hatirlatma',
        'task', 'görev', 'gorev',
        'step', 'adım', 'adim',
        'complete', 'tamamla', 'done',
        'stat', 'istatistik', 'statistics',
        'create', 'oluştur', 'olustur',
        'edit', 'düzenle', 'duzenle',
        'delete', 'sil',
        'show', 'göster', 'goster',
        'list', 'listele',
        'morning', 'sabah',
        'evening', 'akşam', 'aksam',
        'daily', 'günlük', 'gunluk',
        'meditation', 'meditasyon',
        'exercise', 'egzersiz',
        'prayer', 'dua',
        'yoga',
        'sleep', 'uyku',
    ];

    private static forbiddenTopics = [
        'hack', 'crack', 'exploit',
        'illegal', 'yasa dışı', 'yasadisi',
        'drug', 'uyuşturucu', 'uyusturucu',
        'weapon', 'silah',
        'violence', 'şiddet', 'siddet',
        'harm', 'zarar',
        'suicide', 'intihar',
    ];

    private static validateUserInput(prompt: string): boolean {
        const lowerPrompt = prompt.toLowerCase();

        // Check forbidden topics
        for (const forbidden of this.forbiddenTopics) {
            if (lowerPrompt.includes(forbidden)) return false;
        }

        // Check allowed keywords
        let hasAllowedKeyword = false;
        for (const keyword of this.allowedKeywords) {
            if (lowerPrompt.includes(keyword)) {
                hasAllowedKeyword = true;
                break;
            }
        }

        // Allow small talk / greetings
        if (!hasAllowedKeyword && lowerPrompt.length < 50) {
            const greetings = ['hello', 'hi', 'hey', 'merhaba', 'selam', 'nasıl', 'nasilsin'];
            for (const greeting of greetings) {
                if (lowerPrompt.includes(greeting)) {
                    hasAllowedKeyword = true;
                    break;
                }
            }
        }

        return hasAllowedKeyword;
    }

    private static checkRateLimit(userId: string, isPremium: boolean = false) {
        // Skip all checks for premium users
        if (isPremium) return;

        const now = Date.now();
        const userLimit = rateLimits[userId] || { count: 0, lastRequest: 0 };

        // Reset window if passed
        if (now - userLimit.lastRequest > RATE_LIMIT_WINDOW_MS) {
            userLimit.count = 0;
        }

        // Max requests check
        if (userLimit.count >= MAX_REQUESTS_PER_WINDOW) {
            throw new Error('RATE_LIMIT_REACHED');
        }

        // Update limit
        userLimit.count++;
        userLimit.lastRequest = now;
        rateLimits[userId] = userLimit;
    }

    // ==========================================
    // SYSTEM PROMPTS
    // ==========================================

    private static getChatSystemPrompt(): string {
        return `
You are the AI-powered life coach of the "Rituals" app. Your name is "Ritual Guide".
Your Mission: To help users build better habits, organize their rituals, and stay motivated.

Your Personality:
- Empathetic, supportive, and motivating.
- Give short, clear, and actionable answers.
- Do not judge the user; always approach positively.
- Use emojis to keep the communication warm. 🌿✨

Capabilities and Limits:
- Guide on creating, editing, and deleting rituals.
- Provide information about habit tracking and statistics.
- Offer support when motivation drops.
- For questions OUTSIDE these topics (politics, general knowledge, coding, etc.), politely state that you cannot answer and bring the topic back to habits.
`;
    }

    private static getRitualIntentSystemPrompt(): string {
        return `
You are a ritual and habit management assistant.
Return the user's ritual management request ONLY as JSON.

IMPORTANT SECURITY RULES:
- ONLY process requests related to ritual, habit, and routine management.
- Mark out-of-scope requests as "small_talk".
- NEVER generate harmful, illegal, or inappropriate content.

Schema:
- intent: create_ritual | edit_ritual | delete_ritual | reorder_steps | log_completion | set_reminder | show_stats | small_talk
- ritual_name: string|null (Short and concise name)
- description: string|null (Purpose of the ritual or a motivational sentence, max 100 chars)
- icon: string|null (A single emoji representing the ritual, e.g., "🧘‍♂️", "💧")
- steps: string[]|null (List of steps, max 20 steps)
- reminder: { time: "HH:mm" | ISO time, days: ["Mon","Tue","Wed","Thu","Fri","Sat","Sun"] }|null

Rule:
- No free text. Just pure JSON.
- If unsure, make a reasonable guess; do not leave fields null if possible.
- For out-of-scope requests, set intent="small_talk" and other fields to null.
`;
    }

    // ==========================================
    // PUBLIC METHODS
    // ==========================================

    static async getChatResponse(userId: string, prompt: string, isPremium: boolean = false): Promise<string> {
        this.initialize();
        this.checkRateLimit(userId, isPremium);

        if (!this.validateUserInput(prompt)) {
            return "I'm here to help with your rituals and habits. Could we focus on that? 🌿";
        }

        try {
            const response = await this.openai.chat.completions.create({
                model: this.CHAT_MODEL,
                messages: [
                    { role: 'system', content: this.getChatSystemPrompt() },
                    { role: 'user', content: prompt }
                ],
                max_tokens: 800,
                temperature: 0.7,
            });

            return response.choices[0]?.message?.content || "I couldn't think of a response right now.";
        } catch (error) {
            console.error('OpenAI Chat Error:', error);
            throw new Error('Failed to generate response');
        }
    }

    static async inferRitualIntent(userId: string, prompt: string, isPremium: boolean = false): Promise<any> {
        this.initialize();
        this.checkRateLimit(userId, isPremium);

        if (!this.validateUserInput(prompt)) {
            // Return a safe 'small_talk' intent if validation fails
            return { intent: 'small_talk' };
        }

        try {
            const response = await this.openai.chat.completions.create({
                model: this.INTENT_MODEL,
                messages: [
                    { role: 'system', content: this.getRitualIntentSystemPrompt() },
                    { role: 'user', content: prompt }
                ],
                response_format: { type: "json_object" },
                max_tokens: 400,
                temperature: 0,
            });

            const content = response.choices[0]?.message?.content;
            if (!content) return { intent: 'small_talk' };

            return JSON.parse(content);
        } catch (error) {
            console.error('OpenAI Intent Error:', error);
            throw new Error('Failed to infer intent');
        }
    }
}
