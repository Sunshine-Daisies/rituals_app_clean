import { Response } from 'express';
import { AuthRequest } from '../middleware/authMiddleware';
import { LlmService } from '../services/LlmService';

export const chat = async (req: AuthRequest, res: Response) => {
    const { prompt } = req.body;
    const userId = req.user?.id;

    if (!prompt) {
        return res.status(400).json({ error: 'Prompt is required' });
    }

    try {
        const response = await LlmService.getChatResponse(userId, prompt, req.user?.isPrem);
        res.json({ response });
    } catch (error: any) {
        console.error('LlmController Chat Error:', error);
        res.status(500).json({ error: error.message || 'Internal Server Error' });
    }
};

export const inferIntent = async (req: AuthRequest, res: Response) => {
    const { prompt } = req.body;
    const userId = req.user?.id;

    if (!prompt) {
        return res.status(400).json({ error: 'Prompt is required' });
    }

    try {
        const intentData = await LlmService.inferRitualIntent(userId, prompt, req.user?.isPrem);
        res.json(intentData);
    } catch (error: any) {
        console.error('LlmController Intent Error:', error);
        res.status(500).json({ error: error.message || 'Internal Server Error' });
    }
};
